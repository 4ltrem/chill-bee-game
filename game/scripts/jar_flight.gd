# Implements GDD 2 (Stage 2: bottling) for 0.1.2 (game/specs/0.1.2-bottling-and-sale.md, change 5): a jar flies along an arc, from the
# crate to the spigot, or from the spigot or crate onto the truck or back into the crate. Visual only: callers have already counted
# the jar and use on_land to reveal it where it arrives (same convention as CellFlight). Without the jar scene, or outside the tree,
# on_land still fires (at once outside the tree, on time otherwise). Loaded by preload (no class_name): no class cache refresh needed.
extends RefCounted

const JAR_SCENE_PATH := "res://scenes/props/jar.tscn"

static var _scene: PackedScene


## A jar instance (not in the tree), or null when jar.tscn is missing.
static func make_jar() -> Node3D:
	if _scene == null:
		if not ResourceLoader.exists(JAR_SCENE_PATH):
			CellFlight.warn_once(JAR_SCENE_PATH, "%s not found (Bob builds it): no jars are drawn." % JAR_SCENE_PATH)
			return null
		_scene = load(JAR_SCENE_PATH) as PackedScene
	return _scene.instantiate() as Node3D


## Flies a jar from `from` to `to` (world space) over `seconds` after `delay`. `full` draws it full with its lid (flying out) or
## empty (flying in). `jar_scale` is the drawn size (the world scale of the jars it flies between).
static func launch(host: Node, from: Vector3, to: Vector3, seconds: float, arc: float, delay: float, full: bool,
		jar_scale: float, on_land: Callable) -> void:
	if not host.is_inside_tree():
		if on_land.is_valid():
			on_land.call()
		return
	var tree: SceneTree = host.get_tree()
	var jar: Node3D = make_jar()
	if jar == null:
		var timer: SceneTreeTimer = tree.create_timer(maxf(delay + seconds, 0.001))
		timer.timeout.connect(func() -> void:
			if is_instance_valid(host) and on_land.is_valid():
				on_land.call())
		return
	var parent: Node = host   # the scene the host belongs to (its topmost node below the root), so the jar lives and dies with it
	while parent.get_parent() != null and parent.get_parent() != tree.root:
		parent = parent.get_parent()
	parent.add_child(jar)
	jar.visible = false
	jar.global_position = from
	jar.scale = Vector3.ONE * jar_scale
	JarFill.set_fraction(jar, 1.0 if full else 0.0)
	var tween: Tween = jar.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(jar.show)
	tween.tween_method(func(t: float) -> void:
		jar.global_position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t)), 0.0, 1.0, maxf(seconds, 0.001))
	tween.tween_callback(func() -> void:
		if is_instance_valid(host) and on_land.is_valid():
			on_land.call()
		jar.queue_free())


## One jar's whole trip at the spigot: it flies from `from` to `to` (empty), then fills over `fill_seconds` and gets its lid, and waits
## there until send() takes it onward. Returns the jar node (null if no jar scene or outside the tree: the caller then has no carrier).
static func fetch(host: Node, from: Vector3, to: Vector3, seconds: float, arc: float, delay: float, jar_scale: float,
		fill_seconds: float) -> Node3D:
	if not host.is_inside_tree():
		return null
	var jar: Node3D = make_jar()
	if jar == null:
		return null
	var parent: Node = host
	while parent.get_parent() != null and parent.get_parent() != host.get_tree().root:
		parent = parent.get_parent()
	parent.add_child(jar)
	jar.visible = false
	jar.global_position = from
	jar.scale = Vector3.ONE * jar_scale
	JarFill.set_fraction(jar, 0.0)
	var tween: Tween = jar.create_tween()
	jar.set_meta("trip_tween", tween)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(jar.show)
	tween.tween_method(func(t: float) -> void:
		jar.global_position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t)), 0.0, 1.0, maxf(seconds, 0.001))
	tween.tween_method(func(f: float) -> void: JarFill.set_fraction(jar, f), 0.0, 0.999, maxf(fill_seconds, 0.001))
	tween.tween_callback(func() -> void: JarFill.set_full(jar))
	return jar


## The jar from fetch() leaves from where it is to `to` after `delay` (full, with its lid), then on_land runs and it is freed.
static func send(host: Node, jar: Node3D, to: Vector3, seconds: float, arc: float, delay: float, to_scale: float,
		on_land: Callable) -> void:
	if not is_instance_valid(jar):
		if on_land.is_valid():
			on_land.call()
		return
	var old: Variant = jar.get_meta("trip_tween", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	JarFill.set_full(jar)
	jar.show()
	var from: Vector3 = jar.global_position
	var from_scale: float = jar.scale.x
	var tween: Tween = jar.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(func(t: float) -> void:
		jar.global_position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t))
		jar.scale = Vector3.ONE * lerpf(from_scale, to_scale, t), 0.0, 1.0, maxf(seconds, 0.001))
	tween.tween_callback(func() -> void:
		if is_instance_valid(host) and on_land.is_valid():
			on_land.call()
		jar.queue_free())
