# Design Votes, 0.1.4: questions and render plan (draft)

Draft, written while the 0.1.4 goal run was still going (2026-11-07 14:40). Render after the run exits: one round, with every option rendered.
The table below is in the format `compare_page.py add --stop BOARD ROW` reads (`Fix = "A: ...; B: ..."`). Paste it into the goal board's
`## Waiting for the designer` section, or point `--stop` at this file.

## Waiting for the designer

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | C5 frame size | game_config.gd frame_scale, grid_cols; hive body (Bob) | A 2.15x frame is about 1.95 wide against a 1.26 hive body, so the spec's size can't fit | A: frame_scale 1.35 with grid_cols 7 -> 5, the body unchanged; B: frame_scale 2.15 with the hive body widened to about 2.0 (Bob sets the width), grid_cols stays 7; C: keep the current size (frame_scale 1.0) |
| 2 | C2 Harvest nudge | game_config.gd harvest/spin/sell_anchor_offset | Returning from the second stop, Spin's anchor meets Harvest's, so Harvest is nudged 86 px up ("nudged clear", spec item 2) | A: keep the nudge, all offsets 0 (current); B: harvest_anchor_offset -24, so the two anchors don't meet; C: spin_anchor_offset +24, Spin moves down instead |
| 3 | C3 Back at the second stop | Back (576, 16, 120x120), top-right | At the second stop Back covers the hive's visible corner (the 0.1.3 pan puts the hive upper-right) | A: accept the overlap (current); B: Back smaller, 96x96 at (600, 16), still top-right and still the same rect in both views; C: reframe the second stop so the hive sits lower-left of Back |
| 4 | C1 hive count over Harvest | farm_ui.gd count_gap_px (4.0); icon_visual_px 88 in a 120 touch rect | "7/10" sits 4 px above the drawn button but 12 px inside its touch rect; t_hud_no_overlap_no_cutoff fails on that pair | A: label above the full touch rect (Bob's fix, about 16 px higher than now); B: keep it where it is and let the test compare visible shapes for this pair; C: label overlapping the button's top edge on purpose, a badge (count_gap_px -20) |

Notes on the options:
- Row 3, "Back lower" was left out on purpose: spec item 8 puts `HintLabel` below Back, so a lower Back pushes the hint down too. Add it as D if you want to see it.
- Row 2's ±24 px are starting values to see the effect, not tuned. If B or C wins, the value gets its own section of 3 values in the next round (the numeric-change rule).
- Row 4: A and C change `farm_ui.gd` (Patricia's file); B changes only the test (Quinn's).

## Render plan

`ui_shots.py` takes `LABEL=WORKTREE`, so each option is a temporary worktree off `milestone/0.1.4` with the one change in it. Remove the worktrees once the votes are applied ([[one-folder-rule]]).

| Row | Option worktrees | Change in each | Shots used |
|---|---|---|---|
| 1 | c5-a, c5-b | A: `frame_scale = 1.35`, `grid_cols = 5`. B: `frame_scale = 2.15`, and a widened body from Bob (one Bob call) | `3-zoom-hive`, `4-zoom-scraping` |
| 2 | c2-b, c2-c | one offset each | `6-centrifuge-stop`, then the shot after the trip back (`2-farm-hive-full`) |
| 3 | c3-b, c3-c | B: Back's size and position. C: the second-stop camera (Patricia or Bob) | `6-centrifuge-stop` |
| 4 | c1-a, c1-c | A: label y from `_fork.global_position.y`. C: `count_gap_px = -20` | `1-farm-start`, `2-farm-hive-full` |

The reference for every row is the current `milestone/0.1.4` build: `game/reports/ui-compare/0.1.4/` (re-shoot it after the run exits, since the run is still changing code).

Then, as one `add` call:

```
python -I _tools/compare_page.py add PAGE.html OUT.html --h1 "0.1.4 UI placement" \
  --stop BOARD 1 --prefix c5 --option A=<c5-a shots> --option B=<c5-b shots> --ref <ref shots> --shot 3-zoom-hive.png \
  --stop BOARD 2 --prefix c2 ... --stop BOARD 3 --prefix c3 ... --stop BOARD 4 --prefix c1 ... \
  --versions v014 "Before / after: 0.1.3 vs 0.1.4" --version 0.1.3=<0.1.3 sheet> --version 0.1.4=<0.1.4 sheet>
```

Two things to check in `compare_page.py` before running it:
- `stop_section` labels its eyebrow "Style loop · designer stop". These rows come from the goal run, so that label is wrong for them.
- Option C of row 1 is the current build, so it duplicates the reference card. Either drop C and let "ref" be the keep vote, or keep both.

Answers go into the spec, or into the handoff's open questions marked "(answered". Then the goal agent resumes.
