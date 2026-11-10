---
author: gerard
type: design
status: superseded by build-from-start-r2.md (2026-11-10)
description: Build mode from the first launch - the farm starts with the hive and the truck, the player builds the centrifuge then the crate, raw comb before the centrifuge, one fork icon per hive sharing one centrifuge; Build mode becomes roadmap layer 1 (0.4)
---
# Build from the start: first session, raw comb and several hives
**Sources:** `GDD.md` (Executive Summary; Audience & Production Plan, Vertical Slice; §1; §2; §3 Tree A, Tree B, Tree C Hive Balance, Capstone Speedrun route and Target run length; §4; §5; §6; §7; §8; §9; Technical Constraints; Glossary), `proposals/design/roadmap.md` (rows 1-16, question 1 "Answered"), `proposals/design/ui-screens.md` (§1, §2 board 6, decisions), `UI_DESIGN.md` (rules 1-4), `game/specs/0.1-harvest.md`, `game/specs/0.1.4-ui-placement.md` (items 2, 3, 7, 11, 12, 15), `game/specs/0.2-first-automation.md` (items 1, 6, 7, 9, 12), `content/onboarding-script.md` (act headings only).
**Trigger:** designer, 2026-11-09/10 (`roadmap.md` question 1, "Answered"): Build mode is available from the start; the farm starts with the hive and the truck; the starting money builds the centrifuge; build order centrifuge → crate; raw comb at a low price before the centrifuge; one fork icon (with its own meter) per hive, tapping it zooms into that hive; ships in 0.4.

---

## 1. Concept and assumptions

**Fixed (designer, 2026-11-09/10; not reopened here):**
- Build mode exists from the first launch.
- First launch: the farm holds the hive and the truck. Lore, designer's words: "the queen in her infinite wisdom and whatever leftover magic from the world creation that is left builds the truck".
- The starting money lets the player build the centrifuge. Build order: centrifuge → crate.
- Before the centrifuge is built, harvested frames sell as **raw comb** at a low price; the truck carries it.
- Several hives: one Harvest fork icon per hive, each with its own honey meter (`UI_DESIGN.md` rule 4). Tapping one zooms into that hive.
- Ships in 0.4, after the 11/24 course build. 0.2.1 and 0.3.0 keep today's start (centrifuge, crate and truck placed).

**What the feature is.** The player no longer finds a finished harvest line. They find a hive, a truck and a few empty **build pads** (ghost outlines), and they build the harvest line themselves, a machine at a time. This brings in the *Factorio* pillar ("Optimization pays off") from minute one: the first decision is a build, not a tap. The harvest itself (GDD §2) does not change once the centrifuge and crate exist.

**Assumptions:**
- **One centrifuge per farm** in 0.4 and 0.5. Every hive's cells go to the same bucket and the same pile. More centrifuges, or centrifuge tiers, belong to the grid layer (0.6); see §2.6.
- **The hive starts empty** and fills as today. The first fill is the natural window for the first build: the player builds while the hive fills.
- **Building is a pop-in**: the machine scales in with the cell pop's ease where its pad was. There are no build timers; the GDD has no growth timers anywhere, so build timers would be a new rule.
- **No new models.** The centrifuge, crate, hive and truck exist (`scenes/props/`). New art is only a ghost material for pads, plus a price label that reuses the Sell pill.
- **Tree A is farm-wide.** Worker Swarm Count and Flight Endurance apply to every hive (the bees serve the farm). This is a rule, not an open question, because per-hive Tree A would multiply Shop rows by the hive count.

### 1.1 Options for the build surface (where the player builds)

| Option | Shape | For | Against |
|---|---|---|---|
| **A. Build pads (recommended for 0.4)** | The farm shows fixed ghost pads: one centrifuge pad, one crate pad (by the truck's road) and a small number of hive pads placed around the centrifuge. In Build mode, tapping a pad buys and builds its unit. | Every camera stop from 0.1.4 stays valid (first zoom = this hive + the centrifuge; second stop = centrifuge, crate, truck). Icon spacing is guaranteed by the layout, so no clutter rule is needed. Smallest build (M). | No free placement until the grid layer. GDD §4 "players place each hive … themselves" is met only from 0.6. |
| B. Grid with a harvest ring | Hives go on any tile within a ring around the centrifuge that the first zoom can frame. Centrifuge and crate stay on fixed pads. | Real placement choices from the start. | Zoom framing is computed per placement; icon overlap needs a rule; the cost is L and pulls most of the grid layer into 0.4. |
| C. Free grid everywhere | Everything placed freely, with framing computed from positions. | Closest to GDD §4. | Breaks the "first zoom always keeps both in focus" rule (§2) for distant hives; highest cost and play-test risk. |

**Recommendation: A for 0.4, with B as the rule the grid layer (0.6) grows into.** Pads let 0.4 ship the designer's three decisions (build from start, raw comb, several hives) on today's tuned camera. Later, the pads become reserved tiles on the grid (decision 4).

## 2. Options and recommendation

### 2.1 First-session flow (recommended path)

The flow below follows decisions 1-3 as recommended. Where it branches, the branch is noted.

1. **First launch.** The age gate comes first (board 14; Connie's area, unchanged). Then the farm: the hive (empty, filling), the truck at home, and three ghost pads: centrifuge (with price), crate (marked "Needs centrifuge"), and the hive pads (price shown on the first; the rest hidden until the first extra hive is affordable, or shown locked, per `ui-screens.md` decision 3). Money shows `STARTING_MONEY`. The Build icon is shown from the start (this changes `ui-screens.md` §1, "Build at the first land or unit purchase").
2. **The guide's first beat** (new, William). The guide welcomes the player, explains that the queen and the world's leftover magic made the truck, and points at the centrifuge pad: "a beekeeper needs a centrifuge".
3. **Build the centrifuge.** Build icon → Build mode (the pads glow; the rest of the HUD dims) → tap the centrifuge pad → a small confirm with the price → the centrifuge pops in, lid off and bucket empty, as today's `EMPTY` state. Build mode closes by itself after the first build, so the first session is not left in a mode. Money drops by `CENTRIFUGE_BUILD_COST`. The crate pad unlocks.
   - **Branch, raw comb (decision 1):** if the hive fills before the centrifuge is built (the player skipped the guide, or spent the money in the Shop), the fork icon works as usual. The zoom frames the hive and the empty centrifuge pad. Scraped cells fly to the **pile** beside the pad, because there is no bucket. A **Sell raw comb ($X)** pill shows over the truck. Tapping it moves the pile onto the truck bed and sells it at `RAW_COMB_PRICE_RATIO` of the jar value. If the centrifuge is built while comb is still on the pile, that pile is today's pile: it loads into the empty bucket at full value. Nothing is lost.
4. **First harvest.** As GDD §2 today: the fork icon over the full hive → first zoom (this hive + the centrifuge) → scrape → cells to the bucket, then the pile → zoom ends → Spin (only on tap, 0.2 spec item 9) → second stop → crank → bottling.
5. **Bottling with no crate (decision 3).** Jars fly from the spigot onto the truck while it is home, as today. When the truck is full or the player sells, the truck leaves. **While it is away, bottling waits:** the honey stays in the bucket (its level shows it), the lid stays on, and new cells go to the pile. When the truck returns, bottling resumes. This is the crate's teaching moment: the guide (or a one-line hint) points at the crate pad: "a crate keeps the jars coming while the truck is away".
6. **Build the crate.** It is paid from the first sale or sales (`CRATE_BUILD_COST`). From then on, GDD §2 Stage 3 holds as written: jars wait in the crate while the truck is away.
7. **First upgrade** (GDD §7 third bullet, unchanged): the Shop as in 0.2. Rows that need the centrifuge (Centrifuge Gearing, Spigot Flow) show "Needs centrifuge" until it is built.
8. **The second hive** becomes a goal when affordable (`HIVE_BUILD_COST_BASE`). Its pad was visible from step 1, so the player sees it coming ("the thrill of the next unlock").

### 2.2 Rules: gated, earned, lost, reset

| Thing | Gate | Earned / paid | Lost | On reset (Swarm Splitting) |
|---|---|---|---|---|
| Hive (first) | none | given | never | the new world starts with it again |
| Truck | none | given (lore: the queen's magic) | never | given again in each new world (lore holds per world; William) |
| Centrifuge | none (first build) | `CENTRIFUGE_BUILD_COST`, one-time | never in a run (no demolish in 0.4) | rebuilt, unless a Crystal starting upgrade pre-builds it (§2.5) |
| Jar crate (tier 1) | centrifuge built | `CRATE_BUILD_COST`, one-time | never in a run | rebuilt |
| Extra hives | a free hive pad; the centrifuge built | `HIVE_BUILD_COST_BASE × HIVE_BUILD_COST_GROWTH^(n)` | never in a run | Crystal "starting hives" option (GDD §1) |
| Raw comb sale | no centrifuge built | `RAW_COMB_PRICE_RATIO` × jar value | not offered once the centrifuge exists | — |

- **Build mode in 0.4** builds only: there is no move, no sell-back and no upgrade in place (those are 0.6, board 6's later rows).
- **The Shop is not locked** before the centrifuge (decision 1 option A). The raw-comb path is the safety net if the starting money goes to Worker Swarm Count first, so no soft lock exists.

### 2.3 Several hives: manual harvest

| Part | Rule |
|---|---|
| Fork icon | One per hive, anchored over that hive's lid (0.1.4 item 2 anchor-follow), showing its own meter and n/10 (`UI_DESIGN.md` rule 4). It shows when that hive is full, or while its own `resume_pending` holds (Back with Capped cells left). |
| Zoom | Tapping a hive's icon zooms on **that hive and the shared centrifuge**. With pads, each hive pad has its own `ZoomFraming` (Bob places one per pad), so GDD §2's "first zoom always keeps both in focus" still holds. Every farm icon hides in the zoom, as today. |
| Other hives during a zoom | They keep filling, as bottling and the truck do today. Their icons reappear when the zoom ends. A zoom never chains to the next hive by itself; the player taps the next icon. A "Next hive" button is a possible later step, not in 0.4. |
| Bucket and pile | Shared. Cells from any hive go to the one bucket, then the one pile. The bucket's capacity (`CENTRIFUGE_CAPACITY_FRAMES`) counts frames from any hive. |
| Spin | One Spin icon (one centrifuge), only on tap (0.2 spec item 9). The second stop is unchanged (centrifuge, crate, truck). Its "hive partly visible upper-right" is whichever hive pad sits there in Bob's layout. |
| Overflow buffer | **Per hive**: each hive keeps its own free one-hive buffer (GDD §2). This scales offline storage with hive count; Terry checks it against the 4 h free cap (§2.5). |
| Capacity pause | Per hive, as today. |
| Clutter at 720 × 1280 | With pads, the layout guarantees that fork icons' 120 × 120 touch areas, their n/10 labels, Spin and Sell never overlap at the default farm view. Hive pads are capped at as many as fit (Bob's layout sets the count; `HIVE_PAD_COUNT` records it). Quinn's 0.1.4 overlap check is extended to every fork icon with all hives full. No merging of icons (that would undo the designer's one-icon-per-hive rule). |

### 2.4 Automation across hives (decision 5)

| Option | Motor | Auto-scraper | For | Against |
|---|---|---|---|---|
| **A. Per farm (recommended)** | one (one centrifuge) | one purchase mounts a gantry on every hive, now and later; new hives come with it | one Shop row each; the capacity-pause rule ("both owned") stays one check; the post-automation bonuses stay as coded in 0.2 | extra hives get cheaper to run after automation; Terry prices hives with that in mind |
| B. Per hive | one | bought for each hive, cost growing | the *Factorio* feel: you automate hive by hive | the capacity pause ends hive by hive; one Shop row per hive or a Build › Open per hive; more UI |
| C. Per farm plus an install fee per new hive | one | as A, plus `AUTO_SCRAPER_INSTALL_COST` added to each later hive | keeps hive cost honest after automation | one more number and one more line on the price label |

**Recommendation: A.** In Build mode, tapping an automated unit offers **Open** to its zoom (`ui-screens.md` decision 4). That needs only Build mode, which now exists from 0.4, so the GDD §1 "UI TBD" is answered by 0.5 at no extra cost.

### 2.5 Interactions with other systems

- **Harvest (§2).** Unchanged once both machines exist. New: the no-centrifuge path (cells to the pile, the raw-comb sale), the no-crate path (bottling waits for the truck), and the per-hive fork icons and zoom framings. Today `main.gd` owns the zoom and frame queue for one hive found by name. Several hives means per-hive harvest state, which is the largest code change for Patricia (a risk, not a design rule).
- **Economy, Tree A.** Farm-wide, so each level is worth more per extra hive. Terry re-checks Swarm and Flight costs against hive count.
- **Economy, Tree B.** Gearing and Spigot Flow are gated on the centrifuge. Heated Fork works in the raw-comb harvest too (it is the fork's reach). Faster Delivery and Auto-Sell work before the crate. Auto-Sell with no crate means the truck leaves full and bottling waits; that is legal, but the crate should come first in Terry's pacing. Deep Frame (0.5) changes the zoom framing of every hive pad, not one.
- **Phase 2.** Still triggered by Auto-Sell (0.2 item 7). Building is not automation.
- **Build mode UI (board 6).** In 0.4 it holds only: the Build icon from the start, glowing pads with price labels, a buy confirm, locked text ("Needs centrifuge"), the pop-in and close. Board 6's land, move, upgrade in place, unit tiers, crate tiers and Refinery placement stay for later layers. `ui-screens.md` §1 "Build at the first land or unit purchase" becomes "Build from the start" (the designer's decision; update when that proposal is applied).
- **Onboarding (§7) and the guide.** The guide gains two beats: the first build (the centrifuge) before the first harvest, and the crate when bottling first waits for the truck. `content/onboarding-script.md` has four acts (welcome, uncapping, centrifuge, first upgrade). Act 3 describes the frame dropping into a wooden barrel centrifuge, which does not match the game's cells-to-the-bucket flow either. **William** rewrites Act 1 (the truck lore line, the centrifuge build) and adds the crate beat; Clara checks the result against the GDD. GDD §7's guide list gains "Guides the first build".
- **Story and lore (William).** The truck's origin uses the designer's words. William should also give one line on how the player builds (the player's own coins and hands, or the same leftover magic?). The lore says "the queen". One guide candidate is Queen Maeve, but the guide is still chosen by play-test, so the lore line must not assume the guide is the queen. Each new pocket world after a reset starts with a hive and a truck, so the line should hold for every world (§7 Reset Story).
- **Real-world facts (to check, not stated as fact).** "Raw comb sells low" is a **game rule**. In real markets, cut comb honey may sell at a *higher* price than extracted honey; this is unverified, and **Ruth / William must check it** before any guide or Journal line explains the price. Until then, text should give a game reason ("the truck's buyers want jars") and make no real-world claim.
- **Offline earnings (§6).** Per-hive overflow buffers mean more hives store more while offline. In Phase 1 the buffer, not the 4 h cap, limits offline earnings; Terry checks both with N hives.
- **Save and load (roadmap row 9).** It becomes required in 0.4: the built pads, each hive's frames and buffer, and any raw comb on the pile must persist. The save is versioned from this first format (roadmap §2.3).
- **Habitat (Tree C, later).** Hives bought in 0.4-0.6 exist before flowers and Hive Balance (0.7 under the new layering). Saves with several hives and no flowers will start Habitat at a low Health when Tree C arrives. Terry's Hive Balance values must expect that, and the Tree C spec needs a save migration rule.
- **Rush gap (Terry).** Starting money, build costs and early hive purchases add to the **fixed setup time** of every run. In Sunny Meadow they add the same amount to the rush and the normal route, so the rush gap barely moves. The risk is per biome: **if each new biome starts with its own empty yard** (its own centrifuge and crate to build), that adds to ΔF for every biome the normal route opens, and the rush skips it. That pushes the rush gap down (the rush relatively faster), mostly for new players. Terry should model ΔF with and without a per-biome yard before the Alpine spec. The per-biome yard question is for the Alpine proposal, not this one.
- **Starting upgrades (Crystals).** "Centrifuge and crate pre-built" is a natural whitelist candidate. GDD §1 forbids pre-buying only automation and the capstone, so this is allowed and shortens Phase 1 without skipping it. It joins `roadmap.md` question 3; it is not decided here.
- **Leaderboards (opt-in).** Run time starts at the new world's creation (§5), so the build steps count, equally for all players in the same content version. Changing `STARTING_MONEY` or the build costs after launch shifts every route's fixed time by the same small amount on a ~66 h run. That needs no new content version, but the change should be logged with the run-tracking fields so a ranked comparison across that change can be flagged. No paid booster is involved.
- **Dev mode.** Every tunable lives in config and is live in the Dev panel (placeholders err slow). New Dev toggles: "legacy start" (centrifuge and crate pre-built, as 0.3.0), "fill all hives", "+$100" (exists).

### 2.6 Impact table

| System | Effect | Risk |
|---|---|---|
| Harvest (§2) | no-centrifuge and no-crate paths; per-hive fork icon and zoom; shared bucket and pile | `main.gd` single-hive assumptions; a per-pad zoom framing to tune and test for every hive pad |
| Economy Tree A | farm-wide; worth more per hive | costs tuned for one hive become cheap with three |
| Economy Tree B | Gearing and Spigot Flow gated on the centrifuge | Auto-Sell before the crate stalls bottling; pacing must put the crate first |
| Automation (0.5) | motor once; auto-scraper per farm (if decision 5 = A) | hives get much cheaper to run after automation |
| Build mode (board 6) | exists from launch, build-only with pads | the free grid (0.6) must turn pads into reserved tiles without breaking saves |
| UI clutter (720 × 1280) | N fork icons + Spin + Sell + rail | solved by layout with pads; the real-phone touch check needs Android (row 16) |
| Onboarding (§7), guide | two new beats; Act 1 rewrite; Act 3 already out of date | the guide play-test (one of six) runs on a changed script |
| Lore (William) | truck origin; how the player builds | "the queen" vs the guide choice |
| Offline (§6) | buffer per hive | offline income grows with hive count in Phase 1 |
| Save (row 9) | required in 0.4 | the first save format has to carry pads and N hives |
| Habitat (Tree C) | hives exist before flowers | save migration when Hive Balance arrives |
| Rush gap, leaderboards | small equal shift in Meadow | a per-biome yard would lower the rush gap (Terry) |
| Roadmap | Build mode is layer 1; every later layer shifts by one version | the vertical slice moves from 0.9 to 0.10 (§2.7) |

### 2.7 Roadmap effect: rows 1-16 re-layered

Build mode becomes layer 1 (0.4). Automation becomes layer 2 (0.5). The grid's free placement becomes layer 3 (0.6). Rows 11, 13 and 14 split into a 0.4 part (pads) and a 0.6 part (free grid).

| # | Feature | Was | Now | Why |
|---|---|---|---|---|
| N1 | Start state: hive and truck, `STARTING_MONEY`, ghost pads | — | **0.4** | designer, 2026-11-10 |
| N2 | Raw comb: cells to the pile with no centrifuge, the raw-comb sale | — | **0.4** | designer, 2026-11-10 |
| N3 | Centrifuge and crate builds, build-order lock, Tree B "Needs centrifuge" gates, bottling waits with no crate | — | **0.4** | designer, 2026-11-10 |
| N4 | Several hives, manual: per-hive fork icon and meter, per-pad zoom framing, shared bucket and pile, per-hive buffer | — | **0.4** | designer, 2026-11-10 |
| N5 | Guide and lore text for the new beats (William, then Clara) | — | before the 0.4 spec | content, not a build row |
| 11a | Build mode v1: Build icon, pads, buy and pop-in (board 6, build only) | held → 0.5 | **0.4** | the blocker (multi-hive harvest) is answered here |
| 13a | Extra Langstroth hives on hive pads | 0.5 | **0.4** | |
| 14a | Jar crate tier 1 as a build | 0.5 | **0.4** | tier 1 is today's crate |
| 9 | Save and load; offline at 4 h; Welcome back | 0.4 | **0.4** (now required) | the built farm must persist |
| 16 | Android export | 0.5 | **0.4** (recommended) | several fork icons need a real-phone touch check |
| 1 | Long Fork | 0.4 | 0.5 | automation layer |
| 2 | Centrifuge motor | 0.4 | 0.5 | its "UI TBD" is answered by Build › Open, which needs 11a |
| 3 | Auto-scraper | 0.4 | 0.5 | per farm or per hive: decision 5 |
| 4 | End of the capacity pause; post-automation bonuses | 0.4 | 0.5 | |
| 5 | Deep Frame | 0.4 | 0.5 | now re-frames every hive pad's zoom |
| 6 | Artisanal Branding | 0.4 | 0.5 (could ride in 0.4) | independent, S |
| 7 | Spigot Flow | 0.2.1 | 0.2.1 | unchanged |
| 8 | Overflow Storage | 0.4 | 0.5 | per-hive buffer (§2.3) |
| 10 | Heated Fork clean cut | held → 0.4 | held → 0.5 | still undefined |
| 11b | Free placement, move, pan and zoom over a larger farm | held → 0.5 | 0.6 | pads become reserved tiles (decision 4) |
| 12 | Land expansion | 0.5 | 0.6 | |
| 13b | Flower units; hives placed freely | 0.5 | 0.6 | |
| 14b | Jar crate tiers 2-3 | 0.5 | 0.6 | |
| 15 | Bee rendering plan | 0.5 | 0.6 | 0.4's few hive pads fit today's MultiMesh; Quinn checks FPS with every pad full |

Rows 17 onward each move one version: habitat 0.7, research 0.8, capstone 0.9, reset 0.10 (the **vertical slice moves from 0.9 to 0.10**), Alpine 0.11, feel 0.12, Royal Jelly 0.13, launch services 0.14-0.15. Rough cost of the new 0.4: L (~35-100 goal-agent runs). Multi-hive harvest state and save/load are the bulk. The roadmap file is revised by the orchestrator once this proposal is decided; Gerard does not edit it.

## 3. Parameters for the next agent (Terry)

Names only; no values. Placeholders err slow until Terry's run.

1. `STARTING_MONEY`: money on first launch. Must be at least `CENTRIFUGE_BUILD_COST`; any surplus is the player's first free choice.
2. `CENTRIFUGE_BUILD_COST`: one-time cost of the centrifuge.
3. `CRATE_BUILD_COST`: one-time cost of the tier 1 jar crate. Sets how many sales pass with bottling waiting for the truck.
4. `RAW_COMB_PRICE_RATIO`: raw comb's sale value as a share of `JAR_BASE_PRICE` per jar-equivalent. Low enough that building the centrifuge is clearly better, high enough that a player who spent the start money is never stuck.
5. `RAW_COMB_TRUCK_SPACE`: truck bed room one jar-equivalent of raw comb takes, relative to one jar (sets the size of one raw-comb load).
6. `HIVE_BUILD_COST_BASE`, `HIVE_BUILD_COST_GROWTH`: cost of the second and later hives (the exponential cost model, §3).
7. `HIVE_PAD_COUNT`: hive pads in 0.4. The ceiling is set by Bob's layout (icons that fit at 720 × 1280); Terry chooses whether the economy wants all of them.
8. `OVERFLOW_HIVES_PER_HIVE`: buffer per hive (today 1), re-checked against the 4 h offline cap with N hives.
9. `CENTRIFUGE_CAPACITY_FRAMES`, `TRUCK_CAPACITY_JARS`, `TRUCK_TRIP_SECONDS` (from the roadmap's 0.4 list): re-checked for one centrifuge and one truck serving N hives.
10. `AUTO_SCRAPER_COST` (per farm), or `AUTO_SCRAPER_COST_PER_HIVE` and growth (if decision 5 = B), or `AUTO_SCRAPER_INSTALL_COST` (if C).
11. Pacing targets to calibrate, as minutes into the first session: `TIME_TO_CENTRIFUGE`, `TIME_TO_CRATE`, `TIME_TO_SECOND_HIVE`, and the existing Auto-Sell point (about 12 min, `first-automation-values.md`), re-checked now that the build costs come first.
12. Rush-gap input: the per-biome fixed setup time ΔF with and without a per-biome yard (§2.5), before the Alpine spec.

Look and timing values (pop-in seconds, ghost alpha, pad label offset) are Patricia's config values, not Terry's.

## Decisions needed from the designer

Each item is a question for the quiz, with options and a recommendation. Before the 0.4 spec, William's text (N5) and Terry's run (§3) are also needed, and Ruth/William must check the raw-comb price claim (§2.5).

1. **How do "the starting money builds the centrifuge" and "raw comb before the centrifuge" fit together?**
   - A. The hive starts empty; `STARTING_MONEY` covers the centrifuge; the Shop is open from the start. Raw comb happens only if the player harvests before building (or spends the money elsewhere first), so it is a safety net. **(recommended)**
   - B. As A, but the Shop is locked until the centrifuge is built, so the money cannot be misspent; raw comb happens only if the player harvests before building.
   - C. The hive starts full: the guide's first beat is a raw-comb harvest and sale, then the build, so every player feels the price difference.
2. **How is raw comb harvested?**
   - A. The normal scrape; cells fly to the pile beside the empty centrifuge pad; a "Sell raw comb" pill over the truck sells the pile. If the centrifuge is built first, the pile loads into it at full value. **(recommended: reuses the pile, teaches uncapping once)**
   - B. One drag cuts a whole frame's comb out (no scrape), straight onto the truck; a new gesture, closer to cut comb, but it takes the Long Fork's one-sweep moment early.
3. **Where do jars go before the crate exists?**
   - A. Onto the truck while it is home; while it is away, bottling waits and the honey stays in the bucket (cells pile up). The crate then has an obvious job. **(recommended)**
   - B. Jars stand on the ground beside the spigot up to a small cap and load when the truck returns; smoother, but it needs a new jar row and makes the crate less needed.
4. **What does the player build on in 0.4?**
   - A. Fixed build pads (centrifuge, crate, a few hive pads around the centrifuge); the free grid comes in 0.6 and the pads become reserved tiles. **(recommended)**
   - B. A grid from 0.4, with hives anywhere inside a harvest ring around the centrifuge.
   - C. A free grid for everything from 0.4, with framing computed per placement (largest build; breaks "first zoom keeps both in focus" for distant hives).
5. **With several hives, are the motor and the auto-scraper bought per farm or per hive?**
   - A. Per farm: one motor, one auto-scraper that equips every hive, now and later. **(recommended)**
   - B. Per hive: an auto-scraper for each hive, with growing cost.
   - C. Per farm, plus a small install fee for each hive added after it.

Accepting this proposal also accepts the roadmap shift in §2.7 (the vertical slice moves to 0.10) and the GDD edits it implies: §2 "the farm holds the hive, a centrifuge…" becomes the start state plus builds, with the raw-comb and no-crate rules; §2 Start becomes "one fork icon per hive"; §3 Tree B gates; §4 build pads; §7 lore and the guide's first build; §9 Build mode from the start; Glossary "Raw comb" and "Build pad". The proposals index needs a rebuild (`python -I _tools/index.py proposals/design`); this run had no shell to run it.

## Designer's answers (2026-11-10, quiz)

1. **A**: the hive starts empty, `STARTING_MONEY` covers the centrifuge, the Shop is open; raw comb is a safety net.
2. **A**: raw comb by the normal scrape to the pile, sold by a "Sell raw comb" pill; a centrifuge built first loads the pile at full value.
3. **B** (not the recommendation): before the crate, jars stand on the ground beside the spigot up to a small cap and load when the truck returns; the crate is the bigger buffer.
4. **C** (not the recommendation): a free grid from 0.4. Designer's note: "centrifuge placements are close to the hive". Follow-up answer: a centrifuge must sit **within N tiles of a hive** and serves every hive in that range (hives out of range need their own centrifuge); **the range scales with Flight Endurance** (designer's note). So "Build pad" and the fixed-pad layout drop; per-placement zoom framing is in scope.
5. **B, tentative**: motor and auto-scraper per hive, with growing cost. Designer's note: "am unsure if it should be farm wise or per unit wise". Terry models per farm vs per unit before the 0.5 spec; the designer decides on his numbers.
6. **New (designer's note on 4): bigger centrifuges are separate units** bought in Build mode that replace the old one on the same spot, like the GDD's hive tiers (e.g. hand centrifuge 2 frames → barrel 4 → radial extractor 8), giving room for the Deep Frame and later upgrades. Separate from Gearing (crank) and Spigot Flow (bottling).

Still needed before acceptance: Gerard revises §1.1, §2.1–2.7 to these answers (free grid, ground jars, centrifuge range and tiers, per-hive automation pending Terry); the GDD edits listed above change accordingly ("Build pad" leaves the Glossary; "centrifuge range" and centrifuge tiers join §4).
