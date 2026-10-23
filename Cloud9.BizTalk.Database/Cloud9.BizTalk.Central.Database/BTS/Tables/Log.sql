CREATE TABLE [BTS].[Log](
	[logGUID] [uniqueidentifier] NOT NULL,
	[pcInstanceAddress] [nvarchar](200) NULL,
	[logProcess] [varchar](50) NULL,
	[logType] [varchar](50) NULL,
	[logMessage] [varchar](max) NULL,
	[logInternalEntityId] [varchar](100) NULL,
	[logExternalEntityId] [varchar](100) NULL,
	[logRequest] [varchar](max) NULL,
	[logStackTrace] [varchar](max) NULL,
	[logCreatedDate] [datetime] NOT NULL,
	[logCreatedBy] [varchar](50) NULL,
 CONSTRAINT [PK_Log] PRIMARY KEY NONCLUSTERED 
(
	[logGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [IDX_Log_logCreatedDate] ON [BTS].[Log]
(
	[logCreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

ALTER TABLE [BTS].[Log] ADD  CONSTRAINT [DF_Log_logGUID]  DEFAULT (newid()) FOR [logGUID]
GO

ALTER TABLE [BTS].[Log] ADD  CONSTRAINT [DF_Log_logCreatedDate]  DEFAULT (getdate()) FOR [logCreatedDate]