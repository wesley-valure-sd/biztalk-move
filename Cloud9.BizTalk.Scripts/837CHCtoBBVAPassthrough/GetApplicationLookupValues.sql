USE [BizTalkCloud9Common]

-- Get Application Lookup values for 835 CHC to BBVA

DECLARE @payeeIdentifier INT = 1000000004	-- Replace with N104 WHERE N101 = 'PE'

SELECT	* 
FROM	BTS.ApplicationLookupValue
WHERE	alvApplication = 'CHC835ToBBVA'
		AND alvLookup = @payeeIdentifier
		AND alvKey IN ('AgreementNameForSend', 'SenderPartyNameForSend', 'ReceiverPartyNameForSend')
ORDER BY alvLookup