---
author: terry
type: balance
status: applied
decided: 2026-11-22
decision: $40 x 1.25 per patch, Health 10 + 15 per patch to 100 over six slots, no Auto-Sell gate on patches; applied as provisional values to GDD Tree C (First slice) on 2026-11-23
description: Provisional 0.3.0 course-ending values - Habitat Health 10 -> 100 in six $40 x 1.25 patches ($449 in all), victory at about 25 min for a normal player (Auto-Sell at 14 min), never before a normal player's Auto-Sell, 4 s delay
---
# Course ending: Habitat Health, patch costs and victory timing (0.3.0, provisional)
**Sources:** `GDD.md` (§3 Tree C Flower Patches and Hive Balance; Progression Trees "Target run length"; Glossary rows Equal for veterans, Throughput cap, Habitat Health), `proposals/design/course-ending.md` (§2.2 rules, §2.4, §3 parameters, Designer decisions 2026-11-22), `proposals/balance/first-automation-values.md` (bottleneck model A10, assumptions A1-A11, §4.2 rush-gap table), `proposals/balance/refinery-parameters.md` (§2 run model, rush gap and κ only, as reused in the report above), `proposals/balance/native-species-balance.md` (raw Habitat Health scale, by grep), `game/specs/0.2-first-automation.md`, `game/scripts/default_config.tres`, `game/scripts/bees.gd` (by grep), `_meta/memory/dev-mode-and-pacing.md`. Model scripts (throwaway): `game/reports/_runs/terry-course-ending/ce_sim.py`, `ce_tables.py`.
**Trigger:** Orchestrator for the designer, 2026-11-22: set the provisional values for the accepted course-ending design (option B). Patches raise habitat only, the build is save-free, a skip icon exists for graders, and victory should come after Auto-Sell within one normal sitting. Placeholders err slow.

---

## Summary

| Config key | Value | Why |
|---|---|---|
| `habitat_health_start` | **10** | A 0-100 meter that starts nearly empty: "a world that needs restoring" (§7) |
| `habitat_health_per_patch` | **15** | Six patches take 10 to 100 exactly |
| `habitat_thriving` | **100** | Thriving means a full meter, so no number needs explaining |
| `habitat_health_max` | **100** | Equal to thriving (allowed by the design, §3 item 4). The row maxes at the same moment |
| `patch_slots` | **6** | = ceil((100 − 10) / 15) = 6, the reachability rule in design §2.2. Bob places six slots |
| `patch_base_cost` | **$40** | Costs $40, 50, 62, 78, 97, 122 (floored), **$449 in all** |
| `patch_cost_growth` | **1.25** | Between Swarm (1.18) and Faster Delivery (1.30) |
| `victory_target_minutes` | **25** | Model: normal player 24.8 min at η = 0.8 (Auto-Sell at 14.0 min) |
| `victory_delay_seconds` | **4.0** | Grow-in, bees reaching the new patch, and the bumble bee toast read before the overlay |

| Player (η = 0.8) | Auto-Sell | Victory |
|---|---|---|
| A. Normal: upgrades to Auto-Sell, then patches | 14.0 min | **24.8 min** |
| B. Mixed: alternates patches with income upgrades after Auto-Sell | 14.0 | 28.2 |
| C. Plants one patch early out of curiosity, then as A | 15.5 | 25.3 |
| D. Rusher: patches only, no upgrades | never | 18.7 |
| E. Cheap fill upgrades, then patches, no automation | never | **16.5** (fastest possible here) |

**Standing checks:** rush gap G at 0 / 20 / 50 / 150 Crystals = 1.215 / 1.173 / 1.121 / 1.004, unchanged. κ unchanged, because jar intake does not change (§4). Target run length unaffected.

**Main finding:** in the 0.2 build as shipped (no Branding, no motor), income levels off at about $42-48/min by minute 8. After that, upgrades pay back slowly, so a player who skips automation and buys patches always wins sooner than one who buys it (E 16.5 vs A 24.8 min). This can't be tuned away with patch costs alone. What the costs can guarantee is the floor: **no player can reach thriving before a normal player owns Auto-Sell** (16.5 > 14.0 min). That floor is what sets the $449 total.

## 1. Assumptions

Config values used (`default_config.tres`, live 0.2): `base_seconds_per_jar` 6.0, `sale_value_per_jar` 3, `taps_per_jar` 4, `centrifuge_capacity_frames` 2 (4 jars per bucket), `bottling_seconds_per_jar` 3.0, `truck_capacity_jars` 10, `truck_trip_seconds` 30. Rows: Swarm $25 × 1.18 (+15% fill), Flight $15 × 1.15 (+10%), Heated Fork $40 × 1.22, Gearing $35 × 1.20 (−15% turns), Spigot Flow $30 × 1.20 (**−8%** bottling per level in config; the spec says 0.12, see Risks), Faster Delivery $60 × 1.30, Auto-Sell $250 at Delivery 1. None of these is changed.

| # | Assumption | Effect |
|---|---|---|
| A1-A7, A10, A11 | As in `first-automation-values.md` §1: fill = (1 + 0.15S)(1 + 0.1F)/6 jars/s, crank at 4 taps/s, serial centrifuge (spin, then bottle 4 jars), truck 10 jars per 30(1 − 0.15D) s, one station, income = price × η × min(stages) | Same bottleneck model, reused unchanged |
| B1 | **The 0.2 build has no Branding, motor, Long Fork or scraper.** Price stays $3 per jar, and the harvest stays manual all game | Income is lower than in the 0.2 report: Auto-Sell comes at 14.0 min, not 12.0 |
| B2 | Attention η = 0.8 for the whole run (A8). Auto-Sell gives no η bonus in the model | Errs slow: Auto-Sell shows up as cost only. Every time scales with 0.8 / η |
| B3 | Patches do not change fill: `bees.gd` only uses `flower_patch` as flight targets, and the fill rate comes from config (decision 2) | Jar intake is unchanged, so κ is too (§4) |
| B4 | Scripted buy orders (`ce_sim.py`): A = Flight, Swarm, Flight, Swarm, Spigot, Gearing, Swarm, Spigot, Delivery 1, Auto-Sell, then the six patches | A sensible player, not an optimal one |
| B5 | Victory time is measured from Play, with the welcome overlay holding the world idle (design §2.3) | The time spent on the title screen doesn't count |
| B6 | `victory_delay_seconds` counts only after the conditions in design §2.2 are met (farm view, nothing open) | Delays the overlay, not thriving itself |

**Model extension:** none to the `refinery-parameters.md` §2 hour-scale model, because the slice adds no Refinery, route or Crystal. The minute-scale A10 model is re-run on the shipped 0.2 rows, with a patch row added as a pure money sink.

## 2. Model

### 2.1 Income in the shipped 0.2 build (`ce_tables.py`)

| State | Binding stage | Jars/s | $/min (η 0.8) |
|---|---|---|---|
| Start (S0 F0) | fill | 0.167 | 24.0 |
| S3 F2 G1 P2 (minute 8, A) | fill 0.290 vs chain 0.295 | 0.290 | 41.8 |
| G2 P2 chain cap | chain | 0.306 | 44.0 |
| G5 P5 chain cap (all bottling buys, about $380 more) | chain | 0.488 | 70.2 |

Chain cap example: G1 has ceil(16 × 0.85) = 14 turns / 4 = 3.5 s; P2 has 4 × 3.0 × 0.84 = 10.08 s; 4 / 13.58 = 0.295 jars/s. Fill passes the chain at about Swarm 3 + Flight 2, so the next income needs Spigot and Gearing in pairs. Each pair adds only about $2-3/min for about $85.

### 2.2 Timeline, player A (η 0.8, `ce_sim.py 40 1.25 6 -v`)

| Buy | Cost | Minute | $/min before |
|---|---|---|---|
| Flight 1, Swarm 1, Flight 2, Swarm 2 | 15, 25, 17, 29 | 0.6-3.0 | 24.0-30.4 |
| Spigot 1, Gearing 1, Swarm 3, Spigot 2 | 30, 35, 34, 36 | 3.8-6.6 | 33.1-37.4 |
| Faster Delivery 1 | 60 | 8.0 | 39.6 |
| **Auto-Sell** | 250 | **14.0** | 41.8 |
| Patch 1-6 | 40, 50, 62, 78, 97, 122 | 15.0, 16.2, 17.6, 19.5, 21.8, **24.8** | 41.8 |

Arithmetic: $449 / $41.8 per minute = 10.7 min after Auto-Sell, so 14.0 + 10.7 = 24.8 min. Player B buys income upgrades between patches. Because of the chain cap they don't pay back in time, so B is slower (28.2).

### 2.3 Why $449 in all: the "not before Auto-Sell" floor

- The fastest route to thriving is E: Flight 1-2 and Swarm 1-3 ($120), plus Spigot 1 ($30), then patches.
- E must not win before player A's Auto-Sell at 14.0 min. The sim gives this floor:

| Patch total | Curve | E victory | A victory | Margin over Auto-Sell |
|---|---|---|---|---|
| $391 | $35 × 1.25 | 15.0 | 23.4 | 1.0 min |
| $395 | $40 × 1.20 | 15.1 | 23.5 | 1.1 min |
| **$449** | **$40 × 1.25** | **16.5** | **24.8** | **2.5 min** |
| $430 | $30 × 1.35 | 16.0 | 24.3 | 2.0 min |
| $436 | $50 × 1.15 | 16.1 | 24.5 | 2.1 min |

- $449 keeps a 2.5-minute margin, which covers the gap between scripted and real play (errs slow). Below about $350 (extrapolated), a fill-only player wins before a normal player gets automation.
- **Curve shape:** 1.25 makes the first patch affordable at about 1.7 min of base income ($40 / $24). A player sees the row work early (player C loses only 0.5 min), while the last patch ($122) costs half of Auto-Sell. A flat curve ($50 × 1.15) gives the same totals but a duller first buy. A steep one ($30 × 1.35) makes the sixth patch ($134) a wall.

### 2.4 How patches compete with Tree A/B and the truck

| Row | First cost | Total to max | Patch total as a share |
|---|---|---|---|
| Plant wildflower patch (6) | $40 | **$449** | - |
| Flight Endurance (10) | 15 | 299 | 150% |
| Spigot Flow (5) | 30 | 222 | 202% |
| Gearing (5) | 35 | 259 | 173% |
| Swarm (10) | 25 | 583 | 77% |
| Heated Fork (5) | 40 | 307 | 146% |
| Faster Delivery (4) + Auto-Sell | 60 + 250 | 620 | 72% |
| All Tree A/B + truck | - | 2,290 | 20% |

- The first patch costs the same as Heated Fork 1 and a little more than Gearing 1, so it sits in the middle of the early prices.
- Restoring the whole meadow costs about 1.8 × Auto-Sell, or 20% of all the 0.2 upgrades. A player who wins at 25 min has bought about $980 in all: $531 of upgrades and $449 of patches (§2.3). That leaves most of Tree A/B for after victory, as design §2.5 wants ("keep playing").

### 2.5 Sensitivity to attention (times × 0.8 / η)

| η | A Auto-Sell | A victory | B victory | E victory |
|---|---|---|---|---|
| 0.6 (distracted) | 18.7 | 33.0 | 37.6 | 22.0 |
| 0.8 (model) | 14.0 | 24.8 | 28.2 | 16.5 |
| 1.0 (focused) | 11.2 | 19.8 | 22.5 | 13.2 |

- Every case ends within one sitting: 20-38 min. The skip icon covers graders who play for less time.
- The order "never before Auto-Sell" holds at every η, because it is a ratio.

## 3. Provisional values

| Key | Value | Notes |
|---|---|---|
| `habitat_health_start` | 10 | Integer meter, shown as "10" or "10%" (Bob/William) |
| `habitat_health_per_patch` | 15 | Steps of 10, 25, 40, 55, 70, 85, 100 |
| `habitat_thriving` | 100 | Triggers the visitor and the victory queue |
| `habitat_health_max` | 100 | The meter's top. Clamp Health to it |
| `patch_slots` | 6 | Must satisfy `slots ≥ ceil((thriving − start) / per_patch)`. Quinn tests this rule against the config |
| `patch_base_cost` | 40.0 | Cost = floor(40 × 1.25^planted) |
| `patch_cost_growth` | 1.25 | |
| `victory_target_minutes` | 25 | A target for play-test calibration, not read by game logic |
| `victory_delay_seconds` | 4.0 | Errs slow. 0 in tests that are about the victory itself |

Every key is in `default_config.tres` and live in the Dev panel (design §2.6). These are **slice values**. They must not be copied into the GDD as Tree C values. In 0.6 the raw Habitat Health scale of `native-species-balance.md` takes over (10 raw HH = 1 Synergy level; Meadow bumble visitor at raw 40), and these numbers are re-derived then.

## 4. Standing checks

### 4.1 Target run length (GDD: about 66 h to the first Royal Crystal at launch)
- The slice adds a $449 sink in the first 25 minutes and no Crystal, Refinery or route. That is far below the hour-scale model's resolution, and the victory is not a run end (design §2.4).
- The run length is unaffected.

### 4.2 Rush gap (G = T_R / T_N; T_N = 3 + 69/M, T_R = 2 + 85.5/M, M = 1 + 0.1n, the stand-in table of `first-automation-values.md` §4.2)

| Crystals n | M | T_N (h) | T_R (h) | G |
|---|---|---|---|---|
| 0 | 1 | 72.00 | 87.50 | 1.215 |
| 20 | 3 | 26.00 | 30.50 | 1.173 |
| 50 | 6 | 14.50 | 16.25 | 1.121 |
| 150 | 16 | 7.31 | 7.34 | 1.004 |

- Unchanged. The patch row is route-neutral and gives no production, and the slice has no reset.
- At n = 150, G = 1.004 is inside the "Equal for veterans" band (0.95-1.05).
- **For 0.6:** once patches feed Habitat Synergy, their price sets how cheaply the rush meets its habitat minimum. Re-check G then.

### 4.3 Throughput cap κ (16 × J_ref)
- Jar intake does not change: patches give no fill bonus (decision 2, B3).
- So κ needs no re-derivation. The station-cap finding of the 0.2 report still stands (the chain caps one station at 0.488 jars/s at G5 P5 with the config's 0.08 Spigot cut).

## Risks
- **Skipping automation is the fastest win (largest).** Upgrades pay back slowly once the chain cap binds at about $42-48/min, so player E wins 8 min before player A. The costs guarantee only that no one wins before a normal player's Auto-Sell. If the designer wants automation to be *required*, that needs a rule (for example, gating patches 4-6 behind Auto-Sell), not a price (Decision 2).
- **Assumption A5 (serial centrifuge) is still unconfirmed.** If bottling overlaps the next spin, the chain cap rises, upgrades pay back better, and A's victory moves earlier (about 22-23 min; estimated, not simulated). E barely moves, because it is fill-bound.
- **Spigot cut mismatch:** the config has `spigot_flow_cut_per_level = 0.08`, and the spec item 12 says 0.12. This report uses the config. At 0.12, A's Auto-Sell and victory come about 0.3-0.5 min earlier (estimated, not simulated).
- **η is a guess.** No 0.2 play-test time has been recorded (calibration point 5 of the 0.2 report is still open). If the designer reaches Auto-Sell at about 12 min, η ≈ 0.93 and victory comes at about 21 min.
- **A 100 meter that ends at thriving** leaves no room above it. If 0.6 wants "thriving" below the top, the max and the slots change then. Nothing carries over, because there is no save.

## Decisions needed from the designer
1. **Accept the slice values:** Health 10 → 100 in six patches of +15, thriving = max = 100, 6 slots, patches $40 × 1.25 ($449), delay 4 s, target 25 min? The faster alternative is $35 × 1.25 ($391, victory about 23.4 min), which leaves only a 1-minute margin before a fill-only player beats Auto-Sell.
2. **Is "never before a normal Auto-Sell" enough**, or must the player own automation to win? If the latter, add a gate (for example, patch 4 needs Auto-Sell). Gerard's design keeps the row ungated so a grader can always finish. With the skip icon that matters less.
3. **Spigot Flow cut:** confirm 0.08 (config) or 0.12 (spec item 12) before 0.3.0. The times above move by less than 0.5 min either way.
4. **Calibration:** in the first 0.3.0 play-test, time Play → Auto-Sell and Play → thriving. If thriving comes after 30 min, lower `patch_cost_growth` to 1.20 first ($395). If it comes before Auto-Sell, raise `patch_base_cost`.
5. **Before final:** Patricia confirms A5 (serial centrifuge). In 0.6, Terry re-derives every value here on the raw Habitat Health scale and re-checks the rush gap with patches feeding Synergy.
