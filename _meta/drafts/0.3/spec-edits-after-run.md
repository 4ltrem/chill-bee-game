---
author: orchestrator
type: draft
status: applied (edit 1 in the 0.3 spec; edits 2-4 opened as game/specs/0.3.1-playtest-fixes.md items 3, 1, 2 on 2026-11-22; the spec is the source now)
description: The 0.3 placeholder-visuals flag, the canvas Shop board, and the one-Shop-button + Journal icon play-test fix as 0.3.1 items, approved 2026-11-22
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

Decided (designer, 2026-11-22 quiz): rows follow the GDD §3 trees (designer: "nothing for refinery yet look in the gdd for where to put the upgrades"): **Bees** (Tree A) = Swarm, Flight Endurance; **Hive** (Tree B: Hive & Tool Efficiency) = Heated Fork, Centrifuge Gearing, Spigot Flow, Faster Delivery, Auto-Sell; **Habitat** (Tree C) = Plant wildflower patch; **Research** and **Refinery** = no rows yet. A tab with no rows still shows, and selecting it shows one greyed "Coming soon" line (key `shop_coming_soon`, fr "Bientôt disponible").

Still open:
- The quote "Shop covers the whole screen" stays in the spec history only. The board's top strip is still under the dim overlay, which may be what was meant.
- Tests to update (Quinn): `t_shop_compact_layout_nothing_in_zoom`, `t_shop_no_row_overlaps_other_controls`, `t_shop_rows_order_and_level_text`, `t_bumble_visitor_toast_journal_unlock_twice` (it taps the Shop and expects the Journal button on screen).
- Edit 3 moves the Journal button out of the Shop: drop "and the Journal button" from the quote above when both land.

## 3. One way into the Shop; the Journal gets its own icon: 0.3.1 (designer play-test of 0.3.0, 2026-11-22)

Same home as edit 2: an item in the 0.3.1 spec, not `0.3-course-build.md` (designer: "add to 0.3.1 spec"). The text below is that item's starting point.

> **One way into the Shop; the Journal gets its own icon** (designer play-test of 0.3.0, 2026-11-22: "there's a shop button and a + button, and the + button moves in the zoom spin view, the journal is only accessible through the shop screen. we only need the shop button"; then picked "Own bee icon"). Supersedes 0.3 item 2's "then **+**, which opens the Shop" and "its 120 px + button (V11)", and item 3's "the Journal button" in the open Shop. The Habitat pill loses its **+** (`HabitatPlusButton` is deleted from `main.tscn`; `habitat_pill.gd` no longer looks for it): the pill is the number and the wildflower icon only, and the Shop button is the only control that opens the Shop. The pill, like the rest of `TopInfo`, never shows in the first zoom or at the second stop. The `JournalButton` leaves the Shop sheet and becomes a farm-view icon (`UI_DESIGN.md` rules 2, 3, 6): a 120 × 120 button (V11) labelled through `tr()` (key `journal_icon`, en "Journal", fr "Carnet"; the bee shape comes with the UI pass), bottom-right directly above the Shop button with a 16 px gap, under `FarmUI` so it hides in both zooms. It keeps 0.3 item 4's rule (hidden until thriving, hidden again by "Reset habitat") and opens the same Journal panel over the farm; Close returns to the farm. It clears the Shop button, the skip icon, the hive count and the Harvest, Spin and Sell anchors. Size and position are placeholders the designer confirms at play-test.

Contract lines for that spec:
- Patricia: `habitat_pill.gd` without the + (`_on_plus` removed); `journal_ui.gd` places the Journal icon and hides it outside the farm view; the `journal_icon` row in `game/translations/`.
- Bob: delete `HabitatPlusButton`; move `JournalButton` from `ShopPanel/ShopBox` to `FarmUI`.
- Quinn: the pill has no Button child and does not show in either zoom; nothing but `ShopButton` opens the Shop; before thriving the Journal icon is hidden, after it the icon shows on the farm view, opens the Bumble Bees entry without opening the Shop, and is hidden in both zooms; it clears the controls named above. Stale tests: `test_habitat.gd` (reads `HabitatPlusButton`), `test_journal.gd`, `test_shop.gd` (counts `JournalButton` in the sheet's overlap check), `t_bumble_visitor_toast_journal_unlock_twice`. Mutation: the Journal icon showing in the zoom.

## 4. Toasts wait for the Shop to close; the patch toast shows: 0.3.1 (designer play-test of 0.3.0, 2026-11-22)

Found from the designer's "I noticed a message after I bought all the upgrades but it vanished before I could read it": the thriving toast `toast_bumble_visitor` (`farm_ui.gd` `_on_thriving`, `PHASE_TOAST_SECONDS` 4.0) shows under the full-height Shop sheet's dim, since the last patch is bought inside the Shop, and hides before the Shop closes. Also `toast_patch_planted` is never shown: `patch_slots.gd` emits `toast_requested` and nothing connects it (no test caught it).

> **Toasts wait for the Shop to close** (designer, 2026-11-22 quiz: "Wait for Shop close"; "Show it, same queue"). Toasts (`PhaseToast`) go through one queue in `farm_ui.gd`: while the Shop sheet or the Journal panel is open, or a zoom is up, a toast waits; it shows on the farm view once they close, for `toast_seconds` (config, 4.0, replacing `PHASE_TOAST_SECONDS`), one at a time in order. `toast_patch_planted` is wired to the queue (from `PatchSlots.toast_requested`); the planting that reaches thriving queues only `toast_bumble_visitor`, not both. The victory screen's queue (0.3 item 5) waits until the bumble toast has finished. A Dev reset clears the queue.

Contract lines: Patricia: the queue, the `toast_requested` connection, `toast_seconds` in config and the Dev panel, the victory waiting for the toast. Quinn: buying a patch with the Shop open shows no toast until Close, then `toast_patch_planted` for `toast_seconds` (± 0.2 s); the last patch shows only the bumble toast after Close and the victory after it; the Phase-2 toast still shows. Mutations: the toast showing while the Shop is open; `toast_requested` not connected.
