# Operator analysis: Phase 2 synthesis (2026-11-18)

This merges the three Phase 1 readers' files (`decisions-findings.md`, `commits-findings.md`, `memory-findings.md`, same folder) and the Phase 0 check. It is also the first manual run of the planned dream skill (future-tbd item 2). **Nothing here is applied yet.** Every change waits for the designer's yes, and the stops are at the end of the file.

**Phase 0 result:** Claude Code's official docs have no `autoDreamEnabled` and no built-in memory consolidation. The memory and settings pages cover only `autoMemoryEnabled` and `autoMemoryDirectory`, and community reports call the setting an undocumented no-op. So the dream skill is built as our own skill.

**Checked by the orchestrator against the repo:**
- **The 735.4M total is right.** `agent-runs.csv` has 44 Orchestrator rows with 44 distinct session keys, so nothing is counted twice. 723.1M of it (98.3%) is cache reads.
- **Agent rows total 147.7M,** so the main session is about **83%** of all logged tokens.
- **Commit counts confirmed:** `agent-runs.md` 44 commits, `session-handoff.md` 31, end-of-day 13, goal state files 30–31 each.

**Reader claims corrected:**
- **Not all memory loads each session.** The memory reader says all 70 KB of memory loads into every session. Only `MEMORY.md` does (4.7 KB), and with `AGENTS.md` the always-loaded total is about 11 KB. Pruning memory helps accuracy more than cost.
- **"voice_check.py missing from main" and "MILESTONES has no A4 line"** are both on the unmerged `feat/voice-check` branch (`ff131dc`), not missing.
- **The decisions reader's work-kind labels are inferred** from the decision logs, not measured. Read the shares in B as rough.

## A. Preferences and memory fixes (dream output)

### A1. Preferences seen in the decision logs and not found in memory or `team.md`

| # | Proposed rule | Evidence | Proposed home |
|---|---|---|---|
| 1 | Ask before every push; an earlier yes covers only that push | D43, D45 (11-01/03) | new memory `push-ask`, or fold into `commit-to-main` |
| 2 | Before asking the designer, check the cast votes and the spec; ask only if still unclear | D104, D165, D50/D61 | fold into `spec-consistency` |
| 3 | The owner fixes their own defect; the orchestrator makes only small, certain fixes, and records them | D48, D173 | operator definition (escalation rules) |
| 4 | The budget guard judges by an average run, not the peak, and overriding is fine while the 5-hour window has room | D187, D167, D171 | `usage-calibration` |
| 5 | A critic miss that the designer catches becomes a new script check or fixture | D8, D24, D142, D159 | `_meta/learnings.md` rule, not memory |
| 6 | Play-test notes keep the designer's own wording beside the spec item | D111-D197 (about 15) | `spec-consistency` |

Strongest already-recorded preferences (no change needed):
- decide by looking at the Design Votes page (9 times)
- fewer permission prompts (8)
- scripts go to Rex or to a script (6)
- see headless agents live (6)

### A2. Memory changes (33 files to about 22)

| Action | Files | Why |
|---|---|---|
| Prune | `flower-patch-followup`, `playtest-0-1-3` | the work is done or superseded; their index lines are now false |
| Merge | `prefer-bash` + `no-select-string` + `no-inline-python` into `shell-habits` | one theme; `prefer-bash` still shows a `VAR=` prefix that the CLI-flag branch forbids |
| Merge | `drafts-folder` into `repo-only`; `model-routing` into `rex-runs-scripts`; `itch-upload-rule` + `demo-link-submissions` into `submission-rules` | overlapping rules |
| Prune | `icm-run-phases` | already stated in `agent-runs.md:5` |
| Correct | `session-handoff` (and its index line, which still says 0.1.4 is waiting on the play-test) | stale; it is the file read first |
| Correct | `future-tbd` | its header says "not started" though items 4, 5a, 7b and 9b are built; shorten its 600-character index line |
| Correct | `test-speed-fixes` | its body uses `VAR=` prefixes while its index line uses flags; dead link `[[quinn-split-pending]]`; trim the history (L4/L5/L17 hold it) |
| Correct | `pending-approvals`, `guide-playtest` | description and body disagree (one approval or two; four guides or six) |
| Trim | `gdd-review-decisions` | most of it duplicates GDD.md; keep "GDD is a first draft" and Terry's pending item |
| Shorten | `course-milestones` | point to MILESTONES.md; keep "final 11/24" |

Do the merges after `fix/cli-args-not-env-prefix` lands, so the flag rules match the code.

## B. Where the main session's tokens go

**Mechanism:** each turn re-reads the whole context; 98% of tokens are cache reads. Cost is roughly **turns × context size × model price**, so a cheaper model, a smaller context and fewer turns all multiply together.

| Kind of work | Share (rough) | Evidence | Cheapest place to run it |
|---|---|---|---|
| Routing and waiting on agents or goal runs | sessions mostly doing this total about **398M (54%)**; 7 of the 10 costliest | 29b33c17 69M (668 turns), 81c6a13d 58M, 4ccf1614 56M, 452ddba6 36M, 28475ef9 33M | **Sonnet operator** with a small ICM context; waits go to Monitor or notifications, not turns; Rex for runs |
| Building the crew and pipeline (design plus doc work) | **170M (23%)**, one session, fa5df4be | D01-D54 | stays **Opus**; it was a one-time build |
| Judgement: votes, play-test synthesis, specs | about 100M | 3e77b3cf, e0d1da16, 49ba7bdd, 360de647 | stays **Opus**; it can be run as a short session the operator hands off to |
| Mechanical: commits, handoff, memory, logs, end-of-day, doc syncs | about 30M directly, but present in every session | 147 touches of the handoff, memory and log files; 13 end-of-day and 14 checkpoint commits; 78 touches of status tables | **scripts** first, then the operator |
| Idle | small in tokens | 24feb07b 13.5 h for 38 turns; 60faff60, edd56bee, 2159a8f0 | no change needed; shows the waits already avoid turns when nothing polls |

### Token-saving opportunities, ranked

| # | Cut | Saves | Effort |
|---|---|---|---|
| 1 | **Operator session (Sonnet, ICM context) for routing and waiting** | the largest share (about 54% of the main session's tokens is in sessions like this); exact gain measured in Phase 5 | Phase 3 |
| 2 | **Merge `fix/cli-args-not-env-prefix` and `feat/voice-check`** | fast test flags end 15-minute runs and the turns waiting on them; voice checks skip Clara calls | small, needs a yes |
| 3 | **End-of-day as one script** (export, page, links, commit), with the operator writing only the decision log | 13 commits' worth of mechanical turns | small to medium |
| 4 | **Generate the handoff and `MEMORY.md` status lines** from git and the run log | 63 hand edits | medium |
| 5 | **Stop committing goal state on every goal commit** (`blackboard.md`, `ledger.json`, `gaps.json`: 30–31 commits each); commit once per run | smaller diffs for Doris and for the readers | small |
| 6 | **Generate status tables by script** (README, AGENTS.md, team.md, CONTEXT files: 78 touches), extending `sync_docs.py` | Doris reads less, less doc drift | medium |
| 7 | **Hook for "scripts go to Rex"** (L21) and a `commit-to-main` script (L24) | stops expensive repeat slips | small |
| 8 | Cheaper Clara pass plus a quote cache (A4 item a) | small in tokens (content runs average 124k) but **lifts the content-run gate** | medium |

Not a lever: pruning memory, since only 4.7 KB of it loads each session.

## C. Priority upgrade (recommendation)

**Build the operator, with the dream pass as its first skill, right after merging the two branches.**

- **Why it comes first:** it targets the 83% of tokens the main session uses. The other upgrades in memory work on small slices:
  - 9a's Clara cost is about 6M in total.
  - The live view saves interruptions, not tokens.
  - Episodic memory is a later convenience.
- **What the merge does:** it is the operator's first, small task, and it makes the memory flag rules true.
- **Timing risk:** A7 is due 11/18–19 and the final is 11/24, and M4 is still unpushed on the desktop. Keep the operator to its first version (routing, waiting, mechanical work, the dream pass) and do not let it delay M4 or M5.
- **A7 bonus:** this analysis (section B and the run-log tables) is ready material for A7 deliverable 3, the pipeline audit and cost analysis.
- **Next after the final:** 9a (it lifts the content gate), then the live view (5b), episodic memory (1) and the Godot 4.7.2 upgrade (10).

## D. TBDs to move to the operator

| Item | Today | Moves to |
|---|---|---|
| Routing to agents, writing briefs, dispatching Rex, relaying board stops and votes to the designer | Opus main session | **operator** |
| Dream pass: memory prune, merge and correct (future-tbd 2), run from end-of-day | not built | **operator** (skill) |
| Mechanical end-of-day steps, handoff rewrite, checkpoint commits, merging approved branches | Opus | **operator** (script where possible) |
| Republish the decision page after the pull; tick the stale README boxes (milestone dates, token budget) | open | **operator** |
| Extend `live.json` to script steps (5a remainder), then `watch.py` (5b) | open | **operator** |
| L21 Rex hook, L24 commit-to-main script, stop committing goal state | open | **operator** |
| A7 deliverable 3 tables from the run log | open | **operator** drafts, Opus writes the analysis |
| Cheaper Clara pass plus quote cache (9a), episodic memory design (1), `/goal` wrapper (8), Godot 4.7.2 plan (10), live side pane (5c) | open | **Opus** to design; Patricia to build |
| Journal in Godot (7a), M5 QA and balance sim, parallel tests | scheduled | **agents** (Patricia, Quinn, Terry, Rex) |
| Push M4 from the desktop, itch 0.2.0, course submissions, content approvals, title and guide name, transcript-sync route (3), onboarding (6) | open | **designer** |

**Operator escalates to the designer or an Opus session:** design trade-offs, anything touching the GDD, creative A/B picks, explaining choices, and any spending, push or upload.

## Stops for the designer

**Held until the desktop's M4 work is pulled (designer, 2026-11-18):** the desktop's memory may differ from this machine's, so A1 and A2 run on the merged memory after the pull, not before. The two branches are merged together with the desktop commits, in one pass. A dream pass made before the pull would conflict or prune facts only the desktop has.

1. **A1:** add which of the 6 preferences?
2. **A2:** apply the memory changes (after the branch merge)?
3. **B and C:** accept "operator first, after merging both branches"?
4. **Merges:** merge `fix/cli-args-not-env-prefix` and `feat/voice-check` into main now?
