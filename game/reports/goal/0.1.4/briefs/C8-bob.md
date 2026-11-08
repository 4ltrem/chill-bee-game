Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C8. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 8: `HintLabel` lowered below Back.

Spec text:
8. **Instruction text below Back** (designer's review of the 0.1.4 build, 2026-11-07: "back button overlaps instruction text at top, can fix by lowering instruction test below the back button").
   - The instruction text at the top of the zoom (`HintLabel`) moves down so it sits below Back's top-right rect, in the first zoom and at the second stop. Back stays where item 3 puts it.

Reply in at most 150 words: files changed, node names used, open questions.