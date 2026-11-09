Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C5. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scenes/ and materials/) of this change. Patricia works on the scripts in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Items 3–5: promote the picks.
- The truck groups added to `scenes/props/truck.tscn`: `Stacks`, `DecalsSmall`, `DecalsBold`, `FlamesTop` (all hidden at Faster Delivery 0), taken from the files in the item 5 table, with no exhaust flames.
- Render each beside its pick before handing back.

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