---
name: session-handoff
description: "Where work stands (2026-11-22 evening, laptop): 0.3.0 items 1-6 (welcome, Habitat Health, patches, bumble bee, victory, skip) built 14/14, full suite green; no build yet (export templates missing); A7 + final due 11/29; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: cf44f0d9-ea3d-41b5-a628-12e39e761cca
  modified: 2026-11-23T00:19:15.130Z
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
1. **0.3.0 part 1 DONE 2026-11-22:** spec `game/specs/0.3-course-build.md` items 1-6 (from accepted `proposals/design/course-ending.md` B, `proposals/balance/course-ending-balance.md`, approved `content/course-ending-text.md`; FR house style "vous", Journal = "Carnet des abeilles"). 14/14 goals, checkpoint `e532e62`; full suite green `_runs/20261122-190049/` (unit 221/221 --skip-x1, all windowed suites 0 failed; start's 2 mesh_get_surface_count errors are old noise). Designer layout decisions in the spec: the open Shop is a full-height sheet; Habitat pill beside the money (TopRow); 120 px touch (V11) and 28 px fonts (V12) win; blossom added to STYLE_GUIDE UI tokens; skip icon right edge y 210-330, farm view only. Not pushed.
2. **Open test debt:** mutations `--since 3331fce` were 16/20 before item 6: MISSED "0.3 item 1 the French Play text is wrong", "0.3 item 5 victory ignores the farm view"; BROKEN "0.3 item 1 show_welcome false is ignored" (script error), "0.3 item 1 the Play button shows the raw key" (find occurs twice). Quinn.
3. **Build blocked:** this laptop has no Godot 4.2.1 export templates (`%APPDATA%/Godot/export_templates` empty); the designer installs them (Editor > Manage Export Templates), then Rex `build.py 0.3.0 --smoke`, play-test, tag, push and itch (each a yes).
4. **Designer play-test list (placeholders):** welcome title 64 / outline 8 / Play 40 / gap 48 / dim 0.55; victory heading 64, body 36, button 320x120, column 640; pill flower = flat blossom dot 40; + / skip / Buy / Journal 120 px; Shop labels 28; skip icon position; minutes to victory (Terry: 25, range 20-38). Also item 15 (Shop in zooms) still unplayed.
5. **Next 0.3 work (final 11/29):** the UI pass (ui-screens decisions 2-4 + skin), the first-time hint (A7 2-minute gate), adversarial QA, balance sim, polish. Canvas Shop (`Shop.dc.html`, tabs) is a 0.3.1 item: `_meta/drafts/0.3/spec-edits-after-run.md` edit 2.
6. **A7:** session maigd-6a was drafting the audit in `_meta/drafts/a7/audit.md` (outline first, designer approves); run video = designer records.
7. Goal-agent fixes today: L48 (refresh import each step), L49 (backticked `(designer)`), L50 (re-run mutations; maigd-6a's item_mutations + mutated_tests), L51 (versioned `# goal 0.3 T6.1` marks); test_goal_agent 73/73. Lesson: never checkpoint mid goal step; scene work only reaches Bob when his contract lines name items.

**Still open from before:** content approvals in [[pending-approvals]] (onboarding-script, biome-intros re-approval); proposals awaiting acceptance: `proposals/design/roadmap.md` (Q3 watering, Q5 Connie timing open; re-layer to build-from-start r2) and build-from-start-r2 (accepted, applied from 0.4); 0.3.0 = first UI pass (`UI_DESIGN.md`, ui-screens decisions 2-4; canvas redraw of boards 2-3 for Shop + Tools left for 0.3.0); mutation 25 test (Quinn); `t_icons_never_overlap` weakened to "0 icons at the second stop" (designer to confirm); the side pane (`claude --plugin-dir _tools/live-pane`) untested in a real session; run-5's `sandbox.patch` applied without `jar.tscn`; UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca. Uncommitted and left alone: `_meta/agent-runs.*` (end-of-day), `game/reports/goal/0.2/gaps.json`.

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); the hook also matches script file names inside `git add` (stage those by glob); don't kill the designer's running game; questions in AskUserQuestion with previews ([[ask-with-quiz-tool]]); [[one-folder-rule]] (main only), [[spec-consistency]], [[test-speed-fixes]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
