#Requires -Version 7
<#
.SYNOPSIS
    Makes the TESTC9 insurance (flow C) test files from production BBVA insurance 835 samples.
.DESCRIPTION
    Reads src\testdata\Insurance\scenarios.csv. For each scenario, reads the source file from -SourceDir, replaces every
    identifier, name, and bank number, keeps amounts, dates, codes, and structure, and writes
    src\testdata\Insurance\TESTC9\SDOC_<date>_TESTC9_<Id>.835. A file is not written if a source value survives.

    Masked values keep their shape (digit count, letters, separators), because shape drives some scenarios:
    CLP01 longer than int, CLP01 not numeric, TRN02 of 15 digits. REF*LB keeps the DTM*405 date (GetLockboxNumber removes it).

    Identity column of scenarios.csv:
      valid       REF*EJ, REF*69, NM1*QC NM109, and CLP01 get a TestC9 identity from -IdentityFile.
      unknownPip  Same as valid, but REF*69 gets a GUID that is not in the practice database.
      mask        GUIDs get a TestC9 identity. CLP01 keeps its shape (overflow or not numeric).
      none        CLP01 keeps its shape. The file has no REF*EJ or REF*69.
.PARAMETER SourceDir
    Production samples. Default references\SampleInputFiles\BBVA_835\Insurance\GULFCOAST (git ignores it).
.PARAMETER IdentityFile
    CSV with columns patGUID, pipGUID, pipPolicyNumber, adaClaimNumber. Make it with src\sql\C9-T.insurance-test-identities.sql.
    Without it, placeholder identities are used: the files parse and map, but C9-T cannot find the claims.
.PARAMETER F8Seed
    Changes every REF*F8 value. Use a new value for each C9-T run, or the procedure rejects the payments as duplicates.
#>
param(
    [string]$SourceDir,
    [string]$OutDir,
    [string]$ScenarioFile,
    [string]$IdentityFile,
    [int]$F8Seed = 0
)

$ErrorActionPreference = 'Stop'
$src = Split-Path $PSScriptRoot -Parent
$repo = Split-Path $src -Parent
if (-not $SourceDir) { $SourceDir = Join-Path $repo 'references\SampleInputFiles\BBVA_835\Insurance\GULFCOAST' }
if (-not $OutDir) { $OutDir = Join-Path $src 'testdata\Insurance\TESTC9' }
if (-not $ScenarioFile) { $ScenarioFile = Join-Path $src 'testdata\Insurance\scenarios.csv' }

$identities = if ($IdentityFile) { @(Import-Csv $IdentityFile) } else {
    Write-Warning 'No -IdentityFile. Placeholder identities are used. C9-T cannot find these claims.'
    @([pscustomobject]@{ patGUID = '00000000-0000-0000-0000-000000000001'; pipGUID = '00000000-0000-0000-0000-000000000002'; pipPolicyNumber = 'TESTPOLICY1'; adaClaimNumber = '900000001' })
}
$g = [guid]::Empty
foreach ($i in $identities) {
    if (-not ([guid]::TryParse($i.patGUID, [ref]$g) -and [guid]::TryParse($i.pipGUID, [ref]$g))) { throw "Identity '$($i.adaClaimNumber)' has a bad GUID." }
    if ($i.adaClaimNumber -notmatch '^\d{1,9}$') { throw "Identity adaClaimNumber '$($i.adaClaimNumber)' is not an int." }
}
$unknownPip = '0BADC0DE-0000-4000-8000-000000000069'

$md5 = [Security.Cryptography.MD5]::Create()
# Same input, same output. Digits stay digits and letters stay letters. The result never equals the input.
function Get-Masked([string]$value, [string]$salt, [string]$keep = '') {
    if (-not $value) { return $value }
    $parts = if ($keep -and $value.Contains($keep)) { $value -split [regex]::Escape($keep) } else { , $value }
    $masked = foreach ($part in $parts) {
        $seed = [BitConverter]::ToInt32($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("$salt|$part")), 0)
        $rng = [Random]::new($seed)
        $chars = foreach ($ch in $part.ToCharArray()) {
            if ([char]::IsDigit($ch)) { [char](48 + $rng.Next(10)) }
            elseif ([char]::IsLetter($ch)) { [char](65 + $rng.Next(26)) }
            else { $ch }
        }
        $out = -join $chars
        if ($out -eq $part -and $part -match '[0-9A-Za-z]') { $out = Get-Masked $part "$salt+" }
        $out
    }
    $masked -join $keep
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$scenarios = Import-Csv $ScenarioFile
$written = @{}
$identityIndex = 0
$claimIndex = 0
$report = foreach ($sc in $scenarios | Where-Object { -not $_.CopyOf }) {
    $path = Join-Path $SourceDir $sc.Source
    if (-not (Test-Path $path)) { throw "$($sc.Id): source file '$($sc.Source)' is not in $SourceDir." }
    $text = [IO.File]::ReadAllText($path)
    $sep = [string]$text[3]; $comp = [string]$text[104]; $term = [string]$text[105]
    $segments = $text -split [regex]::Escape($term) | ForEach-Object { $_.Trim("`r", "`n") } | Where-Object { $_ }
    $secrets = [Collections.Generic.Dictionary[string, string]]::new()
    $depositDate = ($segments | Where-Object { $_ -like "DTM$($sep)405$($sep)*" } | Select-Object -First 1) -split [regex]::Escape($sep) | Select-Object -Index 2
    $identity = $null
    $f8Count = 0

    $out = foreach ($s in $segments) {
        $e = [Collections.Generic.List[string]]($s -split [regex]::Escape($sep))
        $set = { param($i, $v) if ($e.Count -le $i -or -not $e[$i]) { return }; if ($e[$i].Length -ge 3 -and $e[$i] -ne $v) { $secrets[$e[$i]] = '{0}{1:D2}' -f $e[0], $i }; $e[$i] = $v }
        $mask = { param($i, $keep = '') if ($e.Count -gt $i -and $e[$i]) { & $set $i (Get-Masked $e[$i] "$($sc.Id)|$($e[0])$i" $keep) } }
        switch ($e[0]) {
            'BPR' { & $set 7 '111000025'; & $set 9 '000123'; & $set 10 '1999999999'; & $set 13 '222000025'; & $set 15 '000456' }
            'TRN' { & $mask 2; & $set 3 '1999999999'; & $mask 4 }
            'TS3' { & $set 1 '1234567890' }
            'N1' { if ($e[1] -eq 'PR') { & $set 2 'TEST PAYER' } else { & $set 2 'TEST PAYEE' }; if ($e.Count -gt 4) { & $set 4 '1234567890' } }
            'N3' { & $set 1 'TEST STREET'; & $set 2 '' }
            'N4' { & $set 1 'TEST CITY'; & $set 3 '00000' }
            'PER' { & $set 2 'TEST CONTACT'; for ($i = 3; $i -lt $e.Count; $i++) { if ($e[$i] -and $i % 2 -eq 0) { & $set $i '' } } }
            'PLB' {
                & $set 1 '1234567890'
                for ($i = 3; $i -lt $e.Count; $i += 2) {
                    $c = $e[$i] -split [regex]::Escape($comp)
                    if ($c.Count -gt 1 -and $c[1]) {
                        if ($c[1].Length -ge 3) { $secrets[$c[1]] = "PLB$('{0:D2}' -f $i)-2" }
                        & $set $i ($c[0] + $comp + (Get-Masked $c[1] "$($sc.Id)|PLB$i"))
                    }
                }
            }
            'CLP' {
                $claimIndex++
                $identity = $identities[$identityIndex++ % $identities.Count]
                if ($sc.Identity -in 'valid', 'unknownPip') { & $set 1 $identity.adaClaimNumber } else { & $mask 1 }
                & $mask 7
            }
            'NM1' {
                switch ($e[1]) {
                    'QC' { & $set 3 'TEST'; & $set 4 'PATIENT'; & $set 5 ''; if ($e.Count -gt 9 -and $e[9]) { & $set 9 $identity.pipPolicyNumber } }
                    'IL' { & $set 3 'TEST'; & $set 4 'SUBSCRIBER'; & $set 5 ''; & $mask 9 }
                    default { & $set 3 'TEST'; & $set 4 'PROVIDER'; & $set 5 ''; if ($e.Count -gt 9 -and $e[9]) { & $set 9 '1234567890' } }
                }
            }
            'REF' {
                switch ($e[1]) {
                    'EJ' { if ($sc.Identity -eq 'none') { throw "$($sc.Id): Identity is none, but the file has REF*EJ." }; & $set 2 $identity.patGUID }
                    '69' { if ($sc.Identity -eq 'none') { throw "$($sc.Id): Identity is none, but the file has REF*69." }; & $set 2 ($(if ($sc.Identity -eq 'unknownPip') { $unknownPip } else { $identity.pipGUID })) }
                    'F8' { $f8Count++; & $set 2 ('EOB{0:D2}{1:D2}{2:D4}' -f [int]$sc.Id.Substring(1), $f8Count, $F8Seed) }
                    'LB' { & $set 2 (Get-Masked $e[2] "$($sc.Id)|LB" $depositDate) }
                    'TJ' { & $set 2 '000000000' }
                    default { & $mask 2 }
                }
            }
        }
        $e -join $sep
    }

    $result = ($out -join "$term`r`n") + "$term`r`n"
    # Source values that are placeholders themselves are not leaks: one repeated digit, part of 1234567890, or a placeholder word.
    $placeholder = { param($v) $v -match '^(\d)\1*$' -or ($v -match '^\d+$' -and '1234567890'.Contains($v)) -or $v -in 'NOT PROVIDED', 'DEFAULT CITY', 'SMILE DOCTORS', 'PATIENT', 'TEST' }
    $leaks = @($secrets.Keys | Where-Object { -not (& $placeholder $_) -and $result.Contains($_) })
    if ($leaks.Count) { throw "$($sc.Id): $($leaks.Count) source values remain ($((@($leaks | ForEach-Object { $secrets[$_] }) | Select-Object -Unique) -join ', ')). File not written." }

    $date = if ($sc.Source -match '_(\d{8})_') { $Matches[1] } else { $depositDate }
    $name = "SDOC_${date}_TESTC9_$($sc.Id).835"
    [IO.File]::WriteAllText((Join-Path $OutDir $name), $result)
    $written[$sc.Id] = @{ Name = $name; Text = $result; Date = $date }
    [pscustomobject]@{ Id = $sc.Id; File = $name; Identity = $sc.Identity; Replaced = $secrets.Count }
}
foreach ($sc in $scenarios | Where-Object { $_.CopyOf }) {
    $from = $written[$sc.CopyOf]
    if (-not $from) { throw "$($sc.Id): CopyOf '$($sc.CopyOf)' was not written." }
    $name = "SDOC_$($from.Date)_TESTC9_$($sc.Id).835"
    [IO.File]::WriteAllText((Join-Path $OutDir $name), $from.Text)
    $report += [pscustomobject]@{ Id = $sc.Id; File = $name; Identity = "copy of $($sc.CopyOf)"; Replaced = 0 }
}
$report | Format-Table -AutoSize | Out-String
"Identities used: $([Math]::Min($identityIndex, $identities.Count)) of $($identities.Count) ($identityIndex claims)."
