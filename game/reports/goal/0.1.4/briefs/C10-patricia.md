Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C10. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 10: the frames' comb cells show while the frames sit in the hive (today `hive.gd` hides the `Honeycomb` until a frame is raised), filling with the hive.

Spec text:
10. **Combs shown in the hive** (designer's play-test of 0.1.4, 2026-11-07: "the honeycombs aren't shown until the frame pops out"). The comb cells on each frame are visible while the frame sits in the hive, filling as the hive fills, not only once the frame is raised for harvest. Goes with item 5 (bigger frames): the rerun of C5 builds both.

Reply in at most 150 words: files changed, node names used, open questions.