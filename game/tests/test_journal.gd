extends "res://tests/test_phase.gd"

# Quinn: 0.2 item 8 (Bee Journal, EN/FR), written from game/specs/0.2-first-automation.md before the code.
# Expected text is read from game/translations/journal.csv (the committed file); the CSV itself is checked against its generator.

const JOURNAL_CSV: String = "res://translations/journal.csv"


## Parse the CSV (Godot's own reader, quoted newlines included): {header: Array, rows: {key: {col: text}}}.
func _journal_read() -> Dictionary:
	var f: FileAccess = FileAccess.open(JOURNAL_CSV, FileAccess.READ)
	if f == null:
		return {}
	var header: PackedStringArray = f.get_csv_line()
	var rows: Dictionary = {}
	while not f.eof_reached():
		var line: PackedStringArray = f.get_csv_line()
		if line.size() < 2 or line[0] == "":
			continue
		var r: Dictionary = {}
		for i in range(1, mini(header.size(), line.size())):
			r[header[i]] = line[i]
		rows[line[0]] = r
	return {"header": header, "rows": rows}


func _journal_ids(rows: Dictionary) -> Array:
	var ids: Array = []
	for k in rows.keys():
		var s: String = str(k)
		if s.begins_with("JOURNAL_") and (s.ends_with("_TITLE") or s.ends_with("_BODY")):
			var id: String = s.trim_prefix("JOURNAL_").trim_suffix("_TITLE").trim_suffix("_BODY")
			if not ids.has(id):
				ids.append(id)
	return ids


## journal.csv: columns en and fr; every key present in both, non-empty; each entry has a TITLE and a BODY; Bumble Bees is there.
# goal T8.1
func t_journal_csv_every_key_en_and_fr() -> void:
	var d: Dictionary = _journal_read()
	ck(not d.is_empty(), "journal.csv opens")
	if d.is_empty():
		_fin()
		return
	var header: PackedStringArray = d["header"]
	ck(header.has("en") and header.has("fr"), "the header has the columns en and fr")
	var rows: Dictionary = d["rows"]
	ck(rows.size() >= 2, "the CSV has at least one entry (a title and a body)")
	for k in rows.keys():
		for col in ["en", "fr"]:
			ck(str(rows[k].get(col, "")).strip_edges() != "", "%s has non-empty %s text" % [k, col])
	var ids: Array = _journal_ids(rows)
	ck(ids.has("BUMBLE_BEES"), "Entry 3, Bumble Bees, is in the CSV (JOURNAL_BUMBLE_BEES_*)")
	for id in ids:
		ck(rows.has("JOURNAL_%s_TITLE" % id), "%s has a _TITLE key" % id)
		ck(rows.has("JOURNAL_%s_BODY" % id), "%s has a _BODY key" % id)
	ck(str(rows.get("JOURNAL_BUMBLE_BEES_TITLE", {}).get("fr", "")) != str(rows.get("JOURNAL_BUMBLE_BEES_TITLE", {}).get("en", "")),
		"the French title differs from the English one")
	_fin()


## tr() returns the French text with locale fr and the English text with en, for every key; the locale is put back.
# goal T8.1
func t_journal_tr_follows_locale() -> void:
	var d: Dictionary = _journal_read()
	var old: String = TranslationServer.get_locale()
	if d.is_empty():
		ck(false, "journal.csv opens")
		_fin()
		return
	var rows: Dictionary = d["rows"]
	for loc in ["fr", "en", "fr"]:
		TranslationServer.set_locale(loc)
		for k in rows.keys():
			eq(TranslationServer.translate(k), rows[k][loc], "locale %s: tr(%s) is the CSV %s text" % [loc, k, loc])
		var t: String = TranslationServer.translate("JOURNAL_BUMBLE_BEES_TITLE")
		eq(t, rows["JOURNAL_BUMBLE_BEES_TITLE"][loc], "locale %s: the Bumble Bees title" % loc)
	TranslationServer.set_locale(old)
	_fin()


## The Journal button (real tap) opens the panel with the CSV title and body; follows en/fr; Close hides it; twice gives the same.
# goal T8.1
func t_journal_panel_text_matches_csv_twice() -> void:
	var d: Dictionary = _journal_read()
	var old: String = TranslationServer.get_locale()
	if d.is_empty():
		ck(false, "journal.csv opens")
		_fin()
		return
	var rows: Dictionary = d["rows"]
	_portrait()
	var m: Node = await _mk_main()
	if m == null:
		TranslationServer.set_locale(old)
		_fin()
		return
	await _shop_open(m, true)   # item 14: the Journal button sits in the shop; open the sheet by a real Shop tap
	var btn: Button = _nn(m, "JournalButton") as Button
	var panel: Control = _nn(m, "JournalPanel") as Control
	var title: Label = _nn(m, "JournalTitle") as Label
	var body: Label = _nn(m, "JournalBody") as Label
	var close: Button = _nn(m, "JournalCloseButton") as Button
	if btn == null or panel == null or title == null or body == null or close == null:
		TranslationServer.set_locale(old)
		_fin()
		return
	for loc in ["en", "fr"]:
		for run in [1, 2]:
			TranslationServer.set_locale(loc)
			await _frames(2)
			ck(not panel.visible, "%s run %d: the panel starts closed" % [loc, run])
			ck(btn.is_visible_in_tree(), "%s run %d: the Journal button is on screen" % [loc, run])
			await fi.tap_at(btn.get_global_rect().get_center())
			await _frames(2)
			ck(panel.is_visible_in_tree(), "%s run %d: a real tap on Journal opens the panel" % [loc, run])
			eq(title.text, rows["JOURNAL_BUMBLE_BEES_TITLE"][loc], "%s run %d: the panel title is the CSV text" % [loc, run])
			eq(body.text, rows["JOURNAL_BUMBLE_BEES_BODY"][loc], "%s run %d: the panel body is the CSV text" % [loc, run])
			await fi.tap_at(close.get_global_rect().get_center())
			await _frames(2)
			ck(not panel.visible, "%s run %d: a real tap on Close hides the panel" % [loc, run])
	TranslationServer.set_locale(old)
	_fin()


## journal_csv.py regenerates the committed CSV byte for byte (no hand edits). The committed file is saved first and put back.
# goal T8.1
func t_journal_csv_equals_script_output() -> void:
	var script: String = ProjectSettings.globalize_path("res://").path_join("../_tools/journal_csv.py").simplify_path()
	var before: PackedByteArray = FileAccess.get_file_as_bytes(JOURNAL_CSV)
	ck(before.size() > 0, "the committed journal.csv is not empty")
	ck(FileAccess.file_exists(script), "_tools/journal_csv.py exists")
	if before.size() == 0 or not FileAccess.file_exists(script):
		_fin()
		return
	var out: Array = []
	var code: int = OS.execute("python", ["-I", script], out, true)
	var after: PackedByteArray = FileAccess.get_file_as_bytes(JOURNAL_CSV)
	# put the committed bytes back whatever happened
	var w: FileAccess = FileAccess.open(JOURNAL_CSV, FileAccess.WRITE)
	if w != null:
		w.store_buffer(before)
		w.close()
	eq(code, 0, "journal_csv.py exits 0 (%s)" % str(out))
	ck(after == before, "journal_csv.py output equals the committed journal.csv byte for byte (%d vs %d bytes)" % [after.size(), before.size()])
	_fin()
