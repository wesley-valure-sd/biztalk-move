# Test data

C9-T (`TestC9`) test files, split by payment flow. The layout is `<flow>\<REGION>\<file>`, as in the BizTalk receive folders (`...\Patient\GULFCOAST\`). The region folder is the practice name. Point `lockbox run` at a flow folder, for example `src\testdata\Patient`.

| Folder                                   | Flow                         | Posts with                        |
| ---------------------------------------- | ---------------------------- | --------------------------------- |
| [Patient/TESTC9](Patient/TESTC9)         | A. BBVA patient lockbox 835   | `BTS.Post835PatientTransaction`   |
| [Insurance/TESTC9](Insurance/TESTC9)     | C. BBVA insurance lockbox 835 | `BTS.Post835InsuranceTransaction` |

## How a file is classified

BizTalk picks the flow by the receive folder (`...\Patient\` or `...\Insurance\`), not by the file content. Keep each file in the folder of the flow that processed it in production. The content is only a hint:

- **Patient.** One CLP for each transaction set. No SVC, CAS, or PLB. Loop 2100 REF qualifiers `F8` and `G2`.
- **Insurance.** Usually SVC service lines and CAS adjustments, and loop 2100 REF qualifiers `EJ` (patGUID) and `69` (pipGUID). But about 6% of production insurance claims (in about a third of the files) have no `EJ` or `69` (only `F8` and `G2`, or `EA`), and a few files have no SVC. Those claims look like patient claims.

## Patient files (flow A)

| Code | ST | CLP | BPR04 | Scenario                         |
| ---- | -- | --- | ----- | -------------------------------- |
| HE   | 1  | 1   | CHK   | GUIDs present                    |
| 2Q   | 1  | 1   | CHK   | GUIDs present                    |
| N2   | 1  | 1   | PCC   | GUIDs present                    |
| PO   | 1  | 1   | CHK   | GUIDs present                    |
| TO   | 1  | 1   | CHK   | GUIDs present                    |
| U9   | 1  | 1   | PCC   | No NM1*IL, no NM109 (NULL GUIDs) |
| 8G   | 1  | 1   | PCC   | No NM1*IL, no NM109 (NULL GUIDs) |

## Insurance files (flow C)

One file for each scenario in [Insurance/scenarios.csv](Insurance/scenarios.csv). The scenarios come from 2,112 production GULFCOAST insurance files (2026-02 to 2026-10) and the BizTalk result of each claim in the `C9-GulfCoast` ImportLog (read-only, C9-P). "BizTalk result" is what production BizTalk logged for the source claim.

| Id  | ST | CLP | PLB | Scenario                                                                    | BizTalk result                                                            |
| --- | -- | --- | --- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| I01 | 1  | 1   | 0   | One CLP, CHK, REF*EJ and REF*69, service CAS (baseline)                     | Finished: Success                                                         |
| I02 | 1  | 2   | 0   | Two CLPs in one transaction set                                             | Finished for each CLP                                                     |
| I03 | 2  | 2   | 0   | Two transaction sets in one file, NON, CLP04 0                              | Finished for each set                                                     |
| I04 | 1  | 1   | 0   | ACH, TRN02 of 15 digits (larger than the int `transCheckNumber`)            | Finished                                                                  |
| I05 | 1  | 1   | 0   | NON, CAS with more than one pair (the note lists the first pair of each)   | Finished                                                                  |
| I06 | 1  | 1   | 0   | BOP (BPR01 U)                                                               | Finished                                                                  |
| I07 | 1  | 1   | 0   | CLP04 0, CLP02 4 (denied)                                                   | Finished: a 0.00 transaction                                              |
| I08 | 1  | 1   | 0   | CLP04 negative, CLP02 22 (reversal), no REF*F8                              | Finished: transAmount is positive                                         |
| I09 | 1  | 1   | 0   | No REF*EJ or REF*69 (F8 and G2 only), NM1*QC without NM109                  | Failed: Could not locate Claim; Could not locate Insurance Policy        |
| I10 | 1  | 1   | 0   | No REF*EJ, REF*69, or REF*F8 (EA and IG only)                               | Failed: same as I09. `ilExternalReference` empty                          |
| I11 | 1  | 1   | 0   | CLP01 longer than the int range (14 digits)                                 | Failed: The conversion of the nvarchar value ... overflowed an int column |
| I12 | 1  | 1   | 0   | CLP01 not numeric                                                           | Failed: Conversion failed when converting the nvarchar value ... to int   |
| I13 | 1  | 1   | 0   | GUIDs present, no REF*F8                                                    | Finished. No duplicate protection                                         |
| I14 | 1  | 1   | 1   | PLB L6 (negative), more than one adjustment pair                            | CLP Finished. ADJ Failed: Duplicate payment (ADJ reuses the CLP REF*F8)   |
| I15 | 1  | 1   | 2   | PLB L6 and WO, header REF*EV, no REF*LB, no REF*F8                          | CLP Finished. Both ADJ Finished                                           |
| I16 | 1  | 1   | 0   | NM1*QC without NM109 (no `pipPolicyNumber`)                                 | Finished                                                                  |
| I17 | 1  | 5   | 2   | Five CLPs and two PLBs in one transaction set (guard)                       | Failed: There were 5 CLP payments and 2 PLB adjustments ...; no post      |
| I18 | 1  | 1   | 0   | REF*69 is a GUID that is not in the practice database                       | Failed: PatientInsurancePolicy record not found for pipGUID               |
| I19 | 1  | 1   | 0   | LQ remark segment in the service loop                                       | Finished                                                                  |
| I20 | 1  | 1   | 0   | DTM*150 and DTM*151 service dates, NM1*QC without NM109                     | Finished                                                                  |
| I21 | 1  | 1   | 0   | Same content as I01 under a new file name. Run after I01                    | Failed: Duplicate payment for ilExternalReference                         |
| I22 | 1  | 1   | 0   | ACH, TRN02 with a letter                                                    | Finished                                                                  |

"Finished" includes the variant "Payment amount exceeds remaining balance. Success". The procedure decides it from the claim balance, not from the file.

I15 comes from a hand-made Delta Dental file (`BD_SDOC_*`). It is the only sample with a WO adjustment and with no REF*LB.

### How the files are made

[New-TestC9InsuranceFiles.ps1](../tools/New-TestC9InsuranceFiles.ps1) reads the production samples from `references\SampleInputFiles\BBVA_835\Insurance\GULFCOAST` (git ignores that folder) and writes these files. It replaces names, IDs, bank numbers, trace numbers, and payment references, and keeps amounts, dates, codes, and structure. Masked values keep their shape (digit count, letters), because the shape drives I04, I11, I12, and I22. The script stops if a source value survives.

The committed files use the first 27 TestC9 claims of [C9-T.insurance-test-identities.sql](../sql/C9-T.insurance-test-identities.sql) on 2026-10-29 (13874 to 13865 and 12900 to 12884) and REF*F8 values `EOB<Id><n>0001` (`-F8Seed 1`). No TestC9 ImportLog row had those REF*F8 values on 2026-10-29. After a C9-T run, the procedure rejects a second run of the same REF*F8 (any earlier ImportLog row counts, Failed or Finished). For the next run:

1. Run [C9-T.insurance-test-identities.sql](../sql/C9-T.insurance-test-identities.sql) on C9-T and save the grid as CSV outside the repo (or reuse the same claims).
2. Run `New-TestC9InsuranceFiles.ps1 -IdentityFile <csv> -F8Seed <n>` with a new `-F8Seed`.

### Production gaps with no test file

- PLB with a positive L6 amount, and PLB codes other than L6 and WO: no production sample.
- Claim-level CAS: one production claim (BPR04 NON, Finished), inside a file of 32 transaction sets. Cover it with a unit test.
- 128 of the 2,112 production files have no ImportLog row and no posted check. BizTalk most likely suspended them or never picked them up. The replacement must log every file.
- 43 file names have more ImportLog rows than claims. The two-character file name suffix repeats, so a file name is not a unique key.
