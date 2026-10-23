USE [PRACTICE-DB]

-- Get Insurance Payment Unmapped Transactions

DECLARE @patientId uniqueidentifier = '9EDAD3D4-F056-9648-38BE-C1CF01EED88B'

SELECT	patGUID,
		utDateTime,
		utStatus
		utAmount,
		utReceiptNote,
		utReference,
		utCheckNumber,
		utRouting,
		adaClaimNumber,
		pipPolicyNumber,
		ptPaymentTypeCode,
		utErrorMessage
FROM	UnmappedTransaction
WHERE	patGUID = @patientId
ORDER BY utDateTime DESC