/*
    C9-T check of an insurance POC run (flow C). Read-only. Made by src\tools\New-InsuranceVerifyScript.ps1. Do not edit.
    Run on C9-T after: lockbox run src\testdata\Insurance  (with LOCKBOX_SQL_CONNECTION set to the Utility database).
    @since defaults to 60 minutes before the newest ImportLog row of the scenario files. Set it by hand for an older run.
    ImportLog rows are matched by file name. [Transaction] and UnmappedTransaction rows are matched by reference (TRN02 or
    ADJn-TRN02) and a date at or after @since; scenarios that share a reference (I01 and I21) are checked together.
    "Finished" includes "Payment amount exceeds remaining balance. Success".
*/
USE [TestC9];
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
    (N'I15', N'SDOC_20260508_TESTC9_I15.835', 1, 0, N'', N'799719119', N'Finished', NULL, 1, -396, 396, 0),
    (N'I15', N'SDOC_20260508_TESTC9_I15.835', 2, 1, N'', N'ADJ1-799719119', N'Finished', NULL, 1, 396, 396, 0),
    (N'I15', N'SDOC_20260508_TESTC9_I15.835', 3, 1, N'', N'ADJ2-799719119', N'Finished', NULL, 2, 0, 100, 0),
    (N'I19', N'SDOC_20260717_TESTC9_I19.835', 1, 0, N'EOB19010001', N'HU59745648', N'Finished', NULL, 1, -84.93, 84.93, 0),
    (N'I17', N'SDOC_20260804_TESTC9_I17.835', 1, 0, NULL, NULL, N'Failed', N'There were 5 CLP payments and 2 PLB adjustments on transaction 0001', 0, 0, 0, 0),
    (N'I04', N'SDOC_20260814_TESTC9_I04.835', 1, 0, N'EOB04010001', N'595394800294710', N'Finished', NULL, 1, -45.06, 45.06, 0),
    (N'I05', N'SDOC_20260819_TESTC9_I05.835', 1, 0, N'EOB05010001', N'YXDC56438261729039457', N'Finished', NULL, 1, 0, 0, 0),
    (N'I03', N'SDOC_20260825_TESTC9_I03.835', 1, 0, N'EOB03010001', N'VANH59391483909543691', N'Finished', NULL, 1, 0, 0, 0),
    (N'I03', N'SDOC_20260825_TESTC9_I03.835', 2, 0, N'EOB03020001', N'CGEG30923270917669500', N'Finished', NULL, 1, 0, 0, 0),
    (N'I12', N'SDOC_20260825_TESTC9_I12.835', 1, 0, N'EOB12010001', N'5110970274', N'Failed', N'Conversion failed when converting the nvarchar value % to data type int%', 0, 0, 0, 1),
    (N'I02', N'SDOC_20260827_TESTC9_I02.835', 1, 0, N'EOB02010001', N'6078666632', N'Finished', NULL, 1, -100, 100, 0),
    (N'I02', N'SDOC_20260827_TESTC9_I02.835', 2, 0, N'EOB02020001', N'6078666632', N'Finished', NULL, 1, -100, 100, 0),
    (N'I22', N'SDOC_20260903_TESTC9_I22.835', 1, 0, N'EOB22010001', N'C595953043', N'Finished', NULL, 1, -60.52, 60.52, 0),
    (N'I07', N'SDOC_20260923_TESTC9_I07.835', 1, 0, N'EOB07010001', N'657983204', N'Finished', NULL, 1, 0, 0, 0),
    (N'I14', N'SDOC_20260923_TESTC9_I14.835', 1, 0, N'EOB14010001', N'696086740186883', N'Finished', NULL, 1, -1350, 1350, 0),
    (N'I14', N'SDOC_20260923_TESTC9_I14.835', 2, 1, N'EOB14010001', N'ADJ1-696086740186883', N'Failed', N'%Duplicate payment for ilExternalReference%', 0, 0, 0, 1),
    (N'I06', N'SDOC_20260924_TESTC9_I06.835', 1, 0, N'EOB06010001', N'7314', N'Finished', NULL, 1, -218.73, 218.73, 0),
    (N'I09', N'SDOC_20260928_TESTC9_I09.835', 1, 0, N'EOB09010001', N'53021618', N'Failed', N'%Could not locate Claim%Could not locate Insurance Policy%', 0, 0, 0, 1),
    (N'I16', N'SDOC_20260928_TESTC9_I16.835', 1, 0, N'EOB16010001', N'4087096', N'Finished', NULL, 1, -174.87, 174.87, 0),
    (N'I01', N'SDOC_20260929_TESTC9_I01.835', 1, 0, N'EOB01010001', N'1959226824', N'Finished', NULL, 1, -54.5, 54.5, 0),
    (N'I21', N'SDOC_20260929_TESTC9_I21.835', 1, 0, N'EOB01010001', N'1959226824', N'Failed', N'%Duplicate payment for ilExternalReference%', 0, 0, 0, 1),
    (N'I18', N'SDOC_20261005_TESTC9_I18.835', 1, 0, N'EOB18010001', N'4794544941', N'Failed', N'%PatientInsurancePolicy record not found for pipGUID%', 0, 0, 0, 1),
    (N'I11', N'SDOC_20261006_TESTC9_I11.835', 1, 0, N'EOB11010001', N'72426594', N'Failed', N'The conversion of the nvarchar value % overflowed an int column%', 0, 0, 0, 1),
    (N'I08', N'SDOC_20261015_TESTC9_I08.835', 1, 0, N'', N'0249151567', N'Finished', NULL, 1, 638, 638, 0),
    (N'I10', N'SDOC_20261021_TESTC9_I10.835', 1, 0, N'', N'65237557', N'Failed', N'%Could not locate Claim%Could not locate Insurance Policy%', 0, 0, 0, 1),
    (N'I13', N'SDOC_20261022_TESTC9_I13.835', 1, 0, N'', N'4526750706', N'Finished', NULL, 1, -130.58, 130.58, 0),
    (N'I20', N'SDOC_20261022_TESTC9_I20.835', 1, 0, N'', N'123003941', N'Finished', NULL, 1, -112.5, 112.5, 0);

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