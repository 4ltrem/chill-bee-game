# Implements 0.3.1 item 4 (game/specs/0.3.1-playtest-fixes.md): the first-time hint. `HintBubble` (FarmUIRoot) is a small panel with one
# line (HintBubbleLabel), a Skip button (HintSkipButton, key hint_skip) and a tail (HintTail) that points at the target of the current step.
# The hint follows the game's state, not a script of taps: each frame it shows the first step whose condition holds and that is not
# done. It starts once the welcome overlay is gone (play_pressed), ends for good when the first patch is planted or on Skip, and
# `config.show_hint` (read when used) turns it off. Texts are the hint_* rows of game/translations/journal.csv (content/first-time-hint.md).
# State pattern (PATTERNS.md): WAITING -> ACTIVE -> DONE through one _set_state. The bubble only reads game state; nothing here
# changes the game.
class_name HintBubble
extends Control

const MainScript := preload("res://scripts/main.gd")

enum State { WAITING, ACTIVE, DONE }
enum Step { NONE, WAIT, HARVEST, UNCAP, SPIN, CRANK, SELL, SHOP, PLANT }

## The translation key of each Step (index = Step value).
const STEP_KEYS: Array[String] = ["", "hint_wait", "hint_harvest", "hint_uncap", "hint_spin", "hint_crank", "hint_sell", "hint_shop", "hint_plant"]
const SKIP_KEY: String = "hint_skip"
const PLANT_ID: String = "plant_patch"
const DRAW_Z: int = 60   # above the Shop sheet (z 51) and its dim (z 50): hint_plant draws over the sheet
const TAIL_MIN_EDGE: float = 32.0   # the tail's half width (its polygon is 64 px wide): keeps it on the panel

var state: int = State.WAITING
var step: int = Step.NONE

var _main: Node
var _label: Label
var _skip: Button
var _tail: Polygon2D
var _tail_h: float = 44.0
var _nodes: Dictionary = {}          # name -> Node, looked up once and re-found when freed
var _blocked: Dictionary = {}        # source -> true: other panels that hide the bubble (e.g. the Tools sheet, item 8)
var _shown_key: String = ""
# progress seen this farm (a step is done once its outcome was seen; cleared by replay)
var _fork_seen: bool = false         # the Harvest icon has been pressable
var _spin_reached: bool = false      # the bucket has been full: Harvest and uncap are done
var _crank_started: bool = false     # the crank was started: Spin is done
var _crank_turned: bool = false      # a crank turn was counted: the crank step is done
var _sold: bool = false              # the first sale happened (a fact about the farm, kept by replay)


func _ready() -> void:
	z_index = DRAW_Z
	visible = false
	_label = find_child("HintBubbleLabel", true, false) as Label   # 0.3.1 item 7: HintLabel is the zoom's instruction (unique names)
	_skip = find_child("HintSkipButton", true, false) as Button
	_tail = find_child("HintTail", true, false) as Polygon2D
	if _tail != null:
		_tail_h = 0.0
		for p: Vector2 in _tail.polygon:
			_tail_h = maxf(_tail_h, p.y)
	if _skip != null:
		_skip.pressed.connect(skip)
	_main = owner
	var truck: Truck = _find("Truck") as Truck
	if truck != null:
		truck.departed.connect(func() -> void: _sold = true)
	Economy.upgrade_changed.connect(func(id: String, level: int) -> void:
		if id == PLANT_ID and level >= 1 and state != State.DONE:
			_set_state(State.DONE))


# --- state ---

func _set_state(next: int) -> void:
	if next == state:
		return
	if state == State.ACTIVE:   # exit: the bubble goes away
		_hide()
	state = next
	if next == State.ACTIVE:
		_shown_key = ""
	elif next == State.DONE:
		step = Step.NONE


## Skip (button): the hint ends for good.
func skip() -> void:
	_set_state(State.DONE)


## Dev "Replay hint": starts again at the step that fits where the player now is.
func replay() -> void:
	_fork_seen = false
	_spin_reached = false
	_crank_started = false
	_crank_turned = false
	state = State.WAITING
	step = Step.NONE
	_hide()


## Another panel (the Tools sheet) hides the bubble while `on`.
func set_blocked(source: StringName, on: bool) -> void:
	if on:
		_blocked[source] = true
	else:
		_blocked.erase(source)


## The translation key of the step showing now ("" when no bubble shows).
func step_key() -> String:
	return STEP_KEYS[step] if visible else ""


func _hide() -> void:
	visible = false
	step = Step.NONE
	_shown_key = ""


func _process(_delta: float) -> void:
	if _main == null or not _main.has_method("welcome_active"):
		return
	var cfg: GameConfig = Economy.config
	if state == State.DONE or not cfg.show_hint or bool(_main.call("welcome_active")):
		if visible:
			_hide()
		return
	if Economy.level(PLANT_ID) >= 1:
		_set_state(State.DONE)
		return
	if state == State.WAITING:
		_set_state(State.ACTIVE)
	_observe()
	var next: int = _current_step()
	if next == Step.NONE or _covered():
		if visible:
			_hide()
		return
	var target: Rect2 = _target_rect(next)
	if target.size == Vector2.ZERO:
		if visible:
			_hide()
		return
	step = next
	if _shown_key != STEP_KEYS[next]:
		_shown_key = STEP_KEYS[next]
		_apply_text()
	visible = true
	_place(target, cfg)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _label != null:
		_apply_text()


func _apply_text() -> void:
	if _label != null and step != Step.NONE:
		_label.text = tr(STEP_KEYS[step])
	if _skip != null:
		_skip.text = tr(SKIP_KEY)


# --- what the game is doing ---

func _find(node_name: String) -> Node:
	var cached: Node = _nodes.get(node_name) as Node
	if cached == null or not is_instance_valid(cached):
		cached = _main.find_child(node_name, true, false) if _main != null else null
		_nodes[node_name] = cached
	return cached


func _fork_available() -> bool:
	return bool(_main.call("fork_available"))


func _observe() -> void:
	if _fork_available():
		_fork_seen = true
	var c: Centrifuge = _find("Centrifuge") as Centrifuge
	if c == null:
		return
	if c.state >= Centrifuge.State.FULL:
		_spin_reached = true
		_fork_seen = true
	if c.state == Centrifuge.State.CRANKING:
		_crank_started = true
		if c.turns_counted > 0:
			_crank_turned = true


func _shop_open() -> bool:
	var shop: ShopUI = _find("ShopPanel") as ShopUI
	return shop != null and shop.is_sheet_open()


func _icon_shows(icon_name: String) -> bool:
	var icon: FloatingIcon = _find(icon_name) as FloatingIcon
	return icon != null and icon.is_wanted() and icon.is_visible_in_tree()


## Any open panel (main.gd any_panel_open(); the Shop sheet is left out, hint_plant shows over it), the victory overlay and any
## set_blocked() source hide the bubble.
func _covered() -> bool:
	if not _blocked.is_empty():
		return true
	if bool(_main.call("any_panel_open", true)):
		return true
	var victory: VictoryOverlay = _find("VictoryOverlay") as VictoryOverlay
	return victory != null and victory.is_showing()


## The first step whose condition holds and that is not done, in the spec's order; with the Shop sheet open only hint_plant.
func _current_step() -> int:
	if _shop_open():
		return Step.PLANT
	var zoom: int = int(_main.get("zoom"))
	var second: bool = bool(_main.call("at_second_stop"))
	var farm_view: bool = zoom == MainScript.Zoom.NONE and not second
	var fork_ok: bool = _fork_available()
	if not _fork_seen and farm_view and not fork_ok:
		return Step.WAIT
	if not _spin_reached and farm_view and fork_ok:
		return Step.HARVEST
	var hive: Hive = _find("Hive") as Hive
	if not _spin_reached and hive != null and hive.has_capped_cells() \
			and (zoom == MainScript.Zoom.OPENING or zoom == MainScript.Zoom.RISING or zoom == MainScript.Zoom.WORKING):
		return Step.UNCAP
	if not _crank_started and _icon_shows("CentrifugeIcon"):
		return Step.SPIN
	var c: Centrifuge = _find("Centrifuge") as Centrifuge
	if second and not _crank_turned and c != null and c.state == Centrifuge.State.CRANKING and c.turns_counted == 0:
		return Step.CRANK
	if not _sold and _icon_shows("SellIcon"):
		return Step.SELL
	if _sold and farm_view:
		return Step.SHOP
	return Step.NONE


## The screen rect of the step's target (zero size = nothing to point at, no bubble).
func _target_rect(which: int) -> Rect2:
	match which:
		Step.WAIT:
			return _control_rect("HiveCountLabel")
		Step.HARVEST:
			return _control_rect("ForkIcon")
		Step.UNCAP:
			return _point_rect(_find("Honeycomb") as Node3D)
		Step.SPIN:
			return _control_rect("CentrifugeIcon")
		Step.CRANK:
			return _point_rect(_find("Crank") as Node3D)
		Step.SELL:
			return _control_rect("SellIcon")
		Step.SHOP:
			return _control_rect("ShopButton")
		Step.PLANT:
			var tab: Control = _find("TabHabitat") as Control
			if tab != null and tab.is_visible_in_tree() and not (tab is BaseButton and (tab as BaseButton).button_pressed):
				return tab.get_global_rect()
			return _control_rect("Row_plant_patch")
	return Rect2()


func _control_rect(node_name: String) -> Rect2:
	var c: Control = _find(node_name) as Control
	if c == null or not c.is_visible_in_tree():
		return Rect2()
	return c.get_global_rect()


## A 3D anchor's screen position (as the floating icons place themselves), as a box of hint_point_radius_px around it.
func _point_rect(anchor: Node3D) -> Rect2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if anchor == null or camera == null or camera.is_position_behind(anchor.global_position):
		return Rect2()
	var r: float = Economy.config.hint_point_radius_px
	return Rect2(camera.unproject_position(anchor.global_position) - Vector2(r, r), Vector2(r, r) * 2.0)


# --- placing the bubble ---

## Above the target (tail down) when it fits, else below (tail flipped); inside the screen margins, never over the target or the
## toasts' place (PhaseToast), whose rect the bubble keeps clear of.
func _place(target: Rect2, cfg: GameConfig) -> void:
	var view: Vector2 = get_viewport_rect().size
	var m: float = cfg.button_screen_margin
	var gap: float = cfg.hint_gap_px + _tail_h
	var x: float = clampf(target.get_center().x - size.x * 0.5, m, maxf(view.x - m - size.x, m))
	var toast: Rect2 = _toast_rect()
	var above_y: float = target.position.y - gap - size.y
	var below_y: float = target.end.y + gap
	var y: float = above_y
	var below: bool = false
	if not _fits(Rect2(x, above_y, size.x, size.y), view, m, target, toast):
		if _fits(Rect2(x, below_y, size.x, size.y), view, m, target, toast):
			below = true
			y = below_y
		else:   # neither is clear: below the toasts' place, else the roomier side, kept on screen
			var under_toast: float = toast.end.y + cfg.hint_gap_px
			if toast.size != Vector2.ZERO and _fits(Rect2(x, under_toast, size.x, size.y), view, m, target, toast):
				y = under_toast
				below = under_toast >= target.end.y
			else:
				below = view.y - target.end.y > target.position.y
				y = below_y if below else above_y
	y = clampf(y, m, maxf(view.y - m - size.y, m))
	global_position = Vector2(x, y)
	if _tail != null:
		_tail.visible = true
		var tx: float = clampf(target.get_center().x - x, TAIL_MIN_EDGE, maxf(size.x - TAIL_MIN_EDGE, TAIL_MIN_EDGE))
		_tail.position = Vector2(tx, 0.0 if below else size.y)
		_tail.scale = Vector2(1.0, -1.0 if below else 1.0)


func _fits(box: Rect2, view: Vector2, m: float, target: Rect2, toast: Rect2) -> bool:
	if box.position.y < m or box.end.y > view.y - m:
		return false
	return not box.intersects(target) and not (toast.size != Vector2.ZERO and box.intersects(toast))


func _toast_rect() -> Rect2:
	var toast: Control = _find("PhaseToast") as Control
	if toast == null or toast.size == Vector2.ZERO:
		return Rect2()
	return toast.get_global_rect()
