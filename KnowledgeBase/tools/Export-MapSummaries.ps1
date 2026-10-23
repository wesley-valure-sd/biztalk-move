<#
.SYNOPSIS
  Write a readable text summary of each BizTalk map (.btm).
.DESCRIPTION
  A .btm file is a UTF-16 XML document with long lines. This script
  writes one .txt file for each map. The text file lists the source and
  target schemas, every link, every functoid, and the inline script code.
  Use the output to read map logic without the BizTalk Mapper.
#>
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$OutDir = (Join-Path $PSScriptRoot '..\map-summaries')
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Functoid IDs. Names marked "(inferred)" come from how the maps use them, not from a BizTalk reference.
$fidNames = @{
    '101' = 'String Find (inferred)'
    '102' = 'String Left (inferred)'
    '105' = 'String Size (inferred)'
    '107' = 'String Concatenate'
    '119' = 'Subtraction (inferred)'
    '120' = 'Multiplication (inferred)'
    '125' = 'Date and Time, current (inferred)'
    '260' = 'Scripting'
    '311' = 'Greater Than (inferred)'
    '313' = 'Less Than (inferred)'
    '315' = 'Equal (inferred)'
    '320' = 'Logical OR (inferred)'
    '323' = 'Index (inferred)'
    '328' = 'Cumulative Concatenate (inferred)'
    '375' = 'Value Mapping'
    '424' = 'Looping'
    '474' = 'Iteration (inferred)'
    '701' = 'FID 701 (unknown: Nil Value or Logical Existence)'
    '705' = 'Logical NOT (inferred)'
}

function Get-ShortPath([string]$xpath) {
    $names = [regex]::Matches($xpath, "local-name\(\)='([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    ($names | Where-Object { $_ -ne '<Schema>' }) -join '/'
}

Get-ChildItem -Path $Root -Recurse -Filter *.btm | Where-Object { $_.FullName -notlike '*\KnowledgeBase\*' } | ForEach-Object {
    $file = $_
    [xml]$doc = [System.IO.File]::ReadAllText($file.FullName)
    $ms = $doc.mapsource
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("MAP: $($file.Name)")
    [void]$sb.AppendLine("PATH: $($file.FullName.Substring($Root.Length).TrimStart('\'))")
    [void]$sb.AppendLine("SOURCE: $($ms.SrcTree.Reference.Location) (root $($ms.SrcTree.RootNode_Name))")
    [void]$sb.AppendLine("TARGET: $($ms.TrgTree.Reference.Location) (root $($ms.TrgTree.RootNode_Name))")
    $precedence = @($ms.ScriptTypePrecedence.ChildNodes | Where-Object { $_.Enabled -eq 'Yes' } | ForEach-Object { $_.LocalName }) -join ' > '
    [void]$sb.AppendLine("SCRIPT PRECEDENCE (first match wins when a functoid has more than one script): $precedence")
    [void]$sb.AppendLine('')

    foreach ($page in @($ms.Pages.Page)) {
        [void]$sb.AppendLine("=== PAGE: $($page.Name) ===")
        [void]$sb.AppendLine('--- LINKS (LinkID: From -> To). A number is a functoid ID. ---')
        foreach ($l in @($page.Links.Link)) {
            if (-not $l) { continue }
            $from = if ($l.LinkFrom -match '^\d+$') { "F$($l.LinkFrom)" } else { Get-ShortPath $l.LinkFrom }
            $to = if ($l.LinkTo -match '^\d+$') { "F$($l.LinkTo)" } else { Get-ShortPath $l.LinkTo }
            [void]$sb.AppendLine("L$($l.LinkID): $from -> $to")
        }
        [void]$sb.AppendLine('--- FUNCTOIDS ---')
        foreach ($f in @($page.Functoids.Functoid)) {
            if (-not $f) { continue }
            $fid = $f.'Functoid-FID'
            $name = if ($fidNames.ContainsKey($fid)) { $fidNames[$fid] } else { "FID $fid" }
            $inputs = @($f.'Input-Parameters'.Parameter | Where-Object { $_ } | ForEach-Object {
                    if ($_.Type -eq 'link') { "L$($_.Value)" } else { "const:'$($_.Value)'" }
                }) -join ', '
            [void]$sb.AppendLine("F$($f.FunctoidID) [$name] inputs: $inputs")
            foreach ($script in @($f.ScripterCode.Script | Where-Object { $_ })) {
                if ($script.Language -eq 'ExternalAssembly') {
                    [void]$sb.AppendLine("    script ExternalAssembly: $($script.Class).$($script.Function) [$($script.Assembly)]")
                    continue
                }
                [void]$sb.AppendLine("    script language: $($script.Language)")
                $code = $script.'#cdata-section'
                if (-not $code) { $code = $script.InnerText }
                foreach ($line in ($code -split "`r?`n")) { [void]$sb.AppendLine("    | $line") }
            }
        }
        [void]$sb.AppendLine('')
    }
    $dest = Join-Path $OutDir ($file.BaseName + '.txt')
    [System.IO.File]::WriteAllText($dest, $sb.ToString())
}
"Map summaries written to $OutDir" | Tee-Object -FilePath (Join-Path $OutDir '_done.txt')
