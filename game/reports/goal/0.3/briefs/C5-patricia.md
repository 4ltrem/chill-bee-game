Goal agent run `0.3`, spec `game/specs/0.3-course-build.md`, goal C5. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.

Your contract lines:
- Item 5: the victory overlay script and its queue (farm view, no zoom, sheet or drag; delay).

Spec text:
5. **Victory screen.** After `thriving`, the victory is queued: it shows the next time the player is on the farm view with no zoom, sheet or drag in progress, after `victory_delay_seconds` (4.0). It never interrupts a harvest. An overlay over the live farm, dimmed, with the new patches visible behind it: `victory_title`, `victory_body`, and one button, `victory_button` ("Keep playing"), which closes it. No summary, timer or record. It shows once per farm. After it, play continues unchanged (honey, upgrades, truck), the pill stays at 100 and the row stays maxed. Strings through `tr()` from the approved `content/course-ending-text.md` rows, exported to a translation CSV by script, not retyped.

Reply in at most 150 words: files changed, node names used, open questions.