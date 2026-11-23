---
slug: first-time-hint
type: ui-text
started: 2026-11-23
max_rounds: 3
max_tokens: 500000
result: draft
---
# Blackboard: first-time-hint

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
0.3.1 item 4, the first-time hint (game/specs/0.3.1-playtest-fixes.md item 4; designer quiz 2026-11-22). After Play, a small bubble with ONE short line points at the next thing to do, one step at a time, up to the first wildflower patch. Write EN/FR rows for the translation CSV (key, en, fr), French in 'vous' (house style). Keys and what each bubble points at: hint_wait (the hive is filling, points at the hive count: the bees are filling the hive, wait for it), hint_harvest (points at the fork icon over the full hive: harvest it), hint_uncap (first zoom, points at the comb: swipe to uncap the cells), hint_spin (points at the centrifuge icon: load and spin the frames), hint_crank (second stop, points at the centrifuge's crank: tap or hold the crank to spin), hint_sell (points at the sell icon: send the honey off to sell), hint_shop (after the first sale, points at the Shop button: spend your earnings), hint_plant (in the Shop, points at the Habitat tab and then the 'Plant wildflower patch' row: plant a patch for the wild bees), hint_skip (the label of the bubble's Skip button, one word). Each line must fit a small bubble: at most about 40 characters in EN and in FR, 28 px text on a 720 px wide phone screen, an imperative or gentle nudge, cozy and kid-safe, using the GDD's Glossary terms for the harvest steps (GDD §2 harvest flow). No numbers, no spending pressure, no real-world claims.

## Round 1

### Draft (William), round 1

The full draft: `content/_runs/first-time-hint/run-1/round-1.md` (65 lines). Later rounds show only the changes.

### Script check, round 1
VERDICT: FAIL
Checked (voice_check.py, no agent call):
- Sources (T5): 2. Phase 1 Uncapping & Extraction Minigame; 7. Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Sources | "2. Phase 1 Uncapping & Extraction Minigame" | GDD headings | no GDD heading has this name; cite the section by its exact heading |
| 2 | Sources | "7. Story Premise & Onboarding" | GDD headings | no GDD heading has this name; cite the section by its exact heading |

## Round 2

### Changes (William), round 2

~~~~diff
--- round 1
+++ round 2
@@ -7,3 +7,3 @@
 # First-time hint
-**Sources:** `GDD.md` (2. Phase 1 Uncapping & Extraction Minigame, 7. Story Premise & Onboarding, Aesthetic & Tone, Child Safety, Glossary), `game/specs/0.3.1-playtest-fixes.md` (item 4).
+**Sources:** `GDD.md` (Phase 1 Uncapping & Extraction Minigame, Story Premise & Onboarding, Aesthetic & Tone, Child Safety, Glossary), `game/specs/0.3.1-playtest-fixes.md` (item 4).
 
~~~~

### Script check, round 2
VERDICT: PASS
Checked (voice_check.py, no agent call):
- Sources (T5): Phase 1 Uncapping & Extraction Minigame; Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

### Critic, round 2
VERDICT: FAIL
Checked:
- Lore: I compared the fork icon over the full hive, the centrifuge with its crank, the Sell icon on the truck, the Shop and Habitat tab, and the wildflower patch against GDD §2 and Tree C. The names match. Decision 2 miscounts the keys (see row 5).
- Tone & Glossary: Every line is a gentle imperative and cozy. Harvest, uncap, spin, frames, comb and centrifuge match the Farm & Harvest terms and §2. "earnings" is not the Glossary's term "In-game money" (row 6, minor). "wild bees" is not the Glossary's main term "Native bees" (row 7, minor).
- Child safety & spending: "Spend your earnings in the Shop!" and "Dépensez vos gains à la boutique!" are mild, with no pressure, guilt or worth framing. I found nothing else touching purchases, donations or worry.
- Facts & French: I found no real-world statements. "Bees are filling the hive", "Plant a patch for the wild bees!" and the rest are in-world nudges. French and English do not match in meaning for hint_wait, hint_spin, hint_sell and hint_plant (rows 1–4).
- Sources: checked by script.
- Look & words: Objects described are the fork icon, comb, centrifuge, crank, truck and Sell icon. The crank is on the centrifuge and the fork is an icon, which matches §2. The glass bucket is not described.
- Completeness: The EN and FR tables both have 9 rows, and the CSV has 9 rows. The EN table has the columns key, points at, en, chars. The FR table has no "points at" column (row 8). I found no placeholders. The Decisions needed section holds real questions.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Facts & French | `hint_wait,"Bees are filling the hive. Hang tight!","Les abeilles remplissent la ruche."` | Story Premise & Onboarding / request: "wait for it" | The French leaves out the "wait" nudge that the English carries. Add a short French equivalent of "Hang tight!" and keep it within about 40 characters. |
| 2 | Facts & French | `hint_spin,"Tap the centrifuge to spin the frames","Chargez et faites tourner les cadres"` | §2 Phase 1 Uncapping & Extraction Minigame | The English says to tap the centrifuge. The French says "load and spin" and never mentions touching it. Make the two say the same thing, within 40 characters. |
| 3 | Facts & French | `hint_sell,"Tap Sell to send the honey off!","Envoyez le miel à la vente!"` | §2 Stage 3 Bottling & Selling | The English points at the Sell icon with "Tap". The French has no tap and does not name Sell. Align the meaning of the two lines. |
| 4 | Facts & French | `hint_plant,"Plant a patch for the wild bees!","Plantez pour les abeilles sauvages!"` | Tree C: Flower Patches | The French drops "a patch". Add the patch to the French so it matches the English. |
| 5 | Lore | `the spec would need a ninth key (e.g. hint_plant_row)` | Request key list | The request lists nine keys, and hint_skip is the ninth. A new key would be the tenth. Correct the count. |
| 6 | Tone & Glossary | `Spend your earnings in the Shop!` | Glossary > Currencies & Prestige ("In-game money") | (minor) Consider "Spend your money" or wording closer to "In-game money". The request's own wording was "earnings", so this does not block. |
| 7 | Tone & Glossary | `Plant a patch for the wild bees!` | Glossary > Habitat ("Native bees") | (minor) The Glossary's main term is "Native bees", and the request itself says "wild bees". Refer to the designer if the hint should use "native bees". |
| 8 | Completeness | `\| clé \| fr \| car. \|` | Request: EN and FR must have the same sections and columns | Give the FR table the same columns as the EN table. Add a "pointe vers" column with the French for each "points at" entry. |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 7/10 | Icons, crank and Shop match §2. Decision 2 miscounts the keys ("a ninth key"), which is a small slip. |
| Tone & Glossary | 7/10 | The lines are cozy imperatives and the harvest terms are right. "earnings" and "wild bees" drift slightly from the Glossary. |
| Child safety & spending | 9/10 | "Spend your earnings in the Shop!" is gentle and has no pressure or worth framing. |
| Facts & French | 4/10 | The FR drops "Hang tight!", "tap" and "a patch", and hint_spin's FR does not match its EN. No real-world claims were found. |
| Sources | 9/10 | Checked by script. |
| Look & words | 9/10 | The fork icon, crank on the centrifuge and Sell icon match §2. |
| Completeness | 5/10 | The row counts match at 9 and there are no placeholders. The FR table lacks the "points at" column that the EN table has. |

## Round 3

### Changes (William), round 3

~~~~diff
--- round 2
+++ round 3
@@ -30,10 +30,10 @@
 ```
-hint_wait,"Bees are filling the hive. Hang tight!","Les abeilles remplissent la ruche."
+hint_wait,"Bees are filling the hive. Hang tight!","La ruche se remplit. Patience!"
 hint_harvest,"Tap the fork to harvest the hive!","Touchez la fourche pour récolter!"
 hint_uncap,"Swipe across the comb to uncap cells","Glissez pour désoperculer les alvéoles"
-hint_spin,"Tap the centrifuge to spin the frames","Chargez et faites tourner les cadres"
+hint_spin,"Tap the centrifuge to spin the frames","Touchez la centrifugeuse pour la lancer"
 hint_crank,"Tap or hold the crank to spin!","Touchez ou tenez la manivelle!"
-hint_sell,"Tap Sell to send the honey off!","Envoyez le miel à la vente!"
+hint_sell,"Tap Sell to send the honey off!","Touchez Vendre pour envoyer le miel!"
 hint_shop,"Spend your earnings in the Shop!","Dépensez vos gains à la boutique!"
-hint_plant,"Plant a patch for the wild bees!","Plantez pour les abeilles sauvages!"
+hint_plant,"Plant a patch for the wild bees!","Plantez une parcelle pour les abeilles!"
 hint_skip,"Skip","Passer"
@@ -45,13 +45,13 @@
 
-| clé | fr | car. |
-|---|---|---|
-| hint_wait | Les abeilles remplissent la ruche. | 34 |
-| hint_harvest | Touchez la fourche pour récolter! | 33 |
-| hint_uncap | Glissez pour désoperculer les alvéoles | 38 |
-| hint_spin | Chargez et faites tourner les cadres | 36 |
-| hint_crank | Touchez ou tenez la manivelle! | 30 |
-| hint_sell | Envoyez le miel à la vente! | 27 |
-| hint_shop | Dépensez vos gains à la boutique! | 33 |
-| hint_plant | Plantez pour les abeilles sauvages! | 35 |
-| hint_skip | Passer | 6 |
+| clé | pointe vers | fr | car. |
+|---|---|---|---|
+| hint_wait | le compteur de la ruche | La ruche se remplit. Patience! | 30 |
+| hint_harvest | l'icône de fourche sur la ruche pleine | Touchez la fourche pour récolter! | 33 |
+| hint_uncap | le rayon (premier zoom) | Glissez pour désoperculer les alvéoles | 38 |
+| hint_spin | l'icône de la centrifugeuse | Touchez la centrifugeuse pour la lancer | 39 |
+| hint_crank | la manivelle de la centrifugeuse (deuxième arrêt) | Touchez ou tenez la manivelle! | 30 |
+| hint_sell | l'icône Vendre | Touchez Vendre pour envoyer le miel! | 36 |
+| hint_shop | le bouton de la boutique (après la première vente) | Dépensez vos gains à la boutique! | 33 |
+| hint_plant | l'onglet Habitat, puis la ligne « Planter une parcelle de fleurs sauvages » | Plantez une parcelle pour les abeilles! | 39 |
+| hint_skip | le bouton Passer de la bulle | Passer | 6 |
 
@@ -61,4 +61,4 @@
 ## Decisions needed from the designer
-1. **Shop and Sell labels in French.** `hint_shop` says "la boutique" and `hint_sell` avoids naming the Sell icon. If the game's French UI uses other words for Shop and Sell, tell me and I will match them.
-2. **Same line for two targets.** `hint_plant` is shown at the Habitat tab and again at the "Plant wildflower patch" row. If the designer wants different words for each, the spec would need a ninth key (e.g. `hint_plant_row`).
+1. **Shop and Sell labels in French.** `hint_shop` says "la boutique" and `hint_sell` uses "Vendre" for the Sell icon. The French `hint_plant` drops "wild" ("les abeilles") to fit 40 characters with the patch. If the game's French UI uses other words for Shop and Sell, tell me and I will match them.
+2. **Same line for two targets.** `hint_plant` is shown at the Habitat tab and again at the "Plant wildflower patch" row. If the designer wants different words for each, the spec would need a tenth key (e.g. `hint_plant_row`).
 3. **"Fork" in the hint.** The lines call the harvest tool "the fork" / "la fourche" to match the fork icon. Check this against the French wording used elsewhere for the uncapping fork.
~~~~

### Script check, round 3
VERDICT: PASS
Checked (voice_check.py, no agent call):
- Sources (T5): Phase 1 Uncapping & Extraction Minigame; Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

### Critic, round 3
VERDICT: PASS
Checked:
- Lore: The changed "pointe vers" entries (hive counter, fork icon on the full hive, comb, centrifuge icon, crank, Sell icon, Shop button, Habitat tab and its wildflower row, Skip) match GDD §2 and Tree C. Decision 2 now says "tenth key", which fixes row 5.
- Tone & Glossary: The new French lines are gentle imperatives and cozy. "Patience!", "Touchez … la centrifugeuse" and "Vendre" use the right harvest terms. The "earnings" and "wild bees" wording from round 2 is unchanged and was minor.
- Child safety & spending: "Spend your earnings in the Shop!" and "Dépensez vos gains à la boutique!" are mild, with no pressure, guilt or worth framing. Nothing else touches purchases, donations or worry.
- Facts & French: I found no real-world statements. All lines are in-world nudges. The four earlier mismatches are fixed:
  - hint_wait: "Patience!" matches "Hang tight!".
  - hint_spin: "Touchez la centrifugeuse pour la lancer" matches "Tap the centrifuge to spin".
  - hint_sell: "Touchez Vendre pour envoyer le miel!" matches the EN.
  - hint_plant: "Plantez une parcelle pour les abeilles!" has the patch. It drops "wild", and Decision 1 says so.
  - Character counts are 30, 39, 36 and 39, all within 40.
- Sources: checked by script.
- Look & words: The objects described are the fork icon, comb, centrifuge, crank, truck/Sell icon and Shop button. They match §2. The glass bucket is not described.
- Completeness: The EN table, the FR table and the CSV each have 9 rows. The FR table now has the "pointe vers" column to match "points at". I found no placeholders. Decisions needed holds three real questions.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Tone & Glossary | `Spend your earnings in the Shop!` | Glossary > Currencies & Prestige ("In-game money") | (minor) The request's own wording was "earnings", so this does not block. Consider wording closer to "In-game money". |
| 2 | Tone & Glossary | `Plant a patch for the wild bees!` | Glossary > Habitat ("Native bees") | (minor) The Glossary's main term is "Native bees". Refer to the designer, because the request itself says "wild bees". |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 9/10 | The icons, crank, Shop and Habitat targets match §2 and Tree C, and the key count is fixed ("tenth key"). |
| Tone & Glossary | 8/10 | The lines are cozy imperatives with the right harvest terms. "earnings" and "wild bees" drift slightly from the Glossary. |
| Child safety & spending | 9/10 | "Spend your earnings in the Shop!" is gentle, with no pressure or worth framing. |
| Facts & French | 9/10 | There are no real-world claims, and the FR now matches the EN on all nine lines. |
| Sources | 9/10 | Checked by script. |
| Look & words | 9/10 | The fork icon, crank on the centrifuge and Sell icon match §2. |
| Completeness | 9/10 | EN, FR and CSV each have 9 rows, the FR table has the "pointe vers" column, and there are no placeholders. |

## Result

PASS after 3 round(s): `content/first-time-hint.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-23-first-time-hint-run-1/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| William, round 1 | 112,191 | 29,238 | 12 | 33 s |
| William, round 2 | 41,088 | 15,270 | 4 | 5 s |
| Critic, round 2 | 69,084 | 29,547 | 5 | 30 s |
| William, round 3 | 48,742 | 19,311 | 9 | 25 s |
| Critic, round 3 | 17,647 | 17,647 | 1 | 11 s |
| **Total** | **288,752** | | | |
