---
name: session-handoff
description: "Where work stands (2026-11-21 late, laptop): one branch now (main; milestone branches dropped, origin cleaned); reports renamed to builds/goal/style/votes/variants; spec item 15 (Shop in zoom) written, not built; Godot binary MISSING on the laptop (folder empty) - nothing that runs Godot works until it is re-unpacked; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: cf44f0d9-ea3d-41b5-a628-12e39e761cca
  modified: 2026-11-22T05:04:22.437Z
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
1. Check why `start --refresh` exited 1 despite PASS (one-line look at the log).
2. Build item 15: `python -I _tools/goal_agent.py game/specs/0.2-first-automation.md --goal C15,T15.1` (Patricia, then Quinn; budget guard first: 5-hour was 75% at ~23:50).
3. 0.2.1 version build + itch upload as the A7 link (each needs a yes; A7 was due 11/18-11/19: ask whether it was submitted). Tag it (`v0.2.1`).
4. End-of-day (designer starts it): log decisions (branch model A; naming A/A/A + rename-script exception to edit-lines; item 15 = Shop + Tools; keep-going rule A; item 10 = A; T9.1 paused crank = A; Quinn probe hook = A), `sync_docs.py` (agent-runs totals), rebuild + republish the decision page (D219+ not yet published from the laptop), push `main`.
5. A6 (due 11/22): link = `STYLE_LOOP.md` (approved); its demo folders are now committed but not on origin until the push.

**Still open from before:** content approvals in [[pending-approvals]] (onboarding-script, biome-intros re-approval); proposals awaiting acceptance: `proposals/design/roadmap.md` (Q3 watering, Q5 Connie timing open; re-layer to build-from-start r2) and build-from-start-r2 (accepted, applied from 0.4); 0.3.0 = first UI pass (`UI_DESIGN.md`, ui-screens decisions 2-4; canvas redraw of boards 2-3 for Shop + Tools left for 0.3.0); mutation 25 test (Quinn); `t_icons_never_overlap` weakened to "0 icons at the second stop" (designer to confirm); the side pane (`claude --plugin-dir _tools/live-pane`) untested in a real session; run-5's `sandbox.patch` applied without `jar.tscn`; UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca. Uncommitted and left alone: `_meta/agent-runs.*` (end-of-day), `game/reports/goal/0.2/gaps.json`.

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); the hook also matches script file names inside `git add` (stage those by glob); don't kill the designer's running game; questions in AskUserQuestion with previews ([[ask-with-quiz-tool]]); [[one-folder-rule]] (main only), [[spec-consistency]], [[test-speed-fixes]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
