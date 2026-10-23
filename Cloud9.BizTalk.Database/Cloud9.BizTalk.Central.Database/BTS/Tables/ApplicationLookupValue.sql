CREATE TABLE BTS.ApplicationLookupValue(
	alvGUID UNIQUEIDENTIFIER
	, alvApplication VARCHAR(50)
	, alvLookup VARCHAR(50)
	, alvKey VARCHAR(50)
	, alvValue VARCHAR(255)
	, alvDescription VARCHAR(255), 
    CONSTRAINT [PK_ApplicationLookupValue] PRIMARY KEY (alvGUID)
)