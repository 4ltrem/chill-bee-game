---
author: orchestrator
type: draft
status: waiting (edit 1 when the live 0.3 goal run stops; edit 2 after 0.3.0, in a 0.3.x spec)
description: The 0.3 placeholder-visuals flag, and the canvas Shop board as a 0.3.x revision item, both approved 2026-11-22
---
# 0.3 spec edits to apply after the run

File: `game/specs/0.3-course-build.md`. Apply with Edit once `_meta/usage/goal-run.lock` is gone, then resume the run with a `--note` naming both edits.

## 1. Placeholder visuals (designer, 2026-11-22: "make all four changes")

In the front matter, after `version: 0.3`, add:

```
visuals: placeholder
```

`goal_agent.py` then keeps the visual numbers a fix round sets, lists them in `game/reports/goal/0.3/placeholders.md` for the play-test, and doesn't stop for a Design Votes row.

## 2. Shop follows the canvas board as drawn: a 0.3.x revision, NOT the 0.3 spec (designer, 2026-11-22: "Board as drawn"; "now this would be a 0.3.X revision")

Don't edit `0.3-course-build.md` for this. 0.3.0 keeps item 2 as written (full-height sheet). After 0.3.0, this goes in the next 0.3 revision: one above the newest 0.3 build when it's written (`config/version` in `game/project.godot` and `game/reports/builds/`). On 2026-11-22 that is 0.3.1, since 0.3.0 is still being built (designer: "x to be whatever number round of revisions we're at now"). If that revision's spec already exists, add it as an item there; if not, it opens `game/specs/0.3.<n>-<name>.md`. Played locally (itch only at a new milestone number). The text below is that item's starting point.

Source: `Shop.dc.html` on the canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca, the same as `proposals/design/ui-screens-mockup/project/Shop.dc.html` (sha256 620ef9ba…, checked 2026-11-22). The board shows: the farm dimmed behind; a sheet from 84 px below the top of a 360 × 640 board (168 px at 720 × 1280) to the bottom, with rounded top corners; a header with "Shop", the money line and a round Close button; a row of category tabs (Bees, Hive, Habitat, Research, Refinery, one selected); then that tab's rows, each with a name, an effect line with its level, and a Buy button (greyed when you can't afford it, a lock when locked).

In the 0.3.x spec, this item supersedes 0.3 item 2's sentence from "With 120 px buttons (V11) the eight rows" through "stay on screen at 720 × 1280.":

> With 120 px buttons (V11) the eight rows and the Journal button don't fit under the top info, so the open Shop follows the canvas board `Shop.dc.html` (designer, 2026-11-22: "Board as drawn"): the farm dimmed behind; a sheet from 168 px below the top of the screen to the bottom; a header with the title, the money and a Close button; category tabs (Bees, Hive, Habitat, Research, Refinery) with the selected tab's rows below. Its Close button and a tap on the dimmed farm return to the farm. Its rows must not overlap each other, and every row of the selected tab and the Journal button stay on screen at 720 × 1280.

Open before applying (decide while editing, or ask the designer):
- Which tab each of the 8 rows sits in (the patch row in Habitat is the obvious one). A tab with no 0.3 rows: hide it, or show it empty?
- The quote "Shop covers the whole screen" stays in the spec history only. The board's top strip is still under the dim overlay, which may be what was meant.
- Tests to update (Quinn): `t_shop_compact_layout_nothing_in_zoom`, `t_shop_no_row_overlaps_other_controls`, `t_shop_rows_order_and_level_text`, `t_bumble_visitor_toast_journal_unlock_twice` (it taps the Shop and expects the Journal button on screen).
