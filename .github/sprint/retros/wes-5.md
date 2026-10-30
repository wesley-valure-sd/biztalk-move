# Retro: Wes 5, Biztalk 2 - Insurance POC (2026-10-30 to 2026-10-30)

Sprint record: `AdoWorklog\reports\sprint-5.md`. Iteration: `SD\Wes\Biztalk 2 - Insurance POC - 2026-10-30`. Most of the work happened on 2026-10-29, before the start date (see "What did not work").

## Sprint summary

Projects: BizTalk file push to Cloud9 (Feature #27403, story #28337)
Goal: Run a local POC that posts BBVA insurance lockbox payments (`RP_BBVA835_Insurance`, flow C) into Cloud9 on C9-T without BizTalk, and show that the 22 insurance scenarios give the BizTalk result. Met: yes.
Velocity: 9 S, 0 M, 0 L closed. Estimate 12h. Actual 12h (all logged at the estimate under auto-review, so not a measured velocity).
Added after planning: 0h.
Shipped: BizTalk file push to Cloud9: 9 tasks.
Process lessons:

| Lesson | Change | File |
| ------ | ------ | ---- |
| ADO sprint dates cannot overlap, so a second open sprint starts after the open one and earlier work falls outside its dates | Tell Wes the trade-off when he asks for a second open sprint | `sprint-work\references\sprint-rules.md` section 2 |
| Auto-review was used with no rule behind it (`work.md` cites a missing section 14) | Add the auto-review policy, with no close straight from Active and no calibration from estimate hours | `sprint-rules.md` section 14, `sprint-work\SKILL.md` step 6, `sprint-retro\SKILL.md` step 3 |
| An unblocked task in an approved queue needed a second yes by the skill, but the queue approval covered it | Set it Ready on a "Scope unchanged" pre-check and note the result | `sprint-work\SKILL.md` step 5 and "Ready pre-check" |
| `Get-WlSprint <n>` fails for a sprint not named `Wes <n>`, and the skills junction path was stale | Use the iteration name from the record, and fix the path | `sprint-retro\SKILL.md` Setup and step 7 |

## BizTalk file push to Cloud9

### Shipped

| Task   | Title                                                  | Size | Est | Actual |
| ------ | ------------------------------------------------------ | ---- | --: | -----: |
| #28338 | Read the insurance procedure and settle the open rules | S    |  1h |     1h |
| #28340 | Build the insurance CLP mapping and guard              | S    |  1h |     1h |
| #28345 | Build the insurance SQL poster                         | S    |  1h |     1h |
| #28343 | Build the Utility insurance posting procedure          | S    |  2h |     2h |
| #28342 | Route insurance files to the insurance mapper          | S    |  1h |     1h |
| #28341 | Build the PLB adjustment posts                         | S    |  1h |     1h |
| #28344 | Deploy the Utility insurance procedure to C9-T         | S    |  1h |     1h |
| #28346 | Run the insurance scenarios on C9-T and compare        | S    |  2h |     2h |
| #28347 | Compare insurance POC rows with PROD rows              | S    |  2h |     2h |

- Result: 22 of 22 scenarios PASS on C9-T (#28346). The POC rows match the C9-P rows on all 25 post keys and 14 columns, and each failure has the same UnmappedTransaction row (#28347, KB doc 04). Known differences: `transStatus` N vs D, a `transCreditGroup` on the I15 rows in PROD only (later Cloud9 work), and the I02 test file split of one claim number.
- Story #28337 closed. No deploy: the POC runs locally, and the Utility procedure is on C9-T (#28344).
- Before the sprint: #28339 (test files with TestC9 identities, 1h, 2026-10-29).

### Deferred and removed

- Deferred at planning (not in the sprint): #28349 Test the insurance POC error paths (story #28348), #28336 Find why 128 insurance files were never logged (waits on Taylor), story #27930 tasks, story #28324 tasks, #27407.
- Removed: none.
- New work found: backlog story #28364 "Post L6 interest adjustments without duplicates" (the D24 fix).
- Dropped: a masking fix for the I02 test file (one claim number split into two TestC9 claims). Both sides post the same rows; recorded in KB doc 04.

### What worked

- The proof passed on the first run: 22 of 22 PASS (#28346) and a full PROD match (#28347).
- The mapper check against C9-P notes found the set-wide NON CAS lists before any C9-T run (#28340, 80 of 80 notes after the fix).
- D24, D23, and D8 were decided before the work (#28338, 2026-10-29), so no task waited on a decision.
- The early Utility deploy as the compile check (#28343, Wes approved) left #28344 as a 1h smoke task.
- No review rejection, no stuck task, no failing check.

### What did not work

- #28347 stayed Blocked for about 20.5h (2026-10-29 20:10 to 2026-10-30 16:48 UTC), because #28346 waited 19h in QA for Wes's CLI run. The session cannot hold the C9-T password.
- The actual hours cannot calibrate estimates: under auto-review all 9 tasks were logged at the estimate, and the ADO state spans (5 to 20 minutes for each task) are too short to be the work time.
- The sprint start was set to 2026-10-30 to avoid an overlap with Make a Payment 1, so 10h of the 12h are dated 2026-10-29, before the start.
- `work.md` cites "sprint-rules.md section 14" for auto-review, and that section does not exist.
- Skill friction: `Get-WlSprint 5` failed (the sprint is not named `Wes 5`), and the retro skill names an old skills path.

### Lessons and changes

| Lesson | Change | File |
| ------ | ------ | ---- |
| The proof task waits on Wes's CLI run, because the session cannot run the CLI on C9-T | Agree on the run time with Wes when the build tasks start | `.github\sprint\work.md` Known traps |

### Standing preferences

none
