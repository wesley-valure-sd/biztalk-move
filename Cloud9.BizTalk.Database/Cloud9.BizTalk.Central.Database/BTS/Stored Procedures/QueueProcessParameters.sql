-- =============================================
-- Author:		James Jordan
-- Create date: 04/12/2019
-- =============================================
CREATE PROCEDURE [BTS].[QueueProcessParameters]
	@processName varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ppID bigint = NULL
	DECLARE @lastProcessed DATETIME 
	DECLARE @toDateTime DATETIME = GETDATE()

	SELECT TOP 1 @LastProcessed = ppProcessLastRun, @ppID = ppid
	FROM BTS.ProcessParameter WHERE ppProcessName = @processName and ppStatus = 0
	ORDER BY ppID DESC ;

	UPDATE BTS.ProcessParameter SET ppStatus = 1 WHERE @ppID = ppid

	SELECT TOP 1
		@ppID AS ppID,
		@lastProcessed as fromDateTime, 
		@toDateTime as toDateTime,
		@processName as processName
	WHERE @ppID IS NOT NULL ;

	SELECT
		pcGUID,
		pcInstanceAddress,
		pcInstanceConnectionString,
		pcRoutingPrefix,
		pcName
	FROM BTS.PracticeConfig
	WHERE @ppID IS NOT NULL ;
END
