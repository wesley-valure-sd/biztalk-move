CREATE TABLE [BTS].[ProcessingError] (
    [peID]           BIGINT           IDENTITY (1, 1) NOT NULL,
    [peMessageID]    NVARCHAR (100)   NOT NULL,
    [ifGUID]         UNIQUEIDENTIFIER NULL,
    [peMessageType]  NVARCHAR (10)    NOT NULL,
    [peErrorMessage] NVARCHAR (1000)  NOT NULL,
    [peCreatedDate]  DATETIME         NOT NULL,
    [peCreatedBy]    NVARCHAR (50)    NOT NULL,
    CONSTRAINT [PK_ProcessingError] PRIMARY KEY CLUSTERED ([peID] ASC)
);



