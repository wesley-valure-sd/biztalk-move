USE [LocalDemo-Trunk]

-- Get Insurance Payment Transactions

DECLARE @patientId uniqueidentifier = 'AA7EC8B8-4A28-4931-B199-7384A8D51570'

SELECT	transGUID,
		transDateTime,
		transDateTimePosted,
		transStatus,
		locGUIDAssigned,
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
WHERE	
		transNote like '%Approval Code%' 
		AND transRouting IS NOT NULL
		AND patGUID = @patientId
ORDER BY transDateTimePosted DESC