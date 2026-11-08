Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C14. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 14: frame count, rise and comb grid retuned to Bob's rebuilt hive (five upright frames).

Spec text:
14. **The hive is the round 9 pick** (designer's play-test of 0.1.4, 2026-11-08: "the hive and frame models were changed WRONG"). C5 built a shallow hive body with its front-left wall missing and two large flat frames, not the pick. `scenes/props/hive.tscn` must match `scenes/variants/hive-frames/hive-frames-a.tscn` (render `game/reports/variants/hive-frames-r9/hive-frames-r9-a.png`): a deep box with all four walls, five upright frames standing side by side, the comb cells on each frame filling it edge to edge, the lid hinged at the back. The frames still rise one at a time in the first zoom.

Reply in at most 150 words: files changed, node names used, open questions.