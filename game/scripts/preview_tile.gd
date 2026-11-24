# Implements 0.3.2 item 7 (game/specs/0.3.2-tests-and-quick-buy.md): a preview on every upgrade row and on the QuickBuy bar.
# Fills Bob's `PreviewTile` (a Control, not a Button) with res://scenes/props/previews/<file>.tscn, drawn once in a SubViewport
# (render_target_update_mode UPDATE_ONCE, never every frame). A model Bob has not promoted yet leaves the tile empty.
class_name PreviewTile
extends RefCounted

const TILE: String = "PreviewTile"
const VIEWPORT: String = "PreviewViewport"
const IMAGE: String = "PreviewImage"
const DIR: String = "res://scenes/props/previews/"
const PX: int = 144   # 144 x 144 at 720 x 1280 (placeholder; the designer confirms at play-test)
const FILES: Dictionary = {   # Economy upgrade id -> preview file (spec item 7 ids)
	"swarm": "swarm", "flight": "flight_endurance", "heated_fork": "heated_fork", "gearing": "centrifuge_gearing",
	"spigot_flow": "spigot_flow", "faster_delivery": "faster_delivery", "auto_sell": "auto_sell", "plant_patch": "wildflower_patch",
}


## Draws `upgrade_id`'s model into `tile` once. Safe to call again: the same id is a no-op, a new id re-renders once.
static func fill(tile: Control, upgrade_id: String) -> void:
	if tile == null or not FILES.has(upgrade_id):
		return
	if str(tile.get_meta("preview_id", "")) == upgrade_id:
		return
	var path: String = DIR + str(FILES[upgrade_id]) + ".tscn"
	if not ResourceLoader.exists(path):
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var old: Node = tile.find_child(VIEWPORT, false, false)
	if old != null:
		tile.remove_child(old)
		old.queue_free()
	var vp := SubViewport.new()
	vp.name = VIEWPORT
	vp.size = Vector2i(PX, PX)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var model: Node = packed.instantiate()
	vp.add_child(model)
	if model is Node3D:
		var cam := Camera3D.new()
		cam.position = Vector3(0.0, 0.6, 2.4)
		cam.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
		vp.add_child(cam)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
		vp.add_child(sun)
	tile.add_child(vp)   # a SubViewport child draws nothing itself; the TextureRect shows its texture
	var image: TextureRect = tile.find_child(IMAGE, false, false) as TextureRect
	if image == null:
		image = TextureRect.new()
		image.name = IMAGE
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile.add_child(image)
	image.texture = vp.get_texture()
	tile.set_meta("preview_id", upgrade_id)
