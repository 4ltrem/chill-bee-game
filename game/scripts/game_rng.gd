# Supports the 0.1.3 Input recorder (game/specs/0.1.3-next-revision.md, "Input recorder"): the one seeded random source for gameplay.
# Gameplay code that needs randomness calls GameRng.randf() / randi_range() / pick() and never the global randf()/randi(), so a replay
# that sets the same seed draws the same numbers. (No gameplay script draws random numbers yet; bee phases come from the index.)
class_name GameRng
extends RefCounted

static var _rng: RandomNumberGenerator = null
static var _initial_seed: int = 0


static func _ensure() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		var fixed: int = GameConfig.live().rng_seed
		if fixed != 0:
			set_seed(fixed)
		else:
			_rng.randomize()   # the engine picks the seed; no clock read in script
			set_seed(_rng.seed)   # saved as the seed actually used (the recorder stores it)
	return _rng


## Reseeds; the sequence restarts. The recorder and replays call this.
static func set_seed(seed_value: int) -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	_initial_seed = seed_value
	_rng.seed = seed_value


## The seed the current sequence started from (what a recording stores).
static func current_seed() -> int:
	_ensure()
	return _initial_seed


static func randf() -> float:
	return _ensure().randf()


static func randf_range(from: float, to: float) -> float:
	return _ensure().randf_range(from, to)


static func randi_range(from: int, to: int) -> int:
	return _ensure().randi_range(from, to)


static func pick(items: Array) -> Variant:
	return null if items.is_empty() else items[_ensure().randi_range(0, items.size() - 1)]
