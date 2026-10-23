# Retro: Wes 2 (2026-10-20 to 2026-10-22)

Projects: BizTalk file push to Cloud9 (Feature #27403, story #27987)
Goal: Run a local POC that posts BBVA patient lockbox payments (`RP_BBVA835_Patient`, flow A) into Cloud9 on C9-T without BizTalk, with the same results as BizTalk. Met: yes, for the 7 sample payments (8 scenarios). The error paths are not tested (backlog story #28101).
Velocity: 8 S, 1 M closed. Estimate 17h. Actual 13h. Planned 12h over 2 days. The sprint closed on day 3 (finish date set to 2026-10-22).

## Shipped

| Task   | Title                                            | Size |  Est | Actual |
| ------ | ------------------------------------------------ | ---- | ---: | -----: |
| #27977 | Read the live patient posting procedures (spike) | S    |   2h |     2h |
| #27988 | Make C9-T test files from the patient samples    | S    |   1h |     1h |
| #27989 | Build the 835 reader and patient lockbox mapping | S    |   2h |     1h |
| #27990 | Build the file intake with claim and reset       | S    |   2h |     1h |
| #27991 | Build the Utility posting procedure              | S    |   2h |     1h |
| #27992 | Deploy the Utility posting procedure to C9-T     | S    |   1h |     1h |
| #28067 | Build the SQL poster for the POC                 | S    |   2h |     2h |
| #27993 | Run the POC on C9-T and compare with BizTalk     | S    |   2h |     2h |
| #28063 | Compare POC data in TestC9 with PROD data        | M    |   3h |     2h |

- Result: on C9-T and on C9-P, 7 of 7 scenarios give the same data on 24 columns (`txn_status` is ignored: the end-of-day run changes N to D). The proof is in `src\proof\`.
- No task ran 1.5 times over its estimate. No task ran under half. Three build tasks (#27989, #27990, #27991) closed at exactly half. No change to the estimation guide: three points are too few.
- Time outside tasks: a 2h distraction (#28014, in #28013 "Interruptions - Wes 2") on 2026-10-21.

## Deferred and removed

- Deferred: #27407 Find the cause of the failed transfers (story #27404). #27978 to #27983 (story #27930): configuration export, inventory, rules, Cade, replay rules, design.
- Removed: #27408 (superseded by #27983).
- Out of scope: the insurance lockbox flow and the other 835 flows.
- New work found: #28063 (3h) and #28067 (2h) in the sprint. Backlog story #28101 "Test lockbox POC error paths" for 10 untested scenarios (duplicate payment, unknown payment type, one ID missing, bad GUID, several CLP or ST, odd trace number, missing REF*F8, odd amounts, other lockbox forms, no PracticeConfig row).
- Blockers: #27991 on #27977 (same day). #27993 on #28067 (2026-10-21). #28063 on #27993 (about one day, until 2026-10-22).

## What worked

- The spike first (#27977) found the live procedure, the NULL-GUID path, and D17 to D19 before any build.
- The rule "change as little as possible, same outcome as BizTalk" kept the scope small. The decisions are in the sprint record.
- The PROD samples with their ImportLog rows gave a real oracle for the comparison.
- Auto-review closed build tasks with evidence. Test data has no PROD identities.

## What did not work

- No task built the C# SQL poster. It showed up at #27993 and cost #28067.
- Login to C9-T cost time (Entra is not supported on SQL Server 2019, wrong host name). The access rule changed twice.
- The generated verify script failed on C9-T (`TRY_CONVERT` at compatibility level 100) and had a check-number bug. It was not tested before the hand-off.
- The proof said that the test files "have the same shape". They differ in the identity values. It was corrected after Wes asked.
- The 10 untested scenarios had no task until Wes asked.
- Estimate 17h and 2 days. Actual 13h and 3 days.

## Lessons and changes

| Lesson                                                                          | Change                                                                                 | File                                     |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| A missing part of the path shows up late                                        | Sprint test asks: does every part of the path, from first input to proof, have a task? | `sprint-work\references\sprint-rules.md` |
| Access facts were not known at planning                                         | Planning asks which test sources the session may query and how it logs in              | `sprint-planning\SKILL.md`               |
| Wes wants Copilot to write the retro answers                                    | Retro drafts the answers. Wes only corrects them.                                      | `sprint-retro\SKILL.md`                  |
| C9-T is SQL 2019, TestC9 is compatibility level 100, a rerun needs a new REF*F8 | Known traps                                                                            | `.github\sprint\work.md`                 |
| A proof must say what is the same and what differs                              | Known traps                                                                            | `.github\sprint\work.md`                 |

## Standing preferences

- Change as little as possible from BizTalk and get the same outcome. Our procedures live in `Utility`. No DBA review for test servers.
- The session never queries C9-P. Wes runs those queries.

## Files edited by this retro

- `C:\Users\wesley.valure\.copilot\skills\sprint-work\references\sprint-rules.md`
- `C:\Users\wesley.valure\.copilot\skills\sprint-planning\SKILL.md`
- `C:\Users\wesley.valure\.copilot\skills\sprint-retro\SKILL.md`
- `.github\sprint\work.md` (new)
- This file. The folder is not a git repo, so nothing is committed.
