# Implements GDD 2 (Stage 2: bottling) for 0.1.1 (game/specs/0.1.1-playtest-fixes.md, change 5).
# Draws how full a jar.tscn instance is: JarHoney is stretched between the JarHoneyBottom and JarHoneyTop markers (the same convention
# as the bucket's HoneyLevel: a mesh of height 1 scaled in Y, centred between the markers), and JarLid shows only when the jar is full.
# Truck and crate jars call set_full once; the spigot jar calls set_fraction every frame.
class_name JarFill
extends RefCounted


## fraction 0 (empty, no lid) to 1 (full, lid on).
static func set_fraction(jar: Node3D, fraction: float) -> void:
	if jar == null:
		return
	var level: float = clampf(fraction, 0.0, 1.0)
	var honey: Node3D = jar.get_node_or_null("JarHoney") as Node3D
	var bottom: Node3D = jar.get_node_or_null("JarHoneyBottom") as Node3D
	var top: Node3D = jar.get_node_or_null("JarHoneyTop") as Node3D
	if honey != null and bottom != null and top != null:
		honey.visible = level > 0.001
		var height: float = maxf(level * (top.position.y - bottom.position.y), 0.001)
		honey.scale.y = height
		honey.position.y = bottom.position.y + height * 0.5
	var lid: Node3D = jar.get_node_or_null("JarLid") as Node3D
	if lid != null:
		lid.visible = level >= 1.0


## A full jar with its lid on (truck and crate jars).
static func set_full(jar: Node3D) -> void:
	set_fraction(jar, 1.0)
