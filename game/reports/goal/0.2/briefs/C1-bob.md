Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C1. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 1: the shop panel as a scrolling list with a row template (name, level, buy button, gate text), at 720 × 1280 with no overlap with the HUD.

Spec text:
1. **Upgrade shop holds several rows.** Today `shop_ui.gd` shows one item (Worker Swarm Count). It becomes a list of rows, one per upgrade, each with name, level ("Lv 2 / 5", or "Owned" for one-time buys), and a buy button showing the next cost ($, rounded down) that is disabled when unaffordable, maxed or locked. A locked row shows its gate ("Needs Faster Delivery 1"). Costs follow GDD §3: `base × growth^level`. Rows, in order: Worker Swarm Count, Flight Endurance, Heated Uncapping Fork, Centrifuge Gearing, Faster Delivery, Auto-Sell. The panel scrolls if the rows do not fit at 720 × 1280. The look of the new UI (`UI_DESIGN.md`: icons over the shots, wrench icon) is **not** in 0.2; the existing panel is extended.

Reply in at most 150 words: files changed, node names used, open questions.