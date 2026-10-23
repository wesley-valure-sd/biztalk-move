

-- =============================================
-- Author:          James Jordan
-- Create date: 2019/02/25
-- =============================================
CREATE PROCEDURE [BTS].[QueueUnprocessedStagingPatientIDs]
       @pageSize int,
       @maxProcessing int = 0
AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

		DECLARE @errorGUIDS AS TABLE
		(
			[hisGUID] uniqueidentifier,
			[pcGUID] uniqueidentifier, 
			[imGUID] uniqueidentifier
		)

		;WITH CTE AS 
		(
			SELECT [hisGUID], [imGUID], [pcGUID]
			FROM [BTS].[HL7InboundStaging]
			WHERE [BTS].[HL7InboundStaging].hisStatus IN (0,1)
		)
		INSERT INTO @errorGUIDS
		( [hisGUID], [pcGUID], [imGUID] )
		SELECT [hisGUID], CTE.[pcGUID], [imGUID]
		FROM CTE
		LEFT JOIN [BTS].[PracticeConfig] ON CTE.[pcGUID] = [BTS].[PracticeConfig].[pcGUID]
		WHERE [BTS].[PracticeConfig].[pcGUID] IS NULL

		-- This happens when the sender of the message sends a Practice GUID which has not been configured or that is incorrect.
		-- This allows those messages to cleanly error out so they can be diagnosed/resolved and don't linger and cause misbehavior 
		INSERT INTO [BTS].[Log]
		( [logGUID], [pcInstanceAddress], [logProcess], [logType], [logMessage], [logInternalEntityId], [logExternalEntityId], [logStackTrace], [logCreatedDate], [logCreatedBy] )
		SELECT newid(), 'n/a', 'PracticeConfigNotFound', 'Error', 'Practice Configuration not found for pcGUID <' + cast([pcGUID] as varchar(40)) + '>', [imGUID], null, null, getdate(), null 
		from @errorGUIDS 

		UPDATE hl7 set hisStatus = 3, hisLastModifiedDate = GETDATE()
		FROM @errorGUIDS eg
		JOIN [BTS].[HL7InboundStaging] hl7 ON hl7.hisGUID = eg.hisGUID

        --grab top x records insert into temp table
		DECLARE @RecordsToProcess TABLE 
		(
			hisEPICPatientID nvarchar(100),
			pcGUID uniqueidentifier,
			pcInstanceAddress nvarchar(200)
		)

       IF (@maxProcessing = 0) OR ((SELECT COUNT(*) FROM [BTS].[HL7InboundStaging] WHERE hisStatus = 1) < @maxProcessing)
             BEGIN
             


                    INSERT INTO @RecordsToProcess
                    SELECT TOP (@pageSize) 
                           [BTS].[HL7InboundStaging].[hisEPICPatientID],
                           [BTS].[HL7InboundStaging].[pcGUID],
                           [BTS].[PracticeConfig].[pcInstanceAddress]
                    from [BTS].[HL7InboundStaging]
                    join [BTS].[PracticeConfig]
                    ON [BTS].[HL7InboundStaging].[pcGUID] = [BTS].[PracticeConfig].[pcGUID]
                    WHERE [BTS].[HL7InboundStaging].[hisStatus] = 0
                    ORDER BY [hisMSH_7_DateTimeOfMessage]

                    --update status to 1 for any hisEPICPatientID + pcGUID in the list where status = 0
                    UPDATE hl7is
                    SET hl7is.hisStatus = 1
                    FROM [BTS].[HL7InboundStaging] AS hl7is
                    INNER JOIN @RecordsToProcess AS recs
                    ON hl7is.hisEPICPatientID = recs.hisEPICPatientID AND hl7is.pcGUID = recs.pcGUID
                    WHERE hl7is.hisStatus = 0

             END

		--return distinct hisEPICPatientID + pcInstanceAddress combo
		SELECT DISTINCT [hisEPICPatientID],[pcInstanceAddress] FROM @RecordsToProcess
END