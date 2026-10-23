# Cloud9 BizTalk: system overview

This repository holds the BizTalk Server 2016 integration layer of the Cloud9 orthodontic practice management system. It also holds a central BizTalk support database, test SQL scripts, and a small HL7 Web API. This document gives the general picture. The payment flows have their own document: [02-payments-835-end-to-end.md](02-payments-835-end-to-end.md).

## Repository layout

| Folder                                                   | Contents                                                                                                                                                  |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Cloud9.BizTalk](../../Cloud9.BizTalk)                   | BizTalk projects (`.btproj`), C# helper projects (`.csproj`), deployment projects (BizTalk Deployment Framework, `.btdfproj`), party configuration, tools |
| [Cloud9.BizTalk.Database](../../Cloud9.BizTalk.Database) | SQL project for the central database `BizTalkCloud9Common` (schema `BTS`)                                                                                 |
| [Cloud9.BizTalk.Scripts](../../Cloud9.BizTalk.Scripts)   | Ad hoc SQL that testers use to build test files and to check results, one folder for each integration                                                     |
| [Cloud9.HL7.WebAPI](../../Cloud9.HL7.WebAPI)             | ASP.NET Web API that accepts HL7 messages and locations from partners and writes them to `BizTalkCloud9Common`                                            |
| [KnowledgeBase](..)                                      | This knowledge base, the code graph, and the tools that build it                                                                                          |

The repository is a source export. It is not a git repository.

## BizTalk applications

| BizTalk application | Solution                                                      | Deployment project                                                          | Main content                                                                                        |
| ------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `Cloud9.Common`     | [Cloud9.Common.sln](../../Cloud9.BizTalk/Cloud9.Common.sln)   | [Cloud9.Common.Deployment](../../Cloud9.BizTalk/Cloud9.Common.Deployment)   | Shared pipeline component (Archive) and shared ports                                                |
| `Cloud9.BizTalk`    | [Cloud9.BizTalk.sln](../../Cloud9.BizTalk/Cloud9.BizTalk.sln) | [Cloud9.BizTalk.Deployment](../../Cloud9.BizTalk/Cloud9.BizTalk.Deployment) | Epic HL7 integration, treatment cards, shared schemas, `Common.AddLog`                              |
| `Cloud9.EDI`        | [Cloud9.EDI.sln](../../Cloud9.BizTalk/Cloud9.EDI.sln)         | [Cloud9.EDI.Deployment](../../Cloud9.BizTalk/Cloud9.EDI.Deployment)         | X12 EDI: 835 payments, 837 claims, 276/277 claim status, 271 eligibility, Change Healthcare mailbox |

Each solution has a `.PDS` variant (`Cloud9.BizTalk.PDS.sln`, `Cloud9.Common.PDS.sln`, `Cloud9.EDI.PDS.sln`) with its own deployment folder. The PDS variant is for a second customer deployment. The helper library calls a PDS API through Okta at `pacificdental.okta.com`, so PDS is Pacific Dental Services **(inferred)**. The Smile Doctors deployment uses the non-PDS bindings.

Hosts named in the bindings: `BizTalkProcessingHost` (orchestrations), `BizTalkReceiveHost`, `BizTalkReceiveHostSFTP`, `BizTalkSendHost`, `BizTalkSendHostSFTP`.

## Projects

| Project                                                                      | Type                  | Purpose                                                                                  |
| ---------------------------------------------------------------------------- | --------------------- | ---------------------------------------------------------------------------------------- |
| `Cloud9.BizTalk.X12` (and `.PDS`)                                            | BizTalk               | X12 orchestrations, maps, pipelines                                                      |
| `Cloud9.BizTalk.X12.Schemas`                                                 | BizTalk               | X12 schemas: BBVA 835, SD 835, CHC 835/837D/276/277/277CA/271, Channel Health 271        |
| `Cloud9.BizTalk.Schemas`                                                     | BizTalk               | Canonical schemas and WCF-SQL schemas for every stored procedure call                    |
| `Cloud9.BizTalk.Maps` (folder `Cloud9.BizTalk.Transforms`)                   | BizTalk               | Shared map `QueueProcessParametersTypedPolling_To_UpdateProcessParameters`               |
| `Cloud9.BizTalk.Common`                                                      | BizTalk               | Orchestration `Cloud9.BizTalk.Common.AddLog` (writes `BTS.Log`)                          |
| `Cloud9.BizTalk.Epic`                                                        | BizTalk               | Epic HL7 v2.6 orchestrations and maps                                                    |
| `Cloud9.BizTalk.Epic.BTAHL7*`                                                | BizTalk               | HL7 v2.6 schemas for the BizTalk Accelerator for HL7                                     |
| `Cloud9.BizTalk.Helper`                                                      | C#                    | Helper methods for orchestrations and maps (dates, codes, Emdeon payload, Okta, PDS API) |
| `Cloud9.BizTalk.Shared.Components.Archive`                                   | C# pipeline component | Writes a raw copy of each received file                                                  |
| `Cloud9.BizTalk.PipelineComponent.CustomEncoder`                             | C# pipeline component | Re-encodes the body as ASCII (Emdeon HTTP send)                                          |
| `Cloud9.BizTalk.PipelineComponent.EmdeonPayload`                             | C# pipeline component | Puts an EDI payload into the Emdeon XML envelope (base64 and size)                       |
| `Cloud9.BizTalk.PipelineComponent.ReplacePayloadStrings`                     | C# pipeline component | Replaces strings from an SSO setting (HL7 receive pipeline only)                         |
| `Cloud9.BizTalk.ReportGenerator`, `Cloud9.BizTalk.Reports`, `...ConsoleTest` | C#                    | Telerik treatment card PDF                                                               |
| `Cloud9.BizTalk.SignalR.Helper`                                              | C#                    | SignalR payload builder (appointment changed)                                            |
| `Cloud9.BizTalk.HelperTest`                                                  | C# test               | Tests for the helper library                                                             |
| `Cloud9.BizTalk.Central.Database`                                            | SQL project           | `BizTalkCloud9Common` database                                                           |
| `Cloud9.HL7.WebAPI`, `.BLL`, `.DAL`, `.WebAPIClient`                         | C#                    | HL7 Web API and test client                                                              |

For the full project graph, read `project:*` and `solution:*` nodes in [../graph/index.md](../graph/index.md).

## Databases

| Database              | Owner              | Use                                                                                                                                                                                                                                                                        |
| --------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BizTalkCloud9Common` | This repository    | Practice routing (`BTS.PracticeConfig`), lookup values, logs (`BTS.Log`), process scheduling (`BTS.ProcessParameter`), HL7 staging (`BTS.IncomingMessage`, `BTS.HL7InboundStaging`), claim tracking (`BTS.SubmittedClaim`), outgoing message queue (`BTS.OutgoingMessage`) |
| Practice databases    | Cloud9 application | One database for each practice group. BizTalk calls procedures in the `BTS` schema of each database. The address comes from `BTS.PracticeConfig.pcInstanceAddress`                                                                                                         |
| BizTalk databases     | BizTalk Server     | MessageBox, tracking, SSO. Not in this repository                                                                                                                                                                                                                          |

## Integration catalog

The orchestrations below are in the graph as `orchestration:*` nodes. Each node lists its activation, ports, messages, maps, called orchestrations, and stored procedures.

### EDI (application Cloud9.EDI)

| Integration                            | Orchestrations                                                                                              | Trigger                                                             | Summary                                                                                                                   |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Patient lockbox payments (BBVA)        | `Process_BBVA_835Patient`                                                                                   | File in a region folder                                             | See document 02, flow A                                                                                                   |
| Web patient payments (Smile Doctors)   | `Process_SD_835Patient`                                                                                     | File in an `SD-<REGION>` folder                                     | See document 02, flow B                                                                                                   |
| Insurance lockbox payments (BBVA)      | `Process_BBVA_835Insurance`                                                                                 | File in a region folder                                             | See document 02, flow C                                                                                                   |
| Insurance ERA (Change Healthcare)      | `Process_CHC_InboundFiles_Controller`, `Process_CHC_InboundFiles_Worker`, `Process_CHC_835Insurance`        | SQL polling of `BTS.ProcessParameter` (`ProcessCHCInboundFiles`)    | See document 02, flow D                                                                                                   |
| CHC 835 and 837 pass-through to BBVA   | `Process_CHC_835_To_BBVA`, `Process_CHC_837_To_BBVA`                                                        | File in a folder                                                    | Re-envelope and send by SFTP                                                                                              |
| Dental claims 837D (Change Healthcare) | `Process_CHC_837Claims_Controller`, `Process_CHC_837Claims_Worker`                                          | SQL polling (`ProcessClaims`)                                       | Read queued claims from each practice, map to 837D, send by HTTP to Change Healthcare, update claim status, archive       |
| Claim status inquiry 276/277           | `Process_CHC_276ClaimStatus`, `Process_CHC_ClaimsStatus`                                                    | `BTS.OutgoingMessage` rows with `omMessageType = 276` (XML polling) | Build a 276 from `GetADAClaim`, send, map the 277 response, update statuses                                               |
| Claim status 277 and 277CA             | `Process_CHC_277ClaimsStatus`, `Process_CHC_277AClaimsStatus`, `Process_CHC_277_Unsolicitated_ClaimsStatus` | Files in `CHC_Inbound` (from the mailbox) and `CHC_Inbound\277`     | Map to `ClaimStatus` canonical, then `Process_CHC_ClaimsStatus` updates claim statuses, adds claim errors and to-do items |
| Eligibility 271                        | `Process_CHC_271Eligibility`, `Process_ChannelHealth_271Eligibility`                                        | Files from Change Healthcare and Channel Health                     | Map to `InsuranceInformation` and `PatientEligibilities` canonical, update `PatientInsurancePolicy`                       |
| Shared types                           | `EDITypes`                                                                                                  | None                                                                | Message types and port types for the X12 orchestrations                                                                   |

Active status: the discovery session of 2026-10-14 calls the 271 eligibility flows and the patient insurance policy updates inactive. It names the BBVA / Fifth Third patient and insurance lockbox flows and the web patient payments as active. It does not give a status for the other EDI flows. See [03-replacement-guide.md](03-replacement-guide.md#0-project-context-discovery-session-2026-10-14).

### Epic HL7 (application Cloud9.BizTalk)

| Integration        | Orchestrations                                                                                      | Summary                                                                                                                        |
| ------------------ | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| HL7 intake         | `HL7SQLReceive`, `HL7FlatFileReceive`, `ProcessingHl7_Inbound`, `StageHL7_Inbound`                  | Poll `BTS.IncomingMessage` (written by the HL7 Web API) or read flat files, stage each message in `BTS.HL7InboundStaging`      |
| HL7 processing     | `ProcessHL7MessagesForPatient`                                                                      | Poll staged patients, then upsert patients (ADT A28/A31), employees (MFN M02), and appointments (SIU) in the practice database |
| Treatment cards    | `ProcessTreatmentCardData_Controller`, `ProcessTreatmentCardData_Worker`, `SendTreatmentCardsToPDS` | Render treatment card PDFs (Telerik), wrap them in MDM T02, send to the PDS API                                                |
| Logging and errors | `Cloud9.BizTalk.Epic.AddLog`, `ErrorReporting`, `Cloud9.BizTalk.Common.AddLog`                      | Write `BTS.Log` and `BTS.ProcessingError` rows                                                                                 |

### HL7 Web API

`Cloud9.HL7.WebAPI` has two controllers: `IncomingMessagesController` (partners post HL7 messages) and `LocationController`. Partners authenticate with a user name and password that the BLL checks against a partner database. Messages go to `BTS.IncomingMessage`. BizTalk polls that table (`HL7SQLReceive`).

## Shared mechanisms

1. **Practice routing.** Every flow that writes to a practice database finds the address in `BTS.PracticeConfig`. Dynamic WCF-SQL send ports carry the address at run time.
2. **Typed procedure calls.** Each call uses a WCF-SQL schema from `Cloud9.BizTalk.Schemas`. The action is `TypedProcedure/BTS/<ProcName>`. Orchestrations set `useAmbientTransaction=false` and `EnableTransaction=false`. The procedures own the transactions.
3. **Process scheduling.** Rows in `BTS.ProcessParameter` trigger the polling receive locations (`ProcessClaims`, `ProcessCHCInboundFiles`, `ProcessTreatmentCards`). `BTS.QueueProcessParameters` returns the practice list. The controller orchestration calls a worker for each practice.
4. **Logging.** Central `BTS.Log` (through `Common.AddLog`), practice `ImportLog` (through `BTS.AddImportLog`), and the Windows event log.
5. **Configuration.** The BizTalk Deployment Framework replaces `${...}` placeholders in `PortBindingsMaster.xml` with values from `SettingsFileGenerator.xml` for each environment. Environments in the EDI settings: Default, Local Dev, JGLISSON Development, LAB, LAB2, LAB3, C9Prod1, C9Prod2, SDLab1, SDProd1. Some runtime settings (PDS API) come from SSO through `SSOClientHelper`.

## How to read BizTalk artifacts without BizTalk

| Artifact                             | Format                                                                              | How to read it                                                                                                                              |
| ------------------------------------ | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Orchestration `.odx`                 | XML designer data, then the XLANG/s code after the line `#endif // __DESIGNER_DATA` | Read the code section. It has every shape as code. The graph node gives the line of the `service` declaration                               |
| Map `.btm`                           | UTF-16 XML with very long lines                                                     | Read the dump in [../map-summaries](../map-summaries). Run [Export-MapSummaries.ps1](../tools/Export-MapSummaries.ps1) again after a change |
| Pipeline `.btp`                      | UTF-16 XML                                                                          | The graph `pipeline:*` node lists the components. Binding files override component properties for each location                             |
| Schema `.xsd`                        | XML, some UTF-16                                                                    | X12 schemas use `trigger_field` / `trigger_value` to bind a qualifier (for example `REF01 = EJ`) to a named record                          |
| Binding `PortBindingsMaster.xml`     | XML with `${...}` placeholders                                                      | Graph nodes `receiveport:*`, `receivelocation:*`, `sendport:*`, `setting:*`                                                                 |
| Settings `SettingsFileGenerator.xml` | Excel 2003 XML                                                                      | Graph nodes `setting:*` with values for each environment (secrets redacted)                                                                 |

Some editors and tools cannot read UTF-16. [Export-Utf8Copies.ps1](../tools/Export-Utf8Copies.ps1) writes UTF-8 copies of all source files to `%TEMP%\c9decoded`.
