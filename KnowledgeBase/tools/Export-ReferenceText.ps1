#Requires -Version 7
# Extracts plain text from the binary files in references/ (docx, xlsx, pdf, zip listing) to an output folder.
param(
    [string]$SourceDir = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'references'),
    [string]$OutDir = (Join-Path $env:TEMP 'c9refs')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Read-ZipEntry([System.IO.Compression.ZipArchive]$zip, [string]$name) {
    $e = $zip.GetEntry($name)
    if (-not $e) { return $null }
    $r = [IO.StreamReader]::new($e.Open())
    try { return $r.ReadToEnd() } finally { $r.Dispose() }
}

function Get-ParagraphText([System.Xml.XmlNode]$p, $ns) {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($n in $p.SelectNodes('.//w:t|.//w:tab|.//w:br', $ns)) {
        switch ($n.LocalName) { 't' { [void]$sb.Append($n.InnerText) } 'tab' { [void]$sb.Append("`t") } 'br' { [void]$sb.Append(' ') } }
    }
    $sb.ToString()
}

function Convert-Docx([string]$path) {
    $zip = [IO.Compression.ZipFile]::OpenRead($path)
    try { [xml]$doc = Read-ZipEntry $zip 'word/document.xml' } finally { $zip.Dispose() }
    $ns = [System.Xml.XmlNamespaceManager]::new($doc.NameTable)
    $ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    $lines = foreach ($node in $doc.SelectSingleNode('//w:body', $ns).ChildNodes) {
        if ($node.LocalName -eq 'p') {
            $style = $node.SelectSingleNode('w:pPr/w:pStyle/@w:val', $ns)
            $t = Get-ParagraphText $node $ns
            if ($style -and $style.Value -match '^Heading(\d)') { ('#' * [int]$Matches[1]) + ' ' + $t } else { $t }
        }
        elseif ($node.LocalName -eq 'tbl') {
            foreach ($tr in $node.SelectNodes('w:tr', $ns)) {
                '| ' + (($tr.SelectNodes('w:tc', $ns) | ForEach-Object {
                            (($_.SelectNodes('w:p', $ns) | ForEach-Object { Get-ParagraphText $_ $ns }) -join ' / ').Trim()
                        }) -join ' | ') + ' |'
            }
            ''
        }
    }
    $lines -join "`n"
}

function Convert-Xlsx([string]$path) {
    $zip = [IO.Compression.ZipFile]::OpenRead($path)
    try {
        $shared = @()
        $ssXml = Read-ZipEntry $zip 'xl/sharedStrings.xml'
        if ($ssXml) {
            [xml]$ss = $ssXml
            $shared = @($ss.sst.si | ForEach-Object { ($_.SelectNodes('.//*[local-name()="t"]') | ForEach-Object InnerText) -join '' })
        }
        [xml]$wb = Read-ZipEntry $zip 'xl/workbook.xml'
        [xml]$rels = Read-ZipEntry $zip 'xl/_rels/workbook.xml.rels'
        $out = [System.Text.StringBuilder]::new()
        foreach ($sheet in $wb.workbook.sheets.sheet) {
            $rid = $sheet.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
            $target = ($rels.Relationships.Relationship | Where-Object Id -eq $rid).Target -replace '^/xl/', ''
            [xml]$ws = Read-ZipEntry $zip ('xl/' + $target)
            [void]$out.AppendLine("## Sheet: $($sheet.name)")
            foreach ($row in $ws.worksheet.sheetData.row) {
                $cells = foreach ($c in $row.c) {
                    $v = $c.v
                    if ($c.t -eq 's' -and $null -ne $v) { $v = $shared[[int]$v] }
                    elseif ($c.t -eq 'inlineStr') { $v = $c.is.InnerText }
                    "$($c.r)=$v"
                }
                $vals = @($cells | Where-Object { $_ -notmatch '=$' })
                if ($vals.Count) { [void]$out.AppendLine(($vals -join "`t")) }
            }
            [void]$out.AppendLine()
        }
        $out.ToString()
    }
    finally { $zip.Dispose() }
}

function Convert-Pdf([string]$path) {
    $pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
    if ($pdftotext) { return (& $pdftotext.Source -layout $path - | Out-String) }
    # Word COM is not used: it hangs on a hidden PDF-conversion prompt.
    & (Join-Path $PSScriptRoot 'Convert-PdfToText.ps1') -Path $path
}

$report = [System.Collections.Generic.List[string]]::new()
foreach ($f in Get-ChildItem $SourceDir -Recurse -File) {
    $rel = [IO.Path]::GetRelativePath($SourceDir, $f.FullName)
    $outName = ($rel -replace '[\\/:*?"<>| ]', '_') + '.txt'
    try {
        $text = switch ($f.Extension.ToLowerInvariant()) {
            '.docx' { Convert-Docx $f.FullName }
            '.xlsx' { Convert-Xlsx $f.FullName }
            '.pdf' { Convert-Pdf $f.FullName }
            '.zip' { $z = [IO.Compression.ZipFile]::OpenRead($f.FullName); try { ($z.Entries | ForEach-Object { "$($_.FullName)`t$($_.Length)" }) -join "`n" } finally { $z.Dispose() } }
            default { $null }
        }
        if ($null -ne $text) {
            Set-Content -LiteralPath (Join-Path $OutDir $outName) -Value $text -Encoding utf8
            $report.Add("OK`t$rel`t$($text.Length) chars")
        }
    }
    catch {
        $report.Add("FAIL`t$rel`t$($_.Exception.Message)")
    }
}

# Compare reference SQL scripts with the copies in the repo.
$repoScripts = Join-Path (Split-Path $SourceDir -Parent) 'Cloud9.BizTalk.Scripts'
foreach ($s in Get-ChildItem $SourceDir -Recurse -Filter *.sql) {
    $repoCopy = Join-Path $repoScripts (Join-Path $s.Directory.Name $s.Name)
    if (-not (Test-Path -LiteralPath $repoCopy)) { $report.Add("SQL-NEW`t$([IO.Path]::GetRelativePath($SourceDir, $s.FullName))"); continue }
    $same = (Get-FileHash -LiteralPath $s.FullName).Hash -eq (Get-FileHash -LiteralPath $repoCopy).Hash
    $report.Add("SQL-$(if ($same) { 'SAME' } else { 'DIFF' })`t$([IO.Path]::GetRelativePath($SourceDir, $s.FullName))")
}

$report | Set-Content -LiteralPath (Join-Path $OutDir '_report.txt') -Encoding utf8
"Wrote $($report.Count) report lines to $OutDir"
