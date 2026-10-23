#Requires -Version 7.2
# Minimal PDF text extractor: Flate streams, object streams, ToUnicode CMaps. No OCR, no encryption.
param([Parameter(Mandatory)][string]$Path, [switch]$Diagnose)

$ErrorActionPreference = 'Stop'
$latin1 = [Text.Encoding]::Latin1
$raw = $latin1.GetString([IO.File]::ReadAllBytes($Path))
if ($raw -match '/Encrypt\s') { return 'PDF EXTRACT FAILED: the file is encrypted' }

function Expand-Flate([string]$data) {
    $in = [IO.MemoryStream]::new($latin1.GetBytes($data))
    $z = [IO.Compression.ZLibStream]::new($in, [IO.Compression.CompressionMode]::Decompress)
    $out = [IO.MemoryStream]::new()
    # Trailing bytes after the deflate data can throw after a complete decode.
    try { $z.CopyTo($out) } catch { if ($out.Length -eq 0) { return $null } }
    $latin1.GetString($out.ToArray())
}

function ConvertFrom-Utf16Hex([string]$hex) {
    if (-not $hex) { return '' }
    if ($hex.Length % 4) { $hex = $hex.PadLeft($hex.Length + 4 - $hex.Length % 4, '0') }
    [Text.Encoding]::BigEndianUnicode.GetString([Convert]::FromHexString($hex))
}

# Objects: number -> @{ Dict; Stream }
$objects = @{}
foreach ($m in [regex]::Matches($raw, '(?s)(\d+)\s+\d+\s+obj\b(.*?)\bendobj')) {
    $body = $m.Groups[2].Value
    $dict = $body
    $stream = $null
    $sm = [regex]::Match($body, '(?s)^(.*?)\bstream\r?\n(.*)\bendstream')
    if ($sm.Success) {
        $dict = $sm.Groups[1].Value
        if ($dict -match '/FlateDecode') { $stream = Expand-Flate $sm.Groups[2].Value }
        elseif ($dict -notmatch '/Filter') { $stream = $sm.Groups[2].Value }
    }
    $objects[[int]$m.Groups[1].Value] = @{ Dict = $dict; Stream = $stream }
}

foreach ($o in @($objects.Values)) {
    if ($o.Dict -notmatch '/Type\s*/ObjStm' -or -not $o.Stream) { continue }
    $n = [int]([regex]::Match($o.Dict, '/N\s+(\d+)').Groups[1].Value)
    $first = [int]([regex]::Match($o.Dict, '/First\s+(\d+)').Groups[1].Value)
    $nums = @([regex]::Matches($o.Stream.Substring(0, $first), '\d+') | ForEach-Object { [int]$_.Value })
    for ($i = 0; $i -lt $n; $i++) {
        $start = $first + $nums[2 * $i + 1]
        $end = if ($i + 1 -lt $n) { $first + $nums[2 * $i + 3] } else { $o.Stream.Length }
        if (-not $objects.ContainsKey($nums[2 * $i])) {
            $objects[$nums[2 * $i]] = @{ Dict = $o.Stream.Substring($start, $end - $start); Stream = $null }
        }
    }
}

function Get-Obj([int]$num) { if ($objects.ContainsKey($num)) { $objects[$num] } else { @{ Dict = ''; Stream = $null } } }

function Read-CMap([string]$s) {
    $map = @{}
    $width = 2
    $cs = [regex]::Match($s, 'begincodespacerange\s*<([0-9A-Fa-f]+)>')
    if ($cs.Success) { $width = $cs.Groups[1].Value.Length / 2 }
    foreach ($b in [regex]::Matches($s, '(?s)beginbfchar(.*?)endbfchar')) {
        foreach ($p in [regex]::Matches($b.Groups[1].Value, '<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]*)>')) {
            $map[[Convert]::ToInt32($p.Groups[1].Value, 16)] = ConvertFrom-Utf16Hex $p.Groups[2].Value
        }
    }
    foreach ($b in [regex]::Matches($s, '(?s)beginbfrange(.*?)endbfrange')) {
        foreach ($p in [regex]::Matches($b.Groups[1].Value, '<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(<[0-9A-Fa-f]*>|\[[^\]]*\])')) {
            $lo = [Convert]::ToInt32($p.Groups[1].Value, 16)
            $hi = [Math]::Min([Convert]::ToInt32($p.Groups[2].Value, 16), $lo + 65535)
            $dst = $p.Groups[3].Value
            if ($dst.StartsWith('[')) {
                $items = [regex]::Matches($dst, '<([0-9A-Fa-f]*)>')
                for ($c = $lo; $c -le $hi -and ($c - $lo) -lt $items.Count; $c++) { $map[$c] = ConvertFrom-Utf16Hex $items[$c - $lo].Groups[1].Value }
            }
            else {
                $baseText = ConvertFrom-Utf16Hex $dst.Trim('<', '>')
                if (-not $baseText) { continue }
                $prefix = $baseText.Substring(0, $baseText.Length - 1)
                $last = [int]$baseText[-1]
                for ($c = $lo; $c -le $hi; $c++) { $map[$c] = $prefix + [char]($last + $c - $lo) }
            }
        }
    }
    @{ Map = $map; Width = $width }
}

# Font resource name -> decoder. First definition of a name wins.
$fontByName = @{}
$fontCache = @{}
function Get-FontDecoder([int]$fontNum) {
    if ($fontCache.ContainsKey($fontNum)) { return $fontCache[$fontNum] }
    $dec = $null
    $tu = [regex]::Match((Get-Obj $fontNum).Dict, '/ToUnicode\s+(\d+)\s+\d+\s+R')
    if ($tu.Success) {
        $cm = (Get-Obj ([int]$tu.Groups[1].Value)).Stream
        if ($cm) { $dec = Read-CMap $cm }
    }
    $fontCache[$fontNum] = $dec
    $dec
}
foreach ($o in $objects.Values) {
    $fontDicts = [System.Collections.Generic.List[string]]::new()
    foreach ($fm in [regex]::Matches($o.Dict, '/Font\s*<<([^>]*)>>')) { $fontDicts.Add($fm.Groups[1].Value) }
    foreach ($fm in [regex]::Matches($o.Dict, '/Font\s+(\d+)\s+\d+\s+R')) { $fontDicts.Add((Get-Obj ([int]$fm.Groups[1].Value)).Dict) }
    foreach ($fd in $fontDicts) {
        foreach ($e in [regex]::Matches($fd, '/([^\s/<>\[\]()]+)\s+(\d+)\s+\d+\s+R')) {
            if (-not $fontByName.ContainsKey($e.Groups[1].Value)) { $fontByName[$e.Groups[1].Value] = Get-FontDecoder ([int]$e.Groups[2].Value) }
        }
    }
}

function ConvertFrom-PdfString([string]$s, $font) {
    if (-not $font -or $font.Map.Count -eq 0) { return $s }
    $sb = [Text.StringBuilder]::new()
    for ($k = 0; $k + $font.Width -le $s.Length; $k += $font.Width) {
        $code = 0
        for ($b = 0; $b -lt $font.Width; $b++) { $code = ($code -shl 8) -bor [int]$s[$k + $b] }
        if ($font.Map.ContainsKey($code)) { [void]$sb.Append($font.Map[$code]) }
    }
    $sb.ToString()
}

$rxNum = [regex]'\G[+-]?(?:\d+\.?\d*|\.\d+)'
$rxName = [regex]'\G/[^\s/\[\]()<>{}%]*'
$rxOp = [regex]'\G[A-Za-z''"*]+'

function Read-Literal([string]$c, [int]$i) {
    $sb = [Text.StringBuilder]::new()
    $depth = 1
    $i++
    while ($i -lt $c.Length) {
        $ch = $c[$i]
        if ($ch -eq [char]'\') {
            $i++
            $n = $c[$i]
            if ([int]$n -ge 48 -and [int]$n -le 55) {
                $oct = ''
                while ($oct.Length -lt 3 -and [int]$c[$i] -ge 48 -and [int]$c[$i] -le 55) { $oct += $c[$i]; $i++ }
                [void]$sb.Append([char][Convert]::ToInt32($oct, 8))
                continue
            }
            if ($n -ceq [char]'n') { [void]$sb.Append("`n") }
            elseif ($n -ceq [char]'t') { [void]$sb.Append("`t") }
            elseif ('rbf'.IndexOf($n) -ge 0 -or $n -eq "`r" -or $n -eq "`n") { }
            else { [void]$sb.Append($n) }
            $i++
            continue
        }
        if ($ch -eq [char]'(') { $depth++ }
        elseif ($ch -eq [char]')') { $depth--; if ($depth -eq 0) { $i++; break } }
        [void]$sb.Append($ch)
        $i++
    }
    , @($sb.ToString(), $i)
}

function Get-ContentText([string]$c) {
    $sb = [Text.StringBuilder]::new()
    $font = $null
    $ops = [System.Collections.Generic.List[object]]::new()
    $lastY = $null
    $i = 0
    $len = $c.Length
    while ($i -lt $len) {
        $ch = $c[$i]
        if ([char]::IsWhiteSpace($ch)) { $i++; continue }
        if ($ch -eq [char]'%') { while ($i -lt $len -and $c[$i] -ne "`n" -and $c[$i] -ne "`r") { $i++ }; continue }
        if ($ch -eq [char]'(') { $r = Read-Literal $c $i; $ops.Add($r[0]); $i = $r[1]; continue }
        if ($ch -eq [char]'<') {
            if ($i + 1 -lt $len -and $c[$i + 1] -eq [char]'<') { $j = $c.IndexOf('>>', $i); $i = if ($j -lt 0) { $len } else { $j + 2 }; continue }
            $j = $c.IndexOf('>', $i)
            $hex = $c.Substring($i + 1, $j - $i - 1) -replace '\s', ''
            if ($hex.Length % 2) { $hex += '0' }
            $ops.Add($latin1.GetString([Convert]::FromHexString($hex)))
            $i = $j + 1
            continue
        }
        if ($ch -eq [char]'[') {
            $arr = [System.Collections.Generic.List[object]]::new()
            $i++
            while ($i -lt $len -and $c[$i] -ne [char]']') {
                $a = $c[$i]
                if ([char]::IsWhiteSpace($a)) { $i++; continue }
                if ($a -eq [char]'(') { $r = Read-Literal $c $i; $arr.Add($r[0]); $i = $r[1]; continue }
                if ($a -eq [char]'<') {
                    $j = $c.IndexOf('>', $i)
                    $hex = $c.Substring($i + 1, $j - $i - 1) -replace '\s', ''
                    if ($hex.Length % 2) { $hex += '0' }
                    $arr.Add($latin1.GetString([Convert]::FromHexString($hex)))
                    $i = $j + 1
                    continue
                }
                $nm = $rxNum.Match($c, $i)
                if ($nm.Success) { $arr.Add([double]$nm.Value); $i += $nm.Length; continue }
                $i++
            }
            $i++
            $ops.Add($arr)
            continue
        }
        if ($ch -eq [char]'/') { $nm = $rxName.Match($c, $i); $ops.Add([pscustomobject]@{ Name = $nm.Value.Substring(1) }); $i += [Math]::Max($nm.Length, 1); continue }
        $nm = $rxNum.Match($c, $i)
        if ($nm.Success) { $ops.Add([double]$nm.Value); $i += $nm.Length; continue }
        $om = $rxOp.Match($c, $i)
        if (-not $om.Success) { $i++; continue }
        $op = $om.Value
        $i += $om.Length
        # Plain assignment: an if-expression would unroll a TJ array.
        $last = $null
        if ($ops.Count) { $last = $ops[$ops.Count - 1] }
        switch -CaseSensitive ($op) {
            'Tf' { if ($ops.Count -ge 2 -and $ops[$ops.Count - 2].Name) { $font = $fontByName[$ops[$ops.Count - 2].Name] } }
            'Tj' { if ($last -is [string]) { [void]$sb.Append((ConvertFrom-PdfString $last $font)) } }
            { $_ -eq "'" -or $_ -eq '"' } { [void]$sb.Append("`n"); if ($last -is [string]) { [void]$sb.Append((ConvertFrom-PdfString $last $font)) } }
            'TJ' {
                if ($last -is [System.Collections.Generic.List[object]]) {
                    foreach ($e in $last) {
                        if ($e -is [string]) { [void]$sb.Append((ConvertFrom-PdfString $e $font)) }
                        elseif ($e -lt -180) { [void]$sb.Append(' ') }
                    }
                }
            }
            { $_ -eq 'Td' -or $_ -eq 'TD' } {
                if ($ops.Count -ge 2 -and $last -is [double]) {
                    if ([Math]::Abs($last) -gt 0.5) { [void]$sb.Append("`n") } else { [void]$sb.Append(' ') }
                }
            }
            'T*' { [void]$sb.Append("`n") }
            'Tm' {
                if ($ops.Count -ge 6 -and $last -is [double]) {
                    if ($null -ne $lastY -and [Math]::Abs($last - $lastY) -gt 0.5) { [void]$sb.Append("`n") } elseif ($null -ne $lastY) { [void]$sb.Append(' ') }
                    $lastY = $last
                }
            }
            'BI' { $j = $c.IndexOf('EI', $i); $i = if ($j -lt 0) { $len } else { $j + 2 } }
        }
        $ops.Clear()
    }
    $sb.ToString()
}

# Page order from the page tree. Fall back to every stream with text operators.
$pageContents = [System.Collections.Generic.List[int[]]]::new()
function Add-PageNode([int]$num, [int]$depth) {
    if ($depth -gt 50) { return }
    $d = (Get-Obj $num).Dict
    $kids = [regex]::Match($d, '/Kids\s*\[([^\]]*)\]')
    if ($kids.Success) {
        foreach ($k in [regex]::Matches($kids.Groups[1].Value, '(\d+)\s+\d+\s+R')) { Add-PageNode ([int]$k.Groups[1].Value) ($depth + 1) }
        return
    }
    $cm = [regex]::Match($d, '/Contents\s*(\[[^\]]*\]|\d+\s+\d+\s+R)')
    if ($cm.Success) {
        $pageContents.Add(@([regex]::Matches($cm.Groups[1].Value, '(\d+)\s+\d+\s+R') | ForEach-Object { [int]$_.Groups[1].Value }))
    }
}
$root = [regex]::Match(($objects.Values | Where-Object { $_.Dict -match '/Type\s*/Catalog' } | Select-Object -First 1).Dict, '/Pages\s+(\d+)\s+\d+\s+R')
if ($root.Success) { Add-PageNode ([int]$root.Groups[1].Value) 0 }
if ($pageContents.Count -eq 0) {
    foreach ($k in ($objects.Keys | Sort-Object)) {
        $s = $objects[$k].Stream
        if ($s -and $s -match '\bBT\b' -and $s -match '\bT[fjJ]\b') { $pageContents.Add(@($k)) }
    }
}

$out = [Text.StringBuilder]::new()
if ($Diagnose) {
    [void]$out.AppendLine("Objects: $($objects.Count); pages: $($pageContents.Count)")
    foreach ($k in $fontByName.Keys) { [void]$out.AppendLine("Font $k -> " + $(if ($fontByName[$k]) { "map $($fontByName[$k].Map.Count), width $($fontByName[$k].Width)" } else { 'no ToUnicode' })) }
    foreach ($k in ($objects.Keys | Sort-Object)) {
        $d = $objects[$k].Dict
        if ($d -match '/Type\s*/Font\b') { [void]$out.AppendLine("Obj $k font dict: " + ($d.Trim() -replace '\s+', ' ').Substring(0, [Math]::Min(200, $d.Trim().Length))) }
    }
    if ($pageContents.Count) {
        $s = (Get-Obj $pageContents[0][0]).Stream
        [void]$out.AppendLine('First content stream: ' + $(if ($s) { ($s.Substring(0, [Math]::Min(800, $s.Length)) -replace '[^\x20-\x7E\r\n]', '?') } else { 'NULL' }))
    }
    return $out.ToString()
}
$page = 0
foreach ($refs in $pageContents) {
    $page++
    [void]$out.AppendLine("--- page $page ---")
    $content = ($refs | ForEach-Object { (Get-Obj $_).Stream }) -join "`n"
    if ($content) { [void]$out.AppendLine((Get-ContentText $content)) }
}
$text = $out.ToString()
if (($text -replace '--- page \d+ ---|\s', '').Length -lt 20) { $text += "`nNO TEXT FOUND: the PDF can be a scanned image" }
$text
