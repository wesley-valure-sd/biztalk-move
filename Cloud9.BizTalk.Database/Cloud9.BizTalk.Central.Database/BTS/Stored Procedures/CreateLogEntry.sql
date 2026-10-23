-- =============================================
-- Author:      James Jordan
-- Create date: 6/18/2019
-- =============================================
CREATE PROCEDURE [BTS].[CreateLogEntry]
      @pcInstanceAddress NVARCHAR(200) NULL,
	  @Process VARCHAR(50) NULL,
	  @Type VARCHAR(50) NULL,
	  @Message VARCHAR(MAX) NULL,
	  @InternalEntityID VARCHAR(100) = NULL,
	  @ExternalEntityID VARCHAR(100) = NULL,
	  @StackTrace VARCHAR(MAX) = NULL,
	  @CreatedBy VARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [BTS].[Log]
		(pcInstanceAddress,
		logProcess,
		logType,
		logMessage,
		logInternalEntityID,
		logExternalEntityID,
		logStackTrace,
		logCreatedDate,
		logCreatedBy)
	VALUES
	    (@pcInstanceAddress,
		@Process,
		@Type,
		@Message,
		@InternalEntityID,
		@ExternalEntityID,
		@StackTrace,
		GETDATE(),
		@CreatedBy)

END