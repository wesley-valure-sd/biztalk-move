CREATE TABLE [BTS].[SubmittedClaim] (
    [scGUID] 						UNIQUEIDENTIFIER NOT NULL,
    [pcGUID] 						UNIQUEIDENTIFIER NOT NULL,
    [adaClaimGUID] 					UNIQUEIDENTIFIER NOT NULL,
    [adaclaimBox23PatientAccountID] NVARCHAR (30) NULL,
    [adaclaimTotal]                 MONEY         NULL,
    [adaclaimNumber]                INT           NOT NULL,
    [pracTIN]                       NVARCHAR (50) NULL,
    [pracProviderNumber]            NVARCHAR (50) NULL,
    [pracLicenseNumber]             NVARCHAR (50) NULL, 
    CONSTRAINT [PK_SubmittedClaim] PRIMARY KEY NONCLUSTERED ([scGUID]), 
    CONSTRAINT [FK_SubmittedClaim_ToTable] FOREIGN KEY ([pcGUID]) REFERENCES [BTS].[PracticeConfig]([pcGUID]) 
);

