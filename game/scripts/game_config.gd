# Implements GDD "Engine Integration" (balance values as data) and the Prototype 0 spec
# (game/specs/prototype-0.md, "Values" and "Dev mode"). One Resource holds every tunable value.
# Values marked "# PLACEHOLDER (GDD TBD)" are not decided in the GDD yet; do not treat them as balance.
# Scripts read these values when they use them (never cached), so Dev mode edits apply at once.
class_name GameConfig
extends Resource

# --- From the GDD (fixed) ---
@export var frames_per_hive: int = 5                   # PLACEHOLDER (GDD TBD): frames in the hive body (designer: 4-5; read when the hive is built)
@export var frame_jars: int = 2                        # jars per frame at base (GDD 2, 3: 2 jars per frame, 10 per full hive)
@export var overflow_hives: int = 1                    # free overflow buffer, in full hives (GDD 2: one extra full hive)
@export var swarm_fill_bonus_per_level: float = 0.15   # Worker Swarm Count, +15% fill rate per level (GDD Tree A). Documented GDD value; the fill multiplier derives from the bee count (bees_per_swarm_level / base_bee_count = 3 / 20 = 0.15)
@export var swarm_base_cost: float = 25.0              # GDD Tree A
@export var swarm_cost_growth: float = 1.18            # cost = base * growth^level (GDD Tree A)
@export var swarm_max_level: int = 10                  # GDD Tree A

# --- Placeholders (TBD in the GDD) ---
@export var base_seconds_per_jar: float = 6.0          # PLACEHOLDER (GDD TBD): 1 jar per 6 s, one frame in 60 s
@export var sale_value_per_jar: int = 3                # PLACEHOLDER (GDD TBD): $3 per jar
@export var taps_per_jar: int = 4                      # PLACEHOLDER (GDD TBD): counted crank turns per jar in the bucket (40 per 10 jars as revision 3)
@export var grid_cols: int = 7                         # PLACEHOLDER (GDD TBD): honeycomb frame width in cells (read when a frame is built)
@export var grid_rows: int = 5                         # PLACEHOLDER (GDD TBD): honeycomb frame height in cells (read when a frame is built)
@export var base_bee_count: int = 20                   # PLACEHOLDER (GDD TBD): bees in the swarm at level 0
@export var bees_per_swarm_level: int = 3              # PLACEHOLDER (GDD TBD): bees added per Worker Swarm Count level (15% of 20)
@export var visual_bee_cap: int = 60                   # PLACEHOLDER (GDD TBD): most bees drawn; GDD: visual cap TBD after profiling
@export var centrifuge_capacity_frames: int = 2        # PLACEHOLDER (GDD TBD): frames' worth of cells the bucket holds (designer; a hand-crank extractor takes 2 deep frames)
@export var truck_capacity_jars: int = 10              # PLACEHOLDER (GDD TBD): jars the truck carries
@export var truck_trip_seconds: float = 30.0           # PLACEHOLDER (GDD TBD): seconds the truck is away after Sell
@export var bottling_seconds_per_jar: float = 3.0      # PLACEHOLDER (GDD TBD): seconds to bottle one jar
@export var jar_lid_seconds: float = 0.25             # PLACEHOLDER (GDD TBD; 0.1.1, Patricia): how long the spigot jar shows full with its lid on before the next jar (visual only)
@export var max_tap_rate: float = 5.0                  # PLACEHOLDER (GDD TBD): most crank turns counted per second (tap or hold)
@export var hold_ramp_seconds: float = 1.5             # PLACEHOLDER (GDD TBD): seconds for the barrel to reach full spin when held (visual only)

@export var jar_fly_seconds: float = 0.5               # PLACEHOLDER (GDD TBD; 0.1.2): a jar's flight, crate to spigot and spigot to truck or crate
@export var crate_empty_jars_shown: int = 10           # PLACEHOLDER (GDD TBD; 0.1.2): empty jars drawn in the crate (the supply is unlimited)

# --- Visual and flow tuning (not balance; also in Dev mode) ---
@export var spin_impulse: float = 5.0                  # barrel spin added per counted turn (rad/s)
@export var spin_decay: float = 3.0                    # barrel spin lost per second when not cranked (rad/s^2)
@export var spin_max: float = 18.0                     # barrel spin cap (rad/s)
@export var slide_seconds: float = 0.3                 # a frame rising or sinking by frame_rise
@export var close_delay_seconds: float = 0.5           # pause after the frame slides away before the close-up closes
@export var truck_slide_distance: float = 25.0         # how far the truck drives off, in world units
@export var truck_slide_fraction: float = 0.25         # share of the trip spent driving off, and again coming back

# --- 0.1 Harvest (game/specs/0.1-harvest.md, "Values"): the zoom, lids, flying cells, piles, icons ---
@export var zoom_seconds: float = 0.6                  # PLACEHOLDER (GDD TBD): the camera's zoom in and out
@export var lid_lift_height: float = 0.6               # PLACEHOLDER (GDD TBD; 0.1.1): how far a lid rises straight up before it falls (parent-space units)
@export var lid_lift_seconds: float = 0.25             # PLACEHOLDER (GDD TBD; 0.1.1): the lift
@export var lid_drop_seconds: float = 0.4              # PLACEHOLDER (GDD TBD): the fall after the lift, hive lid and centrifuge lid, off or on (closing plays backwards)
@export var frame_rise: float = 0.76                   # PLACEHOLDER (GDD TBD; 0.1.1: Bob's new value to come): how far a frame rises above the body (hive root units)
@export var cell_fly_seconds: float = 0.5              # PLACEHOLDER (GDD TBD): a scraped cell's flight after its pop
@export var cell_fly_arc: float = 1.5                  # PLACEHOLDER (GDD TBD; Patricia): arc height of a cell's flight, in units
@export var pile_load_stagger_seconds: float = 0.03    # PLACEHOLDER (GDD TBD; Patricia): delay between pile cells flying into the bucket
@export var icon_visual_px: int = 88                   # visible icon size; the touch area stays at least 120 (GDD 8)
@export var min_cell_px: int = 44                      # the smallest cell allowed on screen at the zoom (a check, not a look tunable)
@export var zoom_size: float = 2.4                     # PLACEHOLDER (GDD TBD; 0.1.1: Bob's tighter value to come): camera ortho size at the zoom (Bob's value from ZoomFraming metadata); 0 = read that metadata instead

const DEFAULT_PATH := "res://scripts/default_config.tres"
const DEV_PATH := "user://dev_config.tres"
const DEV_SETTING := "chill_bee/dev_mode"

static var _live: GameConfig


## Cells in one frame (the grid, read when used).
func cells_per_frame() -> int:
	return grid_cols * grid_rows


## Jars one cell is worth: frame_jars / cells_per_frame (2 / 35 at base).
func cell_value() -> float:
	return float(frame_jars) / float(maxi(cells_per_frame(), 1))


## Seconds a lid takes to open or close: the lift plus the fall.
func lid_move_seconds() -> float:
	return maxf(lid_lift_seconds, 0.0) + maxf(lid_drop_seconds, 0.0)


## Cells the centrifuge bucket holds when full.
func bucket_capacity_cells() -> int:
	return centrifuge_capacity_frames * cells_per_frame()


## True when the custom project setting chill_bee/dev_mode is on (Dev mode spec).
static func dev_mode_enabled() -> bool:
	return bool(ProjectSettings.get_setting(DEV_SETTING, false))


## A new config load: a fresh copy of default_config.tres. With Dev mode on, user://dev_config.tres is laid over it;
## with Dev mode off that file is ignored. Not shared: scripts that need the live values use live().
static func load_default() -> GameConfig:
	var cfg: GameConfig = fresh_default()
	if dev_mode_enabled() and FileAccess.file_exists(DEV_PATH):
		var saved: GameConfig = ResourceLoader.load(DEV_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GameConfig
		if saved != null:
			apply_from(cfg, saved)
	return cfg


## The one shared live config (the same instance as Economy.config). Every script holds it, and Dev mode edits it,
## so an edit is seen everywhere at once. Loaded on first use through load_default().
static func live() -> GameConfig:
	if _live == null:
		_live = load_default()
	return _live


## A fresh copy of default_config.tres without any Dev mode overlay (the numbers Dev mode shows as defaults).
static func fresh_default() -> GameConfig:
	return ResourceLoader.load(DEFAULT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GameConfig


## Models a restart for the live config: reloads it in place from the defaults and the saved dev file.
static func reload_live() -> GameConfig:
	apply_from(live(), load_default())
	return live()


## Names of every exported value, in declaration order (the rows of the Dev mode panel).
static func value_names(cfg: GameConfig) -> PackedStringArray:
	var names := PackedStringArray()
	for prop in cfg.get_property_list():
		if (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (int(prop["usage"]) & PROPERTY_USAGE_EDITOR) != 0:
			names.append(String(prop["name"]))
	return names


## Copies every exported value from source onto target.
static func apply_from(target: GameConfig, source: GameConfig) -> void:
	for value_name in value_names(target):
		target.set(value_name, source.get(value_name))
