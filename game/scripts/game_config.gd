# Implements GDD "Engine Integration" (balance values as data) and the Prototype 0 spec
# (game/specs/prototype-0.md, "Values" and "Dev mode"). One Resource holds every tunable value.
# Values marked "# PLACEHOLDER (GDD TBD)" are not decided in the GDD yet; do not treat them as balance.
# Scripts read these values when they use them (never cached), so Dev mode edits apply at once.
class_name GameConfig
extends Resource

# --- From the GDD (fixed) ---
@export var frame_jars: int = 10                       # one frame = 10 jars (GDD)
@export var overflow_frames: int = 1                   # free overflow buffer, in frames (GDD)
@export var swarm_fill_bonus_per_level: float = 0.15   # Worker Swarm Count, +15% fill rate per level (GDD Tree A). Documented GDD value; the fill multiplier derives from the bee count (bees_per_swarm_level / base_bee_count = 3 / 20 = 0.15)
@export var swarm_base_cost: float = 25.0              # GDD Tree A
@export var swarm_cost_growth: float = 1.18            # cost = base * growth^level (GDD Tree A)
@export var swarm_max_level: int = 10                  # GDD Tree A

# --- Placeholders (TBD in the GDD) ---
@export var base_seconds_per_jar: float = 6.0          # PLACEHOLDER (GDD TBD): 1 jar per 6 s, one frame in 60 s
@export var sale_value_per_jar: int = 3                # PLACEHOLDER (GDD TBD): $3 per jar
@export var taps_per_frame: int = 40                   # PLACEHOLDER (GDD TBD): counted crank turns for a full frame
@export var grid_cols: int = 7                         # PLACEHOLDER (GDD TBD): honeycomb frame width in cells (read when a frame is built)
@export var grid_rows: int = 5                         # PLACEHOLDER (GDD TBD): honeycomb frame height in cells (read when a frame is built)
@export var base_bee_count: int = 20                   # PLACEHOLDER (GDD TBD): bees in the swarm at level 0
@export var bees_per_swarm_level: int = 3              # PLACEHOLDER (GDD TBD): bees added per Worker Swarm Count level (15% of 20)
@export var visual_bee_cap: int = 60                   # PLACEHOLDER (GDD TBD): most bees drawn; GDD: visual cap TBD after profiling
@export var centrifuge_capacity_frames: int = 1        # PLACEHOLDER (GDD TBD): frames the centrifuge holds
@export var truck_capacity_jars: int = 10              # PLACEHOLDER (GDD TBD): jars the truck carries
@export var truck_trip_seconds: float = 30.0           # PLACEHOLDER (GDD TBD): seconds the truck is away after Sell
@export var bottling_seconds_per_jar: float = 3.0      # PLACEHOLDER (GDD TBD): seconds to bottle one jar
@export var max_tap_rate: float = 5.0                  # PLACEHOLDER (GDD TBD): most crank turns counted per second (tap or hold)
@export var hold_ramp_seconds: float = 1.5             # PLACEHOLDER (GDD TBD): seconds for the barrel to reach full spin when held (visual only)

# --- Visual and flow tuning (not balance; also in Dev mode) ---
@export var spin_impulse: float = 5.0                  # barrel spin added per counted turn (rad/s)
@export var spin_decay: float = 3.0                    # barrel spin lost per second when not cranked (rad/s^2)
@export var spin_max: float = 18.0                     # barrel spin cap (rad/s)
@export var slide_seconds: float = 0.3                 # frame slide-in and slide-out tween
@export var close_delay_seconds: float = 0.5           # pause after the frame slides away before the close-up closes
@export var truck_slide_distance: float = 25.0         # how far the truck drives off, in world units
@export var truck_slide_fraction: float = 0.25         # share of the trip spent driving off, and again coming back

const DEFAULT_PATH := "res://scripts/default_config.tres"
const DEV_PATH := "user://dev_config.tres"
const DEV_SETTING := "chill_bee/dev_mode"

static var _live: GameConfig


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
