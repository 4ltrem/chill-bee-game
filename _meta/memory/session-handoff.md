---
name: session-handoff
description: "Where work stands (2026-11-22, laptop): item 15 built and accepted, full suite green; A6 submitted; A7 and final both due 11/29 (run video, >20-page audit, 2-minute playable gate); start-suite exit 1 = 'no total line'; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: cf44f0d9-ea3d-41b5-a628-12e39e761cca
  modified: 2026-11-22T16:20:17.960Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Godot loss, resolved (L45):** Oscar's `git worktree remove --force .claude/worktrees/m02-play` (2026-11-21 23:19) followed that worktree's Godot junction and emptied the repo's Godot folder. The designer re-unpacked it (2026-11-22); Rex: `start --refresh` printed PASS but exited 1 (`game/reports/_runs/20261122-000040/start.log`, unchecked), then `ui_shots.py 0.2.1=.` wrote 12 shots + sheet to `builds/0.2.1/ui/` (new naming proven). Guard rule 8 (link-delete, `5ce4cc6`) now refuses a recursive delete of a folder holding a junction.

**Done this session (Opus, 2026-11-21 late), all on `main`:**
- **Branch model = A (designer):** work on `main` only; `checkpoint.py` and goal_agent commit on the current branch (refuse only a detached HEAD); `commit_main.py` retired; end-of-day tags shipped states (`v0.2.1`, `a6-demo`) with a yes and pushes only a green main. `d3b3b5c`. Local and origin `milestone/0.2` deleted; origin `main` = `d3b3b5c` (pushed with the designer's yes). Later commits NOT pushed.
- **Naming restructure (designer: target A, content A, history A, rename script A):** scripts `eb50160`; history move + path rewrite `02e0e6d` (one commit: the gate's link check blocks a move-only commit). `game/reports/` = `builds/<v>/` (report.md, shots, logs, ui, round-N), `goal/<v>/` (runs/<date>-<n>.log, pick/<id>/round-N), `style/<version>-<scene>/run-N/round-N/`, `votes/<vote-id>/<option>/`, `variants/<prop>/round-N|pick-match/`, `_runs/`. `content/_runs/<slug>/run-N/`. Rules in `game/CONTEXT.md` and `content/CONTEXT.md`. Tool: `_tools/rename_paths.py` + `_meta/drafts/naming/moves.tsv`. The A6 demo folders (`style/0.2.0-farm/run-1..5`, `content/_runs/biome-intros/run-3`) were untracked and are now committed. NOT verified: one real `ui_shots.py` run writing to `builds/0.2.1/ui/` (blocked by Godot; the folder exists, empty).
- **Operator item 23 + learnings:** scan takes each test's newest result across `--only` logs (`unit_results`, L44); L43 = Bob's style-loop regressions. `aa5618e`. Items 7, 8, 11, 12 were already applied (L40); item 7's tail (do `run_tests.gd` and the windowed suites read `--set` overrides? only `ui_compare_shots.gd` does) and item 23's plan-count part (C14, CFG, T.1 not listed) stay open.
- **Spec item 15, Shop in both zooms:** in `game/specs/0.2-first-automation.md` (goals C15, T15.1; lint clean; supersedes 0.1-harvest items 3/8). `3b3d524`. Code facts for Patricia's brief: `_meta/drafts/0.2/item-15-shop-in-zoom.md`.
- Tests at the end: test_generate 91/91, test_goal_agent 64/64, consistency clean, links 0 broken.

**NEXT:**
1. Operator cleanup DONE 2026-11-22 (pre-feature round): `start` "exit 1" was Godot's code in the summary, not godot_run's (it exits 0); the line now says "0 errors (godot exit 1 (1 is normal here))". L47 prevention (DIAG_RULE, checkpoint label from newest runs), scan counts code-built nodes and "replaces" as removed (0.2 = 36/36), `run_tests.gd` reads `--set` (windowed suites still don't). Verified by Rex `_runs/20261122-111955/`.
2. Item 15 DONE 2026-11-22: C15 `daf2d7c`, test fixes `f42034a`/`7616d20` (orchestrator diag: stray main, CLOSE_DELAY, other frames emptied), C15/T15.1 accepted `9aadc61`; full suite green `_runs/20261122-011146/`. 0.2 spec: 36/36 except C14 still "partial" in the scan. Not pushed. Not yet play-tested by the designer.
3. 0.2.1 version build + itch upload as the A7 link (each needs a yes; A7 is due 11/29 with a run video and a >20-page audit, brief in MILESTONES.md Open; A6 submitted 11/22). Tag it (`v0.2.1`).
4. Designer play-tests item 15 (Shop in first zoom and second stop, buy, leave with the sheet open).
5. A7 plan (final also 11/29): 2-minute stranger gate (first-time hint?), run video (designer records), >20-page audit. End of day 11/22 logged D256-D260; L47 prevention open.

**Still open from before:** content approvals in [[pending-approvals]] (onboarding-script, biome-intros re-approval); proposals awaiting acceptance: `proposals/design/roadmap.md` (Q3 watering, Q5 Connie timing open; re-layer to build-from-start r2) and build-from-start-r2 (accepted, applied from 0.4); 0.3.0 = first UI pass (`UI_DESIGN.md`, ui-screens decisions 2-4; canvas redraw of boards 2-3 for Shop + Tools left for 0.3.0); mutation 25 test (Quinn); `t_icons_never_overlap` weakened to "0 icons at the second stop" (designer to confirm); the side pane (`claude --plugin-dir _tools/live-pane`) untested in a real session; run-5's `sandbox.patch` applied without `jar.tscn`; UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca. Uncommitted and left alone: `_meta/agent-runs.*` (end-of-day), `game/reports/goal/0.2/gaps.json`.

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); the hook also matches script file names inside `git add` (stage those by glob); don't kill the designer's running game; questions in AskUserQuestion with previews ([[ask-with-quiz-tool]]); [[one-folder-rule]] (main only), [[spec-consistency]], [[test-speed-fixes]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
