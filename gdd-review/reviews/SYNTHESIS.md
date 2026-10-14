# Design Review Board — Synthesis

**Document:** Chill Bee Game GDD (`GDD.md`, ~1,770 words)
**Board:** Systems Designer (SD), Narrative Critic (NC), Player Psychologist (PP), Technical Feasibility Lead (FL), Adversarial QA (QA), Production/Business Analyst (BA)
**Method:** 6 independent Round 1 reviews (30 findings) → Round 2 cross-examination → moderated synthesis. Everything below traces to the review files; the moderator adds no critiques of its own.

---

## 1. Top 5 issues (ranked by severity × confidence)

### #1 — The speed-run leaderboard is pay-to-win, can't be verified, and contradicts the cozy pitch · BLOCKING
**Flagged by:** QA F1, BA F1, SD F2, PP F2, NC F3/F5, FL F3 (all six)
**Cross-examination: STRENGTHENED**

- Round 1 found that the Patron Pass's +25% multiplier carries across resets and that its badge sits on the same speed-run board.
- In Round 2 the case widened:
  - **Bigger paid edge (SD X2).** Patron value bonus, uncapped 2x ads and paid-only pest removal stack to roughly **2.5x** a free player's income, not 25%.
  - **No fair definition of run time (QA X1 + FL F3).** Every definition can be broken: offline earnings plus a device-clock change, with no server time validation.
  - **Excluding Patrons isn't enough (QA C3).** Ads and the Impact Pass still affect runs, and lapsed or mid-run passes create new edge cases.
  - **The feature is tiny on the page (BA).** It is one clause (line 12) plus one badge mention (line 90).
- SD downgraded its own finding to MAJOR, but only on condition that leaderboards are cut. Every other reviewer kept or raised the severity.

### #2 — The conservation pillar makes claims the design and funding model don't support · BLOCKING
**Flagged by:** NC F1/F2, BA F3, QA F5, PP F5, FL F3 (all six)
**Cross-examination: STRENGTHENED**

- **The modal over-promises.** Every batch summary shows "real-world wildflower seed contributions," but only monetization funds conservation (line 14).
- **The beneficiaries don't match.** The Patron Pass funds "managed hives" (line 89), while the headline pillar promises *native* bee habitat (QA X3, NC F1).
- **Payouts and partners are vague.** Percentages are "25–50%" and "a significant portion," and partners are listed only as "such as" (BA F3).
- **Upgrades.** In Round 2, NC, QA and BA each raised their finding to BLOCKING, and PP raised its own to MAJOR. FL raised the backend to BLOCKING because this pillar needs donation accounting and compliance work. BA describes the combination as a "greenwashing profile" that blocks any impact-based marketing or store submission.
- **The message also disappears (NC X1).** The modal only shows during manual harvests, so the impact message vanishes once Phase 2 automates harvesting.

### #3 — The macro-loop is undefined: unreachable prestige trigger, no Phase 1→2 gate, unlinked biomes, no income model · BLOCKING
**Flagged by:** SD F1/F4/F5, QA F2/F4, PP F4, NC F4, BA F5, FL X1
**Cross-examination: STRENGTHENED**

- **The trigger can't fire.** "End of the progression tree" can never be reached: Flight Endurance has no cap, and Flora Synergy has no numbers at all.
- **The automation unlocks are missing.** They appear in no tree and have no cost. Queen Markers have no formula, and the four biomes have no unlock rules or mechanical role.
- **Short, then stuck (QA C1).** The capped upgrades total only about $3,840. After that, one uncapped +10% stat is the only thing left to buy.
- **The GDD contradicts itself on the reset (QA X6).** It is automatic in line 12 and player-triggered in line 29.
- **The AI pipeline depends on it (FL X1).** The pipeline cannot run as designed, because the "progression file" its agents must ground against doesn't exist.
- **Severity.** PP moved its long-term-goals finding toward BLOCKING. SD calls this "the single highest-leverage fix in the document."

### #4 — Scope has no team, timeline, cut list or backend plan · BLOCKING
**Flagged by:** FL F1/F3/F5, BA F2/F4, QA F5 (platforms), PP B5
**Cross-examination: SURVIVED (and reframed)**

- **The scope is large.** Six platforms, four biomes, three monetization tiers, a live dashboard and a prestige meta-tree, with no MVP and nothing marked as deferrable.
- **The team is effectively one person.** BA (Connection B) and FL agree the AI-agent roster is the only staffing evidence, which implies one developer working with LLM agents. No agent owns QA, builds, the backend, payments or compliance.
- **Switch and desktop fail on three separate grounds** (BA Connection C):
  - no business model off mobile (BA F4)
  - no first-party Godot console export (FL F2)
  - no non-touch input scheme (QA F5)
- **Revised cut order.** FL revised its cut order in Round 2 and moved a minimal prestige layer *into* the vertical slice.
- **Downgrades within this finding.** FL lowered 60 FPS with hundreds of bees to MINOR, and partly withdrew the C# risk because the GDD only says "if required."

### #5 — The first hour isn't designed, and Phase 1's rules decide whether the paid perks do anything · BLOCKING / MAJOR
**Flagged by:** PP F1/F3, SD F3, QA F4, FL X3, NC C3, BA F5
**Cross-examination: STRENGTHENED (fatigue claim WEAKENED)**

**What is missing:**
- There is no onboarding, tutorial or first-session plan.
- The game opens on what the document itself calls "The Grinding Stage."
- There is no guide character to teach anything (PP B6, NC F4).

**What Round 2 added:**
- **Hive-full behavior controls the paid perks** (SD X1, QA X2, FL X3, PP B3). If a full hive stops producing, then in Phase 1:
  - rewarded ads do nothing
  - paid offline hours are worth nothing
  - a returning player finds the same single frame after 8 hours as after 20 minutes
- **SD raised this sub-issue to BLOCKING.**
- **The first purchase may do nothing visible (PP B1).** Worker Swarm is the obvious first buy, but it only fills a hive that is already waiting on manual harvests.
- **Tree B tool upgrades may become dead spending at Phase 2.**
- **The only automation the GDD actually describes is paid** (the Impact Pass "auto-tap helpers," QA X4). That amounts to a soft paywall on the phase change.

**What weakened:** PP marked its own repetition and fatigue claim as unverified, because there is no base income figure to check it against.

---

## 2. Unresolved disagreements

**D1. If the speed race goes, what replaces it?**
- **Cut it** (FL, BA, PP). FL: keep local personal bests. BA: cutting it is the board's highest-leverage single change. PP: at most an opt-in ladder with no boosts allowed.
- **Replace the metric** (NC). A fair race is still a race in a game called "Chill." Rank something the story values instead, such as meadow biodiversity or community "acres restored."
- **Caveat** (SD, partly QA). Removing leaderboards takes away the GDD's *only* stated reason to reset, so all the payoff then rests on Queen Marker math that doesn't exist yet. If boards stay, runs must be tagged by everything that boosted them (QA C3).
- **Decision escalated:** cut outright or replace with a non-speed metric. In either case, the team must specify the reset's standalone payoff.

**D2. Fix the honeybee vs. native-bee contradiction by changing the game, or by changing the claims?**
- **Change the game** (NC). Bring native pollinators and habitat health into the core loop. SD and FL back this only through the empty Flora Synergy slot, which costs no extra scope.
- **Change the claims** (BA). Align the charity claims and partners with what the game actually shows, drop "native bee" wording where the money funds managed hives, and treat a native-pollinator layer as post-launch.
- **Decision escalated:** is the launch fantasy "habitat steward" or "honey business with honest impact copy"?

**D3. Is a permanent paid multiplier acceptable once leaderboards are gone?**
- **Yes** (SD, revised). A paid +25% is a standard idle-game lever (*Egg, Inc.* sells similar). It is BLOCKING only if speed boards ship.
- **No** (BA). Selling a permanent advantage in a cause-marketing game is a brand and platform-review problem. In a tree that maxes at about $3,840, +25% is an outsized share of power (BA Connection E).
- **Partly** (QA). It can't be judged until the rules on what persists after a lapsed pass are written.
- **Decision escalated:** keep the persistent stat boost in the Patron Pass, or make it cosmetic-only.

**D4. Should rewarded ads stay tied to habitat funding?**
- **Risky** (PP). Tying ads to habitat funding risks a guilt prompt.
- **Theme problem** (NC X4). The button intensifies *managed honeybee* output in the name of *native* bees, and ad-chaining is also the best speed-run exploit.
- **Keep it** (BA). Cause-linked ads are a proven differentiator. Keep the mechanic, state a fixed per-ad contribution, and never frame a declined ad as a loss to bees.
- **Decision escalated:** keep cause-linked ads with stricter copy, or decouple them.

---

## 3. Quick wins

1. **Delete the speed-run clause (line 12) and the leaderboard badge (line 90)** from the launch scope. This is one sentence, and BA counts findings from all six reviewers that it resolves or shrinks. *(BA Connection A, FL C1)*
2. **Change the batch modal to show a community-wide total and name the funding source** (for example, "Ad views and passes this week funded X seed packets"). That removes the false per-harvest claim and one backend feature. *(PP C1, FL X2)*
3. **Add a currency and naming table with sources and sinks.** Give Royal Jelly one meaning instead of three, and merge "Queen Markers" and "Royal DNA" into one name. State that the reset is player-triggered and optional, and remove the duplicated Real-World Impact section. *(QA F3/X6, PP F5/C3, SD X3, BA F3)*

---

## 4. Verdict

The document is not ready to drive production. It has a clear, appealing identity: a cozy, cause-driven idle game with a polished hands-on harvesting minigame. The board agrees that the minigame should be kept and given a lasting role, not cut (PP A1, FL C2, BA revised F5). But the core of the game is not designed yet:
- The prestige reset can never fire as written.
- The Phase 1→2 automation has no unlock rules.
- There is no income side to the economy.
- Biomes, Queen Markers and Flora Synergy have no numbers.
- The two features that carry the pitch are both unsound as written. The competitive endgame can be bought and cheated, and the conservation pillar makes claims the funding model doesn't support.

The cheapest, most broadly supported move is cutting the speed-run layer. The single change that matters most is writing the missing progression spec:
- how biomes map onto the phases and the reset
- what unlocks automation
- base income and what happens when the hive is full
- the Queen Marker formula

The hive-full behavior, the value of every paid perk, the length of the mid-game and the author's own AI pipeline all depend on that one missing spec.
