Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C7. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 7: `Economy.phase` and the toast.

Spec text:
7. **Phase 2 flag.** Buying Auto-Sell (designer, 2026-11-09; Faster Delivery does not trigger it) sets `Economy.phase = 2` (GDD §1). In 0.2 the flag has no gameplay effect; the Dev panel shows it, and a one-line toast "Phase 2: your farm starts running itself" shows once.

Reply in at most 150 words: files changed, node names used, open questions.