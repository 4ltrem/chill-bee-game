extends "res://tests/test_habitat.gd"

# Quinn: 0.3 item 5 (victory screen), written from game/specs/0.3-course-build.md item 5. Numbers from the config: victory_delay_seconds.


func _vic_overlay(m: Node) -> Node:
	return m.find_child("VictoryOverlay", true, false)


func _vic_shown(o: Node) -> bool:
	return o != null and o.has_method("is_showing") and bool(o.call("is_showing"))


func _vic_diag(o: Node, m: Node) -> String:
	return "diag: _queued %s, _wait %s, farm_view_idle() %s" % [o.get("_queued"), o.get("_wait"), m.call("farm_view_idle")]


## Make Health thrive on a fresh farm (emits `thriving`).
func _vic_thrive() -> void:
	var e: Node = _eco()
	e.call("reset")
	e.call("add_habitat", int(cv("habitat_health_max")) * 3)


## After `thriving` and victory_delay_seconds on the farm view the overlay shows; the real tap on its button closes it; once per farm; a new farm shows it again.
# goal T5.1
func t_victory_delay_show_close_once_per_farm() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var o: Node = _vic_overlay(m)
	ck(o != null, "VictoryOverlay exists in main.tscn")
	if o == null:
		_fin()
		return
	var title: Label = o.find_child("VictoryTitle", true, false) as Label
	var body: Label = o.find_child("VictoryBody", true, false) as Label
	var btn: Button = o.find_child("VictoryButton", true, false) as Button
	ck(title != null and body != null and btn != null, "title, body and one button exist")
	var delay: float = float(cv("victory_delay_seconds"))
	eq(_vic_shown(o), false, "step start: hidden before thriving")
	_vic_thrive()
	await _frames(3)
	eq(_vic_shown(o), false, "step delay: not shown at once after thriving; diag: delay %s" % delay)
	var ok: bool = await _until(func() -> bool: return _vic_shown(o), delay * 3.0 + 2.0)
	ck(ok, "step show: shown after victory_delay_seconds on the farm view")
	if not ok or btn == null:
		_fin()
		return
	ck(title != null and title.text != "" and title.text != "victory_title", "step text: the title is a translated string; diag: '%s'" % (title.text if title != null else ""))
	ck(btn.text != "" and btn.text != "victory_button", "step text: the button is a translated string; diag: '%s'" % btn.text)
	await fi.tap_at(btn.get_global_rect().get_center())
	await _frames(3)
	eq(_vic_shown(o), false, "step close: a real tap on the button closes it; diag: btn rect %s" % btn.get_global_rect())
	e_thrive_again_once(o)
	var again: bool = await _until(func() -> bool: return _vic_shown(o), delay * 1.5 + 1.0)   # real seconds: at least the delay in game time at any time scale
	eq(again, false, "step once: never again for the same farm; diag: queued %s, scale %s" % [o.call("is_queued"), Engine.time_scale])
	_vic_thrive()
	var ok2: bool = await _until(func() -> bool: return _vic_shown(o), delay * 3.0 + 2.0)
	ck(ok2, "step twice: a new farm shows it again")
	_eco().call("reset")
	_fin()


## `thriving` fires once per farm in Economy, so emit it again directly: the overlay's own once-per-farm guard must ignore it.
func e_thrive_again_once(_o: Node) -> void:
	_eco().call("add_habitat", int(cv("habitat_health_max")))
	_eco().emit_signal("thriving")


## The victory waits while a sheet or a zoom is up, then shows when the player is back on the farm view.
# goal T5.1
func t_victory_waits_for_farm_view() -> void:
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		_fin()
		return
	var o: Node = _vic_overlay(m)
	var panel: Node = m.find_child("ShopPanel", true, false)
	ck(o != null and panel != null and panel.has_method("set_sheet_open"), "overlay and Shop panel exist")
	if o == null or panel == null:
		_fin()
		return
	var delay: float = float(cv("victory_delay_seconds"))
	panel.call("set_sheet_open", true)
	await _frames(3)
	_vic_thrive()
	await _wait(delay + 1.0)   # game seconds (the overlay counts scaled delta), not frames: frames can run faster than real time
	eq(_vic_shown(o), false, "step sheet: not shown while the Shop sheet is open; %s" % _vic_diag(o, m))
	panel.call("set_sheet_open", false)
	var ok: bool = await _until(func() -> bool: return _vic_shown(o), 3.0)
	ck(ok, "step back: shown once the sheet is closed")
	if o.has_method("close"):
		o.call("close")
	_eco().call("reset")
	var zc: Dictionary = m.get_script().get_script_constant_map()
	var working: int = int(zc["Zoom"]["WORKING"]) if zc.has("Zoom") else 3
	var was: int = int(m.get("zoom"))
	m.set("zoom", working)
	_vic_thrive()
	await _wait(delay + 1.0)
	eq(_vic_shown(o), false, "step zoom: not shown while a zoom is in progress; %s" % _vic_diag(o, m))
	m.set("zoom", was)
	var ok2: bool = await _until(func() -> bool: return _vic_shown(o), 3.0)
	ck(ok2, "step zoom out: shown once the zoom is over")
	_eco().call("reset")
	_fin()
