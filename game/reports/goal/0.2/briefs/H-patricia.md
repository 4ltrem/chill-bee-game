Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal H. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Write the node handoff `game/specs/0.2-node-handoff.md` (Process 5; model it on `game/specs/0.1.3c-node-handoff.md`): every node Bob must add, rename, move or remove for the changes below, with exact names and parents in `scenes/main.tscn` or the prop scenes, and the nodes your scripts will look up. Read the scenes and scripts you need; write no code yet.

Change 1: 1. **Upgrade shop holds several rows.** Today `shop_ui.gd` shows one item (Worker Swarm Count). It becomes a list of rows, one per upgrade, each with name, level ("Lv 2 / 5", or "Owned" for one-time buys), and a buy button showing the next cost ($, rounded down) that is disabled when unaffordable, maxed or locked. A locked row shows its gate ("Needs Faster Delivery 1"). Costs follow GDD §3: `base × growth^level`. Rows, in order: Worker Swarm Count, Flight Endurance, Heated Uncapping Fork, Centrifuge Gearing, Faster Delivery, Auto-Sell. The panel scrolls if the rows do not fit at 720 × 1280. The look of the new UI (`UI_DESIGN.md`: icons over the shots, wrench icon) is **not** in 0.2; the existing panel is extended.
Bob's lines: Item 1: the shop panel as a scrolling list with a row template (name, level, buy button, gate text), at 720 × 1280 with no overlap with the HUD.

Change 3: 3. **Heated Uncapping Fork** (Tree B): base $40, 1.22× growth, max level 5.
   - Fork reach: the player takes the fork from its icon and drags it through the combs; each drag point uncaps every capped cell within `uncap_radius × (1 + heated_fork_radius_bonus_per_level × level)` of the hit cell (level 0 = the hit cell only, today's behaviour). Reach is the Heated Fork's only manual effect in 0.2 (designer, 2026-11-09: "heated fork increases the fork reach"; one continuous sweep is the Long Fork's job).
   - The GDD's "+5% batch bonus for clean cuts" is left out of 0.2: its rule is undefined (listed in the README's Outstanding checklist; nothing to build for it now).
   - After automation (`heated_fork_post_auto_yield_bonus_per_level` 0.04) applies only once the auto-scraper is owned, so it has no effect in 0.2; the key and its use are coded and tested with the Dev toggle "own auto-scraper".  
   - The look (designer, 2026-11-09): the game has no 3D fork yet (`ForkIcon` is a button), so 0.2 adds the uncapping fork as a prop: it appears at the drag point over the combs while the player drags, and leaves when the drag ends. Model: `scenes/variants/fork-r4/fork-r4-c.tscn` (comb fork after the Harvest icon: five round tines, rounded crossbar, ferrule, wooden capsule handle).
   - Heated (Heated Fork ≥ 1): the whole metal head (tines, crossbar, ferrule) eases steel → crank orange → steel once per `fork_pulse_seconds`, as an albedo colour tween with **no emission** (STYLE_GUIDE V2); `fork-r4-c-hot.tscn` is the peak colour. The handle stays wood. At Heated 0 the head stays steel.
Bob's lines: Items 3–5: promote the picks.

Change 5: 5. **Faster Delivery** (Automation, levels): base $60, 1.30× growth, max level 4. The truck's trip time is `truck_trip_seconds × (1 − faster_delivery_trip_cut_per_level × level)` (30 → 25.5 → 21 → 16.5 → 12 s).
   - The look (designer, 2026-11-09): the truck gains hot rod parts level by level, and nothing disappears on an upgrade. **No flames come from the exhaust at any level**; flames are crank orange (STYLE_GUIDE Accent).
     | Faster Delivery | Shows | From the pick |
     |---|---|---|
     | 0 | today's truck | `scenes/props/truck.tscn` |
     | 1 | `Stacks`: two exhaust pipes on the cab | `truck-flames-r3/truck-flames-r3-l1.tscn` |
     | 2 | `Stacks` + `DecalsSmall` (small flame decals on the cab sides) | decals of `truck-flames-r1/truck-flames-r1-a.tscn` |
     | 3 | `Stacks` + `DecalsBold` (bold flame decals) | decals of `truck-flames-r1/truck-flames-r1-b.tscn` |
     | 4 | `Stacks` + `DecalsBold` + `FlamesTop` (flames over the cab roof) | `truck-flames-r3/truck-flames-r3-l4.tscn` |
Bob's lines: The truck groups added to `scenes/props/truck.tscn`: `Stacks`, `DecalsSmall`, `DecalsBold`, `FlamesTop` (all hidden at Faster Delivery 0), taken from the files in the item 5 table, with no exhaust flames.

Change 6: 6. **Auto-Sell** (Automation, one-time $250, unlocks at Faster Delivery level 1): once owned, the truck leaves by itself when its bed is full and sells at the full price, exactly as a Sell press would. Sell stays pressable for a part load. A small "Auto" tag shows by the Sell button while Auto-Sell is owned.
Bob's lines: Item 6: the "Auto" tag node by Sell. Item 7: the toast node.

Change 7: 7. **Phase 2 flag.** Buying Auto-Sell (designer, 2026-11-09; Faster Delivery does not trigger it) sets `Economy.phase = 2` (GDD §1). In 0.2 the flag has no gameplay effect; the Dev panel shows it, and a one-line toast "Phase 2: your farm starts running itself" shows once.
Bob's lines: Item 6: the "Auto" tag node by Sell. Item 7: the toast node.

Change 8: 8. **Bee Journal entry, EN/FR, through Godot's translation CSV.** One approved entry from `content/bee-journal-real.md`: Entry 3, Bumble Bees (a Sunny Meadow visitor; designer, 2026-11-09: any Meadow species) is exported by a script, `_tools/journal_csv.py`, into `game/translations/journal.csv` (keys `JOURNAL_<ID>_TITLE`, `JOURNAL_<ID>_BODY`; columns `en`, `fr`), imported by Godot and registered in `project.godot`. A **Journal** button in the shop panel opens a panel showing the title and body through `tr()`. The game's locale follows the OS (`en` fallback); the Dev panel has an EN/FR toggle. The text is the approved text verbatim; nothing is retyped by hand.
Bob's lines: Item 8: the Journal button and panel (title, scrolling body), STYLE_GUIDE tokens.

Reply in at most 150 words: files changed, node names used, open questions.