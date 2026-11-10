Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C8. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 8: the Journal button and panel (title, scrolling body), STYLE_GUIDE tokens.

Spec text:
8. **Bee Journal entry, EN/FR, through Godot's translation CSV.** One approved entry from `content/bee-journal-real.md`: Entry 3, Bumble Bees (a Sunny Meadow visitor; designer, 2026-11-09: any Meadow species) is exported by a script, `_tools/journal_csv.py`, into `game/translations/journal.csv` (keys `JOURNAL_<ID>_TITLE`, `JOURNAL_<ID>_BODY`; columns `en`, `fr`), imported by Godot and registered in `project.godot`. A **Journal** button in the shop panel opens a panel showing the title and body through `tr()`. The game's locale follows the OS (`en` fallback); the Dev panel has an EN/FR toggle. The text is the approved text verbatim; nothing is retyped by hand.

Reply in at most 150 words: files changed, node names used, open questions.