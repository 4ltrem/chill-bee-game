Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C13. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 13: `CentrifugeLabel` follows the centrifuge anchor through the item 2 anchor-follow component (Bob moves the node out of its fixed offsets).

Spec text:
13. **Centrifuge text sits on the centrifuge** (designer's play-test of 0.1.4, 2026-11-08: "the centrifuge helper text should stay on top of the centrifgue not screen position locked"). `CentrifugeLabel` ("Honey: x / y" and the crank hint) is fixed at screen (24, 245) in `FarmUI` today. It follows the centrifuge's lid anchor through the same anchor-follow component as Harvest, Spin and Sell (item 2), sitting above the centrifuge in every view, clamped inside the screen and clear of Spin and Back.

Reply in at most 150 words: files changed, node names used, open questions.