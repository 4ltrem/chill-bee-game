extends "res://tests/test_web_shell.gd"

# Quinn: shared steps of the 0.3.2 item 2 tests (game/specs/0.3.2-tests-and-quick-buy.md), written before the code, from the spec's node names only:
# SettingsButton, SettingsPanel, SettingsDim, ComingSoonLabel, HarvestFill, SpinGlyph, HabitatPill, SkipIcon, ShopButton, ShopPanel, Tab<Name>.
# Every tap is a real mouse event in the viewport (farm_input.gd); every number comes from the config, the scene or the translation table.

const PT_CIRCLE_DETAIL: int = 24      # spec item 2: "corner_detail >= 24"
const PT_TAB_FONT: int = 28           # spec item 2: "each tab's text fits its button at 28 px" (V12)
const PT_MIN_CONTRAST: float = 3.0    # WCAG large-text ratio; the 28 px sheet text is large text; white on cream is about 1.1
const PT_TAB_KEYS: Array[String] = ["Bees", "Hive", "Habitat", "Research", "Refinery"]   # the node suffixes of the five tabs (spec 0.3.1 item 3)

var _pt_locale: String = ""


func _cleanup() -> void:
	super._cleanup()
	if _pt_locale != "":
		TranslationServer.set_locale(_pt_locale)
		_pt_locale = ""


## Switch the UI language ("en" / "fr"); the first call remembers the language the run started in, _cleanup puts it back.
func _pt_lang(code: String) -> void:
	if _pt_locale == "":
		_pt_locale = TranslationServer.get_locale()
	TranslationServer.set_locale(code)


## The farm view at the phone's portrait size, English, a fresh scene; null when it did not load.
func _pt_farm() -> Node:
	_portrait()
	_pt_lang("en")
	return await _mk_main()


## A real tap on a control's centre, then a few frames for the reaction.
func _pt_tap(c: Control) -> void:
	await fi.tap_at(c.get_global_rect().get_center())
	await _frames(3)


## Open the Shop sheet with a real tap on ShopButton; false when the sheet did not open.
func _pt_open_shop(m: Node) -> bool:
	var sb: Control = _nn(m, "ShopButton") as Control
	if sb == null or not sb.is_visible_in_tree():
		return false
	await _pt_tap(sb)
	return _tl_sheet_open()


## Close the Shop sheet with a real tap on its Close button.
func _pt_close_shop(m: Node) -> void:
	var cb: Control = _nn(m, "ShopCloseButton") as Control
	if cb != null and cb.is_visible_in_tree():
		await _pt_tap(cb)


## A real tap on a Shop tab by its node suffix ("Research", ...); the sheet must be open.
func _pt_tab(m: Node, key: String) -> void:
	var t: Control = _nn(m, "Tab" + key) as Control
	if t != null:
		await _pt_tap(t)


## Names of the drawn Controls that draw over `c` at the point `at` (a panel, dim, texture, button higher in layer, z or tree order).
## "Seen" needs none. Same rule as _hi_covers (test_helpers_4.gd), for any target.
func _pt_covers(c: Control, at: Vector2) -> Array:
	var out: Array = []
	var all: Array = root.find_children("*", "CanvasItem", true, false)
	var idx: Dictionary = {}
	for i in all.size():
		idx[all[i]] = i
	var kc: Array = _hi_order(c, idx)
	for n in all:
		var o: Control = n as Control
		if o == null or o == c or c.is_ancestor_of(o) or o.is_ancestor_of(c) or not o.is_visible_in_tree() or o.modulate.a < 0.05:
			continue
		if o is ColorRect and (o as ColorRect).color.a < 0.05:
			continue
		if not (o is Panel or o is PanelContainer or o is ColorRect or o is TextureRect or o is BaseButton):
			continue
		if o.get_global_rect().has_point(at) and _hi_over(_hi_order(o, idx), kc):
			out.append(String(o.name))
	return out


## WCAG relative luminance and contrast ratio of two opaque colours.
func _pt_lum(c: Color) -> float:
	var f: Callable = func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * float(f.call(c.r)) + 0.7152 * float(f.call(c.g)) + 0.0722 * float(f.call(c.b))


func _pt_contrast(a: Color, b: Color) -> float:
	var la: float = _pt_lum(a)
	var lb: float = _pt_lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## The text width of a Button at its own font and size (what the label needs), plus the button's horizontal style margins.
func _pt_need_px(b: Button) -> float:
	var font: Font = b.get_theme_font("font")
	var size: int = b.get_theme_font_size("font_size")
	var sb: StyleBox = b.get_theme_stylebox("normal")
	return font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x + (sb.get_minimum_size().x if sb != null else 0.0)


## Every point a glyph's Polygon2D / Line2D children draw, in canvas coordinates, each with the half line width around it.
## Returns [[Vector2 point, float margin], ...].
func _pt_glyph_points(glyph: Node2D) -> Array:
	var out: Array = []
	for n in glyph.find_children("*", "Node2D", true, false):
		var xf: Transform2D = (n as Node2D).get_global_transform()
		if n is Polygon2D:
			for pt in (n as Polygon2D).polygon:
				out.append([xf * pt, 0.0])
		elif n is Line2D:
			var half: float = (n as Line2D).width * 0.5 * xf.get_scale().x
			for pt in (n as Line2D).points:
				out.append([xf * pt, half])
	return out


## Free a main scene now (a test that needs a second, fresh scene: two live mains would share one current camera).
func _pt_drop(m: Node) -> void:
	if m != null and is_instance_valid(m):
		if m.is_inside_tree():
			m.get_parent().remove_child(m)
		_to_free.erase(m)
		m.free()


## Fill the bucket in the farm view by calls (a full bucket, lid landed): Spin shows on the farm view. Returns the Centrifuge.
func _pt_full_bucket(p: Dictionary) -> Node:
	var cen: Node = p["Centrifuge"]
	_load_bucket(cen)
	_land_lid(cen)
	return cen
