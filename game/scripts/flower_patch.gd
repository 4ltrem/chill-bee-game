# Implements GDD 1 (flower patches the bees forage on; group "flower_patch", found by bees.gd) for 0.1 Harvest
# (game/specs/0.1-harvest.md, "Models as reusable scenes"). The model is flower_patch.tscn: this script only applies the
# exported colour and radius to its PatchMesh, so one scene serves every patch (more colours, other biomes).
class_name FlowerPatch
extends Node3D

@export var color: Color = Color(0.97, 0.66, 0.78)
@export var radius: float = 0.9


func _ready() -> void:
	add_to_group("flower_patch")
	var patch: MeshInstance3D = find_child("PatchMesh", true, false) as MeshInstance3D
	if patch == null:
		CellFlight.warn_once("PatchMesh", "flower_patch.gd: no PatchMesh node (see game/specs/0.1-harvest.md, flower_patch.tscn).")
		return
	var cylinder: CylinderMesh = patch.mesh as CylinderMesh
	if cylinder != null:
		cylinder = cylinder.duplicate() as CylinderMesh   # the scene's mesh is shared between instances
		cylinder.top_radius = radius
		cylinder.bottom_radius = radius
		patch.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	patch.material_override = material
