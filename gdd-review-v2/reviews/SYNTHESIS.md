# Design Review Board — Synthesis (Review 2)

**Document:** Chill Bee Game GDD at commit `8ddb97a` (~3,100 words)
**Board:** Systems Designer (SD), Narrative Critic (NC), Player Psychologist (PP), Technical Feasibility Lead (FL), Adversarial QA (QA), Production/Business Analyst (BA)
**Method:** 6 independent Round 1 reviews (30 findings) → Round 2 cross-examination → moderated synthesis. Reviewers were told that values marked TBD are known open items. Everything below traces to the review files; the moderator adds no critiques of its own.

---

## 1. Top 5 issues (ranked by severity × confidence)

### #1 — A full hive stops production, so idle and offline progress doesn't work in Phase 1 · BLOCKING
**Flagged by:** PP F1, SD F3, QA F3, FL R2, BA R2 (C1)
**Cross-examination: STRENGTHENED**

By default, production "pauses at capacity... including while offline." That has three consequences:
- **Day 2.** A new player returning the next day finds one 10-jar frame waiting, in a game pitched as *Egg, Inc.*-style idle (PP F1).
- **The offline cap never matters (SD F3).** In Phase 1 the full frame stops production long before any offline-hours cap is reached.
- **The Impact Pass sells a perk that does nothing.** Its "extended offline production" is useless in Phase 1. That hits a new player at the exact moment they're most likely to pay, a refund and review risk noted by PP X1 and BA C1.

**Severity.** SD raised F3 to BLOCKING in Round 2, so two reviewers now rate it BLOCKING. QA and SD both trace the "run time punishes sleep" complaint to this pause, not to the clock.

**Fix.** Every reviewer who proposed one gave the same fix: a small free overflow buffer from the start, and automation removing the pause. FL notes this also cuts down the cases to test.

### #2 — The economy as specified runs out within a few harvests and has no long-run sink · BLOCKING
**Flagged by:** SD F1, with connections from FL, BA, PP, QA and NC
**Cross-examination: STRENGTHENED**

- **The numbers.** Every capped upgrade costs about $3,840 in total. The bonuses add up linearly, and one maxed Deep Frame harvest earns about a sixth of the whole tree.
- **Confirmed.** FL checked the arithmetic and concluded the real state is "no economy exists yet." Economy design is serial work on the critical path, and the 6-month plan has no slot for it.
- **What it causes:**
  - PP X2: an early burst of rewards, then "the game stopped paying me," a likely drop-off around days 3–7.
  - QA X1: short runs make stockpiled Royal Jelly decisive.
  - QA X2: the "key upgrades maxed" half of the capstone requirement opens almost at once, so Habitat becomes the only real gate.
  - NC X1: the player never spends long enough in the world to feel they restored it.
- **Research may be the missing piece.** SD and BA now agree the research trees are the only planned money sink. BA withdrew calling them feature creep. They are TBD and missing from the UI screen list.

### #3 — Launch scope doesn't fit one developer and 6 months, and compliance and art have no owner · BLOCKING
**Flagged by:** FL F1/F2/F4, BA F1/F4
**Cross-examination: STRENGTHENED**

- **The launch list is mid-studio scope:**
  - two biomes, three trees plus automation, prestige and research
  - Royal Jelly, the Impact Pass and ads
  - a backend, Kid Mode, and English and French
  - four accessibility modes, tablets, and 60 FPS with hundreds of bees
  - auditable donations
- **No plan.** There are no milestones between the first playable version and launch, and no list of what gets cut if the date slips.
- **Compliance is now BLOCKING too.** FL upgraded it in Round 2: the family audience decides which ad SDK and backend can be used, both needed in month one. BA X adds that ads aimed at children earn far less, which shrinks both launch revenue and the donation pool.
- **Nobody makes the art (FL F4).** No agent produces 3D models, animation, effects, UI art or French text. BA revised its own pipeline point accordingly: the problem is the wrong roles, not too much process.
- **The first playable version stops too early (FL).** It ends exactly where the weakest stretch, Phase 2, begins. FL recommends one complete rough run, from start to capstone to reset, before any monetization work.

### #4 — The competitive leaderboard layer can't be enforced, and it causes the largest group of findings · BLOCKING
**Flagged by:** QA F1/F3/F4, SD F4/F5, FL F5, BA F2, PP F4, NC F4
**Cross-examination: STRENGTHENED**

- **One Royal Jelly balance.** Jelly from play, ads, purchases and the stipend all goes into one balance that carries over resets. Brackets can't tell whether a run used purchased Jelly. Earned or ad Jelly can be saved over many runs and spent on one record run that still counts as unboosted (QA F1, SD F4).
- **New biomes break old times.** Adding biomes after launch lengthens every run, so launch-era personal bests can't be compared with later ones (SD F5, QA F3, FL F5).
- **One cause behind many findings.** BA counted about seven findings from five reviewers that trace back to the ranked speed-run layer. That includes No-Rapid-Tap Mode becoming a "competitive exploit" (QA F4), and it led BA to raise F2 ("three games at once") to BLOCKING.
- **The fix the board agrees on (FL, QA, SD).** Put three things in the launch save format now, while it's cheap:
  - a source tag on each unit of Royal Jelly
  - a log of which boosters were active during each run
  - a content-version number on every stored run

  Adding them after launch would mean classifying runs that were never logged.

### #5 — The conservation and restoration promise isn't delivered by the mechanics · BLOCKING (NC) / MAJOR
**Flagged by:** NC F1/F2, SD F2, QA F2/F5, PP F3/F5, BA F3
**Cross-examination: STRENGTHENED**

- **The reset wipes the restoration (NC F1, BLOCKING).** The game's only premise is "restore a pocket world," and the encouraged reset wipes it with no story reason. PP raised its own first-reset finding from MINOR to MAJOR, calling the first reset the point where invested players quit.
- **Hive Balance can't happen.** No upgrade lets the player buy hives, so on a first run the honeybee vs. native bee lesson never comes up (SD F2, QA F5 now MAJOR, PP R1).
- **The one named hive source backfires.** It's the Crystal's "extra starting hives," which *lowers* Habitat Health in the next run. That makes the next run's capstone requirement harder (QA X2, PP R1).
- **Honey still comes first (NC F2, now BLOCKING).** Native bees mainly matter as honey multipliers, and restoration only counts as a minimum requirement. The paid and ad rewards aimed at kids also pay out in honey, not habitat (NC X5).
- **The selling point is the least specified part (BA F3).** The habitat layer is what's meant to set the game apart, yet it's almost entirely TBD.

---

## 2. Compared with Review 1

| Review 1 top issue | Status now |
|---|---|
| Speed-run leaderboard is pay-to-win | **Partly fixed.** It's now bracketed by boosters and Crystal tier, but one Royal Jelly balance makes the brackets impossible to enforce (#4). |
| Conservation claims not backed by the design | **Mostly fixed.** The per-harvest claim is gone, the beneficiaries are stated, and donations are single fixed percentages. The *mechanics* still put honey first (#5). |
| Main loop undefined: unreachable reset, no automation gate | **Partly fixed.** The capstone, automation tree and biome stages are defined. The economy's numbers don't hold up (#2). |
| Scope with no team, timeline or cut list | **Persists.** The team and timeline are now stated, and they make the mismatch explicit (#3). |
| First hour undefined, full-hive rule unknown | **Partly fixed.** There's a guide and first-session beats, but the full-hive decision (pause) is now the top issue (#1). The guide stops after the first purchase (PP F3). |

**New in Review 2:**
- the Royal Jelly source-tracking problem
- the unlimited Crystal "any starting upgrade," which could let a player skip Phase 1
- No-Rapid-Tap Mode compared with normal input
- no agent produces art
- child-safety compliance driving which ad SDK and backend can be used
- post-launch biomes changing run length and breaking stored times
- no way to buy hives

---

## 3. Unresolved disagreements

**D1. Keep the ranked, bracketed leaderboards?** *(Your earlier decision is to keep them.)*
- **Cut them (BA).** BA counts seven findings that trace back to the leaderboards. It recommends making run time an optional personal stat and treating online boards as a separate future decision, not a launch requirement.
- **Speed as an optional layer (PP).** The game's tone, audience and premise all promise cozy, so a racing identity would be a bait-and-switch at the first capstone. PP wants a hideable pace stat and opt-in brackets.
- **Restoration first (NC).** The game's main fantasy should be restoration. Any speed layer needs a story reason.
- **Keep it, fix the pause (SD, QA).** Keep real-time run measurement, since it's the only one the server can verify. Remove the full-hive pause instead. If the competitive layer stays, the per-source Jelly tracking is a launch requirement. If it goes, QA's leaderboard tagging issues drop to MINOR.
- **Decision for you:** keep online brackets as designed (and pay for the tracking and versioning from launch), or move to optional personal-best times only.

**D2. How to fix the economy**
- **Add structure (SD).** Make bonuses multiply instead of add, or reopen upgrade tiers in each biome.
- **One shared tree (FL).** Keep a single tree with multiplier effects, and have each biome raise level caps through data rows. That needs no new art, text or screens.
- **Retune first (BA).** Raise max levels and growth rates, and make the native-bee multiplier the main way bonuses compound, before adding any system.
- **Common ground:** research trees are the intended money sink and must be specified or replaced.
- **Decision for you:** retune the existing numbers, or restructure how bonuses scale across biomes.

**D3. What to cut to fit 6 months**
- **FL:** cut Alpine Valley, research, French and the Impact Pass.
- **BA:**
  - Cut Alpine Valley. If trees are shared, it only raises the sale price on upgrades that are already maxed.
  - Keep French, because the game is positioned on Canadian and Quebec partners.
  - Keep the Impact Pass, the only recurring revenue at launch.
  - Keep research, since it may be the economy's sink.
- **PP:** accepts cutting research, but objects to cutting Alpine Valley unless something else gives Phase 2 a goal.
- **NC:** if Alpine Valley goes, put that effort into visible restoration stages inside Sunny Meadow instead.
- **Decision for you:** the launch cut list, especially Alpine Valley and research.

**D4. Should "extra starting hives" lower Habitat Health?**
- **A defect (SD, QA).** A prestige reward shouldn't hurt the next run, and it currently makes the main capstone gate harder.
- **The one mechanic that carries the theme (NC).** Keep the penalty and pair it with a habitat-positive Crystal option (for example "starting wildflower plot"), so choosing between them is a values choice.
- **Explain it on the Crystal screen (PP).** If it stays, the warning belongs where Crystals are assigned.
- **Decision for you:** keep the trade-off and make it visible, or make the Crystal rewards neutral for habitat.

**Converging, not fully settled:** the reset's story. NC proposes that the split swarm seeds a new pocket world, with post-launch biomes becoming the places the swarm goes. FL and BA prefer a cheap Bee Journal snapshot of each finished world over worlds the player can revisit. QA requires that past worlds produce nothing.

---

## 4. Quick wins

1. **Give a small free overflow buffer from the start, and have automation remove the capacity pause.** This fixes #1, makes the Impact Pass perk work, and reduces the test cases. *(PP F1, SD R2, QA C1, FL R2, BA C1)*
2. **Add three fields to the launch save format:** a source tag on Royal Jelly, a log of active boosters per run, and a content-version number on stored runs. It's cheap now and can't be done properly after launch, whatever you decide on leaderboards. *(FL F5/R2, QA X5, SD X5)*
3. **Turn manual-tool upgrades into flat output bonuses when input is automated or simplified.** For example, Fork and Gearing become +% yield and −% time. This rescues about $570 of upgrades after automation, makes them useful in No-Rapid-Tap Mode, and closes the accessibility speed edge. *(SD X3, QA X3, FL R2)*

---

## 5. Verdict

The GDD has improved since Review 1:
- The pay-to-win leaderboard, the misleading per-harvest charity claim, the unreachable reset and the six-platform scope are all addressed.
- The new Native Habitat tree gives the game a real point of difference.

It is still not ready to drive production. The idle loop stalls overnight, and the specified economy finishes in a few harvests. The launch scope is far beyond one developer in six months, with no owner for art or compliance. The habitat lesson the game is built around can't come up on a first run, because there's no way to buy hives.

Several of the board's fixes are cheap and agreed: a free overflow buffer, three save-format fields, and tool upgrades as flat bonuses. The single change that matters most is a positioning decision. Is this primarily a cozy restoration game with optional personal bests, or a game with competitive brackets? Five reviewers trace their largest group of findings to that choice. It decides the save format, the backend, the cut list and the success metric, so it should be settled before the economy is rebalanced.
