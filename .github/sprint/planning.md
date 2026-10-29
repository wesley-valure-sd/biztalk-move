# Sprint planning rules for BizTalk file push to Cloud9

The `sprint-planning` skill reads this file. Rules here win over the
global skill. The `sprint-retro` skill updates this file.

## Backlog sources

- Feature IDs (sprint scope): #27403 BizTalk file push to Cloud9
- Plan file: `<home>\plans\biztalk-cloud9.plan.yaml`
- Spike artifacts go to: `KnowledgeBase/docs/` (link each from `KnowledgeBase/README.md`)
- Sprint titles: `Biztalk <n> - <goal>`. Wes 2 (2026-10-20) was the first BizTalk sprint (patient lockbox POC); Biztalk 2 is the insurance POC.

## Ready definition (extra checks for this repo)

- A SQL change has its script in `src/sql/` and targets the `TestC9` schema of the `Utility` database on C9-T.
- A C9-T run uses test files with REF*F8 values that are not in the TestC9 ImportLog. Regenerate insurance files with a new `-F8Seed` (`src/testdata/README.md`).
- The expected result of each insurance scenario is in `src/testdata/Insurance/scenarios.csv`.

## Deploy to test

- Automatic staging deploy from main: no. Each SQL procedure needs a "Deploy <x> to C9-T" task before the C9-T run. No DBA review for test servers.

## Sizing notes

- Wes 2 (patient POC): estimate 17h, actual 13h (0.76). Mapping, intake, and Utility procedure tasks closed at half their estimate.
- A C# + SQL change that crosses mapper, poster, and procedure is about 2h. A single build piece is 1h.

## Standing preferences

- Change as little as possible from BizTalk and get the same outcome. Our procedures live in `Utility`.
- Database access (Wes, 2026-10-29): the session may query C9-T and the C9-P read-only connection, read-only only. Return counts and masked text, never PHI. PROD sample files stay in `references/SampleInputFiles/` (git ignores it).

## Known traps

- C9-T is SQL Server 2019; `TestC9` is compatibility level 100: no `TRY_CONVERT`, no `STRING_AGG` (use `FOR XML PATH`).
- The C9-P read-only login cannot see `BTS` procedure bodies. Read them on C9-T.
- The insurance duplicate check matches any ImportLog row with the REF*F8, Failed or Finished (KB doc 05 D25). A rerun needs new REF*F8 values.
- The mssql query tool cuts a text cell at 65,535 characters. Split large results.
- `ADAClaim.adaclaimNumber` is an int. A CLP01 that is not an int fails in the procedure (D23). That is the BizTalk result, not a POC defect.
