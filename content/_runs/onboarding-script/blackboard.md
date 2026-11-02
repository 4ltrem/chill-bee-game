---
slug: onboarding-script
type: onboarding
started: 2026-10-31
max_rounds: 3
result: draft
---
# Blackboard: onboarding-script

Shared by William and the critic for this run only. The script writes the drafts; the critic appends its verdicts.

## Request
The guide character's script for a new player's first session (GDD Story Premise & Onboarding): explain why the meadow matters and introduce the farm, guide the first manual harvest (uncapping, then centrifuge extraction), and guide the first upgrade purchase. Short lines suited to mobile dialogue bubbles. The guide's name and personality are TBD in the GDD, so offer 2-3 options rather than choosing one.

## Round 1

### Draft (William), round 1

~~~~markdown
---
author: william
type: onboarding
status: draft
description: Guide character dialogue script for a new player's first session — welcome, first manual harvest (uncapping + centrifuge), and first upgrade purchase
run: content/_runs/onboarding-script/blackboard.md
rounds: 1
---
# Onboarding Script — First Session
**Author:** William, the Writer
**Sources:** `GDD.md` (Story Premise & Onboarding §7, Phase 1 Uncapping & Extraction Minigame §2, Progression Trees §3, Aesthetic & Tone, Child Safety, Glossary).
**Request:** The guide character's script for a new player's first session: explain why the meadow matters and introduce the farm, guide the first manual harvest (uncapping, then centrifuge extraction), and guide the first upgrade purchase. Short lines suited to mobile dialogue bubbles.
**Status:** Draft. Guide name and personality are TBD in the GDD — three options offered below. Accessibility branch (No-Rapid-Tap Mode) and exact Upgrade Shop UI label need designer confirmation. Nothing in this script touches monetisation, donations or kid-mode copy; flag for Connie if any of those appear in a future revision.

---

## 1. Outline / Text (English)

> **How to read this script**
> Each indented line is one dialogue bubble — short enough to fit on a mobile screen.
> `[GAME]` lines are stage directions for the UI team, not player-facing copy.
> The guide's name is a placeholder written **[GUIDE]** throughout; see *Decisions needed* for three options.

---

### ACT 1 — Welcome to Sunny Meadow

`[GAME: First launch. The pocket-world farm fades in — rolling green hills, wild clover, a lone wooden hive. The guide character appears in the corner.]`

**[GUIDE]:**
> "Oh! A visitor! I've been waiting so long for someone like you."

**[GUIDE]:**
> "This tiny world needs a beekeeper. And lucky me — here you are!"

**[GUIDE]:**
> "Take a look around. These rolling hills are Sunny Meadow — your very first biome."

**[GUIDE]:**
> "Wildflowers and bees keep this place alive. The more flowers you plant, the healthier the meadow… and the more wild native bees will want to move in!"

**[GUIDE]:**
> "But first things first. Your honeybees are already out there, visiting every clover patch they can find."

**[GUIDE]:**
> "They'll fill the hive before you know it. Don't worry — they'll keep working even when it's full, for a little while. But let's not keep them waiting too long!"

`[GAME: Time-lapse animation: bees fly loops between flowers and the hive. The hive-storage bar fills to capacity. A gentle chime plays. Harvest prompt appears.]`

---

### ACT 2 — First Manual Harvest: Uncapping

`[GAME: Tapping the harvest prompt zooms the camera into the Uncapping screen — a 3D wooden honeycomb frame tilted at an isometric angle. Cells glow matte yellow under a warm light.]`

**[GUIDE]:**
> "Your hive is full — harvest time!"

**[GUIDE]:**
> "See those golden cells? Your bees sealed the honey inside with little wax caps. Smart bees!"

**[GUIDE]:**
> "Swipe your uncapping tool across the cells to open them up."

`[GAME: Animated arrow shows a swipe gesture. Player swipes. Pop effects and haptic feedback fire. Cells shift from capped gold to glowing liquid gold.]`

**[GUIDE]:**
> "Oh! Listen to that pop! You're a natural."

**[GUIDE]:**
> "Keep going! Swipe until every cell is glowing — that's all the honey ready to spin."

`[GAME: Player finishes uncapping the frame. All cells gleam. A satisfying chime plays. The frame tilts toward the centrifuge drum below.]`

---

### ACT 3 — First Manual Harvest: Centrifuge Extraction

`[GAME: Frame drops into a low-poly wooden barrel centrifuge. Honey streams wait inside the cells. The crank button pulses.]`

**[GUIDE]:**
> "Now the fun part! The frame goes into the centrifuge."

**[GUIDE]:**
> "Tap the crank — faster, faster! Spin the honey right out of the comb!"

`[GAME: Player taps/spins the crank. The drum accelerates. Golden honey streams spray against the glass walls. Jars fill at the spigot below.]`

> *(No-Rapid-Tap Mode alternate line):*
> "Hold the crank and let it spin! The honey will fly right out of the comb."

**[GUIDE]:**
> "Oh, look at that golden waterfall! Beautiful."

`[GAME: Batch-complete modal appears: base honey value, tool precision bonus, artisanal quality multiplier, total jars earned.]`

**[GUIDE]:**
> "Your very first batch of Wildflower Gold Honey — straight from Sunny Meadow!"

**[GUIDE]:**
> "Pop over to the Market Stand to sell it. The meadow's customers can't wait."

`[GAME: Honey is added to inventory. Market Stand button pulses. Player taps to sell. In-game money counter ticks up cheerfully.]`

---

### ACT 4 — First Upgrade Purchase

`[GAME: Post-sale. Guide reappears. Upgrade Shop button pulses gently in the corner.]`

**[GUIDE]:**
> "Well done! That honey money is yours to spend."

**[GUIDE]:**
> "Open the Upgrade Shop — see those shiny tools?"

`[GAME: Upgrade Shop opens to Tree B: Hive & Tool Efficiency. The Heated Uncapping Fork is highlighted.]`

**[GUIDE]:**
> "A better uncapping tool means wider swipes and cleaner cuts — more honey every single harvest."

**[GUIDE]:**
> "Go on, pick one! Your bees will be thrilled."

`[GAME: Player taps the upgrade. Purchase animation plays — tool gleams, bees cheer.]`

**[GUIDE]:**
> "Look at you — a real beekeeper! The meadow is already a little brighter."

**[GUIDE]:**
> "There's so much more ahead: wild native bees, new flowers, whole new worlds beyond these hills…"

**[GUIDE]:**
> "But that's for you to discover. Go on — your bees are counting on you!"

`[GAME: Guide waves goodbye. Player is returned to the Farm View. Normal gameplay begins.]`

---

## 2. Texte (français canadien)

> **Comment lire ce script**
> Chaque ligne en retrait correspond à une bulle de dialogue — assez courte pour tenir sur un écran mobile.
> Les lignes `[JEU]` sont des indications de mise en scène, pas du texte destiné au joueur.
> Le nom du guide est un paramètre à confirmer, indiqué **[GUIDE]** tout au long du texte; voir *Décisions requises* pour trois options.

---

### ACTE 1 — Bienvenue dans le Pré ensoleillé

`[JEU: Premier lancement. La ferme du monde-poche s'affiche en fondu — collines verdoyantes, trèfle sauvage, une ruche de bois solitaire. Le personnage guide apparaît dans un coin.]`

**[GUIDE]:**
> « Oh! Un visiteur! Ça faisait si longtemps que j'attendais quelqu'un comme toi. »

**[GUIDE]:**
> « Ce petit monde a besoin d'un apiculteur. Et quelle chance — te voilà! »

**[GUIDE]:**
> « Regarde autour de toi. Ces collines ondulantes, c'est le Pré ensoleillé — ton tout premier biome. »

**[GUIDE]:**
> « Les fleurs sauvages et les abeilles gardent ce monde bien vivant. Plus tu plantes, plus le pré est en santé… et plus les abeilles sauvages indigènes auront envie de s'installer! »

**[GUIDE]:**
> « Mais commençons par le commencement. Tes abeilles butinent déjà dehors, à visiter chaque touffe de trèfle qu'elles trouvent. »

**[GUIDE]:**
> « Elles vont remplir la ruche avant que tu t'en rendes compte. T'inquiète pas — elles continueront à travailler même quand elle sera pleine, pour un petit bout de temps. Mais on ne va pas les faire attendre trop longtemps! »

`[JEU: Animation accélérée : les abeilles font des allers-retours entre les fleurs et la ruche. La barre de stockage monte à pleine capacité. Un carillon doux sonne. L'invite de récolte apparaît.]`

---

### ACTE 2 — Première récolte manuelle : désoperculation

`[JEU: En appuyant sur l'invite de récolte, la caméra zoome sur l'écran de désoperculation — un cadre de ruche en bois 3D incliné en vue isométrique. Les alvéoles brillent d'un jaune mat sous une lumière chaleureuse.]`

**[GUIDE]:**
> « Ta ruche est pleine — c'est le temps de la récolte! »

**[GUIDE]:**
> « Tu vois ces alvéoles dorées? Tes abeilles ont scellé le miel à l'intérieur avec de petits couvercles de cire. Des abeilles bien futées! »

**[GUIDE]:**
> « Passe ton outil de désoperculation sur les alvéoles pour les ouvrir. »

`[JEU: Une flèche animée montre le geste de balayage. Le joueur balaye. Des effets de bulles et de vibrations haptiques se déclenchent. Les alvéoles passent de l'or mat à l'or liquide lumineux.]`

**[GUIDE]:**
> « Oh! Tu entends ce petit clic? Tu as vraiment le tour! »

**[GUIDE]:**
> « Continue! Balaye jusqu'à ce que chaque alvéole brille — tout le miel est prêt à être extrait. »

`[JEU: Le joueur termine la désoperculation. Toutes les alvéoles scintillent. Un carillon satisfaisant retentit. Le cadre s'incline vers le tambour de centrifugeuse en dessous.]`

---

### ACTE 3 — Première récolte manuelle : extraction à la centrifugeuse

`[JEU: Le cadre tombe dans une centrifugeuse en bois de style tonneau. Le miel attend dans les alvéoles. Le bouton de manivelle pulse doucement.]`

**[GUIDE]:**
> « Maintenant, la partie la plus amusante! Le cadre entre dans la centrifugeuse. »

**[GUIDE]:**
> « Appuie sur la manivelle — plus vite, plus vite! Fais tourner le miel hors du rayon! »

`[JEU: Le joueur appuie sur la manivelle ou la fait tourner. Le tambour s'accélère. Des filets de miel doré giclent contre les parois en verre. Les pots se remplissent au robinet en dessous.]`

> *(Variante Mode sans tapotements rapides) :*
> « Maintiens la manivelle et laisse-la tourner! Le miel va s'élancer hors du rayon. »

**[GUIDE]:**
> « Oh, regarde cette cascade dorée! C'est magnifique. »

`[JEU: La fenêtre de résumé de lot s'affiche : valeur de base du miel, bonus de précision de l'outil, multiplicateur de qualité artisanale, total de pots récoltés.]`

**[GUIDE]:**
> « Ta toute première récolte de Miel d'or des fleurs sauvages — directement du Pré ensoleillé! »

**[GUIDE]:**
> « Passe au kiosque de marché pour le vendre. Les clients du pré ont hâte de le goûter! »

`[JEU: Le miel est ajouté à l'inventaire. Le bouton du kiosque de marché pulse. Le joueur appuie pour vendre. Le compteur d'argent de miel monte joyeusement.]`

---

### ACTE 4 — Premier achat d'amélioration

`[JEU: Après la vente. Le guide réapparaît. Le bouton de la boutique d'améliorations pulse doucement dans le coin.]`

**[GUIDE]:**
> « Bravo! Cet argent de miel t'appartient. »

**[GUIDE]:**
> « Ouvre la boutique d'améliorations — tu vois ces outils tout brillants? »

`[JEU: La boutique d'améliorations s'ouvre sur l'arbre B : Efficacité de la ruche et des outils. La Fourche de désoperculation chauffante est mise en évidence.]`

**[GUIDE]:**
> « Un meilleur outil de désoperculation, c'est des passages plus larges et des coupes plus nettes — plus de miel à chaque récolte. »

**[GUIDE]:**
> « Vas-y, choisis-en un! Tes abeilles vont être ravies. »

`[JEU: Le joueur appuie sur l'amélioration. Animation d'achat — l'outil brille, les abeilles font la fête.]`

**[GUIDE]:**
> « Te voilà — un vrai apiculteur! Le pré a déjà l'air un peu plus lumineux. »

**[GUIDE]:**
> « Il y a encore tellement à découvrir : des abeilles sauvages indigènes, de nouvelles fleurs, des mondes entiers au-delà de ces collines… »

**[GUIDE]:**
> « Mais c'est à toi de les explorer. Allez — tes abeilles comptent sur toi! »

`[JEU: Le guide fait un signe d'au revoir. Le joueur revient à la vue de la ferme. Le jeu normal commence.]`

---

## 3. Sources

This script contains no real-world factual claims requiring citation. All named flowers, species and mechanics are drawn directly from `GDD.md`. Journal facts for native bee species will appear in separate `journal-*.md` files with citations reviewed by a conservation partner.

*Wildflower Gold Honey* — name sourced from GDD §Progression Tiers & Biomes, Sunny Meadow entry. No external citation required.

---

## Decisions needed from the designer

1. **Guide character name and personality.** The GDD lists this as TBD (§7: "a guide character (e.g., a queen bee; name and personality TBD)"). Three options — choose one before production art begins:

   | Option | Name | Species | Voice / Personality | Notes |
   |---|---|---|---|---|
   | A | **Queenie** | Queen bee | Warm, motherly, gently authoritative. Speaks in confident short sentences. Calm even when excited. | Reinforces the real-world queen bee role; very readable for all ages. |
   | B | **Bixby** | Worker bee scout | Excitable, pun-loving, speaks in bursts of enthusiasm. Uses a lot of "Oh!"s and ellipses. Younger voice. | High energy matches the tactile minigame; may need toning down for cozy players. |
   | C | **Miel** | Elder drone (retired) | Calm, poetic, slightly mysterious. Speaks as though the meadow is very old and very precious. Name means *honey* in French, so it works bilingually. | Fits the whimsical pocket-world tone; easier to voice in both English and Canadian French with consistent personality. |

2. **Upgrade Shop UI label.** The script uses "Upgrade Shop" as written in GDD §9 (UI & Screens). Confirm this is the final in-game label before script lock.

3. **Bee Journal mention in onboarding.** The script currently ends with a teaser ("wild native bees… whole new worlds beyond these hills") rather than naming the Bee Journal explicitly. Confirm: should the Journal be name-dropped in the first-session script, or saved for the moment the player's first native bee arrives?

4. **No-Rapid-Tap Mode branch.** The centrifuge dialogue has an alternate line for No-Rapid-Tap Mode (§8 Accessibility). Confirm whether the script should ship as two branching versions or as a single script that the game substitutes one line in at runtime.

5. **Market Stand sell step.** The script includes a short beat for selling honey at the Market Stand between harvest and upgrade. If the first sell is automated or skipped in the tutorial flow, this beat can be removed — confirm intended tutorial flow.
~~~~

### Critic, round 1
VERDICT: PASS
Checked:
- Lore: Guide character verified as TBD with three options offered (as required); GDD §7 gives "queen bee" as one example only, so options B (worker bee scout) and C (elder drone) are not contradictions. Sunny Meadow, Market Stand, Upgrade Shop, Tree B: Hive & Tool Efficiency, Heated Uncapping Fork, Wildflower Gold Honey, pocket-world premise, and in-game money / Royal Crystal carry-over rules all match GDD. No invented characters, places or systems found.
- Tone & Glossary: All four acts checked. Tone is playful, whimsical, and cozy throughout (consistent with GDD Aesthetic & Tone). UI labels used correctly: Upgrade Shop (§9), Market Stand (§1 loop), Tree B: Hive & Tool Efficiency (§3), Heated Uncapping Fork (§3), No-Rapid-Tap Mode (§8). Informal currency phrase "honey money" / "argent de miel" in dialogue noted below.
- Child safety & spending: Act 4 purchase-adjacent lines checked in full ("Go on, pick one! Your bees will be thrilled."; "Well done! That honey money is yours to spend."; "Look at you — a real beekeeper!"). No fear, guilt, pressure to spend, or link between purchase and player worth found. No mention of donations, subscriptions, premium currency or Impact Pass. Closing line "your bees are counting on you" is play-motivation only, not spending pressure.
- Facts & French: One real-world-adjacent statement found and evaluated: "Your bees sealed the honey inside with little wax caps" (Act 2) — factually correct (honey bees do cap cells with beeswax); functions as a game-mechanic description of the in-world uncapping process; no quantitative or debatable claim requiring citation. No other real-world factual claims found; no unlabelled fictional species or flowers. French checked line-by-line against English: meaning matches throughout; beekeeping register correct (désoperculation, rayon, butiner, alvéoles, centrifugeuse); Québec register appropriate (T'inquiète pas, C'est le temps de, Tu as le tour). French stage directions faithfully reflect English stage directions.
- Sources: GDD §7 (Story Premise & Onboarding), §2 (Phase 1 Uncapping & Extraction Minigame), §3 (Progression Trees & Economy Balance), Aesthetic & Tone, Child Safety, Glossary, and Progression Tiers & Biomes (Sunny Meadow entry) — all confirmed present in GDD.md under those names.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Tone & Glossary (minor) | "That honey money is yours to spend." | Glossary > Currencies & Prestige ("In-game money"; no "also called" listed) | Designer to confirm whether informal dialogue may use "honey money", or revise to a neutral phrase such as "That money is yours to spend." |

## Result

PASS after 1 round(s): `content/onboarding-script.md` saved with `status: draft`.

| Call | Tokens | Turns | Duration |
|---|---|---|---|
| William, round 1 | 90,439 | 6 | 161 s |
| Critic, round 1 | 130,197 | 5 | 221 s |
| **Total** | **220,636** | | |
