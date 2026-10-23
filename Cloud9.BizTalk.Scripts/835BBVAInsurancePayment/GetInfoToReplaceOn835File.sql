USE [PRACTICE-DB]

-- Get Insurance info to replace on 835 EDI File

DECLARE @patientName NVARCHAR(50)	= 'Josh Sm' 
DECLARE @paymentAmount INT			= 130		-- Amount you want for the payment

-- Patient
SELECT	pat.patGUID as [REF02],				-- Replace Patient GUID WHERE REF = 'EJ'
		per.persFullName,
		@paymentAmount as [CLP04],			-- Replace Payment amount
		pip.pipGUID,
		pip.pipPolicyNumber as [NM109],		-- Replace Insurance Policy Number WHERE NM101 = 'QC'
		ac.adaclaimNumber as [CLP01]		-- Replace Claim Number
FROM	Person per 
		JOIN Patient pat ON per.persGUID = pat.persGUID 
		JOIN ADAClaim ac ON pat.patGUID = ac.patGUID
		JOIN PatientInsurancePolicy pip ON (ac.pipGUID = pip.pipGUID AND pat.patGUID = pip.patGUID)
WHERE	persFullName like '%' + @patientName + '%'