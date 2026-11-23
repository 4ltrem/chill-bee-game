Goal agent run `0.3.1`, spec `game/specs/0.3.1-playtest-fixes.md`, goal C7. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish. Where a panel sits, how it opens and what fits on screen come from the designer's Claude Design canvas: read `UI_DESIGN.md` and the matching board in `proposals/design/ui-screens-mockup/project/` for the look and placement of what the spec item asks for. Build only what the spec asks (a board part it does not name, like tabs, waits for a later revision); where the spec text differs, the spec wins. Before writing any `(designer)` row, look for the answer in `UI_DESIGN.md`, the canvas boards, `README.md` (Outstanding TBDs), `proposals/design/ui-screens.md` and `_meta/sessions/*/decisions.md`: if one answers it, apply that answer and cite the file. If the topic is already a listed TBD, build the placeholder, name the TBD and go on; it is not a question. Ask only when none of them covers it. STYLE_GUIDE minimums are approved values, not votes: raise a touch target below 120 px to 120 and a font below 28 px to 28 without asking, and say so in your reply. 

Your contract lines:
- Item 7: `settings_ui.gd` (open, close, the language toggle, the device-language start) and every listed label through `tr()` with keys; the translation rows from `content/ui-labels.md` exported by the existing script; `modal_panel.gd` (`ModalPanel`) under the Settings sheet and the Journal panel; `main.gd` `any_panel_open()`, asked by `farm_view_idle()`, `farm_ui.gd`'s toast queue and `hint.gd` in place of their own panel lists; `hint.gd` finding `HintBubbleLabel`.

Spec text:
7. **Settings icon with a language switch, and every label translated** (designer, 2026-11-23: "add some of the icons from the ui design so we can switch language"; today the only switch is the Dev panel's "Language" button). From the canvas: `UI_DESIGN.md` rule 6 (Settings = a toothed gear), the Legend board ("Settings … Top-right corner · from the start") and the Settings board (`proposals/design/ui-screens-mockup/project/Settings.dc.html`, row "Language" with a two-part toggle "English" | "Français"). A `SettingsButton` (120 × 120, V11; a flat ink toothed gear on the gold circle with the ink ring, like the other icons) sits in the farm view's top-right corner, clear of the skip icon below it, the Habitat pill and the money; being under `FarmUI` it hides in both zooms, where Back holds that corner. It opens a `SettingsPanel` sheet over the dimmed farm, as the Shop sheet opens, holding only the Language row for now (the board's other rows come with their features); its close button and a tap on the dim close it. While it is open, toasts wait in item 2's queue and the hint bubble (item 4) hides, as for the Journal panel. The toggle calls `TranslationServer.set_locale("en"/"fr")` and every visible label updates at once, the open sheet's included. The language names are never translated ("English", "Français"). No save system, so each launch starts in the device's language (French when it begins with `fr`, else English). Every player-facing string on the farm view, in the zooms, the Shop, the Journal panel, the toasts, the welcome and victory overlays and the hint goes through `tr()` with a key, including those hard-coded today: `farm_ui.gd` (bees, the jar summary), `main.gd` (Sell and its price), `harvest_ui.gd` ("All cells uncapped!"), `shop_ui.gd` (the title, today `tr("Shop")` rather than the `shop_title` key; the Close button stays the "✕" glyph from item 3; "Owned", "Not owned", "Lv", the row names and their lock lines), `main.tscn` (the hive-full line, the Phase 2 toast, "Auto"); numbers and `$` stay as they are. The keys and EN/FR text are `content/ui-labels.md` (William + Clara, approved by the designer on 2026-11-23), Settings, Language and the Shop tabs included; French prices put the number first ("Vendre %d $", Canadian order), which the translated format string carries, so the code only formats `tr(key) % value`. **One panel base and one "panel open" check** (designer, 2026-11-23, from the 0.3.1 goal-run review; `_meta/drafts/0.3.1/shared-panel-check.md`): four places each keep their own list of what covers the farm view (`main.gd` `farm_view_idle()`, `farm_ui.gd` `_toasts_blocked()`, `hint.gd` `_covered()` / `_shop_open()`, `shop_ui.gd` `_set_hint_blocked()`), and the lists disagree: the victory waits for the Shop sheet but not the Journal panel, while toasts wait for both. A `ModalPanel` base (`modal_panel.gd`: `open()`, `close()`, `is_open()`, the z order and `top_level` the Journal and Shop panels use, its `<Name>CloseButton` and optional dim closing it, the text refreshed on a locale change, membership of the group `modal_panels`) carries the Settings sheet, and the Journal panel moves onto it; the Shop, welcome and victory move when a later item touches them. One check, `main.gd` `any_panel_open()` (a `modal_panels` member open, or the Shop or Tools sheet open), replaces those lists: `farm_view_idle()`, the toast queue and the hint bubble all ask it (the hint's `set_blocked()` stays for other blockers). So the victory also waits while the Journal or Settings panel is open (designer, 2026-11-23), as toasts already do. A node a test or script finds by name from the top of the scene is unique there: the hint bubble's `HintLabel` becomes `HintBubbleLabel` (the zoom's instruction keeps `HintLabel`; 0.3.1 C4's second fix round found the clash), and every Settings node carries the `Settings` or `Lang` prefix.

Recipes: `game/RECIPES.md` says how to add what the game already has (a panel, a corner icon, a translated label, a config value, a Dev button, a toast, their tests). Follow the one that fits instead of working it out again.

Code map of this goal's names (`python -I _tools/code_map.py --for CloseButton,FarmUI,FarmUIRoot,HintBubble,HintBubbleLabel,HintLabel,LangEnglishButton,LangFrenchButton,ModalPanel,SettingsButton,SettingsCloseButton,SettingsPanel,TranslationServer,UI_DESIGN,_set_hint_blocked,_shop_open,_toasts_blocked,any_panel_open,farm_ui,farm_view_idle,harvest_ui,is_open,modal_panel,modal_panels,set_blocked,set_locale,settings_ui,shop_title,shop_ui,top_level`; what each script offers and where the nodes sit). Read it first; open a script only for the lines you change.

# Code map for CloseButton, FarmUI, FarmUIRoot, HintBubble, HintBubbleLabel, HintLabel, LangEnglishButton, LangFrenchButton, ModalPanel, SettingsButton, SettingsCloseButton, SettingsPanel, TranslationServer, UI_DESIGN, _set_hint_blocked, _shop_open, _toasts_blocked, any_panel_open, farm_ui, farm_view_idle, harvest_ui, is_open, modal_panel, modal_panels, set_blocked, set_locale, settings_ui, shop_title, shop_ui, top_level

Generated by `python -I _tools/code_map.py`; do not edit.

## Scripts

### `dev_panel.gd` — `DevPanel` (CanvasLayer)

Implements the Prototype 0 spec "Dev mode" (game/specs/prototype-0.md): a developer panel for tuning while playing.
- Functions: `setup(hive_node: Hive, truck_node: Truck) -> void`, `set_value(value_name: String, value: Variant) -> void`, `save_values() -> void`, `reset_to_defaults() -> void`, `changed_lines() -> PackedStringArray`, `print_values() -> void`, `set_ui_bounds(on: bool) -> void`, `ui_bounds_shown() -> bool`, `step_speed(direction: int) -> void`, `toggle() -> void`, `reset_habitat() -> void`
- Config read: `habitat_health_per_patch`, `habitat_thriving`, `record_from_launch`, `show_hint`
- Nodes looked up: `HintBubble`, `VictoryOverlay`
- Nodes created at run time: `DevButton`, `DevButtonLayer`, `InputRecorder`, `LocaleButton`, `Panel`, `PhaseLabel`, `RecordingLabel`, `Row_`

### `farm_ui.gd` — `FarmUI` (Control)

Implements GDD 9 (UI & Screens: farm view HUD) for Prototype 0: money, fill bar, bee counter, paused label,
- Signals: `summary_closed`
- Functions: `enqueue_toast(key: String) -> void`, `clear_toasts() -> void`, `bumble_toast_pending() -> bool`, `toast_showing_key() -> String`, `setup(hive: Hive, centrifuge: Centrifuge, truck: Truck) -> void`, `fit_top_info(obstacles: Array[Rect2], gap: float) -> void`, `restore_top_info() -> void`, `show_summary(jars: int, per_jar: int, total: int) -> void`
- Exports: `count_gap_px = 4.0`
- Config read: `button_screen_margin`, `habitat_thriving`, `toast_seconds`
- Nodes looked up: `BeeCountLabel`, `CentrifugeAnchor`, `CentrifugeLabel`, `ForkIcon`, `HarvestFill`, `HiveCountLabel`, `JournalPanel`, `MoneyLabel`, `PatchSlots`, `PausedLabel`, `PhaseToast`, `SummaryJarsLabel`, `SummaryModal`, `SummaryOkButton`, `SummaryTotalLabel`, `SummaryValueLabel`, `ToastLabel`, `TopInfo`
- Nodes created at run time: `FillShape`

### `harvest_ui.gd` — `HarvestUI` (Control)

Implements GDD 9 (UI & Screens: the uncapping zoom on the hive and the centrifuge) for 0.1 Harvest (game/specs/0.1-harvest.md).
- Signals: `back_pressed`
- Functions: `show_zoom() -> void`, `show_pan() -> void`, `show_done() -> void`, `hide_zoom() -> void`
- Nodes looked up: `BackButton`, `HintLabel`

### `hint.gd` — `HintBubble` (Control)

Implements 0.3.1 item 4 (game/specs/0.3.1-playtest-fixes.md): the first-time hint. `HintBubble` (FarmUIRoot) is a small panel with one
- Functions: `skip() -> void`, `replay() -> void`, `set_blocked(source: StringName, on: bool) -> void`, `step_key() -> String`
- Config read: `button_screen_margin`, `hint_gap_px`, `hint_point_radius_px`, `show_hint`
- Nodes looked up: `HintLabel`, `HintSkipButton`, `HintTail`

### `main.gd` (Node3D)

Implements GDD 1 (Primary Game Loop) and 2 (the whole harvest plays on the farm; for uncapping the camera zooms in on the hive and the
- Functions: `show_welcome() -> void`, `at_second_stop() -> bool`, `welcome_active() -> bool`, `fork_available() -> bool`, `sell() -> int`, `load_pile() -> void`, `open_zoom() -> bool`, `spin_tapped() -> void`, `back() -> void`, `advance(delta: float) -> void`, `farm_view_idle() -> bool`, `zoom_size() -> float`, `zoom_position() -> Vector3`, `leave_second_stop() -> void`, `second_stop_pose() -> Dictionary`
- Config read: `camera_pan_seconds`, `cell_fly_arc`, `cell_fly_seconds`, `close_delay_seconds`, `frame_rise`, `jar_fly_seconds`, `lid_move_seconds`, `pan_margin`, `pan_zoom_size`, `pile_load_stagger_seconds`, `show_welcome`, `slide_seconds`, `spin_farm_visual_px`, `spin_zoom_offset`, `zoom_seconds`, `zoom_size`
- Nodes looked up: `Bees`, `Camera3D`, `Centrifuge`, `CentrifugeIcon`, `FarmUI`, `FarmWorld`, `ForkIcon`, `HabitatPill`, `HarvestUI`, `Hive`, `Honeycomb`, `JarCrate`, `Pile`, `SellIcon`, `ShopPanel`, `SkipIcon`, `Truck`, `UncapFork`, `WelcomeOverlay`, `ZoomFraming`
- Nodes created at run time: `DevPanel`

### `shop_ui.gd` — `ShopUI` (Control)

Implements GDD 3 (Tree A: Worker Swarm Count) and 9 (Upgrade Shop panel) for Prototype 0.
- Functions: `is_sheet_open() -> bool`, `set_sheet_open(on: bool) -> void`, `set_tools_open(on: bool) -> void`, `is_tools_open() -> bool`
- Config read: `shop_font_size`, `shop_layout`, `shop_row_height`
- Nodes looked up: `BuyButton`, `GateLabel`, `HintBubble`, `JournalButton`, `JournalPanel`, `LevelLabel`, `NameLabel`, `RowTemplate`, `ShopBox`, `ShopCloseButton`, `ShopHeader`, `ShopMoney`, `ShopRows`, `ShopTabs`, `ShopTitle`, `ToolsButton`
- Nodes created at run time: `ComingSoonLabel`, `Row_`, `ShopButton`, `ShopCloseButton`, `ShopDim`, `ShopHeader`, `ShopMoney`, `ShopTabs`, `ShopTitle`, `UpgradeButton`
- tr() keys: `Shop`, `shop_coming_soon`, `shop_tab_`, `tools_icon`

## Scene nodes

### `scenes/main.tscn` (131 nodes)

| Node | Type | Parent | Script |
|---|---|---|---|
| `FarmUIRoot` | CanvasLayer | `.` |  |
| `FarmUI` | Control | `FarmUIRoot` | farm_ui.gd |
| `Margin` | MarginContainer | `FarmUIRoot/FarmUI` |  |
| `Column` | VBoxContainer | `FarmUIRoot/FarmUI/Margin` |  |
| `TopInfo` | VBoxContainer | `FarmUIRoot/FarmUI/Margin/Column` |  |
| `TopRow` | HBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/TopInfo` |  |
| `MoneyLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/TopInfo/TopRow` |  |
| `BeeCountLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/TopInfo` |  |
| `HabitatPill` | HBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/TopInfo/TopRow` | habitat_pill.gd |
| `HabitatCountLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/TopInfo/TopRow/HabitatPill` |  |
| `HabitatIcon` | Panel | `FarmUIRoot/FarmUI/Margin/Column/TopInfo/TopRow/HabitatPill` |  |
| `DevSpeedTag` | Label | `FarmUIRoot/FarmUI/Margin/Column/TopInfo` |  |
| `Spacer` | Control | `FarmUIRoot/FarmUI/Margin/Column` |  |
| `PausedLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column` |  |
| `ShopPanel` | PanelContainer | `FarmUIRoot/FarmUI/Margin/Column` | shop_ui.gd |
| `ShopBox` | VBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel` |  |
| `ShopHeader` | HBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox` |  |
| `ShopHeaderText` | VBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopHeader` |  |
| `ShopTitle` | Label | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopHeader/ShopHeaderText` |  |
| `ShopMoney` | Label | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopHeader/ShopHeaderText` |  |
| `ShopCloseButton` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopHeader` |  |
| `ShopTabs` | HBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox` |  |
| `TabBees` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopTabs` |  |
| `TabHive` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopTabs` |  |
| `TabHabitat` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopTabs` |  |
| `TabResearch` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopTabs` |  |
| `TabRefinery` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopTabs` |  |
| `ShopRows` | VBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox` |  |
| `RowTemplate` | PanelContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows` |  |
| `RowBox` | HBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate` |  |
| `Info` | VBoxContainer | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate/RowBox` |  |
| `NameLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate/RowBox/Info` |  |
| `LevelLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate/RowBox/Info` |  |
| `GateLabel` | Label | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate/RowBox/Info` |  |
| `BuyButton` | Button | `FarmUIRoot/FarmUI/Margin/Column/ShopPanel/ShopBox/ShopRows/RowTemplate/RowBox` |  |
| `JournalButton` | Button | `FarmUIRoot/FarmUI` |  |
| `CentrifugeLabel` | Label | `FarmUIRoot/FarmUI` |  |
| `ForkIcon` | Button | `FarmUIRoot/FarmUI` | floating_icon.gd |
| `HarvestFill` | ColorRect | `FarmUIRoot/FarmUI/ForkIcon` |  |
| `ForkGlyph` | Node2D | `FarmUIRoot/FarmUI/ForkIcon` |  |
| `Handle` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph` |  |
| `HandleWood` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph` |  |
| `Tines` | Node2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph` |  |
| `Tine1` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Tine2` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Tine3` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Tine4` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Tine5` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Tine6` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph/Tines` |  |
| `Head` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph` |  |
| `HeadSteel` | Line2D | `FarmUIRoot/FarmUI/ForkIcon/ForkGlyph` |  |
| `HiveCountLabel` | Label | `FarmUIRoot/FarmUI` |  |
| `CentrifugeIcon` | Button | `FarmUIRoot` | floating_icon.gd |
| `SpinGlyph` | Node2D | `FarmUIRoot/CentrifugeIcon` |  |
| `DropFill` | Polygon2D | `FarmUIRoot/CentrifugeIcon/SpinGlyph` |  |
| `DropOutline` | Line2D | `FarmUIRoot/CentrifugeIcon/SpinGlyph` |  |
| `TurnArrow` | Line2D | `FarmUIRoot/CentrifugeIcon/SpinGlyph` |  |
| `TurnArrowHead` | Line2D | `FarmUIRoot/CentrifugeIcon/SpinGlyph` |  |
| `SellIcon` | Button | `FarmUIRoot/FarmUI` | floating_icon.gd |
| `SkipIcon` | Button | `FarmUIRoot/FarmUI` | skip_icon.gd |
| `AutoTag` | Label | `FarmUIRoot/FarmUI` |  |
| `PhaseToast` | PanelContainer | `FarmUIRoot/FarmUI` |  |
| `ToastLabel` | Label | `FarmUIRoot/FarmUI/PhaseToast` |  |
| `SummaryModal` | PanelContainer | `FarmUIRoot/FarmUI` |  |
| `SummaryMargin` | MarginContainer | `FarmUIRoot/FarmUI/SummaryModal` |  |
| `SummaryColumn` | VBoxContainer | `FarmUIRoot/FarmUI/SummaryModal/SummaryMargin` |  |
| `SummaryJarsLabel` | Label | `FarmUIRoot/FarmUI/SummaryModal/SummaryMargin/SummaryColumn` |  |
| `SummaryValueLabel` | Label | `FarmUIRoot/FarmUI/SummaryModal/SummaryMargin/SummaryColumn` |  |
| `SummaryTotalLabel` | Label | `FarmUIRoot/FarmUI/SummaryModal/SummaryMargin/SummaryColumn` |  |
| `SummaryOkButton` | Button | `FarmUIRoot/FarmUI/SummaryModal/SummaryMargin/SummaryColumn` |  |
| `JournalPanel` | PanelContainer | `FarmUIRoot/FarmUI` |  |
| `JournalMargin` | MarginContainer | `FarmUIRoot/FarmUI/JournalPanel` |  |
| `JournalColumn` | VBoxContainer | `FarmUIRoot/FarmUI/JournalPanel/JournalMargin` |  |
| `JournalTitle` | Label | `FarmUIRoot/FarmUI/JournalPanel/JournalMargin/JournalColumn` |  |
| `JournalScroll` | ScrollContainer | `FarmUIRoot/FarmUI/JournalPanel/JournalMargin/JournalColumn` |  |
| `JournalBody` | Label | `FarmUIRoot/FarmUI/JournalPanel/JournalMargin/JournalColumn/JournalScroll` |  |
| `JournalCloseButton` | Button | `FarmUIRoot/FarmUI/JournalPanel/JournalMargin/JournalColumn` |  |
| `HintBubble` | Control | `FarmUIRoot` | hint.gd |
| `HintPanel` | Panel | `FarmUIRoot/HintBubble` |  |
| `HintLabel` | Label | `FarmUIRoot/HintBubble` |  |
| `HintSkipButton` | Button | `FarmUIRoot/HintBubble` |  |
| `HintTail` | Polygon2D | `FarmUIRoot/HintBubble` |  |
| `HintLabel` | Label | `HarvestUIRoot/HarvestUI` |  |

Duplicate names (`find_child` returns the first): `HintLabel` under `FarmUIRoot/HintBubble` and `HarvestUIRoot/HarvestUI`


Reply in at most 150 words: files changed, node names used, open questions.