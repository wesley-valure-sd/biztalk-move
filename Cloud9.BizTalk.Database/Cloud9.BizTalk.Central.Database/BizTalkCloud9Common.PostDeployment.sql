/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
INSERT INTO [BTS].[PracticeConfigStatus] (pcsStatusID, pcsStatusDescription)
SELECT 0, 'Active' WHERE NOT EXISTS (SELECT 1 FROM [BTS].[PracticeConfigStatus] WHERE pcsStatusID = 0  AND pcsStatusDescription = 'Active')

INSERT INTO [BTS].[PracticeConfigStatus] (pcsStatusID, pcsStatusDescription)
SELECT 1, 'Inactive' WHERE NOT EXISTS (SELECT 1 FROM [BTS].[PracticeConfigStatus] WHERE pcsStatusID = 1  AND pcsStatusDescription = 'Inactive')

INSERT INTO BTS.ApplicationLookupValue(alvGUID, alvApplication, alvLookup, alvKey, alvValue, alvDescription)
SELECT
	NEWID()
	, 'CHC835ToBBVA'
	, '1000000004'
	, 'AgreementNameForSend'
	, 'ChangeHealthcare_BBVA'
	, 'Sample Provider DMD'
WHERE NOT EXISTS(SELECT 1 FROM BTS.ApplicationLookupValue WHERE alvApplication = 'CHC835ToBBVA' AND alvLookup = '1000000004' AND alvKey = 'AgreementNameForSend')

INSERT INTO BTS.ApplicationLookupValue(alvGUID, alvApplication, alvLookup, alvKey, alvValue, alvDescription)
SELECT
	NEWID()
	, 'CHC835ToBBVA'
	, '1000000004'
	, 'SenderPartyNameForSend'
	, 'ChangeHealthcare'
	, 'Sample Provider DMD'
WHERE NOT EXISTS(SELECT 1 FROM BTS.ApplicationLookupValue WHERE alvApplication = 'CHC835ToBBVA' AND alvLookup = '1000000004' AND alvKey = 'SenderPartyNameForSend')

INSERT INTO BTS.ApplicationLookupValue(alvGUID, alvApplication, alvLookup, alvKey, alvValue, alvDescription)
SELECT
	NEWID()
	, 'CHC835ToBBVA'
	, '1000000004'
	, 'ReceiverPartyNameForSend'
	, 'BBVA'
	, 'Sample Provider DMD'
WHERE NOT EXISTS(SELECT 1 FROM BTS.ApplicationLookupValue WHERE alvApplication = 'CHC835ToBBVA' AND alvLookup = '1000000004' AND alvKey = 'ReceiverPartyNameForSend')

INSERT INTO BTS.StagingStatus(stsStatusID, stsStatusDescription)
SELECT 0, 'Unprocessed'
WHERE NOT EXISTS(SELECT 1 FROM BTS.StagingStatus WHERE stsStatusID = 0)

INSERT INTO BTS.StagingStatus(stsStatusID, stsStatusDescription)
SELECT 1, 'Processing'
WHERE NOT EXISTS(SELECT 1 FROM BTS.StagingStatus WHERE stsStatusID = 1)

INSERT INTO BTS.StagingStatus(stsStatusID, stsStatusDescription)
SELECT 2, 'Processed'
WHERE NOT EXISTS(SELECT 1 FROM BTS.StagingStatus WHERE stsStatusID = 2)

INSERT INTO BTS.StagingStatus(stsStatusID, stsStatusDescription)
SELECT 3, 'Error'
WHERE NOT EXISTS(SELECT 1 FROM BTS.StagingStatus WHERE stsStatusID = 3)

