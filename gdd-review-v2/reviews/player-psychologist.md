# Player Psychologist — Round 1

## 1. A brand-new player comes back to a hive that stopped working while they were away
**Severity: BLOCKING**

**Problem:** The GDD sets up an idle-game expectation, then by default turns off the idle reward. Players return to a game like this for "I came back and earned stuff." A Phase 1 player who closes the app after the first session comes back to a full hive that stopped producing early on. At best they get one 10-jar frame to harvest. Day 2 is when most players decide whether to keep a casual mobile game, and this is the experience they get. The "Offline Earnings" cap doesn't help, because production stops at hive capacity long before any hour cap is reached. The game only fixes this through optional upgrades whose cost and capacity are TBD, so a new player has no idea when relief will come, or that it exists at all.

**Source:**
- Executive Summary: "inspired by and the love child of *Egg, Inc.*" sets idle expectations.
- §2: "By default, production pauses at capacity until the player harvests, including while offline; the optional Overflow Storage and Auto-Sell upgrades change this."
- §3 Tree B: Overflow Storage and Auto-Sell, both "(capacity and costs TBD)"; Deep Frame starts at "10 jars".
- §5: "Free players earn offline up to a cap."

**Recommendation:** Give a small amount of overflow for free from the start. Tell the player on their first exit that the hive will fill and wait for them, and make Overflow Storage one of the first few purchases.

## 2. The mid-game loses its signature activity, and Phase 3 is defined as starting at the end of a run
**Severity: MAJOR**

**Problem:** The game's most fun, best-described interaction is the tactile uncapping and centrifuge minigame. Phase 2 automates it away, and there are no Phase 2 hands-on activities to replace it. What's left to do actively has low stakes:
- Pests and nectar drops give "a small reward," and ignoring them "costs nothing."
- Manual screens stay only "for upgrading tool efficiency." Once harvesting is automated, the Heated Fork and Centrifuge Gearing upgrades (swipe radius, fewer taps) seem to stop mattering, so they risk feeling like money spent for nothing.

Phase 3 is supposed to be where "the main loop comes into full swing," but it only starts after the capstone, which ends the run. So the stretch from the first automation purchase to the capstone, which is most of a run, has no stated goal, rhythm, or new activity. This is where idle players get bored and drift away.

**Source:**
- Executive Summary Phase 2/3 bullets.
- §1: "Phase 3 … The very last upgrade in the progression tree produces a Royal Crystal."
- §1 Pests & Wild Nectar Drops.
- §1 Phase 2: "Manual screens remain accessible for upgrading tool efficiency and batch multipliers."
- §3 Tree B tool upgrades.

**Recommendation:** Spell out what the player actively does and aims for during Phase 2. Possible goals include the next biome milestone, Bee Journal entries, and habitat targets. State whether manual harvesting still pays off after automation, for example a manual-quality bonus, and how.

## 3. Onboarding stops after the first upgrade, and the habitat trade-off can feel like being punished for doing what the game told you
**Severity: MAJOR**

**Problem:** The guide covers three beats: why the meadow matters, the first harvest, and the first purchase. Most of the systems a new player meets come after that and are never introduced:
- three trees
- Habitat Health
- native bees
- the hive/habitat balance
- biomes
- the capstone requirements
- the Royal Crystal reset
- research trees

The riskiest gap is Hive Balance. The stated primary goal is "make more honey and money," so a player will naturally add hives. The GDD says doing that "without enough habitat lowers Habitat Health," which in turn shrinks the native-bee multiplier. A player who wasn't taught this sees their numbers drop after a sensible purchase, can't tell why, and decides the game is unfair. The capstone also needs a Habitat Health or species threshold, so a player who ignored Tree C reaches the end of the run and finds a hidden wall.

**Source:**
- §6 onboarding beats (three only).
- Executive Summary: "The primary gameplay objective is to make more honey and money."
- §3 Tree C Hive Balance.
- §3 Capstone: "unlocks only after key upgrades are maxed (which ones TBD) and a minimum Habitat Health…"

**Recommendation:** Add guided beats for:
- the first flower planting
- the first native bee and Journal entry
- a warning before buying a hive that would harm the habitat
- the first biome unlock
- the first reset

Show the capstone requirements as a visible checklist early in every run.

## 4. Counting wall-clock time, offline included, puts speed-run pressure on a cozy game and penalizes free players for sleeping
**Severity: MAJOR**

**Problem:** Run time counts every minute, including time the player is away. For free players, offline production is capped and, in Phase 1, pauses at hive capacity. So every night of sleep adds dead time to their personal best, while Impact or Patron subscribers keep earning for up to 24 hours. The reset is "encouraged" and pitched as a race against the clock. That makes players feel they have to check in or pay, which conflicts with the "cozy" and "Families and players of all ages" positioning. Bracketing by booster keeps leaderboards fair, but it doesn't stop the free player's own clock from feeling like a penalty. Local personal-best times ship at launch, so this applies from day one, not only after online leaderboards arrive.

**Source:**
- §4: "Run Time: Wall-clock time from the start of a run to buying the capstone upgrade, offline time included."
- §5 Offline Earnings caps.
- Executive Summary: "optional but encouraged … competing for high scores based on completion speed."
- Launch Scope: "local personal-best run times."

**Recommendation:** Present run time as optional or secondary, for example a "pace" stat players can hide. Alternatively, measure progress in a way that doesn't punish normal breaks, and make sure the main reason to reset is the reward, not a clock.

## 5. The first reset asks a cozy audience to give up a farm they built, for a reward nobody has defined yet
**Severity: MINOR (partly blocked by TBDs)**

**Problem:** A reset wipes:
- every tree level
- the Habitat Health the player built up
- the second biome they unlocked
- all research

The player keeps only the Bee Journal and Royal Crystals. The Crystal's production boost is "% TBD." Families and casual players care more about their farm than about stats, so this feels like a real loss. Without a clear preview of what they keep and how much faster the next run will be, many will never press reset. If they don't, the long-term Phase 3 loop never starts for them. The restoration story ("restore" the pocket world) also clashes with wiping the restored meadow, and the GDD doesn't say how the game explains that in the story.

**Source:**
- §1 Phase 3 Crystal bullets ("% TBD").
- §1: research "do not carry over."
- §3: "Habitat levels reset with the farm each run."
- Biomes: "a reset returns the player to Sunny Meadow."
- §6 Premise: "a beekeeper to restore it."

**Recommendation:** Before the reset, show a preview screen listing what's kept and what's lost, along with an estimated speed-up for the next run. Keep a visible keepsake of past farms, such as a gallery or a hive skin, and give a story reason for "splitting the swarm" that doesn't undo the restoration.

## Round 2 — Cross-examination

### A. Revisions to my Round 1

**R1. Finding 3 (Hive Balance trap): CORRECTED, severity stays MAJOR.** Systems Designer #2 and Adversarial QA #5 are right that no upgrade in Trees A–C or the Upgrade Shop adds hives. I re-checked §3 and §8: Worker Swarm "adds active foraging bees," and the only source of hives is the Crystal's "extra starting hives" (§1 Phase 3). So my scenario, where a first-run player sensibly buys a hive and watches their numbers drop, can't happen as written. The real trap is worse for player psychology, and it moves to **the first run after a reset**. The document's own example of a prestige reward, extra starting hives, gives a player who just made the game's biggest commitment (resetting) a run that starts with *lower* Habitat Health and a harder capstone gate. A reward that turns out to be a penalty is the classic way to make a player feel tricked, and it lands right when they are judging whether prestige was worth it (my #5). The onboarding recommendation stands, but the warning beat belongs on the **Crystal assignment screen**, not on a hive purchase. The Run 1 version of the problem also changes. With no hive lever, Tree C shows no visible tension in Run 1, so players will treat it as optional decoration until the capstone's Habitat gate surprises them. That makes the recommendation to show the capstone checklist from minute one *more* important.

**R2. Finding 4 (wall-clock run time): CORRECTED in detail, severity stays MAJOR.** I wrote that Impact/Patron subscribers "keep earning for up to 24 hours." Systems Designer #3 shows that in Phase 1 the frame cap (10–25 jars) binds long before any hours cap, so paying players stall too. The free-vs-paid asymmetry I described only appears after Overflow, Auto-Sell, or Automation is bought. My conclusion holds, and Systems #4 strengthens it: the best speed-run strategy is to never put the phone down. That makes the conflict with cozy play structural, not just a monetization issue.

**R3. Finding 5 (first reset): UPGRADED from MINOR to MAJOR.** In Round 1 I treated this as mostly blocked by TBDs. But three colleague findings now combine with it:
- Narrative #1: the reset contradicts the restoration premise and has no fictional reason.
- R1 above: the sample prestige reward hurts the next run.
- Adversarial QA #2: an unbounded Crystal can skip Phase 1, removing the minigame and onboarding the player liked.

Together they make the first reset the point where the most invested players quit. Everything after the first capstone (Phase 3, Crystals, leaderboards, research) assumes players press reset. If a cozy player never does, the whole long-term loop and its monetization have no audience. That is not MINOR.

**R4. Finding 1 (Day-2 stalled hive): HOLD at BLOCKING, with a note.** Systems #1 suggests the capped economy runs out "within a few harvests," so someone could argue Overflow Storage arrives fast and solves my problem. I disagree. Overflow's cost is TBD, it is labelled "optional," and nothing tells the player it exists. The churn moment is the *first* return visit, which happens before the player knows the shop. Cheap relief that the player doesn't know about doesn't help.

### B. Conflicts

**C1. vs. Adversarial QA #4 (No-Rapid-Tap Mode must match default time AND value).** I agree on **value** parity. The Fork's "+5% batch bonus for clean cuts" and the summary modal's "tool precision bonuses" pay players with fine motor control more. A family audience includes young children and grandparents, and being paid less for using an accessibility mode tells them they are second-class. I push back on making **time** parity a design priority. The minigame lasts seconds, while run time is wall-clock hours including sleep (§4). Tap speed barely affects leaderboard results compared with check-in frequency. Slowing the accessible mode to match "real" tapping makes it feel worse for the players it serves, all to protect a competitive edge that is close to zero. Recommendation: guarantee equal payout and accept small time differences, or remove minigame time from scoring entirely, which automation does in Phase 2 anyway.

**C2. vs. Narrative Critic #4 (frame speed in-fiction, e.g., "the world is in decline and time matters").** I agree with the diagnosis but not the remedy. A decay clock in the fiction turns the existing check-in pressure into guilt: the player isn't just slow, they are letting the magic world die while they sleep. For a family and child audience this is a known source of anxiety (the Tamagotchi effect). It would also land hardest on free players, who are already hurt most by offline stalls. If speed needs an in-fiction reason, make it positive and optional, such as a "Swift Swarm" challenge mode, not a threat built into the base premise. Narrative's *other* option, reframing the success metric, is the one I support.

**C3. vs. Business Analyst #2 ("pick one primary fantasy," with competitive prestige-racer offered as an equal option).** I agree the game has to choose, but from the player-experience side the two options aren't equal. Everything that recruits a player promises the cozy fantasy: the "Chill Bee" title, the cozy tone, the family audience, the restoration premise, and the tactile minigame. A racer identity would be a bait-and-switch revealed at the first capstone, which is the worst possible moment (see R3). Speed should be the optional layer, with hideable pace stats and opt-in brackets. Business Analyst #3 supplies the reason: the differentiator is the habitat layer, not the clock.

**C4. vs. Feasibility #1 / Business Analyst #1 (cut list).** Both name Alpine Valley and research trees as likely cuts.
- **Research trees:** I accept this cut. The system is unspecified, missing from the UI, and adds a fourth system that would overload onboarding (my #3).
- **Alpine Valley:** I object to cutting it without a replacement. In Round 1 it was the only concrete goal I found for the empty Phase 2 stretch (my #2). With one biome, the run from first automation to capstone has no visible destination. If it is cut, something else must be scoped in as the Phase 2 goal, such as Journal completion tiers or habitat milestones.
- **My own recommendation:** I concede that my #3 call for five new guided beats adds to an already overloaded scope with no narrative or UI owner (Feasibility #4). I'm downgrading the ask to *one-line contextual prompts from the guide plus the capstone checklist*. That is cheap and still covers the churn risk.

### C. Connections (visible only by combining lenses)

**X1. Systems #3 + my #1 + Business Analyst #5: the Impact Pass at launch sells a perk that does nothing in Phase 1.** The Impact Pass's selling point is "extended offline production" (§8). In Phase 1 the frame cap stops production long before any hours cap. Picture a new player who buys the pass on Day 2 *because* they came back to a stalled hive, the exact pain the pass appears to fix. They get no benefit. That is a refund and a 1-star review, and it happens the first time the player is willing to pay. It also damages trust in the conservation pillar ("we sold kids a pass that didn't work"). Either the pass must include overflow or storage, or it should not be offered before automation.

**X2. Systems #1 (flat economy maxes within a few harvests) + my #2 (empty mid-game).** Apart, these read as a "balance issue" and a "content issue." Together they define the churn curve:
1. The first session feels generous: purchases come quickly and the rewards land fast.
2. Then the capped trees run out, and the only uncapped sink (Flight Endurance) has diminishing returns.
3. The next big moment, Automation, has a TBD cost and no visible price or progress bar.

Players experience this as "the game suddenly stopped paying me," the textbook day 3–7 drop-off. The fix needs both sides: a cost curve that keeps meaningful purchases spaced out, *and* a visible next goal, such as showing the automation price early as a savings target.

**X3. Adversarial QA #2 (Crystal can skip Phase 1) + Narrative #3 + my #2.** If Crystals can start a run already automated, then from Run 2 onward the game removes the activity I called its most fun interaction in Round 1. It is also the only part of the game with any onboarding or story attached. Veteran players would *permanently* have nothing to do with their hands. My recommendation: let Crystals shorten Phase 1 (bigger frames, a faster fork) but never skip it. Give the returning minigame something new each run, such as a new honey variety or a cosmetic tool, so the repetition feels like a ritual rather than a chore.

**X4. Feasibility #3 (bee rendering budget) + reward motivation.** In an idle game, seeing growth is the reward. Players feel Worker Swarm Count mainly as more bees on screen. If performance forces a cap on visible bees (more simulated than rendered), the upgrade's payoff disappears unless something else signals it: denser trails, a swarm-size counter, or louder hive audio. Feasibility should set the visual cap early so UX can design that substitute signal. Otherwise Tree A upgrades will feel like they do nothing.

**X5. Business Analyst #4 / Feasibility #2 (Kid Mode) + my #3 (onboarding).** "All ages" includes children who can't read yet. Every onboarding beat and the Bee Journal's "real-world facts" are text, and French localization doubles that text. If young children are a real audience, onboarding must work through icons, voice, or animation. Otherwise the habitat systems, which are the game's educational point, go unread by the very players they are meant to teach. This should be decided alongside the audience definition Business Analyst asks for.
