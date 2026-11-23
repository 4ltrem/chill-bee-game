# Recipes: how to add the things the game already has

`goal_agent.py` points every build brief here and adds the code-map slice of the goal's names (L53).

Most spec items add one more of something the game already has: a panel, a corner icon, a translated label, a config value, a Dev button, a toast. Each recipe below names the existing example to copy, the files to touch and the places that must also learn about the new piece. Follow the recipe; don't rediscover it by grepping.

**Before any recipe:** run `python -I _tools/code_map.py --for <the node names in your contract lines>`. It lists every script that declares, finds or creates those names (signals, public functions, config read, tr() keys) and where the nodes sit in the scenes. Read that output, not whole scripts.

---

## R1. A panel or sheet that opens over the farm (Journal, Shop, Settings)

**Copy:** `game/scripts/journal_ui.gd` (80 lines), which is the smallest complete one.

- **Patricia:** one script, attached under `FarmUI`, finds its nodes by name in `_ready()`. It has `open()`, `close()` and a way to tell whether it is open. When it opens it sets `z_index = 60` and `top_level = true` so it sits above the Shop sheet (z 51) and its dim (z 50). Its labels refresh on `NOTIFICATION_TRANSLATION_CHANGED`.
- **Bob:** a hidden `PanelContainer` named `<Name>Panel` with children named `<Name>Title`, `<Name>Body`, `<Name>CloseButton`. **Prefix every child with the panel's name.** `find_child` returns the first match, so a second `HintLabel` broke three tests in 0.3.1 (C4 fix 2). `code_map.py` lists any duplicate that a script looks up.
- **Also tell (until the shared panel check exists, see proposal):** an open panel must block these four. Add the new panel to each:
  1. `main.gd` `farm_view_idle()`: the victory waits for it.
  2. `farm_ui.gd` `_toasts_blocked()`: toasts wait for it.
  3. `hint.gd` `_covered()`, or call `HintBubble.set_blocked(&"<name>", on)` as `shop_ui.gd` `_set_hint_blocked()` does: the hint hides under it.
  4. If it may be open when a zoom starts: `main.gd` `_finish_zoom()` / `_close_shop_sheet()`.
- **Quinn:** opens from its icon, closes on the close button (and the dim if the spec says so), blocks toasts while open, and shows the right text in both EN and FR. Check twice (open, close, open again).

## R2. A farm-view icon button (Journal, Shop, Tools, Settings gear)

**Copy:** `JournalButton` (a `Button` under `FarmUIRoot/FarmUI`) and how `journal_ui.gd` wires it.

- **Bob:** a `Button` named `<Name>Button` under `FarmUIRoot/FarmUI` at the place the canvas board shows. It must be at least 120 × 120 px (STYLE_GUIDE minimum; raise it without asking). Use the existing icon StyleBoxes in `main.tscn` (grep `StyleBox_circle`), not new ones.
- **Patricia:** text or tooltip through `tr("<name>_icon")`; `pressed.connect(open)`. Visibility belongs to whoever owns the state (the Journal shows it at thriving; `shop_ui.gd` `_sync_tools_button()` shows Tools only in the zooms).
- **Also tell:** if 3D-anchored icons (fork, spin, sell) must keep clear of it, add its name to `AVOID_NAMES` in `floating_icon.gd:21`.
- **Icons that follow a 3D object** are a different thing: `FloatingIcon` (`floating_icon.gd`) with an `anchor_path`, and `main.gd` calls `set_wanted()`.

## R3. A translated label

- **The text** lives in an approved content file (`content/*.md`), in the first fenced block, as CSV rows `key,en,fr` (French house style: "vous", prices `%d $`).
- **Export:** add that file to `UI_TEXT` in `_tools/journal_csv.py`, then run `python -I _tools/journal_csv.py`. It writes `game/translations/journal.csv`. A new key needs the import rebuilt, so the test run uses `--refresh` (L48).
- **Script:** `label.text = tr("key")`, set again on `NOTIFICATION_TRANSLATION_CHANGED` (see `journal_ui.gd` `_notification`).
- **Never** put a literal English string where a key belongs. Quinn's `t_journal_csv_every_key_en_and_fr` checks that every key has both languages.

## R4. A tunable number

- **Add** an `@export var` to `game/scripts/game_config.gd` with its default, and a `## PLACEHOLDER (spec item):` comment if the spec gives no value. Placeholders err slow.
- **The Dev panel row appears by itself:** `dev_panel.gd` builds one row per exported value from the property list. No UI work.
- **Read** it as `Economy.config.<name>` (or the script's `config.<name>`). Never copy the number into a script as a literal; a test reads the config value (`t_config_values`).

## R5. A Dev button

- **Add** one line to `dev_panel.gd` `_actions_row()`: `flow.add_child(_button("Label", callable))`.
- **The callable** calls the game's own code path (the shop buy, `Economy.reset`, `show_welcome()`), never a shortcut that sets state directly.
- **Quinn** finds it with `_button_with(panel, "Label")` and the panel with `_find_dev_panel(m)` (`tests/test_helpers_1.gd`).

## R6. A toast

- **Call** `farm_ui.enqueue_toast("<tr key>")`. The queue waits by itself for zooms, the second stop, the Shop sheet, the Journal and the welcome, shows one toast at a time for `toast_seconds`, and `clear_toasts()` empties it.
- **Don't** show `PhaseToast` directly.

## R7. Tests for any of the above

- **Find nodes** with `_node(m, name)` (`test_helpers_1.gd:116`), which resolves the names used twice. Flows (open the zoom, crank, sell) come from `tests/flow.gd` and the helpers, never copied inline (L39).
- **Tests run with** `show_welcome` and `show_hint` false (`test_base.gd` `_mk_main`); only the welcome and hint tests turn them on.
- **"twice":** every UI test does its action, undoes it and does it again (open, close, open).
- **Name** new tests `t_<item>_<what>` and register them under the spec item. The goal agent runs a change's own tests first.
