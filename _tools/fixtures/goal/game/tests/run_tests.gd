extends SceneTree
const X1_TESTS: Array[String] = ["t_meter_wall_clock"]

func _run() -> void:
	var tests: Array[String] = [
		# economy (unchanged)
		"t_cost",
		# 9.9a meter (written from game/specs/9.9-fixture.md before the code)
		"t_meter_fill", "t_meter_wall_clock",
		# 9.9 item 2 (written from game/specs/9.9-fixture.md before the code)
		"t_tag_under_money",
	]
