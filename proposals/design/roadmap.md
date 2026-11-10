---
author: gerard
type: design
status: proposed
description: Roadmap - every GDD feature not yet in a milestone placed into dependency-layered milestones (0.4-0.9 vertical slice, 0.10+ alpha, post-launch), with blocking TBDs, compliance flags and rough cost
---
# Roadmap: placing the rest of the GDD
**Sources:** `GDD.md` (all sections, including the Glossary), `MILESTONES.md` (M0-M7, Open), `proposals/design/ui-screens.md`, `UI_DESIGN.md`, `proposals/design/capstone-machine.md` (§6 open questions), `README.md` (Outstanding TBDs), `game/specs/` (descriptions; `0.2-first-automation.md` and `flower-patch-b.md` read for what is already built), `_meta/agent-runs.md` and `_meta/agent-runs.csv` (goal-agent rows, for cost).
**Trigger:** designer, 2026-11-09 (MILESTONES M6): "Placement of the rest of the GDD: Gerard's roadmap proposal (`proposals/design/roadmap.md`)". Place every GDD feature not yet in a milestone, one row per feature, grouped by dependency layer; hold features with a blocking TBD or an unreviewed compliance flag; nothing before 2026-11-24 beyond what MILESTONES already has.

---

## 1. Assumptions

- **Already placed, not repeated below:** the manual harvest (M1, 0.1.x), Worker Swarm Count (0.1 quick-buy), Flight Endurance, Heated Uncapping Fork (reach only), Centrifuge Gearing, Faster Delivery, Auto-Sell, the Phase 2 flag, one Bee Journal entry EN/FR (M4, 0.2.x), the first UI pass for those features and the first-time hint (M5, 0.3.0). Flower patches exist in the scene only as decoration (`flower-patch-b.md`), so Tree C's flower patches are still unplaced.
- **UI ships with its feature** (`ui-screens.md`, `UI_DESIGN.md`): each row includes its sheet or icon from `ui-screens.md` §2; there are no separate UI rows.
- **Two kinds of TBD.** A *design* TBD (a rule or content nobody has defined) holds the feature in "Needs a decision first" (§4). A *number-only* TBD (a cost, capacity, threshold) does not hold the milestone: it needs a Terry run before the spec is approved, and the spec uses slow placeholders until then (as 0.2 did). This split is decision 2 below; if the designer rejects it, every row with a number-only TBD moves to the held list.
- **No dates.** Every milestone below starts after 2026-11-24 (the final course build, 0.3.0). Order only.
- **Implied rows.** Two rows are not named GDD features but are needed by several that are: save and load (offline earnings §6, Worlds §7, run tracking §5) and an Android export (the vertical slice is "mobile only"). Patricia should check `game/` for any existing save code before the 0.4 spec.
- **Rough cost** is build cost in goal-agent runs (Patricia, Bob and Quinn turns run by `goal_agent.py`). How it was derived: the `agent-runs.md` Goal agent table averages **~238k tokens total processed per run** (130 runs). In `agent-runs.csv`, the 0.2 build (about 10 spec changes, 21 checklist items) took **35** goal-agent runs (~8.3M tokens); 0.1.4 (layout and UI placement) took **95** (~23M). So:
  - **S** = up to ~10 runs (≤ ~2.4M): a shop row or one rule on existing models.
  - **M** = ~10-35 runs (~2.4-8.3M): a mechanic with one new model or one new screen; the whole 0.2 build is the top of M.
  - **L** = ~35-100 runs (~8-24M): a new system with several models and a screen; 0.1.4 is the top of L.
  - Not included: the orchestrator (median ~760k per agent run), Milo's model sessions before a build, and design-side runs (Terry ~127k final, William ~125k-350k, Connie est. ~42-90k). These are rough, from two builds only.

## 2. Options and recommendation

| Option | Shape | For | Against |
|---|---|---|---|
| **A. Dependency layers, one theme per 0.x (recommended)** | 0.4 automation, 0.5 grid, 0.6 habitat, 0.7 research, 0.8 capstone, 0.9 reset = vertical slice; alpha 0.10+ | follows the GDD phase order exactly; each build adds one system on a working one; every milestone is playable; the goal agent gets small, ordered specs | the first full run (capstone and reset) is only playable at 0.9 |
| B. Thin slice first | 0.4 = a minimal grid + a placeholder Refinery + reset; 0.5-0.9 deepen each layer | a full run is testable early, so Terry measures the real economy sooner | builds throwaway versions of the Refinery and reset; many reworks for a solo developer; harder to play-test any one system |
| C. Habitat first | Tree C (flowers, Habitat Health, native bees) in 0.4, then automation and grid | the conservation pillar shows earlier | Habitat Health needs several hives and flowers on a grid (Hive Balance), so it would be a stub; breaks the GDD phase order |

**Recommendation: A.** It is the grouping rule as asked, and it builds on what 0.2 already has (the post-automation bonuses are coded behind Dev toggles and need only the motor and auto-scraper). B's advantage, measuring the real economy early, is kept by having Terry re-derive the Refinery values from 0.4-0.7 play data before the 0.8 spec.

### 2.1 Roadmap table

Compliance: kids, ads, purchases, donations, data, backend → needs Connie. "–" = none found. Milestone "held → 0.x" = the slot it takes once its blocker is cleared (see §4).

**Layer 1: full automation (0.4)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 1 | Long Fork (one-sweep uncapping) | §2 Stage 1; §3 Tree B | Heated Fork (0.2) | none (cost "provisional") | – | S | 0.4 |
| 2 | Centrifuge motor | §1 Phase 2; §3 Automation | Centrifuge Gearing (0.2) | "its zoom screen opens from upgrade mode instead of from a harvest icon (UI TBD, with the rest of the UI)"; answered if `ui-screens.md` decision 4 (Tools icon, Build › Open) is accepted | – | M | 0.4 |
| 3 | Auto-scraper (Long Fork on a gantry) | §3 Automation | Long Fork | same UI TBD as row 2 | – | M | 0.4 |
| 4 | End of the capacity pause; post-automation tool bonuses live | §2 intro; §3 Tool Upgrades After Automation | motor, auto-scraper | none (values "provisional"; already coded in 0.2 behind Dev toggles) | – | S | 0.4 |
| 5 | Deep Frame | §3 Tree B | none | none | – | M (frames twice as long change the zoom framing) | 0.4 |
| 6 | Artisanal Branding (and the "artisanal quality" line in the sale summary) | §3 Tree B; §2 Stage 3 | none | none | – | S | 0.4 |
| 7 | Spigot flow-rate upgrades | §3 Tool Upgrades After Automation | none | number-only: "bottling speed will come from spigot flow-rate upgrades (TBD, after 0.2)" | – | S | moved to 0.2.1 (designer, 2026-11-09) |
| 8 | Overflow Storage | §2; §3 Tree B | free overflow buffer (§2) | number-only: "(capacity and costs TBD)" | – | S | 0.4 (after Terry) |
| 9 | Save and load; offline earnings at the free 4 h cap (device clock); Welcome back sheet | §6; `ui-screens.md` board 4 | none (implied row) | none for the free cap (server time is row 40) | data (local save only; Connie when it syncs, row 40) | M | 0.4 |
| 10 | Heated Fork clean-cut batch bonus | §3 Tree B | Heated Fork | design: "adds up to +5% batch bonus for clean cuts"; README: "what counts as a clean cut" | – | S | held → 0.4 or later |

**Layer 2: grid (0.5)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 11 | Build mode: place and move units on the grid; pan and zoom over a larger farm | §4 Grid Placement; §9 Farm View; board 6 | 0.4 automation (see decision 1) | design gap: the GDD's harvest (§2) is for one hive; nothing says how a second hive is harvested in Phase 1 | – | L | held → 0.5 (decision 1) |
| 12 | Land expansion | §4 Indefinite Expansion | Build mode | number-only: "(cost growth TBD)" | – | M | 0.5 |
| 13 | Hive and flower units, first tier (Langstroth hive, wild patch): buy more, place | §4 Hive & Flower Units | Build mode | number-only: README "costs, production and space per tier" | – | M | 0.5 |
| 14 | Jar crate tiers 1-3 | §4 Jar Crate Tiers | Build mode | number-only: "(values TBD)" | – | M (two new crate sizes) | 0.5 |
| 15 | Bee rendering plan: capped crowd, `MultiMeshInstance3D`, swarm counter, denser trails | Technical Constraints | rows 11, 13 | "(visual cap TBD after profiling)": set by profiling, not a spec blocker | – | M | 0.5 |
| 16 | Android export for phone play-tests (implied: the vertical slice is "mobile only") | Audience (Vertical Slice); Technical Constraints | none | "Test Devices … (exact models TBD)": only for profiling | – for sideloaded tests; store release needs Connie | S | 0.5 |

**Layer 3: habitat, Sunny Meadow only (0.6)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 17 | Tree C flower patches: plant and upgrade, raising Habitat Health | §3 Tree C Flower Patches | flower units (13) | number-only: "(values TBD)"; design gap: §1 and the Executive Summary say "plant and water flowers", but Synergy has "no growth timers" and watering is defined nowhere; flower names "(to be fact-checked)" (William, conservation partner; placeholders until then) | – | M | held → 0.6 (decision 4) |
| 18 | Habitat Health and Hive Balance | §3 Hive Balance; Glossary Habitat | flowers (17), several hives (13) | number-only: README "Habitat Health values … and how much hive count lowers it" | – | M | 0.6 |
| 19 | Habitat Synergy level (Meadow) | §3 Habitat Synergy Level | Habitat Health | number-only: README "Habitat Synergy threshold for each biome" | – | S | 0.6 |
| 20 | Native bees: per-biome capped bonus, abundance bonus; Meadow species arrive, leave, return (sweat bees, leafcutter bees, bumble bee visitor) | §3 Native Bees, Native Bee Species | Habitat Health, flower types | values provisional (`native-species-balance.md`); "Real-species assignments must be fact-checked by William and a conservation partner" blocks launch, not the build | – | M (bee variants) | 0.6 |
| 21 | Bee Journal: every Meadow species, found / "?", sources list in-game | §3 Bee Journal; board 9 | native bees (20); 0.2 Journal pipeline | README "Bee Journal sources list in-game"; partner review before launch | – | S | 0.6 |
| 22 | Habitat sheet (board 7, habitat half) | §9; `ui-screens.md` board 7 | rows 17-20 | `ui-screens.md` decision 5: Habitat and Refinery on one sheet or two | – | S | 0.6 |

**Layer 4: research (0.7)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 23 | Research: bee and flower genetics (production multipliers); research tab in the Shop | §1 Phase 3; §9 Upgrade Shop | units (13), flowers (17) | number-only: README "Research values (genetics multipliers and unit-tier unlocks)" | – | M | 0.7 |
| 24 | Higher unit tiers unlocked by research (stacked hive, hive tower; raised bed, vertical garden); upgrade in place | §4 Hive & Flower Units, Unlocking Tiers | research (23), units (13) | number-only (as row 13) | – | L (four new models) | 0.7 |

**Layer 5: capstone (0.8)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 25 | Royal Honey Refinery: build and place, divert slider, charge, Meadow affinity, habitat lock, throughput cap, Refinery research ladder; Refinery half of board 7 | §3 Capstone; Glossary Refinery | Build mode (11), Habitat Synergy (19), research (23) | `CAP_UNLOCK_CONDITION` is undefined; "Charge phase: How much of a run is spent charging the Refinery is TBD"; values "must be re-derived once the real economy and the per-biome setup time are measured"; ladder "must be re-checked for +15%" (all Terry, using 0.4-0.7 data) | – | L | held → 0.8 (`CAP_UNLOCK_CONDITION`, charge share) |
| 26 | Royal Crystal forms; run time recorded | §3 Royal Crystal; §5 Run Time | Refinery | `capstone-machine.md` §6 Q5: "is the Crystal credited when it forms or when the swarm splits?" | – | S | held → 0.8 (Q5) |

**Layer 6: reset = vertical slice complete (0.9)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 27 | Reset (Swarm Splitting): new pocket world, +15% per Crystal, Royal Crystal sheet (board 8) | §1 Phase 3; §7 Reset Story | Crystal (26), save (9) | none for the reset itself | – | L | 0.9 |
| 28 | Starting upgrades: whitelist, starting hives, starting wildflower plot, live Habitat preview | §1 Phase 3 | reset (27), Habitat Health (18) | design: README "Royal Crystal starting-upgrade whitelist"; "both options have a max level (TBD)" | – | M | held → 0.9 (else 0.10) |
| 29 | Worlds: kept worlds, load and switch, dormant Refinery monument | §7 Reset Story; §9 Worlds; board 10 | reset (27), save (9) | none | data (local saves only) | M | 0.9 |
| 30 | Local personal-best run times; run-tracking save fields (booster set, Jelly sources, content version, highest biome) | §5 Run Tracking; §3 Content versions | Crystal (26), save (9) | none for local times (Crystal tiers "exact tiers TBD" matter only online) | – (local only) | S | 0.9 |

**Layer 7: launch content (alpha, 0.10-0.12)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 31 | Alpine Valley: unlock by Synergy threshold, biome switch, Frosted Fireweed Honey, Alpine affinity, chalet hives (biome units), stacking | Progression Tiers & Biomes; §3; §4 Biome Units | vertical slice (0.9) | design: "Fireweed and other alpine wildflowers (TBD)"; number-only: honey "(values TBD)", must stay below 1.92× Meadow | – | L | held → 0.10 |
| 32 | Alpine species (bumble, mason, mining bees) and their Journal entries | §3 Native Bee Species, Bee Journal | Alpine (31) | "Attracted by: Fireweed, alpine wildflowers (TBD)"; fact-check by William and a conservation partner; README "Confirmed agreements with conservation partners" | – | M (+ William ~350k per real Journal) | held → 0.10 |
| 33 | Pests and wild nectar drops (active play only) | §1 Pests & Wild Nectar Drops | none | number-only: the "small reward" is unsized | – | M | 0.11 |
| 34 | Audio: uncapping pops, ukulele and acoustic music | Aesthetic & Tone; §2 Stage 1 | none | none (Andrew's licence-checked picks) | – | M | 0.11 |
| 35 | Settings and accessibility: haptics, sound and music toggles, colour-blind shapes, text size, one-thumb reach, language (board 13) | §8; §9 Settings | audio (34) | none | – | M | 0.11 |
| 36 | French localization of every string | Audience (Languages); GDD timeline milestone 3 | every text-bearing feature | none | – | M | 0.11 |
| 37 | Onboarding guide (first session) | §7 | harvest, Shop, Settings | "a playtest chooses one" of six guides; README "Guide character's name and personality" | – (Connie only if the age gate shares its first screen, row 39) | M | held → 0.11 |
| 38 | Royal Jelly earned through play; time skips and speed-ups; time-skipped tag | §6; §5 Royal Jelly | run tracking (30) | number-only: README "Royal Jelly prices, time-skip costs" | purchases (a premium currency) | M | held → 0.12 |

**Layer 8: monetization, backend, kid mode (alpha, after Connie)**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 39 | Age gate and kid mode (first-launch board 14) | Child Safety | none | none in the GDD; Connie's review | kids, data | M | held → 0.13 |
| 40 | Backend: purchase receipts, cloud saves, server time | Audience (Backend) | save (9) | "A managed game-backend service (provider TBD)" | backend, data | L | held → 0.13 |
| 41 | Store and parental gate: Jelly packs, passes (board 12) | §9 Store; Child Safety | Jelly (38), backend (40), age gate (39) | prices TBD; `ui-screens.md` decision 6: parental gate not drawn | purchases, kids | M | held → 0.14 |
| 42 | Rewarded ads: optional 2× boost tied to habitat funding | Monetization (Rewarded Ads) | age gate (39), Welcome back (9) | "a fixed percentage of ad revenue donated (TBD)"; ad boost length unset (`ui-screens.md` decision 7) | ads, kids, donations, data | M | held → 0.14 |
| 43 | Impact Pass: auto-tap helpers, 12 h offline cap | Monetization (Impact Pass); §6 | Store (41), backend (40) | price TBD; "fixed percentage of proceeds … (TBD)"; "auto-tap helpers" undefined | purchases, donations | M | held → 0.14 |
| 44 | Impact sheet: periodically updated totals, donation % per stream, local best runs (board 11) | Conservation Partnerships; §9 | partners, backend (40) | "values TBD before any cause marketing"; partners unconfirmed | donations, data | S | held → 0.14 |
| 45 | Profiling on test devices to 60 FPS | Technical Constraints | all launch content | "exact models TBD" | – | M | beta |

**Post-launch (after 1.0; GDD "Post-Launch")**

| # | Feature | GDD section | Depends on | Open TBDs that block a spec | Compliance | Cost | Milestone |
|---|---|---|---|---|---|---|---|
| 46 | Enchanted Grove and Cloud Gardens: fictional flowers and species, biome units, content version 4 | Progression Tiers & Biomes; §3 | Alpine (31) | species "Attracted by … TBD"; "Glowcap digger: faster pollination (value TBD, Terry)" | – | L each | post-launch |
| 47 | Patron Pass: Golden Drone, mahogany skin with restoration coordinates, +25%, Jelly stipend, 24 h offline | Monetization (Adopt-a-Hive) | Store (41), pests (33), backend (40) | prices and stipend TBD; the coordinates need a partner | purchases, donations, data | L | post-launch |
| 48 | Online leaderboards: preset-word names, booster, Crystal-tier and route brackets, server validation, opt-in | §5 | backend (40), run tracking (30), kid mode (39) | "exact tiers TBD" | kids, data, backend | L | post-launch |
| 49 | Live Impact Dashboard | Conservation Partnerships | Impact sheet (44), backend | partners unconfirmed | donations, data, backend | M | post-launch |
| 51 | BeeTech Automation: conveyors or pipes carry cells from a hive pile to a centrifuge, bypassing the bee carry so the bees "focus on making honey and polinating" (designer, 2026-11-10) | §4 (with `build-from-start-r2.md`) | Build mode, bee carry (0.4) | number-only: the freed bees' bonus (+x% fill, more pollination; designer chose "free now, bonus later", `build-from-start-r2.md` answer 7) | – | L | post-launch |
| 50 | Switch and desktop | Technical Constraints | – | "each requiring its own business model and input scheme" | purchases | L | post-launch option, not planned |

### 2.2 Milestones as playable increments

| Version | Name | Playable as |
|---|---|---|
| 0.4 | Full automation | one Meadow hive that runs itself; saves and pays offline |
| 0.5 | Grid | buy land and place more hives, flowers and crates; first phone build |
| 0.6 | Habitat | flowers raise Habitat Health; Meadow native bees arrive and fill the Journal |
| 0.7 | Research | genetics and higher unit tiers |
| 0.8 | Capstone | build and charge the Refinery to a Royal Crystal |
| 0.9 | Reset | **vertical slice**: one full rough Meadow run, reset, kept worlds |
| 0.10 | Alpine Valley | the normal route at launch content (two biomes) |
| 0.11 | Feel | pests and drops, audio, Settings, French, the guide |
| 0.12 | Royal Jelly | earned Jelly and time skips |
| 0.13-0.14 | Launch services | age gate, kid mode, backend, Store, ads, Impact Pass, Impact sheet (after Connie) |
| beta, 1.0 | | profiling, content lock, launch |

### 2.3 Interactions

- **Rush gap (Terry).** Until 0.10 there is only Sunny Meadow, so every run in 0.8-0.9 is the rush by definition and `RUSH_GAP_TARGET` cannot be measured. Terry should use 0.8-0.9 to measure the per-biome setup time and real Meadow production, and re-check the rush gap only from 0.10.
- **Leaderboards (opt-in).** 0.9 writes the full run-tracking fields from the start (§5 "from launch"), so later saves need no migration. Vertical-slice runs should carry their own content version, distinct from launch's 2 (`CAP_CHARGE_TARGET[content_version]`), so their run times are never compared with launch runs.
- **Save format.** Save and load arrives in 0.4, but reset, Worlds and run tracking (0.9) and cloud saves (0.13) all extend it. Each spec from 0.4 on should version the save.
- **Phase order.** Grid after full automation (decision 1) keeps the manual harvest at one hive and matches "Phase 3: … expand their biomes indefinitely on a grid".

### 2.4 Impact table

| System | Effect of this roadmap | Risk |
|---|---|---|
| Harvest (§2) | finished in 0.4, then frozen | Deep Frame changes the zoom framing tuned in 0.1.4 |
| Economy (Trees A-B) | 0.4 adds the last Tree B rows | the README income side ("base jar price, bee fill rate, harvest cycle time") is still unset; every later number rests on it |
| Grid (§4) | new in 0.5 | the largest unknown: multi-hive harvest, build-mode UI, performance |
| Tree C | 0.6, Meadow only | real-species facts unchecked until partners are confirmed |
| Capstone and reset | 0.8-0.9 | Terry's values come from a stand-in model; they need 0.4-0.7 data first |
| Monetization and kid mode | held until Connie | if Connie's review starts late, the alpha stops at 0.12 |
| Cost | rough total, vertical slice (0.4-0.9) ≈ 325-1,000 goal-agent runs | Quinn remains the costliest agent per task; the grid and Refinery builds are L |

## 3. Parameters for the next agent (Terry)

Needed before each milestone's spec; no values here. Names marked (Glossary) already exist.

- **0.4:** `JAR_BASE_PRICE`, `BEE_FILL_RATE`, `CENTRIFUGE_CAPACITY_FRAMES`, `TRUCK_CAPACITY_JARS`, `TRUCK_TRIP_SECONDS` (the README income and logistics lines); `LONG_FORK_COST`, `MOTOR_COST`, `AUTO_SCRAPER_COST` (re-confirm provisional); `SPIGOT_FLOW_BASE_COST`, `SPIGOT_FLOW_GROWTH`, `SPIGOT_FLOW_MAX_LEVEL`, `SPIGOT_FLOW_CUT_PER_LEVEL`; `OVERFLOW_STORAGE_CAPACITY_PER_LEVEL`, `OVERFLOW_STORAGE_COST`.
- **0.5:** `LAND_COST_BASE`, `LAND_COST_GROWTH`; `UNIT_COST[type][tier]`, `UNIT_PRODUCTION[type][tier]`, `UNIT_FOOTPRINT[type][tier]`; `CRATE_TIER_JARS[tier]`, `CRATE_TIER_TRUCK_LOAD[tier]`, `CRATE_TIER_COST[tier]`; `BEE_VISUAL_CAP` (with Quinn's profiling).
- **0.6:** `HABITAT_HEALTH_PER_FLOWER[tier]`, `HIVE_BALANCE_PENALTY`, `FLOWER_UPGRADE_COST`, `SYNERGY_THRESHOLD[biome]`; confirm the Meadow values in `native-species-balance.md`.
- **0.7:** `GENETICS_MULT_PER_LEVEL`, `GENETICS_COST`, `TIER_UNLOCK_RESEARCH_COST[tier]`.
- **0.8:** `CAP_BUILD_COST`, `CAP_FOOTPRINT`, `CAP_CHARGE_TARGET[content_version]`, `CAP_DIVERT_MAX`, `AFFINITY[biome]`, `CAP_THROUGHPUT_MAX`, `CAP_SYNERGY_MIN[biome]`, `CAP_UNLOCK_CONDITION` (Glossary), and the Refinery research ladder re-checked at +15%.
- **0.9:** `START_UPGRADE_MAX_LEVEL[option]` (starting hives, starting wildflower plot).
- **0.10:** `HONEY_VALUE[biome]` (Alpine below 1.92× Meadow), `RUSH_GAP_TARGET` re-checked with real data, Crystal tier ranges.
- **0.11-0.12:** `PEST_REWARD`, `NECTAR_DROP_REWARD`, `DROP_SPAWN_RATE`; `JELLY_EARN_RATE`, `TIME_SKIP_COST`.

## 4. Needs a decision first

Rows marked "held" in §2.1; each takes its slot once the blocker is cleared: 10 (clean cut), 11 (multi-hive harvest), 17 (watering), 25 (`CAP_UNLOCK_CONDITION`, charge share), 26 (Crystal credit timing), 28 (starting-upgrade whitelist), 31-32 (Alpine flowers, partner fact-check), 37 (guide play-test), 38-44 (Connie, backend provider, prices, donation percentages).

## 5. Dependency layers

1. 0.4 full automation: Long Fork → auto-scraper; motor; save/load; Tree B rows.
2. 0.5 grid: Build mode → land, units, crates, bee rendering; Android export.
3. 0.6 habitat: flowers → Habitat Health → Synergy, native bees → Journal, Habitat sheet.
4. 0.7 research: genetics → higher unit tiers.
5. 0.8 capstone: Refinery → Royal Crystal.
6. 0.9 reset: Swarm Splitting → starting upgrades, Worlds, local run times (vertical slice).
7. 0.10-0.12 launch content: Alpine, feel (pests, audio, Settings, French, guide), Royal Jelly.
8. 0.13-0.14 after Connie: age gate, kid mode, backend → Store, ads, passes, Impact.

## Decisions needed from the designer

**TBD decisions per milestone, in order:**
- 0.4: `ui-screens.md` decision 4 (Tools icon, Build › Open for automated units); whether the clean-cut bonus is defined or dropped.
- 0.5: decision 1 below (multi-hive harvest).
- 0.6: decision 4 below (watering); `ui-screens.md` decision 5 (one Habitat & Refinery sheet or two).
- 0.8: `CAP_UNLOCK_CONDITION`; `capstone-machine.md` Q5 (Crystal credited on forming or on splitting).
- 0.9: decision 3 below (starting-upgrade whitelist).
- 0.10: the Alpine flower list (Ruth's sources, then William; a conservation partner later).
- 0.11: the guide play-test (one of six).
- 0.12-0.14: decision 5 below (Connie), the backend provider, prices, donation percentages, conservation partner agreements.

**Questions:**
1. **Grid gate and multi-hive harvest (0.5).** Recommended: Build mode appears only once the motor and the auto-scraper are owned, so the manual harvest never covers more than one hive. Alternative: a second hive can be bought in Phase 1, and then the GDD needs a rule for a fork icon and zoom per hive.
   **Answered (designer, 2026-11-09): neither. Build mode is available from the start, and the first thing the player builds is the centrifuge.** This moves Build mode (row 11) out of layer 2 to the start of the game and needs its own proposal (start state, multi-hive harvest, layer order) before the roadmap is revised.
   **Designer's answers (2026-11-10):** the farm starts with the hive and the truck ("the queen in her infinite wisdom and whatever leftover magic from the world creation that is left builds the truck"); the starting money lets the player build the centrifuge; build order centrifuge → crate; before the centrifuge, harvested frames sell as raw comb at a low price; several hives = one fork icon (with its own meter) per hive; ships in 0.4. Proposal: `proposals/design/build-from-start.md` (Gerard).
2. **TBD convention.** Accept that number-only TBDs need a Terry run before the spec but do not hold a milestone, while design TBDs do? (If not, rows 7, 8, 12-14 and 17-19 move to the held list.)
3. **Starting upgrades (0.9).** Which options are on the Royal Crystal whitelist? If this is not settled by the 0.9 spec, 0.9 ships the reset with +15% only and row 28 moves to 0.10.
4. **Watering (0.6).** The Executive Summary and §1 say players "plant and water flowers", but Habitat Synergy has "no growth timers" and watering is defined nowhere. Should watering be dropped from the GDD, or given a rule?
5. **Connie's timing.** Start Connie's review of rows 38-44 (premium currency, kid mode, ads, Store, passes, donations, backend data) during the vertical slice, so 0.12-0.14 are not held when 0.11 ends? Should earned-only Royal Jelly (row 38) wait for her too?
