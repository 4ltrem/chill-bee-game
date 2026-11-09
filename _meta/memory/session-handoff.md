---
name: session-handoff
description: "Where work stands (2026-11-08, 22:55): 0.1.4 items 1-22 + later-fix 1 committed (044f59b), unit 178/178; both builds re-exported from 044f59b; waits on the designer's play-test and itch upload; end-of-day not run; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 4ccf1614-06de-4d77-a86f-48a1fbf341b4
  modified: 2026-11-09T04:07:43.231Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** main folder on `milestone/0.1.4`. Last commit `044f59b`. No other worktrees. Uncommitted, left for end-of-day: `_meta/agent-runs.csv/.md`, `ONBOARDING.md`, `game/reports/_look/votes/`, `game/reports/ui-compare/now/`, memory files (this one, `repo-only.md`, `commit-to-main.md`). End-of-day has NOT run for 2026-11-08 ([[end-of-day-routine]]).

**0.1.4 state:** spec items 1-22 built; last commit `044f59b`; unit 178/178 (full run `20261108-222553` reached 177 before the 15-min cap, the cut-off test passed alone in `20261108-224135`). Both builds re-exported from `044f59b` (~22:50). Next test runs: use the fast env vars ([[test-speed-fixes]]).
- Item 19: lowered frames start empty; overflow pours back at the fill rate on top of production (orchestrator default, GDD silent; designer may overrule).
- Item 20 (designer: "Spin moves down"): Harvest holds its lid anchor; Spin yields down by `button_gap_px` (8); Spin's `process_priority` 1; a hidden Harvest (second stop) is not a blocker.
- Item 21: the truck loads waiting jars whenever it is home with room.
- Learnings L15 (raw tabs in mutations.json, now a validity test) and L16 (order-dependent nudge: test both update orders).
- Item 14 (`d8cefc8`): lid back to the voted open pose, closes with no clip; combs fit the frame (`hex_cell_mesh.gd`).
- Item 16: Dev mode saves only edited values to `user://dev_config.json`; the old `dev_config.tres` is ignored (the designer's stale one renamed to `dev_config.old.tres` in `%APPDATA%/Godot/app_userdata/Chill Bee Game/`).
- Item 17: cell hitbox = thin collider (r 0.29, h 0.1 in `honey_cell.tscn`) scaled by `frame_scale` with the mesh.
- Item 18: Dev panel opens on the physical backtick and from `DevButton` (left edge, 8,600, 80x80); the HUD overlap test skips "dev" names, so `t_dev_button_clear_of_hud` checks it.

**Later fixes ALL DONE (2026-11-08 ~22:50):** fix 1 centrifuge text only on the spin screen (`b810f31`); item 22 Spin 60 px in the farm view, +80 px in the first zoom (Design Votes spin-r1: C; `044f59b`); unit 178/178. Both builds re-exported from `044f59b` (exe + `game/builds/chill-bee-game-0.1.4-web.zip`). Old note: Spin smaller in the farm view and lower in the first zoom (both against item 2's rules; sizes/offsets go to Design Votes).

**Waiting on the designer (A5 due 11/15):** play both builds (comb hitbox, Dev button on web), then upload the web zip to itch and submit the A5 link ([[itch-upload-rule]], [[demo-link-submissions]]). Local web check: `python -I _tools/build.py 0.1.4 --serve 8060` via Rex (stop it after; the designer asked for it off).

**Tools changed this session:** budget guard uses average agent cost (`--costs`), heavy line stays 10; `godot_run.py fixture` suite; `build.py --serve`. Reads outside the repo allowed ([[repo-only]]).

**Rules:** all scripts go to Rex ([[rex-runs-scripts]]); don't kill the designer's running game (wait for it to close, then export); [[fix-needs-commit]]; [[look-before-done]]; [[edit-lines-only]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
