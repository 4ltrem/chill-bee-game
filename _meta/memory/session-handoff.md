---
name: session-handoff
description: "Where work stands (2026-11-24 ~02:30): 0.3.2 build part-way (C2-C4, C6, C7 empty tiles, C9 done; C1 by hand); Milo's preview vote next; end-of-day run 11/24; A7 + final due 11/29; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 5c77a6f2-f6b5-4ff0-a169-8eabbf24bafe
  modified: 2026-11-26T20:47:50.962Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**State (2026-11-24 ~02:30, `main`):** `v0.3.1` tagged and pushed. The 0.3.2 goal run (`game/reports/goal/0.3.2/blackboard.md`) built C2 (`6d9704d`), C3 (recorded built, L56), C6 quick-buy (`cd96d5d`), C7 previews (`b0f3a7d`, **empty `PreviewTile`s**: built past the spec's vote STOP, L57), C9 Habitat bar (`0174378`, accepted with the flower centre recoloured to gold for V1), C4 second crank (`8ec9f65`). C1 hint walk: the hang was the walk cranking only one load (helper fixed `50573ed`); Patricia's fix sets `_sold` from a new `truck.sold` signal; the main session changed the stale "still at the second stop" check to follow the state, then `--accept C1` (`e34a4c3`; the walk PASS in `_runs/20261124-025157`). Spec items 8 (no hint said twice), 9 (Habitat bar) and the quick-buy price-label removal were added 11/24 (`c31d17d`, lint and fact-check clean). End of day 11/24 ran (D284-D306, `_meta/sessions/2026-11-24-4825c661/decisions.md`) and committed everything, incl. the other sessions' GDD / style / UI / milestones edits (designer's yes); not pushed.

**NEXT:**
1. **Resume the 0.3.2 run** (budget guard: `python -I _tools/budget_guard.py --allow-for 60`, designer's command; week ~82%, resets 11/28): `python -I _tools/goal_agent.py 0.3.2-tests-and-quick-buy.md` in the background. Left: C8 (hints said twice), C5 adversarial QA, T-lines incl. T6.2 (no `QuickBuyPrice`: C6 stays built, so its red test sends the label removal to a fix round), T7.1, T.1.
2. **Milo's upgrade-preview vote** (designer chose 11/24): 2 variants x 8 upgrades in `game/scenes/variants/preview-<id>-r1/`, `model_shots.py`, `compare_page.py add` section `upgrade-previews`; STOP for the pick; then Bob promotes into `scenes/props/previews/<id>.tscn` and the tiles fill.
3. **A7 (due 11/29), written 2026-11-26, uncommitted:** README top has the play link + 2-minute steps, the A7 fields and the 1-page audit; `audit.md` is final (new §3.7 dollars: $730.25 API-equivalent from `_tools/run_cost.py` over both machines' transcripts; 0.3.1 in §4.1/§4.5/§7.2/§8), `audit.pdf` 33 pages. Left for the designer: upload `game/builds/chill-bee-game-0.3.1-web.zip` to itch (headless smoke only shows the loader spinner, as 0.1.4's did: check it plays in a real browser), record the run video and put its link in the README row "Pipeline run video", then commit + push (README must be on GitHub). `.stignore` in `_meta/sessions/` (uncommitted) keeps Syncthing off git-tracked files.
4. **Final 11/29 leftovers:** UI pass (ui-screens decisions 2-4 + skin), balance sim, polish; placeholders to confirm at the 0.3.2 play-test: quick-buy bar, Habitat bar size and colours, welcome/victory/Settings/hint bubble sizes, minutes to victory (Terry: 25).

**Still open:** L57 (goal_agent ignores a spec item's "**Stop:**"): a planner job; goal_agent can't close goals by a designer's decision; asked the designer whether `UI_DESIGN.md`'s "number and wildflower icon only" pill rule should change for item 9 (no answer yet); L52 check 3 (event shots); [[pending-approvals]]; `proposals/design/roadmap.md` still `proposed`; the side pane untested; first `/dream` pass; stale README TBD boxes (ask first). UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca; Design Votes https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (version 29).

**Lessons from this run:** a spec is locked while `_meta/usage/goal-run.lock` exists (hook): play-test notes go to `_meta/drafts/<version>/` and in when the run stops; reword a spec's wanted change as a change ("today X; after this change Y") or the fact-check calls it UNTRUE; after a hand fix Rex runs only `start` + `unit --only <name> --time-scale 6` ([[test-speed-fixes]]); a test that waits on a centrifuge must crank every reload.

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); stage by glob; questions in AskUserQuestion ([[ask-with-quiz-tool]]); [[one-folder-rule]], [[spec-consistency]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]], [[french-house-style]], [[ui-vote-shots]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
