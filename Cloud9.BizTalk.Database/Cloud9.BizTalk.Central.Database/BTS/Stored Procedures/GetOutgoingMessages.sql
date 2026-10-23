CREATE PROCEDURE BTS.GetOutgoingMessages
AS

BEGIN
	WITH XMLNAMESPACES(DEFAULT 'http://Cloud9.BizTalk.Schemas.OutgoingMessage.OutgoingMessage')
	SELECT
		OutgoingMessage.omGUID
		, OutgoingMessage.omCorrelationID
		, OutgoingMessage.omMessageType
		, OutgoingMessage.omSourceDatabase
		, OutgoingMessage.stsStatusID
		, OutgoingMessage.omCreateDateTime
		, OutgoingMessage.omProcessedDateTime
		, OutgoingMessageAttribute.omaGUID
		, OutgoingMessageAttribute.AttributeName
		, OutgoingMessageAttribute.AttributeValue
	FROM BTS.OutgoingMessage OutgoingMessage
	INNER JOIN BTS.OutgoingMessageAttribute OutgoingMessageAttribute
		ON OutgoingMessageAttribute.omGUID = OutgoingMessage.omGUID
	WHERE OutgoingMessage.stsStatusID = 0
	FOR XML AUTO, ELEMENTS

	UPDATE BTS.OutgoingMessage
	SET stsStatusID = 1
	WHERE stsStatusID = 0
END
