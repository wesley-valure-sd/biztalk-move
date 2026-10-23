USE [PRACTICE-DB]

-- Get Lockbox Payment Type configured on BizTalk

SELECT	ttypCode, ptPaymentType, ptPaymentTypeCode, ptIsDeleted
FROM	BTS.PaymentType
WHERE	ttypCode = 'LBOXPERCMO'

-- Get Lockbox Payment Type configured on Practice (Should be added from the UI for the practice)

SELECT	ttypCode, ttypDescription, ttypDeleted
FROM	TransactionType
WHERE	ttypCode = 'LBOXPERCMO'
