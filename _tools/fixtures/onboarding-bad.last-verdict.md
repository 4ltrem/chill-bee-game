<!-- critic_check.py, 2026-11-05; overwritten each run -->

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: I compared the draft with GDD §2 (harvest flow), §3 (Trees A/B), §7, §8 and Progression Tiers & Biomes. The guide options (Melli, Pip, Lady Aura) are offered as options, which is correct. Sunny Meadow, Wildflower Gold Honey, Worker Swarm Count and Tree A all exist. These do not match the GDD:
  - The hive is tapped, not the fork icon.
  - The jars are said to fill during extraction.
  - A "market stand" replaces the truck and its Sell icon.
  - A "No-Rapid-Tap Mode" is invented.
  - The Sources row calls Worker Swarm Count "cheapest" in Tree A.
- Tone & Glossary: The tone is playful and cozy. The Glossary term is "in-game money", but the draft uses "coins", "honey money" and "sou". Those are not listed under "Also called".
- Child safety & spending: I checked Beats 6–8, where the player is led to an upgrade, and Decision 4 (emoji). There is no fear, guilt or pressure to spend, and no price or donation is tied to the player's worth. "This little meadow is counting on you" is about the story premise, not spending, so it passes.
- Facts & French: Real-world statements found:
  - "Without bees, the flowers can't bloom. Without blooms, the meadow can't grow."
  - "Look at all those capped cells — fresh honey, sealed with wax!"
  - "Every flower they visit fills the hive a little more."

  The first two are real-world claims with no source. The third is a foraging mechanic, which is in-world and fine. French is present for every beat and mostly matches the English. Two small mismatches: "plus de miel pour tout le monde" vs "for us" (Beat 7), and "Un vrai apiculteur" is masculine while later lines are inclusive.
- Sources: Cited sections checked:
  - Story Premise & Onboarding, Phase 1 Uncapping & Extraction Minigame, Progression Trees & Economy Balance, Aesthetic & Tone, Child Safety and Glossary all exist.
  - "GDD §8 Accessibility" exists, but the row misstates it.
  - "GDD §9 Progression Tiers" does not exist. §9 is UI & Screens, and Progression Tiers & Biomes has no number.
- Look & words: Objects checked against GDD §2 and STYLE_GUIDE (centrifuge, frame, crank, jars, truck). These do not match: the "low-poly wooden barrel centrifuge" (FR "centrifugeuse en bois"), the frame "tilted at an angle", the "market stand", and glass jars sitting at the spigot during extraction. The wooden hive and frame, the glass walls and the crank do match.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Lore | `Tap the hive to start the harvest!` | §2 Start: a fork icon floats above the full hive and tapping it starts the harvest | Have the guide point at the fork icon above the hive, in the stage direction, EN and FR (also Beat 3). |
| 2 | Look & words | `low-poly wooden barrel centrifuge` | §2: the centrifuge is a glass bucket with a spigot and a steel lid carrying the crank. STYLE_GUIDE: metal centrifuge, glass bucket. | Describe a glass bucket with a steel lid and crank, and fix the FR "centrifugeuse en bois". |
| 3 | Look & words | `isometric wooden honeycomb frame, tilted at an angle` | §2 Stage 1: the frame slides up out of the hive and stands upright. | Say the frame slides up out of the hive and stands upright, EN and FR ("légèrement incliné"). |
| 4 | Lore | `Keep tapping until those jars are full!` | §2 Stages 2–3: the crank melts the combs into honey in the bucket. Bottling then starts by itself, and the jars fill one at a time from the spigot. | Have the guide say extraction fills the bucket, then bottling starts by itself. Remove "jars sit at a spigot" and "honey flies into those jars", EN and FR. |
| 5 | Lore | `Tap the market stand to put your honey out.` | §2 Stage 3: full jars load onto the truck, and a Sell ($X) icon floats above it. No market stand exists. | Replace the market stand with the truck and its Sell icon, EN and FR (Beat 6). |
| 6 | Lore | `if No-Rapid-Tap Mode is on, the crank tap is replaced with a hold-or-single-tap` | §8: holding the crank is built in for every player, with no separate toggle. | Drop the mode. Show the guide teaching "tap or hold the crank", and remove Decision 3 and its Sources row. |
| 7 | Lore | `Worker Swarm Count: first upgrade candidate (Tree A, cheapest)` | §3 Tree A: Flight Endurance costs $15 and Worker Swarm Count $25, so Flight Endurance is cheaper. | Remove "cheapest". Decision 2 already says it is second cheapest, so make the table match. |
| 8 | Tone & Glossary | `Every coin you earn can grow this farm` | Glossary > Currencies & Prestige: "In-game money" is the main term. | Use "money" in the English lines and stage directions ("Coins appear", "honey money", "coin"). Use "argent" in the French ("sou"). |
| 9 | Facts & French | `Without bees, the flowers can't bloom. Without blooms, the meadow can't grow.` | Story Premise & Onboarding (in-world premise). It is a real-world pollination claim with no source, and flowers bloom without bees. | Reword it as clearly in-world, e.g. the pocket world needs a beekeeper to wake up. Do the same in FR. |
| 10 | Facts & French | `fresh honey, sealed with wax!` | §2 Stage 1 (capped wax cells are game visuals). It is a real-world claim about bees capping honey, with no source URL. | Reword it to describe what the player sees in the game, e.g. golden honey under wax caps. Do the same in FR. |
| 11 | Sources | `Progression Tiers §9` and `GDD §9 Progression Tiers` | GDD: "Progression Tiers & Biomes" is an unnumbered heading, and §9 is UI & Screens. | Cite "Progression Tiers & Biomes" without §9, in the Sources line and the table. |
| 12 | Sources | `No-Rapid-Tap Mode replaces speed taps with hold or single tap` (cited to `GDD §8 Accessibility`) | §8 Accessibility: "Hold Instead of Tapping" is built in, with no mode. | Drop the row, or restate it as "holding the crank ramps to the fastest tap rate". |
| 13 | Facts & French | `Plus d'abeilles, plus de butinage — et plus de miel pour tout le monde!` | Check 4: French must match the English meaning. | Match the English "more honey for us" (e.g. "pour nous"), and use inclusive wording in "Un vrai apiculteur". (minor) |
