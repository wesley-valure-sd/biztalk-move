# Sprint work rules for the BizTalk replacement (lockbox POC)

The `sprint-work` skill reads this file. Rules here win over the global
skill. The `sprint-retro` skill updates this file.

## Automated checks (run before Review)

```powershell
dotnet build src\Cloud9.Lockbox.slnx
dotnet test src\Cloud9.Lockbox.slnx
```

## Review environment

- Staging target: none. The POC runs locally and posts to the `TestC9` schema in the `Utility` database on C9-T.
- How the code gets to C9-T: Wes runs `dotnet run --project src\Cloud9.Lockbox.Cli -- run <root>` in his own terminal. The session does not hold the C9-T password.

## Review checklist additions

- Run `src\sql\C9-T.verify-poc-run.sql` on C9-T after a POC run. Each scenario must show PASS.
- For a proof, run `src\proof\C9_P_query.sql` on C9-P (Wes runs it) and compare it with `C9_T_query.sql`.

## Auto-review (sprint-rules.md section 14)

- Approved sources for read-only queries (Wes, 2026-10-29): C9-T `c9-t-sql-01` (`TestC9`, `Utility`) through the saved VS Code profile `C9-T`, and C9-P `c9-p-sql-04` through the saved profile `C9-P (Read-only)`. Read-only only. Return counts and masked text, never PHI.
- Approved test servers for a deploy, a smoke call, or a POC run: C9-T (`TestC9` and `Utility`), through the `C9-T` profile (Wes, 2026-10-29). No DBA review for test servers. Never write to C9-P.
- Review mode (Wes, 2026-10-29, Biztalk 2): auto-review. The session closes a build task when its checks pass, with the evidence in the review note and the Original Estimate as hours if `Get-WlEvidence` has none. Wes reviews the C9-T proof and corrects hours.

## Git and PRs

- One branch and one PR for each sprint lane: `feat/<story id>-<slug>`. Biztalk 2: `feat/28337-insurance-poc`.
- No commitlint config or CI. Use conventional commit subjects (`feat:`, `fix:`, `chore:`, `docs:`, `test:`) and the footer `Refs: AB#<task id>`.
- Remote: `origin` = `wesley-valure-sd/biztalk-move`. Push and open the PR only when Wes says so.

## Decision log

- Path: the sprint record `<home>\reports\sprint-<n>.md`, section "Decisions". Open questions go to `KnowledgeBase\docs\05-known-issues-and-open-questions.md`.
- 2026-10-29 (Wes, Biztalk 2): the insurance POC copies BizTalk for D24 (an ADJ sends the claim REF*F8, so L6 adjustments fail as duplicates), D23 (a CLP01 that is not an int fails in the practice procedure), and D8 (the procedure posts L6 as L6C and L6P).

## Standing preferences

- Change as little as possible from BizTalk and get the same outcome. The accepted differences are the atomic post plus ImportLog (D22) and the error on a 0-row insert (D19).
- Our procedures live in the `Utility` database.
- Production sample files and rows hold PHI. Do not copy them into a ticket or a git repository.

## Known traps

- C9-T is SQL Server 2019. Entra tokens do not work. Use the saved `C9-T` profile, or a SQL login that Wes types in his own terminal. Host: `c9-t-sql-01.c9.smiledoctors.com`.
- `TestC9` has compatibility level 100. `TRY_CONVERT` and other functions of level 110 or higher fail. Test a generated script on C9-T, or parse it, before you give it to Wes.
- A rerun of a test file with the same REF*F8 fails the duplicate check (D18). Use a new REF*F8, or reset the test rows.
- Test files are split by flow, in the BizTalk layout `<flow>\<REGION>\`: `src\testdata\Patient\TESTC9` (flow A) and `src\testdata\Insurance\TESTC9` (flow C). Point `lockbox run` at `src\testdata\Patient` or `src\testdata\Insurance`. The CLI picks the flow from the root folder name (as the BizTalk receive folders) or `--flow`, and refuses any other root (#28342).
- The `.835` files in `src\testdata\Patient\TESTC9` are copies of the PROD samples with the identity values replaced (names, IDs, bank numbers, trace and payment references). Amounts, dates, and structure are the same. Say exactly this when you present a proof.
- The `.835` files in `src\testdata\Insurance\TESTC9` are made by `src\tools\New-TestC9InsuranceFiles.ps1` from PROD insurance samples, one file for each scenario in `src\testdata\Insurance\scenarios.csv`. Identity values are replaced (names, IDs, bank numbers, trace and payment references). Amounts, dates, codes, and structure are the same. The committed files use TestC9 claims and `-F8Seed 1`; regenerate with a new `-F8Seed` before each later C9-T run (see `src\testdata\README.md`).
- PROD samples go in `references\SampleInputFiles\...` (git ignores it). Never put them in `src\testdata`.
- In the VS Code terminal, output can be lost. Write it to a file and read the file.
- The insurance duplicate check matches any ImportLog row with the REF*F8, Failed or Finished (KB doc 05 D25).
- The session cannot run the CLI on C9-T, so a proof task waits for Wes's run (Biztalk 2: #28346 waited 19h in QA). Agree on the run time with Wes when the build tasks start.
