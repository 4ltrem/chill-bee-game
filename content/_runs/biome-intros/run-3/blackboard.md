---
slug: biome-intros
type: story
started: 2026-11-20
max_rounds: 3
max_tokens: 500000
result: draft
---
# Blackboard: biome-intros

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
Revision of `content/biome-intros.md` (previous run: `content/_runs/biome-intros/run-2/blackboard.md`, status was `draft`).

Designer notes: none; re-check against the current rules.

## Round 1

### Draft (unchanged from the previous run), round 1

The full draft: `content/_runs/biome-intros/run-3/round-1.md` (128 lines). Later rounds show only the changes.

### Script check, round 1
VERDICT: PASS
Checked (voice_check.py, no agent call):
- Sources (T5): Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary; Progression Tiers & Biomes; Land Grid & Units; Tree C Native Habitat
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: Compared the four biome names, hive styles (Langstroth, chalet, lantern, brass solar-powered), honey names, Glowbell and Skybloom, and the Decisions needed guide options against GDD §7, Progression Tiers & Biomes and §3 (flora table). Biomes, hives, honeys and flora match. The guide options do not match the GDD (row 1).
- Tone & Glossary: Read the Title cards and every [GUIDE] line. They are playful and cozy ("Oh my stars", "I promise it shimmers"). Terms used are pocket world, hive, honey, jars and biome names. No rejected or off-glossary money or habitat terms appear.
- Child safety & spending: No line touches purchases, donations, fear or guilt. "Not every beekeeper finds their way here" is a gentle hook with no pressure.
- Facts & French: Real-world statements found:
  - "the blush of fireweed" and "whole hillsides painted in soft violet and rose" (fireweed's real colour, unsourced; row 2).
  - "Your classic wooden Langstroth hive … a beekeeper's most trusted companion, tried-and-true" (a real hive type, unsourced; row 2).
  - "patches of wild clover" and "Pine trees reaching up to the clouds" (GDD biome features, in-world, fine).
  - "the mountain air gives your honey a character all its own" (framed "In this pocket world", fine).
  - Glowbell and Skybloom are labelled "make-believe flower" in EN and "fleur imaginaire" in FR, and their claims are in-world and whimsical. Fine.
  - French matches the English in meaning on all 16 lines.
  - Section 3 says "None", which is wrong given the fireweed and Langstroth lines.
- Sources: Checked by script.
- Look & words: Hives match the GDD: wooden Langstroth, chalet, lantern-shaped hanging, brass solar-powered. Two minor points, see rows 3 and 4. No bucket, truck or jars are described.
- Completeness: Four biomes × (title card + 3 guide lines) in both EN and FR, with identical sections. No empty cells or placeholders. The [GUIDE] tag is acceptable because GDD §7 says all six candidate guides share one script.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Lore | "**Guide character name and personality (GDD: TBD).** … **Wren** — a small, bright-eyed scout bee" | Story Premise & Onboarding | The GDD no longer has the guide as TBD. It lists six candidates in `content/guides.md` (Melli, Pip, Lady Aura, Miel, Queen Maeve, Lumi), and a playtest picks one. Remove Wren, which is not a candidate. Remove or correct the Pip description ("used to be a bee" is Lumi in the GDD). Say the [GUIDE] tag stands in for the playtest winner. |
| 2 | Facts & French | "the blush of fireweed" / "whole hillsides painted in soft violet and rose" / "tried-and-true" | Aesthetic & Tone; Progression Tiers & Biomes | These describe how real fireweed looks and how real Langstroth hives perform, with no source URL. Reword them as clearly in-world scenery that does not claim a real flower colour or hive reliability (for example "a whole new horizon for your hive" and "painted in soft pastel blooms"). The other option is a Ruth brief with a quote. Then correct Section 3 so it no longer says "None". |
| 3 | Look & words (minor) | "glowing softly in the dark like little suns" | Aesthetic & Tone (STYLE_GUIDE V1 Biome glow) | The mushroom glow token is cool cyan-green (0.60, 0.90, 0.95), so "little suns" suggests a warm light. Consider a softer, cooler word such as "little lanterns" or "moons", or confirm with the designer. |
| 4 | Look & words (minor) | "hanging hives that sway gently and fill the grove with a warm amber light" | Progression Tiers & Biomes (STYLE_GUIDE V2) | V2 lets only honey and Biome-glow materials emit light, and the GDD describes the lantern hives only by shape. Consider dropping the claim that the hives light the grove, or confirm with the designer. |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 5/10 | Biomes, hives and honeys match the GDD, but the guide options still say "GDD: TBD" and offer the non-candidate "Wren". |
| Tone & Glossary | 9/10 | "Oh my stars, just look at this place!" and "I promise it shimmers" are playful and cozy, and no off-Glossary terms appear. |
| Child safety & spending | 10/10 | No purchase, donation or pressure line in the draft. |
| Facts & French | 5/10 | The fireweed colour and Langstroth "tried-and-true" claims are real-world and unsourced, and Section 3 says "None". The French matches the English and the fictional flowers are labelled. |
| Sources | 10/10 | Checked by script. |
| Look & words | 7/10 | Hive shapes match the GDD, but the mushroom "little suns" and the hives' "warm amber light" sit uneasily with V1 and V2. |
| Completeness | 9/10 | EN and FR have the same four biomes with four slots each and no placeholders. |

## Round 2

### Changes (William), round 2

~~~~diff
--- round 1
+++ round 2
@@ -22,3 +22,3 @@
 
-**[GUIDE]:** Your classic wooden Langstroth hive is ready and waiting. It's a beekeeper's most trusted companion, tried-and-true and full of golden promise.
+**[GUIDE]:** Your classic wooden Langstroth hive is ready and waiting. It's a beekeeper's cosy first home for the bees, full of golden promise.
 
@@ -30,5 +30,5 @@
 
-> **Title card:** *Cool mountain air, the blush of fireweed, and a whole new horizon for your hive.*
+> **Title card:** *Cool mountain air, soft pastel blooms, and a whole new horizon for your hive.*
 
-**[GUIDE]:** Oh, breathe that in! Pine trees reaching up to the clouds, and whole hillsides painted in soft violet and rose. Your bees are going to love it up here.
+**[GUIDE]:** Oh, breathe that in! Pine trees reaching up to the clouds, and whole hillsides painted in soft pastel blooms. Your bees are going to love it up here.
 
@@ -72,3 +72,3 @@
 
-**[GUIDE] :** Ta ruche Langstroth en bois classique t'attend déjà. C'est la meilleure amie de tout apiculteur qui se respecte — éprouvée, fiable, et débordante de promesses dorées.
+**[GUIDE] :** Ta ruche Langstroth en bois classique t'attend déjà. C'est le premier petit chez-soi de tes abeilles, débordant de promesses dorées.
 
@@ -80,5 +80,5 @@
 
-> **Carte-titre :** *L'air frais de la montagne, le rose de l'épilobe, et un tout nouvel horizon pour ta ruche.*
+> **Carte-titre :** *L'air frais de la montagne, des fleurs aux teintes pastel, et un tout nouvel horizon pour ta ruche.*
 
-**[GUIDE] :** Ah, sens-moi ça ! Des pins qui s'élancent jusqu'aux nuages, et des flancs de montagne tout entiers peints de violet et de rose tendres. Tes abeilles vont adorer ça.
+**[GUIDE] :** Ah, sens-moi ça ! Des pins qui s'élancent jusqu'aux nuages, et des flancs de montagne tout entiers peints de fleurs aux teintes pastel. Tes abeilles vont adorer ça.
 
@@ -116,3 +116,3 @@
 
-None. The biome intro cards are story and onboarding text set inside the game's pocket-world fiction. They name hive styles and flora from the GDD but make no independent real-world factual claims. (Fact-checked GDD elements such as Langstroth hives, fireweed, and Canadian native wildflowers belong to the Bee Journal, not these cards.)
+No sourced real-world facts, and no research brief is needed. The intros are in-world scenery and onboarding text. They name hive styles and flora from the GDD, but they do not state a real flower colour, a real hive's reliability or any other real-world claim. Round 2 removed the earlier lines about fireweed's colour, the hillside colours and the Langstroth being "tried-and-true". Real-world facts about Langstroth hives, fireweed and native wildflowers belong to the Bee Journal, with Ruth's briefs and a conservation-partner review.
 
@@ -122,6 +122,3 @@
 
-1. **Guide character name and personality (GDD: TBD).** The [GUIDE] placeholder is used throughout. Suggested options for the designer to consider:
-   - **Queen Maeve** — a wise, warmly maternal queen bee with a gentle wit.
-   - **Wren** — a small, bright-eyed scout bee, curious and enthusiastic; genderless.
-   - **Pip** — a tiny glowing sprite companion who used to be a bee; whimsical and wordplay-prone.
+1. **Guide identity.** The guide is no longer TBD: the GDD lists six candidates in `content/guides.md` (Melli, Pip, Lady Aura, Miel, Queen Maeve, Lumi), and a playtest picks one. The [GUIDE] tag stands in for the playtest winner; nothing in these intros needs to change until it is picked (the lines are written to fit any of the six voices).
 
~~~~

### Script check, round 2
VERDICT: PASS
Checked (voice_check.py, no agent call):
- Sources (T5): Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary; Progression Tiers & Biomes; Land Grid & Units; Tree C Native Habitat
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

### Critic, round 2
VERDICT: PASS
Checked:
- Lore: Row 1 is fixed. Decisions needed item 1 now lists the six candidates from `content/guides.md` (Melli, Pip, Lady Aura, Miel, Queen Maeve, Lumi). It says the [GUIDE] tag stands in for the playtest winner. Wren and the wrong Pip description are gone. Biomes, hives, honeys and flora are unchanged from round 1 and still match.
- Tone & Glossary: Changed lines "a beekeeper's cosy first home for the bees, full of golden promise" and "soft pastel blooms" are playful and cozy. No off-Glossary terms.
- Child safety & spending: No changed line touches purchases, donations, fear or guilt.
- Facts & French: Row 2 is fixed.
  - The fireweed colour, the hillside violet and rose, and "tried-and-true" are gone.
  - The new text is in-world scenery: "soft pastel blooms" and "a beekeeper's cosy first home".
  - It makes no claim about a real flower colour or a hive's reliability.
  - Section 3 now says "No sourced real-world facts", which is accurate.
  - The French lines match the English in meaning: "des fleurs aux teintes pastel" and "le premier petit chez-soi de tes abeilles". The French drops "beekeeper's", which does not change the meaning.
  - "l'épilobe" is removed from the French.
- Sources: checked by script.
- Look & words: The Langstroth line still describes a wooden hive, which matches the GDD. Rows 3 and 4 from round 1 (the mushroom "little suns" and the lantern hives' "warm amber light") were minor and are not changed. They are carried below.
- Completeness: Four biomes with EN and FR matching in sections and slots. The Decisions needed item is filled. No placeholder found in the changed lines.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Look & words (minor) | "glowing softly in the dark like little suns" | Aesthetic & Tone (STYLE_GUIDE V1 Biome glow) | Still unfixed. The mushroom glow token is cool cyan-green. Consider a cooler word such as "little lanterns" or "moons", or confirm with the designer. |
| 2 | Look & words (minor) | "fill the grove with a warm amber light" | Progression Tiers & Biomes (STYLE_GUIDE V2) | Still unfixed. V2 lets only honey and Biome-glow materials emit light. Consider dropping the claim that the hives light the grove, or confirm with the designer. |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 9/10 | Decisions needed now lists the six GDD guide candidates and treats [GUIDE] as the playtest placeholder. |
| Tone & Glossary | 9/10 | "a beekeeper's cosy first home for the bees" is cozy, and no off-Glossary terms appear. |
| Child safety & spending | 10/10 | No purchase, donation or pressure line in the draft. |
| Facts & French | 9/10 | Fireweed colour and "tried-and-true" are removed, Section 3 is accurate, the fictional flowers are labelled, and the French matches. |
| Sources | 10/10 | Checked by script. |
| Look & words | 7/10 | Hive shapes match the GDD. The "little suns" and "warm amber light" lines are still open as minor rows 1 and 2. |
| Completeness | 9/10 | EN and FR have the same four biomes and slots, and no placeholders remain. |

## Result

PASS after 2 round(s): `content/biome-intros.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-20-biome-intros-run-3/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| Critic, round 1 | 110,364 | 37,185 | 8 | 37 s |
| William, round 2 | 68,753 | 21,311 | 11 | 18 s |
| Critic, round 2 | 17,110 | 17,110 | 1 | 11 s |
| **Total** | **196,227** | | | |
