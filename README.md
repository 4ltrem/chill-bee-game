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
| **1. Manual** | Harvest by hand in a tactile two-stage minigame: swipe to uncap the comb, then crank the centrifuge. Production pauses when the hive is full. |
| **2. Automation** | Buy automation upgrades (uncapping hubs, electric centrifuges, transport trucks) to take over the manual work. |
| **3. Optimization** | Buy the capstone upgrade to earn a **Royal Crystal**, then optionally reset the farm. Crystals carry over, and each one gives a stacking production boost plus one starting upgrade for future runs. |

Within a run, the player moves through four biomes in order: Sunny Meadow → Alpine Valley → Enchanted Grove → Cloud Gardens. A reset returns them to Sunny Meadow.

### Currencies
- **In-game money:** earned by selling honey; spent on upgrades and research; resets each run.
- **Royal Jelly (premium):** earned slowly through play and ads, or bought; spent on time skips; kept across resets.
- **Royal Crystal (prestige):** earned from the capstone upgrade; gives permanent stacking boosts.

### Leaderboards (post-launch)
These are speed-run boards that measure wall-clock time from the start of a run to the capstone, validated on the server. Players only race others with the same set of paid boosters and a similar Royal Crystal count. Watching free rewarded ads keeps a player on the unboosted board.

### Real-World Impact
A fixed percentage of each revenue stream funds bee conservation (native bee habitat and managed hives), starting with Canadian partners. The revenue streams are rewarded ads, the Impact Pass and the Patron Pass.

### Audience & Scope
- **Audience:** families and all ages. An age gate turns on a kid mode for under-13s: no personalized ads, a parental gate on purchases, and no public username.
- **Team:** a solo developer directing AI agents in Claude Code. The agent roles are in the GDD.
- **Engine:** Godot (GDScript).
- **Launch platforms:** iOS and Android, in English and French.
- **Timeline:** launch within 6 months.
- **Launch scope:** Sunny Meadow and Alpine Valley, rewarded ads and the Impact Pass, local personal-best times.
- **Post-launch:** biomes 3–4, the Patron Pass, online leaderboards, the live Impact Dashboard, and possibly Switch and PC/Mac.

---

## Repository Contents

| Path | Contents |
|---|---|
| [GDD.md](GDD.md) | Game design document |
| [gdd-review/reviews/](gdd-review/reviews/) | A multi-agent design review of the first draft. Six reviewer agents each reviewed it independently, then cross-examined each other, and a moderator wrote a synthesis ([SYNTHESIS.md](gdd-review/reviews/SYNTHESIS.md)). It was run with [gdd-review-kit](https://github.com/GixGosu/gdd-review-kit). |
| [gdd-review/gdd.txt](gdd-review/gdd.txt) | Snapshot of the GDD as it was reviewed. Many review findings have since been addressed in `GDD.md`. |
| [gdd-review-v2/](gdd-review-v2/) | Second review, of the GDD at commit `8ddb97a` after the first round of fixes and peer feedback. Its [SYNTHESIS.md](gdd-review-v2/reviews/SYNTHESIS.md) compares the results with the first review. |

---

## Outstanding TBDs

### Economy & Numbers
- [ ] Income side of the economy: base jar price, bee fill rate, harvest cycle time
- [ ] Royal Crystal production boost (%)
- [ ] Habitat Health values (multipliers, costs, levels) and how much hive count lowers it
- [ ] Honey sale value for each biome
- [ ] Automation upgrade costs
- [ ] Overflow Storage capacity and costs
- [ ] Auto-Sell discount and costs
- [ ] Free-player offline earnings cap (hours)
- [ ] Royal Jelly prices, time-skip costs, and Patron daily stipend amount
- [ ] Impact Pass and Patron Pass prices

### Progression
- [ ] Which upgrades must be maxed, and the Habitat Health or native-species threshold, before the capstone unlocks
- [ ] Capstone's final name (working name: Royal Crystal Chamber)
- [ ] Biome unlock milestones
- [ ] Native bee species for each biome and their effects
- [ ] Flower list for the habitat tree
- [ ] Research trees: unlock conditions and how they differ from Trees A–C

### Leaderboards
- [ ] Royal Crystal tier ranges (e.g. 0, 1–5, 6–20, 21+)

### Real-World Impact
- [ ] Fixed donation percentage for each revenue stream (ads, Impact Pass, Patron Pass)
- [ ] Confirmed agreements with conservation partners

### Story & Characters
- [ ] Final game title
- [ ] Guide character's name and personality

### Production
- [ ] Launch date
- [ ] Backend provider (managed game-backend service)
