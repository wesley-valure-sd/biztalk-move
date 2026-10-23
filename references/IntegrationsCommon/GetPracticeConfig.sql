USE [BizTalkCloud9Common]

-- Get Practice Config Information

DECLARE @practiceName NVARCHAR(50) = 'GULFCOAST'

SELECT	pcName as Name, 
		pcsStatusID as Status, 
		pcRoutingPrefix as ReoutingPrefix, 
		pcInstanceAddress, 
		pcInstanceConnectionString
FROM	BTS.PracticeConfig
WHERE	pcName like '%' + @practiceName + '%'