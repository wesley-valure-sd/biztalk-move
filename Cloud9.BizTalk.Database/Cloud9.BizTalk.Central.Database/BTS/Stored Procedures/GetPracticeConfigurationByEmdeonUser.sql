
CREATE PROCEDURE [BTS].[GetPracticeConfigurationByEmdeonUser]
	@emdeonUserID NVARCHAR(10)
AS
BEGIN
	SELECT	[pcGUID],
			[pcInstanceAddress],
			[pcInstanceConnectionString],
			[pcName]
	FROM	[BTS].[PracticeConfig]
	WHERE	[emdeonUserID] = @emdeonUserID
END
