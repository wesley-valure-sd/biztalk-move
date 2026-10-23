CREATE TABLE BTS.OutgoingMessage(
	omGUID UNIQUEIDENTIFIER NOT NULL
	, omCorrelationID VARCHAR(255) NOT NULL
	, omMessageType VARCHAR(50) NOT NULL
	, omSourceDatabase VARCHAR(50) NOT NULL
	, stsStatusID SMAllINT NOT NULL
	, omCreateDateTime	 DATETIME NOT NULL
	, omProcessedDateTime DATETIME NULL
	, CONSTRAINT PK_OutgoingMessage PRIMARY KEY NONCLUSTERED (omGUID)
	, CONSTRAINT FK_OutgoingMessage_StagingStatus FOREIGN KEY (stsStatusID)
		REFERENCES BTS.StagingStatus(stsStatusID)
)
GO

CREATE CLUSTERED INDEX IX_OutgoingMessage_omCreateDateTime ON BTS.OutgoingMessage(omCreateDateTime)