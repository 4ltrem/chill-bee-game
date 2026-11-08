Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C9. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 9: `PausedLabel` moved above the upgrade section.

Spec text:
9. **"Production paused" above the upgrades** (designer's play-test of 0.1.4, 2026-11-07: "in spin mode the production paused message is wrapping so let's move it above the upgrade section at the bottom"). `PausedLabel` ("Hive full, production paused", now in `TopInfo`) moves to just above the upgrade section at the bottom of the screen, on one line, in every view. Item 4 confirmed: the ×N tag displays correctly.

Reply in at most 150 words: files changed, node names used, open questions.