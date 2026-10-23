CREATE TABLE [BTS].[IncomingMessage] (
    [imGUID]               UNIQUEIDENTIFIER CONSTRAINT [DF_IncomingMessage_imGUID] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [imCorrelationId]      VARCHAR (150)    NOT NULL,
    [imVendorUserName]     NVARCHAR (25)    NULL,
    [imMessageType]        VARCHAR (12)     NOT NULL,
    [imMessageContents]    VARCHAR (MAX)    NOT NULL,
    [imStatus]             INT              CONSTRAINT [DF_IncomingMessage_imStatus] DEFAULT ((0)) NOT NULL,
    [imProcessImmediately] BIT              CONSTRAINT [DF_IncomingMessage_imProcessImmediately] DEFAULT ((0)) NOT NULL,
    [imReceiveTime]        DATETIME2 (7)    CONSTRAINT [DF_IncomingMessage_imReceiveTime] DEFAULT (getdate()) NOT NULL,
    [imProcessTime]        DATETIME2 (7)    NULL,
    [patGUID]              UNIQUEIDENTIFIER NULL,
    [pcGUID]               UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_IncomingMessage_imGUID] PRIMARY KEY NONCLUSTERED ([imGUID] ASC)
);


GO

CREATE CLUSTERED INDEX [IDX_IncomingMessage_imReceiveTime] ON [BTS].[IncomingMessage]
(
       [imReceiveTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


GO


GO


GO


GO


