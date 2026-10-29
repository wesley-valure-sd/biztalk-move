#Requires -Version 7
<#
.SYNOPSIS
    Makes the read-only SSMS script that compares the POC result with the BizTalk result.
.DESCRIPTION
    -Target Test: reads the TESTC9 patient test files (src\testdata\Patient\TESTC9). Writes src\sql\C9-T.verify-poc-run.sql. Run it on C9-T after the POC run.
                  The last result set has a PASS or FAIL for each scenario.
    -Target Prod: reads the production sample files (BBVA patient 835). Writes the script OUTSIDE the repo by default.
                  Run it on C9-P (PROD). It shows the BizTalk result for the same scenarios. It never prints production data here.
    The script holds the payment reference (REF*F8) and the trace number (TRN02) of each file. Treat the Prod script as sensitive.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Test', 'Prod')][string]$Target,
    [string]$SourceDir,
    # The practice database that holds dbo.ImportLog and dbo.[Transaction].
    [string]$Database,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$src = Split-Path $PSScriptRoot -Parent
$repo = Split-Path $src -Parent
if (-not $SourceDir) { $SourceDir = if ($Target -eq 'Test') { Join-Path $src 'testdata\Patient\TESTC9' } else { Join-Path $repo 'references\SampleInputFiles\BBVA_835\Patient\GULFCOAST' } }
if (-not $Database) { $Database = if ($Target -eq 'Test') { 'TestC9' } else { 'GULFCOAST' } }
if (-not $OutFile) { $OutFile = if ($Target -eq 'Test') { Join-Path $src 'sql\C9-T.verify-poc-run.sql' } else { Join-Path $env:TEMP 'C9-P.read-biztalk-results.sql' } }
if ($Database -notmatch '^[A-Za-z0-9_-]+$') { throw "Database '$Database' is not a plain name." }

$values = foreach ($f in Get-ChildItem $SourceDir -Filter *.835 | Sort-Object Name) {
    $text = [IO.File]::ReadAllText($f.FullName)
    $sep = [string]$text[3]
    $term = [string]$text[105]
    $segments = $text -split [regex]::Escape($term) | ForEach-Object { $_.Trim("`r", "`n") } | Where-Object { $_ }
    $split = { param($s) $s -split [regex]::Escape($sep) }

    $clp = @($segments | Where-Object { $_.StartsWith("CLP$sep") })
    if ($clp.Count -ne 1) { throw "$($f.Name): expected one CLP, found $($clp.Count)." }
    $trn = & $split ($segments | Where-Object { $_.StartsWith("TRN$sep") } | Select-Object -First 1)
    $f8 = & $split ($segments | Where-Object { $_.StartsWith("REF${sep}F8$sep") } | Select-Object -First 1)
    $qc = $segments | Where-Object { $_.StartsWith("NM1${sep}QC$sep") } | Select-Object -First 1
    $hasGuid = [bool]($qc -and (& $split $qc).Count -gt 9 -and (& $split $qc)[9])

    $label = ($f.BaseName -split '_')[-1]
    $trace = $trn[2]
    $ref = $f8[2]
    $amount = [decimal]::Parse((& $split $clp[0])[4], [Globalization.CultureInfo]::InvariantCulture)
    if ($label -notmatch '^[A-Za-z0-9]+$') { throw "$($f.Name): label '$label' is not a plain name." }
    if ($trace -notmatch '^[A-Za-z0-9._-]+$') { throw "$($f.Name): TRN02 is not a plain value." }
    if ($ref -notmatch '^[A-Za-z0-9._-]+$') { throw "$($f.Name): REF*F8 is not a plain value." }

    "    (N'$label', '$ref', N'$trace', $($amount.ToString([Globalization.CultureInfo]::InvariantCulture)), N'$(if ($hasGuid) { 'Finished' } else { 'Failed' })')"
}
if (-not $values) { throw "No .835 files in $SourceDir." }

$result = if ($Target -eq 'Test') {
    @'
-- PASS needs: one ImportLog row in the right state, one [Transaction] row (or none and one UnmappedTransaction row for a Failed file),
-- the amounts equal to the file, is_group 0, and the check number equal to TRN02. The status column is not compared (the end-of-day run changes N to D).
SELECT r.*,
    CASE WHEN r.expected_state = N'Finished' THEN
            CASE WHEN r.import_rows = 1 AND r.il_state = N'Finished' AND r.il_level = 2
                      AND r.il_process = N'Process_BBVA_835Patient' AND r.il_file_name_only = 1 AND r.il_msg_tail = N'Success'
                      AND r.txn_rows = 1 AND r.txn_amount = -r.file_amount AND r.due_now = -r.file_amount AND r.total_due = -r.file_amount
                      AND r.is_group = N'0' AND r.check_no_ok = 1 AND r.posted_equals_trans = 1 AND r.ut_rows = 0
                 THEN N'PASS' ELSE N'FAIL' END
         ELSE
            CASE WHEN r.import_rows = 1 AND r.il_state = N'Failed' AND r.il_level = 0
                      AND r.il_msg_tail LIKE N'Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL;%'
                      AND r.txn_rows = 0 AND r.ut_rows = 1
                 THEN N'PASS' ELSE N'FAIL' END
    END AS result
FROM #R r
ORDER BY r.label;
'@
}
else {
    'SELECT * FROM #R ORDER BY label;'
}

$body = [IO.File]::ReadAllText((Join-Path $src 'sql\poc-compare.body.sql'))
$sql = $body.Replace('{{USE}}', "USE [$Database];").Replace('{{VALUES}}', ($values -join ",`r`n")).Replace('{{RESULT}}', $result)
[IO.File]::WriteAllText($OutFile, $sql, [Text.UTF8Encoding]::new($true))
"Wrote $OutFile ($(@($values).Count) scenarios, database [$Database])."
