# POC (C9-T) compared with BizTalk (C9-P): flow A, BBVA patient 835

**Result: 7 of 7 scenarios give the same data on C9-T and on C9-P.** Each scenario is compared on 24 columns. The `txn_status` column is not compared. BizTalk posts `N` (new). The end-of-day run changes it to `D`.

## Result for each scenario

| Scenario | Outcome  | Amount | Import log (state, level) | Transaction rows | Transaction type | Unmapped rows    | Same on C9-T and C9-P  |
| -------- | -------- | ------ | ------------------------- | ---------------- | ---------------- | ---------------- | ---------------------- |
| 2Q       | Finished | 169    | Finished, 2               | 1                | LBOXPERCMO       | 0                | Yes (24 of 24 columns) |
| 8G       | Failed   | 297    | Failed, 0                 | 0                | none             | 1 (PCC, -297.00) | Yes (24 of 24 columns) |
| HE       | Finished | 250    | Finished, 2               | 1                | LBOXPERCMO       | 0                | Yes (24 of 24 columns) |
| N2       | Finished | 74.53  | Finished, 2               | 1                | LBOXCC           | 0                | Yes (24 of 24 columns) |
| PO       | Finished | 169    | Finished, 2               | 1                | LBOXPERCMO       | 0                | Yes (24 of 24 columns) |
| TO       | Finished | 100    | Finished, 2               | 1                | LBOXPERCMO       | 0                | Yes (24 of 24 columns) |
| U9       | Failed   | 784    | Failed, 0                 | 0                | none             | 1 (PCC, -784.00) | Yes (24 of 24 columns) |

## All compared columns

The same value is on C9-T and on C9-P in every cell. Full rows are in `C9_T_results.csv` and `C9_P_results.csv`.

| Column                | 2Q                                           | 8G                                                                                        | HE                                           | N2                                           | PO                                           | TO                                           | U9                                                                                        |
| --------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------- | -------------------------------------------- | -------------------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `expected_state`      | Finished                                     | Failed                                                                                    | Finished                                     | Finished                                     | Finished                                     | Finished                                     | Failed                                                                                    |
| `file_amount`         | 169.0000                                     | 297.0000                                                                                  | 250.0000                                     | 74.5300                                      | 169.0000                                     | 100.0000                                     | 784.0000                                                                                  |
| `import_rows`         | 1                                            | 1                                                                                         | 1                                            | 1                                            | 1                                            | 1                                            | 1                                                                                         |
| `il_state`            | Finished                                     | Failed                                                                                    | Finished                                     | Finished                                     | Finished                                     | Finished                                     | Failed                                                                                    |
| `il_level`            | 2                                            | 0                                                                                         | 2                                            | 2                                            | 2                                            | 2                                            | 0                                                                                         |
| `il_process`          | Process_BBVA_835Patient                      | Process_BBVA_835Patient                                                                   | Process_BBVA_835Patient                      | Process_BBVA_835Patient                      | Process_BBVA_835Patient                      | Process_BBVA_835Patient                      | Process_BBVA_835Patient                                                                   |
| `il_file_name_only`   | 1                                            | 1                                                                                         | 1                                            | 1                                            | 1                                            | 1                                            | 1                                                                                         |
| `il_msg_tail`         | Success                                      | Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL; | Success                                      | Success                                      | Success                                      | Success                                      | Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL; |
| `txn_rows`            | 1                                            | 0                                                                                         | 1                                            | 1                                            | 1                                            | 1                                            | 0                                                                                         |
| `txn_amount`          | -169.00                                      | NULL                                                                                      | -250.00                                      | -74.53                                       | -169.00                                      | -100.00                                      | NULL                                                                                      |
| `due_now`             | -169.00                                      | NULL                                                                                      | -250.00                                      | -74.53                                       | -169.00                                      | -100.00                                      | NULL                                                                                      |
| `total_due`           | -169.00                                      | NULL                                                                                      | -250.00                                      | -74.53                                       | -169.00                                      | -100.00                                      | NULL                                                                                      |
| `production`          | 0.00                                         | NULL                                                                                      | 0.00                                         | 0.00                                         | 0.00                                         | 0.00                                         | NULL                                                                                      |
| `is_group`            | 0                                            | NULL                                                                                      | 0                                            | 0                                            | 0                                            | 0                                            | NULL                                                                                      |
| `ttyp_code`           | LBOXPERCMO                                   | NULL                                                                                      | LBOXPERCMO                                   | LBOXCC                                       | LBOXPERCMO                                   | LBOXPERCMO                                   | NULL                                                                                      |
| `routing_present`     | 1                                            | NULL                                                                                      | 1                                            | 1                                            | 1                                            | 1                                            | NULL                                                                                      |
| `check_no_ok`         | 1                                            | NULL                                                                                      | 1                                            | 1                                            | 1                                            | 1                                            | NULL                                                                                      |
| `posted_equals_trans` | 1                                            | NULL                                                                                      | 1                                            | 1                                            | 1                                            | 1                                            | NULL                                                                                      |
| `note_head`           | Deposit Date: 20260810, Check Date: 20260804 | NULL                                                                                      | Deposit Date: 20260806, Check Date: 20260730 | Deposit Date: 20260812, Check Date: 20260812 | Deposit Date: 20260813, Check Date: 20260701 | Deposit Date: 20260928, Check Date: 20260922 | NULL                                                                                      |
| `ut_rows`             | 0                                            | 1                                                                                         | 0                                            | 0                                            | 0                                            | 0                                            | 1                                                                                         |
| `ut_amount`           | NULL                                         | -297.00                                                                                   | NULL                                         | NULL                                         | NULL                                         | NULL                                         | -784.00                                                                                   |
| `ut_payment_type`     | NULL                                         | PCC                                                                                       | NULL                                         | NULL                                         | NULL                                         | NULL                                         | PCC                                                                                       |
| `ut_msg_tail`         | NULL                                         | Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL; | NULL                                         | NULL                                         | NULL                                         | NULL                                         | Patient record not found for patGUID NULL; PersonPerson record not found for ppGUID NULL; |

## Input files

Each scenario has two files. The C9-P file went through BizTalk. The C9-T file went through the POC (`lockbox run`).

**The two files in a pair are not byte-for-byte the same.** The C9-T file is a copy of the C9-P file with the identifying values replaced by test values. I compared each pair segment by segment. Every pair has the same separators, the same number of segments, and the same segment order.

Same in both files: the amounts (BPR02, CLP02 to CLP04), the dates, the claim status, the service lines, the adjustments, and every segment that is not in the list below.

Different in the C9-T file (test values):
- Bank routing and account numbers (BPR07, BPR09, and in some files BPR10, BPR13, BPR15).
- The trace number (TRN02), which becomes the check number, and the payment reference (REF*F8).
- Payer and payee names, contacts, addresses, and ID numbers (N1, PER, N3, N4, REF, TS3).
- The patient control number (CLP01), and the patient and member names and IDs (NM1).

For the patient (NM1*QC) in the five Finished files, the ID in NM109 is a test patient from `TestC9`. In the two Failed files (U9 and 8G), NM109 is empty in both the C9-P and the C9-T file. This is why both fail with "Patient record not found".

| Scenario | C9-T file (POC)                               | C9-P file (BizTalk)                              |
| -------- | --------------------------------------------- | ------------------------------------------------ |
| 2Q       | files/C9_T_SDOC_20260810_TESTC9_PATPAY_2Q.835 | files/C9_P_SDOC_20260810_GULFCOAST_PATPAY_2Q.835 |
| 8G       | files/C9_T_SDOC_20261009_TESTC9_8G.835        | files/C9_P_SDOC_20261009_GULFCOAST_8G.835        |
| HE       | files/C9_T_SDOC_20260806_TESTC9_PATPAY_HE.835 | files/C9_P_SDOC_20260806_GULFCOAST_PATPAY_HE.835 |
| N2       | files/C9_T_SDOC_20260812_TESTC9_PATPAY_N2.835 | files/C9_P_SDOC_20260812_GULFCOAST_PATPAY_N2.835 |
| PO       | files/C9_T_SDOC_20260813_TESTC9_PATPAY_PO.835 | files/C9_P_SDOC_20260813_GULFCOAST_PATPAY_PO.835 |
| TO       | files/C9_T_SDOC_20260928_TESTC9_PATPAY_TO.835 | files/C9_P_SDOC_20260928_GULFCOAST_PATPAY_TO.835 |
| U9       | files/C9_T_SDOC_20260824_TESTC9_PATPAY_U9.835 | files/C9_P_SDOC_20260824_GULFCOAST_PATPAY_U9.835 |

The C9-P files are production samples. They can hold patient data. Do not send them outside the team.

## Queries

Both queries only read data. Run each one in SSMS. Both give one row for each scenario, with the same columns.

- `C9_T_query.sql`: run on C9-T, database `TestC9`. It has a PASS or FAIL `result` column.
- `C9_P_query.sql`: run on C9-P (read-only secondary), practice database `GULFCOAST`. Change the `USE` line if the database name is different. It can be slow, because `ImportLog.ilExternalReference` has no index.

To compare, put the two result sets side by side. The two files named `C9_T_results.csv` and `C9_P_results.csv` hold the output that was used here.
