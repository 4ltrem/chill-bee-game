Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C12. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): spigot_flow_max_level, spigot_flow_cut_per_level.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 12: `spigot_flow` on the `Economy` upgrade table; `centrifuge.gd` bottling time uses the cut.
- The config keys above, in the Dev panel.

Spec text:
12. **Spigot Flow** (Tree B; designer's play-test of 0.2.0, 2026-11-09: "the jar filing rate has become the bottleneck"; moved from after 0.2 into 0.2.1, designer 2026-11-09). A new shop row after Centrifuge Gearing: base $30, 1.20× growth, max level 5 (provisional placeholders, erring slow; Terry checks them before 0.3.0). Bottling time per jar is `bottling_seconds_per_jar × (1 − spigot_flow_cut_per_level × level)` (−12%/level: 3.0 → 1.8 s at level 5); the jar's flight time is unchanged. No model change in 0.2.1.

Reply in at most 150 words: files changed, node names used, open questions.