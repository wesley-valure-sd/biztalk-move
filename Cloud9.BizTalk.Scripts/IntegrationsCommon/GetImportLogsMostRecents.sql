USE [LocalDemo-Trunk]

-- Get Most Recent Import Logs

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
ORDER BY ilDateTime DESC