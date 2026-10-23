

-- =============================================
-- Author:      Alan Ware
-- Create date: 2019/02/27
-- =============================================
create PROCEDURE [BTS].[SetStagingPatientMessageStatus]
      @hisStagingID BIGINT,
	  @hisStatus SMALLINT,
	  @hisModifiedBy nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE [BTS].[HL7InboundStaging]
	SET [hisStatus] = @hisStatus,
		[hisLastModifiedDate] = GETDATE(),
		[hisLastModifiedBy] = @hisModifiedBy
	WHERE [BTS].[HL7InboundStaging].[hisStagingID] = @hisStagingID
END