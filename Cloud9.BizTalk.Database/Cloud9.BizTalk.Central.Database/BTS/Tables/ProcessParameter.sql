CREATE TABLE [BTS].[ProcessParameter](
	[ppGUID] [uniqueidentifier] NOT NULL,
	[ppID] [bigint] IDENTITY(1,1) NOT NULL,
	[ppProcessName] [varchar](25) NOT NULL,
	[ppProcessLastRun] [datetime] NOT NULL,
 [ppStatus] SMALLINT NOT NULL, 
    CONSTRAINT [PK_BTS.ProcessParameter] PRIMARY KEY CLUSTERED 
(
	[ppGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [BTS].[ProcessParameter] ADD  CONSTRAINT [DF_ProcessParameter_ppGUID]  DEFAULT (newid()) FOR [ppGUID]
GO