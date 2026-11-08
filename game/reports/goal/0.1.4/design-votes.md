# Design Votes, 0.1.4: the questions as rendered

Built from `_meta/drafts/0.1.4/design-votes-0.1.4.md`, with each row's options cut down to what is rendered (`game/reports/ui-compare/vote-*`, `game/reports/variants/hive-frames/`). `compare_page.py add --stop` reads the table below. Row 1 (C5 frame size) is a variants section on the page (Milo's hive-frames a/b/c), so it isn't in this table.

## Waiting for the designer

| # | Rule | Where | Finding | Fix |
|---|---|---|---|---|
| 2 | C2 button anchors | game_config.gd harvest/spin/sell_anchor_offset | Coming back from the second stop, Spin's anchor meets Harvest's and Harvest is nudged 86 px up. The shot shows where the offset puts Harvest over the hive (the nudge itself happens on the way back, which no moment captures yet) | A: all three anchor offsets -40 (buttons 40 px higher above their props); B: all three anchor offsets +40 (40 px lower, closer to the props) |
| 3 | C3 Back at the second stop | Back (576, 16, 120x120), top-right | At the second stop, Back covers the hive's visible corner | A: Back smaller, 96x96, still top-right; B: Back lower, 120x120 moved 40 px down (pushes the item 8 hint down too). Reframing the second stop isn't rendered: ask for it in a note |
| 4 | C1 hive count over Harvest | farm_ui.gd count_gap_px (4) | "7/10" sits 4 px above the drawn button but 12 px inside its 120 px touch rect, so t_hud_no_overlap_no_cutoff fails on that pair | A: count_gap_px -12 (closer to the button: a badge-like look); B: count_gap_px 12 (label clear of the full touch rect, the test passes as is) |
| 5 | pan_zoom_size at the second stop | game_config.gd pan_zoom_size (9.30) | The game warns 9.30 is 0.24 short of what the second stop needs to fit (since 0.1.3c) | A: pan_zoom_size 9.54 (what the warning asks for) |
