CREATE TABLE [BTS].[StagingStatus] (
    [stsStatusID]          SMALLINT       NOT NULL,
    [stsStatusDescription] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_StagingStatus] PRIMARY KEY CLUSTERED ([stsStatusID] ASC)
);



