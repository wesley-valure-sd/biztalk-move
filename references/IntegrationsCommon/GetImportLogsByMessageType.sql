USE [InternalSd-gulfcoast]

-- Get Import Logs by Process Type

DECLARE @processType NVARCHAR(50)

SET @processType = 'Process_BBVA_835Insurance'
--SET @processType = 'Process_BBVA_835Patient'
--SET @processType = 'Process_ChannelHealth_271Eligibility'

SELECT	TOP 10 
		ilDateTime as CreatedOn,
		ilProcess as MsgType,
		ilLogLevel as MsgLevel,
		ilMessage as MsgText,
		ilFileName as FileName,
		ilImportGUID as ImportGUID,
		ilImportState as ImportState,
		ilStackTrace as stackTrace,
		ilExternalReference as ExternalReference
FROM	ImportLog
WHERE	ilProcess = @processType
ORDER BY ilDateTime DESC