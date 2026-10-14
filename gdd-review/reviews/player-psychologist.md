# Player Psychologist — Round 1

## Finding 1: The first hour is undesigned, and it opens on the game's most grind-heavy phase
**Severity: BLOCKING**

**Problem:** There is no onboarding, tutorial, or first-session plan anywhere in the document. What a new player does in minute 1, minute 10, and minute 60 is never described. The first thing they get is the stage the document itself calls "The Grinding Stage" and "High manual labor": swiping, cranking, planting, watering, and selling by hand. That clashes with the "cozy, casual" pitch the player installed the game for. The document also never says how long Phase 1 lasts or what triggers Phase 2 beyond "first few upgrades." So nobody can say when the relief arrives, which is exactly when an early player decides whether to stay or quit. The minigame runs every time "hive storage reaches capacity," and a frame holds only 10 jars at base. Repeating that two-stage sequence many times is a strong fatigue risk before automation shows up. There is also no base honey price, so we can't estimate how many repetitions it takes to afford the first upgrades.

**Source:** Executive Summary, "Phase 1 (The Grinding Stage): High manual labor..."; Game Mechanics §2, "When hive storage reaches capacity in Phase 1, players trigger..."; Tree B, "Expanded Frame Deep: ...from 10 jars"; no FTUE, tutorial, or pacing section exists. The Phase 1 to Phase 2 trigger is never defined.

---

## Finding 2: Prestige resets plus speed-run leaderboards break the cozy promise, and the paid boost makes the competition feel rigged
**Severity: MAJOR**

**Problem:** The audience the document targets ("cozy," "relaxed ukulele," "playful, whimsical") is told that the endgame is wiping the farm they built ("the pocket dimension resets") and then "competing for high scores based on completion speed." Cozy players care about attachment and their own pace. A forced reset of a diorama they have put time into reads as loss, not reward, unless the document spells out what visibly carries over (cosmetics, layout, named hives). It doesn't. The competitive layer is also undermined from the start. The Patron Pass gives "+25% global honey value multiplier (persists across Phase 3 resets)" and a premium currency stipend, and its owners carry a golden badge on the same speed-run leaderboard. Free players will reasonably conclude the leaderboard can be bought, which kills the motivation the leaderboard was meant to create.

**Source:** Executive Summary, Phase 3 ("pocket dimension resets... competing for high scores based on completion speed"); Aesthetic & Tone; Monetization, Patron Pass ("golden 'Patron' badge on speed-run leaderboards," "+25% global honey value multiplier (persists across Phase 3 resets)"). No description of what the player keeps visually or emotionally after a reset.

---

## Finding 3: Upgrades to the manual tools become wasted investment once automation arrives
**Severity: MAJOR**

**Problem:** In Phase 1 the player is pushed to spend money on Heated Uncapping Fork (swipe radius and clean-cut bonus) and Centrifuge Gearing (fewer taps). Those upgrades only make sense inside the manual minigame. Phase 2 then replaces that minigame with "automated uncapping hubs, electric centrifuges." The document says manual screens "remain accessible for upgrading tool efficiency and batch multipliers," but it never says whether those upgrades affect automated output. If they don't, the player's early spending feels thrown away, and the fun tactile minigame they learned has no reason to exist. If they do, the player is never told that. Either way the link between effort and reward is broken at the exact moment of the phase transition.

**Source:** Tree B (Heated Uncapping Fork, Centrifuge Gearing); Game Mechanics §1, Phase 2 ("Manual screens remain accessible for upgrading tool efficiency..."); Executive Summary, Phase 1 parenthetical. There is no statement on how manual tool upgrades carry into automation.

---

## Finding 4: Long-term goals are missing. Biomes, flowers, and the "Factorio" promise have no player-facing path
**Severity: MAJOR**

**Problem:** The game is pitched as *Egg, Inc.* crossed with *Factorio*, but every upgrade listed is a flat percentage on a single stat. Nothing in the document describes layout, logistics, or spatial problem-solving, which is what Factorio-motivated players will expect. Meanwhile the clearest aspirational goals, the four biomes (Sunny Meadow to Cloud Gardens) with their own honeys, have no unlock condition, cost, or place in the phase structure. Players can't work toward what they can't see. Several trees also cap early (tools at max 5, Frame Deep at max 3, Swarm Count at max 10), and Flora Synergy has no numbers at all. That leaves a real chance of an "I've bought everything, now what?" gap before the reset, which is the most common point where idle games lose players.

**Source:** Executive Summary ("love child of *Egg, Inc.* and *Factorio*"); Tree A/B/C upgrade specs and max levels; Tree C, Flora Synergy (no values); Progression Tiers & Biomes (no unlock criteria). No mid-term goal or milestone structure exists.

---

## Finding 5: Systems and currencies appear without explanation, and the conservation framing sets up expectations that may break player trust
**Severity: MINOR**

**Problem:**
- **Undefined friction:** "Pest events" and "wild nectar drops" first show up as things the paid Golden Drone handles. The free player meets a negative mechanic the core design never describes, and it looks like it exists to be sold away. The same goes for offline earnings: Patrons get "up to 24 hours," but the free baseline is never stated. That baseline is what decides whether returning players feel welcomed or punished.
- **Name overload:** "Royal Jelly" is the name of the reset ("Royal Jelly Harvest"), the premium currency, and the biome-4 product ("Stardust Royal Jelly"). The prestige currency also has two names ("Queen Markers" / "Royal DNA"). New players will mix these up.
- **Impact expectations:** Every batch summary shows "real-world wildflower seed contributions," which tells a free player that their own play is helping. But the funding sources listed are all monetized (ads, passes, Adopt-a-Hive). If free play doesn't actually contribute, players who find out will feel misled. Tying ads "explicitly" to habitat funding also risks turning an optional boost into a guilt prompt, which works against the cozy tone.

**Source:** Patron Pass ("handles pest events," "extends offline idle earnings up to 24 hours," "daily stipend of Royal Jelly premium currency"); Executive Summary ("Swarm Splitting / Royal Jelly Harvest"); Game Mechanics §1 ("Queen Markers (Royal DNA)"); Biome 4; §2 summary modal ("real-world wildflower seed contributions"); Monetization, "Non-Predatory Rewarded Ads... explicitly tied to native habitat funding."

---

## Round 2 — Cross-examination

### A. Conflicts (where I push back)

**A1. Business Analyst F5 ("cut the minigame's scope"): I disagree. It is the onboarding, not dead weight.**
BA calls the 3D uncapping/centrifuge minigame the costliest content for "the phase the game is designed to automate away," and offers cutting its scope as one option. From the player's side, that minigame is the only thing in the first ten minutes with tactile novelty (raycast slicing, particles, haptics). It is what makes Phase 1 bearable rather than just a grind. Cutting it would leave a first session of tapping menus for percentage upgrades, which makes my Round 1 F1 (undesigned first hour) worse. My position: keep the minigame at full quality and change *how often it is required*. Make the first 3–5 batches fully manual as a taught ritual, start soft automation early, and afterwards keep it as an optional high-value "artisanal batch," which is BA's own alternative. BA's real concern is cost per minute of play. The fix is to raise how many minutes it gets played, not to lower its quality.
I also see a new problem by combining this with GDD line 87: the Impact Pass sells "auto-tap helpers." So the document puts its most polished first-session content up for sale as something to skip. That tells players the minigame is a chore, and it undercuts both BA's ROI argument and my onboarding argument.

**A2. Feasibility Lead F1 (likely cuts include "the genetic research trees"): cut the leaderboards first. Cutting the meta tree breaks the reason to prestige.**
I agree with the vertical slice and the cut order in general. But FL lists the genetic research trees and the leaderboards as if they were equally cuttable. For player motivation they are not. In an idle game, a reset is only acceptable when the player can *see what it buys* in a meta tree. Remove that tree and the reset is pure loss (my Round 1 F2) with a bare "+x% production" as its only payoff. Leaderboards, on the other hand, attract only a minority of a cozy audience, cause the pay-to-win perception problem (AQA F1, BA F1, SD F2, my F2), and need the server work FL F3 describes. My suggested cut order: leaderboards out of the vertical slice, plus a minimal meta tree (5–8 nodes) kept in, if prestige ships at all.

**A3. Feasibility Lead F4 ("fallback: lower bee count"): the bee swarm is the main progress signal, so protect how dense it *looks*.**
FL's MultiMesh/shader approach is right. But "lower bee count" as the fallback trades away the most important feedback an idle game has: seeing your operation grow. In idle games the visible crowd *is* the reward. A player who buys Swarm Count and sees no more bees on a low-end phone gets nothing for the purchase. The fallback should keep perceived density (impostors, cluster sprites, LOD swarms where one visual bee stands for N) rather than shrinking the visible count. This is a constraint from the player's side on FL's solution, not a rejection of it.

**A4. Narrative Critic F5 (make pests a base-game threat): yes to stakes, but they must not punish.**
NC wants real pollinator threats in the base loop for thematic tension. I agree the theme needs them. But cozy players churn on *loss while away*. If pests destroy production while the player is offline, the return session starts with a penalty, and the free player cannot prevent it while the paid Golden Drone can, which is the predatory pattern I flagged in Round 1 F5. Version that works for this audience: threats appear only during active play, pause while offline, and turn into a *gain* when handled (a habitat-restoration action, a rescued colony) instead of a loss when ignored. That keeps NC's theme without bringing in the anxiety loop.

**A5. Business Analyst F1 ("choose one primary audience"): agreed, and I'll name it. It is cozy.**
BA leaves the choice open. The evidence points one way: tone, music, art, conservation framing, and the "pocket dimension" pitch all target cozy players. Only one sentence and the Patron badge point to competition. Competition should become an opt-in, separate ladder with no boosts allowed (also AQA F1's suggestion), not a co-equal pillar.

### B. Connections (issues visible only by combining lenses)

**B1. Systems Designer F3 + my F1: the player's first purchase may visibly do nothing.**
SD shows that in Phase 1 Worker Swarm (+15% fill rate) only fills the hive faster, while the actual limit is manual harvesting. For a new player, Worker Swarm is the most obvious first purchase ("more bees = more honey"). If it brings no felt improvement, the first spend teaches the player that upgrades don't matter. That is a disastrous lesson for minute 5–15 of an idle game. The FTUE needs a guided first purchase that pays off immediately and visibly (Frame Deep or Artisanal Branding, not Worker Swarm).

**B2. Systems Designer F5 + my F4: the "now what?" wall is now quantified.**
SD totals all capped upgrades at about $3,840, with last levels costing only 2–3x the first. Combined with my F4, every capped upgrade could be bought well before the uncapped/undefined items (Flight Endurance, Flora Synergy, automation) give the player anything to aim at. Players then face a stretch where the only visible goal is an endless +% on bee speed. That is exactly the mid-game dead zone where idle games lose players. It makes my F4 more concrete and more serious (see C2).

**B3. Adversarial QA F4 (full hive stalls) + my F5 (no free offline baseline): the return session is empty, and paid offline time may be worth nothing.**
If production stops at a full hive in Phase 1, a free player who comes back after 8 hours finds one full frame, which is the same as after 20 minutes. Coming back is not rewarded, and that kills the day-1 to day-2 return habit. Worse, a player who bought the Impact Pass for "extended offline production" gets nothing extra in Phase 1. That is the first paid experience for an early subscriber, and it is a refund/review risk. The doc needs a free offline baseline plus an overflow buffer (or auto-harvest while away) from day one.

**B4. Feasibility Lead F3 (device-clock exploit) + my F2: honest players see both cheaters and payers at the top.**
I argued in Round 1 that the paid +25% makes free players think the board can be bought. FL adds that without server time validation, clock-changers will fill the top ranks. A free player then sees a board topped by badges and impossible times. In that situation the most rational response is to stop caring about the leaderboard. That is extra support for A2: cut leaderboards from the slice.

**B5. Feasibility Lead F2 / AQA F5 (no non-touch input) + my F1: there is no first hour at all on desktop/Switch.**
Since the FTUE is the manual minigame, a platform with no swipe/crank mapping or haptics fallback has a broken first session, not just a missing polish feature. This supports BA F4 and FL F2 (mobile-only launch) from the onboarding side.

**B6. Narrative Critic F4 (no narrative spine) + my F1: no tutorial voice.**
No guide, keeper, or narrator exists, so nobody can teach the player anything. The cheapest fix for both NC's gap and my FTUE gap is one guide character (a queen bee or a partner-org ranger) who explains the first harvest, the first purchase, and why the meadow matters.

### C. Revisions to my Round 1

**C1. Upgrade: the impact-expectations bullet in F5 goes from MINOR to MAJOR and becomes its own finding.**
NC F2, AQA F5, and BA F3 all flag the "real-world wildflower seed contributions" modal independently. AQA and BA add consumer-protection and app-store exposure. From the player side, the impact pillar is the game's *reason to feel good*. When a cause-driven game turns out to show contributions that don't exist, the result is a public trust collapse (store reviews, social posts), not quiet churn. That outweighs a naming problem. Recommended fix: the modal shows the *community* total and states the funding source plainly ("Ad views and passes this week funded X seed packets").

**C2. Upgrade: F4 (no long-term goals) moves toward BLOCKING, conditional on SD's numbers.**
SD F5's cost math shows the capped tree is short, and SD F1/AQA F2 show the prestige trigger cannot be reached as written. Together these mean the mid-game currently has *no* designed goal. I keep F4 at MAJOR only because the income side is unknown. If base jar income makes ~$3,840 reachable in the first session or two, it should be treated as blocking.

**C3. Partial withdrawal: F2's "forced reset" wording.**
I re-checked the GDD. Line 29 says "players trigger a dimension reset," which implies the player opts in. Line 12 ("the pocket dimension resets") sounds automatic. I called it forced, and that overstated it. The real issue is the ambiguity (AQA F2 asks the same question). The loss-aversion point still holds even for an optional reset, because the doc never states what visibly carries over. Optional resets help cozy players a lot, so the doc should commit to "optional" explicitly.

**C4. Partial downgrade: F1's fatigue claim, not the FTUE claim.**
SD's short-tree numbers suggest Phase 1 *might* be brief, which would weaken my "many repetitions before relief" argument. I can't confirm this without income values, so the fatigue part becomes "unverified." F1 stays BLOCKING because no onboarding plan, Phase 2 trigger, or first-session pacing exists, and B1 and B5 add new first-hour failures.
