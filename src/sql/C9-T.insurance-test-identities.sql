-- Read-only. Run on C9-T (TestC9) in SSMS. Save the result grid as CSV (with headers) and pass it to
-- src\tools\New-TestC9InsuranceFiles.ps1 -IdentityFile <file>.
-- Returns TestC9 claims that have a patient and an insurance policy, as Cloud9.BizTalk.Scripts\835BBVAInsurancePayment\GetInfoToReplaceOn835File.sql does.
-- The scenarios use 27 claims. Identities are reused in turn if there are fewer rows.
USE [TestC9];

SELECT TOP (30)
        CONVERT(varchar(36), pat.patGUID)  AS patGUID,          -- REF*EJ
        CONVERT(varchar(36), pip.pipGUID)  AS pipGUID,          -- REF*69
        pip.pipPolicyNumber                AS pipPolicyNumber,  -- NM1*QC NM109
        ac.adaclaimNumber                  AS adaClaimNumber    -- CLP01
FROM    Patient pat
        JOIN Person per ON per.persGUID = pat.persGUID          -- the insert joins Person
        JOIN ADAClaim ac ON pat.patGUID = ac.patGUID
        JOIN PatientInsurancePolicy pip ON ac.pipGUID = pip.pipGUID AND pat.patGUID = pip.patGUID
WHERE   ac.adaclaimNumber IS NOT NULL
  AND   ISNULL(pip.pipPolicyNumber, '') <> ''
  AND   pip.pipPolicyNumber NOT LIKE '%,%'                      -- keeps the CSV simple
  AND   (pip.pipDeleted IS NULL OR pip.pipDeleted = 0)
ORDER BY ac.adaclaimNumber DESC;
