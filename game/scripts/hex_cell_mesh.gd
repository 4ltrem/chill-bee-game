# Implements 0.1.4 item 14 align (game/specs/0.1.4-ui-placement.md): the honeycomb cell's hexagonal prism with its own 30 degree turn
# built into the vertices (corners on the x axis, flat sides facing z), so the node carries no yaw and the mesh's bounding box is
# tight (x = 2 radius, z = 1.732 radius). Same look as the old CylinderMesh (6 segments, radius 0.34, height 0.3) turned 30 degrees.
class_name HexCellMesh
extends ArrayMesh

var radius: float = 0.34   # keep equal to the cell's CollisionShape3D radius in honey_cell.tscn
var height: float = 0.3


func _init() -> void:
	_build()


func _build() -> void:
	clear_surfaces()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var hh: float = height * 0.5
	var corners: Array[Vector2] = []
	for k in 6:
		var a: float = float(k) * PI / 3.0
		corners.append(Vector2(cos(a), sin(a)) * radius)
	# top and bottom caps: a fan around a centre vertex
	for cap in 2:
		var y: float = hh if cap == 0 else -hh
		var n: Vector3 = Vector3.UP if cap == 0 else Vector3.DOWN
		var base: int = verts.size()
		verts.append(Vector3(0.0, y, 0.0))
		norms.append(n)
		uvs.append(Vector2(0.5, 0.5))
		for k in 6:
			verts.append(Vector3(corners[k].x, y, corners[k].y))
			norms.append(n)
			uvs.append(Vector2(0.5 + corners[k].x / (2.0 * radius), 0.5 + corners[k].y / (2.0 * radius)))
		for k in 6:
			var a: int = base + 1 + k
			var b: int = base + 1 + (k + 1) % 6
			if cap == 0:
				idx.append_array([base, a, b])
			else:
				idx.append_array([base, b, a])
	# six flat sides
	for k in 6:
		var c0: Vector2 = corners[k]
		var c1: Vector2 = corners[(k + 1) % 6]
		var mid: Vector2 = (c0 + c1).normalized()
		var n: Vector3 = Vector3(mid.x, 0.0, mid.y)
		var base: int = verts.size()
		verts.append(Vector3(c0.x, hh, c0.y))
		verts.append(Vector3(c1.x, hh, c1.y))
		verts.append(Vector3(c1.x, -hh, c1.y))
		verts.append(Vector3(c0.x, -hh, c0.y))
		for i in 4:
			norms.append(n)
		uvs.append_array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)])
		# front faces wind clockwise seen from outside: top (k+1), top k, bottom k, then bottom (k+1)
		idx.append_array([base + 1, base, base + 3, base + 1, base + 3, base + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
