# 0.1.4: play-test notes to fix later

Designer, 2026-11-08 (after the items 19–21 build, `948a49e`): "note for bugs to fix later". Not started; becomes spec items when picked up.

1. **DONE 2026-11-08 (item 13 rewritten; `FarmUI.on_spin_screen`, checked in `test_crank_pause.gd`).** **Centrifuge text only on the spin screen.** "the centrifuge text stays when backing out when a spin has started, it should apear only on the spin screen". `CentrifugeLabel` ("Honey: x / y" and the crank hint) shows only at the second stop; Back from a started spin hides it.
   - **Conflicts with spec item 13** ("sitting above the centrifuge in every view"): rewrite item 13 in the same edit. Check item 15 (paused crank, Spin shown on the farm) for anything that relies on the label outside the second stop.
**Items 2-3 (designer 2026-11-08: per-view Spin values allowed, pick on Design Votes):** spec item 22; config `spin_farm_visual_px` / `spin_zoom_offset` (defaults 88 / 0 = no change); section "spin-r1" on Design Votes (A 88/0, B 72/40, C 60/80). DONE: the designer picked C for both (60 px, +80 px), set as the defaults.

2. **Spin icon smaller in the farm view.** "the spin icon can be smaller in farm view". Size TBD: a numerical visual change, so it goes to Design Votes with shots ([[ab-comparison-page]] rule).
   - **Spec check:** the 120×120 minimum touch rect (`t_icons_never_overlap`, "touch rect is at least 120 x 120") and item 2 ("the same way in every view") would need an exception for Spin in the farm view.
3. **Spin icon lower in the harvest view.** "lower in harvest view": the first zoom. Offset TBD: Design Votes with shots.
   - **Spec check:** item 2 forbids per-view offsets ("No per-view offsets are allowed"); this needs the designer to allow one for Spin, or an anchor change that lands lower in the first zoom.
