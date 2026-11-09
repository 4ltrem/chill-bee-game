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
Revision of `content/guides.md` (previous run: `none recorded`, status was `draft`).

Designer notes: Fill every 'to write' / 'à écrire' slot in content/guides.md: one signature line per guide for each of the five moments (welcome, first harvest, first sale, first upgrade, hand-off), English and Canadian French, 60 lines in all. Keep the three existing run-1 welcome lines. Each guide must sound clearly different from the other five: give Queen Maeve and the sprite a Voice row, and make Queen Maeve distinct from the other two queens. Propose the sprite's name (not Pip; works in EN and FR) and Queen Maeve's French name. Lines follow the current harvest flow in GDD section 2 (Harvest button, uncapping fork, centrifuge Spin, sales truck: no crank button, no Market Stand). Short enough for a mobile dialogue bubble. Change nothing else in the file.

## Round 1

### Draft (William), round 1

The full draft: `content/_runs/guides/blackboard-2-round-1.md` (92 lines). Later rounds show only the changes.

### Critic, round 1
VERDICT: FAIL
Checked:
- Lore: I compared the six guides (Melli, Pip, Lady Aura/Dame Aura, Miel, Queen Maeve, the sprite) with GDD §7, which lists the same six candidates, and with the "Dame Aura" French name. The new lines follow the GDD §2 harvest flow: fork icon, uncapping, centrifuge spin, jars, sales truck. None of them mention a crank button or Market Stand, and none invent a character, place or system. Lumi and Reine Maëve are offered as proposals with alternatives under Decisions needed, so they are not presented as settled GDD names.
- Tone & Glossary: I checked hive, centrifuge, fork, jars, truck, upgrade, sold, meadow and clover. All are playful and cozy, and none conflict with the Glossary. Each guide's lines fit its own Voice row.
- Child safety & spending: I read the upgrade and sale lines. Examples are "No rush with the next", "Commerce suits you" and "Do try to look effortless". None use fear, guilt or spending pressure, and none tie worth to a purchase.
- Facts & French: Real-world statements found:
  - Pip: "they're always buzzing". This is in-world banter about pocket-world bees.
  - Notes row: "Name means *honey* in French". This is true, and it sits in a designer note, not in player text.
  - Decisions #2: "as it is commonly spelled in Quebec French". This is an unsourced real-world claim (row 1).
  - Every other line is in-world poetry or whimsy about the pocket world. Lumi is labelled as the sprite's proposed name.
  - French: all 30 FR lines match the EN meaning: welcome, first harvest, first sale, first upgrade and hand-off for six guides. Examples are "glow-getter" → "je brille de tous mes feux", "Have a sit" → "Assois-toi un peu", and "Do try to look effortless" → "Garde un air nonchalant". The accents and the register are Canadian French.
- Sources: GDD "Story Premise & Onboarding" exists (§7). The other cited items are content and session files, not GDD sections. The quoted GDD text is out of date (minor row 2).
- Look & words: Objects described are the fork, wax cap, centrifuge, jars, the truck and a shed tool. They match GDD §2: the fork uncaps the wax, the centrifuge spins, the jars go on the truck and the truck drives off. No wooden-bucket-style mismatches.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Facts & French | as it is commonly spelled in Quebec French | STYLE_GUIDE T4 (real-world statements must be true and sourced, or clearly in-world) | Cut the claim about Quebec spelling, or reword it as a plain option ("Reine Maëve, with the diaeresis, or plain Reine Maeve"). If you keep it, ask Ruth for a sourced brief. |
| 2 | Sources | (minor) "a guide character (e.g., a queen bee; name and personality TBD)" | Story Premise & Onboarding (§7) | The GDD now says "Six candidate guides… share one script". Update the Sources quote to match the current §7 wording, or label it as the old wording. |

## Round 2

### Changes (William), round 2

~~~~diff
--- round 1
+++ round 2
@@ -91,2 +91,2 @@
 1. **The sprite's name** (EN and FR): proposed **Lumi** (*lumière*; reads the same in both languages; the pun in its welcome line needs it). Other options: **Glimmer** (EN) / **Lueur** (FR), or **Fizz** (works in both, but loses the light link).
-2. **Queen Maeve in French:** proposed **Reine Maëve** (the Irish name with the diaeresis, as it is commonly spelled in Quebec French). The other option is plain **Reine Maeve**.
+2. **Queen Maeve in French:** proposed **Reine Maëve** (the Irish name with a diaeresis on the e). The other option is plain **Reine Maeve**.
~~~~

### Critic, round 2
VERDICT: PASS
Checked:
- Lore: The only changed line is Decisions #2, which offers "Reine Maëve" or plain "Reine Maeve". These are options, not settled GDD names. It adds no character, place or system, and it contradicts nothing in GDD §7.
- Tone & Glossary: The changed line has no player-facing text and no Glossary terms.
- Child safety & spending: The changed line touches no purchase, donation or pressure.
- Facts & French: The round 1 FAIL row #1 (the Quebec spelling claim) is fixed, because "commonly spelled in Quebec French" is gone. Two statements remain in the changed line, both in a designer note and not in player text: "the Irish name" and "a diaeresis on the e". The first is an unsourced real-world claim, but it is a plain description of the name's origin and I passed it in round 1. The second describes the spelling of an option. Neither is a claim about bees or nature. The FR lines did not change, and they matched the EN in round 1.
- Sources: Round 1 minor row 2 is not addressed, because the Sources quote is still the old wording. It was minor and does not block a PASS.
- Look & words: The changed line describes no game object.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Sources | (minor) "a guide character (e.g., a queen bee; name and personality TBD)" | Story Premise & Onboarding (§7) | The GDD now says "Six candidate guides… share one script". Update this quote, or label it as the old wording. |
| 2 | Facts & French | (minor) "the Irish name with a diaeresis on the e" | STYLE_GUIDE T4 | The origin claim "Irish name" is unsourced. It is harmless in a designer note. Cut it, or ask Ruth for a sourced brief, if you want the draft strictly clean. |

## Result

PASS after 2 round(s): `content/guides.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-07-guides-run-2/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| William, round 1 | 247,658 | 40,666 | 20 | 87 s |
| Critic, round 1 | 66,237 | 31,613 | 7 | 35 s |
| William, round 2 | 30,819 | 10,925 | 3 | 6 s |
| Critic, round 2 | 12,359 | 12,359 | 1 | 8 s |
| **Total** | **357,073** | | | |
