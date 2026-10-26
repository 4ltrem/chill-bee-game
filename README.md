# chill-bee-game

Multi-Agent AI for Game Development Assignment repo.

**Chill Bee Game** is a cozy, mobile-first beekeeping idle game. You start by harvesting honey by hand, automate the farm step by step, and then reset it for permanent bonuses. A share of the game's revenue funds real-world bee conservation. The working titles are *Digibees*, *My Bee Hotel* and *Pocket Hive*.

The full design is in [GDD.md](GDD.md). The document is a **first draft**: the systems are mostly defined, but most of the numbers are not yet (see [Outstanding TBDs](#outstanding-tbds)).

---

## Game Overview

### Pitch
The game is a cross between *Egg, Inc.* and *Factorio*. The player discovers a tiny magical pocket world that needs a beekeeper to restore it. You pan and zoom around a low-poly diorama farm as it grows, and upgrade three things: the bees, the hive and tools, and the native habitat. The habitat tree is measured in biodiversity rather than honey: native wild bees pollinate, boost production, and fill a Bee Journal, while too many managed hives without enough habitat lowers Habitat Health.

### Core Loop
**Bees forage → hive fills → uncap & extract → sell honey → reinvest**

| Phase | What the player does |
|---|---|
| **1. Manual** | Harvest by hand in a tactile two-stage minigame: swipe to uncap the comb, then crank the centrifuge. A small free overflow buffer keeps production going while the hive is full. |
| **2. Automation** | Buy automation upgrades (uncapping hubs, electric centrifuges, transport trucks) to take over the manual work. |
| **Expansion** | Buy land and place hive and flower units on each biome's grid. Biomes can grow indefinitely, and higher-tier units cost more but fit more honey production into less space. |
| **3. Optimization** | Build the capstone Royal Honey Refinery and charge it with honey from every biome to earn a **Royal Crystal**. Then optionally reset: the swarm splits and leaves to restore a new pocket world. Crystals carry over, and each one gives a stacking production boost plus one starting upgrade for future runs. |

Within a run, the player moves through four biomes in order: Sunny Meadow → Alpine Valley → Enchanted Grove → Cloud Gardens. Reaching a biome's Habitat Synergy threshold (enough flowers for its bees) unlocks the next one, and earlier biomes keep producing. The capstone is normally reached in the last biome, but can be speedrun from the first. Each finished world is kept as its own save that can be loaded and played.

### Currencies
- **In-game money:** earned by selling honey; spent on land, units, upgrades and research; resets each run.
- **Royal Jelly (premium):** earned slowly through play and ads, or bought; spent on time skips; kept across resets.
- **Royal Crystal (prestige):** earned by charging the Refinery; each gives +10% production (additive) and one starting upgrade; account-wide.

### Leaderboards (post-launch, opt-in)
The game is cozy by default; players who want to compete opt into speed-run boards. These boards measure wall-clock time from the start of a run until the Royal Crystal forms, validated on the server. Players only race others with the same set of paid boosters and a similar Royal Crystal count. Watching free rewarded ads keeps a player on the unboosted board, but spending Royal Jelly on time skips puts the run in its own bracket.

### Real-World Impact
A fixed percentage of each revenue stream funds bee conservation (native bee habitat and managed hives), starting with Canadian partners. The revenue streams are rewarded ads, the Impact Pass and the Patron Pass.

### Audience & Scope
- **Audience:** adults and teens who play cozy games, with family-friendly content. An age gate turns on a kid mode for under-13s: no personalized ads, a parental gate on purchases, and no public username.
- **Team:** a solo developer directing AI agents in Claude Code. The agent roles are in [_meta/team.md](_meta/team.md).
- **Engine:** Godot (GDScript). Art comes from purchased low-poly asset packs.
- **Launch platforms:** iOS and Android, in English and French.
- **Timeline:** milestone-based, with no fixed date. The first playable is one full rough run in Sunny Meadow.
- **Launch scope:** Sunny Meadow and Alpine Valley, rewarded ads and the Impact Pass, local personal-best times.
- **Post-launch:** biomes 3–4, the Patron Pass, online leaderboards, the live Impact Dashboard, and possibly Switch and PC/Mac.

---

## Repository Contents

| Path | Contents |
|---|---|
| [AGENTS.md](AGENTS.md) | Entry file for AI agents: where everything lives and where to go for each task. [CONTEXT.md](CONTEXT.md) describes the design loop (request, proposal, decision, apply). |
| [GDD.md](GDD.md) | Game design document |
| [gdd-review/reviews/](gdd-review/reviews/) | A multi-agent design review of the first draft. Six reviewer agents each reviewed it independently, then cross-examined each other, and a moderator wrote a synthesis ([SYNTHESIS.md](gdd-review/reviews/SYNTHESIS.md)). It was run with [gdd-review-kit](https://github.com/GixGosu/gdd-review-kit). |
| [gdd-review/gdd.txt](gdd-review/gdd.txt) | Snapshot of the GDD as it was reviewed. Many review findings have since been addressed in `GDD.md`. |
| [proposals/design/](proposals/design/) | Feature design proposals, e.g. the capstone [Royal Honey Refinery](proposals/design/capstone-machine.md) (Gerard). |
| [proposals/balance/](proposals/balance/) | Balance reports, e.g. [Royal Crystal balance](proposals/balance/royal-crystal-balance.md) (Terry). |
| [_meta/agent-runs.md](_meta/agent-runs.md) | Token, tool-call and duration log of every agent run. |
| [.claude/agents/](.claude/agents/) | Runnable Claude Code agent definitions, starting with Connie, the Compliance Officer. |
| [gdd-review-v2/](gdd-review-v2/) | Second review, of the GDD at commit `8ddb97a` after the first round of fixes and peer feedback. Its [SYNTHESIS.md](gdd-review-v2/reviews/SYNTHESIS.md) compares the results with the first review. |

---

## Outstanding TBDs

### Economy & Numbers
- [ ] Income side of the economy: base jar price, bee fill rate, harvest cycle time
- [ ] Habitat Health values (multipliers, costs, levels) and how much hive count lowers it
- [ ] Honey sale value for each biome
- [ ] Automation upgrade costs
- [ ] Overflow Storage capacity and costs (free buffer is 1 extra frame)
- [ ] Land expansion costs
- [ ] Hive and flower unit tiers: costs, production and space per tier
- [ ] Research values (genetics multipliers and unit-tier unlocks)
- [ ] Tool-upgrade flat bonuses after automation
- [ ] Auto-Sell discount and costs
- [ ] Royal Jelly prices, time-skip costs, and Patron daily stipend amount
- [ ] Impact Pass and Patron Pass prices

### Progression
- [ ] Refinery parameters (build cost, charge target, biome affinities, Habitat Synergy minimum): Terry
- [ ] Habitat Synergy threshold for each biome
- [ ] Royal Crystal starting-upgrade whitelist
- [ ] Max levels for the starting-hives and starting-wildflower-plot Crystal options
- [ ] Native bee species: provisional effects set (Terry); Glowcap digger effect, real values and run length with native bees still to confirm
- [ ] Flower list for the habitat tree

### Leaderboards
- [ ] Royal Crystal tier ranges (e.g. 0, 1–5, 6–20, 21–50, 51–100, 101+)

### Real-World Impact
- [ ] Fixed donation percentage for each revenue stream (ads, Impact Pass, Patron Pass)
- [ ] Confirmed agreements with conservation partners

### Story & Characters
- [ ] Final game title
- [ ] Guide character's name and personality

### Production
- [ ] Milestone dates
- [ ] Daily token budget: first calibration gives ~2.0M tokens/day (provisional; refine with a larger task, see [_meta/agent-runs.md](_meta/agent-runs.md))
- [ ] Test device models and visual bee cap
- [ ] Backend provider (managed game-backend service)
