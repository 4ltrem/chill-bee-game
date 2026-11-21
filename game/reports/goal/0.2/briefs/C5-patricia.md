Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C5. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): faster_delivery_max_level, faster_delivery_trip_cut_per_level.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 3 look: the fork prop follows the drag point over the combs and hides when the drag ends; with Heated Fork ≥ 1 the head's albedo tweens steel → crank orange → steel per `fork_pulse_seconds` (live in Dev), emission off. Item 4 look: Gear1..Gear(N + 1) show at Gearing N and turn with the crank, neighbours in opposite directions. Item 5 look: the truck's groups show per the item 5 table.
- Items 2–6: each effect in the script that owns it (`hive.gd` fill, `bees.gd` speed, `honeycomb.gd` radius and clean cut, `centrifuge.gd` turns and ramp, `truck.gd` trip time and Auto-Sell).
- The config keys above, in the Dev panel.

Spec text:
5. **Faster Delivery** (Automation, levels): base $60, 1.30× growth, max level 4. The truck's trip time is `truck_trip_seconds × (1 − faster_delivery_trip_cut_per_level × level)` (30 → 25.5 → 21 → 16.5 → 12 s).
   - The look (designer, 2026-11-09): the truck gains hot rod parts level by level, and nothing disappears on an upgrade. **No flames come from the exhaust at any level**; flames are crank orange (STYLE_GUIDE Accent).
     | Faster Delivery | Shows | From the pick |
     |---|---|---|
     | 0 | today's truck | `scenes/props/truck.tscn` |
     | 1 | `Stacks`: two exhaust pipes on the cab | `truck-flames-r3/truck-flames-r3-l1.tscn` |
     | 2 | `Stacks` + `DecalsSmall` (small flame decals on the cab sides) | decals of `truck-flames-r1/truck-flames-r1-a.tscn` |
     | 3 | `Stacks` + `DecalsBold` (bold flame decals) | decals of `truck-flames-r1/truck-flames-r1-b.tscn` |
     | 4 | `Stacks` + `DecalsBold` + `FlamesTop` (flames over the cab roof) | `truck-flames-r3/truck-flames-r3-l4.tscn` |

Reply in at most 150 words: files changed, node names used, open questions.