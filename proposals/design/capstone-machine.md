---
author: gerard
type: design
status: applied
description: Royal Honey Refinery capstone concept; adopted into the GDD Capstone section
---
# Capstone Concept Proposal: Royal Crystal Chamber
**Author:** Gerard, the Gameplay Architect
**Sources:** `GDD.md` (Phase 3, Tree C, Capstone, Land/Grid/Units, Leaderboards, Currencies, Story, Biomes), `proposals/balance/royal-crystal-balance.md` (Terry; option A, +10% additive per Crystal, pending approval).
**Status:** Proposal. No numbers are final; every tunable is listed in §5 for Terry.

---

## 1. Concept

### 1.1 Options

| | Option 1: Monument (one-time build) | Option 2: Royal Honey Refinery (build, then charge) | Option 3: Recipe Press (per-biome quotas) |
|---|---|---|---|
| **How it works** | Pay a very large money cost while the Synergy minimum is met. The Crystal forms instantly. | Build the Chamber for a moderate money cost. Then send part of your honey production into it. The Chamber refines honey into **Royal Honey**. Each biome's honey yields Royal Honey at that biome's *royal affinity* rate. When the Royal Honey meter is full, the Crystal forms. | Build the Chamber, then deliver fixed jar quotas of each biome's honey (e.g. X Wildflower Gold + Y Frosted Lavender). |
| **Consumes** | Money | Money (build) + diverted honey (charge) | Specific biome honeys |
| **Produces** | Crystal | Royal Honey (meter), then Crystal | Crystal |
| **Pushes to last biome?** | Weakly. Only through sale-value ratios between biomes. | Yes. The affinity curve can favour late biomes more than their market price does, as a separate knob. | Hard-forces it. |
| **First-biome speedrun?** | Yes | Yes. Meadow honey still charges the meter, just less efficiently. | **No.** Later-biome quotas block it. This contradicts the designer's intent. |
| **Post-launch biomes 3–4** | Cost must change or the new biomes become optional accelerators | Add one affinity value per biome. The target is set per content version. | Every new biome rewrites the recipe. |
| **Solo-dev cost** | Lowest (one model, a buy button) | Low (one model, one panel with a meter and a slider) | Medium (quota UI per biome) |
| **Feel** | A purchase, not a machine | A machine you feed and watch fill. Fits the Factorio half of the pitch. | A checklist |

### 1.2 Recommendation: Option 2, Royal Honey Refinery

The Chamber is a single large machine placed on the grid. Once built, it draws a player-set share of all honey production, from every biome, through the existing abstracted auto-transport trucks. It refines that honey into Royal Honey, shown as a glowing fill meter on the model. When the meter reaches `CAP_CHARGE_TARGET`, the Royal Crystal crystallizes, the run timer stops, and the run is complete.

- **Royal Honey from one jar** = jar sale value × `AFFINITY[biome]`. Affinity rises with each biome, so later honey is worth more to the Chamber than its market price alone would suggest. This is the main lever that makes the capstone "normally only affordable in the last biome".
- **Diversion slider** (`0–CAP_DIVERT_MAX`%): diverted honey is not sold. The player trades reinvestment growth against charge progress, which gives optimizers a real decision and speedrunners a skill axis. The panel shows an ETA at the current rate, so cozy players do not divert too early by accident.
- **Habitat lock:** the Chamber only refines while its host biome is at or above `CAP_SYNERGY_MIN` (§3.3). Below that, the meter pauses (it never drains). The cozy fail-state is "paused", never "lost".
- **New UI:** one Chamber panel (meter, slider, ETA, Synergy status), reached by tapping the machine or from the Upgrade Shop entry the GDD already lists. No new screen.
- **Art:** one machine model from an asset pack (brass/glass refinery kit), with a shader-driven fill level and a crystal mesh that grows in steps. Biome skins are optional and post-launch only.
- **Vertical slice:** the same system with only the Sunny Meadow affinity. Option 1 is the degenerate case of Option 2 (100% diversion, no build step), so the slice can fall back to it at no cost if needed.

---

## 2. Gating

### 2.1 What the cost is paid in

1. **Build cost (`CAP_BUILD_COST`):** in-game money. Moderate: it signals "the endgame is here" but is not the main gate.
2. **Charge cost (`CAP_CHARGE_TARGET`):** Royal Honey, made only from honey. Because it is denominated in value × affinity rather than in units of a specific honey, **every biome's honey counts**. That is what keeps the Meadow route legal.
3. **Habitat gate (`CAP_SYNERGY_MIN`):** must be held by the host biome for refining to run (§3.3).
4. **Availability (`CAP_UNLOCK_CONDITION`):** the Chamber appears in the shop only after the first automation purchase (Phase 2). This fits the GDD rule that Crystals cannot pre-buy the capstone. Phase 1 can never be skipped into it.

### 2.2 Why the normal route ends in the last biome

- The stacked production of all biomes feeds one meter, and the last biome's honey has the highest sale value and the highest affinity.
- With affinity rising faster than sale value, a jar of last-biome honey moves the meter several times further than a Meadow jar. In practice, players unlock the last biome, build out its top-tier units, and charge from there.
- The last biome is also where fresh land is cheapest relative to income, so the Chamber's footprint (§3.1) is easiest to absorb there.

### 2.3 The speedrun route (first biome)

1. Never invest in Alpine Valley. Unlocking it as a side effect of reaching Meadow Synergy is fine; it is simply ignored.
2. Rush the research nodes for top Meadow unit tiers (hive towers, vertical gardens) to maximise honey per tile.
3. Plant only enough flowers to hold `CAP_SYNERGY_MIN` in the Meadow under Hive Balance. Use Terry's Task 2 option (i) hive:plot loadout from Crystal starting upgrades.
4. Build the Chamber in the Meadow and run the diversion slider at maximum once compound growth flattens.
5. Skill expression: when to build, slider timing, footprint placement, and tight Hive Balance management.

It skips all biome-unlock setup (Terry's floor F_r < F). It pays for that with low-affinity honey (W_r > W).

### 2.4 Harder, equal or easier?

**Recommendation: harder at low Crystal tiers, converging towards rough parity at high tiers. It should never become clearly dominant.**

- At low tiers the normal route should be clearly faster, so new and cozy players are never told that skipping content is optimal.
- At high tiers the rush should be competitive. That gives the leaderboard two viable routes, which is healthier than one.
- Terry's §1.4 crossover M\* applies directly. `AFFINITY[1] / AFFINITY[last]` sets W_r/W, so the designer can tune M\* without touching market prices. Target: M\* ≥ M(60) under option A, as Terry recommends. Set `RUSH_GAP_TARGET` (§5) as the design goal and derive the affinities from it.
- The run should record the highest biome that contributed Royal Honey (§3.8), so a "Meadow-only" category can be added later without a save migration.

---

## 3. System interactions

### 3.1 Grid placement and space
- The Chamber occupies `CAP_FOOTPRINT` tiles in one biome (its **host biome**). It is placed in build mode like any unit, with only one per world.
- The footprint competes with production per tile, which is the grid's core goal. That cost is felt most in the rush route (a packed Meadow) and least in the normal route.
- It can be moved freely until refining has started. After that, moving it pauses the meter but does not reset it, to avoid feel-bad.
- It is not a hive or a flower: no honey output, no flower demand, and no effect on Hive Balance.

### 3.2 Stacking biomes
- All biomes feed the Chamber through the existing abstracted trucks, with no new logistics.
- Earlier biomes keep producing at full rate (GDD), so stacking still matters: Meadow honey is the base of the meter and the last biome is the accelerant.
- The diversion slider applies globally. A per-biome slider is a possible post-launch QoL feature, not needed at launch.

### 3.3 Habitat Synergy minimum
- **Which habitat counts: the host biome only.** The Chamber's biome must hold Synergy ≥ `CAP_SYNERGY_MIN` for refining to run.
- This keeps the rule legible ("look after the biome your Chamber is in"). Both routes must restore habitat, which keeps the GDD's "every run includes restoration".
- `CAP_SYNERGY_MIN` should be **above** that biome's unlock threshold. Otherwise the rush has no restoration cost beyond what it already pays.
- **Dependency:** the GDD currently treats Synergy as a single unlock threshold. A "minimum level" needs Synergy to be a graded value per biome (e.g. a flower-to-bee ratio or a Habitat Health score). Terry and Patricia need that definition.

### 3.4 Hive Balance
- The habitat lock (§1.2) turns Hive Balance into the Chamber's live constraint. Overpacking hives in the host biome lowers Habitat Health, Synergy drops below the minimum, and the meter pauses.
- This interacts directly with Terry's Task 2 decision: under option (i), starting hives obey Hive Balance and the lock holds. Under option (ii), neutral hives would let the rush bypass it, which is one more reason to choose (i).

### 3.5 Research and unit tiers
- The Chamber has no tiers and no upgrade tree, which keeps scope small.
- Research shapes it indirectly: genetics multiply honey (and so charge rate), and unit tiers raise honey per tile (the rush's main lever).
- Optional: gate the Chamber behind one research node (`CAP_RESEARCH_GATE`) if the designer wants it to read as a tech goal. The default is no gate, with availability after first automation.
- Research does not carry over, so every run rebuilds the path to the Chamber. That is intended.

### 3.6 Royal Jelly time skips and speed-ups
- No dedicated "skip refining" button. Jelly speed-ups and time skips already advance honey production, and diverted honey advances the meter. So Jelly speeds the Chamber naturally, with no new rule.
- Leaderboard tagging is unchanged: any Jelly time skip tags the run "time-skipped", and purchased Jelly tags it as boosted.
- Rewarded-ad 2× production also speeds charging and stays on the unboosted board, as the GDD already defines.
- Offline: charging continues offline up to the offline cap (4/12/24 h by pass). Pass-based offline length is already part of the booster brackets.

### 3.7 Leaderboards and run time
- **Wording change needed:** the GDD defines run time as "start of a run to buying the capstone upgrade". Under this concept the run ends when **the Crystal forms** (the meter is full), not when the Chamber is bought. Building the Chamber is not the finish line.
- Server-side time validation must cover the moment the Crystal forms, since offline charging can complete the run while the app is closed.
- One Crystal per world. Once the Crystal has formed, the Chamber goes dormant (§3.10).

### 3.8 Post-launch biomes 3–4 (stored run times)
- Adding Enchanted Grove and Cloud Gardens adds `AFFINITY[3]` and `AFFINITY[4]` and changes which biome is last. With a fixed charge target, new biomes would shorten runs, and with the target raised, they would lengthen the Meadow rush.
- **Recommendation:** store all capstone parameters in a table keyed by content version (`CAP_PARAMS[content_version]`). Each run saves its content version (the GDD already requires this) plus its `CAP_CHARGE_TARGET`. Boards never compare runs across content versions, so old run times stay valid and are archived rather than invalidated.
- Also record in the run the highest biome that contributed Royal Honey. This is cheap, fits the existing Run Tracking list, and enables a future Meadow-only category.

### 3.9 Royal Crystal boost and the starting-upgrade whitelist
- The Chamber's charge rate scales with Terry's M(n), so higher-n runs end sooner on both routes. That is exactly the dynamic Terry's crossover analysis models.
- The Chamber itself must never appear on the whitelist (GDD rule). Whitelist items that lower setup time (starting land, hives, plots) favour the rush, as Terry notes.

### 3.10 Reset story
- **Fiction:** the Chamber refines the world's best honey into Royal Honey. The Royal Crystal it forms is what a new queen needs to lead a swarm. When the Crystal forms, the hive raises a new queen, and on reset **the swarm splits and carries the Crystal to restore a new pocket world**. The old world stays restored and kept as a save, as in the GDD.
- **In the kept world:** the Chamber stays as a decorative monument, dormant, with an empty crystal socket. It cannot be rebuilt or recharged. This blocks crystal farming in old saves and is consistent with "nothing transfers between worlds".
- The reset stays optional: after the Crystal forms, the player may keep playing the world. The Crystal is credited to the persistent Crystal count when the swarm splits (or at formation; see open question 5).
- Hook for William: the guide queen character can deliver the Crystal moment and the split.

---

## 4. Impact table

| System | Effect | Risk |
|---|---|---|
| Grid & space | Multi-tile footprint competes with production per tile | Footprint too large makes the Meadow rush unviable; too small makes the footprint meaningless |
| Biome stacking | All biomes feed one meter; later honey charges more via affinity | If affinity is too steep, earlier biomes feel pointless late in the run |
| Habitat Synergy | Host biome must hold `CAP_SYNERGY_MIN`, or refining pauses | Needs Synergy redefined as a graded value (currently a binary threshold) |
| Hive Balance | Becomes the live constraint on the host biome | Paused meters with no clear reason feel bad; the panel must show *why* it paused |
| Tree A/B (bees, tools) | Indirect: more honey means faster charge | None new |
| Tree C (habitat) | Gains an endgame purpose beyond biome unlocks | None; this supports the restoration pillar |
| Automation / Phase 2 | Chamber unlocks after first automation | Low |
| Research & unit tiers | Top tiers are the rush's main lever; optional research gate | Rush players skip all non-Meadow research, which is fine but should be watched |
| Royal Jelly | Speeds charging through production, with no new skip button | Time-skipped board spread is already flagged by Terry; no new risk |
| Rewarded ads / offline / passes | Charging continues offline within the cap; 2× applies | Runs completing while offline need server validation at Crystal formation |
| Royal Crystal boost (Terry A) | M(n) compresses both routes; affinity tunes the rush crossover | If affinities are tuned before final run lengths are known, M\* moves |
| Starting-upgrade whitelist | Unchanged; Chamber excluded | Neutral-hive option (ii) would bypass the habitat lock |
| Leaderboards / run time | End point moves to Crystal formation; record the highest contributing biome | GDD wording must be updated; old local personal bests need the same definition |
| Content versions (biomes 3–4) | Capstone parameters keyed by content version | Without this, adding biomes silently shortens or lengthens runs |
| Reset story / worlds | Chamber becomes a dormant monument in kept worlds | If it is not made dormant, old worlds become Crystal farms |
| UI | One panel: meter, slider, ETA, Synergy status | Low |
| Art / performance | One asset-pack model plus a fill shader | Low; one object per world |

---

## 5. Parameters for Terry

| Variable | Controls |
|---|---|
| `CAP_BUILD_COST` | Money cost to place the Chamber. Sets how early players commit to building it. |
| `CAP_CHARGE_TARGET[content_version]` | Royal Honey needed for the Crystal: the main "very high cost". |
| `AFFINITY[biome]` | Royal Honey per $1 of that biome's honey value. Its slope sets how strongly the normal route ends in the last biome, and the rush penalty W_r/W. |
| `CAP_SYNERGY_MIN[biome]` | Graded Synergy level the host biome must hold for refining to run. Per biome, so a Meadow-hosted Chamber has a defined bar. |
| `CAP_DIVERT_MAX` | Maximum share of honey production that can be diverted (100% or lower, to protect the reinvestment loop). |
| `CAP_FOOTPRINT` | Tiles the Chamber occupies. |
| `CAP_UNLOCK_CONDITION` | When the Chamber appears in the shop (default: first automation purchase). |
| `CAP_RESEARCH_GATE` (optional) | Research node cost that gates the Chamber, if used. |
| `CAP_THROUGHPUT_MAX` (optional) | Royal Honey per second cap. A deliberate non-scaling floor; leave unset unless Terry's floor model needs one. |
| `RUSH_GAP_TARGET` | Design target: the Meadow-rush run time relative to the normal route per Crystal tier. Used to derive the `AFFINITY` values and check M\* ≥ M(60). |

---

## 6. Open questions for the designer

1. **Run end point:** approve changing run time from "buying the capstone" to "the Royal Crystal forms" (end of charging)?
2. **Biomes 3–4:** should the charge target be redefined per content version (recommended), or stay fixed so that new biomes act as accelerators?
3. **Meadow-only category:** should first-biome runs eventually get their own leaderboard category, or only compete on the main board? (The data is recorded either way.)
4. **Synergy scope:** host biome only (recommended), or must every unlocked biome also hold its threshold while charging?
5. **Crystal timing and kept worlds:** is the Crystal credited when it forms or when the swarm splits? Confirm that the Chamber in a kept world is a dormant monument, and clarify the GDD line "nothing transfers between worlds" against Crystals carrying over resets.
