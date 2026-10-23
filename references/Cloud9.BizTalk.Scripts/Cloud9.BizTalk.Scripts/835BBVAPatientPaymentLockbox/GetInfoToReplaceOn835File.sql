USE [PRACTICE-DB]

-- Get Patient info to replace on 835 EDI File

DECLARE @patientName NVARCHAR(50)	= 'Elizabeth Sanders' 
DECLARE @personGUID uniqueidentifier

-- Patient
SELECT	per.persGUID,
		pat.patGUID as [NM109],				-- Copy Patient Id on NM109 (for QC on MN101)
		per.persFirstName as [NM103],		-- Copy Patient First Name on NM103
		per.persLastName as [NM104],		-- Copy Patient Last Name on NM104
		per.persFullName as [N102_PER02]	-- Copy Patient Name on N102 & PER02
FROM	Person per JOIN Patient pat ON per.persGUID = pat.persGUID 
WHERE	persFullName like '%' + @patientName + '%'

-- Get Person Id to get the responsible persons
SELECT	@personGUID = per.persGUID 
FROM Person per JOIN Patient pat ON per.persGUID = pat.persGUID 
WHERE	persFullName like '%' + @patientName + '%'

-- Financial Responsible
SELECT	pp.ppGUID as [NM109],				-- Copy Responsible Person Id on NM109 (for IL on MN101)
		per.persGUID,			
		per.persFirstName as [NM103],		-- Copy Responsible Person First Name on NM103
		per.persLastName as [NM104]			-- Copy Responsible Last Name on NM104
FROM	PersonPerson pp JOIN Person per ON pp.persGUIDRelated = per.persGUID
WHERE	pp.persGUID = @personGUID
		AND pp.ppFinanciallyResponsible = 1