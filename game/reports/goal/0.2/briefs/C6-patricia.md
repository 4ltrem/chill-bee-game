Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C6. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): auto_sell_unlock_delivery_level.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Items 2–6: each effect in the script that owns it (`hive.gd` fill, `bees.gd` speed, `honeycomb.gd` radius and clean cut, `centrifuge.gd` turns and ramp, `truck.gd` trip time and Auto-Sell).
- The config keys above, in the Dev panel.

Spec text:
6. **Auto-Sell** (Automation, one-time $250, unlocks at Faster Delivery level 1): once owned, the truck leaves by itself when its bed is full and sells at the full price, exactly as a Sell press would. Sell stays pressable for a part load. A small "Auto" tag shows by the Sell button while Auto-Sell is owned.

Reply in at most 150 words: files changed, node names used, open questions.