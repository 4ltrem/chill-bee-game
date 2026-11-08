Goal agent run `0.1.4`, fix round 2 for goal C5 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Rerun only the tests you touch (CB_ONLY).

tests:
FAIL    unit      137 passed, 1 failed  (exit 1, 202 noise lines dropped)  game/reports/_runs/20261107-223939/unit.log
    FAIL  t_dev_show_ui_bounds  Show UI bounds off: the outlines are gone: expected 15 got 17  (719 ms)

Spec text:
5. **Bigger hive frames and combs** (designer: "hive frames and combs can be bigger to match the pile size"). The frames and their cells scale up so a cell reads at about the size of a cell in the bucket pile. The rack stays inside the hive body; the first zoom's ≥ 20 px rule and "hive + centrifuge whole" still hold.
   - **Design Votes round 8 (2026-11-07): all three variants rejected.** a: "frame model changed, frames too small"; b: "too small but close"; c: "hex are right size but again frame and hive model changed, unacceptable". The redo keeps the current hive and frame models exactly as they are and changes only sizes: variant c's hex cell size, frames bigger than b's. Milo renders new variants for a new Design Votes section; C5 is built from the pick. Fewer cells per row are allowed (designer, 2026-11-07: "fewer cells are ok"), e.g. Patricia's `grid_cols` 7 → 5 at about 1.35×, so the bigger frames fit the unchanged hive body.
   - **Design Votes round 9 (2026-11-07): variant a** (`game/scenes/variants/hive-frames/hive-frames-a.tscn`: real hive, lid and bars; frames 1.18× wider, 1.17 × 0.63; `grid_cols` 5 × `grid_rows` 2; cell radius 0.14). Note: "closest one, just needs more spacing between hexs, ok if pile hexs are smaller too so they should match the frame hex sizes". So: build a with more gap between cells (smaller cells are fine), and the pile and bucket cells take the same size as the frame cells. b and c (4×2, 3×2): "too empty".

Reply in at most 150 words.