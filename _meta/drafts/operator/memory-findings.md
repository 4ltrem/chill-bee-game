# Memory findings (read-only analysis, 2026-11-18)

Scope: all 33 files in `_meta/memory/` (32 topic files plus MEMORY.md), `_meta/learnings.md`, `_meta/agent-runs.md`, MILESTONES.md Open, README Outstanding TBDs, `_meta/team.md`, AGENTS.md. Checked against the working tree on branch `feat/operator` (HEAD = main = `2e36631`). Line refs are `file:line`. "unclear" = could not be verified from the repo.

Key repo facts used as evidence:
- `_tools/voice_check.py` and `_tools/godot_path.py` do NOT exist on main/this branch. They live only on unmerged branches: `feat/voice-check` (`ff131dc`) and `fix/cli-args-not-env-prefix` (`51b775d`, `8011388`; this branch adds `--only`, `--time-scale`, `--skip-x1` to `godot_run.py`). On this branch `godot_run.py:34` still hard-codes `C:\Users\mtrem\...` and has no `--only` flag (`_tools/godot_run.py:177-183`).
- `_meta/memory/quinn-split-pending.md` is linked (`test-speed-fixes.md:20`) but does not exist.
- `_meta/drafts/operator/` was empty before this file.

## 1. Memory health (dream job)

Size outliers: `future-tbd.md` 7.5 KB / 83 lines, `gdd-review-decisions.md` 6.7 KB, `MEMORY.md` 4.7 KB, `session-handoff.md` 4.8 KB, `test-speed-fixes.md` 4.2 KB. Everything else is 0.7-3.3 KB.

| File | Problem | Proposal | Reasoning / evidence |
|---|---|---|---|
| `flower-patch-followup.md` | Stale: the work is done (MEMORY.md:1 itself says "DONE 11/6 ... except Bob's shots"); the file body still says "not merged yet" (`flower-patch-followup.md:11`) and the worktree `.claude/worktrees/flower-patch` is gone (only `icm-architect` remains in `.claude/worktrees/`). | **Prune** (delete file and index line); Bob's shots, if still wanted, is one line for session-handoff | Contradicts its own index line; past fact. |
| `playtest-0-1-3.md` | Stale: 0.1.3 play-test, superseded by 0.1.4 which is merged (`session-handoff.md:15`). Items became `game/specs/0.1.4-ui-placement.md` items. Names recordings under `%APPDATA%` that are history. | **Prune** after confirming the spec holds items 1-3 and the Round 7 UI direction; else fold into the spec | MEMORY.md:7 still presents it as live ("noted, not fixing yet"); that is false now. |
| `session-handoff.md` | Stale and wrong in places. States "main last commit `739b51c`" (`:13`) but main is `2e36631`; "M4 ... due 2026-11-18" (`:17`) is today; MEMORY.md index line says "0.1.4 items 1-21 done (948a49e) ... waits on designer play-test + itch upload" which contradicts the file (0.1.4 is merged and play-tested, `:15`). The index line is from an older version. Also mixes the A4 gate (`:21`), laptop plan (`:23`) and M3 summary (`:19`). It carries a rule to "Replace, don't append" (`:11`) but has grown. | **Correct** (rewrite to current state; fix index line). Move the "Gate on content runs" to `future-tbd` only | Handoff is the file read first; stale commit hashes and an outdated index line mislead the next session. Whether M4/0.2.0 is pushed or on itch is "unclear" (`:17`). |
| `future-tbd.md` | Too long for one fact (10 items, 83 lines) and the header says "not started" (`:11`) though items 4, 7b, 9b are built and 5a is built. Items 7, 9 and 10 are scheduled/assessed work, not backlog. | **Correct** header; **split**: keep a short index file, and move items 5, 7-10 to their own memories (or to MILESTONES Open); mark 4, 7b as DONE | Item 9(b) says BUILT as `voice_check.py` (`:65`) but that script is not on main (see Section 3). |
| `gdd-review-decisions.md` | 6.7 KB, ~14 distinct decisions in one file; most are GDD content (the GDD is the source of truth, AGENTS.md "single source of truth") and contain stale pending notes (Terry re-check "NEW PENDING", `:24`; "Worktree itself still exists (locked)", `:25`). Description (`:3`) names only 2 decisions. | **Correct then prune**: strip what GDD.md already records; keep only "GDD is a first draft, don't flag missing numbers" and the Terry pending item (also in README TBDs `README.md:94-103`) | Duplicates GDD; the worktree sentence is stale. Whether each decision is in the GDD today is "unclear" (not diffed). |
| `test-speed-fixes.md` | Mix of history and live rule, 4 dated sections; the live rule is the index line and Section "2026-11-08, missed". Contradiction: body says `CB_TIME_SCALE=6 CB_SKIP_X1=1 python -I _tools/godot_run.py all` (`:22`); MEMORY.md index says use flags `--time-scale 6 --only`, "never VAR= prefixes". Flags exist only on branch `fix/cli-args-not-env-prefix`, not on main/this branch. Also dead link `[[quinn-split-pending]]` (`:20`) and says "start tomorrow with 1 and 2" (`:29`, long done). | **Correct**: rewrite to the current rule, drop history (L4/L5/L17 hold it); keep the parallel-test backlog item as one line in future-tbd; remove dead link | Index and body disagree; flags not merged. Merge branch first or the index misleads Rex briefs. |
| `prefer-bash.md` | Instructs inline env prefix `CB_TIME_SCALE=6 python ...` (`:15`) which `test-speed-fixes` index and branch `fix/cli-args-not-env-prefix` ("Pass test/render settings as CLI flags, not VAR= shell prefixes") now forbid. | **Correct** (point to flags) and **merge** with `no-select-string` and `no-inline-python` into one `shell-habits` memory | Three 0.7-1.3 KB files with one theme and cross-links (`no-select-string.md:15`, `prefer-bash.md:15`). |
| `no-select-string.md`, `no-inline-python.md` | Overlap (see above). `no-inline-python` and `edit-lines-only` both say "enforced by `guard_shell.py`" (`no-inline-python.md:15`, `edit-lines-only.md:20`). | **Merge** into `shell-habits` (with prefer-bash); the guard_shell enforcement is the real rule, the memory is a pointer | Enforced rules do not need prose. |
| `repo-only.md`, `drafts-folder.md` | Overlap: both say writes outside the repo are blocked by `guard_shell.py` (`repo-only.md:15`, `drafts-folder.md:15`). `drafts-folder` also still says "never the temp folder" while this task's scratchpad is outside the repo. | **Merge** `drafts-folder` into `repo-only` (one paragraph); keep a line "drafts for later sessions go in `_meta/drafts/<version>/`" | One concern: where files may be written. |
| `rex-runs-scripts.md`, `model-routing.md`, `cost-rules.md` | `model-routing` (0.8 KB, `:11-15`) is the general form of `rex-runs-scripts`; both point to `cost-rules`. | **Merge** `model-routing` into `rex-runs-scripts`; keep `cost-rules` | Same decision: delegate small and scripted work to cheap agents. Note this analyst run is itself the "operator" pattern the designer may want. |
| `course-milestones.md`, `itch-upload-rule.md`, `demo-link-submissions.md` | Overlap with MILESTONES.md (source of truth: `MILESTONES.md:15-23, 29`). `course-milestones` dates are partly past ("A5 11/15", "A6 11/12", M4 11/18); `demo-link-submissions` says "Which page shows the tooling assignments is not settled yet" (`:18`): status unknown now. | **Correct**: shorten `course-milestones` to "see MILESTONES.md, final 11/24"; **merge** `itch-upload-rule` and `demo-link-submissions` into one `submission-rules` file | Each repeats rules that MILESTONES.md Open already records. |
| `pending-approvals.md` | Description (`:3`) says only onboarding-script awaits approval; body (`:19`) and MEMORY.md:2 add biome-intros. Both files confirm `status: draft` (`content/onboarding-script.md:4`, `content/biome-intros.md:4`). Crossed-out items are done. | **Correct** description; delete struck-out lines (`:23-25`) | Internal contradiction. |
| `guide-playtest.md` | Long (2.6 KB); the 4-guide list (`:12-14`) is superseded by the six-guide note (`:20`, designer 2026-11-07); `content/guides.md` approved (`:22`, `content/guides.md:4`). MEMORY.md:5 still says "four characters". | **Correct** (rewrite around six guides; link guides.md) | Index line and body disagree. |
| `usage-calibration.md` | Mixes a rule (log usage before/after) with the budget_guard description (`:28`) and a hook list (`:30`). The budget numbers are in `_meta/agent-runs.md`. | **Correct**: keep the rule, move budget_guard facts to `_tools/CONTEXT.md` (check it exists there: unclear) | Duplicated with agent-runs.md Daily Budget. |
| `icm-run-phases.md` | Rule is already stated in `agent-runs.md:5`; run log generator applies it. | **Merge into** `agent-runs.md` (already there) and prune | Duplicate of a written doc. |
| `ab-comparison-page.md` | 3.3 KB, three rules in one (one artifact, numeric changes need visuals, contact sheet size). The contact-sheet "fix before the next votes page" (`:30-32`) has unknown status. Artifact URLs are fine. | **Keep**, split optional; check `compare_page.py` for the contact-sheet fix (unclear) | Live rule, enforced by `guard_shell.py` (`:23`). |
| `look-before-done.md`, `fix-needs-commit.md`, `spec-consistency.md`, `scripted-shots.md`, `variant-shots.md`, `dev-mode-and-pacing.md`, `edit-lines-only.md`, `end-of-day-routine.md`, `one-folder-rule.md`, `commit-to-main.md`, `cost-rules.md` | One fact each, still true or tool-backed. Minor: `end-of-day-routine.md` repeats `session-handoff` ownership; `edit-lines-only.md` has 4 mixed facts (rule, team rule 5, `.gitattributes`, guard). | **Keep** | No contradictions found. |

Other index issues in `MEMORY.md`:
- Line for `session-handoff` is out of date (see table).
- Line for `future-tbd` (`MEMORY.md:4`) is a 600-char list; shorten to "backlog, see file".
- Line for `playtest-0-1-3` and `flower-patch-followup` should go with the prunes.
- Every topic file has an index line (checked; no orphans). One dangling `[[quinn-split-pending]]` link inside `test-speed-fixes.md:20`.

Proposed net result: 33 files -> about 22 (prune 2-3, merge 8 into 3-4 files, 1 split).

## 2. Preference inventory

User/feedback rules in memory, one line each (decision-log cross-check: dates are the designer's).

| # | Rule | Source | Enforcement |
|---|---|---|---|
| 1 | Run `end-of-day` skill only on explicit "end of work day / done for the day / wrap up"; "close this session" only rewrites the handoff | `end-of-day-routine.md:11-20` | memory + skill trigger |
| 2 | Checkpoint commits on a milestone branch are fine mid-session; no other mid-session commit/export | `end-of-day-routine.md:18` | memory |
| 3 | Change files only with Edit on the needed lines; no whole-file rewrite, `sed -i`, `cat >>` | `edit-lines-only.md:11-19`; team rule 5 `team.md:55` | `guard_shell.py` |
| 4 | Write only inside the repo; read outside freely; moving/deleting outside files needs a yes | `repo-only.md:11-15` | `guard_shell.py` |
| 5 | Unfinished work for a later session goes in `_meta/drafts/<version>/` | `drafts-folder.md:11-15` | `guard_shell.py` |
| 6 | No inline code (`python -c`, heredoc interpreters, `node -e`); run repo scripts by path | `no-inline-python.md:11-15` | `guard_shell.py` |
| 7 | No PowerShell `Select-String`; search with Grep | `no-select-string.md:11-15` | memory |
| 8 | Use Bash and Linux tools over PowerShell cmdlets | `prefer-bash.md:11-15` | memory |
| 9 | Scripts (godot_run, build, mutate, ui_shots, shots, contact sheet) go to Rex, never the orchestrator or Quinn | `rex-runs-scripts.md:11-18` | memory + brief assertion (L21) |
| 10 | Small admin tasks go to a cheap-model subagent, never a `/model` switch | `model-routing.md:11-15` | memory |
| 11 | Brief Rex with the fast flags: `--only` while iterating; `--time-scale 6 --skip-x1` at checkpoints | `test-speed-fixes.md:26`, MEMORY.md | memory (flags unmerged) |
| 12 | "Fixed" needs the commit that changed the bug's code; green test is not a fix | `fix-needs-commit.md:11-15` | goal_agent gates (L18) |
| 13 | Never call a model/scene change done on tests alone; compare a fresh render with the picked variant | `look-before-done.md:11-15` | `pick_match.py`, goal_agent |
| 14 | Before adding a play-test item to a spec, grep the spec for the same object and fix contradictions in the same edit | `spec-consistency.md:11-15` | `spec_lint.py` |
| 15 | Every creative A/B and every numeric visual change becomes a section of the one Design Votes artifact, built by script, never a new artifact or browser tab; real shots, max 9 per page, yes/maybe/no + note | `ab-comparison-page.md:11-32` | `guard_shell.py` (publishing location) |
| 16 | Contact sheets must be full width and click-to-enlarge, or separate cards | `ab-comparison-page.md:30-32` | open (unclear) |
| 17 | Repeated screenshot moments by script (`ui_shots.py`); an agent only for a new screen/phase/menu; gradual animations get at least 3 shots | `scripted-shots.md:11-15` | memory |
| 18 | Variant shots on one shared grid, close up; one folder per vote round `<prop>-r<N>` | `variant-shots.md:11-18` | `model_shots.py` refuses unnumbered |
| 19 | Every spec has an in-game Dev mode; every tunable in config; placeholders err slow and physical; tests written from the spec, not after the code | `dev-mode-and-pacing.md:11-17` | `game/CONTEXT.md` Process 2-3 |
| 20 | Main folder on the milestone branch; worktree only for parallel work, removed the day it merges; main session does not edit a live goal run's files | `one-folder-rule.md:11-17` | `guard_shell.py` rule 6 + run lock |
| 21 | Commit to main via a worktree inside the repo, `-c core.hooksPath=.githooks`, push with `GCM_INTERACTIVE=never` | `commit-to-main.md:11-15` | memory only (L24) |
| 22 | Itch upload only at a new milestone number (0.2.0, 0.3.0), or when the build is an assignment demo | `itch-upload-rule.md:11-22`, `MILESTONES.md:29` | memory + MILESTONES |
| 23 | Every assignment is a demo link, resubmitted after each milestone; keep the link stable | `demo-link-submissions.md:11-18` | memory |
| 24 | Every agent run logs plan usage before/after, orchestrator tokens included | `usage-calibration.md:11-22` | hooks (`runlog.py`, `log_subagent.py`, ...) |
| 25 | Tag every run `post-ICM` in the run log | `icm-run-phases.md:11-14` | `agent-runs.md:5` |
| 26 | Nine token-cost cuts approved (see Section 4) | `cost-rules.md:8-19` | partly scripted |
| 27 | Agent replies at most 150 words; keep CLI replies short; fresh orchestrator session per milestone | `cost-rules.md:17,19`; `session-handoff.md:29` | agent definitions |
| 28 | GDD is a first draft: don't flag missing numbers as defects | `gdd-review-decisions.md:31` | memory |
| 29 | Nothing reaches GDD.md until the designer accepts | `AGENTS.md` ("The one rule"), `team.md:54` | AGENTS.md |
| 30 | No `generate.py` content run until the A4 grader items (a) and (b) are built | `session-handoff.md:21`, `future-tbd.md:58-60`, `MILESTONES.md` Open | memory (check MILESTONES: the Open list I read does not contain this A4 line, `MILESTONES.md:27-37`; unclear) |
| 31 | Don't start future-tbd items unasked | `future-tbd.md:82-83` | memory |
| 32 | Wait by running, not sleeping | `team.md:56` | harness |

Note for cross-checking: the Open list in `MILESTONES.md` (lines 27-37) has no A4 grader entry, although `future-tbd.md:59` and `session-handoff.md:21` say "MILESTONES.md Open". Either the entry was lost or it sits on another branch (unclear).

## 3. TBD inventory

Status legend: built = code exists on main; built-unmerged = exists on a branch only; open; scheduled; blocked.

### 3a. `future-tbd.md` (10 items)

| # | Item | Status | Evidence | Owner |
|---|---|---|---|---|
| 1 | Episodic memory upgrade (recall past sessions from `_meta/sessions/*/decisions.md`) | open, not started | `future-tbd.md:13-15` | Opus (design); operator for the indexer |
| 2 | Dream skill / check `autoDreamEnabled` | open; this findings file is a manual dry run. `autoDreamEnabled` appears only in `future-tbd.md:18`, so the setting has not been checked | `future-tbd.md:16-18` | operator (check setting, then skill) |
| 3 | Sync transcripts between machines | open; blocked by privacy decision (no git) | `future-tbd.md:19-21` | designer (choice of route), operator (script) |
| 4 | Learnings file | built | `_meta/learnings.md` (L1-L24) | operator (upkeep via end-of-day step 2) |
| 5a | `live.json` written by `generate.run_agent`, shown in status line | built (`_meta/usage/live.json` exists); scripts' own steps (godot_run, mutate, checkpoints) not covered | `future-tbd.md:29-31, 26-28`; `L5` still-open | operator |
| 5b | `watch.py` terminal stream | open (approved 2026-11-08, "build next session"; no `_tools/watch.py` present) | `future-tbd.md:26`; `ls _tools` | operator |
| 5c | Live side pane (mod) | open, approved, low priority | `future-tbd.md:26, 34` | Opus (uses `plugin-authoring`); low |
| 6 | Onboarding guide `ONBOARDING.md` | deferred ("not a priority rn"); `ONBOARDING.md` not in repo | `future-tbd.md:37-39` | designer (team name, tips) |
| 7a | Wire one approved Journal entry into Godot `TranslationServer` CSV | scheduled M4; built on the desktop per handoff but not pushed; `grep TranslationServer game` finds nothing here | `future-tbd.md:43-44`, `session-handoff.md:17`, `MILESTONES.md:36` | agent: Patricia (+ William content); verify after the pull |
| 7b | Cap-stop summary in `generate.py` | built, committed on main (`a468036`) | `session-handoff.md:19` | done |
| 8 | `/goal` wrapped around `goal_agent.py` | open; the comparison is written up in GOAL_AGENT.md | `future-tbd.md:49-56` | Opus |
| 9a | Cheaper Clara pass + cached source quotes | open; hard gate on all content runs (see rule 30) | `future-tbd.md:61-63` | Opus (design) then agent Patricia |
| 9b | T2/T5 voice rules as hard checks (`voice_check.py`) | built-unmerged: only on `feat/voice-check` (`ff131dc`), not on main | `git log main..feat/voice-check`; `future-tbd.md:65-66` | operator (merge) |
| 10 | Godot 4.2.1 -> 4.7.2 upgrade | blocked until after final 11/24; one-way, branch | `future-tbd.md:68-78` | designer (go/no-go), Opus (plan), operator (paths) |
| - | Parallel test runs | approved backlog, open | `test-speed-fixes.md:24` | agent: Quinn (+ Rex) |
| - | Fast defaults in `godot_run.py` (code guard for L17) | built-unmerged (branch `fix/cli-args-not-env-prefix` adds flags); "plain speed opt-in" default not confirmed | `L17`, `git show fix/...:_tools/godot_run.py` | operator |
| - | Orchestrator Rex rule as a hook (L21), commit-to-main script (L24) | open ("Still open") | `learnings.md:33, 12` | operator |

### 3b. MILESTONES.md Open (`MILESTONES.md:27-37`) and course items

| Item | Status | Evidence | Owner |
|---|---|---|---|
| M4 / 0.2.x: Flight Endurance, Centrifuge Gearing, Heated Fork, self-driving truck, Journal in Godot | built on desktop, NOT pushed (as of 2026-11-15); whether the truck is in and whether 0.2.0 reached itch is unknown (A7 due 11/18, today) | `session-handoff.md:17` | designer (push/pull); agent: Quinn to verify |
| Upload 0.2.0 to itch | open/unclear | `itch-upload-rule.md:20-22` | designer |
| A7 deliverable 3: pipeline audit and cost analysis (draft in `_meta/drafts/0.2/`) | open; no `_meta/drafts/0.2/` folder exists (only `0.1.4`, `onboarding`, `operator`) | `session-handoff.md:23`, `ls _meta/drafts` | Opus (analysis), operator (draft the tables from `agent-runs.md`) |
| M5 0.3.0: adversarial QA, balance simulation, first-time hint, final itch build (~11/24) | scheduled, not started per memory | `MILESTONES.md:23` | agents: Quinn, Terry; designer for itch |
| Submit A5 link to course | unknown; "the designer's step" | `session-handoff.md:15`, `demo-link-submissions.md` | designer |
| Decision page republish after pull (live page has D200-D218, laptop has D219-D221) | open | `session-handoff.md:13` | operator |
| A4 gate entry in MILESTONES Open | not present in the file | `MILESTONES.md:27-37` | operator (add line, if still the rule) |
| Onboarding deferred; M5 hint is a stopgap | deferred by designer | `MILESTONES.md:37` | designer |

### 3c. `pending-approvals.md`

| Item | Status | Evidence | Owner |
|---|---|---|---|
| `content/onboarding-script.md` approval (after guide revision, GDD §2 harvest flow update) | open, status `draft` | `content/onboarding-script.md:4`, `pending-approvals.md:14-18` | designer, after agent William's revision (blocked by the A4 gate rule 30) |
| `content/biome-intros.md` re-approval (T6 revise) | open, status `draft` | `content/biome-intros.md:4` | same as above |
| Follow-ups: Meadow flower, Glowbell/Skybloom, sweat bee | done (struck out) | `pending-approvals.md:23-25` | prune lines |
| Re-check both against `content/guides.md` | open | `pending-approvals.md:26` | agent: Clara |
| Guides playtest briefs (Gerard, Patricia): drafted, not sent | open, after prototype | `guide-playtest.md:22`, `_meta/drafts/onboarding/guide-playtest-briefs.md` | agent: Gerard, Patricia; designer for 3 questions |

### 3d. README Outstanding TBDs (`README.md:72-117`; 38 unchecked boxes, all `[ ]`)

Grouped, no item is marked done; none was verified as built (README not edited by the loop since). Statuses: open unless noted.

| Group | Items | Owner |
|---|---|---|
| Economy and numbers (`:74-91`) | income side, habitat health values, sale values, automation costs, upgrade-mode UI, **Back button as an arrow (partly built in 0.1.4 per Design Votes round 8; unclear)**, overflow, land, unit tiers, research values, tool bonuses, auto-sell, jar crates, harvest logistics, Long Fork, Jelly prices, Pass prices | agent: Terry (numbers), Gerard (design); designer decides |
| Progression (`:93-99`) | refinery params, synergy thresholds, crystal whitelist and max levels, native species, flower list | agent: Terry |
| Leaderboards (`:101-103`) | crystal tier ranges (~92 at +15%), re-check refinery ladder | agent: Terry |
| Real-world impact (`:105-107`) | donation % per stream, partner agreements | designer + agent: Connie |
| Story (`:109-111`) | final game title, guide character's name | designer |
| Production (`:113-117`) | milestone dates (done in MILESTONES.md: stale box), daily token budget (stale box: second calibration exists, `agent-runs.md:172-186`), test devices, backend provider | operator (tick two stale boxes), designer |

## 4. Cost picture

Source: `agent-runs.md:12-128, 137-139, 188-208`, `cost-rules.md`. All figures are averages x runs I computed from the generated summary; Total processed is not comparable with Final context (`agent-runs.md:7-10`).

| Bucket | Runs | Avg total processed | Approx total | Evidence |
|---|---|---|---|---|
| Orchestrator (main session) | 44 | 16.7M | about 735M | `agent-runs.md:104` |
| Subagent runs (Quinn 30, Rex 40, Bob 29, Patricia 24, Milo 3, general-purpose 9, ...) | 148 | 1.25M | about 185M | `agent-runs.md:83-98` |
| Goal agent (95 calls: Patricia 37, Bob 28, Quinn 30) | 95 | 250k | about 24M (matches the 23.8M in GOAL_AGENT.md per `session-handoff.md:15`) | `agent-runs.md:114-121` |
| Content generation (William, Clara, Critic, Ruth) | 46 | 124k | about 5.7M | `agent-runs.md:59-67` |
| Doc audits (Doris) | 11 | 252k | about 2.8M | `agent-runs.md:69-73` |
| Style loop | 7 | 79k | about 0.6M | `agent-runs.md:106-112` |

Reading: the orchestrator is about 77% of logged tokens (about 735M of about 953M), consistent with the earlier statement that it "is the largest cost by far" (`agent-runs.md:139`) and the 2026-11-03 reading (156.5M, 154.4M of it cache reads over 421 calls, `usage-calibration.md:24-26`). Each orchestrator call re-reads its whole 100k+ context (`agent-runs.md:206`). Quinn is the costliest subagent (3.0M avg in subagent mode; 392k in the goal agent). Rex runs are cheap (121k avg, 40 runs). Caution: orchestrator rows are per session, so an average of 16.7M is session-sized, not call-sized; the 44 x avg is an upper-level estimate.

The 9 approved cuts (`cost-rules.md:11-19`):

| # | Cut | Applied? | Evidence |
|---|---|---|---|
| 1 | `godot_run.py` for suites | applied | `_tools/godot_run.py`; `game/CONTEXT.md:32` |
| 2 | `build.py VERSION --smoke` | applied | `_tools/build.py:2-4` |
| 3 | `mutate.py` + `mutations.json` | applied (880 lines) | `game/tests/mutations.json`; L4 |
| 4 | Tests split one file per area | applied | `game/tests/test_*.gd` (many files) |
| 5 | Briefs name only needed spec sections; fold Clarifications | process rule; cannot verify per brief (unclear); `spec_lint.py` supports it | `game/CONTEXT.md:32` |
| 6 | Number-only questions to a probe script | partly applied: `ui_shots.py`, `model_shots.py`, `pick_match.py`, `compare_page.py` exist; no generic sweep probe script (unclear) | `_tools/` listing |
| 7 | Agent replies at most 150 words | applied in 3 agent definitions (Bob, Patricia, Quinn) only; other agents not checked (unclear for Rex etc.) | `grep "150 words" .claude/agents` |
| 8 | `contact_sheet.py` | applied | `_tools/contact_sheet.py` |
| 9 | Fresh orchestrator session per milestone | process rule; handoff mechanism exists | `session-handoff.md:29` |

Mentioned but not built (cost-related):
- Cheaper Clara pass plus cached facts (A4 item a): open (`future-tbd.md:61-63`). Content runs average only 124k tokens, so this is small against the orchestrator.
- Fast defaults/flags for `godot_run.py` (L17): flags exist only on unmerged branch.
- Parallel test runs: approved, not built (`test-speed-fixes.md:24`).
- Orchestrator-running-scripts and Quinn-running-tests: memory rule only for the orchestrator (L21 "Still open"); Quinn's brief assertion is a test.
- `/goal` outer loop around goal_agent (item 8): not built.
- Model routing for this kind of read-only analysis (cheap Sonnet "operator"): this run is the first attempt.
- Budget numbers: README Production TBD says ~2.0M/day (`README.md:115`), but the second calibration (`agent-runs.md:183-186`) gives about 53-65M/day in total-processed terms. The README line is stale.

## 5. Priority upgrade candidates

Ranked by (a) orchestrator cost cut, (b) what it unblocks before the final (11/24; today 2026-11-18; A7 deliverables due 11/18-19). Evidence is the memory and run log; savings are my estimates, not measurements.

| Rank | Upgrade | (a) Orchestrator cost | (b) Unblocks | Effort / owner |
|---|---|---|---|---|
| 1 | Merge the two unmerged branches (`fix/cli-args-not-env-prefix`, `feat/voice-check`) and make the fast flags the `godot_run.py` default | High: stops 15-minute plain runs and the orchestrator briefing mistakes (L17); cuts the Rex/Quinn waiting turns that each re-read 100k+ context | Fast tests for M5 adversarial QA; voice checks before content runs; A7 engine integration evidence | operator (small); needs the designer's go for the merge |
| 2 | Push/pull the desktop M4 work and rewrite `session-handoff` to real state | Medium: stale handoff forces re-reading and rediscovery each session | A7 deliverables 1 and 2 (due 11/18), 0.2.0 itch, M5 balance sim | designer (push) + operator (handoff) |
| 3 | A7 deliverable 3 draft (pipeline audit and cost analysis) from `agent-runs.md`; table in this file's Section 4 is a start | Low | A7 due ~11/19, directly graded | Opus for the analysis, operator for the tables |
| 4 | Memory dream pass (Section 1): prune/merge about 10 files, shorten `MEMORY.md` | Medium: `MEMORY.md` and all memories load into every session's context (about 70 KB, 33 files) so every orchestrator call re-reads them | Cleaner starts for the last week | operator |
| 5 | A4 grader item (a): cheaper Clara pass plus cached source quotes | Low (content runs are about 124k each) | Lifts the hard gate on content runs; pending approvals (onboarding, biome-intros) are blocked by it | Opus design, Patricia build |
| 6 | Live view: extend `live.json` to script steps (5a remainder), then `watch.py` (5b) | Low-medium: fewer "has it stalled" interruptions (L5) | none before the deadline | operator |
| 7 | Hook-enforce "scripts go to Rex" (L21) and `commit-to-main` script (L24) | Medium over time | none critical | operator |
| 8 | Parallel test runs | Low-medium: only the 6-7 min `all` run | none critical | Quinn/Rex; risky mid-deadline |
| 9 | Episodic memory, transcript sync, `/goal` wrapper, onboarding guide | Unclear / low | not needed for the final | defer |
| 10 | Godot 4.7.2 upgrade | none | explicitly NOT before 11/24 (`future-tbd.md:69`) | defer, designer |

Items clearly needing the designer: push M4 from the desktop, itch upload, course submissions, approvals, merge permission for the two branches, game title and guide name.
