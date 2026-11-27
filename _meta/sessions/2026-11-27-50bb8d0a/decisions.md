---
session: 50bb8d0a-223e-432f-87fe-9f29f43a67a8
dates: 2026-11-26 to 2026-11-26
transcript: session.jsonl (this folder, gitignored)
description: 11/26 day log: 0.3.2 play-test notes, model_snap.py, spec cut line, 0.3.2 run part-way, A7 write-up and audit refresh
---
# Decisions: session 50bb8d0a (2026-11-26 to 2026-11-26)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

This log covers every session exported on 11/26 (Toronto) that had no log of its own; it was written from the session handoff and the day's commits.

## Decisions

### D307 · 2026-11-26 · Records & deliverables · A7: play link and one-page audit in the README, dollar costs from the transcripts
- Decided: the README top carries the play link, 2-minute steps, the A7 fields and the one-page audit; `PIPELINE.md` holds the A7 write-up; costs are API list prices applied to the transcripts by `_tools/run_cost.py` ($730.25 to 2026-11-26), shown as "USD x (CAD y)" at 1.42.
- Why: A7 asks for actual run costs; the plan is flat-rate, so the transcripts' own token counts are the only real measure.
- Files: `README.md`, `PIPELINE.md`, `_meta/drafts/a7/audit.md`, `_tools/run_cost.py`

### D308 · 2026-11-26 · Game build · Eight play-test notes become 0.3.2 items 10-17
- Decided: the early 0.3.2 play-test adds items 10 (draw the Close X), 11 (gate crank on the lid's visual), 12 (row description and note), 13 (`ForkIcon` in the first zoom), 14 (upgrade icons from `model_snap.py`, no vote for existing models), 15 (fork uncaps under its tines), 16 (`hint_habitat` after the welcome) and 17 (web FPS profile, compression check, branded loading screen); linted and fact-checked clean.
- Why: designer's play-test of the 11/26 Windows build.
- Files: `game/specs/0.3.2-tests-and-quick-buy.md`

### D309 · 2026-11-26 · Pipeline design · model_snap.py: a reusable snapshot script for icons
- Decided: `_tools/model_snap.py` shoots any scene to a square PNG in a dummy scene (farm camera and light), Rex-guarded; five upgrade icons committed, spigot flow as the whole centrifuge (designer's pick).
- Why: item 14 wants icons that match the models without a hand-drawn set.
- Files: `_tools/model_snap.py`, `game/assets/icons/upgrades/`, `_meta/learnings.md` (L58)

### D310 · 2026-11-26 · Game build · Quick-buy shows the effect; spigot widens per level
- Decided: item 18: `QuickBuyName` shows the upgrade's effect (`shop_note_<id>`), the price on `QuickBuyButton` once item 6 removes `QuickBuyPrice`; item 19: `Spigot` widens per Spigot Flow level (`spigot_widen_per_level` 0.1, placeholder) and look-changing upgrades get per-level icons.
- Why: play-test notes; fact-check row #44 was UNTRUE until worded as a change.
- Files: `game/specs/0.3.2-tests-and-quick-buy.md`

### D311 · 2026-11-26 · Cost & structure · Cut line "1-9 + cheap fixes": the rest moves to 0.3.3
- Decided: items 12, 13, 15, 16, 18, 19 and item 17's FPS profile and itch check move to `game/specs/0.3.3-playtest-fixes.md` (same numbers), built after 0.3.2's play-test; 0.3.2 fact-check re-run clean.
- Why: the week was at about 82% with the final due 11/29.
- Files: `game/specs/0.3.2-tests-and-quick-buy.md`, `game/specs/0.3.3-playtest-fixes.md`

### D312 · 2026-11-26 · Game build · Branded web loading screen
- Decided: `game/web/shell.html` (STYLE_GUIDE palette, honey bar on Godot's load progress) is the Web preset's custom HTML shell.
- Why: the 35.6 MB engine wasm makes the first load long (Ruth's brief `research/web-loading-screen.md`).
- Files: `game/web/shell.html`, `research/web-loading-screen.md`

### D313 · 2026-11-26 · Pipeline design · 0.3.2 goals accepted by the designer's quiz
- Decided: C10, C14, C11 and C8 (after hand fixes), C17, T10.1, T11.1, T14.1, C5 and T17.1 accepted; T17.1's export and smoke-shot tests move to 0.3.3 item 17; T2.x built after its tests were added to `run_tests.gd` and corner_detail set to 20 (Godot's max) in code, test, spec and mutation.
- Why: designer's answers at the run's stops.
- Files: `game/reports/goal/0.3.2/blackboard.md`, `_meta/learnings.md` (L59)

### D314 · 2026-11-26 · Cost & structure · With 3% of the week left: commit, audit refresh, end of day; the run waits for the reset
- Decided: the rest of the week goes to refreshing the audit (0.3.2 row: 59 calls, 16M, 270k per call, 8 stops; PDF rebuilt), end of day, and the push; the 0.3.2 run resumes after the 11/28 reset. The $730.25 total stays: re-pricing now gives $717.61 because older transcripts are gone locally.
- Why: the week is at about 97%; the remaining 12 goals cost far more than 3%.
- Files: `_meta/drafts/a7/audit.md`, `_meta/drafts/a7/audit.pdf`

## Still open

- Resume the 0.3.2 run after the 11/28 reset: T3.3-T3.6, T5.1, T6-T9, T1.1, T4.1, incl. T6.2 (`QuickBuyPrice` removal) and items 10, 11, 14 (tile hookup).
- A7 (due 11/29): upload the 0.3.1 web zip to itch and check it plays in a real browser; record the run video and add its link to the README.
- L59: goal_agent should fail a round whose new tests are not in `run_tests.gd` and brief Quinn one T-line at a time (planner job); flaky `t_gear_hidden_under_every_sheet_and_panel_twice`.
- Doris: `UI_DESIGN.md:22` round icons with labels vs rule 6 / V9 / GDD §9 (no word on action icons).
- Whether `UI_DESIGN.md`'s "number and wildflower icon only" Habitat pill rule changes for the 0.3.2 Habitat bar.
- Milo's upgrade-preview vote (2 variants x 3 upgrades: swarm, flight, auto-sell), then the pick.
- L57: goal_agent should stop before a change whose spec text holds a designer **Stop:** (planner job); goal_agent can't close goals by a designer's decision.
- `model_snap.py` re-runs churn `.import` UIDs.
- Roadmap Q3 and the rows 1-16 re-layer; Gerard's watering proposal.
- Play-test placeholders: quick-buy bar, Habitat bar, bubble sizes, minutes to victory (Terry: 25), Close X stroke, loading screen look.
- L52 check 3 (event shots); [[pending-approvals]]; the first `/dream` pass; stale README TBD boxes (ask first).
