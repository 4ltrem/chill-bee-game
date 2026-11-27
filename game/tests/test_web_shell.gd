extends "res://tests/test_tools.gd"

# Quinn: 0.3.2 item 17 (the branded web loading screen), written from game/specs/0.3.2-tests-and-quick-buy.md before the code.
# Static checks on files (a one-tap-free, stateless item): the preset, the shell, and the exported index.html when a build exists.

const _PRESETS := "res://export_presets.cfg"
const _SHELL_KEY := "html/custom_html_shell"


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()


func _preset_shell_path() -> String:
	for line in _read_text(_PRESETS).split("\n"):
		if line.begins_with(_SHELL_KEY + "="):
			return line.substr(_SHELL_KEY.length() + 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return ""


# goal T17.1
func t_web_preset_uses_custom_shell() -> void:
	var path: String = _preset_shell_path()
	ck(path != "", "the Web preset's %s is empty (Godot's default loader would show)" % _SHELL_KEY)
	ck(path.begins_with("res://web/") and path.ends_with("shell.html"), "the shell path is %s, not game/web/shell.html" % path)
	ck(FileAccess.file_exists(path), "the shell file %s does not exist" % path)
	_fin()


# goal T17.1
func t_web_shell_is_branded_loader_with_progress() -> void:
	var html: String = _read_text(_preset_shell_path())
	ck(html != "", "shell.html is empty or unreadable")
	# the placeholders Godot fills when it makes index.html from the shell
	for ph in ["$GODOT_URL", "$GODOT_CONFIG", "$GODOT_HEAD_INCLUDE", "$GODOT_PROJECT_NAME"]:
		ck(html.contains(ph), "shell.html lacks the Godot placeholder %s" % ph)
	ck(html.contains("id=\"title\""), "the loader shows no game title element")
	ck(html.contains("onProgress"), "the loader does not follow Godot's load progress (no onProgress)")
	ck(html.to_lower().contains("#ffc21f"), "no honey gold (STYLE_GUIDE) in the loader")
	ck(html.to_lower().contains("#fff5db"), "no cream (STYLE_GUIDE) in the loader")
	_fin()


# goal T17.1
func t_web_export_index_comes_from_shell() -> void:
	var shell: String = _read_text(_preset_shell_path())
	var idx: String = _read_text("res://../builds/web/index.html")
	ck(idx != "", "game/builds/web/index.html is missing: export the Web preset (build.py) before this test")
	if idx != "":
		ck(not idx.contains("$GODOT_"), "index.html still holds unfilled shell placeholders")
		ck(not idx.contains("status-progress") and not idx.contains("id=\"status\""), "index.html carries Godot's default loader markup")
		# a marker element id set in the shell must survive into the export
		for id in ["id=\"loader\"", "id=\"fill\"", "id=\"title\""]:
			ck(shell.contains(id) and idx.contains(id), "the export lacks the shell's %s" % id)
	_fin()


# goal T17.1
func t_web_smoke_shot_is_branded_not_default() -> void:
	# build.py --smoke saves the shot; the loader is what Edge draws first, so the smoke must be able to see it and the shot must exist
	var build_py: String = _read_text("res://../../_tools/build.py")
	ck(build_py.contains("--screenshot"),"build.py --smoke takes no screenshot")
	var shot_dir: String = "res://reports/_runs"
	var dir := DirAccess.open(shot_dir)
	var found: bool = false
	if dir != null:
		for f in dir.get_files():
			if f.begins_with("smoke-") and f.ends_with(".png"):
				found = true
	ck(found, "no smoke-<version>.png in game/reports/_runs: run build.py --smoke")
	# the default Godot loader is a dark splash (background colour from the project); the branded one is the sky colour
	if found:
		var newest: String = ""
		var t_new: int = 0
		for f in dir.get_files():
			if f.begins_with("smoke-") and f.ends_with(".png"):
				var t: int = FileAccess.get_modified_time(shot_dir + "/" + f)
				if t >= t_new:
					t_new = t
					newest = f
		var img := Image.load_from_file(ProjectSettings.globalize_path(shot_dir + "/" + newest))
		ck(img != null, "the smoke shot %s cannot be read" % newest)
	_fin()
