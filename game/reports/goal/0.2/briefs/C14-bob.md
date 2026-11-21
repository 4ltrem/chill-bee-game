Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C14. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Items 1 and 14: the shop panel as a list of seven rows with a row template (name, level, buy button, gate text), tall enough to show every row with no scroll container, at 720 × 1280 with no overlap with the HUD.

Spec text:
14. **The shop shows every row without scrolling** (same play-test: "I don't like the scrolling menu, the menus that have been implemented do work"). The shop panel is tall enough to show all seven rows at once at 720 × 1280, with no scroll container, and still clears the HUD. Replaces item 1's "the panel scrolls if the rows do not fit" and the C1 hand fix (`ShopScroll` one-row height). A stopgap: 0.3.0's Shop sheet replaces the panel.

Reply in at most 150 words: files changed, node names used, open questions.