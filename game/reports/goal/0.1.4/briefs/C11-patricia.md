Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C11. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 11: Spin moves the camera to the second stop from any view, then enters spin mode.

Spec text:
11. **Spin goes to the second stop** (designer's play-test of 0.1.4, 2026-11-08: "the spin button should bring it to zoom 2 view"). Pressing Spin from any view moves the camera to the second stop (the centrifuge zoom) and enters spin mode there.

Reply in at most 150 words: files changed, node names used, open questions.