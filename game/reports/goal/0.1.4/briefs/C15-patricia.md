Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C15. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 15: leaving the second stop while cranking disables crank input and keeps progress; Spin is wanted on the farm while a crank is paused, and its tap pans back and re-enables the crank.

Spec text:
15. **Leaving the centrifuge stops the crank** (designer's play-test of 0.1.4, 2026-11-08: "If I start spinning the centrifuge and back out I can still spin it WRONG"). Back at the second stop while cranking pauses the crank: no turn counts outside the second stop, and progress is kept. Spin shows again in the farm view while a crank is paused, and tapping it pans back to the second stop, where the crank resumes from where it stopped.

Reply in at most 150 words: files changed, node names used, open questions.