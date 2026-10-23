USE [PRACTICE-DB]

-- Get Patient payment info to replace on 835 EDI File

DECLARE @patientName NVARCHAR(50)	= 'Elizabeth Sanders' 
DECLARE @paymentAmount INT					= 150					-- Amount you want for the payment
DECLARE @paymentCode NVARCHAR(3)			= 'CCC'
DECLARE @transactionDate NVARCHAR(8)		= '20200815'			-- Date you want for the transaction
DECLARE @creditCardNumber as NVARCHAR		= 'XXXXXXXXXXXX2222'	-- Masked Creadit Card Number	

SELECT	per.persFullName,
		@paymentAmount as [CLP04],			-- Replace payment amount
		@paymentCode as [BPR04],			-- Replace payment code
		@creditCardNumber as [REF02],		-- Replace Masked Creadit Card Number (WHEN REF01 = 'TN' & BPR04 = 'CCC')
		@transactionDate as [BPR16],		-- Replace transaction date		
		pat.patGUID as [NM109_patGUID],		-- Replace Patient GUID on NM109 (WHEN MN101 = 'QC')
		pp.ppGUID as [NM109_ppGUID],		-- Replace Person GUID  on NM109 (WHEN MN101 = 'IL')
		pp.ppFinanciallyResponsible
FROM	Person per 
		JOIN Patient pat ON per.persGUID = pat.persGUID 
		JOIN PersonPerson pp ON per.persGUID = pp.persGUID
WHERE	persFullName like '%' + @patientName + '%'
