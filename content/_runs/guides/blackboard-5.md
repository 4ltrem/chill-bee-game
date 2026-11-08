---
slug: guides
type: story
started: 2026-11-07
max_rounds: 3
max_tokens: 500000
result: draft
---
# Blackboard: guides

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
Revision of `content/guides.md` (previous run: `content/_runs/guides/blackboard-4.md`, status was `draft`).

Designer notes: Designer, 2026-11-07: some guides still have no voice. Fill the Voice row (EN) and the Voix row (FR) for Melli and Miel with a real voice description, as Lady Aura, Pip, Queen Maeve and Lumi have: Melli from her run-1 personality (warm, poetic, nurturing, reverent, never rushed) and her signature lines; Miel from his v2 personality (calm, poetic, slightly mysterious, the meadow very old and precious) and his lines. Make Melli and Miel clearly different from each other (both are poetic). Then read the whole file and fill any other empty slot or placeholder in either language. Signature lines stay as they are.

## Round 1

### Draft (William), round 1

The full draft: `content/_runs/guides/blackboard-5-round-1.md` (95 lines). Later rounds show only the changes.

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: Compared the six guides (Melli, Pip, Lady Aura, Miel, Queen Maeve, Lumi) with GDD §7, which names the same six and calls Lumi a bee-turned-sprite. Harvest objects and steps (fork icon, centrifuge, bucket, truck, jars) match GDD §2. No invented place, species or system. Queenie, Bixby and Wren are listed only as folded-in or unused names.
- Tone & Glossary: Playful and cozy throughout, with no menace. Terms used are fork, centrifuge, truck, jars, hive and meadow. None conflicts with the Glossary.
- Child safety & spending: First-sale and upgrade lines are only celebratory ("Commerce suits you", "Well done"). No pressure to spend, no guilt, and no link between worth and spending.
- Facts & French: Real-world statements found: "honey has never once bitten anyone" (a joke in Maeve's voice); "Name means *honey* in French" (Miel). Both are trivially true or in-world, so I did not fail them. The Miel name note is minor and has no source. French matches English meaning in all 30 signature lines, the personality rows and the Voix rows for Melli and Miel. One French section sentence is in English (see row 2).
- Sources: Cited GDD section "Story Premise & Onboarding" exists (§7). Cited content files and the D46 decision file are only references to other files, not GDD sections.
- Look & words: Fork, centrifuge, truck and jars are described in line with GDD §2. No "wooden bucket" or similar error.
- Completeness: The Voice and Voix rows for Melli and Miel are filled, and the two voices are clearly differentiated. EN and FR each have 5 guide-table rows and 5 moment rows, with every cell filled. No placeholder text in player-facing or design text. Gaps: the FR half has no "Other names" table, and one FR intro sentence is in English.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Completeness | "### Other names in the drafts (not in the six)" (English section only) | n/a (template: EN and FR have the same sections) | Add the FR equivalent (Queenie, Bixby, Wren with Qui / Statut) to the French section, or move the table out of the bilingual body. |
| 2 | Completeness | "French signature lines, written alongside the English ones (the three run-1 welcome lines are translated here)." | n/a (French text must be in French) | Rewrite this intro sentence in Canadian French. |
| 3 | Facts & French | "Name means *honey* in French." | n/a (minor) | (minor) Optional: add a source URL, or reword it as an in-world note. |

## Round 2

### Changes (William), round 2

~~~~diff
--- round 1
+++ round 2
@@ -71,3 +71,3 @@
 
-French signature lines, written alongside the English ones (the three run-1 welcome lines are translated here).
+Les répliques types en français, écrites en parallèle des anglaises (les trois répliques de bienvenue du premier essai sont traduites ici).
 
@@ -80,2 +80,10 @@
 | **Au revoir** | « Le reste, c'est à toi de le découvrir, tout doucement, comme un pré dans la lumière du matin. Je serai là, à fredonner, quand tu voudras. » | « Bon, bon, j'arrête de parler… peut-être! Va explorer, je reste juste ici! » | « Va. Demande-moi conseil quand tu veux, quoique je risque d'en donner sans qu'on me le demande. » | « Le chemin est long et le trèfle est doux. Marche-le lentement. » | « Allez, va, mon cœur. La porte reste ouverte. Je ne suis jamais loin. » | « C'est tout pour moi! On se retrouve dans le trèfle. Je serai la petite lueur. » |
+
+### Autres noms dans les ébauches (hors des six)
+
+| Nom | Ébauche | Qui | Statut |
+|---|---|---|---|
+| Queenie | v2, option A | Reine des abeilles. « Chaleureuse, maternelle, d'une autorité tranquille. Parle en phrases courtes et assurées. Calme même quand elle est enthousiaste. » Note : « Renforce le rôle réel de la reine des abeilles; très lisible pour tous les âges. » | Intégrée à la reine Maëve (décision du concepteur, 2026-11-07; la première compilation l'avait placée par erreur chez Melli) |
+| Bixby | v2, option B | Abeille ouvrière éclaireuse. « Enthousiaste, amateur de jeux de mots, parle par élans d'enthousiasme. Beaucoup de « Oh! » et de points de suspension. Voix plus jeune. » Note : « pourrait être adoucie pour les joueurs en quête de douceur. » | Intégrée à Pip |
+| Wren | option de `biome-intros.md` | Petit éclaireur aux yeux vifs, curieux; sans genre | Hors du test de jeu (trop proche de Pip) |
 
~~~~

### Critic, round 2
VERDICT: PASS
Checked:
- Lore: I checked the changed lines. The new FR table lists Queenie, Bixby and Wren. It matches the EN table (lines 52–54) on who each is and on their status: Queenie folded into Queen Maeve, Bixby into Pip, and Wren left out of the playtest. It adds no new character or system.
- Tone & Glossary: The new French lines are cozy and playful. No Glossary term is changed.
- Child safety & spending: The changed lines don't mention purchases, donations or pressure.
- Facts & French: The changed lines state no new real-world facts. Queenie's note, "Renforce le rôle réel de la reine des abeilles", matches the EN note and is a design note, not a claim to players. The French meaning matches the English. The round 1 minor about Miel's name still stands. It is optional and not a FAIL.
- Sources: The changed lines cite no GDD section. The earlier citation of "Story Premise & Onboarding" was confirmed in round 1.
- Look & words: The changed lines describe no game object.
- Completeness: Round 1 row 1 is fixed. The FR "Autres noms" table now has 3 rows, the same as the EN table, and the Nom / Ébauche / Qui / Statut columns match the EN columns. Every cell is filled. Round 1 row 2 is fixed. The FR intro sentence is now in French. No placeholder text was found.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Facts & French | "Name means *honey* in French." | n/a | (minor) Optional: add a source URL, or reword it as an in-world note. |

## Result

PASS after 2 round(s): `content/guides.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-07-guides-run-5/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| William, round 1 | 51,005 | 21,239 | 8 | 19 s |
| Critic, round 1 | 62,516 | 24,237 | 6 | 24 s |
| William, round 2 | 45,458 | 18,338 | 4 | 10 s |
| Critic, round 2 | 27,250 | 14,937 | 2 | 8 s |
| **Total** | **186,229** | | | |
