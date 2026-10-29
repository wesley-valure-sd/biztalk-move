# Data contracts for the payment flows

This document lists every interface that the payment flows use. A replacement application must produce the same calls and data.

Source of truth for each table: the WCF-SQL schema in this repository. The practice database procedures are **not** in this repository. Before you build the replacement, read the real signature from one practice database. Use the query in [Read the live procedure signatures](#read-the-live-procedure-signatures).

## Databases

| Database                                  | Location                                                                                                                                                                     | Contents used by the payment flows                                                                                                                                                                                                                                                                                              |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BizTalkCloud9Common` (central)           | Address from setting `ADDR_DB_CLOUD9COMMON`. Production value in the settings file: `mssql://c9-p-sql-01//BizTalkCloud9Common` (SDProd1 column). Confirm the current server. | `BTS.PracticeConfig`, `BTS.ApplicationLookupValue`, `BTS.Log`, `BTS.ProcessParameter`, procedures `GetPracticeConfigurationByName`, `GetApplicationLookupValues`, `CreateLogEntry`, `QueueProcessParameters`, `UpdateProcessParameters`                                                                                         |
| Practice database (one for each practice) | `BTS.PracticeConfig.pcInstanceAddress` (WCF-SQL URI) or `pcInstanceConnectionString`                                                                                         | Procedures `BTS.Post835PatientTransaction`, `BTS.Post835InsuranceTransaction`, `BTS.AddImportLog`, `BTS.AddTodoItem`, `BTS.GetPracticeEDISettings`. Tables `[Transaction]`, `TransactionType`, `BTS.PaymentType`, `ImportLog`, `UnmappedTransaction`, `ADAClaim`, `PatientInsurancePolicy`, `Patient`, `Person`, `PersonPerson` |

## Central database

### BTS.PracticeConfig

Source: [PracticeConfig.sql](../../Cloud9.BizTalk.Database/Cloud9.BizTalk.Central.Database/BTS/Tables/PracticeConfig.sql).

| Column                                                               | Type                                    | Use                                                                                                                                                                                |
| -------------------------------------------------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pcGUID`                                                             | uniqueidentifier, PK, default `newid()` | Practice key                                                                                                                                                                       |
| `pcName`                                                             | nvarchar(50), not null                  | Lookup key. Equals the region folder name (BBVA), `SD-<REGION>` (SD web), or the CHC file prefix. The refactor log shows a unique index `UIX_PracticeConfig_pcName` **(inferred)** |
| `pcInstanceAddress`                                                  | nvarchar(200)                           | WCF-SQL address of the practice database                                                                                                                                           |
| `pcInstanceConnectionString`                                         | nvarchar(200)                           | ADO.NET connection string (not used by the payment orchestrations)                                                                                                                 |
| `pcsStatusID`                                                        | smallint, default 1                     | FK to `PracticeConfigStatus`. Seed: 0 = Active, 1 = Inactive. The lookup procedure ignores this column                                                                             |
| `pcRoutingPrefix`                                                    | nvarchar(6)                             | Claim routing prefix (claims flows)                                                                                                                                                |
| `emdeonUserID`                                                       | nvarchar(10)                            | Change Healthcare user (277 flows)                                                                                                                                                 |
| `pcCreatedDate`, `pcCreatedBy`, `pcLastModified`, `pcLastModifiedBy` | audit                                   |                                                                                                                                                                                    |

### BTS.GetPracticeConfigurationByName

| Direction          | Name                                                        | Type         |
| ------------------ | ----------------------------------------------------------- | ------------ |
| In                 | `@pcName`                                                   | NVARCHAR(50) |
| Out (result set 0) | `pcGUID`, `pcInstanceAddress`, `pcInstanceConnectionString` |              |

### BTS.GetApplicationLookupValues (flow E)

| Direction | Name                                                                             | Type        |
| --------- | -------------------------------------------------------------------------------- | ----------- |
| In        | `@alvApplication`                                                                | VARCHAR(50) |
| In        | `@alvLookup`                                                                     | VARCHAR(50) |
| Out       | `alvGUID`, `alvApplication`, `alvLookup`, `alvKey`, `alvValue`, `alvDescription` |             |

Seed rows ([BizTalkCloud9Common.PostDeployment.sql](../../Cloud9.BizTalk.Database/Cloud9.BizTalk.Central.Database/BizTalkCloud9Common.PostDeployment.sql)):

| alvApplication | alvLookup  | alvKey                   | alvValue              |
| -------------- | ---------- | ------------------------ | --------------------- |
| CHC835ToBBVA   | 1000000004 | AgreementNameForSend     | ChangeHealthcare_BBVA |
| CHC835ToBBVA   | 1000000004 | SenderPartyNameForSend   | ChangeHealthcare      |
| CHC835ToBBVA   | 1000000004 | ReceiverPartyNameForSend | BBVA                  |

### BTS.CreateLogEntry and BTS.Log (flow D errors)

`BTS.CreateLogEntry(@pcInstanceAddress NVARCHAR(200), @Process VARCHAR(50), @Type VARCHAR(50), @Message VARCHAR(MAX), @InternalEntityID VARCHAR(100) = NULL, @ExternalEntityID VARCHAR(100) = NULL, @StackTrace VARCHAR(MAX) = NULL, @CreatedBy VARCHAR(50) = NULL)` inserts one row into `BTS.Log`. The orchestration `Cloud9.BizTalk.Common.AddLog` builds the request by string concatenation and puts the message in a CDATA block.

### BTS.ProcessParameter and BTS.QueueProcessParameters (flow D schedule)

`QueueProcessParameters(@processName varchar(25))` takes the newest row with `ppProcessName = @processName AND ppStatus = 0`, sets `ppStatus = 1`, and returns two result sets: a header (`ppID`, `fromDateTime` = `ppProcessLastRun`, `toDateTime` = now, `processName`) and every `PracticeConfig` row (`pcGUID`, `pcInstanceAddress`, `pcInstanceConnectionString`, `pcRoutingPrefix`, `pcName`). See [QueueProcessParameters.sql](../../Cloud9.BizTalk.Database/Cloud9.BizTalk.Central.Database/BTS/Stored%20Procedures/QueueProcessParameters.sql).

## Practice database procedures

### BTS.Post835PatientTransaction (flows A and B)

Schema: [Post835TypedProcedure.BTS.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.Schemas/Post835/Post835TypedProcedure.BTS.xsd). All parameters are optional and nullable in the schema.

| Parameter                             | Type        | Flow A value                         | Flow B value                       |
| ------------------------------------- | ----------- | ------------------------------------ | ---------------------------------- |
| `transDateTime`                       | datetime    | Processing time                      | Processing time                    |
| `transDateTimePosted`                 | datetime    | Processing time                      | Processing time                    |
| `transStatus`                         | string(2)   | `N`                                  | `N`                                |
| `transGUID`                           | guid        | New GUID                             | New GUID                           |
| `locGUIDPosted`                       | guid        | Not sent                             | Not sent                           |
| `locGUIDAssigned`                     | guid        | Not sent                             | Not sent                           |
| `empGUIDProvider`                     | guid        | Not sent                             | Not sent                           |
| `patGUID`                             | guid        | NM1*QC NM109                         | NM1 NM109 (first NM1)              |
| `ttypGUID`                            | guid        | Not sent (the procedure resolves it) | Not sent                           |
| `transDebitGroup`, `transCreditGroup` | guid        | Not sent                             | Not sent                           |
| `transAmount`                         | decimal     | -CLP04                               | -CLP04                             |
| `transNote`                           | string(500) | Deposit/check/lockbox note           | `FormatNote` result                |
| `transReceiptNote`                    | string(250) | Not sent                             | `FormatNote` result                |
| `transReference`                      | string(100) | TRN02                                | Masked bank account or masked card |
| `transDueNowAmount`                   | decimal     | -CLP04                               | -CLP04                             |
| `transTotalDueAmount`                 | decimal     | -CLP04                               | -CLP04                             |
| `transProductionAmount`               | decimal     | 0                                    | 0                                  |
| `ppGUID`                              | guid        | NM1*IL NM109                         | NM1*IL NM109                       |
| `persGUIDRelated`, `orgGUID`          | guid        | Not sent                             | Not sent                           |
| `transIsGroup`                        | string(100) | `0`                                  | `0`                                |
| `transClaimAmount`                    | string(100) | `0`                                  | `0`                                |
| `transCheckNumber`                    | string(100) | TRN02                                | REF*1Z (ACH, REV only)             |
| `transRouting`                        | string(100) | BPR07                                | REF*EY                             |
| `emGUID`                              | guid        | Not sent                             | Not sent                           |
| `lbcLockboxCode`                      | string(100) | BPR04                                | BPR04 (`CCC`, `ACH`, `REV`)        |
| `lbcLockboxCodeType`                  | string(25)  | `PATIENT`                            | `WEB`                              |
| `transCardNumber`                     | string(50)  | Not sent                             | REF*TN (CCC only)                  |
| `transCardType`                       | string(50)  | Not sent                             | REF*8X (CCC only)                  |
| `transApprovalCode`                   | string(10)  | Not sent                             | REF*1Z                             |
| `xwebGUID`                            | guid        | Not sent                             | REF*EM                             |
| `transTransactionIDStr`               | string(100) | Not sent                             | REF*2H                             |
| `PaymentIdentifier`                   | string(100) | REF*F8                               | Not sent                           |

Result set 0: `ErrorCount` (int), `ResponseMessage` (string). Also `ReturnValue` (int).

The production `ImportLog` rows of flow A (2026-08 to 2026-10) show this `ResponseMessage` format:

```text
Check No: <transCheckNumber>, Check Date: <MM/dd/yyyy>, Deposit Date: <MM/dd/yyyy>, Check Amount: <amount>, Patient ID : <patient id>, patGUID: <patGUID>, ilExternalReference: <PaymentIdentifier> :: <result>
```

- `<result>` is `Success`, or a list of errors such as `Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL;`.
- "Check Date" and "Deposit Date" show the two date parameters, which BizTalk fills with the processing time.
- "Check No" shows `transCheckNumber` without its leading zeros, because the procedure converts it to `int` (see the procedure behavior below and D17 in document 05).
- "Patient ID" is `Patient.patID` of `@patGUID`. It is empty when the patient is not found.
- The flow passes this text to `AddImportLog` as `ilMessage`. A replacement must do the same.

#### Live procedure behavior (C9-T `TestC9`, modified 2025-04-08, read 2026-10-20)

The live signature has the parameters in the table above, plus `locGUIDPosted`, `locGUIDAssigned`, `empGUIDProvider`, `ttypGUID`, `transDebitGroup`, `transCreditGroup`, `persGUIDRelated`, `orgGUID`, `emGUID` (all default NULL). Amounts are `money`. Only `transDateTime`, `transDateTimePosted`, `transStatus`, `transGUID`, `transAmount`, `transNote`, and `transReference` have no default. The procedure runs in one transaction:

1. `@checkNumber = CONVERT(int, @transCheckNumber)` in a TRY/CATCH. If the conversion fails, `@checkNumber` is NULL. `[Transaction].transCheckNumber` gets `@checkNumber`, not the text. Leading zeros are lost. A value above 2,147,483,647 is stored as NULL.
2. It looks up `Patient.patID` for `@patGUID` and builds the `ResponseMessage` prefix.
3. Validations. Each failure adds 1 to `ErrorCount` and a reason to the message:
   - No `Patient` row for `@patGUID`.
   - No `PersonPerson` row for `@ppGUID`.
   - No `BTS.PaymentType` row with `ptPaymentTypeCode = @lbcLockboxCode`.
   - `WEB` only: `@transTransactionIDStr` is NULL.
   - Duplicate, `WEB`: a `[Transaction]` row with the same `ppGUID` and `transTransactionID`.
   - Duplicate, all other types (`PATIENT`): any `ImportLog` row with `ilExternalReference = @PaymentIdentifier`. A NULL `PaymentIdentifier` never matches.
4. If `ErrorCount > 0`, it raises the message as an error.
5. Else it inserts one `[Transaction]` row. `orgGUID`, `locGUIDPosted`, `locGUIDAssigned`, and `empGUIDProvider` come from the `Patient` row. `ttypGUID` comes from `BTS.PaymentType` (`ptPaymentTypeCode = @lbcLockboxCode AND ptPaymentType = @lbcLockboxCodeType`) joined to `TransactionType` on `ttypCode`. `transClaimAmount` is always 0. The message ends with ` Success`.
6. On any error: rollback, then one `UnmappedTransaction` row with all parameters and `utErrorMessage` = the error text. The returned `ResponseMessage` is the error text.
7. It returns `ErrorCount` and `ResponseMessage`.

Details from the full source (supplied by Wes, 2026-10-21):

- `ErrorCount` is 0 on success. After a failure it is the number of validation errors, plus 1 when the error goes through the CATCH block. So a validation failure returns a count of at least 2.
- The raise is `RAISERROR(@ResponseMessage, 16, 1)`. SQL Server cuts a message over 2,047 characters. The CATCH block returns `ERROR_MESSAGE()`, so a long message is cut. A `%` in the text is read as a format code.
- The validation checks only that the `Patient`, `PersonPerson`, and `BTS.PaymentType` rows exist. It does not check that `ppGUID` belongs to `patGUID`.
- The insert has these inner joins: `Patient` (by `@patGUID`), `Person` (on the patient's `persGUID`), `PersonPerson` (by `@ppGUID`), `BTS.PaymentType` (code and type), and `TransactionType` (on `ttypCode`). The validation covers `Patient`, `PersonPerson`, and the payment type code. A missing `Person`, a payment type with another type, or a missing `TransactionType` writes 0 rows with no error, and the message still ends with `Success` (D19).
- The procedure ignores these parameters: `ttypGUID`, `transClaimAmount`, `emGUID`, `locGUIDPosted`, `locGUIDAssigned`, `empGUIDProvider`, and `orgGUID`. `transDebitGroup` and `persGUIDRelated` only go into `UnmappedTransaction`. `transCreditGroup` goes into `[Transaction]`.
- `transTransactionIDStr` is stored in `[Transaction].transTransactionID`.
- The `UnmappedTransaction` row keeps `ptPaymentTypeCode` and `utCheckNumber` as the original text. It does not keep `PaymentIdentifier`, `lbcLockboxCodeType`, `emGUID`, `xwebGUID`, `transTransactionID`, or the card fields (D20).
- The procedure writes the `UnmappedTransaction` row only if no `[Transaction]` row has the same `transGUID`. The insert is not in a TRY/CATCH.
- The header comment names `udt835Transaction`. The live body does not use it.

The duplicate check for flow A depends on the `ImportLog` row that the flow writes after each post. A replacement must call `AddImportLog` with `ilExternalReference = PaymentIdentifier` after every post, or the duplicate check stops working.

### BTS.AddImportLog (live, C9-T `TestC9`)

`@ilDateTime datetime, @ilFileName nvarchar(250), @ilProcess nvarchar(50), @ilLogLevel int, @ilMessage nvarchar(max), @ilStackTrace nvarchar(max), @ilImportGUID uniqueidentifier, @ilImportState nvarchar(50), @ilExternalReference nvarchar(100) = NULL`. It inserts one `dbo.ImportLog` row with `ilGUID = NEWID()`. Only `ilExternalReference` has a default.

`dbo.ImportLog` columns (DDL supplied by Wes, 2026-10-21): `ilGUID` uniqueidentifier NOT NULL (primary key, clustered, fill factor 80), `ilDateTime` datetime, `ilFileName` nvarchar(250), `ilProcess` nvarchar(50), `ilLogLevel` int, `ilMessage` nvarchar(max), `ilStackTrace` nvarchar(max), `ilImportGUID` uniqueidentifier, `ilImportState` nvarchar(50), `ilExternalReference` **varchar(100)**, `CREATEDBY` nvarchar(15). All columns except `ilGUID` allow NULL. The only other index is `IX_ImportLog_ilImportGUID`. There is no index on `ilExternalReference` (D21). The column is `varchar`, so a non-ASCII character in a REF*F8 value becomes `?` when the procedure stores it.

BizTalk sends only the elements that the map creates. An element that the map does not create is not sent, so the procedure uses its default. Keep this behavior: do not send NULL for a parameter that BizTalk does not send, unless the procedure default is NULL.

Other logic around `ImportLog` (read on C9-T `TestC9`, 2026-10-21):

- `BTS.AddImportLog` is one `INSERT`. It has no checks, no transaction, and no error handling.
- `dbo.ImportLog` has no triggers and no default constraints. `ilDateTime` and `CREATEDBY` stay as the caller sends them (`CREATEDBY` is NULL).
- `ilDateTime` is `DateTime.Now` of the BizTalk server. The two clocks can differ from the SQL server clock. The Utility procedure takes an optional `@ilDateTime`. If the caller does not send it, the procedure uses `GETDATE()` of the SQL server. The POC sends its own processing time (Wes, 2026-10-21).
- Readers: `dbo.GetImportLogs(@ImportID)` returns all rows with `ilImportGUID = @ImportID`, in `ilDateTime` order. `dbo.GetImportLogsByProcess(@ilProcess, @ilDateTimeStart, @ilDateTimeEnd, @LogLevel)` filters by process, time range, and level. Both map the level: 0 Error, 1 Debug, 2 Info, 3 Security. So `ilImportGUID`, `ilProcess`, `ilDateTime`, and `ilLogLevel` must keep the BizTalk meaning.
- `BTS.Post835PatientTransaction` and `BTS.Post835InsuranceTransaction` read `ImportLog` for the duplicate check. `BTS.Post835InsuranceTransaction` skips the check for the `PLB` payment type. The procedure sets `PLB` only when `AdjustmentType` is set and is not `L6`, so flow C L6 adjustments are checked and fail as duplicates of their claim (document 05, D24). No procedure other than `AddImportLog` writes ImportLog for flows A to D.
- Other users that write ImportLog: `BTS.SetPatientInsuranceEligibility` inserts rows directly. `dbo.SetPatientDemographicInfo` returns a text that starts with `Error`, and an SSIS package saves it in ImportLog. Neither is part of flows A to D.
- In the BizTalk flow, the post and the `AddImportLog` call are separate (D22). If the flow throws an exception, no ImportLog row is written, and the payments that are left in the set are not processed.

### Utility database on C9-T (read 2026-10-21)

Server `C9-T-SQL-01`, database `Utility`. Read-only queries with the saved C9-T profile, login `sql.wesley.valure`.

- `dbo` holds 20 procedures and 11 tables. Each practice has its own schema (for example `TestC9`, `C9-MidWest`). The `TestC9` schema holds 132 procedures and 1 table-valued function.
- The `TestC9` procedures are templates. They use three-part names such as `[TestC9].dbo.[Transaction]`. Names follow `usp_<Area>_<Name>`, for example `usp_AutoPost_NSFfees`.
- `dbo.usp_CreateCentralC9_Proc` (`@procName`, `@duplicatePercent = 0`, `@schemaToCopyFrom = 'TestC9'`, `@executeSql = 0`) builds a copy of a template for the practice schemas. The copy accepts an extra `@ssid` parameter and uses dynamic SQL. The procedure refuses to run on a server other than `C9-T-SQL-01` and `C9-T-SQL-02`. Its header says that the SQL Compare tool moves the procedures to the production `Utility` database. The template comments call it `usp_CreateCentral9_Proc`. The real object name has `C9`.
- The name `usp_bts_Post835PatientTransaction` is not in use. No object in `Utility` has `835` in its name.
- The login has `CREATE PROCEDURE` in `Utility`, and `ALTER` and `EXECUTE` on schema `TestC9`.
- From `Utility`, the login reads `[TestC9].dbo.[Transaction]` (859,800 rows), `[TestC9].dbo.ImportLog` (1,627 rows, none with `ilExternalReference` like `EOB9%`), and `[TestC9].dbo.UnmappedTransaction` (0 rows). `[TestC9].BTS.PaymentType` has 3 rows of type `PATIENT`.

Decision (Wes, 2026-10-21): the Utility posting procedure is `[TestC9].usp_bts_Post835PatientTransaction`. This sprint uses only the `TestC9` schema.

### BTS.Post835InsuranceTransaction (flows C and D)

Same schema file. The live procedure (C9-T `TestC9`, read 2026-10-29) has flat parameters, as below, and no table-valued parameter (D1 closed). Live types that differ from the table: `transNote` nvarchar(500), `transReceiptNote` nvarchar(250), `transStatus` nvarchar(2), `AdjustmentType` varchar(2). Defaults are NULL except for `transDateTime`, `transDateTimePosted`, `transStatus`, `transGUID`, `transAmount`, `transNote`, `transReference`, `transCheckNumber`, and `ptPaymentTypeCode`.

| Parameter                                                                                                                                        | Type        | Flow C (claim)            | Flow C (PLB)                                 | Flow D                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ------------------------- | -------------------------------------------- | ---------------------------------------------- |
| `transDateTime`                                                                                                                                  | datetime    | Processing time           | Processing time                              | Processing time                                |
| `transDateTimePosted`                                                                                                                            | datetime    | Processing time           | Processing time                              | Processing time                                |
| `transStatus`                                                                                                                                    | string(2)   | `N`                       | `N`                                          | `N`                                            |
| `transGUID`                                                                                                                                      | guid        | New GUID                  | New GUID                                     | New GUID                                       |
| `patGUID`                                                                                                                                        | guid        | REF*EJ                    | REF*EJ of the single claim                   | Not sent                                       |
| `pipGUID`                                                                                                                                        | guid        | REF*69 (see known issues) | REF*69                                       | Not sent                                       |
| `transAmount`, `transDueNowAmount`, `transTotalDueAmount`                                                                                        | decimal     | -CLP04                    | PLB04 (negated twice)                        | -CLP04                                         |
| `transNote`, `transReceiptNote`                                                                                                                  | string(250) | Canonical note            | Canonical note with `Adj Reason`             | `Check Number: <TRN02>, Claim Number: <claim>` |
| `transReference`                                                                                                                                 | string(100) | TRN02                     | `ADJ<n>-<TRN02>`                             | Not sent                                       |
| `transProductionAmount`                                                                                                                          | decimal     | 0                         | 0                                            | 0                                              |
| `transIsGroup`, `transClaimAmount`                                                                                                               | string(100) | `0`                       | `0`                                          | `0`                                            |
| `transCheckNumber`                                                                                                                               | string(100) | TRN02                     | TRN02                                        | TRN02                                          |
| `transRouting`                                                                                                                                   | string(100) | BPR07                     | BPR07                                        | BPR07                                          |
| `adaClaimNumber`                                                                                                                                 | string(100) | CLP01                     | CLP01 of the single claim                    | `int(CLP01.Substring(12))`                     |
| `pipPolicyNumber`                                                                                                                                | string(100) | NM1*QC NM109              | NM1*QC NM109                                 | NM1*QC NM109                                   |
| `ptPaymentTypeCode`                                                                                                                              | string(3)   | BPR04                     | BPR04                                        | BPR04                                          |
| `ClaimIdentifier`                                                                                                                                | string(100) | TRN04                     | TRN04                                        | Not sent                                       |
| `PaymentIdentifier`                                                                                                                              | string(100) | REF*F8                    | REF*F8 of the single claim (production, D6)  | Not sent                                       |
| `AdjustmentType`                                                                                                                                 | string(2)   | Not sent                  | PLB03-1                                      | Not sent                                       |
| `locGUIDPosted`, `locGUIDAssigned`, `empGUIDProvider`, `ttypGUID`, `transDebitGroup`, `transCreditGroup`, `ppGUID`, `persGUIDRelated`, `orgGUID` | guid        | Not sent                  | Not sent                                     | Not sent                                       |

Result set 0: `ErrorCount` (int), `ResponseMessage` (string). Also `ReturnValue` (int).

#### Live procedure behavior (C9-T `TestC9`, read 2026-10-29)

1. `@checkNumber = CONVERT(int, @transCheckNumber)` in a TRY. A TRN02 that is not an int (15 digits, letters) gives NULL `transCheckNumber` and an empty `Check No:` in the message. No error.
2. If `@pipGUID` is NULL: look up the claim by `adaclaimNumber = @adaClaimNumber` and an active policy with `pipPolicyNumber = @pipPolicyNumber`. Production has no Finished claim without REF*EJ since 2026-05, so this path does not succeed in practice.
3. Build the message header: `Check No, Claim No, Check Date (= transDateTime), Deposit Date (= transDateTimePosted), Check Amount (= -transAmount), Insurance Co, Policy No, Patient ID, PaymentType, pipGUID, patGUID, ilExternalReference :: `.
4. Validation adds an error for each: `pipGUID` given and not found; `pipGUID` NULL and claim not found; `pipGUID` NULL and claim plus policy not found; `ptPaymentTypeCode` not in `BTS.PaymentType`.
5. `ADAClaim.adaclaimNumber` is an **int**. The claim lookup compares it with the nvarchar `@adaClaimNumber`, so a CLP01 that is not an int raises a conversion error (D23). The lookup runs for every claim.
6. If `AdjustmentType` is set and is not `L6`, the payment type becomes `PLB`. Duplicate check: an error if any `ImportLog` row (any state, any process) has `ilExternalReference = @PaymentIdentifier`, unless the type is `PLB`. A NULL `PaymentIdentifier` never matches (D24, D25).
7. Any error: RAISERROR with the full message.
8. Not L6: insert one `[Transaction]` row. The transaction type comes from `BTS.PaymentType` (`ptPaymentType = 'INSURANCE'`, code = `ptPaymentTypeCode`); patient, provider, and location come from the policy and `Patient`. `transDebitGroup` is set if the amount is positive, `transCreditGroup` if negative (both NULL as BizTalk sends them).
9. L6: insert two rows with new GUIDs, `L6C` (charge, amounts negated, new debit group) and `L6P` (payment, new credit group).
10. 0 rows inserted: error `[Transaction] Record Not Created for adaclaimGUID ...`.
11. Add ` Payment amount exceeds remaining balance.` if `-transAmount` is more than `TotalDue` of `dbo.udfGetAgingAsOfDate`. Add ` Success`. Commit.
12. CATCH: roll back, `ErrorCount + 1`, `ResponseMessage = ERROR_MESSAGE()` (only the SQL text for a conversion error or a deadlock), and insert an `UnmappedTransaction` row if `transGUID` is not in `[Transaction]`.

C9-P check (2026-10-29, read-only): all 14,344 flow C ImportLog rows since 2026-09-01 have this header shape, Check Date = Deposit Date, every Finished row ends in `Success`, and 1,191 of 1,198 NON rows have an empty `Check No` (TRN02 not an int). So C9-P most likely runs the same body **(inferred)**. The read-only login cannot read the body.

TestC9 `BTS.PaymentType` rows for `INSURANCE`: `ACH` (LBOXINSEFT), `BOP` (LBOXINSCC), `CHK` (LBOXINSC), `NON` (LBOXINSC), `PLB` (LBOXINSC), `L6C` (INTERESTOTSD), `L6P` (INSIPC).

### BTS.AddImportLog (all posting flows)

Schema: [ImportLogTypedProcedure.BTS.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.Schemas/ImportLog/ImportLogTypedProcedure.BTS.xsd).

| Parameter             | Type                                                              |
| --------------------- | ----------------------------------------------------------------- |
| `ilDateTime`          | datetime                                                          |
| `ilFileName`          | string(250)                                                       |
| `ilProcess`           | string(50)                                                        |
| `ilLogLevel`          | int                                                               |
| `ilMessage`           | string (max)                                                      |
| `ilStackTrace`        | string (max)                                                      |
| `ilImportGUID`        | guid                                                              |
| `ilImportState`       | string(50)                                                        |
| `ilExternalReference` | string (required in the schema, but flows B and D do not send it) |

Response: `ReturnValue` only.

### BTS.AddTodoItem (flow D reversals)

Schema: [AddTodoItemTypedProcedure.BTS.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.Schemas/AddTodoItem/AddTodoItemTypedProcedure.BTS.xsd).

| Parameter        | Type        | Flow D value                                               |
| ---------------- | ----------- | ---------------------------------------------------------- |
| `adaclaimNumber` | int         | Parsed claim number                                        |
| `errorCode`      | string(10)  | Not sent                                                   |
| `message`        | string(300) | `Payment for claim<n> needs reversal for amount $<CLP04>.` |
| `reason`         | string(50)  | Not sent                                                   |

Result set 0: `tdGUID` (guid), `ErrorMessage` (string). A non-blank `ErrorMessage` is an error.

### BTS.GetPracticeEDISettings (flow D mailbox)

No parameters. The worker reads `pracEmdeonIsTest`, `pracEmdeonURL`, `pracEmdeonTestURL` and passes the response to the map `CHC_PracticeEDISettings_To_GetMailFileListReq`. The map summary lists the credential fields that go into the mailbox request: [CHC_PracticeEDISettings_To_GetMailFileListReq.txt](../map-summaries/CHC_PracticeEDISettings_To_GetMailFileListReq.txt).

## Practice tables named by the test scripts

| Table                               | Columns named in scripts                                                                                                                                                                                                                                                                                                         | Meaning                                                                                          |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `[Transaction]`                     | `transGUID`, `transDateTime`, `transDateTimePosted`, `transStatus`, `locGUIDAssigned`, `patGUID`, `ttypGUID`, `transAmount`, `transNote`, `transReceiptNote`, `transReference`, `transDueNowAmount`, `transTotalDueAmount`, `transProductionAmount`, `ppGUID`, `pipGUID`, `transClaimAmount`, `transCheckNumber`, `transRouting` | Posted ledger rows                                                                               |
| `TransactionType`                   | `ttypGUID`, `ttypCode`, `ttypDescription`, `ttypDeleted`                                                                                                                                                                                                                                                                         | Codes used: `LBOXPERCMO`, `WEBCC`, `WEBACH`, `WEBACHRET`, `INTERESTOTSD`, `INSIPC`, `LBOXINSC`   |
| `BTS.PaymentType`                   | `ttypCode`, `ptPaymentType`, `ptPaymentTypeCode`, `ptIsDeleted`                                                                                                                                                                                                                                                                  | Maps BizTalk payment codes to transaction types. Expected codes: `WEB` type, `L6C`, `L6P`, `PLB` |
| `ImportLog`                         | `ilDateTime`, `ilProcess`, `ilLogLevel`, `ilMessage`, `ilFileName`, `ilImportGUID`, `ilImportState`, `ilStackTrace`, `ilExternalReference`                                                                                                                                                                                       | Import results                                                                                   |
| `UnmappedTransaction`               | `patGUID`, `utDateTime`, `utStatus`, `utAmount`, `utReceiptNote`, `utReference`, `utCheckNumber`, `utRouting`, `adaClaimNumber`, `pipPolicyNumber`, `ptPaymentTypeCode`, `utErrorMessage`                                                                                                                                        | Insurance payments that the procedure cannot match **(inferred)**                                |
| `ADAClaim`                          | `adaclaimNumber`, `patGUID`, `pipGUID`                                                                                                                                                                                                                                                                                           | Dental claims                                                                                    |
| `PatientInsurancePolicy`            | `pipGUID`, `patGUID`, `pipPolicyNumber`                                                                                                                                                                                                                                                                                          | Policies                                                                                         |
| `Patient`, `Person`, `PersonPerson` | `patGUID`, `persGUID`, `persFullName`, `ppGUID`, `persGUIDRelated`, `ppFinanciallyResponsible`                                                                                                                                                                                                                                   | Patient and responsible party                                                                    |

## Canonical schemas (BizTalk internal)

A replacement does not need these schemas. They help you read the maps.

- `ClaimPaymentBatch` ([ClaimPaymentBatch.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.Schemas/Canonical/ClaimPaymentBatch.xsd)): a list of `ClaimPayment`.
- `ClaimPayment` ([ClaimPayment.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.Schemas/Canonical/ClaimPayment.xsd)), namespace `http://Cloud9.BizTalk.Schemas.Canonical.ClaimPayment`. Fields: `TotalActualProviderPaymentAmount`, `PaymentMethodCode`, `SenderDFIIdentifier`, `CheckIssueorEFTEffectiveDate`, `CheckorEFTTraceNumber`, `PatientControlNumber`, `PatientIdentifier`, `SubscriberIdentifier`, `PayerClaimControlNumber`, `PaymentDepositDate`, `PaymentPostedDate`, `ProviderIdentifier`, `ProviderFirstName`, `ProviderLastName`, `LockboxNumber`, `CheckDate`, `TransactionNote`, `PracticeTIN`, `PracticeProviderNumber`, `PracticeLicenseNumber`, `PatientAccountID`, `ReversalFlag` (default false), `patGUID`, `pipGUID`, `ttypGUID`, `orgGUID`, `ClaimIdentifier`, `PaymentIdentifier`, `ReferenceIdentifier`, `ApprovalCode`, `OpenEdgeTransactionID`, `OpenEdgeXWebGUID`, `MaskedCreditCardNumber`, `CreditCardType`, `MaskedBankAccountNumber`, `OpenEdgeCheckNumber`, `MaskedRoutingNumber`, `AdjustmentType`.

## X12 835 inbound schemas

| Schema                                                                                           | Namespace                   | Notes                                                                                                             |
| ------------------------------------------------------------------------------------------------ | --------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| [BBVA_X12_00501_835.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.X12.Schemas/BBVA_X12_00501_835.xsd) | `.../X12/2006/BBVA`         | Standard 005010X221 names plus header `REF*LB` (lockbox), 2100 `REF*EJ` (patient GUID) and `REF*69` (policy GUID) |
| [SD_X12_00501_835.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.X12.Schemas/SD_X12_00501_835.xsd)     | `.../X12/2006/SmileDoctors` | Generic element names (`BPR04`, `REF_3`). Qualifiers are tested in the map                                        |
| [CHC_X12_00501_835.xsd](../../Cloud9.BizTalk/Cloud9.BizTalk.X12.Schemas/CHC_X12_00501_835.xsd)   | `.../X12/2006/CHC`          | Standard 005010X221 names                                                                                         |

## Read the live procedure signatures

Run this query in one practice database (read-only). For production, use only the approved read-only endpoint.

```sql
SELECT  OBJECT_SCHEMA_NAME(p.object_id) AS SchemaName,
        OBJECT_NAME(p.object_id)        AS ProcName,
        p.parameter_id,
        p.name                          AS ParameterName,
        TYPE_NAME(p.user_type_id)       AS TypeName,
        p.max_length,
        p.is_output,
        p.has_default_value
FROM    sys.parameters AS p
WHERE   OBJECT_SCHEMA_NAME(p.object_id) = 'BTS'
  AND   OBJECT_NAME(p.object_id) IN ('Post835PatientTransaction', 'Post835InsuranceTransaction', 'AddImportLog', 'AddTodoItem', 'GetPracticeEDISettings')
ORDER BY ProcName, p.parameter_id;

-- Table-valued parameter type used by the insurance map (if it exists)
SELECT  tt.name AS TypeName, c.column_id, c.name AS ColumnName, TYPE_NAME(c.user_type_id) AS ColumnType, c.max_length
FROM    sys.table_types AS tt
JOIN    sys.columns AS c ON c.object_id = tt.type_table_object_id
WHERE   tt.name LIKE '%835%'
ORDER BY tt.name, c.column_id;

-- Procedure bodies
SELECT OBJECT_NAME(object_id) AS ProcName, definition
FROM   sys.sql_modules
WHERE  OBJECT_NAME(object_id) IN ('Post835PatientTransaction', 'Post835InsuranceTransaction', 'AddImportLog', 'AddTodoItem');
```
