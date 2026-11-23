---
author: william
type: ui-text
status: approved (designer, 2026-11-23: as written, with French prices as "%d $" (Canadian order), "À venir", "Paramètres")
description: The game's player-facing UI labels (farm view, zooms, bottling summary, toast, Shop, Journal panel, welcome, Settings) as EN/FR translation rows, so the Settings language switch changes every label (0.3.1 item 7).
run: content/_runs/ui-labels/run-1/blackboard.md
---
# UI labels
**Sources:** `GDD.md` (Story Premise & Onboarding, Aesthetic & Tone, Child Safety, Glossary, §3 Progression Trees & Economy Balance), `game/specs/0.3.1-playtest-fixes.md` (items 1, 3, 7), `content/first-time-hint.md`, `content/course-ending-text.md`.

---

## 1. Outline / Text (English)

One row per label. English is exactly as the game shows it today. `%d` and `$%d` stay where the English has them; `$` and numbers are never translated. The two language names are never translated.

| key | where | en |
|---|---|---|
| farm_bees | farm view, hive count | Bees: %d |
| farm_hive_full | farm view, line when the hive is full | Hive full, production paused |
| farm_honey | farm view, honey held | Honey: %d / %d |
| farm_sell | farm view, Sell icon with its price | Sell $%d |
| farm_auto | farm view, auto-sell tag | Auto |
| journal_icon | farm view, Journal icon | Journal |
| tools_icon | zooms, Tools icon and its sheet title | Tools |
| farm_back | Back button (zooms) | Back |
| zoom_uncap_hint | first zoom, instruction line | Drag across the cells to uncap them |
| zoom_all_uncapped | first zoom, when the last cell opens | All cells uncapped! |
| summary_jars | bottling summary, jars made | Jars: %d |
| summary_jars_sold | bottling summary, jars sold | Jars sold: %d |
| summary_value | bottling summary, value line | Value per jar: $%d |
| summary_price | bottling summary, price line | Price per jar: $%d |
| summary_batch_total | bottling summary, batch line | Batch total: $%d |
| summary_total | bottling summary, total line | Total: $%d |
| summary_ok | bottling summary button | OK |
| toast_phase2 | toast when Phase 2 starts | Phase 2: your farm starts running itself |
| shop_title | Shop button and sheet title | Shop |
| shop_close | Shop sheet Close button | Close |
| shop_owned | row state, bought | Owned |
| shop_not_owned | row state, not bought | Not owned |
| shop_level | row level | Lv %d / %d |
| shop_needs_delivery | Auto-Sell row lock line | Needs Faster Delivery %d |
| shop_tab_bees | tab | Bees |
| shop_tab_hive | tab | Hive |
| shop_tab_habitat | tab | Habitat |
| shop_tab_research | tab | Research |
| shop_tab_refinery | tab | Refinery |
| shop_coming_soon | greyed line on an empty tab | Coming soon |
| shop_row_swarm | Bees tab row | Worker Swarm Count |
| shop_row_endurance | Bees tab row | Flight Endurance |
| shop_row_fork | Hive tab row | Heated Uncapping Fork |
| shop_row_gearing | Hive tab row | Centrifuge Gearing |
| shop_row_spigot | Hive tab row | Spigot Flow |
| shop_row_delivery | Hive tab row | Faster Delivery |
| shop_row_autosell | Hive tab row | Auto-Sell |
| shop_row_patch | Habitat tab row | Plant wildflower patch |
| journal_bumble_bees | Journal panel entry title | Bumble Bees |
| welcome_play | welcome overlay button | Play |
| settings_title | Settings sheet title | Settings |
| settings_language | Settings row name | Language |
| settings_close | Settings sheet close button | Close |
| settings_lang_en | language toggle, never translated | English |
| settings_lang_fr | language toggle, never translated | Français |

Notes on the English:
- Row names are the Glossary / GDD §3 names, unchanged. "Bumble Bees" is the Journal entry title as the game has it.
- No new claims, no numbers beyond the placeholders, no spending pressure. "Needs Faster Delivery %d" states a requirement; it does not urge a purchase.

## 2. Texte (français canadien)

Vouvoiement. La boutique, Vendre, Carnet des abeilles et la fourche suivent les textes approuvés (`first-time-hint`, `course-ending-text`). Pas d'espace avant « ! » (comme dans `first-time-hint`); espace avant « : » (usage québécois). Chaque libellé reste à peu près aussi court que l'anglais; les plus longs sont notés en décision 2.

| clé | où | fr |
|---|---|---|
| farm_bees | ferme, compteur de la ruche | Abeilles : %d |
| farm_hive_full | ferme, ligne de ruche pleine | Ruche pleine, production en pause |
| farm_honey | ferme, miel en réserve | Miel : %d / %d |
| farm_sell | ferme, icône Vendre avec son prix | Vendre %d $ |
| farm_auto | ferme, étiquette de vente auto | Auto |
| journal_icon | ferme, icône du Carnet | Carnet |
| tools_icon | zooms, icône Outils et titre de sa feuille | Outils |
| farm_back | bouton Retour (zooms) | Retour |
| zoom_uncap_hint | premier zoom, consigne | Glissez pour désoperculer les alvéoles |
| zoom_all_uncapped | premier zoom, dernière alvéole ouverte | Alvéoles désoperculées! |
| summary_jars | bilan de mise en pots, pots faits | Pots : %d |
| summary_jars_sold | bilan, pots vendus | Pots vendus : %d |
| summary_value | bilan, ligne de valeur | Valeur du pot : %d $ |
| summary_price | bilan, ligne de prix | Prix du pot : %d $ |
| summary_batch_total | bilan, total du lot | Total du lot : %d $ |
| summary_total | bilan, total | Total : %d $ |
| summary_ok | bilan, bouton | OK |
| toast_phase2 | message au début de la phase 2 | Phase 2 : votre ferme tourne toute seule |
| shop_title | bouton et titre de la feuille | Boutique |
| shop_close | bouton Fermer de la boutique | Fermer |
| shop_owned | état de la ligne, acheté | Acquis |
| shop_not_owned | état de la ligne, pas acheté | Non acquis |
| shop_level | niveau de la ligne | Niv. %d / %d |
| shop_needs_delivery | ligne de verrou de la vente auto | Requiert Livraison rapide %d |
| shop_tab_bees | onglet | Abeilles |
| shop_tab_hive | onglet | Ruche |
| shop_tab_habitat | onglet | Habitat |
| shop_tab_research | onglet | Recherche |
| shop_tab_refinery | onglet | Raffinerie |
| shop_coming_soon | ligne grisée d'un onglet vide | À venir |
| shop_row_swarm | ligne, onglet Abeilles | Essaim d'ouvrières |
| shop_row_endurance | ligne, onglet Abeilles | Endurance de vol |
| shop_row_fork | ligne, onglet Ruche | Fourche chauffante |
| shop_row_gearing | ligne, onglet Ruche | Engrenage centrifuge |
| shop_row_spigot | ligne, onglet Ruche | Débit du robinet |
| shop_row_delivery | ligne, onglet Ruche | Livraison rapide |
| shop_row_autosell | ligne, onglet Ruche | Vente auto |
| shop_row_patch | ligne, onglet Habitat | Planter des fleurs sauvages |
| journal_bumble_bees | titre de la fiche du Carnet | Bourdons |
| welcome_play | bouton de l'écran d'accueil | Jouer |
| settings_title | titre de la feuille des paramètres | Paramètres |
| settings_language | nom de la ligne | Langue |
| settings_close | bouton de fermeture des paramètres | Fermer |
| settings_lang_en | bascule de langue, jamais traduit | English |
| settings_lang_fr | bascule de langue, jamais traduit | Français |

Translation CSV rows (key, en, fr; every cell quoted):

```
farm_bees,"Bees: %d","Abeilles : %d"
farm_hive_full,"Hive full, production paused","Ruche pleine, production en pause"
farm_honey,"Honey: %d / %d","Miel : %d / %d"
farm_sell,"Sell $%d","Vendre %d $"
farm_auto,"Auto","Auto"
journal_icon,"Journal","Carnet"
tools_icon,"Tools","Outils"
farm_back,"Back","Retour"
zoom_uncap_hint,"Drag across the cells to uncap them","Glissez pour désoperculer les alvéoles"
zoom_all_uncapped,"All cells uncapped!","Alvéoles désoperculées!"
summary_jars,"Jars: %d","Pots : %d"
summary_jars_sold,"Jars sold: %d","Pots vendus : %d"
summary_value,"Value per jar: $%d","Valeur du pot : %d $"
summary_price,"Price per jar: $%d","Prix du pot : %d $"
summary_batch_total,"Batch total: $%d","Total du lot : %d $"
summary_total,"Total: $%d","Total : %d $"
summary_ok,"OK","OK"
toast_phase2,"Phase 2: your farm starts running itself","Phase 2 : votre ferme tourne toute seule"
shop_title,"Shop","Boutique"
shop_close,"Close","Fermer"
shop_owned,"Owned","Acquis"
shop_not_owned,"Not owned","Non acquis"
shop_level,"Lv %d / %d","Niv. %d / %d"
shop_needs_delivery,"Needs Faster Delivery %d","Requiert Livraison rapide %d"
shop_tab_bees,"Bees","Abeilles"
shop_tab_hive,"Hive","Ruche"
shop_tab_habitat,"Habitat","Habitat"
shop_tab_research,"Research","Recherche"
shop_tab_refinery,"Refinery","Raffinerie"
shop_coming_soon,"Coming soon","À venir"
shop_row_swarm,"Worker Swarm Count","Essaim d'ouvrières"
shop_row_endurance,"Flight Endurance","Endurance de vol"
shop_row_fork,"Heated Uncapping Fork","Fourche chauffante"
shop_row_gearing,"Centrifuge Gearing","Engrenage centrifuge"
shop_row_spigot,"Spigot Flow","Débit du robinet"
shop_row_delivery,"Faster Delivery","Livraison rapide"
shop_row_autosell,"Auto-Sell","Vente auto"
shop_row_patch,"Plant wildflower patch","Planter des fleurs sauvages"
journal_bumble_bees,"Bumble Bees","Bourdons"
welcome_play,"Play","Jouer"
settings_title,"Settings","Paramètres"
settings_language,"Language","Langue"
settings_close,"Close","Fermer"
settings_lang_en,"English","English"
settings_lang_fr,"Français","Français"
```

## 3. Real-world facts
None.

## Decisions needed from the designer
1. **`$` placement in French.** I kept `$%d` exactly as the English has it ("Vendre $%d", "Total : $%d"), as the request asks. Canadian French usually writes "%d $". If you want that, Patricia would need the placeholder order changed in those five rows (`farm_sell`, `summary_value`, `summary_price`, `summary_batch_total`, `summary_total`).
2. **Longer French labels.** Longer than the English: `farm_hive_full` (33 vs 28), `shop_needs_delivery` (28 vs 24), `shop_row_gearing` (20 vs 19), `shop_row_fork` (18 vs 21, shorter). The longest, `zoom_uncap_hint` and `farm_hive_full`, are the ones to check in Quinn's shots at 28–32 px. No label is meant to wrap on the 720 px sheet; the 120 px buttons carry only "Carnet", "Retour", "Jouer", "Fermer", "Auto" and "OK".
3. **French row names are my choices.** The Glossary has no French names for the Shop rows. I shortened "Heated Uncapping Fork" to "Fourche chauffante" (the fork, as in `first-time-hint`) and "Plant wildflower patch" to "Planter des fleurs sauvages" (the hint's longer form, "parcelle de fleurs sauvages", would not fit one line). Alternatives: "Nombre d'abeilles ouvrières" for the swarm row, "Engrenage de la centrifugeuse" for gearing; both longer.
4. **"Coming soon".** `0.3.1-playtest-fixes.md` item 3 gives "Bientôt disponible" for `shop_coming_soon`. I wrote "À venir" to keep it near the English's length. Pick one; the spec text would need the same word.
5. **Owned / Not owned.** "Acquis" / "Non acquis" were chosen over "Possédé" (longer and stiffer). "Lv" is "Niv.".
6. **Settings title.** "Paramètres" (common in Québec apps) or "Réglages". Say if you prefer the latter.
7. **Keys beyond your list.** Added `settings_close` (item 7 says the close label is part of this run; it could reuse `shop_close` instead) and `welcome_play` (the welcome overlay's prefix was not in your list). `farm_back` is also used in the zooms. The two jar-summary pairs are given as separate keys; tell me if each pair is really one label shown in two states.
8. **"Auto" tag and "Vente auto".** The farm tag "Auto" is the same in both languages; the Auto-Sell row name is "Vente auto". Confirm you are happy with the repeat.
