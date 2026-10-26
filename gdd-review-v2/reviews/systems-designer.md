# Systems Designer — Round 1

Scope: core loop, progression structure, run pacing, difficulty curve, economy math. Every finding is tied to a passage or a clear omission. TBD values are only flagged where they stop evaluation.

---

## 1. The specified economy runs out almost immediately and cannot support a multi-phase, two-biome run (BLOCKING)

**Source:** Section 3, Progression Trees ("exponential cost model, Cost = Base x Growth^Level") and the per-upgrade numbers in Trees A and B; the "Egg, Inc." framing in the Executive Summary.

**Problem:** These are the full costs of every capped upgrade that has numbers, summed from level 0 to max:

| Upgrade | Base / Growth / Max | Total to max |
|---|---|---|
| Worker Swarm Count | $25 / 1.18 / 10 | ~$588 |
| Heated Uncapping Fork | $40 / 1.22 / 5 | ~$310 |
| Centrifuge Gearing | $35 / 1.20 / 5 | ~$260 |
| Deep Frame | $150 / 1.45 / 3 | ~$683 |
| Artisanal Branding | $60 / 1.25 / 10 | ~$1,995 |
| **Total** | | **~$3,840** |

The max levels are low and the bonuses add linearly (+15% fill per level, so 2.5x at max; +$2.50 per jar). That means exponential costs only ever reach about 2.7x to 9.3x the base price. They never climb steeply. The upgrades also feed each other. With Artisanal Branding at max (+$25/jar), a single full Deep Frame harvest (25 jars) earns $625 from branding alone, about a sixth of the whole capped tree. The quoted formula looks like an Egg, Inc.-style curve, but these numbers produce a flat one that finishes within a few harvests. The Capstone's "key upgrades maxed" gate will open early, and Phase 2/3 pacing and a second biome have nothing left to spend on.

The document also never sets the values that decide time-to-first-upgrade and everything after it: base honey value per jar, base fill rate, and the starting number of bees and hives. Without them no pacing number can be checked. Flight Endurance has no max level, so it is the only uncapped sink. Its effect (+10% speed) adds up linearly while its cost grows exponentially, so it soon stops being worth buying. It can't serve as a long-run sink, and it can't be part of a "maxed" gate either.

**Needed:** A target run length per phase and per biome, the base production and price values, and a sink structure where effects multiply (or tiers reopen per biome) so cost and benefit both grow.

---

## 2. "Hive Balance" depends on a hive count that nothing lets the player buy (MAJOR)

**Source:** Tree C, *Hive Balance*: "Adding hives without enough habitat lowers Habitat Health, so players balance hive count against planting." Also Tree A, *Worker Swarm Count* ("adds active foraging bees"), and the Section 1 Crystal example "extra starting hives".

**Problem:** The only stated interaction between Tree C and Trees A/B is the trade-off between hive count and habitat. But no upgrade in Tree A, Tree B, or the Upgrade Shop (Section 8) adds hives. Tree A adds bees to existing hives, and Tree B upgrades tools and frame capacity. The only place more hives come from is a Royal Crystal starting bonus, so in a first run the player never touches the balancing lever at all. The document also doesn't say whether Worker Swarm Count (more managed bees) counts as hive pressure on Habitat Health. If it doesn't, Tree A and Tree C don't compete and simply sit side by side. A related problem: the Crystal option "extra starting hives" would *lower* starting Habitat Health under the stated rule, so a prestige reward can hurt the next run.

**Needed:** A hive-purchase upgrade with costs, a formula for how hive count and swarm count reduce Habitat Health, and a stated value for the native-bee multiplier so the trade-off can actually be balanced. The multiplier is currently "more native bees means a bigger multiplier", with no curve.

---

## 3. The capacity pause makes offline progress and the Phase 1→2 transition fight each other (MAJOR)

**Source:** Section 2: "production pauses at capacity until the player harvests, including while offline"; Section 5 Offline Earnings: "Free players earn offline up to a cap... The Impact Pass extends this, and the Patron Pass extends it to 24 hours"; Tree B Overflow Storage / Auto-Sell / Automation (all costs TBD); Section 1 Phase 2: "Manual screens remain accessible for upgrading tool efficiency and batch multipliers."

**Problem:** Three separate caps control the same quantity (offline output): Deep Frame capacity (10–25 jars), Overflow Storage (TBD), and the offline-hours cap (TBD). In Phase 1 the frame cap always applies first. A full frame stops production long before any hours cap is reached, so the offline cap, and the "extended offline production" that the Impact and Patron passes sell, does nothing until the player buys storage or automation. The document never says which cap wins, or whether automation removes the capacity pause altogether.

The transition also leaves earlier purchases behind. The Fork bonuses ("swipe radius", "clean cut" batch bonus) and Centrifuge Gearing ("fewer taps") are defined only in terms of manual input. Once automated hubs and electric centrifuges take over, the document doesn't say whether those levels affect automated output. If they don't, about $570 of the capped tree becomes sunk cost. If they do, the meaning of a "clean cut" under automation needs defining. The reset also repeats the issue: every run returns the player to the manual minigame unless Crystal starting upgrades skip it, and nothing says whether they can.

**Needed:** One stated rule for how the caps stack, a statement of what automation does to the capacity pause, and how each manual-tool upgrade carries over into Phase 2.

---

## 4. Earned Royal Jelly carries over resets and doesn't count as "boosted", so players can stockpile it for record runs (MAJOR)

**Source:** Section 5 Currencies table: Royal Jelly is earned "slowly through play and rewarded ads", spent on "time skips and production speed-ups", and "Carries Over Resets: Yes". Section 4: "Royal Jelly earned through play does not [count as a paid booster]"; "Free rewarded-ad boosts do not count as a paid booster"; Run Time is "wall-clock time... offline time included".

**Problem:** Run time is measured in wall-clock time, and time skips directly reduce it. Earned Jelly persists across resets and leaves a run on the unboosted board. The best leaderboard strategy is therefore to save Jelly over many slow runs and then spend it all on one run. That run lands on the "unboosted" board with a time that unboosted play can't match. The Royal Crystal tiers (Section 4) don't stop this, because the stockpile is independent of Crystal count. Rewarded ads add another split: the 2x production ad boost and ad-earned Jelly both count as "unboosted", so on the unboosted board, watching ads becomes the competitive requirement.

There is also an accounting gap. Purchased Jelly and earned Jelly sit in one wallet, but bracketing needs to know which kind was spent. The currency spec doesn't separate them, and doesn't say how a mix of the two is tagged.

Because run time counts offline time while production pauses offline (Finding 3), and Pests and Nectar Drops only appear during active play (Section 1), the fastest runs come from never putting the game down. That is a design choice, but it directly opposes the "cozy, casual" framing in the Executive Summary and needs to be decided on purpose.

**Needed:** Either don't let Jelly carry over resets, cap how much Jelly a single run can spend, or count any time skip as a bracket tag. Also track earned and purchased Jelly separately.

---

## 5. How the run's end connects to the biomes is undefined, and post-launch biomes change run length (MAJOR)

**Source:** Progression Tiers & Biomes: "Biomes are stages within a single run, played in order... a reset returns the player to Sunny Meadow", each biome with higher honey value and its own native species (TBD). Section 1 and the Section 3 Capstone: unlocks after "key upgrades are maxed" plus a Habitat Health / species threshold. Audience & Production Plan, Launch Scope: two biomes at launch; Biomes 3–4 post-launch. Section 4 Run Time: "from the start of a run to buying the capstone upgrade".

**Problem:** The document never says whether the capstone requires reaching the final biome, or whether Trees A–C are shared across biomes or restart in each one. If they are shared, the second biome's only effect is a higher sale price on an upgrade set that's already maxed (see Finding 1). If they restart, the cost tables above apply per biome and need per-biome values. The Capstone's Habitat/species threshold doesn't say which biome's habitat it measures, even though "Habitat levels reset with the farm" and each biome draws its own species.

If biomes are run stages and the run ends at the capstone, adding Biomes 3–4 after launch either makes every run longer, which breaks every stored personal best and future leaderboard bracket, or leaves the new biomes off the critical path. The document picks neither option.

**Needed:** State where the capstone sits relative to biome progression, whether trees are per-biome or per-run, and a versioning or bracketing policy for run times when new biomes ship.


---

## Round 2 — Cross-examination

### Conflicts

**C1. Player Psychologist #4 and Narrative Critic #4 vs. my #4: don't drop offline time from Run Time. Fix the pause.**
Both colleagues want wall-clock time, offline included, removed or played down. I agree it currently punishes sleep. Removing offline time from the clock is the wrong fix, though, because it inverts the economy. If offline time is free, every offline hour is pure profit that the clock never counts. The best play becomes "close the app as often as possible", and the Patron Pass's 24-hour offline window (Patron "Automation & QoL") turns into the biggest competitive advantage in the game. Active-time measurement also has to be validated on the server for every session, which is more work than the single start/end timestamp that §4 "Server-Side Time Validation" needs today. My position: keep wall-clock time as the leaderboard metric. Remove what actually makes it punishing, which is the Phase 1 capacity pause (my #3, Psychologist #1). Adopt the Psychologist's presentation fix too: show run time as an optional "pace" stat, not as the main reason to reset. The clock stays honest, and once the pause is gone, sleeping costs a free player only the offline-hours cap. That cap is a number we can tune.

**C2. Adversarial QA #2 overstates the "pre-max the capstone prerequisites" exploit and understates the Automation skip.**
QA worries that putting Crystals on capstone-prerequisite upgrades "collapses run time". By my #1 math, every capped Tree A/B upgrade costs about $3,840 combined to max. Deep Frame, QA's example, costs about $683 to max, roughly one full harvest late in the run. Pre-maxing it with a Crystal saves minutes. So the problem is that the Crystal starting-upgrade reward is nearly worthless on tree upgrades, not that it's exploitable. The only starting upgrades worth a Crystal are the ones with TBD costs: Automation, Overflow/Auto-Sell, and extra hives. That makes QA's "skip Phase 1" case the real issue, and it is a pacing decision (does every run replay the minigame?), not an exploit. My #3 asked the same question. I'd merge the two and treat it as MAJOR: the whitelist QA asks for can only be written after Automation costs exist.

**C3. Narrative Critic #2 (native bees as profit multipliers): I disagree with the diagnosis, but I agree with the fix.**
From a systems view, the multiplier is the only thing that makes Tree C compete with Trees A/B at all. If biodiversity were only a score, a speed-runner would push it to the capstone threshold and stop. The Critic's own observation shows this is already happening, because the gate is a minimum. Removing the multiplier would make it worse. The problem is that biodiversity has no value beyond the run. See connection X1 for a structure that fixes the narrative and economy problems together.

### Connections

**X1. Narrative #1 (restoration is wiped) + Psychologist #5 (reset feels like loss) + my #1 (no long-run sink) form one problem with one fix.**
All three come from the same structural gap: nothing the player builds outlasts the run except Crystals and the Journal. A persistent meta-layer could fix all three, for example restored worlds that stay as a collection, as the Critic suggests, each giving a small permanent bonus scaled to the biodiversity reached in that run. It would provide the story beat (the split swarm seeds a new world), soften the sense of loss, and act as an uncapped, multiplicative long-run sink that my #1 says the tree lacks. It also rewards going past the Habitat threshold, which answers Narrative #2 without removing the multiplier.

**X2. Business Analyst #5 (research trees are unplanned scope creep) + my #1: research is the only sink candidate in the document, and it's TBD.**
I missed this in Round 1, and the Analyst flagged it as creep. §1 says research is "for faster run times", "purchased with in-game money", and "do not carry over". That is exactly the per-run, cost-scaling sink my #1 said was missing. Research therefore isn't optional creep. As specified, it is the only thing that can soak up late-run money, and Business #5 found that it isn't in the UI list. Either research is in launch scope and needs a cost/effect curve, or it's cut and something else has to fill the sink. Cutting it without a replacement makes my #1 worse.

**X3. Adversarial QA #4 (No-Rapid-Tap Mode) + my #3 (manual upgrades stranded by automation): two separate routes strand the same ~$570.**
Fork and Gearing upgrades lose their value once automation arrives (my #3) *and* in accessibility mode (QA #4). In No-Rapid-Tap Mode, a player who uses accessibility settings has those upgrades stranded from the very first purchase. Fixing my #3 so these upgrades apply as plain throughput multipliers (+% batch yield, -% extraction time) instead of input-specific effects fixes both cases. The mode then uses those multipliers and is no longer faster than the default input, which closes QA's leaderboard edge too.

**X4. Feasibility #3 (no bee rendering plan) + Tree A Worker Swarm Count: economic bees have to be decoupled from rendered bees.**
Worker Swarm Count "adds active foraging bees", Flight Endurance is uncapped, and Crystals add hives. If every economic bee is a rendered, pathing agent, the 60 FPS budget is effectively a cap on progression. The GDD should state that production comes from a bee *count* and that rendering shows a capped, instanced crowd. This makes a balancing decision (bee count can grow freely) also a performance decision.

**X5. Business #5 (is Royal Jelly IAP in launch scope?) + Feasibility #5 + QA #1 + my #4: change the timing of the Jelly fix.**
Online leaderboards are post-launch, and launch ships only local PBs. A player who hoards Jelly for a local PB is only cheating themselves. So my #4 exploit has no competitive impact at launch. What *is* needed at launch is the source-tagged Jelly ledger: earned, ad, purchased, and stipend (QA #1's split, which is more complete than mine). Without it, post-launch online boards can't classify runs (Feasibility #5). QA's lapsed-stipend case also extends my exploit. Stipend Jelly hoarded while subscribed makes the "bonuses stop" rule false, which is a second reason to cap per-run Jelly spend.

### Revisions

- **#1 (economy runs out): stays BLOCKING, amended.** I credit research trees as a sink the GDD intends (X2), but their values are TBD so they can't be checked. I also concede one reading I didn't consider. If the intended run is short (a speed-runner), a flat, cheap tree could be deliberate. But in that case the Crystal's "stacking permanent production boost" has very little to speed up, and Crystal starting upgrades are nearly worthless (C2). Either way, the prestige math doesn't work yet.
- **#3 (capacity pause vs offline): upgraded MAJOR → BLOCKING.** The Psychologist's day-2 retention argument (#1) adds a player-facing cost to my structural one. The monetization angle makes it worse: the Impact Pass's launch perk, "extended offline production", gives a Phase 1 player nothing, because the frame cap applies before the hours cap. The only launch subscription would sell a perk that does nothing for new players. Recommended rule: a small free overflow buffer from the start, and automation removes the capacity pause.
- **#4 (Jelly stockpiling): stays MAJOR, reframed** as a launch save-schema requirement (source-tagged ledger plus per-run spend cap) rather than a launch balance issue (X5).
- **#2 (no hive purchase): stays MAJOR.** QA #5 and QA #2 found the same gap independently. QA #2 also adds that Habitat Health has no floor or fail state, which I'm adding to the "Needed" list.
- **#5 (capstone vs biomes): stays MAJOR.** Feasibility #5 and QA #3 reached the same issue from schema and leaderboard angles. Three lenses agreeing makes it the clearest decision item on the board. The capstone location and the content-set versioning of PBs need to be decided before launch PBs exist.
