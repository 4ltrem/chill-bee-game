---
author: william
type: ui-text
status: draft
description: 0.3.0 victory screen heading and lines, the wildflower-patch and bumble-bee-visitor toasts, and the skip-to-ending icon label (EN/FR, translation CSV rows)
---
# Course ending: victory screen, toasts and skip label
**Sources:** `GDD.md` (§7 Story Premise & Onboarding; Aesthetic & Tone; Child Safety; §3 Progression Trees & Economy Balance; Glossary), `proposals/design/course-ending.md` (option B, designer decisions 2026-11-22).

---

## 1. Outline / Text (English)

Rows for the translation CSV (`keys, en, fr`). The CSV rows are in section 2 beside the French. The English is below.

| Key | Where | English |
|---|---|---|
| `victory_title` | Victory screen heading | The meadow is thriving! |
| `victory_body` | Victory screen, under the heading | Your pocket world is restored and buzzing with life. Thank you, beekeeper! Stay as long as you like: the bees are happy to keep going. |
| `victory_button` | Victory screen button (the one button named in the proposal) | Keep playing |
| `toast_patch_planted` | Toast after planting a wildflower patch | A new wildflower patch is blooming! |
| `toast_bumble_visitor` | Toast when Habitat Health reaches thriving and the Journal entry unlocks | A bumble bee has dropped by! Peek at the new page in your Bee Journal. |
| `skip_icon_label` | Label for the small skip-to-ending icon on the farm view | Skip to ending |

Notes on the English:
- "Pocket world" and "beekeeper" come from the §7 premise. "Wildflower patch" and "Bee Journal" are the names the proposal and the Glossary use.
- "Bumble bee" is two words, as in the GDD's species table.
- The patch toast names no species. The victory text makes no real-world, conservation or donation claim and asks for nothing.
- The victory text says play continues without any pressure. It does not tie the win to the player's worth.

## 2. Texte (français canadien)

| Clé | Où | Français |
|---|---|---|
| `victory_title` | Titre de l'écran de victoire | Le pré est en pleine floraison ! |
| `victory_body` | Écran de victoire, sous le titre | Ton monde de poche est restauré et bourdonne de vie. Merci, apiculteur ou apicultrice ! Reste aussi longtemps que tu veux : les abeilles sont ravies de continuer. |
| `victory_button` | Bouton de l'écran de victoire | Continuer à jouer |
| `toast_patch_planted` | Message après la plantation d'une parcelle de fleurs sauvages | Une nouvelle parcelle de fleurs sauvages s'épanouit ! |
| `toast_bumble_visitor` | Message quand la santé de l'habitat atteint « florissant » et que la fiche du Journal se débloque | Un bourdon est passé nous voir ! Jette un œil à la nouvelle page de ton Journal des abeilles. |
| `skip_icon_label` | Étiquette de la petite icône « aller à la fin » sur la ferme | Aller à la fin |

Translation CSV rows (`keys,en,fr`; quote any cell with a comma):

```
victory_title,"The meadow is thriving!","Le pré est en pleine floraison !"
victory_body,"Your pocket world is restored and buzzing with life. Thank you, beekeeper! Stay as long as you like: the bees are happy to keep going.","Ton monde de poche est restauré et bourdonne de vie. Merci, apiculteur ou apicultrice ! Reste aussi longtemps que tu veux : les abeilles sont ravies de continuer."
victory_button,"Keep playing","Continuer à jouer"
toast_patch_planted,"A new wildflower patch is blooming!","Une nouvelle parcelle de fleurs sauvages s'épanouit !"
toast_bumble_visitor,"A bumble bee has dropped by! Peek at the new page in your Bee Journal.","Un bourdon est passé nous voir ! Jette un œil à la nouvelle page de ton Journal des abeilles."
skip_icon_label,"Skip to ending","Aller à la fin"
```

## 3. Real-world facts
None.

## Decisions needed from the designer
1. **French name of the Bee Journal.** I found no French string for it in the repository. I used "Journal des abeilles" as a placeholder. Confirm it or give the name the Journal screen uses.
2. **Form of address in French.** I used the informal "tu" and the inclusive "apiculteur ou apicultrice". Alternatives: "vous" (formal), or "Bravo, au rucher !" with no address at all. Please pick one house style for all French UI text.
3. **Skip label wording.** Options: "Skip to ending" (proposed), "Visit the finale", or "Jump to the meadow's best day". If the icon is icon-only, this key may serve only as the accessibility or tooltip label.
4. **Victory summary line.** The proposal's victory screen also holds a small summary (patches planted, jars sold). That was not in this request, so I did not write labels for it. Tell me if you want them.
5. **Thanks line.** "Thank you, beekeeper!" is a warm thanks from the game. If Connie wants all thanks wording kept clear of anything near donations, it can be removed. The text has no donation link.
