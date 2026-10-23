-- =============================================
-- Author:      Alan Ware
-- Create date: 2019/02/27
-- =============================================
CREATE PROCEDURE [BTS].[GetProcessingStagingPatientMessages]
      @hisEPICPatientID nvarchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
		[hisStagingID],
		hl7.[imGUID],
		[hisMessageType],
		[hisMSH_7_DateTimeOfMessage],
		[hisMSH_10_MessageControlId],
		im.[imCorrelationId],
		'<![CDATA[procstg' + cast( [hisMessageData] as varchar(max) ) +'procstg]]>' AS [hisMessageData],
		im.imVendorUserName,
		hl7.pcGUID
	from [BTS].[HL7InboundStaging] hl7
	JOIN [BTS].[IncomingMessage] im on im.imGUID = hl7.imGUID AND [hisStatus] = 1 AND [hisEPICPatientID] = @hisEPICPatientID
	WHERE [hisStatus] = 1 AND [hisEPICPatientID] = @hisEPICPatientID
	ORDER BY [hisMSH_7_DateTimeOfMessage]
END

