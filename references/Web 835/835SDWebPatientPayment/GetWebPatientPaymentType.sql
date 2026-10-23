USE [PRACTICE-DB]

-- Get SD Web Patient Payment Type configured on BizTalk (Expected: WEBCC, WEBACH & WEBACHRET)

SELECT	ttypCode, ptPaymentType, ptPaymentTypeCode, ptIsDeleted
FROM	BTS.PaymentType
WHERE	ptPaymentType = 'WEB'

-- Get Lockbox Payment Type configured on Practice (Should be added from the UI for the practice)

SELECT	ttypCode, ttypDescription, ttypDeleted
FROM	TransactionType
WHERE	ttypCode IN ('WEBCC', 'WEBACH', 'WEBACHRET')
