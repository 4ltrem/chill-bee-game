# Quinn: shared REAL-INPUT helpers for milestone 0.1 (Harvest), used by run_tests.gd, play_loop.gd and r4_measure.gd.
# Events are pushed into the root viewport in WINDOW pixels, as a real mouse sends them (the window is smaller than the
# 720 x 1280 canvas under canvas_items stretch). Written from game/specs/0.1-harvest.md only; it names no script internals:
# cells are found as the visible collision objects under the node named "Honeycomb".
# Usage: var fi = load("res://tests/farm_input.gd").new(tree)
extends RefCounted

var tree: SceneTree
var root: Window


func _init(t: SceneTree) -> void:
	tree = t
	root = t.root


func to_window() -> Vector2:
	return Vector2(root.size) / root.get_visible_rect().size


func mouse_button(vp_pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos * to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(ev)


func mouse_move(vp_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = vp_pos * to_window()
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(ev)


func click_at(vp_pos: Vector2) -> void:
	mouse_button(vp_pos, true)
	await tree.process_frame
	mouse_button(vp_pos, false)
	await tree.process_frame


## A tap with no frame between press and release (0.1.1). A windowed run also receives the REAL OS cursor's motion events at frame
## boundaries; one of them between a pushed press and release moves the Button's press out of it and cancels `pressed` (headless
## reproduction: the intermittent fork miss of 0.1.0). Hover first (a motion onto the target, as a real mouse arrives), then press and
## release in the same call, so no engine frame can slip a foreign event in between.
func tap_at(vp_pos: Vector2) -> void:
	mouse_move_free(vp_pos)
	mouse_button(vp_pos, true)
	mouse_button(vp_pos, false)
	await tree.process_frame


func mouse_move_free(vp_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = vp_pos * to_window()
	ev.global_position = ev.position
	ev.button_mask = 0
	root.push_input(ev)


func click_ctl(ctl: Control) -> void:
	await click_at(ctl.get_global_rect().get_center())


## Click a floating icon where its anchor projects on screen (unproject_position(anchor) + screen_offset), clamped 6 px
## inside the icon's rect. Returns whether the projected point really lies within 6 px of the rect (the icon follows its
## anchor); the click is made either way so the caller can also see the effect.
func click_icon(icon: Control) -> bool:
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var anchor: Node3D = null
	var ap: Variant = icon.get("anchor_path")
	if ap != null:
		anchor = icon.get_node_or_null(ap) as Node3D
	var rect: Rect2 = icon.get_global_rect()
	if anchor == null or cam == null:
		await tap_at(icon.get_global_rect().get_center())
		return false
	var projected: Vector2 = cam.unproject_position(anchor.global_position) + (icon.get("screen_offset") as Vector2)
	var near_rect: bool = rect.grow(6.0).has_point(projected)
	var inside := Vector2(clampf(projected.x, rect.position.x + 6.0, rect.end.x - 6.0), clampf(projected.y, rect.position.y + 6.0, rect.end.y - 6.0))
	await tap_at(inside)
	return near_rect


## True if a press at p would be taken by a visible Control under `scope` that stops mouse presses.
func blocked(scope: Node, p: Vector2) -> bool:
	for c in scope.find_children("*", "Control", true, false):
		var ctl: Control = c as Control
		if ctl.is_visible_in_tree() and ctl.mouse_filter == Control.MOUSE_FILTER_STOP and ctl.get_global_rect().has_point(p):
			return true
	return false


## A free spot of the screen where a tap reaches _unhandled_input.
func free_spot(scope: Node) -> Vector2:
	for p in [Vector2(360.0, 640.0), Vector2(360.0, 520.0), Vector2(200.0, 480.0), Vector2(520.0, 480.0), Vector2(360.0, 760.0), Vector2(120.0, 700.0)]:
		if not blocked(scope, p):
			return p
	return Vector2(360.0, 640.0)


## The visible collision objects under the Honeycomb node: one per drawn cell (the spec names no cell nodes).
func cells(hc: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in hc.find_children("*", "CollisionObject3D", true, false):
		if (n as Node3D).is_visible_in_tree():
			out.append(n as Node3D)
	return out


## Cell centres on screen grouped into rows (top to bottom, each left to right).
## 0.1.1: the frame stands upright with its face normal along world +X, so rows no longer share a SCREEN y under the isometric camera
## (the screen y slants along the row). Rows are grouped by WORLD height instead (cells of one row share a world y on an upright frame;
## a new row starts when the gap in y is more than half the largest gap), and each row is sorted by screen x. `row_gap` is kept for
## the old call sites and ignored.
func rows(hc: Node, cam: Camera3D, _row_gap: float = 11.0) -> Array:
	var items: Array = []   # [world_y, screen point]
	for c in cells(hc):
		items.append([c.global_position.y, cam.unproject_position(c.global_position)])
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var max_gap: float = 0.0
	for i in range(1, items.size()):
		max_gap = maxf(max_gap, float((items[i - 1] as Array)[0]) - float((items[i] as Array)[0]))
	var out: Array = []
	var cur: Array[Vector2] = []
	for i in items.size():
		if cur.size() > 0 and float((items[i - 1] as Array)[0]) - float((items[i] as Array)[0]) > max_gap * 0.5 and max_gap > 0.01:
			out.append(cur)
			cur = []
		cur.append((items[i] as Array)[1])
	if cur.size() > 0:
		out.append(cur)
	for r in out:
		(r as Array).sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return out


## Real mouse drag along one row: press on the first cell, one motion event per frame, release at the last.
func drag_row(row: Array) -> void:
	var first: Vector2 = row[0]
	var last: Vector2 = row[row.size() - 1]
	mouse_button(first, true)
	await tree.process_frame
	var steps: int = maxi(row.size() * 3, 4)
	for s in range(1, steps + 1):
		mouse_move(first.lerp(last, float(s) / float(steps)))
		await tree.process_frame
	mouse_button(last, false)
	await tree.process_frame


## The same drag as a finger (ScreenTouch + ScreenDrag through Input, like a phone).
func drag_row_touch(row: Array) -> void:
	var first: Vector2 = row[0] * to_window()
	var last: Vector2 = row[row.size() - 1] * to_window()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = first
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	await tree.process_frame
	var steps: int = maxi(row.size() * 3, 4)
	var prev: Vector2 = first
	for s in range(1, steps + 1):
		var p: Vector2 = first.lerp(last, float(s) / float(steps))
		var mv := InputEventScreenDrag.new()
		mv.index = 0
		mv.position = p
		mv.relative = p - prev
		prev = p
		Input.parse_input_event(mv)
		Input.flush_buffered_events()
		await tree.process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = last
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await tree.process_frame


## Number of Capped cells (state 0) of one hive frame, read through hive.frame_cells(i) (spec: PackedByteArray).
static func capped(hive: Node, i: int) -> int:
	var arr: PackedByteArray = hive.call("frame_cells", i)
	var k: int = 0
	for b in arr:
		if b == 0:
			k += 1
	return k


static func capped_total(hive: Node, frames: int) -> int:
	var k: int = 0
	for i in frames:
		k += capped(hive, i)
	return k


## Projected on-screen rectangle (viewport pixels) of every mesh under `node`, merged: the AABB corners through the camera.
func screen_rect(node: Node, cam: Camera3D) -> Rect2:
	var have: bool = false
	var r := Rect2()
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)   # find_children only searches descendants: a leaf mesh passed in must count itself (r4_measure defect, 2026-11-04)
	for m in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var aabb: AABB = mi.mesh.get_aabb()
		for i in 8:
			var corner: Vector3 = mi.global_transform * aabb.get_endpoint(i)
			var p: Vector2 = cam.unproject_position(corner)
			if not have:
				r = Rect2(p, Vector2.ZERO)
				have = true
			else:
				r = r.expand(p)
	return r


## The equivalent of pressing "Reset to defaults" in the Dev panel, for a test run: deletes user://dev_config.tres if one exists
## (a stale Dev mode file would override the default_config.tres values) and puts the live config back to the defaults.
## Returns true if a stale file was found (the caller prints it, so the report can say so).
static func reset_dev_config() -> bool:
	var found: bool = FileAccess.file_exists(GameConfig.DEV_PATH)
	if found:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameConfig.DEV_PATH))
	GameConfig.apply_from(GameConfig.live(), GameConfig.fresh_default())
	return found
