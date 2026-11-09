# Implements GDD 3 (Progression Trees) for 0.2 (game/specs/0.2-first-automation.md, items 3-5 looks): reads an upgrade's level
# from the Economy autoload's generic table (item 1: Economy.level(id)) without a compile-time dependency, so props can show levels.
class_name UpgradeLevel
extends RefCounted


## Level of upgrade `id` ("gearing", "faster_delivery", "heated_fork"); 0 when Economy has no such table yet.
static func of(id: String) -> int:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return 0
	var economy: Node = loop.root.get_node_or_null("Economy")
	if economy != null and economy.has_method("level"):
		return int(economy.call("level", id))
	return 0
