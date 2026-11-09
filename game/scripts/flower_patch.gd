# Implements GDD 1 (flower patches the bees forage on; group "flower_patch", found by bees.gd) for 0.1 Harvest
# (game/specs/flower-patch-b.md, "Changes" 2 and "Contract"). The model is flower_patch.tscn (Base, Stems, Blossoms):
# this script applies the exported colour to every blossom head and the exported radius as a horizontal scale, so one
# scene serves every patch (more colours, other biomes).
class_name FlowerPatch
extends Node3D

## Radius the prop scene was authored at: a constant of the model, not a tunable.
const AUTHORED_RADIUS: float = 0.9

@export var color: Color = Color(0.97, 0.66, 0.78)
@export var radius: float = 0.9


func _ready() -> void:
	add_to_group("flower_patch")
	var k: float = radius / AUTHORED_RADIUS
	var base: MeshInstance3D = find_child("Base", true, false) as MeshInstance3D
	var stems: Node3D = find_child("Stems", true, false) as Node3D
	var blossoms: Node3D = find_child("Blossoms", true, false) as Node3D
	if base == null:
		CellFlight.warn_once("FlowerPatch.Base", "flower_patch.gd: no Base node (see game/specs/flower-patch-b.md, Contract).")
	else:
		base.scale = Vector3(base.scale.x * k, base.scale.y, base.scale.z * k)
	if stems == null:
		CellFlight.warn_once("FlowerPatch.Stems", "flower_patch.gd: no Stems node (see game/specs/flower-patch-b.md, Contract).")
	else:
		_scale_children_xz(stems, k)
	if blossoms == null:
		CellFlight.warn_once("FlowerPatch.Blossoms", "flower_patch.gd: no Blossoms node (see game/specs/flower-patch-b.md, Contract).")
		return
	var material := StandardMaterial3D.new()   # one per patch instance; the shared flower_default.tres is never touched
	material.albedo_color = color
	for child: Node in blossoms.get_children():
		var head: MeshInstance3D = child as MeshInstance3D
		if head != null:
			head.material_override = material
	_scale_children_xz(blossoms, k)


func _scale_children_xz(parent: Node3D, k: float) -> void:
	for child: Node in parent.get_children():
		var node: Node3D = child as Node3D
		if node != null:
			node.position = Vector3(node.position.x * k, node.position.y, node.position.z * k)
