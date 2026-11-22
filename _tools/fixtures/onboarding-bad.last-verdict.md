<!-- critic_check.py, 2026-11-20; overwritten each run -->

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: I compared the draft's farm, harvest flow, accessibility, upgrade-cost and guide-selection statements against GDD §2, §3, §7 and §8. Eight statements broke the GDD or were left unreconciled:
  - the market stand (the GDD sells by truck)
  - "Tap the hive" (the GDD uses the fork icon)
  - the summary modal placed after extraction (the GDD shows it after the truck sale)
  - "No-Rapid-Tap Mode" (the GDD has no toggle)
  - Worker Swarm Count called "cheapest" (Flight Endurance is $15, Worker Swarm Count $25)
  - the guide chosen from three options (the GDD lists six candidates and a playtest picks)
  - the centrifuge "tap the crank" line, which fits the GDD but misses that bottling starts by itself
  - the "None in run 1" check on the Sources header, which is fine
- Tone & Glossary: I checked the terms "honey money", "market stand", "coin", "sou", "in-game money", "pocket world", "swarm", "upgrade" and "Wildflower Gold Honey". "Honey money" is not the Glossary's "In-game money". The rest is playful and cozy.
- Child safety & spending: I checked Beat 6 ("Every coin you earn can grow this farm"), Beat 7 ("Let's make your swarm a little happier") and Beat 8 ("counting on you… And so am I"). No fear, guilt or pressure to spend, and no donation or purchase tied to worth. The Beat 8 line is a minor note.
- Facts & French: I found these real-world statements:
  - "Without bees, the flowers can't bloom. Without blooms, the meadow can't grow."
  - "Look at all those capped cells — fresh honey, sealed with wax!"
  - "Pure gold hiding under each cap"
  - "Every flower they visit fills the hive a little more"
  
  The first two are stated as real-world facts with no source. The third is metaphor, and the fourth is the game's mechanic. The French mostly matches the English. The recap-screen detail "base honey value and any bonuses" is dropped in French, and the French refers to a "Décisions requises" section that does not exist.
- Sources: checked by script.
- Look & words: I checked these descriptions against GDD §2 and STYLE_GUIDE:
  - "low-poly wooden barrel centrifuge" (fails: it is a glass bucket with a steel lid)
  - "centrifugeuse en bois" (fails)
  - "isometric wooden honeycomb frame, tilted at an angle" (fails: frames slide up standing upright)
  - "Wax-capped cells glow softly" (fails: capped cells are matte and only the revealed honey glows)
  - "That golden hive" (fails: the hive is wood-coloured)
  - "Jars move to the market stand" (fails: jars go onto the truck)
  - The jars and the glass walls match.
- Completeness: the English and French beats match: 8 beats each, and the Beat 5 accessibility note appears in both. The guide-options table, the Sources table and the Decisions section exist in English only. No empty table cells. [GUIDE] is a deliberate stand-in because the request asks for options. Frontmatter "status: superseded" and the Sources path `onboarding-script/` versus `run: onboarding-script-v1/` disagree.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Lore | `Jars move to the market stand on the farm view.` / `Tap the market stand to put your honey out.` | Game Mechanics §2 Stage 3 | The GDD has no market stand. Jars load onto the truck, and a Sell ($X) icon floats above the full truck. Reword Beat 6 (EN and FR) so the player taps the Sell icon on the truck. |
| 2 | Tone & Glossary | `Your very first honey money!` / `Ton tout premier argent de miel!` | Glossary > Currencies & Prestige | Use the Glossary term "in-game money", or phrase it without naming the currency. Do the same in French. |
| 3 | Lore | `Tap the hive to start the harvest!` / `Hive storage indicator fills.` | Game Mechanics §2 Start | A fork icon floats above the full hive, and tapping it starts the harvest. Change the line, the stage direction and the French to match. |
| 4 | Lore | `if No-Rapid-Tap Mode is on, the crank tap is replaced with a hold-or-single-tap` | Accessibility §8 Hold Instead of Tapping | The GDD says holding is built in for every player and there is no toggle. Remove the mode from the note, the Sources row and Decision 3. Offer a hold-or-tap line for everyone, or leave the line out. |
| 5 | Lore | `Worker Swarm Count: first upgrade candidate (Tree A, cheapest)` | Progression Trees §3 Tree A | Flight Endurance ($15) is cheaper than Worker Swarm Count ($25). Fix the Sources row so it matches Decision 2's "lowest base cost after Flight Endurance". |
| 6 | Lore | `Choose from Option A (Mellisande / "Melli"), Option B (Pip), or Option C (Lady Aura)` | Story Premise & Onboarding §7 | The GDD lists six candidate guides in `content/guides.md` and a playtest picks one. Reframe the options as a shortlist from that file, not a designer pick. Do not describe the name as TBD. |
| 7 | Lore | `A summary modal appears: base honey value and any bonuses.` | Game Mechanics §2 Stages 2–3 | After extraction, bottling starts by itself. The summary appears after the truck sale. Move or remove the modal, and drop "Keep tapping until those jars are full!" or reword it. |
| 8 | Facts & French | `Without bees, the flowers can't bloom. Without blooms, the meadow can't grow.` | Aesthetic & Tone; Bee Journal §3 | This is a false or unsourced real-world claim. Reword it to be clearly about this pocket world, for example that the little meadow is waiting for its bees. Make the French match. |
| 9 | Facts & French | `fresh honey, sealed with wax!` | Game Mechanics §2 Stage 1 | This reads as a real-world fact about bees with no source. Reword it to the game's look, for example "glowing honey under the wax caps". Or cite a Ruth source URL. |
| 10 | Look & words | `low-poly wooden barrel centrifuge` / `centrifugeuse en bois` | Game Mechanics §2 (glass bucket with steel lid) | The centrifuge is a glass bucket with a spigot and a steel lid carrying the crank. Say so in English and French, and drop "wooden barrel". |
| 11 | Look & words | `isometric wooden honeycomb frame, tilted at an angle. Wax-capped cells glow softly.` | Game Mechanics §2 Stage 1 | The frame slides up out of the hive standing upright. Capped cells are matte yellow, and glowing honey shows once they are scraped. Fix the English and French directions. |
| 12 | Look & words | `That golden hive is yours.` / `Cette ruche dorée` | STYLE_GUIDE Wood tokens | The hive is a wooden Langstroth hive. Say "your hive" or "wooden hive". |
| 13 | Completeness | `see Decisions needed` / `voir Décisions requises` | Completeness check | The French refers to a Décisions section that does not exist, and the options table, Sources and Decisions are English only. Give the English and French the same sections, or drop the cross-reference. Also settle the `status: superseded` and the blackboard path mismatch. |
| 14 | Tone & Glossary | `This little meadow is counting on you.` / `And so am I.` | Child Safety | (minor) This is gentle, but the "counting on you" pressure could be softened. It has no link to spending, so it is not blocking. |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 3/10 | The draft invents a "market stand", says tap the hive, adds a "No-Rapid-Tap Mode" toggle, calls Worker Swarm Count "cheapest", and treats the guide choice as three options. |
| Tone & Glossary | 5/10 | Lines are playful and cozy, but "honey money" and "argent de miel" replace the Glossary's "in-game money". |
| Child safety & spending | 9/10 | No fear, guilt or spending pressure. Only the "counting on you" line is mildly heavy. |
| Facts & French | 4/10 | "Without bees, the flowers can't bloom" and "sealed with wax" are unsourced real-world claims. The French otherwise matches. |
| Sources | 10/10 | Checked by script. |
| Look & words | 3/10 | "wooden barrel centrifuge", a tilted frame, glowing capped cells and a "golden hive" all contradict the GDD §2 look. |
| Completeness | 5/10 | The beats match in English and French. But the options, Sources and Decisions are English only, and the French cross-reference points at a missing section. |
