Goal agent run `0.1.4`, fix round 1 for goal C5 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: scripts/

tests:
FAIL    unit      131 passed, 7 failed  (exit 1, 202 noise lines dropped)  game/reports/_runs/20261107-221540/unit.log
    FAIL  t_config_values  default 'grid_cols': expected 7 (+-0.001) got 5 | default 'grid_rows': expected 5 (+-0.001) got 2 | 35 cells per frame: expected 35 got 10  (1 ms)
    FAIL  t_leftover_adds_no_turns  batch 1 left a fractional carry (0.0000 jars) | the carry still counts in the bottled floor(jars): 30 cells + carry = 2.69 jars, floor 2: expected [2] got [1]  (543 ms)
    FAIL  t_back_keeps_half_frame  half a frame scraped: 0 of 10 cells still Capped | the half frame is still up (not done): expected 0 got 1 | the half frame is the next to harvest: expected 0 got 1 | the half frame rises first on the return: 
    FAIL  t_scrape_then_back_in_pop_window_bucket  cell 17 has a collider with its cell_index  (1044 ms)
    FAIL  t_scrape_then_back_in_pop_window_pile  cell 17 has a collider with its cell_index  (1050 ms)
    FAIL  t_dev_show_ui_bounds  Show UI bounds off: the outlines are gone: expected 15 got 17  (646 ms)
    FAIL  t_heap_shows_every_cell  after frame 4 every heap cell lies inside the glass (radius 0.64, y 0.10 to 0.99): expected 0 got 5 | after frame 5 every heap cell lies inside the glass (radius 0.64, y 0.10 to 0.99): expected 0 got 5  (707 m

Spec text:
5. **Bigger hive frames and combs** (designer: "hive frames and combs can be bigger to match the pile size"). The frames and their cells scale up so a cell reads at about the size of a cell in the bucket pile. The rack stays inside the hive body; the first zoom's ≥ 20 px rule and "hive + centrifuge whole" still hold.
   - **Design Votes round 8 (2026-11-07): all three variants rejected.** a: "frame model changed, frames too small"; b: "too small but close"; c: "hex are right size but again frame and hive model changed, unacceptable". The redo keeps the current hive and frame models exactly as they are and changes only sizes: variant c's hex cell size, frames bigger than b's. Milo renders new variants for a new Design Votes section; C5 is built from the pick. Fewer cells per row are allowed (designer, 2026-11-07: "fewer cells are ok"), e.g. Patricia's `grid_cols` 7 → 5 at about 1.35×, so the bigger frames fit the unchanged hive body.
   - **Design Votes round 9 (2026-11-07): variant a** (`game/scenes/variants/hive-frames/hive-frames-a.tscn`: real hive, lid and bars; frames 1.18× wider, 1.17 × 0.63; `grid_cols` 5 × `grid_rows` 2; cell radius 0.14). Note: "closest one, just needs more spacing between hexs, ok if pile hexs are smaller too so they should match the frame hex sizes". So: build a with more gap between cells (smaller cells are fine), and the pile and bucket cells take the same size as the frame cells. b and c (4×2, 3×2): "too empty".

Reply in at most 150 words.