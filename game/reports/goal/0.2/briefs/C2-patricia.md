Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C2. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): flight_speed_bonus_per_level, flight_max_level.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Items 2–6: each effect in the script that owns it (`hive.gd` fill, `bees.gd` speed, `honeycomb.gd` radius and clean cut, `centrifuge.gd` turns and ramp, `truck.gd` trip time and Auto-Sell).
- The config keys above, in the Dev panel.

Spec text:
2. **Flight Endurance** (Tree A): +10% bee speed per level, base $15, 1.15× growth, max level 10. Effect: the hive's fill rate is multiplied by `(1 + flight_speed_bonus_per_level × level)`, on top of Swarm (Terry A1: faster trips fill faster). The visible bees fly faster by the same factor (`bees.gd` `speed`).

Reply in at most 150 words: files changed, node names used, open questions.