


-- =============================================
-- Author:		Alan Ware
-- Create date: 2019/01/17
-- Description:	Retrieves Configuration information by Organization ID for BizTalk Routing
-- =============================================
CREATE PROCEDURE [BTS].[GetPracticeConfiguration]
	@pcGUID uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
		[pcGUID],
		[pcInstanceAddress]
	from [BTS].[PracticeConfig]
	where [pcGUID] = @pcGUID
END