---
slug: ui-labels
type: ui-text
started: 2026-11-23
max_rounds: 3
max_tokens: 500000
result: draft
---
# Blackboard: ui-labels

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
0.3.1 item 7 (game/specs/0.3.1-playtest-fixes.md): the game's player-facing UI labels as EN/FR translation rows (key, en, fr) so the new Settings language switch changes every label. French house style: 'vous', the Shop = 'boutique', Sell = 'Vendre', the Bee Journal = 'Carnet des abeilles', the harvest tool = 'la fourche'; match the approved content/first-time-hint.md and content/course-ending-text.md. Keep each label as short as the English (buttons are 120 px wide at 28-32 px text; Shop row names fit one line of a 720 px sheet). Use %d / $%d placeholders exactly where the English has them. Labels: farm view: 'Bees: %d', 'Hive full, production paused', 'Honey: %d / %d', 'Sell $%d', 'Auto' (the auto-sell tag), 'Journal' (the Journal icon), 'Back'; zoom: 'Drag across the cells to uncap them', 'All cells uncapped!'; bottling summary: 'Jars: %d' / 'Jars sold: %d', 'Value per jar: $%d' / 'Price per jar: $%d', 'Batch total: $%d' / 'Total: $%d', 'OK'; toast: 'Phase 2: your farm starts running itself'; Shop: 'Shop' (button and sheet title), 'Close', 'Owned', 'Not owned', 'Lv %d / %d', 'Needs Faster Delivery %d', the tab names 'Bees', 'Hive', 'Habitat', 'Research', 'Refinery', 'Coming soon', and the eight row names 'Worker Swarm Count', 'Flight Endurance', 'Heated Uncapping Fork', 'Centrifuge Gearing', 'Spigot Flow', 'Faster Delivery', 'Auto-Sell', 'Plant wildflower patch' (GDD Glossary names); Journal panel: 'Bumble Bees' (entry title); welcome: 'Play' (approved FR 'Jouer'); Settings (new): 'Settings', 'Language'; the language names 'English' and 'Français' are never translated (list them unchanged). Suggest a key for each (snake_case, prefixed by its screen: farm_, zoom_, summary_, toast_, shop_, journal_, settings_). Kid-safe, no new claims.

## Round 1

### Draft (William), round 1

The full draft: `content/_runs/ui-labels/run-1/round-1.md` (178 lines). Later rounds show only the changes.

### Script check, round 1
VERDICT: PASS
Checked (voice_check.py, no agent call):
- Sources (T5): Story Premise & Onboarding; Aesthetic & Tone; Child Safety; Glossary; Progression Trees & Economy Balance (in "§3 Progression Trees & Economy Balance")
- Tone & Glossary (T2, terms only): 1 Rejected Glossary term(s), 2 listed in `_tools/voice_terms.json`
- Completeness (T7 cells only): 0 table row(s) with an empty or placeholder cell
| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|

### Critic, round 1
VERDICT: PASS
Checked:
- Lore: Compared the eight Shop row names and the five tab names with GDD §3 and the Glossary. Worker Swarm Count, Flight Endurance, Heated Uncapping Fork, Centrifuge Gearing, Spigot Flow and Auto-Sell are in §3. Faster Delivery is on a §3 line the search tool cut off, so I trusted the request here. Auto-Sell unlocking at Faster Delivery level 1 matches "Needs Faster Delivery %d". "Bumble Bees" as a Journal entry matches the biome table. No invented characters, places or systems.
- Tone & Glossary: These are plain UI labels with no jokes, so nothing breaks the cozy tone. English row names are the Glossary/§3 names. French follows the approved house style: "vous", boutique, Vendre, Carnet des abeilles, and fourche in the Fourche chauffante row. These match first-time-hint and course-ending-text.
- Child safety & spending: "Needs Faster Delivery %d" states a requirement and does not urge a purchase. "Shop", "Owned" and "Not owned" are neutral. No fear, guilt or pressure.
- Facts & French: I read every label and found no real-world statements. "Bumble Bees" and "Bourdons" are only an entry title. All 45 English rows have a French row with matching meaning. Placeholders `%d` and `$%d` are kept in the same places. "Alvéoles désoperculées!" drops "All", which is acceptable for a short label. "Planter des fleurs sauvages" drops "patch", and decision 3 discloses this.
- Sources: checked by script (cited GDD sections exist).
- Look & words: none described. These are labels only, with no object descriptions.
- Completeness: The EN table, FR table and CSV each have 45 rows with the same keys. No placeholders or empty cells. The Real-world facts section reads "None", which matches what I found. Decisions are listed for the designer.

| # | Check | Quote from draft | GDD section | Fix |
|---|---|---|---|---|
| 1 | Completeness (minor) | `shop_row_gearing` (20 vs 19), `shop_row_fork` (18 vs 21, shorter) | n/a | Decision 2 gets the character counts wrong. "Centrifuge Gearing" is 18 characters and "Heated Uncapping Fork" is 20. The fork row is shorter in French, so it does not belong in a list of longer labels. Correct the counts. |
| 2 | Tone & Glossary (minor) | `Coming soon` / `À venir` | Glossary | Decision 4 already flags that the spec says "Bientôt disponible". Designer to pick one, and William should then align the spec wording. |

Scores
| Check | Score | Reason |
|---|---|---|
| Lore | 9/10 | Row and tab names match GDD §3 and the Glossary, with nothing invented. |
| Tone & Glossary | 9/10 | Main Glossary names are used. French follows the approved "vous", boutique, Vendre and Carnet style. |
| Child safety & spending | 10/10 | "Needs Faster Delivery %d" is a neutral requirement line, with no pressure. |
| Facts & French | 9/10 | There are no real-world claims. French matches the English, and the dropped "patch" is disclosed. |
| Sources | 10/10 | Checked by script. |
| Look & words | 10/10 | No objects are described, only labels. |
| Completeness | 8/10 | All three tables and the CSV have 45 matching rows. The Decision 2 character counts are slightly wrong. |

## Result

PASS after 1 round(s): `content/ui-labels.md` saved with `status: draft`.

Transcripts: `_meta/sessions/runs/2026-11-23-ui-labels-run-1/`

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| William, round 1 | 132,044 | 37,657 | 11 | 54 s |
| Critic, round 1 | 47,384 | 28,580 | 4 | 21 s |
| **Total** | **179,428** | | | |
