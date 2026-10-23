USE [LocalDemo-Trunk]

-- Get Insurance info to replace on 835 EDI File

DECLARE @patientName NVARCHAR(50)	= 'Josh Smith' 
DECLARE @paymentAmount INT			= 130		-- Amount you want for the payment

-- Patient
SELECT	pat.patGUID,
		per.persFullName,
		@paymentAmount as [CLP04],			-- Replace Payment amount
		pip.pipGUID,
		pip.pipPolicyNumber as [NM109],		-- Replace Insurance Policy Number WHERE NM101 = 'QC'
		ac.adaclaimNumber as [CLP01]		-- Replace Claim Number
FROM	Person per 
		JOIN Patient pat ON per.persGUID = pat.persGUID 
		JOIN PatientInsurancePolicy pip ON pat.patGUID = pip.patGUID
		JOIN ADAClaim ac ON pat.patGUID = ac.patGUID
WHERE	persFullName like '%' + @patientName + '%'