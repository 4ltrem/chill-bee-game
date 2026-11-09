Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C12. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 12: the centrifuge spins only at the second stop unless the motor is owned (the farm view never spins in Phase 1), including the reload after a pour.

Spec text:
12. **No spinning in the farm view without the motor** (designer's play-test of 0.1.4, 2026-11-08: "centrifuge shouldn't spin in farm view without the electric centrifuge upgrade, or in stage 1 of the game"). The centrifuge spins only at the second stop, cranked by the player. It may spin in the farm view (zoomed out) only once the **motor** (GDD Automation: "the electric centrifuge spins by itself") is owned, which never happens in Phase 1 ("stage 1" = Phase 1, designer confirmed 2026-11-08). This applies to the auto-reload after a pour too (`_auto_spin` in `main.gd`).

Reply in at most 150 words: files changed, node names used, open questions.