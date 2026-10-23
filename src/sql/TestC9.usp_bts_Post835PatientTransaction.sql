/*
    Utility.TestC9.usp_bts_Post835PatientTransaction
    Posts one patient lockbox payment (BBVA flow A) and writes its ImportLog row.
    Replaces two BizTalk steps: BTS.Post835PatientTransaction and BTS.AddImportLog (ADO #27991).

    Copies the live BTS.Post835PatientTransaction on C9-T TestC9 (modified 2025-04-08). KnowledgeBase doc 04 describes it.
    Differences from the live procedure (Wes, 2026-10-21):
      - The procedure writes the ImportLog row in the same transaction as the post.
      - D19: if the insert writes 0 rows, the payment is an error. BizTalk reports Success.
      - The procedure handles patient payments only. It has no WEB branch.
      - The procedure uses THROW. RAISERROR cuts the message at 2,047 characters.
      - If a caller already has a transaction open, the procedure uses a savepoint.
      - @ilDateTime is optional. BizTalk sends the BizTalk server time. If the caller does not send it, the procedure uses GETDATE() (Wes, 2026-10-21).
    Same as BizTalk (D17, D18): the check number goes through CONVERT(int). Any ImportLog row with the same
    ilExternalReference blocks a retry, Failed rows too.

    ImportLog values match BizTalk flow A: level 2 and state Finished on success, level 0 and state Failed on error,
    ilMessage = ResponseMessage, ilStackTrace = '', ilExternalReference = PaymentIdentifier.

    SSMS: run the whole file. SSMS goes on after an error in one batch. The script is safe to run again (CREATE OR ALTER).
    This sprint uses only the TestC9 schema (Wes, 2026-10-21).
*/
USE [Utility];
GO

CREATE OR ALTER PROCEDURE [TestC9].[usp_bts_Post835PatientTransaction]
    @transGUID            UNIQUEIDENTIFIER,
    @transDateTime        DATETIME,
    @transDateTimePosted  DATETIME,
    @transAmount          MONEY,
    @transNote            NVARCHAR(500),
    @transReference       NVARCHAR(100),
    @ilFileName           NVARCHAR(250),
    @ilImportGUID         UNIQUEIDENTIFIER,
    @transStatus          NVARCHAR(2)      = N'N',
    @patGUID              UNIQUEIDENTIFIER = NULL,
    @ppGUID               UNIQUEIDENTIFIER = NULL,
    @transDueNowAmount    MONEY            = NULL,
    @transTotalDueAmount  MONEY            = NULL,
    @transProductionAmount MONEY           = NULL,
    @transIsGroup         NVARCHAR(100)    = NULL,
    @transCheckNumber     NVARCHAR(100)    = NULL,
    @transRouting         NVARCHAR(100)    = NULL,
    @lbcLockboxCode       NVARCHAR(100)    = NULL,
    @lbcLockboxCodeType   NVARCHAR(25)     = N'PATIENT',
    -- varchar like ImportLog.ilExternalReference. A character outside the code page becomes '?'.
    @PaymentIdentifier    VARCHAR(100)     = NULL,
    @ilProcess            NVARCHAR(50)     = N'Process_BBVA_835Patient',
    @ilDateTime           DATETIME         = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorCount      INT = 0;
    DECLARE @ResponseMessage VARCHAR(MAX) = '';
    DECLARE @StartedTran     BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @patGUIDVC       VARCHAR(64) = CAST(@patGUID AS VARCHAR(64));
    DECLARE @ppGUIDVC        VARCHAR(64) = CAST(@ppGUID AS VARCHAR(64));
    DECLARE @checkNumber     INT = NULL;
    DECLARE @patID           NVARCHAR(100) = NULL;
    DECLARE @rows            INT = 0;

    BEGIN TRY
        IF @StartedTran = 1 BEGIN TRANSACTION; ELSE SAVE TRANSACTION PostPatientPayment;

        -- TRY_CONVERT is not used, to match the live procedure. A failed conversion gives NULL.
        BEGIN TRY
            SELECT @checkNumber = CONVERT(INT, @transCheckNumber);
        END TRY
        BEGIN CATCH
            SELECT @checkNumber = NULL;
        END CATCH;

        SELECT @patID = patID FROM [TestC9].dbo.Patient WHERE patGUID = @patGUID;

        SELECT @ResponseMessage = 'Check No: '
            + ISNULL(CAST(@checkNumber AS VARCHAR(100)), '') + ', Check Date: ' + ISNULL(CAST(FORMAT(@transDateTime, 'MM/dd/yyyy') AS VARCHAR(100)), '')
            + ', Deposit Date: ' + ISNULL(CAST(FORMAT(@transDateTimePosted, 'MM/dd/yyyy') AS VARCHAR(100)), '') + ', Check Amount: ' + ISNULL(CAST((@transAmount * -1) AS VARCHAR(100)), '')
            + ', Patient ID : ' + ISNULL(@patID, '') + ', patGUID: ' + ISNULL(@patGUIDVC, '') + ', ilExternalReference: ' + ISNULL(@PaymentIdentifier, '') + ' :: ';

        IF (ISNULL(@patID, '') = '')
        BEGIN
            SELECT @ErrorCount = @ErrorCount + 1;
            SELECT @ResponseMessage = @ResponseMessage + 'Patient record not found for patGUID ' + ISNULL(@patGUIDVC, 'NULL') + '; ';
        END;

        IF NOT EXISTS (SELECT 1 FROM [TestC9].dbo.PersonPerson WHERE ppGUID = @ppGUID)
        BEGIN
            SELECT @ErrorCount = @ErrorCount + 1;
            SELECT @ResponseMessage = @ResponseMessage + 'PersonPerson record not found for ppGUID ' + ISNULL(@ppGUIDVC, 'NULL') + '; ';
        END;

        IF NOT EXISTS (SELECT 1 FROM [TestC9].BTS.PaymentType WHERE ptPaymentTypeCode = @lbcLockboxCode)
        BEGIN
            SELECT @ErrorCount = @ErrorCount + 1;
            SELECT @ResponseMessage = @ResponseMessage + 'PaymentType record not found for ptPaymentTypeCode ' + ISNULL(@lbcLockboxCode, 'NULL') + '; ';
        END;

        IF EXISTS (SELECT 1 FROM [TestC9].dbo.ImportLog WHERE ilExternalReference = @PaymentIdentifier)
        BEGIN
            SELECT @ErrorCount = @ErrorCount + 1;
            SELECT @ResponseMessage = @ResponseMessage + 'Duplicate payment for ilExternalReference ' + ISNULL(@PaymentIdentifier, '') + '; ';
        END;

        IF (@ErrorCount > 0)
        BEGIN
            DECLARE @validationMessage NVARCHAR(2048) = LEFT(@ResponseMessage, 2048);
            THROW 50000, @validationMessage, 1;
        END;

        ;WITH CTE AS
        (
            SELECT patGUID, persGUID, locGUID, empGUIDOrthodontist, orgGUID
            FROM [TestC9].dbo.Patient
            WHERE patGUID = @patGUID
        )
        INSERT INTO [TestC9].dbo.[Transaction]
        (
              transGUID, transAmount, transDateTime, orgGUID, patGUID, ttypGUID, transNote, transStatus
            , transCreditGroup, transReference, ppGUID, transClaimAmount, transDueNowAmount, transTotalDueAmount
            , transReceiptNote, transRemainingBalance, transRouting, transIsGroup, transCheckNumber
            , transDateTimePosted, transProductionAmount, empGUIDProvider, locGUIDPosted, locGUIDAssigned
            , transCardNumber, transCardType, transApprovalCode, xwebGUID, transTransactionID
        )
        SELECT
              @transGUID, @transAmount, @transDateTime, CTE.orgGUID, CTE.patGUID, tt.ttypGUID, @transNote, @transStatus
            , NULL, @transReference, pp.ppGUID, 0, @transDueNowAmount, @transTotalDueAmount
            , NULL, NULL, @transRouting, @transIsGroup, @checkNumber
            , @transDateTimePosted, @transProductionAmount, CTE.empGUIDOrthodontist, CTE.locGUID, CTE.locGUID
            , NULL, NULL, NULL, NULL, NULL
        FROM CTE
        INNER JOIN [TestC9].dbo.Person per ON per.persGUID = CTE.persGUID
        INNER JOIN [TestC9].dbo.PersonPerson pp ON pp.ppGUID = @ppGUID
        INNER JOIN [TestC9].BTS.PaymentType pt ON pt.ptPaymentTypeCode = @lbcLockboxCode
            AND pt.ptPaymentType = @lbcLockboxCodeType
        INNER JOIN [TestC9].dbo.TransactionType tt ON tt.ttypCode = pt.ttypCode;

        SELECT @rows = @@ROWCOUNT;

        -- D19: the live procedure reports Success here.
        IF (@rows = 0)
        BEGIN
            SELECT @ErrorCount = @ErrorCount + 1;
            SELECT @ResponseMessage = @ResponseMessage + 'Transaction not inserted: no matching Person, BTS.PaymentType (code '
                + ISNULL(@lbcLockboxCode, 'NULL') + ' and type ' + ISNULL(@lbcLockboxCodeType, 'NULL') + '), or TransactionType row; ';
            DECLARE @noRowMessage NVARCHAR(2048) = LEFT(@ResponseMessage, 2048);
            THROW 50000, @noRowMessage, 1;
        END;

        SELECT @ResponseMessage = @ResponseMessage + ' Success';

        INSERT INTO [TestC9].dbo.ImportLog
            (ilGUID, ilDateTime, ilFileName, ilProcess, ilLogLevel, ilMessage, ilStackTrace, ilImportGUID, ilImportState, ilExternalReference)
        VALUES
            (NEWID(), ISNULL(@ilDateTime, GETDATE()), @ilFileName, @ilProcess, 2, @ResponseMessage, N'', @ilImportGUID, N'Finished', @PaymentIdentifier);

        IF @StartedTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            IF @StartedTran = 1 ROLLBACK TRANSACTION; ELSE ROLLBACK TRANSACTION PostPatientPayment;
        END;

        SELECT @ErrorCount = @ErrorCount + 1;
        SELECT @ResponseMessage = ERROR_MESSAGE();

        BEGIN TRY
            IF NOT EXISTS (SELECT 1 FROM [TestC9].dbo.[Transaction] t WHERE t.transGUID = @transGUID)
            BEGIN
                INSERT INTO [TestC9].dbo.UnmappedTransaction
                (
                      utDateTime, utDateTimePosted, utStatus, transGUID, patGUID, utAmount, utNote, utReference
                    , utDueNowAmount, utTotalDueAmount, utProductionAmount, ppGUID, utIsGroup, utClaimAmount
                    , utCheckNumber, utRouting, ptPaymentTypeCode, utErrorMessage
                )
                VALUES
                (
                      @transDateTime, @transDateTimePosted, @transStatus, @transGUID, @patGUID, @transAmount, @transNote, @transReference
                    , @transDueNowAmount, @transTotalDueAmount, @transProductionAmount, @ppGUID, @transIsGroup, N'0'
                    , @transCheckNumber, @transRouting, @lbcLockboxCode, @ResponseMessage
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
            (NEWID(), ISNULL(@ilDateTime, GETDATE()), @ilFileName, @ilProcess, 0, @ResponseMessage, N'', @ilImportGUID, N'Failed', @PaymentIdentifier);
    END CATCH;

    SELECT @ErrorCount AS ErrorCount, @ResponseMessage AS ResponseMessage;
END;
GO
