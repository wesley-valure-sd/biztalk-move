
CREATE PROCEDURE [BTS].[GetIncomingMessageInfo]
	@imGUID UNIQUEIDENTIFIER
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	SELECT [imCorrelationId], [imVendorUserName], [imMessageType], [imStatus], [imProcessImmediately], [patGUID], im.[pcGUID], [pcInstanceAddress], [pcInstanceConnectionString], [pcRoutingPrefix]
	FROM [BTS].[IncomingMessage] im
	JOIN [BTS].[PracticeConfig] pc on pc.[pcGUID] = im.[pcGUID]
	WHERE imGUID = @imGUID
END