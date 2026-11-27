# Implements 0.3.2 item 7 (game/specs/0.3.2-tests-and-quick-buy.md): a preview on every upgrade row and on the QuickBuy bar.
# Item 14: fills Bob's `PreviewTile` with a TextureRect showing assets/icons/upgrades/<id>.png (made by _tools/model_snap.py).
# No live SubViewport. A tile with no PNG is hidden (no white square).
class_name PreviewTile
extends RefCounted

const TILE: String = "PreviewTile"
const IMAGE: String = "PreviewImage"
const DIR: String = "res://assets/icons/upgrades/"
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
	var path: String = DIR + upgrade_id + ".png"
	tile.set_meta("preview_id", upgrade_id)
	var image: TextureRect = tile.find_child(IMAGE, false, false) as TextureRect
	if not ResourceLoader.exists(path):
		# no PNG yet (swarm, flight, auto_sell wait for the Milo vote): no white square
		tile.visible = false
		if image != null:
			image.texture = null
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		tile.visible = false
		return
	tile.visible = true
	if tile is Panel:   # drop the white panel fill so only the picture shows
		tile.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if image == null:
		image = TextureRect.new()
		image.name = IMAGE
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile.add_child(image)
	image.texture = tex
