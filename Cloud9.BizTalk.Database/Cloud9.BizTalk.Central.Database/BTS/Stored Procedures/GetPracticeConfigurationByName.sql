
-- =============================================
-- Author:		John Glisson
-- Create date: 2019/05/06
-- Description:	Retrieves Configuration information by pcName for BizTalk Routing
-- =============================================
CREATE PROCEDURE [BTS].[GetPracticeConfigurationByName]
	@pcName NVARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
		[pcGUID],
		[pcInstanceAddress],
		[pcInstanceConnectionString]
	from [BTS].[PracticeConfig]
	where [pcName] = @pcName
END
