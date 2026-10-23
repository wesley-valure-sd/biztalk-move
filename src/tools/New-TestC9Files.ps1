#Requires -Version 7
# Makes TestC9 test files from production BBVA patient 835 samples. Replaces every identifier,
# name, and bank number, keeps the structure, and fails if a source value survives.
param(
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$OutDir,
    # One "patGUID|ppGUID|patID" per sample that has NM109 values, in file-name order.
    [Parameter(Mandatory)][string[]]$TestPatients
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$files = Get-ChildItem $SourceDir -Filter *.835 | Sort-Object Name
$patientIndex = 0
$fileIndex = 0
$report = foreach ($f in $files) {
    $fileIndex++
    $text = [IO.File]::ReadAllText($f.FullName)
    $sep = $text[3]
    $term = $text[105]
    $segments = $text -split [regex]::Escape([string]$term) | ForEach-Object { $_.Trim("`r", "`n") } | Where-Object { $_ }
    $hasGuids = [bool]($segments | Where-Object { ($_ -split [regex]::Escape([string]$sep))[0] -eq 'NM1' -and ($_ -split [regex]::Escape([string]$sep))[1] -eq 'QC' -and ($_ -split [regex]::Escape([string]$sep))[9] })
    $patient = if ($hasGuids) { $TestPatients[$patientIndex++] -split '\|' } else { $null }
    $secrets = [System.Collections.Generic.Dictionary[string, string]]::new()

    $out = foreach ($s in $segments) {
        $e = [System.Collections.Generic.List[string]]($s -split [regex]::Escape([string]$sep))
        $set = { param($i, $v) if ($e.Count -le $i -or -not $e[$i]) { return }; if ($e[$i].Length -ge 3 -and $e[$i] -ne $v) { $secrets[$e[$i]] = '{0}{1:D2}' -f $e[0], $i }; $e[$i] = $v }
        switch ($e[0]) {
            'BPR' { & $set 7 '111000025'; & $set 9 '000123'; & $set 10 '1999999999'; & $set 13 '222000025'; & $set 15 '000456' }
            'TRN' {
                $orig = $e[2]
                $digits = ([string]$fileIndex).PadLeft([Math]::Max($orig.Length, 2), '7')
                if ($orig.StartsWith('0')) { $digits = '0' + $digits.Substring(1) }
                & $set 2 $digits; & $set 3 '1999999999'
            }
            'REF' {
                switch ($e[1]) {
                    'LB' { & $set 2 ($e[2] -replace '(?<=[A-Z]{3}-)\d{6}', '000001') }
                    'F8' { & $set 2 ('EOB9' + ([string]$fileIndex).PadLeft(7, '0')) }
                    'TJ' { & $set 2 '000000000' }
                    default { & $set 2 ('TEST' + $e[1]) }
                }
            }
            'N1' { if ($e[1] -eq 'PR') { & $set 2 'TEST PAYER' } elseif ($e.Count -gt 4) { & $set 4 '1234567890' } }
            'N3' { if ($e[1] -ne 'NOT PROVIDED') { & $set 1 'TEST STREET' } }
            'N4' { if ($e[1] -ne 'DEFAULT CITY') { & $set 1 'TEST CITY'; & $set 3 '00000' } }
            'PER' { & $set 2 'TEST CONTACT'; for ($i = 3; $i -lt $e.Count; $i++) { if ($e[$i]) { & $set $i '' } } }
            'TS3' { & $set 1 '1234567890' }
            'CLP' { & $set 1 ($(if ($patient) { $patient[2] } else { 'TST000000' })); if ($e.Count -gt 7 -and $e[7]) { & $set 7 'TEST' } }
            'NM1' {
                switch ($e[1]) {
                    'QC' { & $set 3 'TEST'; & $set 4 'PATIENT'; if ($e.Count -gt 9 -and $e[9]) { & $set 9 $patient[0] } }
                    'IL' { & $set 3 'TEST'; & $set 4 'PARENT'; if ($e.Count -gt 9 -and $e[9]) { & $set 9 $patient[1] } }
                    default { if ($e.Count -gt 9 -and $e[9]) { & $set 9 '1234567890' } }
                }
            }
        }
        $e -join $sep
    }

    $result = ($out -join "$term`r`n") + "$term`r`n"
    $outElements = [System.Collections.Generic.HashSet[string]]::new([string[]]@($out | ForEach-Object { $_ -split [regex]::Escape([string]$sep) }))
    $isLeak = { param($v) $outElements.Contains($v) -or ($v.Length -ge 6 -and $result.Contains($v)) }
    # Source values that are placeholders themselves (one repeated digit, or a placeholder word) are not leaks.
    $placeholder = { param($v) $v -match '^(\d)\1*$' -or $v -in 'NOT PROVIDED', 'DEFAULT CITY', 'SMILE DOCTORS', 'PATIENT', 'PARENT', 'TEST' }
    $leaks = @($secrets.Keys | Where-Object { -not (& $placeholder $_) -and (& $isLeak $_) })
    if ($leaks.Count) {
        $where = foreach ($leak in $leaks) {
            foreach ($line in $out) { $p = $line -split [regex]::Escape([string]$sep); for ($i = 1; $i -lt $p.Count; $i++) { if ($p[$i] -eq $leak -or ($leak.Length -ge 6 -and $p[$i].Contains($leak))) { "$($secrets[$leak]) -> $($p[0])$('{0:D2}' -f $i)" } } }
        }
        throw "$($f.Name): $($leaks.Count) source values remain at $((@($where) | Select-Object -Unique) -join ', '). File not written."
    }
    $name = $f.Name -replace 'GULFCOAST', 'TESTC9'
    [IO.File]::WriteAllText((Join-Path $OutDir $name), $result)
    [pscustomobject]@{ File = $name; Guids = $hasGuids; Replaced = $secrets.Count }
}
$report | Format-Table -AutoSize | Out-String
