# Adversarial QA — Round 1

## 1. Royal Jelly bracketing can't be enforced: the currency is pooled and carries over — BLOCKING
**Problem:** Leaderboards say purchased Royal Jelly makes a run "boosted" and earned Royal Jelly does not (§4, "Royal Jelly"). But the currency table (§5) treats Royal Jelly as one balance. It comes from play, rewarded ads, real-money purchases and the Patron daily stipend, and it carries over resets. The document never says whether jelly is tracked by source. So when a player spends 50 jelly mid-run, nothing determines which bracket the run goes in. The edge cases are unaddressed:
- **Patron stipend jelly:** Is it "paid"? The stipend is part of a paid subscription, but §4 lists only "purchased" jelly as a booster.
- **Lapsed subscriptions:** §5 says jelly carries over, and the Patron Pass section says "All Patron bonuses ... stop when the player stops paying." Stipend jelly hoarded while subscribed can therefore be spent after cancelling. That contradicts the "bonuses stop" rule, and it lets a player land on a cheaper bracket or the unboosted board with paid-origin resources.
- **Ad-earned jelly:** It stays on the unboosted board (§4, "Rewarded Ads"). Ad watching can therefore stockpile time skips across many runs, then dump them into one record run.

**Source:** §4 "Royal Jelly", "Run-Based Brackets"; §5 currency table; Patron Pass "Concept" and "Subscription Boosts".
**Fix needed:** Track jelly by source (earned / ad / purchased / stipend) and set a spend order, or tag the run by the source of each jelly unit actually spent. Also decide whether stipend jelly survives cancellation.

## 2. A Royal Crystal starting upgrade can skip phases or break the capstone gate — MAJOR
**Problem:** Each Crystal "can also be applied to any one starting upgrade for future runs (e.g., extra starting hives)" (§1 Phase 3). The word "any" is unbounded, which allows several exploits:
- **Skipping Phase 1:** Applying a Crystal to the first Automation upgrade skips Phase 1 every run, along with its minigame and onboarding. Is that allowed?
- **Pre-maxing the capstone requirements:** The capstone requires "key upgrades ... maxed" (§3 Capstone). Stacking Crystals onto those upgrades, or onto max-level upgrades like Deep Frame (max 3), could pre-satisfy the gate. Run time then collapses toward the Habitat threshold alone.
- **Extra starting hives:** This is the document's own example, and it conflicts with Hive Balance: "Adding hives without enough habitat lowers Habitat Health" (§3 Tree C). Habitat also "resets with the farm each run". A high-prestige player starting with many hives therefore begins each run with low Habitat Health, which makes the restoration gate harder. The prestige reward ends up working against the capstone, and Habitat Health has no defined floor or failure state.
- **Unanswered questions:** Can several Crystals be stacked on one upgrade? Can a Crystal be applied to Overflow/Auto-Sell, Tree C, the Capstone itself, or research? Can a Crystal's assignment be changed later?

**Source:** §1 Phase 3 bullets; §3 Capstone; §3 Tree C "Hive Balance" and "On Reset".
**Fix needed:** Write an explicit whitelist of starting upgrades a Crystal can apply to, with per-upgrade caps. Exclude Automation and the capstone prerequisites, or say deliberately that skipping them is intended. Define how starting hives interact with starting Habitat Health.

## 3. Wall-clock run time conflicts with offline pausing, offline caps and biomes added after launch — MAJOR
**Problem:** Run Time is "wall-clock time ... offline time included" (§4). At the same time:
- **Offline stalls:** Production "pauses at capacity until the player harvests, including while offline" (§2). Pests and nectar drops "pause while offline" (§1). Free players also hit an offline cap, with hours TBD (§5). Free runs are therefore dominated by how often the player opens the app (for example while asleep), not by optimization. Overflow Storage and Auto-Sell are labelled "optional", yet they directly reduce run time, so in practice they are mandatory for anyone competing.
- **Phase 2+ capacity behaviour:** The capacity pause is specified only "in Phase 1" (§2). Behaviour at capacity once automation is bought is undefined. It matters because offline earnings are only meaningful if production continues.
- **Subscription lapse mid-run:** The Patron Pass's 24h offline window and +25% multiplier are a big run-time advantage. If the subscription lapses mid-run, the document doesn't say whether the run keeps its Patron tag. §4 says "every paid booster active during that run", so even one day of Patron puts the whole run in the Patron bracket. That makes the Patron bracket a dumping ground and leaves the board's meaning unclear.
- **Biomes added after launch:** Biomes are "stages within a single run, played in order" (Biomes section). Launch ships with 2 biomes and post-launch adds 3–4. Adding biomes lengthens every run, which makes launch-era local personal bests incomparable. The document also doesn't say whether the capstone moves to the last biome or stays reachable in Sunny Meadow or Alpine Valley.

**Source:** §4 "Run Time"; §2 intro; §1 "Pests & Wild Nectar Drops"; §5 "Offline Earnings"; Biomes intro; Production Plan launch/post-launch scope.
**Fix needed:** Specify behaviour at capacity for every phase. Version leaderboards and personal bests by content set (number of biomes). Define where the capstone sits relative to biomes. Define how a booster that starts or lapses mid-run is tagged.

## 4. No-Rapid-Tap Mode outperforms the default input and makes an upgrade worthless — MAJOR
**Problem:** No-Rapid-Tap Mode replaces speed taps and cranking "with hold-to-crank or a single tap" (§7). Neither the mode nor the leaderboard spec says this mode extracts at the same speed as the default. If a single tap completes extraction:
- **Competitive edge:** Phase 1 becomes faster with the accessibility mode than with the default input, which is a speed-run advantage on the unboosted board.
- **Dead upgrade:** Centrifuge Gearing ("Reduces required extraction taps/spins by -15% per level", §3 Tree B) becomes a pointless purchase in that mode. Its effect in the mode is unspecified.
- **No swipe alternative:** The Heated Uncapping Fork's "+5% batch bonus for clean cuts" and the "tool precision bonuses" on the summary modal (§2) depend on swipe skill. Players who can't swipe precisely have no accessible equivalent, so they earn less per batch.

**Source:** §7 "No-Rapid-Tap Mode"; §2 Stage 2 and summary modal; §3 Tree B Centrifuge Gearing and Heated Uncapping Fork.
**Fix needed:** Make the accessibility mode take the same time and give the same value as the default input. Define how Gearing and precision bonuses apply in that mode.

## 5. "Key upgrades maxed" is unenforceable for some listed upgrades, and per-level values are missing — MINOR
**Problem:** The capstone requires "key upgrades are maxed (which ones TBD)" (§3 Capstone).
- **No max level:** Flight Endurance (§3 Tree A) has no max level. If it is ever chosen as a key upgrade, the gate can never be met.
- **No per-level value:** Deep Frame goes "from 10 jars to 25 jars" over 3 levels with no per-level increment, so the Level 1–2 values are undefined.
- **"Hives" is never defined:** Tree A's Worker Swarm "adds active foraging bees", while Hive Balance penalizes "adding hives". No upgrade in Trees A–C actually adds hives, so it's unclear what action triggers the Habitat Health penalty. The only hive source the document names is the Crystal's "extra starting hives".

**Source:** §3 Tree A Flight Endurance; Tree B Deep Frame; Tree C Hive Balance; Capstone.
**Fix needed:** Give every upgrade a max level (or mark it uncapped and ineligible for the capstone gate). List Deep Frame's per-level values. Add an explicit "Buy Hive" upgrade with costs.

## Round 2 — Cross-examination

### CONFLICTS

**C1. Player Psychologist #4 and Narrative Critic #4 ("measure run time in a way that doesn't punish breaks"). I disagree with the proposed fix, but I agree with the diagnosis.**
I agree that wall-clock time combined with the capacity pause punishes sleep. I disagree that the metric itself is the thing to change. The GDD backs wall-clock time with "Server-Side Time Validation", which makes it the only run metric that is cheap to verify. The alternatives each open an exploit:
- **"Active time" metric:** It rewards leaving the app open in the foreground with an auto-clicker, or splitting play across short sessions while offline production does the work. It also needs client-side session tracking, which the server can't validate.
- **In-game-time or "pace" metric:** It hands the clock to the client, which brings back the device-clock manipulation that §4 exists to prevent.

The real defect is the pause, not the clock. My Round 1 #3 fix still holds: define behaviour at capacity in every phase. Psychologist #1's recommendation (a small free overflow from the start) is the right lever. It removes most of the "sleep penalty" without touching a metric we can verify. A "hide the pace stat" toggle is fine as UX, but it doesn't fix the problem. Local personal bests ship at launch and still record the penalized time.

**C2. Narrative Critic #4's proposed fix ("the world is in decline and time matters") creates a fail state the GDD doesn't have.**
A world that visibly declines over time implies decay while the player is away. The GDD currently has no loss condition. The only negative pressure is Habitat Health, which already has no defined floor (my #2). A decline mechanic would need answers to these questions:
- Can Habitat Health hit zero?
- Can the capstone gate become *un*-met after it was met?
- Do native species leave the Journal?

If the decline is cosmetic only, the fiction ("time matters") and the systems ("nothing is lost") contradict each other again. If it is real, it is a punishing fail state aimed at the families audience. I'd steer narrative toward Narrative #1's "swarm seeds a new pocket world" framing instead. That framing explains the reset without adding a timer.

**C3. Narrative Critic #1's "restored worlds stay as a visitable collection" needs a hard rule: past worlds must be inert.**
If prior worlds keep producing, keep their native species, or keep their Habitat Health, then a reset no longer resets anything. Players would farm old worlds between runs, and run time for the unboosted board would stop meaning anything. This is compatible with my lens only if past worlds are cosmetic snapshots with no economy. Psychologist #5's "gallery or hive skin" keepsake is the safe version of the same idea. The GDD must state this explicitly before Bob builds anything persistent.

**C4. Business Analyst #3 says the leaderboard rules are over-specified for a post-launch feature. They are detailed, but they are not sound.**
I agree that effort is misallocated. But I disagree with the implication that the bracketing section is "done". My #1, Systems #4 and Feasibility #5 each found independently that the most detailed section in the document can't be enforced, because of one wallet. More detail on bracket tiers didn't produce a correct rule. Cutting it back to a "post-launch TBD" stub would be fine. Shipping it as written would not.

### CONNECTIONS

**X1. Systems Designer #1 (flat economy, ~$3,840 for the whole capped tree) combined with my #1 (jelly stockpiling) makes the jelly exploit far worse.**
If a run is only a few harvests long, the fixed-duration time skips that jelly buys are a huge *share* of the run. A stockpile saved over several runs could cut a large fraction off one record run while the run stays on the unboosted board. The shorter the intended run, the more decisive banked jelly becomes. This also means Systems #1's fix (longer, multiplicative sinks) and my fix (a per-source ledger, or a per-run jelly cap) should be designed together. Tuning run length without a jelly-spend cap just moves the exploit.

**X2. Systems Designer #1 combined with my #2 (Crystal starting upgrades) shifts all the gate pressure onto Habitat, which the Crystal's own example undermines.**
If the "key upgrades maxed" half of the capstone gate opens within a few harvests anyway, the Habitat Health / species threshold becomes the *only* real gate. The GDD's own Crystal example, "extra starting hives", lowers starting Habitat Health under the Hive Balance rule (also noted by Systems #2). The one prestige reward the document names therefore directly slows the only meaningful gate. That isn't a nuance. It means the prestige loop may make runs *longer* as Crystals accumulate, which inverts the core loop.

**X3. Systems Designer #3 (manual-tool upgrades sunk after automation) combined with my #4 (Centrifuge Gearing is dead in No-Rapid-Tap Mode) leaves Gearing with almost no value.**
Gearing does nothing in No-Rapid-Tap Mode and possibly nothing after Phase 2. For an accessibility-mode player it is *never* a meaningful purchase. If it is ever named a "key upgrade" for the capstone gate, those players must pay for a no-op to finish a run. The precision bonuses (Fork clean-cut) have the same problem twice: swipe skill doesn't apply in the accessibility mode or under automation. One rule should cover both ("tool upgrades convert to flat output bonuses when input is automated or simplified").

**X4. Player Psychologist #3 recommends "a warning before buying a hive that would harm the habitat", but that purchase doesn't exist (my #5, Systems #2).**
Two lenses reached the same gap from opposite sides. The onboarding the Psychologist wants has nothing to attach to, and the core Tree C trade-off can't currently be triggered in a first run. This is stronger evidence that the missing "Buy Hive" action is a structural hole, not a cosmetic one (see R1 below).

**X5. Feasibility Lead #5 and Business Analyst #5, combined with my #1, mean the jelly ledger must be in the launch save schema even if jelly IAP isn't.**
Business #5 points out it's unclear whether Royal Jelly IAP ships at launch. If it doesn't, every launch-era jelly balance is earned or ad jelly. Those balances carry over resets indefinitely ("Carries Over Resets: Yes"). When IAP and online leaderboards arrive after launch, untagged legacy balances would get mixed with purchased jelly in one wallet, and nothing could classify them retroactively. Feasibility's "build separate server-tracked ledgers from day one" is the only safe option. The ledger needs a source tag per unit from the first build, whatever the IAP timing.

**X6. Feasibility Lead #5 (Patron features written into launch systems) shows that one of those features does almost nothing.**
The Golden Drone "taps [pests and drops] automatically" (Patron Pass). But pests and drops "appear only during active play and pause while offline" (§1). The headline Patron QoL perk only works while the player is already looking at the screen, where they could tap the pests themselves. The pests also give only "a small reward". The perk is close to worthless, or it is meant to work offline, which contradicts §1. Either way, the Patron value proposition the Business Analyst is costing is weaker than it looks.

**X7. Feasibility Lead #3 (separate simulated bees from visual bees) combined with my #3 means offline and capacity behaviour must be a formula, not a simulation.**
If the bee count is capped for rendering, offline earnings, Worker Swarm scaling and any bee-based Habitat penalty all have to come from an analytic rate, not from simulated bees. That rate is exactly the "behaviour at capacity per phase" rule my #3 asks for. It is also what server-side time validation needs in order to re-compute a run. Writing it down solves a feasibility problem and an exploit problem at once.

### REVISIONS

**R1. #5 "Hives" never defined: upgrading from MINOR to MAJOR.**
Systems #2 and Psychologist #3 confirm independently that the missing hive purchase disables the only cross-tree trade-off and the onboarding beat built around it. A rule that can't be triggered is a structural gap. The Flight Endurance and Deep Frame per-level parts of #5 stay MINOR.

**R2. #2 Crystal bullet on pre-maxing the capstone requirements: downgrading.**
Given Systems #1's math, "key upgrades maxed" is cheap anyway, so Crystals pre-maxing them saves little. The bullet on skipping Phase 1 stands. Systems #3 also raises the same "can Crystals skip the manual minigame?" question. The bullet on extra starting hives versus Habitat is *upgraded* in importance (see X2). Overall #2 stays MAJOR, but its weight moves from the capstone-gate exploit to the prestige reward working against the Habitat gate.

**R3. #1 stays BLOCKING, with its scope sharpened.**
The Patron-stipend sub-issue is post-launch only, because the Patron Pass is listed as post-launch (Feasibility #5 / GDD line 25). The core issue, one wallet with no source tag, is still blocking because of X5: it's a launch save-schema decision that can't be fixed after launch.

**R4. #3 run-time conditional note.**
If the team accepts Business Analyst #2's recommendation to make the game a cozy idler with "personal bests as a light layer", #3's leaderboard-tagging sub-issues (Patron lapse mid-run, bracket dumping ground) fall to MINOR. The biome-versioning and capacity-behaviour sub-issues stay MAJOR, because local personal bests and offline progress ship at launch regardless.
