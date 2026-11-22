Goal agent run `0.3`, spec `game/specs/0.3-course-build.md`, goal C2. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.

Your contract lines:
- Item 2: `Economy.habitat_health`, `add_habitat()`, signal `thriving` (once); the pill's script.

Spec text:
2. **Habitat Health.** `Economy` holds `habitat_health`, starting at `habitat_health_start` (10). Nothing lowers it in 0.3. It is capped at `habitat_health_max` (100). When it reaches `habitat_thriving` (100), `Economy` emits `thriving` once per farm. Health shows as a count pill in the farm view's top info, in `UI_DESIGN.md` rule 9 order: the number, a wildflower icon (not a leaf: rule 6 keeps the leaf for Impact), then **+**, which opens the Shop. Farm view only, like the rest of the info row. The pill clears the Harvest, Spin and Sell anchors.

Reply in at most 150 words: files changed, node names used, open questions.