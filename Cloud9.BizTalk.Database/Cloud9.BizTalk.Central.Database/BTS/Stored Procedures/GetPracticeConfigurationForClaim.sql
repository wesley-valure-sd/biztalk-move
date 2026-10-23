
-- =============================================
-- Author:		James Jordan
-- Create date: 2019/08/15
-- Description:	Retrieves Configuration information by pcRoutingPrefix for BizTalk Routing
-- =============================================
CREATE PROCEDURE [BTS].[GetPracticeConfigurationForClaim]
	@pcRoutingPrefix NVARCHAR(6) = NULL,
	@adaclaimBox23PatientAccountID NVARCHAR(30) = NULL,
    @adaclaimNumber INT = NULL,
    @pracTIN NVARCHAR(50) = NULL,
    @pracProviderNumber NVARCHAR(50) = NULL,
    @pracLicenseNumber NVARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @pcGUID UNIQUEIDENTIFIER = NULL;

	IF @pcRoutingPrefix IS NOT NULL
	BEGIN
		SELECT 
			@pcGUID = [pcGUID]
		FROM [BTS].[PracticeConfig]
		WHERE [pcRoutingPrefix] = @pcRoutingPrefix
	END

	IF @pcGUID IS NULL
	BEGIN
		SELECT 
			@pcGUID = [pcGUID]
		FROM [BTS].[SubmittedClaim]
		WHERE adaclaimBox23PatientAccountID = @adaclaimBox23PatientAccountID
			AND adaclaimNumber = @adaclaimNumber
			AND pracTIN = @pracTIN
			AND pracProviderNumber = @pracProviderNumber
			AND pracLicenseNumber = @pracLicenseNumber

	END

	IF @pcGUID IS NULL
	BEGIN
		SELECT 
			@pcGUID = [pcGUID]
		FROM [BTS].[SubmittedClaim]
		WHERE adaclaimBox23PatientAccountID = @adaclaimBox23PatientAccountID
			AND adaclaimNumber = @adaclaimNumber
			AND pracTIN = @pracTIN
	END

	SELECT
		 [pcGUID]
		,[pcInstanceAddress]
		,[pcInstanceConnectionString]
		,[pcName]
	FROM [BTS].[PracticeConfig]
	WHERE pcGUID = @pcGUID

END