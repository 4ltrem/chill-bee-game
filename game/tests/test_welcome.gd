extends "res://tests/test_shop_zoom.gd"

# Quinn: 0.3 item 1 (Welcome screen), written from game/specs/0.3-course-build.md before the code.
# Every tap is a real mouse event in window pixels (farm_input.gd); every wait is read from the config (base_seconds_per_jar, frame_jars).
# Shared steps live here once: _wl_launch (a launch with show_welcome true), _wl_play_button, _wl_idle_world, _wl_play_and_fill.

const WELCOME_TITLE := "Chill Bee Game"


func _wl_overlay(m: Node) -> Node:
	var ov: Node = m.find_child("WelcomeOverlay", true, false)
	return ov if ov != null and is_instance_valid(ov) and not ov.is_queued_for_deletion() else null


## A launch with show_welcome true: the config value is set (and restored by _cleanup) before the scene is instanced.
func _wl_launch() -> Node:
	_set_cfg("show_welcome", true)
	return await _mk_main()


## The visible Buttons under the overlay (the spec: one, Play).
func _wl_buttons(ov: Node) -> Array:
	var out: Array = []
	for b in ov.find_children("*", "BaseButton", true, false):
		if (b as Control).is_visible_in_tree():
			out.append(b)
	return out


func _wl_texts(ov: Node) -> Array:
	var out: Array = []
	for c in ov.find_children("*", "Control", true, false):
		if not (c as Control).is_visible_in_tree():
			continue
		if c is Label:
			out.append((c as Label).text)
		elif c is Button:
			out.append((c as Button).text)
		elif c is TextureRect or c is RichTextLabel:
			out.append("<%s>" % c.get_class())   # an icon or a text block: the spec allows neither
	return out


## Game seconds that would put several cells into the hive at multiplier 1 (the bees only ever make it faster).
func _wl_wait_s() -> float:
	return _cell_secs() * 4.0 + 0.5


func _wl_storage(m: Node) -> float:
	return float(_nn(m, "Hive").get("storage"))


## The world is idle: no hive fill over the wait, and real taps on the farm (hive, fork icon, Spin icon) do nothing.
func _wl_idle_world(m: Node, label: String) -> void:
	var hive: Node = _nn(m, "Hive")
	var cam: Camera3D = _cam()
	var zoom0: int = int(m.get("zoom"))
	var money0: Variant = _eco().get("money")
	var spots: Array[Vector2] = [fi.screen_rect(hive, cam).get_center()]
	for nm in ["ForkIcon", "CentrifugeIcon", "SellIcon"]:
		var ic: Control = _nn(m, nm) as Control
		if ic != null:
			spots.append(ic.get_global_rect().get_center())
	for s in spots:
		await fi.tap_at(s)
	await _wait(_wl_wait_s())
	near(_wl_storage(m), 0.0, 0.0001, "%s: the hive did not fill while the welcome overlay was up" % label)
	eq(int(m.get("zoom")), zoom0, "%s: a tap on the farm did not open a zoom" % label)
	eq(_eco().get("money"), money0, "%s: a tap on the farm did not change the money" % label)
	ck(_wl_overlay(m) != null, "%s: a tap on the farm did not remove the overlay" % label)


## Real tap on Play, then the overlay is gone, the farm UI shows and the hive fills.
func _wl_play_and_fill(m: Node, label: String) -> void:
	var ov: Node = _wl_overlay(m)
	var bs: Array = _wl_buttons(ov)
	if bs.size() != 1:
		ck(false, "%s: exactly one Play button to tap" % label)
		return
	await fi.tap_at((bs[0] as Control).get_global_rect().get_center())
	await _frames(3)
	ck(_wl_overlay(m) == null or not (_wl_overlay(m) as CanvasItem).visible, "%s: after Play the overlay is gone" % label)
	var ui: Node = m.find_child("FarmUI", true, false)
	ck(ui != null and (ui as CanvasItem).is_visible_in_tree(), "%s: after Play the farm UI shows" % label)
	var hive: Node = _nn(m, "Hive")
	var ok: bool = await _until(func() -> bool: return float(hive.get("storage")) > 0.0, _wl_wait_s() * 3.0)
	ck(ok, "%s: after Play the hive fills" % label)


# goal T1.2
func t_welcome_shows_title_and_play_only() -> void:
	var m: Node = await _wl_launch()
	if m == null:
		_fin()
		return
	var ov: Node = _wl_overlay(m)
	ck(ov != null, "a WelcomeOverlay node exists in main.tscn when show_welcome is true")
	if ov == null:
		_fin()
		return
	ck(ov is CanvasLayer, "the overlay is a CanvasLayer inside main.tscn, not a separate scene")
	ck(ov.scene_file_path == "", "the overlay is not a separate scene instance")
	var texts: Array = _wl_texts(ov)
	ck(texts.has(WELCOME_TITLE), "the title '%s' shows (got %s)" % [WELCOME_TITLE, str(texts)])
	var bs: Array = _wl_buttons(ov)
	eq(bs.size(), 1, "exactly one button shows: Play")
	if bs.size() == 1:
		eq((bs[0] as Button).text, tr("welcome_play"), "the button text is tr('welcome_play')")
		ck((bs[0] as Button).text != "welcome_play", "the key welcome_play is translated, not shown raw")
	eq(texts.size(), 2, "nothing else on the overlay: title and Play only (got %s)" % str(texts))
	_fin()


# goal T1.2
func t_welcome_world_idle_then_play_twice() -> void:
	for pass_i in 2:
		var label: String = "launch %d" % (pass_i + 1)
		var m: Node = await _wl_launch()
		if m == null:
			_fin()
			return
		ck(_wl_overlay(m) != null, "%s: the overlay is up at launch" % label)
		await _wl_idle_world(m, label)
		await _wl_play_and_fill(m, label)
		_cleanup_main(m)
	_fin()


## Tear one launch down inside a test so a second launch starts clean (the same free-and-forget _cleanup does at the end).
func _cleanup_main(m: Node) -> void:
	if is_instance_valid(m):
		if m.is_inside_tree():
			m.get_parent().remove_child(m)
		_to_free.erase(m)
		m.free()
	_eco_reset()


# goal T1.1
func t_welcome_off_by_default_in_tests() -> void:
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	eq(bool(cv("show_welcome")), false, "a test run starts with show_welcome false")
	ck(_wl_overlay(m) == null or not (_wl_overlay(m) as CanvasItem).visible, "no overlay shows when show_welcome is false")
	ck(_wl_storage(m) >= 0.0, "storage readable")
	await _wait(_wl_wait_s())
	ck(_wl_storage(m) > 0.0, "with show_welcome false the world runs: the hive fills")
	var def: Variant = GameConfig.fresh_default()
	ck(def != null and bool(def.get("show_welcome")), "the shipped default of show_welcome is true")
	_fin()


# goal T1.2
func t_welcome_play_text_translated_title_not() -> void:
	var loc0: String = TranslationServer.get_locale()
	var m: Node = await _wl_launch()
	if m == null:
		_fin()
		return
	var ov: Node = _wl_overlay(m)
	if ov == null:
		ck(false, "overlay present")
		_fin()
		return
	TranslationServer.set_locale("en")
	eq(tr("welcome_play"), "Play", "en: welcome_play is Play")
	TranslationServer.set_locale("fr")
	eq(tr("welcome_play"), "Jouer", "fr: welcome_play is Jouer")
	await _frames(2)
	ck(_wl_texts(ov).has(WELCOME_TITLE), "fr: the title stays '%s' (not translated)" % WELCOME_TITLE)
	TranslationServer.set_locale(loc0)
	_fin()
