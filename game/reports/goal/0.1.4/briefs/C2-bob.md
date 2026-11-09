Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C2. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 2: an anchor node on the hive lid, the centrifuge lid and the truck bed. Spin moves out of FarmUI in `main.tscn`.
- Item 2: add any new moment to `game/tests/ui_compare_shots.gd` (designer rule 2026-11-06: same moments by script, an agent only for a new screen).

Spec text:
2. **Buttons anchored to their props, the same way in every view** (play-test: "the spin and harvest button changes locations").
   - Each button follows one anchor point on its prop, projected to the screen every frame, in every camera view. No per-view offsets are allowed; today's runtime move of Spin out of FarmUI by `main.gd` goes away, because the scene places it.
   - **Harvest:** lower overall, just above the hive lid in the farm view (designer: "harvest button can be lower overall, in farm view just above the lid"). It is hidden at the second stop, where the lid may be off screen (designer, 2026-11-06: "hide it").
   - **Spin:** just above the centrifuge lid (designer: "same with spin button it can be just above the centrifuge lid").
   - **Sell:** lower, just above the truck bed between crate and truck, as in ab-A's `8-sell` (designer: "same with sell icon it can be lower, refer to ab-A for known good placement"; on ab-A: "sell icon is good here").
   - When an anchor would put a button off screen or over another control, the button is clamped inside the screen with a 16 px margin and nudged clear. Quinn's overlap check below catches failures.

Reply in at most 150 words: files changed, node names used, open questions.