---
author: william
type: ui-text
status: approved (designer, 2026-11-23, as written: "boutique" for Shop and "Vendre" for Sell become the French UI words)
description: The first-time hint bubbles shown after Play, one short line per step up to the first wildflower patch, as EN/FR translation rows (0.3.1 item 4).
run: content/_runs/first-time-hint/run-1/blackboard.md
---
# First-time hint
**Sources:** `GDD.md` (Phase 1 Uncapping & Extraction Minigame, Story Premise & Onboarding, Aesthetic & Tone, Child Safety, Glossary), `game/specs/0.3.1-playtest-fixes.md` (item 4).

---

## 1. Outline / Text (English)

One bubble, one line, one step at a time. Each line is a gentle nudge in the imperative, 40 characters or fewer, with no numbers and no spending pressure.

| key | points at | en | chars |
|---|---|---|---|
| hint_wait | the hive count | Bees are filling the hive. Hang tight! | 38 |
| hint_harvest | the fork icon over the full hive | Tap the fork to harvest the hive! | 33 |
| hint_uncap | the comb (first zoom) | Swipe across the comb to uncap cells | 36 |
| hint_spin | the centrifuge icon | Tap the centrifuge to spin the frames | 37 |
| hint_crank | the centrifuge's crank (second stop) | Tap or hold the crank to spin! | 30 |
| hint_sell | the sell icon | Tap Sell to send the honey off! | 31 |
| hint_shop | the Shop button (after the first sale) | Spend your earnings in the Shop! | 32 |
| hint_plant | the Habitat tab, then the "Plant wildflower patch" row | Plant a patch for the wild bees! | 32 |
| hint_skip | the bubble's Skip button | Skip | 4 |

Translation CSV rows (key, en, fr):

```
hint_wait,"Bees are filling the hive. Hang tight!","La ruche se remplit. Patience!"
hint_harvest,"Tap the fork to harvest the hive!","Touchez la fourche pour récolter!"
hint_uncap,"Swipe across the comb to uncap cells","Glissez pour désoperculer les alvéoles"
hint_spin,"Tap the centrifuge to spin the frames","Touchez la centrifugeuse pour la lancer"
hint_crank,"Tap or hold the crank to spin!","Touchez ou tenez la manivelle!"
hint_sell,"Tap Sell to send the honey off!","Touchez Vendre pour envoyer le miel!"
hint_shop,"Spend your earnings in the Shop!","Dépensez vos gains à la boutique!"
hint_plant,"Plant a patch for the wild bees!","Plantez une parcelle pour les abeilles!"
hint_skip,"Skip","Passer"
```

## 2. Texte (français canadien)

Vouvoiement, comme le reste de l'interface. Pas d'espace avant « ! » (usage québécois).

| clé | pointe vers | fr | car. |
|---|---|---|---|
| hint_wait | le compteur de la ruche | La ruche se remplit. Patience! | 30 |
| hint_harvest | l'icône de fourche sur la ruche pleine | Touchez la fourche pour récolter! | 33 |
| hint_uncap | le rayon (premier zoom) | Glissez pour désoperculer les alvéoles | 38 |
| hint_spin | l'icône de la centrifugeuse | Touchez la centrifugeuse pour la lancer | 39 |
| hint_crank | la manivelle de la centrifugeuse (deuxième arrêt) | Touchez ou tenez la manivelle! | 30 |
| hint_sell | l'icône Vendre | Touchez Vendre pour envoyer le miel! | 36 |
| hint_shop | le bouton de la boutique (après la première vente) | Dépensez vos gains à la boutique! | 33 |
| hint_plant | l'onglet Habitat, puis la ligne « Planter une parcelle de fleurs sauvages » | Plantez une parcelle pour les abeilles! | 39 |
| hint_skip | le bouton Passer de la bulle | Passer | 6 |

## 3. Real-world facts
None.

## Decisions needed from the designer
1. **Shop and Sell labels in French.** `hint_shop` says "la boutique" and `hint_sell` uses "Vendre" for the Sell icon. The French `hint_plant` drops "wild" ("les abeilles") to fit 40 characters with the patch. If the game's French UI uses other words for Shop and Sell, tell me and I will match them.
2. **Same line for two targets.** `hint_plant` is shown at the Habitat tab and again at the "Plant wildflower patch" row. If the designer wants different words for each, the spec would need a tenth key (e.g. `hint_plant_row`).
3. **"Fork" in the hint.** The lines call the harvest tool "the fork" / "la fourche" to match the fork icon. Check this against the French wording used elsewhere for the uncapping fork.
4. **Length at 28 px.** The lines are 27 to 38 characters. Quinn's shots should confirm that the longest ones (`hint_wait`, `hint_uncap` in FR) fit the bubble at 720 px.
