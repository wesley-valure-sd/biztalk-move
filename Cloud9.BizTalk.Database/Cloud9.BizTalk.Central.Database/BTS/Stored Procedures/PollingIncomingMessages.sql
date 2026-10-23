CREATE PROCEDURE [BTS].[PollingIncomingMessages]
	 @pageSize INT = 50,
     @maxProcessing INT = 0
AS
BEGIN

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	--Calculate how many rows to processing
	DECLARE @isProcessing INT = (SELECT COUNT(*) FROM BTS.IncomingMessage WHERE imStatus =1);
	DECLARE @toProcessing INT = 0;

	IF ( @maxProcessing <> 0 ) SET @toProcessing = @maxProcessing - @isProcessing;
	IF ( @toProcessing > @pageSize ) SET @toProcessing = @pageSize;

	-- Get messages to process
	DECLARE @RecordsToProcess TABLE 
	(
		[imGUID] [uniqueidentifier],
		[imCorrelationId] [uniqueidentifier],
		[imMessageType] [varchar](12),
		[imMessageContents] [varchar](max),
		[imStatus] [int],
		[imProcessImmediately] [bit],
		[imReceiveTime] [datetime2](7),
		[imProcessTime] [datetime2](7) 
	);
	INSERT INTO @RecordsToProcess
		SELECT TOP (@toProcessing) imGUID, 
			[imCorrelationId],
			[imMessageType],
			[imMessageContents],
			[imStatus],
			[imProcessImmediately],
			[imReceiveTime],
			[imProcessTime]
			FROM BTS.IncomingMessage 
			WHERE imStatus = 0
			ORDER BY imProcessImmediately DESC, imReceiveTime; 

	-- Mark incoming message to processing
	UPDATE BTS.IncomingMessage 
	SET imStatus = 1 
	WHERE imGUID IN (SELECT imGUID FROM @RecordsToProcess);
		

	-- Return messages to polling
	SELECT [imGUID],
		[imCorrelationId],
		[imMessageType],
		'<![CDATA['+[imMessageContents]+']]>' AS imMessageContents,
		[imStatus],
		[imProcessImmediately],
		[imReceiveTime],
		[imProcessTime] 
		FROM @RecordsToProcess
		ORDER BY imProcessImmediately DESC, imReceiveTime;

END
