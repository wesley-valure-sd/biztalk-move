USE [PRACTICE-DB]

-- Get current Insurance Eligibility benefits

DECLARE @patientName NVARCHAR(50) = 'daniel smith' 

-- Current Benefits
SELECT	pip.pipGUID ,
		per.persFullName,
		pip.pipIndividualDeductible,
		pip.pipIndividualDeductibleRemaining,
		pip.pipIndividualOrthoDeductible,
		pip.pipFamilyDeductible,
		pip.pipIndividualAnnualMax,
		pip.pipIndividualAnnualMaxRemaining,
		pip.pipIndividualOrthoMax,
		pip.pipIndividualOrthoMaxRemaining,
		pip.pipFamilyAnnualMax,
		pip.pipLifetimeMax,
		pip.pipInNetwork,
		pip.pipReplaceMissingTeeth,
		pip.pipPayOutOfNetwork
FROM	Person per 
		JOIN Patient pat ON per.persGUID = pat.persGUID 
		JOIN PatientInsurancePolicy pip ON pat.patGUID = pip.patGUID
		JOIN ADAClaim ac ON pat.patGUID = ac.patGUID
WHERE	persFullName like '%' + @patientName + '%'