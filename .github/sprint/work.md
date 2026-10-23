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

- Approved test sources for read-only queries: C9-T `c9-t-sql-01`, databases `TestC9` and `Utility`, through the saved VS Code profile `C9-T`. Use it only when Wes allows it for the task. Never C9-P or any other production server.
- Approved test servers for a deploy or a rolled-back smoke call: C9-T (`TestC9` and `Utility`). No DBA review for test servers.
- More steps that need a person in this repo: every query on C9-P. Wes runs it and pastes the rows.

## Decision log

- Path: the sprint record `<home>\reports\sprint-<n>.md`, section "Decisions". Open questions go to `KnowledgeBase\docs\05-known-issues-and-open-questions.md`.

## Standing preferences

- Change as little as possible from BizTalk and get the same outcome. The accepted differences are the atomic post plus ImportLog (D22) and the error on a 0-row insert (D19).
- Our procedures live in the `Utility` database.
- Production sample files and rows hold PHI. Do not copy them into a ticket or a git repository.

## Known traps

- C9-T is SQL Server 2019. Entra tokens do not work. Use the saved `C9-T` profile, or a SQL login that Wes types in his own terminal. Host: `c9-t-sql-01.c9.smiledoctors.com`.
- `TestC9` has compatibility level 100. `TRY_CONVERT` and other functions of level 110 or higher fail. Test a generated script on C9-T, or parse it, before you give it to Wes.
- A rerun of a test file with the same REF*F8 fails the duplicate check (D18). Use a new REF*F8, or reset the test rows.
- The `.835` files in `src\testdata\TESTC9` are copies of the PROD samples with the identity values replaced (names, IDs, bank numbers, trace and payment references). Amounts, dates, and structure are the same. Say exactly this when you present a proof.
- In the VS Code terminal, output can be lost. Write it to a file and read the file.
- The folder is not a git repo. Nothing is committed.
