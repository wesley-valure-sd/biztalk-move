USE [LocalDemo-Trunk]

-- Get Import Logs for success Insurance Payments

DECLARE @processType NVARCHAR(50) = 'Process_BBVA_835Insurance'

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
WHERE	ilLogLevel = 2
		AND ilImportState = 'Finished'
		AND ilProcess = @processType
ORDER BY ilDateTime DESC