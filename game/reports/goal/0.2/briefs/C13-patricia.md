Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C13. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 13: `truck.gd` defers departure (Sell and Auto-Sell) until its in-flight bed jars have landed.

Spec text:
13. **No jar flies after a leaving truck** (same play-test: "if the jars are filing and the truck is leaving the jar flies towards the truck"). Today a bottled jar is counted on the truck at once and flies to its bed slot, and Sell or Auto-Sell can send the truck off while that jar is still in the air. The truck now leaves only once every jar flying to its bed has landed (Sell and Auto-Sell both wait); a jar bottled after the truck has left flies to the crate, as today.

Reply in at most 150 words: files changed, node names used, open questions.