CREATE TABLE [BTS].[HL7InboundStaging] (
    [hisStagingID]               BIGINT           IDENTITY (1, 1) NOT NULL,
	[hisGUID] 					 UNIQUEIDENTIFIER DEFAULT NEWID() ,
    [imGUID]                     UNIQUEIDENTIFIER NOT NULL,
    [pcGUID]                     UNIQUEIDENTIFIER NOT NULL,
    [hisEPICPatientID]           NVARCHAR (100)   NOT NULL,
    [hisCloud9PatientID]         UNIQUEIDENTIFIER NULL,
    [hisMessageType]             NVARCHAR (10)    NOT NULL,
    [hisMSH_7_DateTimeOfMessage] NVARCHAR (20)    NOT NULL,
    [hisMSH_10_MessageControlId] NVARCHAR (20)    NOT NULL,
    [hisMessageData]             XML              NOT NULL,
    [hisStatus]                  SMALLINT         NOT NULL,
    [hisCreatedDate]             DATETIME         NOT NULL,
    [hisCreatedBy]               NVARCHAR (50)    NOT NULL,
    [hisLastModifiedDate]        DATETIME         NOT NULL,
    [hisLastModifiedBy]          NVARCHAR (50)    NOT NULL,
    CONSTRAINT [PK_HL7InboundStaging] PRIMARY KEY NONCLUSTERED ([hisGUID] ASC),
    CONSTRAINT [FK_HL7InboundStaging_To_IncomingMessage] FOREIGN KEY ([imGUID]) REFERENCES [BTS].[IncomingMessage]([imGUID]), 
    CONSTRAINT [FK_HL7InboundStaging_To_StagingStatus] FOREIGN KEY ([hisStatus]) REFERENCES [BTS].[StagingStatus]([stsStatusID])
);

GO

CREATE CLUSTERED INDEX [IX_HL7InboundStaging_Column] ON [BTS].[HL7InboundStaging] ([hisStagingID])
