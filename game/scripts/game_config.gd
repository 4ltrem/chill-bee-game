# Implements GDD "Engine Integration" (balance values as data) and the Prototype 0 spec
# (game/specs/prototype-0.md, "Values"). One Resource holds every tunable value.
# Values marked "# PLACEHOLDER (GDD TBD)" are not decided in the GDD yet; do not treat them as balance.
class_name GameConfig
extends Resource

# --- From the GDD (fixed) ---
@export var frame_jars: int = 10                       # one frame = 10 jars (GDD)
@export var overflow_frames: int = 1                   # free overflow buffer, in frames (GDD)
@export var swarm_fill_bonus_per_level: float = 0.15   # Worker Swarm Count, +15% fill rate per level (GDD Tree A)
@export var swarm_base_cost: float = 25.0              # GDD Tree A
@export var swarm_cost_growth: float = 1.18            # cost = base * growth^level (GDD Tree A)
@export var swarm_max_level: int = 10                  # GDD Tree A

# --- Placeholders (TBD in the GDD) ---
@export var base_seconds_per_jar: float = 6.0          # PLACEHOLDER (GDD TBD): 1 jar per 6 s, one frame in 60 s
@export var sale_value_per_jar: int = 3                # PLACEHOLDER (GDD TBD): $3 per jar
@export var taps_per_frame: int = 20                   # PLACEHOLDER (GDD TBD): centrifuge taps for a full frame (2 per jar)
@export var hold_taps_per_second: float = 4.0          # PLACEHOLDER (GDD TBD): No-Rapid-Tap hold rate, taps' worth per second
@export var grid_cols: int = 7                         # PLACEHOLDER (GDD TBD): honeycomb frame width in cells
@export var grid_rows: int = 5                         # PLACEHOLDER (GDD TBD): honeycomb frame height in cells

const DEFAULT_PATH := "res://scripts/default_config.tres"


static func load_default() -> GameConfig:
	return load(DEFAULT_PATH) as GameConfig
