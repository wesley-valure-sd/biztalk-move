USE [PRACTICE-DB]

-- Get Insurance Eligibility info to replace on 271 EDI File

DECLARE @patientName NVARCHAR(50)			= 'daniel smith' 
DECLARE @transactionDate NVARCHAR(8)		= '20200815'
DECLARE @transactionTime NVARCHAR(4)		= '1148'
DECLARE @benefitsRenewalDate NVARCHAR(8)	= '20210101'

DECLARE @newIndividualDeductible INT			= 50
DECLARE @newIndividualDeductibleRemaining INT	= 100
DECLARE @newIndividualAnnualMax INT				= 1500
DECLARE @newIndividualAnnualMaxRemaining INT	= 1600
DECLARE @newFamilyDeductible INT				= 150
DECLARE @newFamilyAnnualMax INT					= 1900
DECLARE @newIndividualOrthoDeductible INT		= 200
DECLARE @newIndividualOrthoMax INT				= 1700
DECLARE @newLifetimeMax INT						= 2000
DECLARE @newIndividualOrthoMaxRemaining INT		= 1800
DECLARE @newReplaceMissingTeeth BIT				= 0		-- true/false	0/1
DECLARE @newInNetwork BIT						= 0		-- true/false	0/1
DECLARE @newPayOutOfNetwork BIt					= 0		-- true/false	0/1

-- Insurance Policy Eligibility benefits
SELECT	pip.pipGUID as [REF02],					-- Replace Insurance Policy ID (When Reference Identification Qualifier Code is '69')
		per.persFullName,
		@transactionDate as [GS04_BHT03],		-- Replace Transaction Date places
		@transactionTime as [GS05_BHT04],		-- Replace Transaction Time places
		@newIndividualDeductible as [EB07_IndividualDeductible],					-- Replace WHEN EB01 = 'C' & EB02 = 'IND' & EB03 = '35' & NOT EB06
		@newIndividualDeductibleRemaining as [EB07_IndividualDeductibleRemaining],	-- Replace WHEN EB01 = 'C' & EB02 = 'IND' & EB03 = '35' & EB06 = '29'
		@newIndividualOrthoDeductible as [EB07_IndividualOrthoDeductible],			-- Replace WHEN EB01 = 'C' & EB02 = 'IND' & EB03 = '38'
		@newIndividualOrthoMaxRemaining as [EB07_IndividualOrthoMaxRemaining],		-- Replace WHEN EB01 = 'F' & EB02 = 'IND' & EB03 = '38' & EB06 = '29'
		@newIndividualAnnualMaxRemaining as [EB07_IndividualAnnualMaxRemaining],	-- Replace WHEN EB01 = 'F' & EB02 = 'IND' & EB03 = '35' & EB06 = '29'
		@newFamilyDeductible as [EB07_FamilyDeductible],		-- Replace WHEN EB01 = 'C' & EB02 = 'FAM' & EB03 = '35' & NOT EB06
		@newIndividualAnnualMax as [EB07_IndividualAnnualMax],	-- Replace WHEN EB01 = 'F' & EB02 = 'IND' & EB03 = '35' & EB06 = '23'
		@newIndividualOrthoMax as [EB07_IndividualOrthoMax],	-- Replace WHEN EB01 = 'F' & EB02 = 'IND' & EB03 = '38' & EB06 = '32'
		@newFamilyAnnualMax as [EB07_FamilyAnnualMax],			-- Replace WHEN EB01 = 'F' & EB02 = 'FAM' & EB03 = '35' & EB06 = '23'
		@newLifetimeMax as [EB07_LifetimeMax],					-- Replace WHEN EB01 = 'F' & EB02 = 'IND' & EB03 = '35' & EB06 = '32'
		@newInNetwork as [EB07_InNetwork],						-- Replace WHEN EB01 = 'D' & EB03 = 'InNetwork'. EB12 = 'N'/'Y'
		@newReplaceMissingTeeth as [EB12_ReplaceMissingTeeth],  -- Replace WHEN EB01 = 'D' & EB03 = 'ReplaceMissingTeeth'. EB12 = 'N'/'Y'
		@newPayOutOfNetwork as [EB12_PayOutOfNetwork],			-- Replace WHEN EB01 = 'D' & EB03 = 'PayOutOfNetwork'. EB12 = 'N'/'Y'
		@benefitsRenewalDate as [DTP03]							-- Benefits Renewal Date
FROM	Person per 
		JOIN Patient pat ON per.persGUID = pat.persGUID 
		JOIN PatientInsurancePolicy pip ON pat.patGUID = pip.patGUID
		JOIN ADAClaim ac ON pat.patGUID = ac.patGUID
WHERE	persFullName like '%' + @patientName + '%'