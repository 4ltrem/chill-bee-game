# Draft: 0.2.x spec item 15, Shop in both zooms

Status: applied (2026-11-21): item 15 is in `game/specs/0.2-first-automation.md` (goals C15, T15.1; lint clean), with a Patricia line and a test line. Not built yet. The code facts below are for Patricia's brief.

Source:
- Designer, 2026-11-21, on the shop-layout vote: "the shop button should be available while zoomed in still so the player can upgrade at any time".
- Then the designer picked "Shop + Tools" over the UI proposal's Tools-only zooms (`UI_DESIGN.md` row 3; `proposals/design/ui-screens.md` decision 4).
- The look of the current shop doesn't matter: 0.3.0's design replaces it.

## Proposed item text

15. **Shop stays available in both zooms** (designer, 2026-11-21: "the shop button should be available while zoomed in still so the player can upgrade at any time").
    - The Shop button (`shop_layout = 1`, the sheet) shows in the first zoom and at the second stop, in the same bottom-right place as on the farm. Back (top-right), the hint and Spin are not moved.
    - Opening it opens the same sheet over the dimmed zoom. Close, or a tap on the dim, returns to the zoom exactly as it was.
    - A purchase takes effect the next time the value is read, the same as on the farm:
      - Heated Fork: the reach grows on the next drag.
      - Gearing: fewer turns are left on the crank in progress.
      - Spigot Flow: the jar now filling speeds up.
      - Faster Delivery and Auto-Sell: they apply to the next truck trip.
    - While the sheet is open, the zoom takes no fork or crank input. Anything automatic keeps going (cells in flight, loads, pours, the truck).
    - Leaving the zoom while the sheet is open closes the sheet. This can happen when the zoom ends on its own, for example when no frame is left.
    - Placement on the second stop must clear Spin and the hive count; Quinn's HUD tests cover it.
    - With `shop_layout = 0` (compact panel), nothing changes in the zoom: the panel stays farm-only.
    - A stopgap like item 14: 0.3.0 adds the Tools icon beside it.

## Code facts (read 2026-11-21, for Patricia's brief)

- **The button and the sheet are both hidden in the zoom today.**
  - `ShopPanel` sits under `FarmUIRoot/FarmUI/Margin/Column` (`main.tscn:324`).
  - `ShopButton` is added as a child of FarmUI (`shop_ui.gd:165`).
  - `main.gd:270` sets `_farm_ui.visible = false` when the zoom opens, and `main.gd:432` shows it again in `_finish_zoom`.
  - So the button and the sheet need a parent that stays visible in the zoom, or the zoom must hide FarmUI's other children instead of FarmUI itself. That choice is Patricia's, under the node-name contract (`ShopButton`, `ShopPanel` keep their names; `contract_check.py`).
- **The dim already blocks input.** It uses `MOUSE_FILTER_STOP` at z 50 with the sheet at z 51 (`shop_ui.gd`), so the crank's `_unhandled_input` (`centrifuge.gd:467`) and the fork's (`honeycomb.gd:359`) should not get taps while the sheet is open. Quinn should test this, not assume it.
- **Purchases already apply on the next read.** Upgrade levels are read when used:
  - fork reach: `honeycomb.gd:431` reads `UpgradeLevel.of("heated_fork")`
  - gearing: `centrifuge.gd:240` `gearing_level()`
  - Shop rows refresh on `Economy.upgrade_changed` (`shop_ui.gd:38`).
  - Open check: whether the gear count and the hot fork's look update mid-zoom on `upgrade_changed`, or only when the zoom next opens.
- **The Dev button is hidden while the sheet is open** (`set_sheet_open`, the `dev_button_layer` group). Its place in the zoom (left edge) doesn't clash with bottom-right.

## Tests for Quinn (from this text, not the code)

- A sequence test per zoom:
  1. Enter the zoom, open the Shop, buy, close.
  2. Check that the zoom state is unchanged and the purchase applied.
  3. Repeat twice.
  4. Also leave by every exit with the sheet open: Back, the zoom ending on its own, and app pause.
- The fork and the crank take no input while the sheet is open.
- HUD overlap: Shop clears Back, the hint, Spin and the hive count in both zooms (extend the existing HUD/anchor tests).
- `shop_layout = 0`: no Shop in the zoom.
- One mutation that keeps the button hidden in the zoom, to prove the test fails for the right reason.

## Answered

- The second stop shows Shop too (designer, 2026-11-21: "yes, second stop shows Shop too"). Nothing is left open; the item is ready to paste.
