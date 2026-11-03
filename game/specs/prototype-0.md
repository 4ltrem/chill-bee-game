---
author: designer
type: spec
status: approved
description: Prototype 0, the manual core loop in Sunny Meadow as a colorbox (primitive shapes and flat colours, no audio)
decided: 2026-11-03
decision: approved as the first prototype; colorbox only, no sound
---
# Prototype 0: the manual core loop (colorbox)

**Sources:** `GDD.md` (1. Primary Game Loop & Phase Structure; 2. Phase 1 Uncapping & Extraction Minigame; 3. Progression Trees, Tree A and Tree B; 8. Accessibility; 9. UI & Screens; Engine Integration; Technical Constraints).

The first playable piece of Chill Bee Game: one hive in Sunny Meadow, harvested by hand, honey sold, the first upgrade bought, and round again. It is the loop the onboarding script (`content/onboarding-script.md`) walks a new player through.

## Look: colorbox

- Primitive meshes and flat colours only (`BoxMesh`, `CylinderMesh`, `PlaneMesh`, `SphereMesh`, `StandardMaterial3D` albedo colours). No imported models, textures or audio.
- Sunny Meadow: a pastel-green ground plane; the hive a tan box; bees small yellow spheres orbiting between the hive and two or three flower patches (coloured cylinders). Use `MultiMeshInstance3D` for the bees.
- Honeycomb cells: hexagonal prisms (`CylinderMesh` with `radial_segments = 6`). Capped: matte yellow. Uncapped: glowing gold (emission). Extracted: pale, near-empty. Cells must also differ in shape or height, not colour alone (GDD Accessibility: colour-blind support), e.g. capped cells raised, uncapped flush, extracted recessed.
- Isometric orthographic camera as in `scenes/main.tscn`. Portrait 720×1280, the project's existing settings.

## The loop

1. **Bees forage, hive fills.** Hive storage rises over time toward capacity (one frame: 10 jars, GDD). The farm view shows a fill bar, and a **bee counter** ("Bees: 20"): the GDD's Bee Rendering Plan shows swarm size with a counter. The swarm has a size: the fill rate scales with the bee count, and the farm shows one flying bee per bee in the count, up to a visual cap (above the cap, the counter keeps rising while the flock stays at the cap; GDD: "Only a capped crowd of bees is drawn").
2. **Hive full → harvest.** A "Harvest" button appears. Production continues into a free overflow buffer of one extra frame (GDD); when that is full too, production pauses.
3. **Stage 1, uncapping.** The camera (or a sub-view) shows one frame of hex cells. Dragging the mouse or a finger across cells uncaps them (state 0 → 1), using `PhysicsDirectSpaceState3D` raycasts from the drag onto the cells' collision shapes (GDD Engine Integration). Uncapped cells show the visual change and a simple scale "pop" (no particles, no sound). When every cell is uncapped, uncapping stops and a large **"Extract honey"** button appears (with the hint "All cells uncapped!"); stage 2 opens only when the player presses it, never automatically. *(Revised 2026-11-03 after the designer played it: the jump straight to the centrifuge felt abrupt.)*
4. **Stage 2, centrifuge.** A cylinder (the barrel) spins faster with each tap of a "Crank" button; each required tap moves honey into jars, shown as a jar counter. With **No-Rapid-Tap Mode** on (GDD Accessibility), holding the button cranks at a steady rate instead.
5. **Batch summary.** A modal lists jars, base value per jar, and the batch total (tool and quality bonuses are 0 in this prototype). Cells become Extracted (state 2).
6. **Sell.** A "Sell" button at the market stand converts jars to money.
7. **Upgrade.** An Upgrade Shop panel with one item, **Worker Swarm Count**: it **adds bees** (GDD Tree A: "Adds active foraging bees"), and the extra bees give the +15% fill rate per level. Cost `25 × 1.18^level`, max level 10. On purchase the bee counter rises and the new bees visibly join the flock; the bees' flying speed does not change (that is Flight Endurance, out of scope). The button shows the next cost and is disabled when unaffordable or at max. *(Revised 2026-11-03: the first build kept 12 bees whatever the level, so the upgrade read as "faster" rather than "more bees".)*
8. Round again. The next harvest resets the frame's cells to Capped.

Out of scope: other upgrades, automation, grid expansion, biomes, Habitat, pests and nectar drops, offline earnings, the guide character and dialogue, saving, localisation, monetisation.

## Values

From the GDD: frame 10 jars; overflow buffer 1 frame; Worker Swarm Count +15%/level, base $25, ×1.18, max 10.

Placeholders (TBD in the GDD; keep them as exported variables in one config resource, each marked `# PLACEHOLDER (GDD TBD)`):

| Value | Placeholder | Why this number |
|---|---|---|
| base fill rate | 1 jar per 6 s (one frame in 60 s) | a first harvest within a minute of starting |
| sale value per jar | $3 | the first Worker Swarm Count ($25) after about one frame |
| taps per frame in the centrifuge | 20 (2 per jar) | a short, tactile stage |
| No-Rapid-Tap hold rate | 4 taps' worth per second | about 5 s per frame |
| honeycomb frame size | 7 × 5 cells | readable at portrait size |
| base swarm | 20 bees | a flock that reads as busy at portrait size |
| bees per Worker Swarm Count level | +3 (15% of 20) | so the count and the +15% fill rate agree: fill multiplier = bees ÷ base swarm |
| visual bee cap | 60 drawn bees | well inside the 60 FPS budget; GDD: visual cap TBD after profiling |

## Contract between scripts and scenes

Patricia writes the scripts; Bob writes the scenes that use them; Quinn tests both. Node names and signals below are the contract: keep them exactly, or update this file and say so.

| Script (`game/scripts/`) | Responsibility | Public API |
|---|---|---|
| `game_config.gd` | `Resource` with every value above as `@export` vars | — |
| `economy.gd` | autoload `Economy`: money, jars, Worker Swarm Count level, cost formula | `money`, `jars`, `swarm_level`, `bee_count()`, `fill_multiplier()`, `swarm_cost()`, `can_buy_swarm()`, `buy_swarm()`, `sell_jars()`; signals `money_changed`, `jars_changed`, `swarm_level_changed` |
| `hive.gd` | storage, overflow, fill over time | `storage`, `overflow`, `capacity`, `is_full()`, `take_frame() -> int`; signals `storage_changed`, `became_full` |
| `honeycomb.gd` | the cell grid as a byte array (`0 = Capped`, `1 = Uncapped`, `2 = Extracted`), builds the cell meshes, handles drag raycasts | `reset()`, `uncap_at(cell)`, `all_uncapped()`, `extract_all()`; signal `all_cells_uncapped` |
| `centrifuge.gd` | taps, hold mode, spin speed, jar output | `start(jars)`, `crank()`, `hold_mode`; signals `jar_filled`, `batch_done(jars)` |
| `farm_ui.gd`, `harvest_ui.gd`, `shop_ui.gd` | the UI panels, wired to the signals above | `harvest_ui.gd`: `show_stage1_done()`, signals `extract_pressed`, `continue_pressed` |
| `main.gd` | switches between farm view and harvest, owns the flow 1 → 8 | — |

Scenes (`game/scenes/`): `main.tscn` (replace the placeholder; Farm view with hive, bees, flowers, UI), `harvest.tscn` (honeycomb frame + centrifuge + harvest UI). Scenes attach scripts by path and hold no logic (Bob's rule).

## Done when

- `Godot_v4.2.1-stable_win64_console.exe --headless --path game --quit-after 300` runs with no errors or warnings from these scripts.
- Quinn's tests in `game/tests/` pass: cost formula, fill multiplier, overflow and pause, cell state transitions, taps per frame, hold mode, sell.
- A Windows export (`builds/windows/ChillBeeGame.exe`) plays the loop 1 → 8 at least twice, including one Worker Swarm Count purchase, at 60 FPS. Quinn's report in `game/reports/` says what was run.

## Node paths for Bob

Written by Patricia. Scripts find their child controls with `find_child(name, true, false)`, so **node names are the contract and the nesting (containers, margins, layout) is yours**. Names must be unique within each scene. Scripts attach by path; no logic in the scenes. Project autoload `Economy` is already registered in `project.godot`. Extra script beyond the contract table: `bees.gd` (the bee MultiMesh, visual only).

### `main.tscn`

```
Main                      Node3D                 script: res://scripts/main.gd
  WorldEnvironment        WorldEnvironment       (as in the placeholder)
  Sun                     DirectionalLight3D     (as in the placeholder)
  Camera3D                Camera3D               direct child of Main, isometric ortho as in the placeholder, current = true
  FarmWorld               Node3D                 main.gd hides this whole node during the harvest
    Ground                MeshInstance3D         pastel-green PlaneMesh
    Hive                  Node3D                 script: res://scripts/hive.gd; add to group "bee_home"; tan BoxMesh as a child
    Flowers               Node3D
      FlowerPatch1..3     Node3D                 add each to group "flower_patch"; coloured CylinderMesh child
    Bees                  MultiMeshInstance3D    script: res://scripts/bees.gd (builds its own MultiMesh; leave multimesh empty), at origin of FarmWorld
  FarmUIRoot              CanvasLayer
    FarmUI                Control (full rect)    script: res://scripts/farm_ui.gd
      MoneyLabel          Label                  text set by script ("$0")
      JarsLabel           Label                  "Jars: n"
      FillBar             ProgressBar            show_percentage off; max/value set by script
      FillLabel           Label                  "Hive: n / 10"
      BeeCountLabel       Label                  "Bees: 20"; text set by script (Economy.bee_count()); in the farm's top info. Revised 2026-11-03
      PausedLabel         Label                  your text, e.g. "Hive full, production paused"; hidden by default
      HarvestButton       Button                 text "Harvest"; hidden by default (script shows it when the hive is full)
      SellButton          Button                 text set by script; this is the market stand's sell action
      ShopPanel           Control / PanelContainer  script: res://scripts/shop_ui.gd (the Upgrade Shop panel)
        LevelLabel        Label                  text set by script
        UpgradeButton     Button                 text and disabled state set by script
```

Nesting under `FarmUI` is free (use containers). `ShopPanel` may sit anywhere below `FarmUI`; it must be a descendant of `FarmUI` so it hides with it. Use `mouse_filter = Ignore` on full-rect containers so the buttons are the only blockers.

No @export vars need setting in `main.tscn` (the `config` exports default to `res://scripts/default_config.tres`).

### `harvest.tscn`

Instanced by `main.gd` from `res://scenes/harvest.tscn` and freed after the summary.

```
Harvest                   Node3D                 no script
  Camera3D                Camera3D               its own ortho camera framing the 7x5 frame (about 7 x 4.5 units, flat on the XZ plane, so look down at it, e.g. top-down or steep tilt); main.gd calls make_current() on it
  Light                   DirectionalLight3D     optional
  Backdrop                MeshInstance3D         optional flat-colour plane under the frame
  Honeycomb               Node3D                 script: res://scripts/honeycomb.gd; place at the origin; the script builds its 35 hex cells and collision shapes in _ready (do not add cells)
  Centrifuge              Node3D                 script: res://scripts/centrifuge.gd; place so the camera sees it (the script builds the barrel around its origin, radius 1.4, height 1.8; main.gd hides it until stage 2 and hides Honeycomb then)
  HarvestUIRoot           CanvasLayer
    HarvestUI             Control (full rect)    script: res://scripts/harvest_ui.gd
      Stage1Panel         Control                a hint Label (e.g. "Drag across the cells to uncap them"; the script swaps its text to "All cells uncapped!" when done) plus ExtractButton; visible at start
        ExtractButton     Button                 text "Extract honey"; large, thumb-sized (min height about 120 px, anchored low on the screen); hidden by default; script shows it when all cells are uncapped and emits extract_pressed. Revised 2026-11-03
      Stage2Panel         Control                hidden by default
        JarCounterLabel   Label                  set by script ("Jars: 3 / 10")
        TapProgressBar    ProgressBar            optional, set by script (jars filled)
        CrankButton       Button                 text "Crank"; large, thumb-sized
        NoRapidTapCheck   CheckButton            text "No-Rapid-Tap Mode" (accessibility: hold to crank)
      SummaryModal        PanelContainer         hidden by default; a centred modal
        SummaryJarsLabel  Label                  set by script
        SummaryValueLabel Label                  set by script ("Value per jar: $3")
        SummaryTotalLabel Label                  set by script ("Batch total: $30")
        ContinueButton    Button                 text "Continue"; returns to the farm
```

Notes for Bob:
- The honeycomb's cells are raycast from the camera returned by `get_viewport().get_camera_3d()`, so `Harvest/Camera3D` must see all cells and nothing with a collider may sit between it and the frame.
- `ExtractButton` is the one control in Stage1Panel that must receive clicks: keep `mouse_filter = Stop` on the button itself (the default) and `Ignore` on Stage1Panel, its containers and the hint Label; the button is hidden during the drag, so it never blocks uncapping. The script takes the first Label under Stage1Panel as the hint, so put no other Label there.
- `HarvestUI` must not cover the frame with a mouse-blocking control during stage 1 (drags are read in `_unhandled_input`): keep Stage1Panel and its parents at `mouse_filter = Ignore`.
- No @export vars need setting in `harvest.tscn`.
- The farm and harvest scenes both need an environment/light; the harvest scene shares the Main `WorldEnvironment` because it is instanced under Main.
