/*
    Utility.TestC9.usp_bts_Post835InsuranceTransaction and Utility.TestC9.usp_bts_AddImportLog
    Post one insurance lockbox payment or PLB adjustment (BBVA flow C) and write its ImportLog row, and write a
    log-only row for a transaction set that BizTalk does not post (the CLP/PLB guard). ADO #28343.
    Replaces two BizTalk steps: BTS.Post835InsuranceTransaction and BTS.AddImportLog.

    Copies the live BTS.Post835InsuranceTransaction on C9-T TestC9 (modified 2025-04-08, read 2026-10-29). KnowledgeBase
    doc 04 describes it. All 14,344 C9-P flow C ImportLog rows since 2026-09-01 match its message shape.
    Same as BizTalk (Wes, 2026-10-29): D23 (a CLP01 that is not an int fails on the ADAClaim lookup), D24 (an L6
    adjustment is checked for duplicates and fails on its claim's REF*F8), D25 (any ImportLog row with the same
    ilExternalReference blocks a retry), D8 (an L6 posts an L6C row and an L6P row).
    Differences from the live procedure, as in usp_bts_Post835PatientTransaction:
      - The ImportLog row is written in the same transaction as the post (D22).
      - THROW instead of RAISERROR: RAISERROR reads '%' as a format character and cuts at 2,047 characters.
      - A deadlock (1205) is retried up to 3 times before the ImportLog row, because a Failed row with the REF*F8 blocks
        every later retry (D25, D27). BizTalk logs the deadlock and the payment is lost.
      - If a caller already has a transaction open, the procedure uses a savepoint and does not retry.
      - The aging check runs through [TestC9].sys.sp_executesql: the dbo.IDList table type cannot be declared in Utility.
    ImportLog values match BizTalk flow C (production C9-GulfCoast, 2026-10-29): level 2 and state Finished on success,
    level 0 and state Failed on error, ilMessage = 'ADJ - ' + ResponseMessage for an adjustment, ilStackTrace = '',
    ilExternalReference = REF*F8 or '' (production has '' for a claim without REF*F8; the practice logic receives NULL,
    so a missing REF*F8 never matches the duplicate check).

    SSMS: run the whole file. The script is safe to run again (CREATE OR ALTER). This sprint uses only the TestC9 schema.
*/
USE [Utility];
GO

CREATE OR ALTER PROCEDURE [TestC9].[usp_bts_AddImportLog]
    @ilFileName          NVARCHAR(250),
    @ilProcess           NVARCHAR(50),
    @ilLogLevel          INT,
    @ilMessage           NVARCHAR(MAX),
    @ilImportGUID        UNIQUEIDENTIFIER,
    @ilImportState       NVARCHAR(50),
    @ilExternalReference VARCHAR(100) = NULL,
    @ilDateTime          DATETIME     = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [TestC9].dbo.ImportLog
        (ilGUID, ilDateTime, ilFileName, ilProcess, ilLogLevel, ilMessage, ilStackTrace, ilImportGUID, ilImportState, ilExternalReference)
    VALUES
        (NEWID(), ISNULL(@ilDateTime, GETDATE()), @ilFileName, @ilProcess, @ilLogLevel, @ilMessage, N'', @ilImportGUID, @ilImportState, @ilExternalReference);
END;
GO

CREATE OR ALTER PROCEDURE [TestC9].[usp_bts_Post835InsuranceTransaction]
    @transGUID             UNIQUEIDENTIFIER,
    @transDateTime         DATETIME,
    @transDateTimePosted   DATETIME,
    @transAmount           MONEY,
    @transNote             NVARCHAR(500),
    @transReference        NVARCHAR(100),
    @transCheckNumber      NVARCHAR(100),
    @ptPaymentTypeCode     NVARCHAR(3),
    @ilFileName            NVARCHAR(250),
    @ilImportGUID          UNIQUEIDENTIFIER,
    @transStatus           NVARCHAR(2)      = N'N',
    @patGUID               UNIQUEIDENTIFIER = NULL,
    @pipGUID               UNIQUEIDENTIFIER = NULL,
    @transReceiptNote      NVARCHAR(250)    = NULL,
    @transDueNowAmount     MONEY            = NULL,
    @transTotalDueAmount   MONEY            = NULL,
    @transProductionAmount MONEY            = NULL,
    @transIsGroup          NVARCHAR(100)    = NULL,
    @transClaimAmount      NVARCHAR(100)    = NULL,
    @transRouting          NVARCHAR(100)    = NULL,
    @adaClaimNumber        NVARCHAR(100)    = NULL,
    @pipPolicyNumber       NVARCHAR(100)    = NULL,
    @ClaimIdentifier       NVARCHAR(100)    = NULL,
    @PaymentIdentifier     NVARCHAR(100)    = NULL,
    @AdjustmentType        VARCHAR(2)       = NULL,
    @ilProcess             NVARCHAR(50)     = N'Process_BBVA_835Insurance',
    @ilDateTime            DATETIME         = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartedTran     BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @pipGUIDIn       UNIQUEIDENTIFIER = @pipGUID;
    DECLARE @paymentTypeIn   NVARCHAR(3) = @ptPaymentTypeCode;
    DECLARE @messagePrefix   NVARCHAR(10) = CASE WHEN @AdjustmentType IS NULL THEN N'' ELSE N'ADJ - ' END;
    DECLARE @externalRef     VARCHAR(100) = ISNULL(@PaymentIdentifier, '');
    DECLARE @attempt         INT = 0;
    DECLARE @retry           BIT = 1;
    DECLARE @ErrorCount      INT;
    DECLARE @ResponseMessage VARCHAR(MAX);
    DECLARE @insuranceName   NVARCHAR(100);
    DECLARE @patID           NVARCHAR(100);
    DECLARE @checkNumber     INT;
    DECLARE @adaClaimGUID    VARCHAR(64);
    DECLARE @rows            INT;
    DECLARE @totalDue        MONEY;

    -- Because TRY_CONVERT is not available in SQL Server 2008 compatibility mode (same as the live procedure).
    BEGIN TRY
        SELECT @checkNumber = CONVERT(INT, @transCheckNumber);
    END TRY
    BEGIN CATCH
        SELECT @checkNumber = NULL;
    END CATCH;

    WHILE @retry = 1
    BEGIN
        SELECT @retry = 0, @attempt = @attempt + 1, @ErrorCount = 0, @ResponseMessage = '', @insuranceName = NULL,
               @patID = NULL, @adaClaimGUID = NULL, @rows = 0, @totalDue = NULL,
               @pipGUID = @pipGUIDIn, @ptPaymentTypeCode = @paymentTypeIn;

        BEGIN TRY
            IF @StartedTran = 1 BEGIN TRANSACTION; ELSE SAVE TRANSACTION PostInsurancePayment;

            -- If pipGUID IS NULL, find it from the claim and the policy number of the 835.
            IF (@pipGUID IS NULL)
            BEGIN
                SELECT @adaClaimGUID = c.adaclaimGUID, @pipGUID = pip.pipGUID
                FROM [TestC9].dbo.ADAClaim c
                INNER JOIN [TestC9].dbo.PatientInsurancePolicy pip ON pip.pipGUID = c.pipGUID
                    AND pip.pipPolicyNumber = @pipPolicyNumber
                    AND (pip.pipDeleted IS NULL OR pip.pipDeleted = 0)
                WHERE c.adaclaimNumber = @adaClaimNumber;
            END;

            SELECT @insuranceName = icbc.icbcName
            FROM [TestC9].dbo.PatientInsurancePolicy pip
            JOIN [TestC9].dbo.InsuranceCompanyBillingCenter icbc ON icbc.icbcGUID = pip.icbcGUID
            WHERE pip.pipGUID = @pipGUID;

            SELECT @patID = patID FROM [TestC9].dbo.Patient WHERE patGUID = @patGUID;

            SELECT @ResponseMessage = 'Check No: '
                + ISNULL(CAST(@checkNumber AS VARCHAR(100)), '') + ', Claim No: ' + ISNULL(@adaClaimNumber, '') + ', Check Date: ' + ISNULL(CAST((FORMAT(@transDateTime, 'MM/dd/yyyy')) AS VARCHAR(100)), '')
                + ', Deposit Date: ' + ISNULL(CAST((FORMAT(@transDateTimePosted, 'MM/dd/yyyy')) AS VARCHAR(100)), '') + ', Check Amount: ' + ISNULL(CAST((@transAmount * -1) AS VARCHAR(100)), '') + ', Insurance Co: ' + ISNULL(@insuranceName, '')
                + ', Policy No: ' + ISNULL(@pipPolicyNumber, '') + ', Patient ID : ' + ISNULL(@patID, '') + ', PaymentType: ' + ISNULL(@ptPaymentTypeCode, '') + ', pipGUID: ' + ISNULL(CAST(@pipGUID AS VARCHAR(64)), '')
                + ', patGUID: ' + ISNULL(CAST(@patGUID AS VARCHAR(64)), '') + ', ilExternalReference: ' + ISNULL(@PaymentIdentifier, '') + ' :: ';

            IF @pipGUID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [TestC9].dbo.PatientInsurancePolicy pip WHERE pip.pipGUID = @pipGUID)
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = @ResponseMessage + 'PatientInsurancePolicy record not found for pipGUID ' + CAST(@pipGUID AS VARCHAR(64)) + '; ';
            END;

            IF @pipGUID IS NULL AND NOT EXISTS (SELECT 1 FROM [TestC9].dbo.ADAClaim c WHERE c.adaclaimNumber = @adaClaimNumber)
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = @ResponseMessage + 'Could not locate Claim ' + ISNULL(@adaClaimNumber, 'n/a') + '; ';
            END;

            IF @pipGUID IS NULL AND NOT EXISTS (SELECT 1 FROM [TestC9].dbo.ADAClaim c
                INNER JOIN [TestC9].dbo.PatientInsurancePolicy pip ON c.adaclaimNumber = @adaClaimNumber AND pip.pipGUID = c.pipGUID
                AND pip.pipPolicyNumber = @pipPolicyNumber
                AND (pip.pipDeleted IS NULL OR pip.pipDeleted = 0))
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = @ResponseMessage + 'Could not locate Insurance Policy for Policy Number ' + ISNULL(@pipPolicyNumber, 'n/a') + ', adaClaimNumber ' + ISNULL(@adaClaimNumber, 'NULL') + '; ';
            END;

            IF NOT EXISTS (SELECT 1 FROM [TestC9].BTS.PaymentType WHERE ptPaymentTypeCode = @ptPaymentTypeCode)
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = @ResponseMessage + 'PaymentType record not found for ptPaymentTypeCode ' + ISNULL(@ptPaymentTypeCode, 'n/a') + '; ';
            END;

            -- adaclaimNumber is an int: a CLP01 that is not an int raises a conversion error here (D23).
            SELECT @adaClaimGUID = c.adaClaimGUID FROM [TestC9].dbo.ADAClaim c WHERE c.adaclaimNumber = @adaClaimNumber;

            IF (@AdjustmentType IS NOT NULL AND @AdjustmentType <> 'L6')
                SET @ptPaymentTypeCode = 'PLB';

            -- D24, D25: any ImportLog row with the reference blocks the payment, except for type PLB.
            IF EXISTS (SELECT 1 FROM [TestC9].dbo.ImportLog WHERE ilExternalReference = @PaymentIdentifier AND @ptPaymentTypeCode <> 'PLB')
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = @ResponseMessage + 'Duplicate payment for ilExternalReference ' + ISNULL(@PaymentIdentifier, '') + '; ';
            END;

            IF (@ErrorCount > 0)
            BEGIN
                DECLARE @validationMessage NVARCHAR(2048) = LEFT(@ResponseMessage, 2048);
                THROW 50000, @validationMessage, 1;
            END;

            IF (@AdjustmentType IS NULL OR @AdjustmentType <> 'L6')
            BEGIN
                INSERT INTO [TestC9].dbo.[Transaction]
                (
                      transGUID, transAmount, transDateTime, orgGUID, patGUID, ttypGUID, transNote, transStatus
                    , transDebitGroup, transCreditGroup, transReference, ppGUID, pipGUID, transClaimAmount, adaclaimGUID
                    , transDueNowAmount, transTotalDueAmount, transReceiptNote, transRemainingBalance, transRouting, transIsGroup
                    , transCheckNumber, transDateTimePosted, transProductionAmount, empGUIDProvider, locGUIDPosted, locGUIDAssigned
                )
                SELECT
                      @transGUID, @transAmount, @transDateTime, pip.orgGUID, pip.patGUID, tt.ttypGUID, @transNote, @transStatus
                    , NULL, NULL, @transReference, pip.ppGUID, pip.pipGUID, 0, NULL
                    , @transDueNowAmount, @transTotalDueAmount, @transReceiptNote, NULL, @transRouting, @transIsGroup
                    , @checkNumber, @transDateTimePosted, @transProductionAmount, p.empGUIDOrthodontist, p.locGUID, p.locGUID
                FROM [TestC9].dbo.PatientInsurancePolicy pip
                INNER JOIN [TestC9].dbo.Patient p ON p.patGUID = pip.patGUID
                INNER JOIN [TestC9].dbo.Person per ON per.persGUID = p.persGUID
                INNER JOIN [TestC9].BTS.PaymentType pt ON pt.ptPaymentTypeCode = @ptPaymentTypeCode
                    AND pt.ptPaymentType = 'INSURANCE'
                INNER JOIN [TestC9].dbo.TransactionType tt ON tt.ttypCode = pt.ttypCode
                WHERE pip.pipGUID = @pipGUID;
                SELECT @rows = @@ROWCOUNT;
            END
            ELSE
            BEGIN
                -- D8: an L6 adjustment posts an L6C (charge) row and an L6P (payment) row with new GUIDs.
                INSERT INTO [TestC9].dbo.[Transaction]
                (
                      transGUID, transAmount, transDateTime, orgGUID, patGUID, ttypGUID, transNote, transStatus
                    , transDebitGroup, transCreditGroup, transReference, ppGUID, pipGUID, transClaimAmount, adaclaimGUID
                    , transDueNowAmount, transTotalDueAmount, transReceiptNote, transRemainingBalance, transRouting, transIsGroup
                    , transCheckNumber, transDateTimePosted, transProductionAmount, empGUIDProvider, locGUIDPosted, locGUIDAssigned
                )
                SELECT
                      NEWID(), CASE WHEN pt.ptPaymentTypeCode = 'L6C' THEN (@transAmount * -1) ELSE @transAmount END
                    , @transDateTime, pip.orgGUID, pip.patGUID, tt.ttypGUID, @transNote, @transStatus
                    , CASE WHEN pt.ptPaymentTypeCode = 'L6C' THEN NEWID() ELSE NULL END
                    , CASE WHEN pt.ptPaymentTypeCode = 'L6P' THEN NEWID() ELSE NULL END
                    , @transReference, pip.ppGUID, pip.pipGUID, 0, NULL
                    , CASE WHEN pt.ptPaymentTypeCode = 'L6C' THEN (@transDueNowAmount * -1) ELSE @transDueNowAmount END
                    , CASE WHEN pt.ptPaymentTypeCode = 'L6C' THEN (@transTotalDueAmount * -1) ELSE @transTotalDueAmount END
                    , @transReceiptNote, NULL, @transRouting, @transIsGroup
                    , @checkNumber, @transDateTimePosted, @transProductionAmount, p.empGUIDOrthodontist, p.locGUID, p.locGUID
                FROM [TestC9].dbo.PatientInsurancePolicy pip
                INNER JOIN [TestC9].dbo.Patient p ON p.patGUID = pip.patGUID
                INNER JOIN [TestC9].dbo.Person per ON per.persGUID = p.persGUID
                INNER JOIN [TestC9].BTS.PaymentType pt ON pt.ptPaymentTypeCode IN ('L6C', 'L6P')
                    AND pt.ptPaymentType = 'INSURANCE'
                INNER JOIN [TestC9].dbo.TransactionType tt ON tt.ttypCode = pt.ttypCode
                WHERE pip.pipGUID = @pipGUID;
                SELECT @rows = @@ROWCOUNT;
            END;

            IF (@rows = 0)
            BEGIN
                SELECT @ResponseMessage = @ResponseMessage + '[Transaction] Record Not Created for adaclaimGUID ' + ISNULL(@adaClaimGUID, 'n/a')
                    + ' AND transReference ' + ISNULL(@transReference, 'n/a') + '; ';
                DECLARE @noRowMessage NVARCHAR(2048) = LEFT(@ResponseMessage, 2048);
                THROW 50000, @noRowMessage, 1;
            END;

            -- dbo.IDList lives in TestC9, so the aging call runs in that database.
            EXEC [TestC9].sys.sp_executesql
                N'DECLARE @Providers dbo.IDList, @Locations dbo.IDList;
                  INSERT INTO @Locations (ID)
                  SELECT trans.locGUIDAssigned
                  FROM dbo.Patient pat
                  INNER JOIN dbo.PatientInsurancePolicy pip ON pip.patGUID = pat.patGUID
                  INNER JOIN dbo.[Transaction] trans ON trans.patGUID = pat.patGUID AND trans.pipGUID = pip.pipGUID
                  WHERE pat.patGUID = @patGUID
                  GROUP BY locGUIDAssigned;
                  INSERT INTO @Providers (ID)
                  SELECT trans.empGUIDProvider
                  FROM dbo.Patient pat
                  INNER JOIN dbo.PatientInsurancePolicy pip ON pip.patGUID = pat.patGUID
                  INNER JOIN dbo.[Transaction] trans ON trans.patGUID = pat.patGUID AND trans.pipGUID = pip.pipGUID
                  WHERE pat.patGUID = @patGUID
                  GROUP BY empGUIDProvider;
                  SELECT @totalDue = TotalDue FROM dbo.udfGetAgingAsOfDate(@patGUID, NULL, @pipGUID, GETDATE(), @Locations, @Providers, NULL);',
                N'@patGUID UNIQUEIDENTIFIER, @pipGUID UNIQUEIDENTIFIER, @totalDue MONEY OUTPUT',
                @patGUID = @patGUID, @pipGUID = @pipGUID, @totalDue = @totalDue OUTPUT;

            -- The transAmount value is a negative amount for a regular payment.
            IF (@transAmount * -1) > @totalDue
                SELECT @ResponseMessage = @ResponseMessage + ' Payment amount exceeds remaining balance.';

            SELECT @ResponseMessage = @ResponseMessage + ' Success';

            INSERT INTO [TestC9].dbo.ImportLog
                (ilGUID, ilDateTime, ilFileName, ilProcess, ilLogLevel, ilMessage, ilStackTrace, ilImportGUID, ilImportState, ilExternalReference)
            VALUES
                (NEWID(), ISNULL(@ilDateTime, GETDATE()), @ilFileName, @ilProcess, 2, @messagePrefix + @ResponseMessage, N'', @ilImportGUID, N'Finished', @externalRef);

            IF @StartedTran = 1 COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
            BEGIN
                IF @StartedTran = 1 ROLLBACK TRANSACTION; ELSE ROLLBACK TRANSACTION PostInsurancePayment;
            END;

            IF ERROR_NUMBER() = 1205 AND @StartedTran = 1 AND @attempt < 3
            BEGIN
                SET @retry = 1;
                WAITFOR DELAY '00:00:01';
            END
            ELSE
            BEGIN
                SELECT @ErrorCount = @ErrorCount + 1;
                SELECT @ResponseMessage = ERROR_MESSAGE();

                BEGIN TRY
                    -- If the payment was not posted, write it into the UnmappedTransaction table (as the live procedure does).
                    IF NOT EXISTS (SELECT 1 FROM [TestC9].dbo.[Transaction] t WHERE t.transGUID = @transGUID)
                    BEGIN
                        INSERT INTO [TestC9].dbo.UnmappedTransaction
                        (
                              utDateTime, utDateTimePosted, utStatus, transGUID, locGUIDPosted, locGUIDAssigned, empGUIDProvider, patGUID, ttypGUID
                            , utDebitGroup, utCreditGroup, utAmount, utNote, utReceiptNote, utReference, utDueNowAmount, utTotalDueAmount
                            , utProductionAmount, ppGUID, persGUIDRelated, pipGUID, orgGUID, utIsGroup, utClaimAmount, utCheckNumber
                            , utRouting, adaClaimNumber, pipPolicyNumber, ptPaymentTypeCode, utErrorMessage
                        )
                        VALUES
                        (
                              @transDateTime, @transDateTimePosted, @transStatus, @transGUID, NULL, NULL, NULL, @patGUID, NULL
                            , NULL, NULL, @transAmount, @transNote, @transReceiptNote, @transReference, @transDueNowAmount, @transTotalDueAmount
                            , @transProductionAmount, NULL, NULL, @pipGUID, NULL, @transIsGroup, @transClaimAmount, @transCheckNumber
                            , @transRouting, @adaClaimNumber, @pipPolicyNumber, @ptPaymentTypeCode, @ResponseMessage
                        );
                    END;
                END TRY
                BEGIN CATCH
                    SELECT @ResponseMessage = @ResponseMessage + ' UnmappedTransaction insert failed: ' + ERROR_MESSAGE();
                END CATCH;

                -- The Failed row is written after the rollback, so it stays.
                INSERT INTO [TestC9].dbo.ImportLog
                    (ilGUID, ilDateTime, ilFileName, ilProcess, ilLogLevel, ilMessage, ilStackTrace, ilImportGUID, ilImportState, ilExternalReference)
                VALUES
                    (NEWID(), ISNULL(@ilDateTime, GETDATE()), @ilFileName, @ilProcess, 0, @messagePrefix + @ResponseMessage, N'', @ilImportGUID, N'Failed', @externalRef);
            END;
        END CATCH;
    END;

    SELECT @ErrorCount AS ErrorCount, @ResponseMessage AS ResponseMessage;
END;
GO
