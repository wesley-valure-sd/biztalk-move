CREATE PROCEDURE BTS.GetApplicationLookupValues
	@alvApplication VARCHAR(50)
	, @alvLookup VARCHAR(50)
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
		AND alvLookup = @alvLookup
END