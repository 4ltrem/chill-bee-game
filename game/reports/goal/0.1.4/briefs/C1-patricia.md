Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C1. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 1: the meter fill on the Harvest button, and the hive-count label above it.
- Item 1 rework (play-test 2026-11-07): the fill drawn behind the label and clipped to the button's rounded shape (with Bob).

Spec text:
1. **Harvest button is the honey meter** (designer: "the honey meter should be transfered over to the harvest button so the background of it slowly fills up").
   - The top Hive bar is removed. The Harvest button is always shown; its background fills from the bottom with the hive's fill fraction, and it is pressable only when full (today's rule).
   - The hive count moves to just above the button as "7/10", without the word "Hive" (designer: "the hive text can go above the button, i.e 5/10 above the harvest button"; 2026-11-06: "no hive").
   - Bees and money stay at the top (designer: "the bees and money count can stay at the top").
   - Full state: the fill is complete and the button takes its present enabled look (STYLE_GUIDE tokens, unchanged).
   - **Play-test of 0.1.4 (designer, 2026-11-07):** "the meter loads but it is a rectangle in front of the button, so it's not cropped properly". The fill must sit behind the label and be clipped to the button's shape (rounded corners, inside its border), not drawn as a square rectangle on top of it.

Reply in at most 150 words: files changed, node names used, open questions.