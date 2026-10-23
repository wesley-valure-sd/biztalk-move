CREATE PROCEDURE BTS.GetApplicationLookupValue
	@alvApplication VARCHAR(50)
	, @alvLookup VARCHAR(50)
	, @alvKey VARCHAR(50)
AS

BEGIN
	SELECT
		alvGUID
		, alvApplication
		, alvLookup
		, alvKey
		, alvValue
		, alvDescription
	FROM BTS.ApplicationLookupValue
	WHERE alvApplication = @alvApplication
		AND alvKey = @alvKey
		AND alvLookup = @alvLookup
END