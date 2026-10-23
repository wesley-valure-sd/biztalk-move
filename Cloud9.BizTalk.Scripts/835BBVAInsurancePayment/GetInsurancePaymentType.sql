USE [PRACTICE-DB]

-- Get Insurance Payment Type configured on BizTalk (Expected: L6C, L6P, PLB)

SELECT	ttypCode, ptPaymentType, ptPaymentTypeCode, ptIsDeleted
FROM	BTS.PaymentType
WHERE	ptPaymentTypeCode IN ('L6C', 'L6P', 'PLB')

-- Transactions types linked to the BizTalk types (Expected: INTERESTOTSD, INSIPC, LBOXINSC)

SELECT	ttypGUID, ttypCode, ttypDescription
FROM	TransactionType
WHERE	ttypCode IN ('INTERESTOTSD', 'INSIPC', 'LBOXINSC')