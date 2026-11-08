---
name: session-handoff
description: "Where work stands (2026-11-08, late evening): lid votes read (before open pose, no end clip); Patricia/Bob lid+comb brief waiting for the 5-hour reset; fix-round edits still uncommitted; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 472fd463-d58d-41f5-abb3-fb73c957a854
  modified: 2026-11-08T23:22:52.597Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** terminal `claude` CLI; main folder on `milestone/0.1.4`, no worktrees. Last commit `b9f9347`. End-of-day has NOT run for 2026-11-08 afternoon/evening.

**Next step (designer: "wait until after the reset", 5-hour usage was 66%):** brief Patricia, then Bob (sequentially, not in parallel), on item 14:
- Lid: go back to the committed (HEAD) open pose, leaning on the left side, NOT the fix rounds' upright-behind-the-hive pose (`HiveLidSpot` at -0.7, 0.68, 110°). Either close motion is fine. Change only the end: the lid lands flat on the hive, no wall clip (HEAD: 1.7 cm into WallXNeg/ZPos/ZNeg at 100%) and no touch on the comb tops (fix rounds: 0.5 cm at 100%). Votes: `game/reports/_look/lid-close-r1-votes.json`.
- Combs: KEEP the fix-round comb size (designer: "the comb size looks good"): `honey_cell.tscn` radius 0.34 + 30° yaw, `honeycomb.gd` CELL_YAW and pitch 1.85, `hive_comb_view.gd` yaw line. Still to fix: cells overshoot the standing frame's top bar; uncapped (bright) cells render on the open lid's face while scraping (`game/reports/ui-compare/now/4-zoom-scraping.png`).
- Regression: `t_icons_above_props` (ForkIcon within 40 px of hive centre in the first zoom).
- After: Rex runs `godot_run.py unit` and `godot_run.py lid`; compare shots before "done" ([[look-before-done]]).

**Uncommitted:** the fix-round edits (`honeycomb.gd`, `hive_comb_view.gd`, `lid_motion.gd`, `hive.tscn`, `honey_cell.tscn`), Quinn's tests (`test_hive_model.gd`, `test_lid_clip.gd`, `lid_shots.gd`, `run_tests.gd`, `mutations.json`, `test_combs.gd`), goal blackboard files; plus tonight's tooling: `_tools/godot_run.py` new `lid` shot suite (by name only, not in `all`; Rex-verified PASS, test_generate 59/59), `_tools/compare_page.py` vote ids slugified (spaces/% made the db drop votes). Last unit run (17:06): 151 passed, 6 failed (3 lid open-pose tests, 2 comb overshoot, ForkIcon).

**Shots:** `game/reports/_look/lid-before/` (HEAD) and `lid-now/` (fix rounds), contact sheets `before-close.png` / `now-close.png`; Design Votes section "Lid close: before or after?" (version 15).

**Open tooling issues:** turn cap inconsistent (Bob fix 1 ran 20 turns under `--max-turns 15`; compare fix-1-bob vs fix-3-bob transcripts in `_meta/sessions/runs/2026-11-08-goal-0.1.4/`); fix rounds should go to one owner per failure. Approved, not built: `live.json` + `_tools/watch.py`; Quinn's interaction checklist; `mutate.py --since`; web smoke real-time wait; `checkpoint.py`.

**A5 (due 11/15):** the `720d42d` exe/web zip exist; web smoke shot was black, so the designer browser-checks before the itch upload ([[itch-upload-rule]], [[course-milestones]]).

**Rules:** all scripts incl. shot follow-ups go to Rex ([[rex-runs-scripts]]); [[fix-needs-commit]]; [[prefer-bash]]; [[edit-lines-only]] (no in-place sed); Bash paths repo-relative (the repo-only hook refuses absolute repo paths and `cd`).

**How to apply:** keep CLI replies short and long material in files ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
