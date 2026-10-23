-- =============================================
-- Author:		James Jordan
-- Create date: 04/12/2019
-- =============================================
CREATE PROCEDURE [BTS].[UpdateProcessParameters]
	@processName VARCHAR(25),
	@lastProcessed DATETIME,
	@ppID BIGINT,
	@ppStatus SMALLINT,
	@ppGUID UNIQUEIDENTIFIER = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE BTS.ProcessParameter SET ppStatus = @ppStatus WHERE ppID = @ppID

	DECLARE @GUIDLinking TABLE
		(ppGUID UNIQUEIDENTIFIER)

	INSERT INTO BTS.ProcessParameter 
		(ppProcessName, ppProcessLastRun, ppStatus) 
	OUTPUT INSERTED.ppGUID INTO @GUIDLinking(ppGUID)
	VALUES 
		(@processName, @lastProcessed, 0);

	SELECT TOP 1 @ppGUID = ppGUID FROM @GUIDLinking ;
	RETURN ;
END