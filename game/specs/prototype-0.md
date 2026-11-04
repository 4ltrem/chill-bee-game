---
author: designer
type: spec
status: approved
revision: 3
decided: 2026-11-04
decision: approved for build (designer set the goal "implement the prototype-0 spec"); slower harvest values and Dev mode added at review
description: Prototype 0, the manual core loop in Sunny Meadow as a colorbox (primitive shapes and flat colours, no audio); revision 3 follows the 2026-11-03 harvest flow in GDD §2
---
# Prototype 0: the manual core loop (colorbox), revision 3

**Sources:** `GDD.md` (1. Primary Game Loop & Phase Structure; 2. Phase 1 Uncapping & Extraction Minigame; 3. Progression Trees, Tree A and Tree B; 8. Accessibility; 9. UI & Screens; Engine Integration; Technical Constraints). Open items from `game/reports/2026-11-03-prototype-0.md`, "Open for revision 3".

The first playable piece of Chill Bee Game: one hive in Sunny Meadow, harvested by hand, honey bottled and sold by truck, the first upgrade bought, and round again. It is the loop the onboarding script (`content/onboarding-script.md`) walks a new player through. That script still describes the old flow and is revised separately.

## Changes from revision 2

GDD §2 now plays only uncapping in a close-up. Extraction, bottling and selling play on the farm.

| | Revision 2 | Revision 3 |
|---|---|---|
| Start the harvest | `HarvestButton` in the farm UI | a **fork icon** floating above the full hive |
| Leave the close-up | none | **`BackButton`**: back to the farm, the frame stays in the hive, uncapping progress is lost |
| End of uncapping | `ExtractButton` ("Extract honey") on the close-up | **retired**: the close-up closes by itself, and a **centrifuge icon** floats above the full centrifuge on the farm. Tapping it is the pause the designer asked for in revision 2 |
| Extraction | `CrankButton` in `harvest.tscn` | **tap or hold the centrifuge's crank, or the screen around it**, on the farm. No crank button |
| Accessibility | `NoRapidTapCheck` and `hold_mode` | **removed**: holding is built in for every player and never slower than tapping (GDD §8) |
| After extraction | `SummaryModal` and Continue in `harvest.tscn` | a **Continue** button on the farm opens the spigot. Jars bottle one at a time onto the truck, then the summary shows on the farm |
| Selling | `SellButton` in the farm UI, money at once | a **Sell ($X) icon** above the full truck. Tapping it credits the money, and the truck drives off and comes back |
| Shop | usable on the farm | usable on the farm at every stage of the harvest |
| `JarsLabel` ("Jars: n") | farm top info | **removed**: jars are visible in the crate and on the truck |
| Where `Centrifuge` lives | `harvest.tscn` | `main.tscn`, `FarmWorld` |
| New scripts | | `truck.gd`, `floating_icon.gd`, `dev_panel.gd` |
| Tuning | edit `default_config.tres` and restart | **Dev mode**: adjust every config value live while playing |

## Look: colorbox

- Primitive meshes and flat colours only (`BoxMesh`, `CylinderMesh`, `PlaneMesh`, `SphereMesh`, `StandardMaterial3D` albedo colours). No imported models, textures or audio.
- Sunny Meadow: a pastel-green ground plane; the hive a tan box; bees small yellow spheres orbiting between the hive and two or three flower patches (coloured cylinders). Use `MultiMeshInstance3D` for the bees. The swarm has a size: the farm shows one flying bee per bee in the count, up to a visual cap.
- **Farm props (new):** the **centrifuge**, a steel-grey cylinder with a lid, a **crank** (a small box handle on an arm, on the side or top, that turns with the spin) and a **spigot** (a short cylinder low on its side). The **jar crate**, a low brown box beside it, with one small jar per waiting jar (up to 10 shown). The **truck**, a vintage pickup made of boxes (cab, bed, four cylinder wheels), with its bed showing one jar per loaded jar. Jars are small amber cylinders.
- Honeycomb cells: hexagonal prisms (`CylinderMesh` with `radial_segments = 6`). Capped: matte yellow. Uncapped: glowing gold (emission). Extracted: pale, near-empty. Cells also differ in height, not colour alone (GDD §8): capped raised, uncapped flush, extracted recessed.
- Isometric orthographic camera as in `scenes/main.tscn`. Portrait 720×1280, the project's existing settings. The farm camera frames the hive, flowers, centrifuge, crate and truck together. The farm is not pannable in this prototype.

**Colorbox simplifications of GDD §2** (the full effect comes later):
- "The camera zooms close to the hive": a cut, or a tween of up to 0.4 s, to the close-up camera.
- "A frame slides out of the top": the frame slides in on a simple position tween of about 0.3 s. When it is fully uncapped it slides away the same way.
- "Each scraped cell pops and flies into the centrifuge": the scale pop only. The centrifuge is not visible from the close-up.
- "Honey streams against its glass walls": the barrel spins. No streams or particles.
- "The truck speeds off and comes back": the truck slides off-screen along the ground and slides back, over the trip time.
- No particles, audio or haptics (GDD §2 lists them; out of scope for colorbox).

## The loop

1. **Bees forage, hive fills.** Hive storage rises over time toward capacity (one frame: 10 jars). The farm's top info shows money, a fill bar ("Hive: n / 10") and the **bee counter** ("Bees: 20"). The fill rate scales with the bee count. Past capacity, production continues into the free overflow buffer of one extra frame; when that is full too, production pauses and the paused label shows.
2. **Fork icon.** When the hive is full **and** the centrifuge is empty, the **fork icon** floats above the hive. If the centrifuge still holds a frame (cranking or bottling), the fork stays hidden and the hive keeps filling into the overflow.
3. **Stage 1, uncapping (close-up).** Tapping the fork opens `harvest.tscn`: the farm view and its UI hide, the close-up camera becomes current, and one frame of 7 × 5 capped cells slides in. Dragging the mouse or a finger across cells uncaps them (state 0 → 1), using `PhysicsDirectSpaceState3D` raycasts onto the cells' collision shapes. Uncapped cells pop (scale) and change height and colour.
   - **Back:** a `BackButton` (top corner, not over the frame) closes the close-up and returns to the farm. The frame stays in the hive (`take_frame()` has not run), the cells reset to Capped next time, and the fork icon shows again.
   - When **every** cell is uncapped, the hint reads "All cells uncapped!", the frame slides away, the hive gives up the frame (`take_frame()`), and after about 0.5 s the close-up closes and the farm returns.
   - **Frame queue (later, not in this prototype):** GDD §2 brings up the next full frame while the hive or overflow has one and the centrifuge has room. With a centrifuge capacity of 1 frame there is never room, so this prototype always closes after one frame. Code the check as `centrifuge has room and hive has a full frame`, so a later capacity change brings the queue in without a rewrite.
4. **Centrifuge full.** The centrifuge is closed and full, and the **centrifuge icon** floats above it. Nothing spins until the player taps it.
5. **Stage 2, extraction (on the farm).** Tapping the centrifuge icon hides it and starts cranking.
   - **Tap:** each tap or click on the crank, the centrifuge, or anywhere on the screen that is not a button or panel counts as one crank turn. It spins the barrel and the crank, and moves honey toward the jar count. Taps arrive through `_unhandled_input`, so presses on buttons (Upgrade, icons, Continue) never count as cranks. **Tap cap:** a tap counts only if at least `1 / max_tap_rate` s has passed since the last counted turn; faster taps are ignored.
   - **Hold:** pressing and holding anywhere that counts as a tap cranks continuously. The press itself counts one turn, as a tap would; after that the hold accrues turns continuously at `max_tap_rate`, the fastest taps can count, so holding is never slower than tapping. The barrel's visual spin ramps up to full speed over `hold_ramp_seconds`; this ramp is visual only. Releasing stops the counting.
   - A label near the centrifuge shows the progress ("Honey: 6 / 10") and a hint while it waits for the first tap ("Tap or hold to spin").
   - When `taps_per_frame` turns are counted, extraction is done: the spin winds down and a **Continue** button appears (bottom of the screen, thumb-sized).
6. **Stage 3, bottling (on the farm).** Continue hides itself and opens the spigot. One jar fills every `bottling_seconds_per_jar` (a jar appears at the spigot and grows), then loads onto the truck. If the truck is away, the jar goes to the crate instead. When the truck returns, crate jars load onto it up to its capacity. The crate has no limit in this prototype (it shows at most 10 jars; a count label shows the rest). When the last jar is bottled, the centrifuge is empty again, and the **batch summary** modal shows jars, value per jar ($3), tool bonus $0, quality bonus $0, and the batch total. An **OK** button closes it.
7. **Sell.** When the truck holds `truck_capacity_jars` and is home, the **Sell ($X) icon** floats above it, with X the load's value (10 × $3 = $30). Tapping it **credits the money at once**, empties the truck and sends it off. The truck is away for `truck_trip_seconds`, then comes back and loads any crate jars.
8. **Upgrade.** The Upgrade Shop panel has one item, **Worker Swarm Count**, unchanged from revision 2. It adds `bees_per_swarm_level` bees per level, and the extra bees give the +15% fill rate. Cost is `25 × 1.18^level`, rounded; max level 10. The button shows the next cost and is disabled when unaffordable or maxed. The shop works at every stage the farm is visible: while cranking, bottling, or the truck being away.
9. Round again. The next fork tap resets the frame's cells to Capped.

**What each state allows** (the farm is live through the whole harvest):

| Centrifuge state | Fork icon (hive full) | Crank input counts | Continue | Centrifuge icon | Sell icon (truck full, home) | Shop |
|---|---|---|---|---|---|---|
| `EMPTY` | shown | no | hidden | hidden | as truck allows | yes |
| `FULL` (closed, waiting) | hidden | no | hidden | shown | as truck allows | yes |
| `CRANKING` | hidden | **yes** | hidden | hidden | as truck allows | yes |
| `DONE` | hidden | no | shown | hidden | as truck allows | yes |
| `BOTTLING` | hidden | no | hidden | hidden | as truck allows | yes |

The close-up (stage 1) is a separate screen: the farm and its UI are hidden while it is open, so nothing on the farm can be pressed then. The hive keeps filling during every state, including the close-up.

Out of scope: the Long Fork and every other upgrade, automation (self-driving truck, electric centrifuge), Auto-Sell, grid expansion, panning and zoom of the farm, biomes, Habitat, pests and nectar drops, offline earnings, the guide character and dialogue, saving, localisation, audio, haptics, particles, monetisation.

## Accessibility (GDD §8)

- **Hold instead of tapping** is built in (loop step 5). There is no toggle and no setting.
- **Colour-blind support:** the three floating icons differ in **shape and label**, not colour alone: fork icon a tall rounded tag with a fork glyph drawn from boxes or the text "Harvest"; centrifuge icon a circle with "Spin"; sell icon a wide pill reading "Sell $30". Cells differ in height (see Look).
- **One-handed play:** every floating icon has a touch area of at least **120 × 120 px** at 720 × 1280. Continue, OK and BackButton are at least 120 px high. Continue and OK sit in the lower half of the screen.
- **Contrast:** text on every button, including the disabled Upgrade button, has a contrast ratio of at least 4.5:1 against its background (open item #5).

## Values

From the GDD: frame 10 jars; overflow buffer 1 frame; Worker Swarm Count +15%/level, base $25, ×1.18, max 10.

Placeholders (TBD in the GDD) stay as exported variables in `game_config.gd` (defaults in `default_config.tres`), each marked `# PLACEHOLDER (GDD TBD)`. **Every one is also adjustable live in Dev mode** (below). The harvest values are deliberately unhurried: honey is viscous, and speed is what upgrades are for (Centrifuge Gearing and later tools).

No script may copy a config value into a constant or cache it at `_ready`: read it from the config when it is used, so Dev mode edits apply at once.

| Value | Placeholder | Why this number |
|---|---|---|
| base fill rate | 1 jar per 6 s (one frame in 60 s) | a first harvest within a minute of starting (unchanged) |
| sale value per jar | $3 | the first Worker Swarm Count ($25) after one truck load (unchanged) |
| taps per frame (`taps_per_frame`) | **40** (was 20) | extraction should feel like work; with the cap below, about 8 s of cranking per frame |
| honeycomb frame size | 7 × 5 cells | readable at portrait size (unchanged) |
| base swarm, bees per level, visual bee cap | 20, +3, 60 | unchanged |
| **centrifuge capacity** (`centrifuge_capacity_frames`) | **1 frame** | new; the designer's prototype value. Keeps one frame per harvest |
| **truck capacity** (`truck_capacity_jars`) | **10 jars** | new; the designer's prototype value. One batch fills the truck |
| **truck trip time** (`truck_trip_seconds`) | **30 s** | new; a real trip to market, long enough that the crate gets used |
| **bottling time** (`bottling_seconds_per_jar`) | **3 s** | new; viscous honey: a 10-jar batch bottles in 30 s while the farm stays live |
| **counted tap cap** (`max_tap_rate`) | **5 taps per second** | new; a frame takes about 7.8 s at the cap, tapped or held |
| **hold spin ramp** (`hold_ramp_seconds`) | **1.5 s** | new; visual only, a heavy barrel takes 1.5 s to reach full spin |

Removed: `hold_taps_per_second` (No-Rapid-Tap Mode is gone; a hold counts at `max_tap_rate`).

## Contract between scripts and scenes

Patricia writes the scripts; Bob writes the scenes that use them; Quinn tests both. Node names and signals below are the contract: keep them exactly, or update this file and say so. Keep every rule headless-testable through an `advance(delta)` method separate from `_process`, as `hive.gd` and `centrifuge.gd` already do.

| Script (`game/scripts/`) | Responsibility | Public API |
|---|---|---|
| `game_config.gd` | `Resource` with every value above as `@export` vars | — |
| `economy.gd` | autoload `Economy`: money, Worker Swarm Count level, cost formula. Jars now live in the centrifuge, crate and truck, so `jars`, `add_jars()`, `sell_jars()` and `jars_changed` go | `money`, `swarm_level`, `bee_count()`, `fill_multiplier()`, `swarm_cost()`, `can_buy_swarm()`, `buy_swarm()`, `jar_value()`, `earn(amount)`; signals `money_changed`, `swarm_level_changed` |
| `hive.gd` | storage, overflow, fill over time (unchanged) | `storage`, `overflow`, `capacity`, `is_full()`, `is_paused()`, `take_frame() -> int`, `advance(delta, multiplier)`; signals `storage_changed`, `became_full` |
| `honeycomb.gd` | the cell grid as a byte array (`0 = Capped`, `1 = Uncapped`, `2 = Extracted`), cell meshes, drag raycasts, slide-in and slide-out tween | `reset()`, `uncap_at(cell)`, `all_uncapped()`, `extract_all()`, `active`; signal `all_cells_uncapped` |
| `centrifuge.gd` | state machine `EMPTY → FULL → CRANKING → DONE → BOTTLING → EMPTY`; counted taps with the rate cap; hold; barrel, crank and spigot visuals; bottling timer. Reads crank input in `_unhandled_input` only in `CRANKING` | `state`, `jars_total`, `jars_extracted`, `jars_bottled`, `has_room() -> bool`, `fill(jars)`, `begin_crank()`, `tap() -> bool` (true if counted), `set_holding(bool)`, `open_spigot()`, `advance(delta)`; signals `state_changed(state)`, `extraction_progress(done, total)`, `extraction_done`, `jar_bottled(count)`, `bottling_done(jars)` |
| `truck.gd` (new) | the truck's load, the crate, the trip; slide-off and return visual | `loaded_jars`, `crate_jars`, `away: bool`, `capacity`, `is_full() -> bool`, `can_sell() -> bool`, `receive_jar()` (to the truck if home and not full, else the crate), `sell() -> int` (credits `Economy.earn`, returns the amount, starts the trip), `load_value() -> int`, `advance(delta)`; signals `load_changed(loaded_jars, crate_jars)`, `departed`, `returned` |
| `floating_icon.gd` (new) | a `Button` that follows a 3D anchor: each frame it places itself at `camera.unproject_position(anchor.global_position)` plus an offset, and hides when the anchor is behind the camera | `@export anchor_path: NodePath`, `@export screen_offset: Vector2`; uses the Button's own `pressed` signal |
| `farm_ui.gd` | money, fill bar, bee counter, paused label, Continue, summary modal, centrifuge progress label and hint. Loses `HarvestButton` and `SellButton` | `setup(hive, centrifuge, truck)`, `show_continue(bool)`, `show_summary(jars, per_jar, total)`; signals `continue_pressed`, `summary_closed` |
| `shop_ui.gd` | the Upgrade Shop panel (unchanged apart from contrast) | — |
| `harvest_ui.gd` | stage 1 only: hint label and BackButton | `show_stage1()`, `show_stage1_done()`; signal `back_pressed` |
| `main.gd` | owns the flow 1 → 9: opens and frees the close-up, shows and hides the three floating icons from the state table, wires Continue, bottling to the truck, and Sell | — |
| `bees.gd` | the bee MultiMesh, visual only (unchanged) | `drawn_count()` |

Scenes (`game/scenes/`): `main.tscn` gains the centrifuge, crate, truck, icons, Continue and the summary; `harvest.tscn` shrinks to the honeycomb close-up. Scenes attach scripts by path and hold no logic (Bob's rule).

## Node paths for Bob

Proposed by the spec; **Patricia confirms or adjusts these names before Bob builds**, as in revision 2. Scripts find their child controls with `find_child(name, true, false)`, so **node names are the contract and the nesting (containers, margins, layout) is Bob's**. Names must be unique within each scene. Project autoload `Economy` is registered in `project.godot`.

### `main.tscn`

```
Main                      Node3D                 script: res://scripts/main.gd
  WorldEnvironment        WorldEnvironment
  Sun                     DirectionalLight3D
  Camera3D                Camera3D               direct child of Main, isometric ortho, current = true; frames hive, flowers, centrifuge, crate and truck in portrait
  FarmWorld               Node3D                 main.gd hides this node during the close-up
    Ground                MeshInstance3D         pastel-green PlaneMesh, large enough for the new props
    Hive                  Node3D                 script: res://scripts/hive.gd; group "bee_home"; tan BoxMesh child
      ForkAnchor          Marker3D               above the hive; the fork icon follows it
    Flowers               Node3D
      FlowerPatch1..3     Node3D                 group "flower_patch"; coloured CylinderMesh child
    Bees                  MultiMeshInstance3D    script: res://scripts/bees.gd
    Centrifuge            Node3D                 script: res://scripts/centrifuge.gd (builds barrel, crank and spigot around its origin)
      CentrifugeAnchor    Marker3D               above the centrifuge; the centrifuge icon follows it
    JarCrate              Node3D                 brown BoxMesh; truck.gd shows the crate's jars on it
    Truck                 Node3D                 script: res://scripts/truck.gd (builds the pickup from boxes, home position = where Bob puts it)
      SellAnchor          Marker3D               above the truck; the Sell icon follows it
  FarmUIRoot              CanvasLayer
    FarmUI                Control (full rect)    script: res://scripts/farm_ui.gd; mouse_filter Ignore
      MoneyLabel          Label
      FillBar             ProgressBar
      FillLabel           Label                  "Hive: n / 10"
      BeeCountLabel       Label                  "Bees: 20"
      PausedLabel         Label                  hidden by default
      CentrifugeLabel     Label                  "Honey: n / 10" and the "Tap or hold to spin" hint; hidden unless CRANKING
      ContinueButton      Button                 "Continue"; gold, at least 120 px high, lower half; hidden by default
      SummaryModal        PanelContainer         hidden by default, centred
        SummaryJarsLabel  Label
        SummaryValueLabel Label                  "Value per jar: $3"
        SummaryBonusLabel Label                  "Tool bonus: $0   Quality bonus: $0"
        SummaryTotalLabel Label                  "Batch total: $30"
        SummaryOkButton   Button                 "OK"
      ForkIcon            Button                 script: res://scripts/floating_icon.gd; anchor_path → ForkAnchor; tall rounded tag, "Harvest"; min 120 × 120
      CentrifugeIcon      Button                 script: floating_icon.gd; anchor_path → CentrifugeAnchor; circle, "Spin"; min 120 × 120
      SellIcon            Button                 script: floating_icon.gd; anchor_path → SellAnchor; wide pill, text set by script ("Sell $30"); min 120 high
      ShopPanel           PanelContainer         script: res://scripts/shop_ui.gd
        LevelLabel        Label
        UpgradeButton     Button
```

**Patricia's confirmation (revision 3).** Every name above is confirmed unchanged. What Bob must set:

- **Icons.** `ForkIcon`, `CentrifugeIcon`, `SellIcon` are direct children of `FarmUI`, each with `script = floating_icon.gd` and `anchor_path` set to its marker (`ForkAnchor`, `CentrifugeAnchor`, `SellAnchor`). The inspector's relative path from the icon works (e.g. `../../../FarmWorld/Hive/ForkAnchor`); a path from `Main` or the bare marker name also resolves. `screen_offset` (default 0) shifts the icon from the projected point; the projected point plus offset is the icon's **centre**. Icons enforce a 120 × 120 minimum themselves. The icons keep `mouse_filter = Stop` (Button default). `main.gd` shows and hides them and sets the Sell text; leave them visible in the scene.
- **Mouse filters.** `FarmUI`, every full-rect container, and every Label: `Ignore`. Buttons, `ShopPanel` and `SummaryModal`: `Stop`.
- **Centrifuge props.** `centrifuge.gd` builds its barrel (radius 1.0, height 1.4), lid, crank (arm and handle on the lid, turning with the barrel) and spigot (low on the +Z side, with a jar that grows under it) at its origin. Bob places the `Centrifuge` node, then puts `CentrifugeAnchor` above it (about y = 2.5).
- **Truck.** `truck.gd` builds a pickup about 3.2 long, facing +X, wheels on the ground at y = 0, bed jars on it. It drives off along `exit_direction` (default +X, an exported var on the node) by `truck_slide_distance` (config, 25 units), so Bob places `Truck` at home with a clear run in that direction, or sets `exit_direction`. `SellAnchor` about y = 2.0 above it.
- **Crate.** `truck.gd` finds `JarCrate` through its `crate_path` (default `../JarCrate`, a sibling of `Truck`) and adds up to 10 jar meshes and a `CrateCountLabel` (Label3D) to it. The crate box's top should be near y = 0.5 (jars sit at y = 0.55 in its local space).
- **Close-up.** `Honeycomb` slides in from `slide_offset` (default `(0, 0, -12)`, the screen top if the camera looks down with -Z up) to its home position in the scene. Bob keeps `Honeycomb` at the origin and the camera framing the frame at home; adjust `slide_offset` if the camera is rotated. `Harvest/Camera3D` and the farm `Camera3D` must both be named `Camera3D` (Main's is its direct child).
- **Nothing in `harvest.tscn` named `Centrifuge`.** `main.gd` looks up `Centrifuge` in `main.tscn` only.
- **Dev panel.** No scene work: `main.gd` adds `DevPanel` at start when `chill_bee/dev_mode` is true.

- All full-rect containers and labels use `mouse_filter = Ignore`, so empty screen space reaches `_unhandled_input` as crank input. Buttons and `ShopPanel` keep `Stop`, so presses on them never count as cranks.
- The three icons are gold with dark text (open item #4: the call to action stands out), and differ in shape as above.
- No farm prop, icon or the summary may sit under the ShopPanel or the top info in portrait (open item #3).

### `harvest.tscn`

Instanced by `main.gd` from `res://scenes/harvest.tscn` when the fork is tapped, and freed when the close-up closes (Back, or all cells uncapped).

```
Harvest                   Node3D                 no script
  Camera3D                Camera3D               ortho camera framing the 7x5 frame (flat on the XZ plane, look down); main.gd calls make_current()
  Backdrop                MeshInstance3D         flat-colour plane under the frame, filling the portrait view
  Honeycomb               Node3D                 script: res://scripts/honeycomb.gd; at the origin; builds its 35 cells in _ready
  HarvestUIRoot           CanvasLayer
    HarvestUI             Control (full rect)    script: res://scripts/harvest_ui.gd; mouse_filter Ignore
      HintLabel           Label                  "Drag across the cells to uncap them" → "All cells uncapped!"; mouse_filter Ignore
      BackButton          Button                 "Back"; top-left corner, at least 120 px high, never over the frame
```

- **No `Light` node** (open item #2). The farm's `Sun` lights the close-up because the scene is instanced under `Main`. The revision 2 `Light` (energy 0.6) on top of the Sun lit capped cells to the same yellow as uncapped ones, and the uncapping pop stopped reading.
- `Centrifuge`, `Stage1Panel`'s `ExtractButton`, `Stage2Panel` and `SummaryModal` are removed from this scene.
- The cells are raycast from `get_viewport().get_camera_3d()`, so `Harvest/Camera3D` must see every cell, and nothing with a collider may sit between it and the frame.

## Clarifications (2026-11-04, from Quinn's spec-first tests)

Settled while the build ran; they take precedence over anything above that reads differently.

- **One live config.** `GameConfig.live()` is the single instance: `Economy.config` and every node's `config` default to it, and the Dev panel edits it. `GameConfig.load_default()` returns a fresh copy, with `user://dev_config.tres` laid over it only when `chill_bee/dev_mode` is on.
- **Centrifuge.** The state enum is `Centrifuge.State { EMPTY, FULL, CRANKING, DONE, BOTTLING }`. `extraction_progress(done, total)` counts jars. A new signal `turn_counted(turns)` fires on every counted turn. A press is counted by the input handler calling `tap()`; `set_holding(true)` counts nothing itself, so the hold timing (one turn on press, then `max_tap_rate`/s) is unchanged.
- **Honeycomb** keeps `get_state(i)`. `grid_cols` and `grid_rows` are read when a frame is built, not live.
- **Close-up timing.** After the last cell, the frame slides out (`slide_seconds`), then the close-up closes after `close_delay_seconds` more (0.8 s in total by default).
- **Floating icon.** The projected anchor point plus `screen_offset` is the icon's **centre**. Icons follow their anchor by default; `main.gd` hides them with `set_wanted(false)`.
- **Dev panel.** It starts hidden; the backquote key and the three-finger tap toggle it. Each row is a Label named after the property and a SpinBox or CheckBox in one HBoxContainer. The buttons read "Save", "Reset to defaults", "Print values", "Fill hive", "+$100", "Truck home", "Reset progress", "×1", "×2" and "×5".
- **More tunables.** Patricia added these as config placeholders, so no number stays a literal in a script: `spin_impulse`, `spin_decay`, `spin_max`, `slide_seconds`, `close_delay_seconds`, `truck_slide_distance` and `truck_slide_fraction`.

## Dev mode

A developer panel for tuning while playing. Every spec from now on includes it (`game/CONTEXT.md`, Process), and every new tunable value joins it.

- **Opening it:** the backquote key (`` ` ``) on desktop, or a three-finger tap on a phone. It opens over the farm or the close-up, and the game keeps running behind it.
- **Values:** one row per `@export` var in `GameConfig`, generated from the resource's property list (so a new config value appears without UI work). Each row has a SpinBox for ints and floats (with sensible steps), a checkbox for bools, and the default beside it. Editing a row changes the live config at once: the hive's fill rate, the tap cap, bottling time and trip time apply mid-harvest.
- **Actions:** fill the hive now; +$100; empty the truck and bring it home; reset money and upgrades; game speed ×1 / ×2 / ×5 (`Engine.time_scale`).
- **Saving:** "Save" writes the edited values to `user://dev_config.tres`, which loads over the defaults at the next start, so tuning survives a restart. "Reset to defaults" deletes it. "Print values" prints every changed value as `name = value` to the console, so good numbers can be copied into `default_config.tres` (and later the GDD, through a proposal).
- **Where it exists:** a custom project setting `chill_bee/dev_mode` (true for prototypes). When it is false, the panel and its input are never created and `user://dev_config.tres` is ignored. Store builds set it false.
- **Who builds it:** Patricia, as `scripts/dev_panel.gd`, a `CanvasLayer` that builds its own controls in code; `main.gd` adds it at start when dev mode is on. No scene work for Bob.
- **Tests (Quinn):** changing `max_tap_rate` and `bottling_seconds_per_jar` through the panel's code path changes the next counted tap and the next jar; Save, restart (a new config load) and Reset round-trip; with `chill_bee/dev_mode` false, no panel node exists.

## Done when

- `Godot_v4.2.1-stable_win64_console.exe --headless --path game --quit-after 300` runs with no errors or warnings from these scripts.
- Quinn's unit tests in `game/tests/` pass. They keep the cost, fill, overflow, cell and bee-count tests, and replace the hold-mode, sell and taps tests with:
  - Every test reads its numbers from the config (e.g. `config.taps_per_frame`), never from literals, so changing a value in the config or Dev mode does not break a test. The figures below are at the default values.
  - taps per frame: 40 counted taps extract 10 jars and give `extraction_done`;
  - **tap cap:** 30 taps evenly spaced over 1 s (one per 1/30 s of `advance`) count as 5;
  - **hold at the cap:** a hold counts one turn on press, then `max_tap_rate` turns per second, and finishes a frame in `(taps_per_frame − 1) / max_tap_rate` s (≈ 7.8 s; ± one physics frame);
  - **hold never slower:** a held frame finishes no later than the same frame tapped at exactly `max_tap_rate`;
  - crank input is ignored in every state but `CRANKING`;
  - **Back:** after Back, the hive is still full (storage unchanged), the centrifuge is `EMPTY`, and the next open shows 35 Capped cells;
  - the fork icon is hidden while the centrifuge is not `EMPTY`, even with a full hive;
  - bottling: 10 jars in 10 × `bottling_seconds_per_jar`, each to the truck;
  - **truck:** 10 jars make it full and `can_sell()`; `sell()` credits $30 at once and sets `away`; jars bottled while away go to the crate; on return the crate loads onto the truck;
  - every new config value matches the Values table.
  - Each new test must be shown to fail for the right reason against a broken copy, as in the revision 2 report.
- `play_loop.gd` drives the loop 1 → 9 **twice through real input**, including one Worker Swarm Count purchase made while the centrifuge is cranking or bottling: clicks on the projected fork, centrifuge and Sell icons, a real drag to uncap, a Back press in round 1 before finishing, real taps and one real hold on the farm, Continue, the summary's OK, and a check that a click on the UpgradeButton during `CRANKING` does not count as a crank.
- **Uncapping pop, measured (open item #2):** with the close-up rendered mid-drag, sample the pixel colour at the centre of one capped and one uncapped cell and report both RGB values and their difference. The two must differ visibly. Report the numbers, not only "I read the image".
- **Layout (open items #3 to #5):** a screenshot of the farm in each state of the state table (6 shots: plus the truck away) shows every prop and icon clear of the ShopPanel and top info. Quinn reports the contrast ratio of the disabled Upgrade button text.
- 60 FPS on the farm while cranking, bottling and the truck driving, and in the close-up (desktop; Android still untested).
- A Windows export (`builds/windows/ChillBeeGame.exe`) starts clean. Quinn's report in `game/reports/` says what was run.
