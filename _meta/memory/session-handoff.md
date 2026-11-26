---
name: session-handoff
description: "Where work stands (2026-11-26 evening): 0.3.2 play-test notes added as spec items 10-17 (unlinted, uncommitted); lint + fact-check, then model_snap.py plan, then resume the 0.3.2 run; A7 + final due 11/29; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 5c77a6f2-f6b5-4ff0-a169-8eabbf24bafe
  modified: 2026-11-26T22:10:41.373Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**State (2026-11-24 ~02:30, `main`):** `v0.3.1` tagged and pushed. The 0.3.2 goal run (`game/reports/goal/0.3.2/blackboard.md`) built C2 (`6d9704d`), C3 (recorded built, L56), C6 quick-buy (`cd96d5d`), C7 previews (`b0f3a7d`, **empty `PreviewTile`s**: built past the spec's vote STOP, L57), C9 Habitat bar (`0174378`, accepted with the flower centre recoloured to gold for V1), C4 second crank (`8ec9f65`). C1 hint walk: the hang was the walk cranking only one load (helper fixed `50573ed`); Patricia's fix sets `_sold` from a new `truck.sold` signal; the main session changed the stale "still at the second stop" check to follow the state, then `--accept C1` (`e34a4c3`; the walk PASS in `_runs/20261124-025157`). Spec items 8 (no hint said twice), 9 (Habitat bar) and the quick-buy price-label removal were added 11/24 (`c31d17d`, lint and fact-check clean). End of day 11/24 ran (D284-D306, `_meta/sessions/2026-11-24-4825c661/decisions.md`) and committed everything, incl. the other sessions' GDD / style / UI / milestones edits (designer's yes); not pushed.

**Session 2026-11-26 (designer's early 0.3.2 play-test, Windows build 0.3.2 exported 16:30 from `main`; `project.godot` version bump uncommitted):** eight notes added to `game/specs/0.3.2-tests-and-quick-buy.md` as items 10-17, each with Patricia/Bob contract lines and a Quinn test line, all **uncommitted and not yet linted or fact-checked**:
- 10 Shop/Tools Close showed the "2715" missing-glyph box (`shop_ui.gd:316` sets "✕"): draw the X.
- 11 crank/spin allowed with the lid still off (`close_lid()` sets FULL before the lid lands): gate on the lid's visual.
- 12 each Shop/Tools row gets `RowDesc` + `RowNote` ("+15% hive filling speed", number from config); wording a play-test placeholder (designer: "add to play-test notes").
- 13 `ForkIcon` shows in the first zoom; the fork grows out of it on press and returns into it on every release (supersedes 0.2 item 10's hide-on-release).
- 14 upgrade icons as PNGs from `_tools/model_snap.py` (reusable dummy-scene snapshot script); existing models for fork/gearing/spigot/truck/patch, no vote; changes item 7.
- 15 the fork uncaps under its tines' footprint, not the pointer.
- 16 `hint_habitat` opens the hint walk right after the welcome (why you're here, fill the bar to restore the meadow), honey glow on `HabitatPill`; ends on a bubble tap or `hint_habitat_seconds` (new config, 6).
- 17 web FPS profile by Quinn + itch compression check + custom HTML shell `game/web/shell.html` with a branded loading screen. Ruth's brief `research/web-loading-screen.md` (draft, for the designer's review): the 35.6 MB engine wasm is the likely load cost; slim export template is the bigger later fix (3D can't be disabled).

**NEXT:**
1. **Done 2026-11-26:** items 10-17 linted and fact-checked clean (item 16's timer counts only while the bubble shows; item 7's contract lines cut to the 3 vote previews per item 14; fact-check row #43 set TRUE by the designer), committed.
2. **Plan `model_snap.py`** with the `planner` skill (tooling, item 14) before the run reaches item 14; the plan goes to `_meta/drafts/0.3.2/`.
3. **Resume the 0.3.2 run** (budget guard: `python -I _tools/budget_guard.py --allow-for 60`, designer's command; week ~82%, resets 11/28): `python -I _tools/goal_agent.py 0.3.2-tests-and-quick-buy.md` in the background. Left: C8 (hints said twice), C5 adversarial QA, T-lines incl. T6.2 (no `QuickBuyPrice`: C6 stays built, so its red test sends the label removal to a fix round), T7.1, T.1, and items 10-17. Item 13's `ForkIcon` place and item 16's hint order touch the existing hint-walk test.
4. **Milo's upgrade-preview vote** (designer chose 11/24): 2 variants x 3 upgrades (swarm, flight, auto-sell; the other five use existing models, spec item 14) in `game/scenes/variants/preview-<id>-r1/`, `model_shots.py`, `compare_page.py add` section `upgrade-previews`; STOP for the pick; then Bob promotes into `scenes/props/previews/<id>.tscn` and the tiles fill.
5. **A7 (due 11/29), written 2026-11-26, uncommitted:** README top has the play link + 2-minute steps, the A7 fields and the 1-page audit; `audit.md` is final (new §3.7 dollars: $730.25 API-equivalent from `_tools/run_cost.py` over both machines' transcripts; 0.3.1 in §4.1/§4.5/§7.2/§8), `audit.pdf` 33 pages. Left for the designer: upload `game/builds/chill-bee-game-0.3.1-web.zip` to itch (headless smoke only shows the loader spinner, as 0.1.4's did: check it plays in a real browser), record the run video and put its link in the README row "Pipeline run video", then commit + push (README must be on GitHub). `.stignore` in `_meta/sessions/` (uncommitted) keeps Syncthing off git-tracked files.
6. **Final 11/29 leftovers:** UI pass (ui-screens decisions 2-4 + skin), balance sim, polish; placeholders to confirm at the 0.3.2 play-test: quick-buy bar, Habitat bar size and colours, welcome/victory/Settings/hint bubble sizes, minutes to victory (Terry: 25), the Close X stroke, row description/note wording + FR, `ForkIcon`'s first-zoom place, `hint_habitat` wording, the loading screen's look.

**Still open:** L57 (goal_agent ignores a spec item's "**Stop:**"): a planner job; goal_agent can't close goals by a designer's decision; asked the designer whether `UI_DESIGN.md`'s "number and wildflower icon only" pill rule should change for item 9 (no answer yet); L52 check 3 (event shots); [[pending-approvals]]; `proposals/design/roadmap.md` still `proposed`; the side pane untested; first `/dream` pass; stale README TBD boxes (ask first). UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca; Design Votes https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (version 29).

**Lessons from this run:** a spec is locked while `_meta/usage/goal-run.lock` exists (hook): play-test notes go to `_meta/drafts/<version>/` and in when the run stops; reword a spec's wanted change as a change ("today X; after this change Y") or the fact-check calls it UNTRUE; after a hand fix Rex runs only `start` + `unit --only <name> --time-scale 6` ([[test-speed-fixes]]); a test that waits on a centrifuge must crank every reload.

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); stage by glob; questions in AskUserQuestion ([[ask-with-quiz-tool]]); [[one-folder-rule]], [[spec-consistency]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]], [[french-house-style]], [[ui-vote-shots]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
