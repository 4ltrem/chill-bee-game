Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal H. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Write the node handoff `game/specs/0.1.4-node-handoff.md` (Process 5; model it on `game/specs/0.1.3c-node-handoff.md`): every node Bob must add, rename, move or remove for the changes below, with exact names and parents in `scenes/main.tscn` or the prop scenes, and the nodes your scripts will look up. Read the scenes and scripts you need; write no code yet.

Change 1: 1. **Harvest button is the honey meter** (designer: "the honey meter should be transfered over to the harvest button so the background of it slowly fills up").
   - The top Hive bar is removed. The Harvest button is always shown; its background fills from the bottom with the hive's fill fraction, and it is pressable only when full (today's rule).
   - The hive count moves to just above the button as "7/10", without the word "Hive" (designer: "the hive text can go above the button, i.e 5/10 above the harvest button"; 2026-11-06: "no hive").
   - Bees and money stay at the top (designer: "the bees and money count can stay at the top").
   - Full state: the fill is complete and the button takes its present enabled look (STYLE_GUIDE tokens, unchanged).
Bob's lines: Item 1: the Harvest button's fill node and the count label; remove the Hive bar.

Change 2: 2. **Buttons anchored to their props, the same way in every view** (play-test: "the spin and harvest button changes locations").
   - Each button follows one anchor point on its prop, projected to the screen every frame, in every camera view. No per-view offsets are allowed; today's runtime move of Spin out of FarmUI by `main.gd` goes away, because the scene places it.
   - **Harvest:** lower overall, just above the hive lid in the farm view (designer: "harvest button can be lower overall, in farm view just above the lid"). It is hidden at the second stop, where the lid may be off screen (designer, 2026-11-06: "hide it").
   - **Spin:** just above the centrifuge lid (designer: "same with spin button it can be just above the centrifuge lid").
   - **Sell:** lower, just above the truck bed between crate and truck, as in ab-A's `8-sell` (designer: "same with sell icon it can be lower, refer to ab-A for known good placement"; on ab-A: "sell icon is good here").
   - When an anchor would put a button off screen or over another control, the button is clamped inside the screen with a 16 px margin and nudged clear. Quinn's overlap check below catches failures.
Bob's lines: Item 2: an anchor node on the hive lid, the centrifuge lid and the truck bed. Spin moves out of FarmUI in `main.tscn`. / Item 2: add any new moment to `game/tests/ui_compare_shots.gd` (designer rule 2026-11-06: same moments by script, an agent only for a new screen).

Change 3: 3. **Back in one fixed place** (play-test: "the back button isn't consistent"). It is a screen-space button in the **top-right** corner in the first zoom and at the second stop, not found by a scan (designer, 2026-11-06: "top right to not interfear with the labels").
Bob's lines: Item 3: Back in its corner. Item 4: the speed tag's new spot.

Change 4: 4. **Speed tag clear of the top info** (play-test: "the 5x is overlaping with some other text in the top left"). The ×N tag sits **under the money and bees lines** (designer, 2026-11-06).
Bob's lines: Item 3: Back in its corner. Item 4: the speed tag's new spot.

Change 5: 5. **Bigger hive frames and combs** (designer: "hive frames and combs can be bigger to match the pile size"). The frames and their cells scale up so a cell reads at about the size of a cell in the bucket pile. The rack stays inside the hive body; the first zoom's ≥ 20 px rule and "hive + centrifuge whole" still hold.
Bob's lines: Item 5: the bigger frames and cells.

Reply in at most 150 words: files changed, node names used, open questions.