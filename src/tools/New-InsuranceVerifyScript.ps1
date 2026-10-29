#Requires -Version 7
<#
.SYNOPSIS
    Makes the read-only SSMS script that checks a C9-T run of the insurance scenario files (flow C).
.DESCRIPTION
    Reads src\testdata\Insurance\TESTC9\*.835 and the Expect column of src\testdata\Insurance\scenarios.csv. Writes
    src\sql\C9-T.verify-insurance-run.sql. Run it on C9-T after `lockbox run src\testdata\Insurance`. The last result set
    has PASS or FAIL for each scenario.

    The expected amounts and references come from the files, not from the POC mapper. The expected states and messages
    come from the BizTalk result of each scenario (scenarios.csv). Expect syntax, one item for each post in file order
    (claims of each transaction set, then its PLB adjustments), separated by ';':
      F                 the post is Finished (level 2)
      X:<like>          the post is Failed (level 0) and ilMessage matches the LIKE pattern
      ADJ F, ADJ X:...  the same, for a PLB adjustment (message prefix 'ADJ - ')
      G:<message>       the transaction set fails the CLP/PLB guard: one Failed row with this message, no post
#>
param(
    [string]$SourceDir,
    [string]$ScenarioFile,
    [string]$Database = 'TestC9',
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$src = Split-Path $PSScriptRoot -Parent
if (-not $SourceDir) { $SourceDir = Join-Path $src 'testdata\Insurance\TESTC9' }
if (-not $ScenarioFile) { $ScenarioFile = Join-Path $src 'testdata\Insurance\scenarios.csv' }
if (-not $OutFile) { $OutFile = Join-Path $src 'sql\C9-T.verify-insurance-run.sql' }
if ($Database -notmatch '^[A-Za-z0-9_-]+$') { throw "Database '$Database' is not a plain name." }

$inv = [Globalization.CultureInfo]::InvariantCulture
function Sql([string]$v) { if ($null -eq $v) { 'NULL' } else { "N'" + $v.Replace("'", "''") + "'" } }
function Plain([string]$v, [string]$what, [string]$file) { if ($v -and $v -notmatch '^[A-Za-z0-9._-]+$') { throw "${file}: $what is not a plain value." }; $v }

$expectById = @{}
foreach ($s in Import-Csv $ScenarioFile) { $expectById[$s.Id] = $s.Expect }

$values = foreach ($f in Get-ChildItem $SourceDir -Filter *.835 | Sort-Object Name) {
    $label = ($f.BaseName -split '_')[-1]
    $expect = $expectById[$label]
    if (-not $expect) { throw "$($f.Name): scenario $label has no Expect value." }
    $text = [IO.File]::ReadAllText($f.FullName)
    $sep = [string]$text[3]; $comp = [string]$text[104]; $term = [string]$text[105]
    $segments = @($text -split [regex]::Escape($term) | ForEach-Object { $_.Trim("`r", "`n") } | Where-Object { $_ } | ForEach-Object { , @($_ -split [regex]::Escape($sep)) })

    # Posts in file order: for each transaction set, its claims, then its PLB adjustments.
    $posts = [Collections.Generic.List[object]]::new()
    $guard = $null
    $set = $null
    foreach ($e in $segments) {
        switch ($e[0]) {
            'ST' { $set = @{ Trn = $null; Lx = 0; Claims = [Collections.Generic.List[object]]::new(); Plbs = [Collections.Generic.List[object]]::new(); Claim = $null } }
            'TRN' { $set.Trn = $e[2] }
            'LX' { $set.Lx++ }
            'CLP' { $set.Claim = @{ Amount = [decimal]::Parse($e[4], $inv); F8 = '' }; $set.Claims.Add($set.Claim) }
            'SVC' { $set.Claim = $null }
            'REF' { if ($e[1] -eq 'F8' -and $set.Claim) { $set.Claim.F8 = $e[2] } }
            'PLB' { $set.Plbs.Add(@{ Type = ($e[3] -split [regex]::Escape($comp))[0]; Amount = [decimal]::Parse($e[4], $inv) }) }
            'SE' {
                if (-not ($set.Lx -eq 1 -or $set.Plbs.Count -eq 0)) { $guard = $true }
                else {
                    $trace = Plain $set.Trn 'TRN02' $f.Name
                    foreach ($c in $set.Claims) { $posts.Add(@{ IsAdj = 0; Ext = (Plain $c.F8 'REF*F8' $f.Name); Ref = $trace; Amount = -$c.Amount; L6 = $false }) }
                    $n = 0
                    foreach ($p in $set.Plbs) {
                        $n++
                        $posts.Add(@{ IsAdj = 1; Ext = $set.Claims[0].F8; Ref = "ADJ$n-$trace"; Amount = $p.Amount; L6 = ($p.Type -eq 'L6') })
                    }
                }
                $set = $null
            }
        }
    }

    $items = @($expect -split ';' | ForEach-Object { $_.Trim() })
    if ($guard) {
        if ($items.Count -ne 1 -or -not $items[0].StartsWith('G:')) { throw "$($f.Name): the file fails the guard, but Expect is '$expect'." }
        "    ($(Sql $label), $(Sql $f.Name), 1, 0, NULL, NULL, N'Failed', $(Sql $items[0].Substring(2)), 0, 0, 0, 0)"
        continue
    }
    if ($items.Count -ne $posts.Count) { throw "$($f.Name): $($posts.Count) posts, but Expect has $($items.Count) items." }
    for ($i = 0; $i -lt $posts.Count; $i++) {
        $p = $posts[$i]
        $item = $items[$i]
        $isAdjItem = $item.StartsWith('ADJ ')
        if ($isAdjItem -ne [bool]$p.IsAdj) { throw "$($f.Name): post $($i + 1) is $(if ($p.IsAdj) { 'an adjustment' } else { 'a claim' }), but Expect says '$item'." }
        $body = if ($isAdjItem) { $item.Substring(4) } else { $item }
        $finished = $body -eq 'F'
        if (-not $finished -and -not $body.StartsWith('X:')) { throw "$($f.Name): Expect item '$item' is not F or X:<like>." }
        # A posted L6 makes an L6C row (-amount) and an L6P row (+amount). A failed post makes one UnmappedTransaction row.
        $rows = if (-not $finished) { 0 } elseif ($p.L6) { 2 } else { 1 }
        $sum = if (-not $finished) { 0 } elseif ($p.L6) { 0 } else { $p.Amount }
        $abs = if (-not $finished) { 0 } elseif ($p.L6) { 2 * [Math]::Abs($p.Amount) } else { [Math]::Abs($p.Amount) }
        $ut = if ($finished) { 0 } else { 1 }
        "    ($(Sql $label), $(Sql $f.Name), $($i + 1), $($p.IsAdj), $(Sql $p.Ext), $(Sql $p.Ref), N'$(if ($finished) { 'Finished' } else { 'Failed' })', $(if ($finished) { 'NULL' } else { Sql $body.Substring(2) }), $rows, $($sum.ToString($inv)), $($abs.ToString($inv)), $ut)"
    }
}
if (-not $values) { throw "No .835 files in $SourceDir." }

$sql = @"
/*
    C9-T check of an insurance POC run (flow C). Read-only. Made by src\tools\New-InsuranceVerifyScript.ps1. Do not edit.
    Run on C9-T after: lockbox run src\testdata\Insurance  (with LOCKBOX_SQL_CONNECTION set to the Utility database).
    @since defaults to 60 minutes before the newest ImportLog row of the scenario files. Set it by hand for an older run.
    ImportLog rows are matched by file name. [Transaction] and UnmappedTransaction rows are matched by reference (TRN02 or
    ADJn-TRN02) and a date at or after @since; scenarios that share a reference (I01 and I21) are checked together.
    "Finished" includes "Payment amount exceeds remaining balance. Success".
*/
USE [$Database];
SET NOCOUNT ON;

DECLARE @since DATETIME = (
    SELECT DATEADD(MINUTE, -60, MAX(ilDateTime)) FROM dbo.ImportLog
    WHERE ilProcess = N'Process_BBVA_835Insurance' AND ilFileName LIKE N'SDOC[_]%[_]TESTC9[_]I[0-9][0-9].835');

IF OBJECT_ID('tempdb..#E') IS NOT NULL DROP TABLE #E;
CREATE TABLE #E (
    label NVARCHAR(10) COLLATE DATABASE_DEFAULT, file_name NVARCHAR(250) COLLATE DATABASE_DEFAULT, seq INT, is_adj BIT,
    ext VARCHAR(100) COLLATE DATABASE_DEFAULT, trans_ref NVARCHAR(100) COLLATE DATABASE_DEFAULT, state NVARCHAR(20) COLLATE DATABASE_DEFAULT,
    msg_like NVARCHAR(400) COLLATE DATABASE_DEFAULT, txn_rows INT, txn_sum MONEY, txn_abs MONEY, ut_rows INT);
INSERT INTO #E VALUES
$($values -join ",`r`n");

-- ImportLog rows of this run, by file.
IF OBJECT_ID('tempdb..#IL') IS NOT NULL DROP TABLE #IL;
SELECT il.ilFileName AS file_name, CASE WHEN il.ilMessage LIKE N'ADJ - %' THEN 1 ELSE 0 END AS is_adj,
       ISNULL(il.ilExternalReference, '') AS ext, il.ilExternalReference AS ext_raw, il.ilImportState AS state, il.ilLogLevel AS lvl, il.ilMessage AS msg
INTO #IL
FROM dbo.ImportLog il
WHERE il.ilProcess = N'Process_BBVA_835Insurance' AND il.ilDateTime >= @since AND il.ilFileName IN (SELECT file_name FROM #E);

-- Expected and actual rows by reference, over all scenarios.
IF OBJECT_ID('tempdb..#REF') IS NOT NULL DROP TABLE #REF;
SELECT e.trans_ref, SUM(e.txn_rows) AS exp_rows, SUM(e.txn_sum) AS exp_sum, SUM(e.txn_abs) AS exp_abs, SUM(e.ut_rows) AS exp_ut,
       (SELECT COUNT(*) FROM dbo.[Transaction] t WHERE t.transReference = e.trans_ref AND t.transDateTime >= @since) AS act_rows,
       (SELECT ISNULL(SUM(t.transAmount), 0) FROM dbo.[Transaction] t WHERE t.transReference = e.trans_ref AND t.transDateTime >= @since) AS act_sum,
       (SELECT ISNULL(SUM(ABS(t.transAmount)), 0) FROM dbo.[Transaction] t WHERE t.transReference = e.trans_ref AND t.transDateTime >= @since) AS act_abs,
       (SELECT COUNT(*) FROM dbo.UnmappedTransaction u WHERE u.utReference = e.trans_ref AND u.utDateTime >= @since) AS act_ut
INTO #REF
FROM #E e
WHERE e.trans_ref IS NOT NULL
GROUP BY e.trans_ref;

-- One row for each scenario.
SELECT x.label, x.exp_finished, x.act_finished, x.exp_failed, x.act_failed, x.failed_msg_ok, x.exp_adj, x.act_adj, x.ext_ok, x.refs_ok, x.refs,
       CASE WHEN x.act_finished = x.exp_finished AND x.act_failed = x.exp_failed AND x.failed_msg_ok = x.act_failed
                 AND x.act_adj = x.exp_adj AND x.ext_ok = 1 AND x.refs_ok = x.refs AND x.levels_ok = 1
            THEN N'PASS' ELSE N'FAIL' END AS result
FROM (
    SELECT s.label,
        (SELECT COUNT(*) FROM #E e WHERE e.label = s.label AND e.state = N'Finished') AS exp_finished,
        (SELECT COUNT(*) FROM #IL i WHERE i.file_name = s.file_name AND i.state = N'Finished') AS act_finished,
        (SELECT COUNT(*) FROM #E e WHERE e.label = s.label AND e.state = N'Failed') AS exp_failed,
        (SELECT COUNT(*) FROM #IL i WHERE i.file_name = s.file_name AND i.state = N'Failed') AS act_failed,
        (SELECT COUNT(*) FROM #IL i WHERE i.file_name = s.file_name AND i.state = N'Failed'
            AND EXISTS (SELECT 1 FROM #E e WHERE e.label = s.label AND e.state = N'Failed' AND e.is_adj = i.is_adj AND i.msg LIKE e.msg_like)) AS failed_msg_ok,
        (SELECT COUNT(*) FROM #E e WHERE e.label = s.label AND e.is_adj = 1) AS exp_adj,
        (SELECT COUNT(*) FROM #IL i WHERE i.file_name = s.file_name AND i.is_adj = 1) AS act_adj,
        -- Each post row carries its claim REF*F8 ('' without one); a guard row carries NULL.
        CASE WHEN EXISTS (SELECT 1 FROM #IL i WHERE i.file_name = s.file_name AND (
                    (i.msg LIKE N'There were %' AND i.ext_raw IS NOT NULL)
                 OR (i.msg NOT LIKE N'There were %' AND NOT EXISTS (SELECT 1 FROM #E e WHERE e.label = s.label AND e.is_adj = i.is_adj AND e.ext = i.ext))))
             THEN 0 ELSE 1 END AS ext_ok,
        CASE WHEN EXISTS (SELECT 1 FROM #IL i WHERE i.file_name = s.file_name AND NOT ((i.state = N'Finished' AND i.lvl = 2) OR (i.state = N'Failed' AND i.lvl = 0)))
             THEN 0 ELSE 1 END AS levels_ok,
        (SELECT COUNT(DISTINCT e.trans_ref) FROM #E e WHERE e.label = s.label AND e.trans_ref IS NOT NULL) AS refs,
        (SELECT COUNT(*) FROM #REF r WHERE r.trans_ref IN (SELECT e.trans_ref FROM #E e WHERE e.label = s.label)
            AND r.act_rows = r.exp_rows AND r.act_sum = r.exp_sum AND r.act_abs = r.exp_abs AND r.act_ut = r.exp_ut) AS refs_ok
    FROM (SELECT DISTINCT label, file_name FROM #E) s
) x
ORDER BY x.label;

-- Reference detail for a FAIL.
SELECT * FROM #REF ORDER BY trans_ref;
"@

[IO.File]::WriteAllText($OutFile, $sql)
"Wrote $OutFile ($(@($values).Count) expected rows, database [$Database])."
