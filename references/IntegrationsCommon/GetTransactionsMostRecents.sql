USE [LocalDemo-Trunk]

-- Get Most recent Transactions

SELECT	TOP 20 
		transDateTime,
		transDateTimePosted,
		transStatus,
		transGUID,
		locGUIDPosted,
		locGUIDAssigned,
		empGUIDProvider,
		patGUID,
		ttypGUID,
		transDebitGroup,
		transCreditGroup,
		transAmount,
		transNote,
		transReceiptNote,
		transReference,
		transDueNowAmount,
		transTotalDueAmount,
		transProductionAmount,
		ppGUID,
		pipGUID,
		orgGUID,
		transIsGroup,
		transClaimAmount,
		transCheckNumber,
		transRouting
FROM	[Transaction]
ORDER BY transDateTimePosted DESC