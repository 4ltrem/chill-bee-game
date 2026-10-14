# Systems Designer — Round 1

Lens: does the loop, progression, pacing, and economy interlock as written? Mostly no. The three trees, three phases, four biomes, and prestige layer are each described, but the document never says how one feeds the next.

---

## 1. Phase transitions and the prestige trigger are undefined, so the macro-loop has no shape (BLOCKING)

**Source:** Exec Summary Phase 3 ("Upon reaching the end of the progression tree, the pocket dimension resets"); Section 1 Phase 3 ("When hive capacity and tech trees peak, players trigger a dimension reset"); Section 1 Phase 2 ("Unlocks automated uncapping hubs, electric centrifuges, and auto-transport trucks"); Progression Tiers & Biomes (4 biomes).

**Problem:**
- **No Phase 1 to Phase 2 gate.** None of the listed Tree A/B/C upgrades is an automation unlock. Automated uncapping hubs, electric centrifuges, and trucks appear in no tree and have no cost.
- **"End of the progression tree" can't be reached as written.** Flight Endurance has no max level, and Flora Synergy has no levels, costs, or cap. So "tech trees peak" is either never true or depends on content that doesn't exist.
- **The four biomes are cut off from everything.** Sunny Meadow through Cloud Gardens are listed as "Progression Tiers", but the doc never says what unlocks them, what they change mechanically, or whether a reset happens per biome or per full run. It also doesn't say whether the biome honey types (Frosted Lavender, Moonlight Nectar, etc.) have different values.
- **Prestige rewards are undefined.** Queen Markers have no earn formula, and the "deep genetic research trees" they unlock have no content.

**Net effect:** The game's stated main loop (Phase 3) has no entry condition, no payout math, and no meta tree to spend on. Pacing across a full playthrough can't be estimated.

## 2. The Patron Pass's permanent +25% breaks the competitive prestige loop (MAJOR, near-BLOCKING)

**Source:** Exec Summary Phase 3 ("competing for high scores based on completion speed"); Patron Pass ("+25% global honey value multiplier (persists across Phase 3 resets) and a daily stipend of Royal Jelly premium currency", plus "golden 'Patron' badge on speed-run leaderboards", "Golden Drone auto-collector ... handles pest events", "offline idle earnings up to 24 hours").

**Problem:** The Phase 3 loop is pitched as a race on completion speed. A permanent +25% value multiplier stacks onto every run's income. Combined with the paid auto-collector and extended offline earnings, a paying player clears runs measurably faster by design. The leaderboard badge even advertises the paid players at the top of the board. Either leaderboards need to be split or normalized, or the multiplier must not touch run speed. The doc does neither.

**Secondary issue:** "Royal Jelly Harvest" is the name of the prestige reset, and "Royal Jelly" is also the premium currency. Queen Markers are a third currency. The doc never says what Royal Jelly buys or how these three currencies relate. That makes the free-player meta economy impossible to balance against the paid stipend.

## 3. Tree B's tool upgrades invest in a minigame that Phase 2 automates away (MAJOR)

**Source:** Tree B (Heated Uncapping Fork "+12% swipe radius", Centrifuge Gearing "-15% required taps", up to "+5% batch bonus for clean cuts"); Section 1 Phase 2 ("Manual screens remain accessible for upgrading tool efficiency and batch multipliers"); Exec Summary Phase 1 note (same).

**Problem:**
- **The upgrades only matter while the player is doing the work by hand.** Swipe radius and tap count are manual-input stats. Once automated hubs and electric centrifuges take over, they do nothing unless the automated machines inherit them. The doc never says whether they do.
- **If automation doesn't inherit them,** ~$570 of Tree B spending (Fork + Gearing, both maxed) becomes dead investment at the Phase 2 transition.
- **If it does,** "-15% taps" and "+12% radius" need a translation into automated throughput, and none is given.

**Phase 1 bottleneck:** The minigame fires "when hive storage reaches capacity". Tree A's Worker Swarm (+15% fill rate) only makes the hive fill faster, so the player hits the cap sooner. In Phase 1 the limit is the player's manual harvest frequency, not the bees, which makes early Tree A spend near-worthless. The doc doesn't say whether production overflows, stalls, or keeps accumulating at cap.

## 4. The headline "synergies" don't exist in the spec (MAJOR)

**Source:** Exec Summary ("three distinct progression trees that feature synergizing effects with each other"); Section 3 ("three synergizing upgrade paths"); Flora Synergy ("Plant and upgrade flower patches (Clover, Lavender, Buckwheat) to grant production multipliers").

**Problem:**
- **No cross-tree effect is written down anywhere.** Each upgrade buffs only its own stat.
- **Flora Synergy, the one item named for synergy, has no numbers at all.** It has no multiplier, cost, growth, or cap. Its flower types (Clover, Lavender, Buckwheat) also don't match the biome flora (wild clover, lavender, night-blooming, rainbow blossoms).
- **Two Tree A stats overlap with no stated distinction.** Worker Swarm (fill rate) and Flight Endurance (bee speed) both raise nectar intake.
- **Systems appear only in the monetization section.** Pests, wild nectar drops, and offline production are mentioned only as paid perks. No base-game version of any of them is specified.

**Net effect:** The trees coexist rather than interlock. "Factorio"-style interdependence is claimed but not designed.

## 5. The economy can't be simulated, and the caps flatten the exponential curve (MAJOR)

**Source:** Section 3 cost model (Cost = Base x Growth^Level) and all listed base/growth/max values; Expanded Frame Deep ("10 jars to 25 jars", max level 3); Artisanal Branding ("+$2.50" per level).

**Problem:**
- **There is no income side.** The doc gives no base jar price, no base fill rate, no harvest cycle time, and no bee count. With only costs specified, time-to-upgrade and session pacing can't be computed.
- **The cost side alone shows a very short tree.** Maxing every capped upgrade costs about:

  | Upgrade | Max-out cost |
  |---|---|
  | Worker Swarm | ~$590 |
  | Fork | ~$310 |
  | Gearing | ~$260 |
  | Frame Deep | ~$680 |
  | Artisanal | ~$2,000 |
  | **Total** | **~$3,840** |

- **The exponential model barely matters.** Low growth factors (1.15 to 1.25) plus hard caps of 3 to 10 levels mean the last level of most upgrades costs only 2 to 3x the first. That isn't the escalating Egg, Inc.-style curve the pitch references, and it gives the Phase 3 meta nothing to accelerate.
- **Artisanal Branding's flat +$2.50 per level** dominates or vanishes depending on the base jar value, which is unknown.
- **Frame Deep's per-level step is unclear.** It goes from 10 to 25 jars over 3 levels; is that +5 per level, or nonlinear?

**Needed:** A base income model and a target time-per-phase, so the cost curves can be validated against them.

---

## Round 2 — Cross-examination

Four of the five colleagues independently raised my F1 (no prestige trigger), F2 (Patron +25% vs. leaderboards) and F3 (dead Tree B tool upgrades). I won't repeat those agreements. This round covers where the proposed fixes conflict with how the systems work, and which problems only show up when two findings are read together.

### CONFLICTS

**C1. Business Analyst F5 / Feasibility F1 vs. my F1: cutting or deferring the biomes and the genetic research tree removes the run's length and the prestige sink.**
- BA F5 says to "link biomes to progression or mark them as post-launch content". Feasibility F1 lists "biomes 3 and 4, the genetic research trees" among the obvious cuts.
- From the systems side these aren't optional content. My F5 table shows the entire specced upgrade economy maxes out at about $3,840 across five capped upgrades. Without biomes as stages within a run, that $3,840 is the whole run, and Player Psychologist F4's "I've bought everything, now what?" gap shows up within the first hour or two.
- The genetic research tree is the only place Queen Markers can be spent. Cut it and prestige is just a flat multiplier, which can work, but only if someone writes the formula. Neither cut list says what replaces it.
- **My position:** For a vertical slice, it's fine to cut biomes 3–4 and the research tree. But the GDD must first say that biomes are the stages of a single run (Meadow → Cloud Gardens, then reset). Those stage gates are what make the run long enough for prestige to matter. If biomes become "cosmetic, post-launch", the macro-loop has nothing to stretch over. So the order matters: define the biome-as-run-stage role first, then defer content.

**C2. Business Analyst F5: the minigame is not "used mainly in the first session or two". It repeats on every prestige run.**
- BA treats the minigame as expensive first-session content. But Phase 3 resets the dimension, and the GDD says nothing about Queen Markers skipping Phase 1. So every run goes back through manual harvesting.
- That makes the problem worse than BA describes. It isn't wasted content. It's a grind the player is forced to repeat each run, which is exactly the fatigue Player Psychologist F1 warns about, multiplied by the number of prestiges.
- **My position:** BA's suggested fix ("optional high-value artisanal batches") is the right systems answer, and it ties into Artisanal Branding. Make manual batches a choice, for example a hand-harvested batch sells at a premium multiplier scaled by clean-cut precision, while automation sells at base value. Then Tree B upgrades keep their value in every phase (this resolves my F3), and the minigame stays meaningful without being required. The alternative fix, "cut its scope", would leave Tree B with nothing to upgrade.

**C3. Adversarial QA F2: "hoarding and delaying the reset to farm Queen Markers" is the intended decision, not an exploit.**
- QA presents an optional reset plus run-scaled Markers as an abuse case. In the idle genre (Egg, Inc., which the pitch names), deciding when to prestige is the core strategic choice of the endgame.
- The real fix for the "tree never ends" problem QA and I both found is not to cap Flight Endurance. It's to replace "end of the progression tree" with a soft trigger: reset is allowed anytime after a threshold, and Markers scale sub-linearly with lifetime earnings in the run (for example a square-root formula).
- The real conflict is with **speed-run scoring**. If players choose when to reset, "completion speed" has no fixed finish line. That supports Business Analyst F1: the prestige system and the leaderboard want different trigger designs, and the GDD has to pick one.

**C4. Narrative Critic F3 / Player Psychologist F2 / Business Analyst F1: dropping leaderboards does not remove the need for a prestige payoff.**
- All three suggest de-emphasizing or removing the racing endgame. I agree on tone grounds. But the GDD gives speed scoring as the *only* stated reason to reset.
- If leaderboards go, the reset has to justify itself through faster growth in the next run. That puts the full weight on Queen Marker math, which doesn't exist yet (my F1).
- Narrative Critic's "daughter colony goes to a new plot, old hive stays" is a real systems option: a partial reset where the old hive keeps producing at a fixed rate. It answers the cozy-attachment objection, but it changes the economy. The retained hive is a permanent income floor that has to be sized against the Marker multiplier.

### CONNECTIONS

**X1. Hive-full stall × paid offline earnings × Impact Pass auto-tap: the paid tiers either do nothing or quietly skip Phase 1** (my F3 + Adversarial QA F4 + Player Psychologist F5).
- In Phase 1 the hive fills, then waits for a manual harvest. If production stalls at capacity, offline earnings are capped at one frame (10 jars at base) no matter how long the player is away. The Patron's "24 hours" and the Impact Pass's "extended offline production" would be worth almost nothing to a Phase 1 player.
- If offline time auto-harvests, the game contains an undocumented automation that makes the Phase 2 gate pointless.
- The Impact Pass "auto-tap helpers" automate the minigame for a monthly fee. That is Phase 2 bought before Phase 2, and it makes Centrifuge Gearing (−15% taps) useless for subscribers.
- **Net:** The Phase 1→2 transition, the main pacing beat of the early game, may be skippable with money, and nobody can tell from the GDD. **Hive-at-cap behavior and the free offline baseline must be specced before any monetization value can be judged.**

**X2. Pests only exist as a paid removal, so the Patron's real advantage is larger than +25%** (my F2/F4 + Narrative F5 + Player Psychologist F5).
- If pest events exist in the free game as a production tax, the Golden Drone removes that tax only for payers. Their effective edge is then +25% value × (1 + pest loss avoided) × wild-nectar income only they collect × 24h offline vs. an unknown free baseline.
- Add Adversarial QA F1's uncapped 2x rewarded ads, which multiply production while the Patron bonus multiplies value, so the two stack. A Patron who watches ads plausibly runs at about 2.5x a free player's income, before pests and nectar drops.
- That isn't a "permanent +25%" pay-to-win problem. It's a multiplier stack, and the leaderboard can't survive it in any form.

**X3. Undefined Royal Jelly sink plus the Patron stipend means the paid advantage can't be bounded** (my F2 secondary + Adversarial QA F3).
- QA found the possible free faucet (a Royal Jelly Harvest reset granting Royal Jelly). The other half is that no sink is listed either.
- Without knowing what premium currency buys (Marker purchases? time skips? biome unlocks?), the daily stipend could be anywhere from cosmetic to a run accelerator. A soft/prestige/premium currency table with sources and sinks is a prerequisite for balancing anything in Phase 3.

**X4. Flora Synergy is the cheapest place to fix both the missing synergies and the theme** (my F4 + Narrative Critic F1).
- Flora Synergy is the only upgrade with no numbers, so redesigning it costs nothing. Narrative F1 asks for native pollinators and habitat health to be part of the loop. My F4 found no cross-tree effects.
- One fix covers both. Reframe Flora as a **habitat diversity score** (number of distinct native plantings) that multiplies Tree A fill rate *and* unlocks the biome honey types, which ties into my F1 biome gap.
- That gives a real cross-tree interaction, turns biodiversity into the player's growth goal instead of just yield, and its plant list can be aligned with the biome flora, fixing the Clover/Lavender/Buckwheat vs. biome mismatch.

**X5. Feasibility F3 (server-side time validation) is also an economy-parameter problem.**
- Offline duration is a core income variable in idle games. If the leaderboard stays, offline accrual during timed runs must be either server-validated or excluded from ranked time.
- The cheapest systems fix is to have ranked runs count active-session time only. That also neutralizes the Patron 24h offline perk on the board.

### REVISIONS

- **F2 → downgraded from "near-BLOCKING" to MAJOR, conditional.** The severity depends on whether leaderboards stay. If the team follows Business Analyst F1 and cuts or makes them cosmetic-only, a paid +25% value multiplier is a standard and acceptable idle-game monetization lever (Egg, Inc. sells similar). It stays BLOCKING only if speed-run boards ship. The currency-collision sub-issue moves out of F2 into its own MAJOR (see X3).
- **F3 → upgraded to BLOCKING for the hive-at-cap sub-issue.** After X1, the hive-full behavior is no longer a Phase 1 tuning detail. It decides whether the offline economy, the Phase 1→2 gate, and two paid tiers work at all. The Tree B dead-investment part stays MAJOR and has a fix (C2).
- **F5 → refined, not withdrawn. "The tree is short" is true in dollars but may be long in repetitions.** Player Psychologist F1 and my F5 look contradictory (long grind vs. short tree), but both can be true. Illustration only, since there is still no base price: at $5/jar and a 10-jar frame, one batch earns $50, so maxing the ~$3,840 tree takes about 77 manual minigame batches if no automation arrives sooner. Frame Deep and Artisanal together account for ~70% of that cost. The tree is shallow in *decisions* and potentially deep in *taps*, which is the worst mix for the cozy audience. This strengthens the need for a base income model and a target time for Phase 1.
- **F4 → no change in severity.** I withdraw the Worker Swarm vs. Flight Endurance overlap as a separate concern. It is minor and goes away if Flora is redesigned per X4, where the two stats map to different multipliers (bee count vs. trip time). The "no cross-tree effects" core stands.
- **F1 → unchanged (BLOCKING).** Every colleague's structural finding (Player Psychologist F4, Adversarial QA F2, Narrative F4, Business Analyst F5) points to the same missing piece: biome ↔ phase ↔ reset mapping. It remains the single highest-leverage fix in the document.
