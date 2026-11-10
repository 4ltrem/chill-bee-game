---
author: gerard
type: design
status: proposed
description: Revision 2 of build-from-start (supersedes the first draft) - free grid from 0.4, bees carry scraped cells from each hive's pile to the nearest centrifuge in range (range from Flight Endurance, carry rate from Worker Swarm Count), raw comb as the no-dead-end fallback, ground jars before the crate, centrifuge tiers as same-spot replacements, cozy Factorio-lite guardrails, automation per farm vs per hive side by side
---
# Build from the start, revision 2: free grid, bee carry and several hives
**Supersedes:** `proposals/design/build-from-start.md` (first draft). That file keeps the designer's quiz answers of 2026-11-10; this revision is built on them and replaces its §1-§3 and decisions. Once this is decided, the first draft can be marked `rejected` (superseded) by the orchestrator.
**Sources:** `GDD.md` (Executive Summary; Audience & Production Plan, Child Safety, Vertical Slice; §1; §2; §3 Tree A, Tree B, Tree C Hive Balance, Capstone Speedrun route and Target run length; §4; §5; §6; §7; §8; §9; Glossary), `proposals/design/build-from-start.md` (all, including "Designer's answers (2026-11-10, quiz)"), `proposals/design/roadmap.md` (rows 1-16, as cited in the first draft), `UI_DESIGN.md` (rule 4, as cited in the first draft), `game/scripts/main.gd` (`load_pile`, the scraped-cell routing, `CellFlight` use).
**Trigger:** designer, 2026-11-10: revise the first draft to the quiz answers, plus three additions: (1) bees carry the combs from the pile to the centrifuge, so Flight Endurance and other bee upgrades set the centrifuge's range; (2) a cozy Factorio-lite guardrail; (3) automation per farm vs per hive side by side.

---

## 1. Concept and assumptions

**Fixed (designer, 2026-11-09/10; not reopened here):**
- Build mode exists from the first launch. The farm starts with the hive and the truck (lore: "the queen in her infinite wisdom and whatever leftover magic from the world creation that is left builds the truck"). Ships in 0.4; 0.2.1 and 0.3.0 keep today's start.
- **Q1 = A:** the hive starts empty; `STARTING_MONEY` covers the centrifuge; the Shop is open from the start. Raw comb is a safety net.
- **Q2 = A:** raw comb is harvested by the normal scrape onto the pile and sold by a "Sell raw comb" pill over the truck; a centrifuge built later takes the pile at full value.
- **Q3 = B:** before the crate, jars stand on the ground beside the spigot up to a small cap and load when the truck returns; the crate is the bigger buffer.
- **Q4 = C:** a free grid from 0.4. A centrifuge serves every hive within its range; hives out of range need their own centrifuge; range scales with Flight Endurance. "Build pad" is dropped; per-placement zoom framing is in scope.
- **Q5 = B, tentative:** automation per hive with growing cost, pending Terry's comparison (§2.6).
- **Q6 (new):** bigger centrifuges are separate units bought in Build mode that replace the old one on the same spot (e.g. hand centrifuge 2 frames, barrel 4, radial extractor 8). Separate from Gearing (crank) and Spigot Flow (bottling).
- **Addition 1 (2026-11-10):** "the flight endurance and other bee upgrades affects the range of the unit placement because the bees carry the combes from the pile to the centrifuge".

**What the feature is.** The player starts with a hive and a truck on a small grid and builds the harvest line: a centrifuge placed near the hive, then a crate beside it, then more hives. Scraped cells no longer fly to the bucket by themselves: **the bees carry them**, along a visible bee lane from the hive to its centrifuge. How far the bees can carry (Flight Endurance) is the centrifuge's range, so bee upgrades and layout meet in one readable rule. The harvest itself (GDD §2) is unchanged once a centrifuge is in range.

**Assumptions:**
- **The guardrail (§2.1) overrides everything else here.** Layout is a gentle puzzle, never a failure state.
- **Building is a pop-in**, no build timers (the GDD has no growth timers).
- **No new models for 0.4.** Existing: hive, centrifuge, crate, truck, bees (MultiMesh), cells. New art: a ghost material for placement, a range-tile pattern, a dotted bee-lane line, and the price label (reuses the Sell pill). Centrifuge tiers 2-3 need two models later (0.5, §2.8); Milo's colorbox variants first.
- **Tree A stays farm-wide** (one Shop row each), so range and carry rate are the same for every hive.
- **Each biome is its own grid.** Range never crosses biomes, so each new biome needs its own centrifuge (this settles the first draft's "per-biome yard" question by consequence; the rush-gap effect is in §2.5).
- **Bees carrying comb is a game mechanic of the magical pocket world, not a real-world claim.** Real honey bees do not ferry wax cappings to an extractor; any Bee Journal or guide line touching it must stay in-world. William checks the wording; Ruth checks any real-bee fact a line implies (e.g. forager roles or flight distance).

## 2. Options and recommendation

### 2.1 Cozy Factorio-lite guardrail (rules)

These are rules, not options. Every later layer (land, tiers, Refinery placement) must keep them.

| # | Rule |
|---|---|
| G1 | **Small grid.** The starting grid is small (`GRID_START_W` × `GRID_START_H`), sized so the whole farm fits the default farm view at 720 × 1280. Growth comes from land expansion (0.6), never from a bigger starting puzzle. |
| G2 | **Generous range.** At Flight Endurance 0, the base range lets the first centrifuge sit on most tiles of the starting grid and still reach the first hive. Range only matters once the farm grows. |
| G3 | **Show range while placing.** In Build mode, while a centrifuge or hive is held, tiles in range show a honeycomb pattern (shape, not colour alone, GDD §8) and the would-be bee lanes preview. A hive placed out of range shows its label "Raw comb only" before the confirm. |
| G4 | **Only one link: range.** No belts, routes, power or rotation. Lanes draw themselves (nearest centrifuge, §2.2). |
| G5 | **Nothing breaks.** No wear, fuel, breakdowns, demolition by accident or decay. Units are never lost in a run. |
| G6 | **Nothing stalls badly offline.** Carry is never the offline bottleneck (§2.2 R6). Offline limits stay the GDD's: the free overflow buffer, the capacity pause and the offline cap. |
| G7 | **No dead end.** Every hive always yields something sellable: in range it feeds a centrifuge; out of range its pile sells as raw comb by truck. Moving units is free (decision 4). Range never shrinks within a run. |
| G8 | **One thumb.** Place = tap a unit in the Build sheet, tap a tile, tap Confirm (bottom third). Dragging is optional, never required. |
| G9 | **Kid mode plays the same rules.** No failure states, no timers, no text-only warnings: every warning has an icon. |

### 2.2 Bees carry the combs (addition 1)

**Shape of the mechanic (all options):** each hive has its own **hive pile** beside it. Scraped cells go to the hive pile; bees take cells from it and fly them along the **bee lane** (a dotted line, hive to centrifuge) into the bucket while the bucket is open with room. The old pile beside the centrifuge and `load_pile` (the pile loads into the empty bucket by itself) are replaced by this one continuous carry. When the bucket's lid is on, the bees wait and cells stay on the hive pile; when it opens, carry resumes. In the manual zoom, a bee meets each cell mid-pop and carries it straight to the bucket, so the moment still reads "scrape, and it flies into the centrifuge", now with a bee under it (Patricia can reuse `CellFlight` with a bee attached; implementation is hers).

**Which upgrade does what:**

| Upgrade (GDD §3 Tree A) | Today | Adds (recommended) | Why |
|---|---|---|---|
| Flight Endurance | +10% bee speed | **Range**: `BEE_CARRY_RANGE_PER_FE_LEVEL` tiles per level, up to `BEE_CARRY_RANGE_MAX_TILES`; also carry speed along the lane | the designer's rule; "endurance" reads as distance |
| Worker Swarm Count | +15% fill rate | **Carry rate**: more bees on each lane (cells per second per hive) | more bees, more carried; no new UI |
| Native bees (Tree C) | habitat bonuses | **none**: wild bees never carry | keeps Hive Balance separate and the managed/wild line clear |
| Bee genetics research (Phase 3, later) | production | possible later range or rate rows (`RESEARCH_CARRY_*`, Terry) | room to grow; not in 0.4 |

**Options:**

| Option | Rule | For | Against |
|---|---|---|---|
| **A. Range + rate, no fill trade-off (recommended)** | Flight Endurance sets range and carry speed; Worker Swarm Count sets carry rate. Carrying never slows the hive's fill. At base, carry rate is at least the manual scrape rate, so carry only shows up as a limit under automation. | Readable for kids: "stronger bees fly further". No new resource. Nothing to lose. Offline is trivially safe. | Carry rate is a soft limit only; the depth is in range and layout, not in bee allocation. |
| B. Egg Inc. style trade-off | As A, plus carrying bees are not foraging: while a lane is busy, the hive fills `CARRY_FILL_PENALTY` slower. | Real choice: far centrifuges cost honey. | A hidden penalty a kid cannot see; punishes layout instead of rewarding it; offline needs a model of busy bees; breaks G5/G9 in spirit. |
| C. Range only, carry is decoration | Flight Endurance sets range; carry is a fixed-speed visual; Worker Swarm Count unchanged. | Smallest change; Terry re-prices one upgrade. | The designer's "and other bee upgrades" goes unused; automation throughput has no bee lever. |

**Recommendation: A.**

**Rules (R1-R7):**
- **R1 Range** = `BEE_CARRY_RANGE_BASE_TILES` + `BEE_CARRY_RANGE_PER_FE_LEVEL` × Flight Endurance level, capped at `BEE_CARRY_RANGE_MAX_TILES`. Measured hive tile to centrifuge tile (Chebyshev "rings", so the range shows as a square of tiles, easy to read on a grid; Patricia/Bob may prefer another metric).
- **R2 Range ceiling = zoom ceiling.** `BEE_CARRY_RANGE_MAX_TILES` may not exceed the farthest hive-to-centrifuge distance the first zoom can frame at 720 × 1280 with Deep Frame at max (Bob measures it). This keeps GDD §2 "the first zoom always keeps both in focus" true on a free grid. Flight Endurance needs a max level for this (`FLIGHT_ENDURANCE_MAX_LEVEL`; the GDD gives none today), or levels past the ceiling give speed only.
- **R3 Assignment.** Each hive's bees carry to the **nearest** centrifuge in range (ties: the one built first). The lane shows it. See decision 3.
- **R4 Out of range** (decision 2, recommended): the hive fills and is harvested as usual; its scraped cells stay on its hive pile, and the "Sell raw comb ($X)" pill over the truck sells every out-of-range pile at `RAW_COMB_PRICE_RATIO`. Placing or moving a centrifuge into range later sends the bees to carry that pile at full value. Nothing is lost.
- **R5 Range only grows** within a run (Flight Endurance is never lost). After a reset the new world starts empty, so no built layout can fall out of range.
- **R6 Offline:** carry is resolved as a rate, never as flights; if the bucket's lid is on, cells wait on the hive pile as today's pile does. Carry adds no offline stall beyond the existing capacity pause.
- **R7 Look:** lanes are dotted lines on the ground (ghost material), shown always at the farm view (they are the layout's story) and highlighted in Build mode. Carrying bees reuse the bee MultiMesh with a cell; their count per lane is capped visually (`CARRY_BEES_VISIBLE_MAX`, Patricia's config) so ten hives do not cost frame rate. Out-of-range hives show a small raw-comb icon, no red.

### 2.3 First-session flow (recommended path)

1. **First launch.** Age gate (Connie's area, unchanged). The farm: a small grid, the hive on its start tile (empty, filling), the truck on its road at the grid's edge. Money shows `STARTING_MONEY`. The Build icon shows from the start.
2. **The guide's first beat** (new, William): welcome, the truck's lore, "a beekeeper needs a centrifuge", "your bees will carry the comb to it".
3. **Build the centrifuge.** Build icon → Build mode (grid lines show; HUD dims) → Build sheet: Centrifuge (price) → tiles in range of the hive glow (G3), with one **suggested tile** the guide points at → tap a tile → Confirm → pop-in (bucket empty, lid off), the bee lane draws itself. Build mode closes after the first build. The crate row unlocks.
   - **Raw-comb branch:** if the hive fills before any centrifuge exists, the fork icon works as usual; the first zoom frames the hive and the suggested centrifuge tile; cells drop onto the hive pile and the "Sell raw comb" pill appears over the truck. A centrifuge built later takes the pile at full value (R4).
4. **First harvest.** As GDD §2: fork icon → first zoom (this hive + its centrifuge, framed from their positions) → scrape → bees carry cells to the bucket → zoom ends → Spin (on tap) → second stop (centrifuge, its jars or crate, the truck) → crank → bottling.
5. **Bottling with no crate (Q3 = B).** Jars go onto the truck while it is home. While it is away, jars stand on the ground beside the spigot up to `GROUND_JAR_CAP`; when the truck returns they load. Only when the ground is full and the truck is away does bottling wait (honey stays in the bucket, its lid stays on, cells wait on the hive pile). The guide's crate beat fires the first time the ground fills: "a crate holds more jars while the truck is away".
6. **Build the crate.** Placed on a tile **touching its centrifuge**; it serves that centrifuge and replaces its ground jars as the buffer (ground jars move into it). GDD §2 Stage 3 then holds as written.
7. **First upgrade.** Shop as in 0.2; Gearing and Spigot Flow show "Needs centrifuge" until one exists. Flight Endurance's row now also states its range ("Range 3 → 4 tiles").
8. **The second hive** (`HIVE_BUILD_COST_BASE`). Placing it shows range tiles of every centrifuge, so the player learns the rule by placing, not by reading.

### 2.4 Rules: gated, earned, lost, reset

| Thing | Gate | Earned / paid | Lost | On reset (Swarm Splitting) |
|---|---|---|---|---|
| Hive (first) | none | given | never | given again |
| Truck | none | given (lore) | never | given again (the lore line must hold per world; William) |
| Centrifuge (each) | none for the first | `CENTRIFUGE_BUILD_COST`, then `EXTRA_CENTRIFUGE_COST_BASE × EXTRA_CENTRIFUGE_COST_GROWTH^(n)` | never | rebuilt, unless a Crystal starting upgrade pre-builds one (whitelist candidate, `roadmap.md` question 3) |
| Centrifuge tier 2-3 | the unit exists; tier gate `CENTRIFUGE_TIER_UNLOCK[t]` (research or Gearing level: Terry/designer, later) | `CENTRIFUGE_TIER_COST[t]`; the old unit is traded in (`CENTRIFUGE_TRADE_IN_RATIO`, may be 0) | never | rebuilt at tier 1 |
| Jar crate tier 1 | a centrifuge with a free touching tile | `CRATE_BUILD_COST` | never | rebuilt |
| Extra hives | a free tile; none other (out of range is allowed, R4) | `HIVE_BUILD_COST_BASE × HIVE_BUILD_COST_GROWTH^(n)` | never | Crystal "starting hives" option |
| Raw comb sale | a hive pile out of range of every centrifuge (or no centrifuge yet) | `RAW_COMB_PRICE_RATIO` × jar value | ends when a centrifuge reaches it | — |
| Ground jars | a centrifuge with no crate | free, up to `GROUND_JAR_CAP` | replaced by the crate | — |
| Move | Build mode, outside a zoom or spin | free (decision 4 = A) | — | — |

- **Centrifuge replacement (Q6):** all centrifuge tiers have the **same footprint** (1 tile; `CENTRIFUGE_FOOTPRINT`), so a replacement always fits the same spot and lanes and the crate stay valid. Replace is disabled during a spin or bottling; the bucket's cells and the ground jars carry into the new unit. Tier capacity is `CENTRIFUGE_TIER_CAPACITY_FRAMES[t]`; Deep Frame (0.5) is where tier 2 becomes wanted.
- **Build mode in 0.4:** place, move (free), replace (centrifuge tiers, from 0.5). No sell-back or demolish (G5).

### 2.5 Interactions with other systems

- **Harvest (§2).** The zoom frames each hive with its assigned centrifuge, computed per placement and bounded by R2. The scraped-cell route changes (hive pile + bee carry instead of bucket-or-centrifuge-pile). Several hives keep the first draft's rules: one fork icon and meter per hive (`UI_DESIGN.md` rule 4), each tap zooms on that hive, other hives keep filling, no auto-chaining. A centrifuge shared by several hives fills from all their lanes. Second stop: the centrifuge and its crate or ground jars; the truck is framed if it fits, otherwise the Sell icon stays pinned at the screen edge (a framing risk for Bob, see §2.7).
- **Clutter at 720 × 1280.** With a free grid the layout no longer guarantees spacing. Rule: two hives may not sit on touching tiles when their fork icons' 120 × 120 touch areas would overlap at the default farm view; the placement preview shows it as a blocked tile (icon, not colour). Quinn's overlap check runs on randomised layouts with all hives full. (`MIN_HIVE_SPACING_TILES`: Bob/Patricia set it from measurement, not Terry.)
- **Economy, Tree A.** Flight Endurance gains range (and loses nothing); Worker Swarm Count gains carry rate. Both are farm-wide, so their value grows with hive count and centrifuge count. Terry re-prices both, and sets Flight Endurance's max level (R2).
- **Economy, Tree B.** Gearing and Spigot Flow need a centrifuge and apply to every centrifuge. Heated Fork works in raw-comb harvests. Auto-Sell before any crate: the truck leaves full and jars use the ground; legal, but Terry's pacing should put the crate first. Deep Frame re-frames every zoom and raises the wish for tier 2 centrifuges.
- **Automation (§2.6).** Under automation, carry rate becomes a real throughput limit for far or crowded centrifuges; that is the "optimization pays off" pillar, kept soft by R6 and G6.
- **Phase 2.** Still triggered by Auto-Sell (0.2 item 7). Building is not automation.
- **Onboarding (§7), guide, lore.** New beats: first build (centrifuge) with the bees-carry line, crate when the ground fills, and a range hint the first time a hive is placed out of range. William rewrites Act 1 and adds these beats; Act 3's barrel description is already out of step with the cells-to-bucket flow. Clara checks. GDD §7 gains "Guides the first build". The truck lore must not assume the guide is the queen (Queen Maeve is only one candidate).
- **Real-world facts (to check, not stated as fact).** (1) Bees carrying comb to a centrifuge is in-world magic (§1). (2) "Raw comb sells low" is a game rule; real cut comb may sell higher than extracted honey (unverified; Ruth/William check before any text explains the price). Text gives a game reason ("the truck's buyers want jars").
- **Offline (§6).** Each hive keeps its own free overflow buffer (the first draft's rule), so offline storage grows with hive count; Terry checks it against the 4 h free cap. Carry adds no stall (R6).
- **Save and load (roadmap row 9).** Required in 0.4: tile positions, centrifuge tiers, crates, each hive's frames, buffer and hive pile, ground jars, and the first save format's version.
- **Habitat (Tree C, later).** Hives placed in 0.4-0.6 exist before flowers; Hive Balance needs a save migration rule. Flowers will compete for tiles with the range square, which is the intended per-tile puzzle (GDD §4), kept gentle by G2.
- **Rush gap (Terry).** Two effects. (a) **Per-biome setup:** each biome is its own grid, so the normal route builds a centrifuge (and crate) in every biome it opens; the rush builds them once. That adds to ΔF per biome and **lowers the rush gap**, mostly for new players. (b) **Layout density:** the rush lives in one biome and packs it; if range rewards dense layouts strongly, the rush gains more. Terry models ΔF with the per-biome build, and checks that range does not make Meadow density a rush-only lever. A Crystal "centrifuge pre-built in each new biome" starting upgrade would cancel (a); not decided here.
- **Leaderboards (opt-in).** Run time starts at world creation (§5), so building counts equally for everyone in a content version. Layout skill now changes run times; that is fair play on opt-in boards. Changing `STARTING_MONEY`, build costs or range parameters after launch shifts every route's fixed time; log the change with the run-tracking fields so ranked comparisons across it can be flagged. No paid booster touches range.
- **Dev mode.** All tunables in config, live in the Dev panel (placeholders err slow). Toggles: "legacy start" (centrifuge and crate pre-built, as 0.3.0), "fill all hives", "show all ranges", "+$100" (exists).

### 2.6 Automation per farm vs per hive (addition 3)

The designer answered "B, tentative" and is unsure. All three are shown side by side; Terry costs all three and the designer decides on his numbers (decision 5). With several centrifuges, "per unit" means the motor per centrifuge and the auto-scraper per hive.

| | A. Per farm | B. Per unit, growing cost (tentative answer) | C. Per farm + flat install fee |
|---|---|---|---|
| What you buy | one motor and one auto-scraper in the Shop; every centrifuge and hive, now and later, is equipped | a motor for each centrifuge and an auto-scraper for each hive, each dearer than the last | one Shop purchase each (as A); every unit built afterwards costs `*_INSTALL_COST` extra, flat |
| Player feel | big "everything runs" moment; new hives feel cheap and instantly productive | Factorio-like: automate one unit at a time, see each gantry appear; but each new hive asks twice (the hive, then its scraper) and the price climbs, so expansion can feel **taxed** | the big moment of A, with a small honest cost per new unit that never grows; reads as "fit the gantry" |
| Precedent | Egg Inc.: research upgrades apply farm-wide | Factorio: each machine is built individually; its recipe cost is flat, not growing | a blend: farm-wide unlock, flat per-unit build (Factorio's flat cost, without its growth) |
| Capacity pause (GDD §2) | ends farm-wide when both are owned (today's single check) | ends per hive: a hive whose centrifuge has a motor and which has its own scraper | ends farm-wide; a new unit is automated on purchase |
| Phase 2 / post-automation bonuses | unchanged from 0.2 | per unit: Heated Fork and Gearing flat bonuses switch per unit (more rules, more UI) | unchanged from 0.2 |
| UI | two Shop rows | one Build › unit row per unit, or a per-unit button in Build mode; Build › Open per unit | two Shop rows; the install fee joins each unit's price label |
| Offline and kid read | simplest | a half-automated farm stalls on its manual hives offline (the pause applies to them): readable but a soft punishment | simple |
| Risk | hives are cheap to run after automation (Terry prices hives with that in mind) | the expansion tax; Shop or Build clutter | one more number per unit |
| Terry parameters | `MOTOR_COST`, `AUTO_SCRAPER_COST` | `MOTOR_COST_PER_UNIT_BASE`, `MOTOR_COST_PER_UNIT_GROWTH`, `AUTO_SCRAPER_COST_PER_HIVE_BASE`, `AUTO_SCRAPER_COST_PER_HIVE_GROWTH` | `MOTOR_COST`, `AUTO_SCRAPER_COST`, `MOTOR_INSTALL_COST`, `AUTO_SCRAPER_INSTALL_COST` |

**Recommendation: C** (per farm with a flat install fee). It keeps the one big Phase 2 moment and today's capacity-pause check, keeps hive cost honest after automation, and borrows Factorio's per-unit flat cost without the growing price that makes B feel like a tax on expansion. If Terry's numbers show the fee is too small to matter, A is the fallback. Precedents are as the designer framed them; they are design references, not claims about the current versions of those games.

### 2.7 Impact table

| System | Effect | Risk |
|---|---|---|
| Harvest (§2) | hive pile + bee carry replace the centrifuge pile and `load_pile`; per-placement zoom framing; per-hive fork icons | `main.gd` single-hive and single-pile assumptions; framing on arbitrary layouts (bounded by R2) |
| Grid and Build mode (§4, §9) | free grid, place, free move, range preview, lanes, from 0.4 | the largest 0.4 build item; one-thumb placement must be play-tested on a phone |
| Tree A | Flight Endurance = range (+ carry speed); Worker Swarm Count = carry rate | both rise in value with N hives; Flight Endurance needs a max level |
| Tree B | Gearing/Spigot Flow need a centrifuge; Deep Frame pushes tier 2 | Auto-Sell before the crate leans on ground jars |
| Centrifuge tiers | same-spot replacement, same footprint | two new models (0.5); trade-in value |
| Automation (0.5) | A / B / C per §2.6 | B's expansion tax; A's cheap hives |
| UI clutter (720 × 1280) | N fork icons, lanes, Spin, Sell | free layouts can crowd icons; spacing rule + Quinn's randomised check; Android touch test |
| Onboarding, guide, lore | three new beats; Act 1 rewrite | the guide play-test runs on a changed script |
| Offline (§6) | per-hive buffer; carry never stalls | offline income grows with hive count in Phase 1 |
| Save (row 9) | required in 0.4, with tile positions and piles | the first format must carry the grid |
| Habitat (Tree C) | flowers compete for tiles in range | save migration when Hive Balance arrives |
| Rush gap, leaderboards | per-biome centrifuge raises ΔF on the normal route | lower rush gap for new players; layout density may favour the rush (Terry) |
| Performance | carrying bees per lane | capped by `CARRY_BEES_VISIBLE_MAX`; Quinn checks FPS with every hive full |
| Roadmap | the grid layer moves into 0.4 | 0.4 grows from L to about XL (§2.8) |

### 2.8 Roadmap effect: rows 1-16 re-layered (free grid in 0.4)

Layer 1 (0.4) is now **build + free grid + bee carry**. Layer 2 (0.5) is automation and centrifuge tiers. Layer 3 (0.6) is what is left of the grid layer: land, flowers, crate tiers, bee rendering.

| # | Feature | Was | Now | Why |
|---|---|---|---|---|
| N1 | Start state: hive and truck on a small grid, `STARTING_MONEY` | — | **0.4** | designer, Q1 |
| N2 | Raw comb: hive pile, "Sell raw comb" pill, full value when a centrifuge reaches it | — | **0.4** | designer, Q2 |
| N3 | Centrifuge and crate builds, build order, "Needs centrifuge" gates, ground jars to `GROUND_JAR_CAP` | — | **0.4** | designer, Q3 |
| N4 | Several hives, manual: per-hive fork icon and meter, per-placement framing, per-hive buffer | — | **0.4** | designer |
| N6 | Bee carry: range from Flight Endurance, carry rate from Worker Swarm Count, lanes, nearest assignment, several centrifuges | — | **0.4** | designer, addition 1 |
| N5 | Guide and lore text for the new beats (William, then Clara) | — | before the 0.4 spec | content |
| 11 | Build mode: free placement, free move, range preview (was 11a pads + 11b grid) | held → 0.5 / 0.6 | **0.4** | Q4 = C |
| 13a | Extra Langstroth hives, placed freely | 0.5 | **0.4** | |
| 14a | Jar crate tier 1 as a build, touching its centrifuge | 0.5 | **0.4** | |
| 9 | Save and load; offline at 4 h; Welcome back | 0.4 | **0.4** (required) | the grid must persist |
| 16 | Android export | 0.5 | **0.4** (recommended) | one-thumb placement and icon spacing need a real phone |
| N7 | Centrifuge tiers 2-3 (same-spot replacement; two models via Milo) | — | **0.5** | Q6; wanted with Deep Frame |
| 1-5, 8 | Long Fork, motor, auto-scraper, end of the capacity pause, Deep Frame, Overflow Storage | 0.4 | 0.5 | automation layer; motor/scraper shape per decision 5 |
| 6 | Artisanal Branding | 0.4 | 0.5 (could ride in 0.4) | independent, S |
| 7 | Spigot Flow | 0.2.1 | 0.2.1 | unchanged |
| 10 | Heated Fork clean cut | held → 0.4 | held → 0.5 | still undefined |
| 12 | Land expansion | 0.5 | 0.6 | G1: growth comes from land |
| 13b | Flower units | 0.5 | 0.6 | |
| 14b | Jar crate tiers 2-3 | 0.5 | 0.6 | |
| 15 | Bee rendering plan | 0.5 | 0.6 | carrying bees add load; 0.4 relies on `CARRY_BEES_VISIBLE_MAX` |

Rows 17 onward each move one version (habitat 0.7, research 0.8, capstone 0.9, reset 0.10: the **vertical slice moves from 0.9 to 0.10**), unless the orchestrator folds the now-thinner 0.6 into 0.5, which would keep the slice at 0.9; that is a scheduling call, not a design one. Rough cost of the new 0.4: about XL, larger than the first draft's L, because free placement, per-placement framing and multi-hive state land together. The roadmap file is revised by the orchestrator once this is decided; Gerard does not edit it.

## 3. Parameters for the next agent (Terry)

Names only; no values. Placeholders err slow.

1. `STARTING_MONEY`: at least `CENTRIFUGE_BUILD_COST`; any surplus is the first free choice.
2. `CENTRIFUGE_BUILD_COST`: the first centrifuge (tier 1).
3. `EXTRA_CENTRIFUGE_COST_BASE`, `EXTRA_CENTRIFUGE_COST_GROWTH`: the second and later tier 1 centrifuges.
4. `CENTRIFUGE_TIER_CAPACITY_FRAMES[t]`: bucket capacity per tier (designer's example shape: 2 / 4 / 8 frames; Terry sets values).
5. `CENTRIFUGE_TIER_COST[t]`, `CENTRIFUGE_TRADE_IN_RATIO`, `CENTRIFUGE_TIER_UNLOCK[t]`: replacement cost, the old unit's credit, and the gate (with the designer).
6. `CRATE_BUILD_COST`; crate tier 1 capacity (existing crate value, re-checked).
7. `GROUND_JAR_CAP`: jars that wait on the ground beside a crateless centrifuge. Small enough that the crate is wanted soon.
8. `RAW_COMB_PRICE_RATIO`, `RAW_COMB_TRUCK_SPACE`: as in the first draft; must keep an out-of-range hive worth having but a centrifuge clearly better.
9. `HIVE_BUILD_COST_BASE`, `HIVE_BUILD_COST_GROWTH`.
10. `BEE_CARRY_RANGE_BASE_TILES`: range at Flight Endurance 0 (G2: generous on the starting grid).
11. `BEE_CARRY_RANGE_PER_FE_LEVEL`: tiles added per Flight Endurance level.
12. `BEE_CARRY_RANGE_MAX_TILES`: the cap; must not exceed Bob's measured zoom ceiling (R2).
13. `FLIGHT_ENDURANCE_MAX_LEVEL` (new; the GDD has none) and Flight Endurance's re-priced cost now that it carries range.
14. `BEE_CARRY_RATE_BASE`: cells per second per hive at Worker Swarm Count 0; at least the manual scrape rate.
15. `BEE_CARRY_RATE_PER_WSC_LEVEL`: carry rate added per Worker Swarm Count level.
16. `BEE_CARRY_SECONDS_PER_TILE`: carry speed along the lane (set with Flight Endurance; affects throughput only under automation).
17. `CARRY_FILL_PENALTY`: only if decision 1 = B.
18. `GRID_START_W`, `GRID_START_H`: starting grid (with Bob's framing; G1).
19. `OVERFLOW_HIVES_PER_HIVE`: per-hive buffer, re-checked against the 4 h cap with N hives.
20. `TRUCK_CAPACITY_JARS`, `TRUCK_TRIP_SECONDS`: one truck serving N centrifuges.
21. Automation, all three shapes (§2.6): `MOTOR_COST`, `AUTO_SCRAPER_COST`; `MOTOR_COST_PER_UNIT_BASE`/`_GROWTH`, `AUTO_SCRAPER_COST_PER_HIVE_BASE`/`_GROWTH`; `MOTOR_INSTALL_COST`, `AUTO_SCRAPER_INSTALL_COST`. Report each shape's cost of the Nth hive including automation, so the "tax on expansion" is visible.
22. `MOVE_COST`: only if decision 4 = B.
23. Pacing targets (minutes into the first session): `TIME_TO_CENTRIFUGE`, `TIME_TO_CRATE`, `TIME_TO_SECOND_HIVE`, `TIME_TO_SECOND_CENTRIFUGE`, and the Auto-Sell point (about 12 min), re-checked with builds first.
24. Rush-gap inputs: ΔF with a centrifuge and crate built in each new biome, and the layout-density effect of range in a Meadow-only rush (§2.5).

Not Terry's (Patricia/Bob config): `MIN_HIVE_SPACING_TILES`, `CARRY_BEES_VISIBLE_MAX`, `CENTRIFUGE_FOOTPRINT` (fixed at 1 by rule), lane dot spacing, pop-in seconds, ghost alpha, label offsets.

## Decisions needed from the designer

Quiz questions, each with a recommendation and a one-line preview. Before the 0.4 spec, William's text (N5), Terry's run (§3), Bob's zoom-ceiling measurement (R2) and Ruth/William's checks (§2.5) are also needed.

1. **What do bee upgrades do to the carry?**
   - A. Flight Endurance = range and carry speed; Worker Swarm Count = carry rate; carrying never slows the hive's fill. **(recommended)**
     `[Hive]-b-b-b->[Cent]   FE+ : lane longer   Swarm+ : more b   fill: same`
   - B. As A, but carrying bees stop foraging: busy lanes slow the hive's fill (Egg Inc. style trade-off).
     `[Hive]-b-b-b->[Cent]   fill -x% while b are carrying`
   - C. Flight Endurance = range only; the carry is a fixed-speed visual.
     `[Hive]-b->[Cent]   FE+ : lane longer   (nothing else changes)`
2. **What happens to a hive out of range of every centrifuge?**
   - A. It is harvested as usual; its cells stay on its pile and sell as raw comb by truck; a centrifuge placed in range later carries the pile at full value. **(recommended: no dead end)**
     `[Hive]~pile~ ... (no lane) ... [Truck: Sell raw comb $X]`
   - B. Its fork icon is greyed with "Needs a centrifuge in range"; it fills its buffer and waits.
     `[Hive] (x) "needs centrifuge" ... buffer full, waiting`
   - C. Bees still carry, slower beyond range (a soft range).
     `[Hive]-b . . . b . . . ->[Cent]  (slow lane)`
3. **When a hive is in range of several centrifuges, where do its bees carry?**
   - A. To the nearest (ties: the first built); the lane shows it. **(recommended)**
     `[CentA]<-b-[Hive]   [CentB]   (nearest wins)`
   - B. The player taps the hive in Build mode and picks the centrifuge.
     `[CentA]   [Hive]-b->[CentB]   (player drew it)`
   - C. Split across all in range (load balancing).
     `[CentA]<-b-[Hive]-b->[CentB]`
4. **Can units be moved in 0.4?**
   - A. Yes, free, in Build mode (not during a zoom or spin); lanes redraw. **(recommended: G7 no dead end)**
     `Build > Move > [Hive] -> tile OK  $0`
   - B. Yes, for a small fee (`MOVE_COST`).
     `Build > Move > [Hive] -> tile OK  $5`
   - C. No moving until 0.6.
     `Build > [Hive] placed (locked)`
5. **Automation with several hives (your tentative B, pending Terry's numbers, §2.6):**
   - A. Per farm: one motor, one auto-scraper equip everything.
     `Shop: Motor $M  Scraper $S  -> all units`
   - B. Per unit, growing cost.
     `Hive1 $S  Hive2 $S*g  Hive3 $S*g^2 ...`
   - C. Per farm, plus a flat install fee on each unit built afterwards. **(recommended: no expansion tax, one big Phase 2 moment)**
     `Shop: Scraper $S once;  new Hive: $H + $fee (flat)`

Accepting this revision also accepts §2.8's roadmap shift and these GDD edits: §2 start state, builds, raw comb, ground jars, hive pile and bee carry, per-hive fork icons and per-placement framing; §3 Tree A (Flight Endurance = range, max level; Worker Swarm Count = carry rate); §3 Tree B gates and the automation shape; §4 free grid from the start, centrifuge range and tiers (same-spot replacement), crate touching its centrifuge, the guardrail G1-G9; §7 lore and the guide's first build; §9 Build mode from the start; Glossary gains "Raw comb", "Hive pile", "Bee lane", "Centrifuge range" (no "Build pad"). The proposals index needs a rebuild (`python -I _tools/index.py proposals/design`); this run had no shell to run it.

## Designer's answers (2026-11-10, quiz)

1. **A**: Flight Endurance = range and carry speed; Worker Swarm Count = carry rate; carrying never slows the hive's fill.
2. **A**: a hive out of range is harvested as usual, its pile sells as raw comb; a centrifuge placed in range later carries the pile at full value.
3. **C** (not the recommendation): a hive in range of several centrifuges splits its cells across all of them. Designer's note: "if both in range".
4. **A**: free moving in Build mode (not during a zoom or spin); lanes redraw.
5. **C**: automation per farm, plus a flat install fee on each unit built afterwards (replaces the tentative "per hive" of the first draft).

6. **Two carry zones** (designer, 2026-11-10): "if the combs are within close range to a centrifuge they fly into the pile next to the centrifuge if too far it flies onto a pile close to hive and the bees transport it". So: close range = cells fly straight to the pile beside the centrifuge (today's flying cells); beyond close range but within bee range = cells land on a pile by the hive and bees carry them; beyond bee range = raw comb (answer 2). The close-range distance is a new Terry parameter (`CELL_FLY_RANGE`), and Bob's zoom ceiling bounds it.
7. **BeeTech Automation, post-launch** (designer, 2026-11-10): "later on in the progression the player can bypass the bees by using conveyors or pipes (post launch BeeTech Automation) which would let the bees focus on making honey and polinating". Conveyors or pipes carry cells from a hive pile to a centrifuge in place of the bees. Added to `roadmap.md` as a post-launch row. Quiz answer (2026-11-10): **free now, bonus later**: the bee carry never slows the fill (answer 1 stands); when conveyors take over a lane, the freed bees give a bonus (+x% fill and/or more pollination for Habitat Health; values Terry, post-launch).

Status: all open decisions answered. Still needed before the 0.4 spec: Terry's run (§3, including the split rule's effect on throughput), Bob's zoom-ceiling measurement (R2), William's text (N5), Ruth/William's raw-comb price check (§2.5); then the designer accepts and the GDD edits above are applied.
