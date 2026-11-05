extends "res://tests/test_hive.gd"

# Quinn: centrifuge tests, split from run_tests.gd 2026-11-05 (names unchanged). Each file extends the one before it.

# Done when, bucket: "cells go to the bucket until 2 x 35"; states EMPTY -> LOADING; capacity read live.
func t_bucket_capacity_and_states() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var cap: int = _bucket_cells()
	eq(c.get("state"), _st(c, "EMPTY"), "starts EMPTY")
	ck(c.call("has_room"), "EMPTY has room")
	eq(c.call("room_cells"), cap, "room_cells = centrifuge_capacity_frames x cells_per_frame (70)")
	eq(c.get("lid_open"), true, "EMPTY: lid off")
	eq(c.get("cells"), 0, "no cells yet")
	c.call("add_cells", 1, _jars_of(1))
	eq(c.get("state"), _st(c, "LOADING"), "one cell in, room left: LOADING")
	eq(c.call("room_cells"), cap - 1, "room_cells counts down")
	eq(c.get("lid_open"), true, "LOADING: lid still off")
	ck(c.call("has_room"), "LOADING has room")
	c.call("add_cells", cap - 1, _jars_of(cap - 1))
	eq(c.get("cells"), cap, "bucket holds cap cells")
	eq(c.call("room_cells"), 0, "no room left")
	ck(not c.call("has_room"), "full bucket has no room")
	near(float(c.get("jars")), _jars_of(cap), 1e-6, "jars = 4 for 70 cells")
	# the capacity is read live (Dev mode)
	var c2: Object = await _mk_cen()
	_set_cfg("centrifuge_capacity_frames", 1)
	eq(c2.call("room_cells"), _cpf(), "room_cells follows centrifuge_capacity_frames live")
	_fin()


# Done when, lid: close_lid() -> FULL, lid_open false, lid_moved(false); then begin_crank -> CRANKING.
func t_lid_close_and_signal() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var seen: Array = []
	c.connect("lid_moved", func(o: Variant) -> void: seen.append(bool(o)))
	c.call("add_cells", _cpf(), _jars_of(_cpf()))
	c.call("close_lid")
	eq(c.get("lid_open"), false, "lid on after close_lid()")
	eq(c.get("state"), _st(c, "FULL"), "a part-full bucket with its lid on waits as FULL (Spin shows)")
	ck(seen.size() > 0 and seen[seen.size() - 1] == false, "lid_moved(false) emitted (got %s)" % str(seen))
	eq(c.get("cells"), _cpf(), "closing the lid keeps the cells")
	c.call("begin_crank")
	eq(c.get("state"), _st(c, "CRANKING"), "begin_crank -> CRANKING")
	_fin()


# Done when, crank: ceil(jars x taps_per_jar) turns; 16 turns for 4 jars. Uses the integer cell count.
func t_turns_per_jar() -> void:
	var per_jar: int = int(cv("taps_per_jar"))
	var cases: Array = [_bucket_cells(), _cpf(), _cpf() + 1, 1]   # 4 jars, 2 jars, 2.057 jars, 2/35 jar
	for cells in cases:
		var c: Object = await _mk_cen()
		if c == null:
			_fin()
			return
		var want: int = _turns_for(cells)
		var done: Array = [0]
		c.connect("extraction_done", func() -> void: done[0] += 1)
		_to_cranking(c, cells)
		var cranking: int = _st(c, "CRANKING")
		var sent: int = 0
		while int(c.get("state")) == cranking and sent < want + 6:
			if not c.call("tap"):
				ck(false, "%d cells: a spaced tap was not counted" % cells)
			c.call("advance", _tap_gap())
			sent += 1
		eq(sent, want, "%d cells (%s jars): ceil(jars x taps_per_jar) turns" % [cells, str(_jars_of(cells))])
		_ext(c, "%d cells: DONE after the last turn" % cells)
		eq(done[0], 1, "%d cells: extraction_done once" % cells)
	var c4: Object = await _mk_cen()
	_to_cranking(c4)
	var n4: int = 0
	var cranking4: int = _st(c4, "CRANKING")
	while int(c4.get("state")) == cranking4 and n4 < 200:
		c4.call("tap")
		c4.call("advance", _tap_gap())
		n4 += 1
	eq(n4, int(roundf(_jars_of(_bucket_cells()))) * per_jar, "4 jars take 4 x taps_per_jar turns (16 at the defaults)")
	_fin()


# Contract: crank_enabled false (the zoom) stops every turn; true again counts.
func t_crank_enabled_flag() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	ck("crank_enabled" in c, "centrifuge.gd has crank_enabled (spec: Contract)")
	if not ("crank_enabled" in c):
		_fin()
		return
	eq(c.get("crank_enabled"), true, "crank_enabled defaults to true on the farm")
	_to_cranking(c)
	c.set("crank_enabled", false)
	ck(not c.call("tap"), "tap() ignored while crank_enabled is false")
	c.call("advance", 1.0)
	ck(not c.call("tap"), "still ignored a second later")
	c.call("set_holding", true)
	for i in 120:
		c.call("advance", 1.0 / 60.0)
	c.call("set_holding", false)
	eq(c.get("turns_counted"), 0, "no turn counted: not by tap, not by hold, while disabled")
	eq(c.get("state"), _st(c, "CRANKING"), "still CRANKING (cranking just stopped counting)")
	c.set("crank_enabled", true)
	c.call("advance", 1.0)
	ck(c.call("tap"), "tap() counts again once enabled")
	eq(c.get("turns_counted"), 1, "one turn counted")
	_fin()


# Table of states: crank input counts only in CRANKING (and then only unless zoomed). Real input in every state.
func t_crank_ignored_outside_cranking() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var burst: int = n * 3
	for i in burst:   # EMPTY
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "EMPTY: input counted nothing")
	eq(c.get("state"), _st(c, "EMPTY"), "EMPTY unchanged by input")
	c.call("add_cells", _cpf(), _jars_of(_cpf()))   # LOADING
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "LOADING: input counted nothing")
	eq(c.get("state"), _st(c, "LOADING"), "LOADING unchanged by input")
	c.call("add_cells", _bucket_cells() - _cpf(), _jars_of(_bucket_cells() - _cpf()))
	c.call("close_lid")   # FULL
	for i in burst:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("turns_counted"), 0, "FULL: input counted nothing")
	eq(c.get("state"), _st(c, "FULL"), "FULL unchanged by input (begin_crank starts cranking, not a tap)")
	c.call("begin_crank")   # CRANKING: positive control
	var cranking: int = _st(c, "CRANKING")
	for i in n + 5:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	_ext(c, "CRANKING: real clicks counted and finished the bucket (positive control)")
	var turns: Variant = c.get("turns_counted")
	for i in burst:   # DONE
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	_ext(c, "DONE unchanged by input")
	eq(c.get("turns_counted"), turns, "DONE: no extra turn")
	_begin_bottling(c)   # BOTTLING
	var bottling: int = _st(c, "BOTTLING")
	for i in 3:
		c.call("tap")
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	eq(c.get("state"), bottling, "BOTTLING unchanged by input")
	eq(c.get("turns_counted"), turns, "BOTTLING: no extra turn")
	_fin()


func t_real_mouse_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
		sent += 1
	eq(sent, n, "exactly ceil(jars x taps_per_jar) real clicks finish the bucket")
	_ext(c, "DONE")
	var c2: Object = await _mk_cen()
	_to_cranking(c2)
	for i in 15:
		_real_click(EMPTY_SPOT)
	ck(not c2.call("tap"), "15 real clicks in zero time were already counted once, so a 16th tap is capped")
	_fin()


func t_real_touch_taps_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var cranking: int = _st(c, "CRANKING")
	var sent: int = 0
	while int(c.get("state")) == cranking and sent < n * 2:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = EMPTY_SPOT * _to_window()
		root.push_input(down)
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = down.position
		root.push_input(up)
		c.call("advance", gap)
		sent += 1
	_ext(c, "touch taps finished the bucket (%d sent)" % sent)
	_fin()


func t_button_press_is_not_a_crank() -> void:
	var c: Object = await _mk_cen()
	if c == null:
		_fin()
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	var btn := Button.new()
	btn.position = Vector2(100.0, 900.0)
	btn.size = Vector2(300.0, 150.0)
	btn.text = "Upgrade"
	layer.add_child(btn)
	root.add_child(layer)
	_to_free.append(layer)
	await process_frame
	_to_cranking(c)
	var gap: float = _tap_gap()
	var n: int = _turns_for(_bucket_cells())
	var on_button: Vector2 = btn.get_global_rect().get_center()
	for i in n * 2:
		_real_click(on_button)
		c.call("advance", gap)
	eq(c.get("state"), _st(c, "CRANKING"), "clicks on a button did not crank")
	eq(c.get("turns_counted"), 0, "no turns from button clicks")
	var cranking: int = _st(c, "CRANKING")
	for i in n * 2:
		if int(c.get("state")) != cranking:
			break
		_real_click(EMPTY_SPOT)
		c.call("advance", gap)
	_ext(c, "clicks off the button finish the bucket (positive control)")
	_fin()


# ---------------------------------------------------------------- bottling
