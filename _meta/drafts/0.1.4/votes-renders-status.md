# Design Votes 0.1.4: what is rendered (draft, 2026-11-07 17:30)

Status of the renders for `design-votes-0.1.4.md` (the plan beside this file). Nothing is published yet. The page update is the next step.

## How the options were rendered

These were rendered without worktrees. `ui_compare_shots.gd` gained an override hook, and `ui_shots.py` gained `--set` (both uncommitted, in the working tree on `milestone/0.1.4`):

- After the label, `key=value` sets a config value before the scene loads, for example `grid_cols=5`.
- `Node.prop=value` or `Node.prop*=value` sets a property on the first node with that name after it loads. This mocks a scene change, for the vote only.
- `shots.json` records the overrides under `"overrides"`.
- Each run takes about 30 s: `python -I _tools/ui_shots.py LABEL=<repo root> --set ...`.
- Limit: a mock can't change what a script rebuilds. `FrameSlots`/`FrameBars` scale, but the comb cells don't, so C5 was rendered as Milo's colorbox variants instead.

## Rendered, in `game/reports/ui-compare/`

| Folder | Overrides | For plan row |
|---|---|---|
| `vote-base/` | none: the current `milestone/0.1.4` build, re-shot after the run exited | reference for every row |
| `vote-anchor-up40/`, `vote-anchor-down40/` | `harvest/spin/sell_anchor_offset` = −40 / +40 | row 2, but not B and C as planned (those offset one button each by ±24) |
| `vote-back-small/` | `BackButton.custom_minimum_size=Vector2(96,96)`, `offset_left=-120`, `offset_bottom=112` | row 3 B |
| `vote-back-lower/` | `BackButton.offset_top=56`, `offset_bottom=176` | row 3, the "Back lower" the plan left out on purpose (a lower Back pushes the item 8 hint down). Drop it, or show it as D |
| `vote-count-gap0/` | `FarmUI.count_gap_px=-12` (named gap0, but it is the 12 px overlap) | row 4, close to C (the plan says −20) |
| `vote-count-gap12/` | `FarmUI.count_gap_px=12` | row 4, roughly A (the label above the full touch rect) |
| `vote-pan-954/` | `pan_zoom_size=9.54` | not in the plan: the game warns that 9.30 is 0.24 short for the second stop (since 0.1.3c). A new row 5 |
| `0.1.3-before/` | none: `milestone/0.1` shot in a throwaway worktree (since removed) | the before/after versions section |

`game/reports/variants/hive-frames/`: Milo's colorbox hives, rendered by `model_shots.py hive-frames`, all `style_check` PASS. **a** is today (0.13 cells, 7 columns). **b** is 1.35× (0.175, 5 columns, same body). **c** is pile size (0.28 cells, body 2.2 wide). Each has a loose 0.28 pile cell beside it for scale, and each shot is zoomed to fit its own hive. Milo's flag: the frames stand above the 0.68 walls in all three. These are row 1 (C5 A, B and the current size).

Spot-checked by eye: `vote-back-lower` shot 3 (Back moved down) and `vote-count-gap12` shot 2 (the gap shows). The rest are not looked at yet.

## Still to do for the round

1. Row 2: render the plan's B (`harvest_anchor_offset=-24`) and C (`spin_anchor_offset=24`), or replace them with the ±40 renders. Today's moments have no shot of the way back from the second stop, where the nudge happens, so it may need a new moment in `ui_compare_shots.gd` (Bob, per the designer's rule).
2. Row 3 C (reframe the second stop) needs a camera change. It isn't rendered.
3. Row 4: render −20 if C stays at −20.
4. Decide on the plan's two `compare_page.py` checks: the "Style loop" eyebrow on `--stop` sections, and C duplicating the reference.
5. Build the page and publish it to the one Design Votes artifact (https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa). Read it first: the live version starts at Round 7, the same as `game/reports/ui-compare/design-votes.html`.
6. Commit the override hook and `--set`, with a line in the `ui_shots.py` docstring (done) and `_tools/CONTEXT.md` if needed.
