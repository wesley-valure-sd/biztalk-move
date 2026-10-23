CREATE TABLE [BTS].[PracticeConfig](
	[pcGUID] [uniqueidentifier] NOT NULL,
	[pcInstanceAddress] [nvarchar](200) NULL,
	[pcCreatedDate] [datetime] NOT NULL,
	[pcCreatedBy] [nvarchar](50) NOT NULL,
	[pcLastModified] [datetime] NOT NULL,
	[pcLastModifiedBy] [nvarchar](50) NOT NULL,
	[pcInstanceConnectionString] [nvarchar](200) NULL,
	[pcName] [nvarchar](50) NOT NULL,
	[pcsStatusID] [smallint] NOT NULL,
	[pcRoutingPrefix] NVARCHAR(6) NULL, 
	[emdeonUserID] NVARCHAR(10) NULL,
    CONSTRAINT [PK_pcanizationConfig] PRIMARY KEY NONCLUSTERED 
(
	[pcGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [BTS].[PracticeConfig] ADD  CONSTRAINT [DF_PracticeConfig_pcGUID]  DEFAULT (newid()) FOR [pcGUID]
GO

ALTER TABLE [BTS].[PracticeConfig] ADD  CONSTRAINT [DF_PracticeConfig_pcCreatedDate]  DEFAULT (getdate()) FOR [pcCreatedDate]
GO

ALTER TABLE [BTS].[PracticeConfig] ADD  CONSTRAINT [DF_PracticeConfig_pcLastModified]  DEFAULT (getdate()) FOR [pcLastModified]
GO

ALTER TABLE [BTS].[PracticeConfig] ADD  CONSTRAINT [DF_PracticeConfig_pcsStatusID]  DEFAULT ((1)) FOR [pcsStatusID]
GO

ALTER TABLE [BTS].[PracticeConfig]  WITH CHECK ADD  CONSTRAINT [FK_PracticeConfig_PracticeConfigStatus] FOREIGN KEY([pcsStatusID])
REFERENCES [BTS].[PracticeConfigStatus] ([pcsStatusID])
GO

ALTER TABLE [BTS].[PracticeConfig] CHECK CONSTRAINT [FK_PracticeConfig_PracticeConfigStatus]
GO