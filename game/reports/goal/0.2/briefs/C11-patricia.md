Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C11. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 11: `centrifuge.gd` stops rotating `Lid`; it rotates `Crank` about its pivot and drives Gear1 from the crank, the rest from Gear1.

Spec text:
11. **The lid stays still; the crank drives the gears** (same play-test: "the lid shouldn't spin the 0 gear spins along with the handle, which makes the other gears spin"). Today `centrifuge.gd` turns the whole `Lid` with `spin_speed`, so the lid disc, crank and gear train all spin as one. Instead: `LidDisc` and the gear ring never rotate; the `Crank` turns about its own pivot (over Gear1); Gear1 turns with the crank at the same rate and direction, and Gear2..Gear6 turn from it as item 4 says (opposite to their neighbour, speed by tooth count). The basket inside (`Spinner`) keeps spinning as today.

Reply in at most 150 words: files changed, node names used, open questions.