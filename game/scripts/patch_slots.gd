# Implements 0.3 item 3 (game/specs/0.3-course-build.md): the six hidden wildflower patch slots in main.tscn.
# Node "PatchSlots" (Node3D, this script) holds the slots as children (instances of scenes/props/flower_patch.tscn), planted in child order.
# Everything follows Economy's "plant_patch" level (a shop buy, the skip icon and Dev mode all go through Economy.set_level):
# a newly reached level shows the next slot with the grow-in (scale 0 -> 1, the pop tween), adds it to group "flower_patch",
# adds habitat_health_per_patch to Health and asks for the toast. A lower level (Reset habitat) hides the slots again.
class_name PatchSlots
extends Node3D

## Asked once per planting step; the toast owner shows tr(key). Text is "toast_patch_planted" (content/course-ending-text.md).
signal toast_requested(key: String)
signal planted(count: int)

const TOAST_KEY: String = "toast_patch_planted"
const GROUP: String = "flower_patch"

var _slots: Array[Node3D] = []
var _rest: Array[Vector3] = []
var _shown: Array[bool] = []


func _ready() -> void:
	for child: Node in get_children():
		var slot := child as Node3D
		if slot == null:
			continue
		_slots.append(slot)
		_rest.append(slot.scale)
		_shown.append(false)
		slot.visible = false
		if slot.is_in_group(GROUP):
			slot.remove_from_group(GROUP)
	_sync(Economy.level("plant_patch"), false)
	Economy.upgrade_changed.connect(_on_upgrade_changed)


func slot_count() -> int:
	return _slots.size()


func planted_count() -> int:
	var n: int = 0
	for on: bool in _shown:
		if on:
			n += 1
	return n


func _on_upgrade_changed(id: String, level: int) -> void:
	if id == "plant_patch":
		_sync(level, true)


## Shows slots 0..level-1 and hides the rest. `animate` is false for the first sync (a loaded or restarted farm).
func _sync(level: int, animate: bool) -> void:
	var added: int = 0
	for i in _slots.size():
		var want: bool = i < level
		if want == _shown[i]:
			continue
		_shown[i] = want
		var slot: Node3D = _slots[i]
		if want:
			slot.visible = true
			slot.add_to_group(GROUP)
			if animate:
				added += 1
				slot.scale = Vector3.ZERO
				var tween: Tween = slot.create_tween()
				tween.tween_property(slot, "scale", _rest[i], Economy.config.patch_grow_seconds) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				slot.scale = _rest[i]
		else:
			slot.visible = false
			slot.scale = _rest[i]
			if slot.is_in_group(GROUP):
				slot.remove_from_group(GROUP)
	if added > 0:
		Economy.add_habitat(added * Economy.config.habitat_health_per_patch)
		toast_requested.emit(TOAST_KEY)
	planted.emit(planted_count())
