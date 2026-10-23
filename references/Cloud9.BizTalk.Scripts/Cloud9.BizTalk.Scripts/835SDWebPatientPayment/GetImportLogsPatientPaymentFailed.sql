USE [PRACTICE-DB]

-- Get Import Logs for failed SD Web Patient Payments

DECLARE @processType NVARCHAR(50) = 'Process_SD_835Patient'

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
WHERE	ilLogLevel = 0
		AND ilImportState = 'Failed'
		AND ilProcess = @processType
ORDER BY ilDateTime DESC