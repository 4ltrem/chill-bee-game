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
Revision of `content/guides.md` (previous run: `content/_runs/guides/blackboard-2.md`, status was `draft`).

Designer notes: Designer's answers, 2026-11-07: the first compile mixed up the characters. Queenie (v2 option A: warm, motherly, gently authoritative, confident short sentences, calm even when excited) folds into Queen Maeve, not Melli. Melli is run 1's poetic, reverent, unhurried elder queen with no borrowed voice. Pip keeps Bixby's voice (bursts, 'Oh!'s, ellipses, younger). The tables now show each source's own words. Revise: (1) Queen Maeve's Voice row and her five signature lines, EN and FR, to Queenie's gently authoritative, short-sentence, calm voice joined with Maeve's warm maternal gentle wit (less 'kitchen-table', no pet name in every line); (2) Melli's lines where they lean on Queenie's short confident sentences, so she reads poetic and reverent; (3) check Pip's lines fit Bixby's voice. Update the French personality row for Reine Maeve to match. Keep the run-1 welcome lines, the other guides' lines, and everything else unchanged.

## Round 1

### Draft (William), round 1

The full draft: `content/_runs/guides/blackboard-3-round-1.md` (93 lines). Later rounds show only the changes.

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: I compared the six guide names, roles and species with GDD §7 (Story Premise & Onboarding), which lists Melli, Pip, Lady Aura, Miel, Queen Maeve and the bee-turned-sprite. I also compared the objects and places the lines mention with the GDD harvest flow (§2): fork, wax, centrifuge, jars, truck, clover. Everything matches except "the shed" and "la remise" in Queen Maeve's first-upgrade line, which are not in the GDD (row 1). "Reine Maëve" and "Lumi" are offered as options in Decisions needed, so no TBD is decided silently. Queenie, Bixby and Wren are listed as folded or unused, and the table states each one's status.
- Tone & Glossary: The lines are playful, whimsical and cozy. Terms are fork, centrifuge, truck, jars, hive and meadow; none is outside the Glossary or the GDD. Maeve's voice has short, calm sentences and a dry kind aside. A pet name appears only in the hand-off ("dear" / « mon cœur »). Melli's lines are long, flowing and reverent, with no clipped confident sentences. Pip's lines are bursts with "Oh!"s and ellipses, which fits Bixby.
- Child safety & spending: No line touches purchases, donations or worry. "The next one can wait" and "Now, a moment's rest" carry no pressure to spend.
- Facts & French: The only statement that could read as real-world is "honey has never once bitten anyone" / « le miel n'a jamais mordu personne ». It is a joke told in the guide's voice, so I count it as in-world. "I've seen a LOT of flowers", "the meadow is very old" and "honey sweetens other days" are character voice about the pocket world. I found no real-world claims that need a source. I compared every French line with its English line, and each matches in meaning. This includes Maeve's five lines and the five Melli lines I compared.
- Sources: The Sources line cites GDD "Story Premise & Onboarding", which exists as §7. The other cited files are content files, not GDD sections.
- Look & words: The fork, wax, centrifuge, truck and jars match GDD §2. No glass bucket, frames or crate are described incorrectly. "The shed" and "la remise" describe a place the game does not show (row 1).

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Lore | "A fine choice. The shed is a little better stocked. The next one can wait." (FR: « La remise est un peu mieux garnie. ») | Game Mechanics §2 (the farm holds the hive, centrifuge, jar crate and truck); Story Premise & Onboarding | The GDD has no shed. Reword both EN and FR to refer to something that exists, such as the hive, the bees, the jars or the farm. Keep the short, calm sentences. |

## Round 2

### Changes (William), round 2

~~~~diff
--- round 1
+++ round 2
@@ -37,3 +37,3 @@
 | **First sale** | "The jars are setting out now, as honey always does, to sweeten other days far from the meadow." | "Oh! The truck! It's going! Look at it go... vroom, vroom, honey!" | "Your first load, sold. Commerce suits you. I shall not pretend to be surprised." | "Off goes the truck, rattling down the lane. Jars of summer, bound for somewhere sweet." | "There goes the truck, and your honey with it. Well done. Now, a moment's rest." | "Sold! Now that's a sweet deal." |
-| **First upgrade** | "A small change, lovingly made, and the whole hive will feel it, as a meadow feels the first warm breeze." | "Ooh, an upgrade! The bees are buzzing... well, they're always buzzing, but MORE!" | "An improvement. How enterprising. The hive approves, and so do I." | "A little better than yesterday. That is how meadows grow." | "A fine choice. The shed is a little better stocked. The next one can wait." | "Upgrade time! Now that's a buzzworthy idea." |
+| **First upgrade** | "A small change, lovingly made, and the whole hive will feel it, as a meadow feels the first warm breeze." | "Ooh, an upgrade! The bees are buzzing... well, they're always buzzing, but MORE!" | "An improvement. How enterprising. The hive approves, and so do I." | "A little better than yesterday. That is how meadows grow." | "A fine choice. The hive is a little better off. The next one can wait." | "Upgrade time! Now that's a buzzworthy idea." |
 | **Hand-off** | "The rest is yours to discover, slowly, like a meadow in the morning light. I'll be here, humming, whenever you wish." | "Okay, okay, I'll stop talking... maybe! Go explore, I'll be right here!" | "Off you go. Ask my advice any time, though I may give it unasked." | "The path is long and the clover is kind. Walk it slowly." | "Off you go, dear. The door stays open. I am never far." | "That's all from me! Catch you in the clover. I'll be the one glowing." |
@@ -76,3 +76,3 @@
 | **Première vente** | « Les pots s'en vont, comme le miel le fait toujours, adoucir d'autres journées bien loin du pré. » | « Oh! Le camion! Il part! Regarde-le filer… vroum, vroum, miel! » | « Première cargaison vendue. Le commerce te va bien. Je ne ferai pas semblant d'être surprise. » | « Le camion s'en va en cahotant sur le chemin. Des pots d'été, en route vers quelque part de doux. » | « Voilà le camion qui part avec ton miel. Bien joué. Maintenant, une petite pause. » | « Vendu! Ça, c'est une douce affaire. » |
-| **Première amélioration** | « Un petit changement, fait avec soin, et toute la ruche le sentira, comme un pré sent la première brise tiède. » | « Ooh, une amélioration! Les abeilles bourdonnent… bon, elles bourdonnent toujours, mais PLUS! » | « Une amélioration. Quel esprit d'entreprise. La ruche approuve, et moi aussi. » | « Un peu mieux qu'hier. C'est ainsi que grandissent les prés. » | « Beau choix. La remise est un peu mieux garnie. Le prochain peut attendre. » | « Amélioration! Ça, c'est une idée qui a du buzz. » |
+| **Première amélioration** | « Un petit changement, fait avec soin, et toute la ruche le sentira, comme un pré sent la première brise tiède. » | « Ooh, une amélioration! Les abeilles bourdonnent… bon, elles bourdonnent toujours, mais PLUS! » | « Une amélioration. Quel esprit d'entreprise. La ruche approuve, et moi aussi. » | « Un peu mieux qu'hier. C'est ainsi que grandissent les prés. » | « Beau choix. La ruche s'en porte un peu mieux. Le prochain peut attendre. » | « Amélioration! Ça, c'est une idée qui a du buzz. » |
 | **Au revoir** | « Le reste, c'est à toi de le découvrir, tout doucement, comme un pré dans la lumière du matin. Je serai là, à fredonner, quand tu voudras. » | « Bon, bon, j'arrête de parler… peut-être! Va explorer, je reste juste ici! » | « Va. Demande-moi conseil quand tu veux, quoique je risque d'en donner sans qu'on me le demande. » | « Le chemin est long et le trèfle est doux. Marche-le lentement. » | « Allez, va, mon cœur. La porte reste ouverte. Je ne suis jamais loin. » | « C'est tout pour moi! On se retrouve dans le trèfle. Je serai la petite lueur. » |
~~~~

### Critic, round 2
VERDICT: PASS
Checked:
- Lore: The changed line is Queen Maeve's first-upgrade line, "The hive is a little better off." The hive is in the GDD (§2), and the shed is gone from both EN and FR. The round 1 findings on names and roles are unchanged, and no other line changed.
- Tone & Glossary: Maeve's line keeps her short, calm sentences, and "hive" is a Glossary term. The rest of the line, "A fine choice… The next one can wait.", is unchanged.
- Child safety & spending: The line has no pressure to spend and no worry. "The next one can wait" is calm.
- Facts & French: The changed lines hold no real-world statements. The FR « La ruche s'en porte un peu mieux. » matches the EN "The hive is a little better off." in meaning.
- Sources: Unchanged. "Story Premise & Onboarding" exists in the GDD.
- Look & words: The changed lines describe no visible object beyond the hive, which the GDD shows. The previous FAIL row 1 (the shed) is fixed.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

## Result

PASS after 2 round(s): `content/guides.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-07-guides-run-3/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| William, round 1 | 58,880 | 25,872 | 26 | 41 s |
| Critic, round 1 | 60,814 | 25,481 | 5 | 20 s |
| William, round 2 | 41,863 | 11,180 | 5 | 8 s |
| Critic, round 2 | 13,350 | 13,350 | 1 | 5 s |
| **Total** | **174,907** | | | |
