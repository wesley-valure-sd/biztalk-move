# Cloud9 BizTalk knowledge base

This folder documents the BizTalk integration layer in this repository. The focus is the patient and insurance payment flows (lockbox and 835), and what a replacement application must do.

## Start here

| Document                                                                                 | Use it to                                                                                      |
| ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [docs/01-system-overview.md](docs/01-system-overview.md)                                 | Learn the repository layout, the BizTalk applications, the databases, and every integration    |
| [docs/02-payments-835-end-to-end.md](docs/02-payments-835-end-to-end.md)                 | Follow each payment flow from the partner file to the practice database, field by field        |
| [docs/03-replacement-guide.md](docs/03-replacement-guide.md)                             | Plan the replacement: responsibilities, facts to confirm, design, pseudo-code, cut-over, tests |
| [docs/04-data-contracts.md](docs/04-data-contracts.md)                                   | Look up every stored procedure parameter, table, and schema that the payment flows use         |
| [docs/05-known-issues-and-open-questions.md](docs/05-known-issues-and-open-questions.md) | See defects, security items, and unknowns found in the source                                  |
| [graph/README.md](graph/README.md)                                                       | Traverse the code graph (nodes, edges, one adjacency file for each node)                       |
| [map-summaries](map-summaries)                                                           | Read any BizTalk map as plain text: links, functoids, inline C# and XSLT                       |

## Payment flows at a glance

| Flow                   | Partner                                        | Orchestration                                            | Posts with                                                         |
| ---------------------- | ---------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------ |
| A. Patient lockbox     | BBVA / Navigant (now Fifth Third / Guidehouse) | `Process_BBVA_835Patient`                                | `BTS.Post835PatientTransaction` (`PATIENT`)                        |
| B. Web patient payment | Smile Doctors web (card, ACH, ACH return)      | `Process_SD_835Patient`                                  | `BTS.Post835PatientTransaction` (`WEB`)                            |
| C. Insurance lockbox   | BBVA / Navigant (now Fifth Third / Guidehouse) | `Process_BBVA_835Insurance`                              | `BTS.Post835InsuranceTransaction` (claims and PLB adjustments)     |
| D. Insurance ERA       | Change Healthcare (Emdeon)                     | `Process_CHC_InboundFiles_*`, `Process_CHC_835Insurance` | `BTS.Post835InsuranceTransaction` or `BTS.AddTodoItem` (reversals) |
| E. 835 pass-through    | Change Healthcare to BBVA                      | `Process_CHC_835_To_BBVA`                                | No posting. SFTP forward                                           |

All posting flows find the practice database in `BizTalkCloud9Common.BTS.PracticeConfig` and write one `ImportLog` row for each payment.

The discovery session of 2026-10-14 puts flows A and C first in the replacement scope. See [docs/03-replacement-guide.md](docs/03-replacement-guide.md) section 0.

## Other sources

The `references` folder at the repository root holds documents that are not source code. The docs use them as follows.

| Document                                                   | Used in                                               |
| ---------------------------------------------------------- | ----------------------------------------------------- |
| `BizTalk to Cloud9 Discovery 20261014-171226UTC.docx`      | Documents 01, 02, 03, 05                              |
| `BizTalk-v1.3_ReleaseNotes_c9*.docx` (release 1.3.2108.86) | Documents 02, 03, 05                                  |
| `*/835_*_Mapping_v1.xlsx` (vendor mapping specs)           | Documents 02, 05                                      |
| `SFTP Monitoring Tool.docx`                                | Documents 03, 05                                      |
| SQL scripts and `Cloud9.BizTalk.Scripts.zip`               | Older copies of `Cloud9.BizTalk.Scripts`. Document 02 |
| `*.pdf` (process guides and the 2021 incident letter)      | Documents 02, 05                                      |
| `How To Test *.zip`                                        | Not reviewed (276/277 and 837D, not payments)         |

The code is the source of truth for current behavior. Where a reference does not agree with the code, document 02 lists the difference.

## Tools

The scripts need PowerShell 7 (`pwsh`). They read the source and do not change it.

| Script                                                           | Output                                                                                                                                                                                                                                        |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [tools/Build-CodeGraph.ps1](tools/Build-CodeGraph.ps1)           | Rebuilds `graph/` (merges `graph/curated/*.json`)                                                                                                                                                                                             |
| [tools/Export-MapSummaries.ps1](tools/Export-MapSummaries.ps1)   | Rebuilds `map-summaries/` from every `.btm` file                                                                                                                                                                                              |
| [tools/Find-GraphNode.ps1](tools/Find-GraphNode.ps1)             | Searches the graph and prints neighbors                                                                                                                                                                                                       |
| [tools/Export-Utf8Copies.ps1](tools/Export-Utf8Copies.ps1)       | Writes UTF-8 copies of the UTF-16 BizTalk files to `%TEMP%\c9decoded` for text tools                                                                                                                                                          |
| [tools/Export-ReferenceText.ps1](tools/Export-ReferenceText.ps1) | Writes plain text of the `references` docx, xlsx, pdf, and zip files to `%TEMP%\c9refs`. Compares the reference SQL files with the repository. Uses `pdftotext` if it exists, else [tools/Convert-PdfToText.ps1](tools/Convert-PdfToText.ps1) |
| [tools/Export-DocsHtml.ps1](tools/Export-DocsHtml.ps1)           | Writes this README and `docs/*.md` to one HTML file in `export/`                                                                                                                                                                              |

The workspace file `.vscode/tasks.json` has VS Code tasks that run these scripts (`kb-*`).

## Conventions in these documents

1. A statement marked **(inferred)** comes from reasoning about the code, not from an explicit line of code. Confirm it before you depend on it.
2. Links point to files in this repository. Line numbers refer to the source at the time of writing.
3. Secrets in the source are never copied here. The graph shows `[REDACTED]` for password, key, and token settings.
4. The practice database procedures are not in this repository. Documents 03 and 04 tell you how to read them.

## Keep the knowledge base current

1. After a change to an orchestration, map, schema, binding, or SQL file, run `Build-CodeGraph.ps1` and `Export-MapSummaries.ps1`.
2. If you learn a new fact about a payment flow, update the document that owns the topic (02 for behavior, 04 for contracts, 05 for issues) and, if it is a step or rule, `graph/curated/payment-flows.json`.
3. Check `graph/build-warnings.txt` after each build. A curated id that does not exist creates a warning and a placeholder node.
