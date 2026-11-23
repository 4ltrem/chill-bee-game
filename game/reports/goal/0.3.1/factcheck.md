---
spec: 0.3.1-playtest-fixes.md
spec_hash: 0660c0be5de3
claims: 21
untrue: 0
unclear: 0
---
# Fact-check: 0.3.1-playtest-fixes.md

Written by `_tools/spec_factcheck.py` (L52). goal_agent builds only when every row is TRUE or NEW and `spec_hash` matches the spec. Fix an UNTRUE claim in the spec and re-run; settle an UNCLEAR one in the spec, or set its verdict to TRUE by hand once checked. Doris: 384,700 tokens, 19 turns.

| # | Verdict | Evidence | Why | Item | Claim |
|---|---|---|---|---|---|
| 1 | NEW |  | Describes the pill and Shop entry after this spec. Today the pill has a `HabitatPlusButton` that opens the Shop (`habitat_pill.gd:24-27`). | 1 | The pill is the number and the wildflower icon only (`UI_DESIGN.md` rule 9 order), and the `ShopButton` is the only control that opens the Shop. |
| 2 | NEW |  | A rule the spec adds, from the designer's "Hide pill at 2nd stop". | 1 | The pill shows on the farm view only: it is hidden in the first zoom and at the second stop (designer, 2026-11-22: "Hide pill at 2nd stop"). |
| 3 | TRUE | `main.gd:711`, `farm_ui.gd:134-144` | At the second stop `fit_top_info` shrinks `TopInfo` to its content and `FarmUI` stays visible. The "+ slid left" effect follows from that and isn't separately shown in code. | 1 | Today `TopInfo` stays at the second stop and shrinks to fit (`farm_ui.gd` `fit_top_info`, 0.1.3c), which made the + slide left; the money and bee count keep that behaviour, only the pill hides. |
| 4 | TRUE | `journal_ui.gd:25-39` | The Journal button is hidden until `habitat_health >= habitat_thriving`, and `habitat_changed` hides it again on reset. The Dev button is named "Reset progress" (`dev_panel.gd:321`); no "Reset habitat" button exists yet. | 1 | It keeps 0.3 item 4's rule: hidden until thriving, hidden again by the Dev "Reset habitat". |
| 5 | TRUE | `patch_slots.gd:80` | The signal is emitted. Nothing in `game/scripts` or `game/scenes` connects it (`farm_ui.gd` only connects `phase_changed`, `thriving` and `habitat_changed`). | 2 | `toast_patch_planted` never showed (`PatchSlots` emits `toast_requested` and nothing connects it). |
| 6 | NEW |  | Describes the new queue behaviour. | 2 | The planting that reaches thriving queues only `toast_bumble_visitor`, not both. |
| 7 | NEW |  | Describes new queue and victory ordering. Today `farm_ui.gd:98-101` only hides a showing bumble toast on reset. | 2 | The victory (0.3 item 5) waits until the bumble toast has finished, then `victory_delay_seconds` as before. "Reset habitat" clears the queue and hides a showing toast. |
| 8 | NEW |  | Describes the new sheet with tabs. | 3 | 3. **The Shop sheet as drawn on the canvas, with tabs.** Supersedes 0.3 item 3's sentence from "With 120 px buttons (V11) the eight rows" through "stay on screen at 720 × 1280." With `shop_layout = 1` (the sheet), the open Shop follows `Shop.dc.html`: the farm dimmed behind (`ShopDim`); a sheet from 168 px below the top of the screen to the bottom, with rounded top corners; a header (`ShopHeader`) with the title "Shop" (`ShopTitle`), the money (`ShopMoney`) and a round Close button (`ShopCloseButton`); a row of five tabs (`ShopTabs`: |
| 9 | NEW |  | A new layout requirement. | 3 | Rows don't overlap each other; every row of the selected tab, the header and the tabs stay on screen at 720 × 1280 (the Hive tab's five rows the most). |
| 10 | NEW |  | Describes the new first-time hint. | 4 | After Play (`play_pressed`, never under the welcome overlay: |
| 11 | NEW |  | A new hint requirement. | 4 | The bubble never covers its own target, stays on screen at 720 × 1280, is 28 px text (V12) with a 120 px Skip target (V11), and sits above the toasts' place so a waiting toast (item 2) and the bubble never overlap. |
| 12 | NEW |  | A new hint requirement. | 4 | While the Shop sheet is open only `hint_plant` shows, and it draws above the sheet and its dim; any other step's bubble waits until the Shop closes. |
| 13 | NEW |  | A build condition on the hint item. | 4 | The text is the only part waiting on content: until `content/first-time-hint.md` is approved, this item is not built. |
| 14 | NEW |  | A contract line for what Patricia builds. | 1 | `journal_ui.gd` finds `JournalButton` under `FarmUI`, keeps the thriving rule, and opens the panel over the farm. |
| 15 | NEW |  | A contract line for what Patricia builds. | 2 | `toast_seconds` from config); the `PatchSlots.toast_requested` connection; the last patch queuing only the bumble toast; the victory waiting for the bumble toast; "Reset habitat" clearing the queue. |
| 16 | NEW |  | A contract line for what Patricia builds. | 3 | `shop_ui.gd` builds the rows into the selected tab (Tree map above), the "Coming soon" line, the remembered tab, the header money, and Close / dim behaviour as 0.2 item 15; compact layout unchanged. |
| 17 | NEW |  | A contract line for what Quinn tests. | 4 | every test run sets `show_hint = false` except the item 4 hint tests; existing tests stay green. |
| 18 | NEW |  | A contract line for new tests. | 1 | item 1: the pill has no Button child; it shows on the farm view and is hidden in the first zoom and at the second stop, while the money still shows at the second stop; nothing but `ShopButton` opens the Shop; before thriving the Journal icon is hidden; after thriving it shows on the farm view, opens the Bumble Bees entry without opening the Shop, and is hidden in both zooms; it clears the `ShopButton`, the skip icon, the hive count and the Harvest, Spin and Sell anchors; stale, updated from this item: |
| 19 | NEW |  | A contract line for new tests. | 2 | item 2: buying a patch with the Shop open shows no toast until Close, then `toast_patch_planted` for `toast_seconds` (± 0.2 s); the last patch shows only `toast_bumble_visitor` after Close, and the victory only after it; the Phase 2 toast still shows; "Reset habitat" empties the queue; |
| 20 | NEW |  | A contract line for new tests. | 3 | Research and Refinery show only the "Coming soon" line; the Shop reopens on the last tab; the header money follows a purchase; at 720 × 1280 no row overlaps another and every row of the selected tab, the header and the tabs are on screen; a tap on the dim strip above the sheet closes it; with `shop_layout = 0` the compact panel still lists all eight rows with no tabs; stale, updated from this item: |
| 21 | NEW |  | A contract line for new tests. | 4 | Skip ends it at any step; "Replay hint" restarts it at the step that fits; the bubble stays on screen at 720 × 1280 and never overlaps a showing toast; |
