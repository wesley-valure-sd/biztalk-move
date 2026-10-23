USE [PRACTICE-DB]

-- Get Insurance Payment Transactions

DECLARE @patientId uniqueidentifier = '9EDAD3D4-F056-9648-38BE-C1CF01EED88B'

SELECT	transDateTime,
		transStatus,
		patGUID,
		ttypGUID,
		transAmount,
		transNote,
		transReceiptNote,
		transReference,
		transDueNowAmount,
		transTotalDueAmount,
		transProductionAmount,
		ppGUID,
		pipGUID,
		transClaimAmount,
		transCheckNumber,
		transRouting
FROM	[Transaction]
WHERE	patGUID = @patientId
ORDER BY transDateTimePosted DESC