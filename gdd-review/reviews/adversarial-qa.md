# Adversarial QA — Round 1

## Finding 1 — Paid boosts break the speed-run leaderboards the endgame relies on
**Severity: BLOCKING**

**Problem:** Phase 3's competitive goal is "competing for high scores based on completion speed." The Patron Pass gives a "+25% global honey value multiplier (persists across Phase 3 resets)," a daily stipend of premium currency, a Golden Drone auto-collector, and 24h offline earnings. Rewarded ads give "2x production boosts." Each of these shortens run time, so the leaderboard ranks spending and ad-watching, not skill. The pass also puts a "Patron" badge on those same leaderboards, which advertises the advantage. Exploit: a player can chain rewarded ads during a timed run, and nothing in the doc limits that (no cooldown, daily cap, or ad-free leaderboard bracket). This conflicts directly with the "Non-Predatory" label in the monetization section.

**Source:** Exec Summary Phase 3 (line 12); Monetization Architecture — Rewarded Ads (line 86) and Patron Pass Visual Prestige / Automation / Permanent Boosts (lines 90–92). Omission: no leaderboard segmentation, normalization, or boost exclusion for ranked runs.

## Finding 2 — The prestige trigger can't happen as written, and leaderboard fairness across prestige levels is undefined
**Severity: MAJOR**

**Problem:** A reset happens "upon reaching the end of the progression tree" (line 12), or "when hive capacity and tech trees peak" (line 29). Several upgrades have no maximum level: *Flight Endurance* has none, and *Flora Synergy* has no cost, cap, or numbers at all. With uncapped exponential costs, the tree never "ends," so the reset condition as written can never be met. Other gaps:
- Is the reset forced or optional? If it's optional, players can hoard and delay it to farm Queen Markers. The doc never says how Queen Markers are calculated: a flat amount per reset, or scaled by run output?
- Queen Markers "boost global production rates" permanently, so each run is faster than the last. Ranking a 1st-prestige player against a 50th-prestige player by "completion speed" is meaningless unless runs are bracketed.
- The four biomes (Sunny Meadow → Cloud Gardens) aren't tied to phases or resets. Does a reset send the player back to Sunny Meadow? What defines "completion" for a timed run?

**Source:** Lines 12, 29, 48, 54, 66–70. Omission: reset formula, cap on unbounded upgrades, how a run's completion is defined, biome/reset relationship.

## Finding 3 — "Royal Jelly" means three different things, so prestige and premium currencies collide
**Severity: MAJOR**

**Problem:** "Royal Jelly" is used for:
1. the prestige reset itself ("Swarm Splitting / Royal Jelly Harvest," line 12)
2. the premium currency in the Patron daily stipend (line 92)
3. the honey product of the Cloud Gardens biome ("Stardust Royal Jelly," line 70)

Meanwhile, the prestige reward is named "Queen Markers (Royal DNA)" (line 29). If a "Royal Jelly Harvest" reset grants Royal Jelly, then premium currency can be farmed for free by prestiging, which undercuts the paid stipend. If it doesn't, the reset's name misleads players. And if selling Stardust Royal Jelly yields premium currency, the economy has a hard-currency faucet with no stated rate. The doc never defines what premium currency buys.

**Source:** Lines 12, 29, 70, 92. Omission: a currency table (soft, prestige, premium) listing each currency's sources and sinks.

## Finding 4 — Manual-tool upgrades go dead after automation; Phase 2 unlocks have no cost or trigger; a full hive can stall Phase 1
**Severity: MAJOR**

**Problem:**
- Tree B's *Heated Uncapping Fork* (swipe radius) and *Centrifuge Gearing* (fewer taps) only affect the manual minigame. Once Phase 2's "automated uncapping hubs, electric centrifuges" take over, these upgrades do nothing unless they also apply to automation, and the doc doesn't say whether they do. Line 28 says manual screens remain "for upgrading tool efficiency and batch multipliers," but not whether those multipliers carry over to automated output.
- The Phase 2 automation unlocks (hubs, electric centrifuges, auto-transport trucks) appear in no progression tree and have no cost or unlock condition. So the Phase 1 → 2 transition is undefined, and it's unclear whether the Impact Pass "auto-tap helpers" (line 87) let paying players skip Phase 1 entirely.
- The minigame is triggered "when hive storage reaches capacity." What happens to a full hive the player doesn't harvest? Does foraging stop? That matters for the "extended offline production" sold in the Impact Pass and Patron Pass: in Phase 1, a capped hive would make those offline hours worthless, or else they silently auto-harvest, which the doc doesn't specify.
- No base jar sale price is given, so *Artisanal Branding* (+$2.50/jar) and the $15–$150 upgrade costs can't be balanced or checked. *Expanded Frame Deep* (10→25 jars over 3 levels) gives no per-level increment.

**Source:** Lines 27–28, 32, 49–52, 55, 87, 91. Omission: automation tree, hive-full behavior, base honey price.

## Finding 5 — The summary modal implies every batch donates, but funding comes only from money; plus platform/input gaps
**Severity: MAJOR (donation claim) / MINOR (platform)**

**Problem:**
- The batch summary modal shows "real-world wildflower seed contributions" for every manual batch (line 41). But real-world funding comes only from "a portion of proceeds from in-game monetization" (line 14). A free player who never spends or watches ads would see contributions that don't exist. That is a false charitable claim and a consumer-protection and app-store-review risk. The Impact Pass pledge is a vague "25–50%," and the Patron Pass says only "a significant portion," so the dashboard has no auditable number to show.
- Platform and input gaps: the core minigame depends on touch swipes and `Input.vibrate_handheld()` haptics, but Desktop (PC/Mac) targets have no touch or handheld vibration, and the doc defines no mouse/controller mapping for "spins an on-screen handle" or a haptics fallback. Nintendo Switch is listed with no input plan, and Godot's Switch support isn't standard, so the console port is unaccounted for.
- Small contradictions: the "Real-World Impact Integration" section (lines 74–77) is duplicated word-for-word in lines 79–83. Martin's role refers to the template in "`GDD.md`," which isn't this document's filename. The developer-tool agent roles describe output that "the player sees," which confuses dev-pipeline output with player-facing content.

**Source:** Lines 14, 41, 74–83, 87, 89, 128, 146–148, 154. Omission: donation accounting rules, a non-touch input scheme, haptic fallback.


## Round 2 — Cross-examination

### Conflicts

**C1. Systems Designer #5 ("the tree is short, ~$3,840 to max") vs. my F2 ("the tree never ends").** Both of us are right, and together the problem is worse than either finding alone. The SD table leaves out *Flight Endurance*, the one upgrade with no max level (line 48). So $3,840 is the cost of every capped upgrade, not the cost of the tree. Once those are bought, Flight Endurance is the only place left to spend money. Every late-run dollar goes into one +10% speed stat at a 1.15x cost growth, and because that stat is uncapped, the "end of the progression tree" condition (line 12) can never be met. The design isn't short or endless; it is short, then stuck. This changes SD's suggested fix: adding an income model won't help. Every stat the reset condition depends on needs a cap, or the condition has to be redefined in terms of something that can actually be reached (for example, a production threshold or the final biome).

**C2. Systems Designer #2 rates the Patron leaderboard problem MAJOR ("near-BLOCKING"). I keep it BLOCKING.** The GDD calls Phase 3 the place where "the main loop comes into full swing" (line 12), and its only stated goal is a speed ranking. If that ranking can be bought, the endgame has no fair win condition. The Business Analyst also rated this BLOCKING. SD treats it as one balance input among many, but I'm not reporting a tuning issue. The ranked objective is invalid by construction until segmentation is designed.

**C3. Business Analyst #1's fix ("exclude Patron runs or make them cosmetic-only") doesn't fully fix the problem.** Four sources make runs faster, and only one of them is the Patron Pass: rewarded-ad 2x boosts with no cap (line 86), Impact Pass auto-tap helpers and extended offline time (line 87), and Patron offline/Drone/+25% (lines 91–92). Excluding Patrons still leaves a board that ranks ad-watching and subscriptions. It also creates two new edge cases. (a) Patron is called a "Pass." If it lapses, does the "+25% (persists across Phase 3 resets)" stay? If it stays, a player can subscribe for one month and keep the boost forever while showing up as a non-Patron on the free board. (b) A player who buys Patron partway through a run has a run that is half-boosted, and nothing says which bracket it belongs to. The real fix is to tag each run as boosted or unboosted by recording everything that affected it during the run, not to look up the player's account status.

**C4. Business Analyst #5 suggests "optional high-value artisanal batches" so the minigame stays relevant later.** Seen as QA, this proposal introduces its own exploit. If manual batches pay more than automated output, then (a) speed-runners have to grind manually in every Phase 3 run, which brings back the Phase 1 fatigue the Player Psychologist (#1) warned about, and (b) the Impact Pass "auto-tap helpers" (line 87) turn into a paid bot for the best income source. If the idea is adopted, manual batches need a cooldown or cap, and auto-tap helpers must be excluded from them.

**C5. Narrative Critic #3 suggests "the old hive stays as a visible memory," and the Player Psychologist #2 asks what carries over after a reset.** I support both, with one condition: anything that carries over must have no effect on production. Otherwise the reset doesn't fully reset, and it adds another permanent advantage that isn't counted in the leaderboard bracket. The GDD already has one item that carries over across resets, the Patron hive skin, so the "what persists" rules have to be written for paid content too.

### Connections

**X1. Feasibility #3 (device-clock exploit) + my F1 + the undefined "completion speed": every possible definition of run time can be broken.** If completion speed is wall-clock time, the offline-earnings caps decide the result. Patrons earn for 24h while the free player's earnings stop at an unstated cap, but both clocks keep running. If it is active play time, offline earnings are progress that costs zero recorded time, so the best speed-run strategy is to close the app and change the device clock. Either way, the leaderboard can't work until the GDD defines run time *and* there is server-side time validation. Neither appears anywhere.

**X2. Systems Designer #3 (Phase 1 is limited by hive capacity) + my F4 (hive-full behaviour) + Monetization line 86: the rewarded ad does nothing in Phase 1.** If the hive stops filling at capacity and the bottleneck is how often the player harvests by hand, a "2x production boost" just fills the hive faster and then sits idle. A new player who watches an ad in their first session gets nothing visible for it. Since the ad is "explicitly tied to habitat funding," it becomes a donation prompt dressed up as a boost. That hurts trust in the first hour, which is the Player Psychologist's #1 concern. The same reasoning makes Impact Pass "extended offline production" worthless before automation. A player who buys the Pass in Phase 1 is sold a perk that has no effect.

**X3. Narrative Critic #1 shows a factual contradiction inside the donation claims, which strengthens my F5.** Line 14 promises "native bee habitat restoration." Line 89 (Patron) says proceeds fund "managed hives and land restoration." Those are different beneficiaries. On top of the Business Analyst's #3 point that payout percentages aren't fixed, this means the top-tier product's charitable claim doesn't match the game's headline pillar. This is no longer just a tone problem. It is an inconsistent consumer representation attached to a paid purchase.

**X4. Player Psychologist #1 ("first few upgrades" triggers Phase 2) + Systems Designer #1 (automation isn't in any tree) + Impact Pass auto-tap helpers.** The only automation the GDD actually describes is a paid one (line 87). Until the free automation unlocks are written, the shipped design has a free path to Phase 2 that isn't defined and a paid path that is. That counts as a soft paywall on the phase transition.

**X5. Feasibility #2 + Business #4 make my input-gap point conditional.** If the recommendation to launch on mobile only is adopted, the missing mouse/controller and haptics fallback stops being a launch issue and becomes a requirement for each port.

**X6. New contradiction found while re-reading for this round:** line 12 says the dimension resets "upon reaching the end of the progression tree," which reads as automatic. Line 29 says "players trigger a dimension reset," which is manual. That confirms the forced-vs-optional question in my F2 is an internal contradiction in the document, not just an omission. If the reset is automatic, a player can't delay it to farm extra Queen Markers. If it is manual, they can, unless Queen Markers are a fixed amount per reset.

### Revisions

- **F5 (donation claim): upgraded from MAJOR to BLOCKING.** Four of six reviewers flagged it independently (Narrative #2, Psych #5, Business #3, mine), and X3 adds a direct contradiction about who receives the money. A false or inconsistent charitable claim attached to IAP is a risk for store rejection and regulators, and it has to be fixed before any marketing goes out.
- **F2: kept at MAJOR, scope widened** to cover C1 (one uncapped sink after ~$3,840) and X6 (automatic vs. manual trigger stated in the text).
- **F1: kept at BLOCKING, scope widened** to cover X1 (no definition of run time can be defended without server time validation) and C3 (lapsed passes, mid-run purchases).
- **F4: kept at MAJOR**, with X2 added: when the hive fills up, the Phase 1 ad and Pass perks become worthless.
- **F5 platform/input sub-point: downgraded from MINOR to a conditional note.** I defer to Feasibility #2 and Business #4. Their recommendation to cut platforms resolves it better than specifying input for each port.
- **F5 cosmetic nits** ("`GDD.md`" filename, "the player sees" wording, duplicated section): **withdrawn as separate items.** Feasibility #3/#5 and Business #2 cover them in the context where they matter (an under-worked impact pillar, and confusion about the document's audience). Listing them again only adds noise.
- **F3 (Royal Jelly): unchanged at MAJOR.** Systems, Narrative, and Psych all agree on the naming collision. My exploit angle (that prestige could be farmed for premium currency) is still the part only my lens covers, and it stays open until a currency table exists.
