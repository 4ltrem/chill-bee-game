extends "res://tests/test_tools.gd"

# Quinn: 0.3.2 item 17 (the branded web loading screen), written from game/specs/0.3.2-tests-and-quick-buy.md before the code.
# Static checks on files (a one-tap-free, stateless item): the preset and the shell.

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
# The exported index.html and the smoke shot need a web export, which a unit run can't make: moved to 0.3.3 item 17 (designer, 2026-11-26).
