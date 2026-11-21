---
author: terry
type: balance
status: applied
decided: 2026-11-09
decision: values adopted as provisional; Heated Fork +4%/level after automation; Auto-Sell before the auto-scraper; Gearing does not speed bottling (spigot flow-rate upgrades will, after 0.2)
description: Provisional 0.2 "First automation" values: post-automation Heated Fork and Gearing, costs and gates of motor, Faster Delivery, Auto-Sell, Long Fork and auto-scraper
---
# First Automation Values (milestone 0.2, provisional)
**Sources:** `GDD.md` (§3 Tree A and Tree B, lines 89-106; Glossary rows "Equal for veterans" and "Throughput cap", by grep), `proposals/balance/harvest-upgrade-paths.md` (adopted structure and parameter names), `proposals/balance/refinery-parameters.md` (§2.2 rush-gap table and κ row only), `game/scripts/default_config.tres` (economy keys, by grep). Model script: `game/reports/_runs/terry-first-automation/fa_sim.py` (throwaway; `fa_sim2.py` runs a variant).
**Trigger:** Milestone 0.2 "First automation" needs provisional numbers for the TBD values in Tree B. A playtester must reach the truck automation (Auto-Sell) within about 10-15 minutes from a fresh start; placeholders err slow.

---

## Summary

| Config key | Value | Reached at (model, η = 0.8) |
|---|---|---|
| `heated_fork_post_auto_yield_bonus_per_level` | **0.04** (L1-5: +4, +8, +12, +16, +20% yield) | - |
| `gearing_post_auto_time_cut_per_level` | **0.08** (L1-5: −8, −16, −24, −32, −40%) | - |
| `gearing_post_auto_cut_includes_bottling` | **true** (recommended; Decision 2) | - |
| `centrifuge_motor_cost` (one-time) | **$150** | **7.9 min** (first automation, Phase 2) |
| `motor_unlock_gearing_level` | **2** | 5.8 min |
| `motor_spin_seconds_per_bucket` | **3.0** | - |
| `faster_delivery_base_cost` / `_cost_growth` / `_max_level` | **$60 / 1.30 / 4** | L1 at 9.6 min |
| `faster_delivery_trip_cut_per_level` | **0.15** of `truck_trip_seconds` (30 → 25.5 → 21 → 16.5 → 12 s) | - |
| `auto_sell_cost` (one-time) | **$250** | **12.0 min** (truck automation) |
| `auto_sell_unlock_delivery_level` | **1** | - |
| `long_fork_cost` (one-time) | **$200** | ≤ 15.7 min |
| `long_fork_unlock_heated_level` | **3** | ≤ 13.8 min |
| `long_fork_seconds_per_frame` | **1.0** (assumption, one sweep) | - |
| `uncap_apparatus_cost` (auto-scraper, one-time) | **$400** | ≤ 19.9 min (capacity pause ends) |
| `uncap_apparatus_unlock` | owns Long Fork | - |
| `apparatus_seconds_per_frame` | **3.0** | - |

**Standing checks:** rush gap G at 0 / 20 / 50 / 150 Crystals = 1.215 / 1.173 / 1.121 / 1.004 before, and the same or slightly higher after (never faster; §4.2). κ needs no change, but one new finding is that the harvest chain caps intake per station (§4.3). Run length is not affected at the 66 h scale. The early income curve is not yet tied to it.

**Main finding:** bottling (`bottling_seconds_per_jar = 3.0`) caps the whole chain at 0.25-0.33 jars/s. By minute 15-20, Swarm, Flight and the Heated Fork yield bonus add nothing unless the post-automation Gearing cut also speeds bottling (Decision 2).

## 1. Assumptions

Config values used (`default_config.tres`): `base_seconds_per_jar` 6.0, `frames_per_hive` 5, `frame_jars` 2 (10 jars per hive), `sale_value_per_jar` 3, `taps_per_jar` 4, `max_tap_rate` 5.0, `centrifuge_capacity_frames` 2 (a bucket = 4 jars), `bottling_seconds_per_jar` 3.0, `truck_capacity_jars` 10, `truck_trip_seconds` 30.0, `swarm_*` (0.15, $25, 1.18, max 10). GDD values: Flight Endurance $15 / 1.15x / +10%; Branding $60 / 1.25x / +$2.50; Heated Fork $40 / 1.22x / max 5; Gearing $35 / 1.20x / max 5 / −15%. None of these is changed.

| # | Assumption | Why / effect |
|---|---|---|
| A1 | Fill rate = (1 + 0.15·Swarm)(1 + 0.10·Flight) / 6 jars/s | Flight speed shortens bee trips, so it is treated as a multiplier on fill |
| A2 | Manual Gearing cuts spin time additively: × (1 − 0.15·G) | GDD text "−15% per level". Only G ≤ 2 matters before the motor |
| A3 | Manual uncap: 3.0 s per frame at Heated 0, divided by (1 + 0.12·H). Long Fork: 1.0 s per frame | Wider swipe means fewer strokes. **Assumed; not in config** |
| A4 | Manual crank at a relaxed 4 taps/s: 4 jars × 4 taps / 4 = 4.0 s per bucket | Below `max_tap_rate` 5; errs slow |
| A5 | **The centrifuge is serial:** spin a bucket, then bottle its 4 jars (12 s), then accept the next bucket. Uncapping runs in parallel | The worst case for throughput. Patricia should confirm the code. If bottling overlaps the next spin, the chain cap is 0.333 jars/s instead (§2.2) |
| A6 | `truck_trip_seconds` is the round trip; the truck carries 10 jars per trip | Truck throughput = 10 / trip |
| A7 | Per-hive player overhead: 6 s (zoom, lids, frame rise), 2 s Sell tap, 5 s to notice a full hive | Sets the manual ceiling. It does not bind before minute 15 |
| A8 | Attention factor η = 0.8 on all income until motor, scraper and Auto-Sell are all owned | A playtester who sometimes looks away. Errs slow. All times scale exactly by 0.8 / η |
| A9 | Scripted buy order (§2.3), a sensible but not optimal player | A min-maxer is faster; that is the safe direction |
| A10 | Income = price × η × min(fill × yield, centrifuge chain, truck, player) | The model is a bottleneck model. Overflow buffers smooth bursts but do not change the steady rate |
| A11 | One harvest station (one hive, centrifuge, crate, truck), as in 0.1 | Multi-hive scaling is still an open gap (harvest-upgrade-paths §3.1.5) |

**Model extension.** The `refinery-parameters.md` §2 run model has no harvest-chain stage (harvest-upgrade-paths §3.3). This report adds one only for the first 20 minutes: a per-second bottleneck model, A10. It does not feed the §2 hour-scale model. That waits for the reference sims (refinery-parameters item 6).

## 2. Model

### 2.1 Throughput of each stage (jars/s)

| Stage | Formula | Values |
|---|---|---|
| Fill | (1 + 0.15S)(1 + 0.1F) / 6 | S0: 0.167; S3: 0.242; S3 F1: 0.266; S5 F1: 0.321; S10 F0: 0.417 |
| Centrifuge, manual | 4 / (4.0(1 − 0.15G) + 12) | G0: 0.250; G1: 0.260; G2: 0.270 |
| Centrifuge, motor (recommended cut) | 4 / ((3.0 + 12)(1 − 0.08G)) | G2: 4 / 12.6 = **0.317**; G5: 4 / 9.0 = **0.444** |
| Centrifuge, motor (spin-only cut) | 4 / (3.0(1 − 0.08G) + 12) | G2: 0.278; G5: 0.303 |
| Truck | 10 / (30(1 − 0.15D)) | D0: 0.333; D1: 0.392; D2: 0.476; D3: 0.606; D4: 0.833 |
| Scraper | 4 / (2 × 3.0) | 0.667 (never binds) |

### 2.2 What the motor and Gearing values do

- **The motor at 3.0 s per bucket** beats the relaxed hand crank at the unlock level (G2 manual: 4.0 × 0.70 = 2.8 s; motor at G2: 3.0 × 0.84 = 2.52 s). At 4.0 s the motor made the chain *slower* (first run: 0.263 vs 0.270 jars/s), so 3.0 is the highest value that does not punish the buy.
- **Gearing after automation, 0.08 per level.** If the cut applies to spin only, Gearing L5 lifts the chain from 0.267 to 0.303 jars/s, which is +14%, and bottling still caps it. If it applies to the whole extraction (spin + bottling), it lifts the chain to 0.444 (+67%). Faster Delivery then matters (the truck at D0, 0.333, becomes the cap), and fill upgrades keep their value. 0.08 rather than 0.10 keeps the G5 chain (0.444) near the truck at D2 (0.476), so neither line makes the other pointless. It also errs slow.
- **Heated Fork after automation, 0.04 per level.** Speed means nothing once the scraper uncaps, so the flat yield must carry the line's value. Here is a value-per-dollar check against Swarm, while fill-bound and at a typical post-automation Swarm level of 6:
  - Swarm L6: +0.15 / 1.75 = +8.6% for $57.2 = **0.150 %/$**.
  - Heated L1: +4% for $40 = **0.100 %/$**. Heated L5: +0.04 / 1.16 = +3.4% for $88.6 = **0.039 %/$**.
  - Swarm L10: +0.15 / 2.35 = +6.4% for $111.6 = **0.057 %/$**.
  
  So Heated stays a secondary line: worth about two-thirds of Swarm at L1, and about the same as late Swarm at L4-L5. It never overtakes Swarm. At L5 (+20%) it is above the manual clean-cut maximum (+5%), on purpose, to replace the lost speed value. 0.03 is the slower alternative (+15% at L5).

### 2.3 Timeline from a fresh start (`fa_sim.py`, motor 3.0 s, spin-only Gearing cut)

| Buy | Cost | Minute | Income before the buy ($/min) | Binding stage |
|---|---|---|---|---|
| Swarm 1 | 25.0 | 1.04 | 24.0 | fill 0.167 |
| Branding 1 | 60.0 | 3.22 | 27.6 | fill |
| Swarm 2 | 29.5 | 3.80 | 50.6 | fill |
| Flight 1 | 15.0 | 4.06 | 57.2 | fill |
| Gearing 1 | 35.0 | 4.62 | 62.9 | fill |
| Swarm 3 | 34.8 | 5.17 | 62.9 | fill |
| Gearing 2 (motor gate) | 42.0 | 5.78 | 68.6 | centrifuge 0.260 |
| **Motor** | 150.0 | **7.92** | 70.2 | fill 0.266 |
| Branding 2 | 75.0 | 8.99 | 70.2 | fill |
| Faster Delivery 1 (Auto-Sell gate) | 60.0 | 9.58 | 102.1 | fill |
| **Auto-Sell** | 250.0 | **12.03** | 102.1 | fill |
| Swarm 4, Heated 1-3 (Long Fork gate) | 41.1 + 40 + 48.8 + 59.5 | 13.82 | 102.1-106.7 | centrifuge 0.278 |
| Long Fork | 200.0 | 15.69 | 106.7 | centrifuge |
| Swarm 5, Branding 3 | 48.5 + 93.8 | 17.03 | 106.7 | centrifuge |
| **Auto-scraper** (pause ends) | 400.0 | **19.88** | 140.0 | centrifuge 0.278 |
| (after) | - | - | 175.0 | centrifuge 0.278 (fill 0.359 wasted) |

Example arithmetic for the motor: after Gearing 2 at 5.78 min, the player holds ≈ $0 left after Gearing 2 ((5.78−5.17) × 68.6 = $41.8), so $150 / $70.2 per minute = 2.14 min, which gives 7.92 min. Income at that point: price $5.50 × 0.266 jars/s × 0.8 × 60 = $70.2/min.

- **Up to Auto-Sell (12.0 min), the recommended bottling-inclusive cut gives the same times.** Income is fill-bound there (0.266 < 0.317), so the chain choice does not matter yet.
- **After that**, the recommended cut lifts the chain cap from 0.278 to 0.317. So the Long Fork and scraper times above are upper bounds.
- **Scraper cost sensitivity:** at $300 instead of $400 the pause ends at 19.2 min instead of 19.9. The Heated gate and the Long Fork, not the scraper price, set the timing.
- **Attention sensitivity** (times × 0.8 / η): at η = 0.6, the motor comes at 10.6 min and Auto-Sell at **16.0 min**, just over the window. At η = 1.0 they come at 6.3 and 9.6 min. If playtesters prove slower than 0.8, drop `auto_sell_cost` to $200 rather than move the gate.

### 2.4 Order this produces

Motor (≈ 8 min), then Faster Delivery 1 and Auto-Sell (≈ 12 min), then Heated 3, Long Fork and auto-scraper (≈ 16-20 min). This keeps uncapping manual the longest, as harvest-upgrade-paths §2.5 recommends. It differs in one way: Auto-Sell comes *before* the scraper, not last, because the 10-15-minute target names the truck automation (Decision 4).

## 3. Provisional values (all new config keys)

| Key | Value | Notes |
|---|---|---|
| `heated_fork_post_auto_yield_bonus_per_level` | 0.04 | Applies once the auto-scraper is owned; replaces the manual clean-cut bonus |
| `gearing_post_auto_time_cut_per_level` | 0.08 | Applies once the motor is owned; replaces the manual −15% tap/hold cut |
| `gearing_post_auto_cut_includes_bottling` | true | false = spin only (Decision 2) |
| `centrifuge_motor_cost` | 150.0 | One-time (max level 1) |
| `motor_unlock_gearing_level` | 2 | $77 of Gearing first |
| `motor_spin_seconds_per_bucket` | 3.0 | Must stay ≤ the hand-crank time at the unlock level |
| `faster_delivery_base_cost` | 60.0 | Costs $60, $78, $101.4, $131.8 (total $371.2) |
| `faster_delivery_cost_growth` | 1.30 | |
| `faster_delivery_max_level` | 4 | |
| `faster_delivery_trip_cut_per_level` | 0.15 | Additive on `truck_trip_seconds`; floor 12 s at L4 |
| `auto_sell_cost` | 250.0 | One-time |
| `auto_sell_unlock_delivery_level` | 1 | Replaces the name `auto_dispatch_unlock` from harvest-upgrade-paths, since the GDD now says Auto-Sell |
| `long_fork_cost` | 200.0 | One-time |
| `long_fork_unlock_heated_level` | 3 | Heated 4-5 then compete with the Long Fork, as harvest-upgrade-paths §2.1 intends |
| `long_fork_seconds_per_frame` | 1.0 | Assumption A3 |
| `uncap_apparatus_cost` | 400.0 | The auto-scraper; one-time |
| `uncap_apparatus_unlock` | `long_fork` | Owning the Long Fork |
| `apparatus_seconds_per_frame` | 3.0 | Never binds (0.667 jars/s) |
| `manual_uncap_seconds_per_frame` (model only) | 3.0 | Not a game key unless Patricia's uncap uses one; listed so the model can be re-run on measured play |

Per the Dev-mode rule, every key above is a tunable in `default_config.tres` and editable live in Dev mode.

## 4. Standing checks

### 4.1 Target run length (GDD §3: about 66 h at launch)
- These buys all land in the first ~20 minutes and are bought identically on every route, so their effect on a 66 h run is below the model's resolution.
- The early income curve ($24/min at the start, $175/min at minute 20) is **not** calibrated against the hour-scale stand-in. When the reference sims exist, J_ref and the run length must be re-derived from the real harvest chain.

### 4.2 Rush gap (G = T_R / T_N, refinery-parameters §2.2; T_N = 3 + 69/M, T_R = 2 + 85.5/M, M = 1 + 0.1n)

| Crystals n | M | T_N (h) | T_R (h) | G now | G if both routes gain δ = 0.33 h |
|---|---|---|---|---|---|
| 0 | 1 | 72.00 | 87.50 | 1.215 | 87.17 / 71.67 = 1.216 |
| 20 | 3 | 26.00 | 30.50 | 1.173 | 30.17 / 25.67 = 1.175 |
| 50 | 6 | 14.50 | 16.25 | 1.121 | 15.92 / 14.17 = 1.123 |
| 150 | 16 | 7.31 | 7.34 | 1.004 | 7.01 / 6.98 = 1.004 |

- These buys are route-neutral: Meadow tools, the same price on both routes, bought in the first minutes.
- So they subtract the same δ from both times. Because T_R > T_N at every n, that can only raise G, so the rush never becomes faster.
- At n = 150, G stays within the "Equal for veterans" band (0.95-1.05). δ = 0.33 h (20 min) is a deliberately generous upper bound.

### 4.3 Throughput cap κ (16 × J_ref jars/h)
- κ is stated in units of J_ref and applies equally to both routes. The 0.2 values therefore **do not change κ**, and no re-derivation is needed now.
- **New finding:** with these values, the harvest chain itself caps intake per station. It is 0.444 jars/s = **1,600 jars/h** at Gearing 5 with the bottling-inclusive cut, or 0.303 jars/s = 1,091 jars/h with the spin-only cut, before the truck (≤ 3,000 jars/h at D4).
- When the reference sim computes J_ref, check that this station cap × the number of stations at hour 27 is above J_ref. Otherwise J_ref is set by the harvest chain, not by bees.

## Risks
- **The bottling ceiling (largest).** `bottling_seconds_per_jar = 3.0` caps every station at ≤ 0.333 jars/s (1,200 jars/h), even with no other bottleneck. Under the serial assumption A5 the cap is 0.25-0.32. Fill passes it at about Swarm 5 + Flight 1, around minute 16. Without Decision 2 (or a bottling upgrade), Swarm 6-10, Flight and the Heated yield bonus become dead buys in 0.2.
- **Assumption A5 is unverified.** If bottling overlaps the next spin, every chain number in §2.1 rises and the motor matters less. Patricia should confirm how the centrifuge queues buckets.
- **Branding dominates early.** +$2.50 on a $3 base is +83% at L1, more than five Swarm levels. It sets the whole early curve. It is a settled value and is not changed here, but any later change moves every time in §2.3.
- **Manual uncap time (A3) is a guess.** It does not bind before minute 15, so the times hold, but the Long Fork's felt value depends on it.
- **Faster Delivery has little throughput value** until the chain exceeds the truck's 0.333 jars/s, which happens only with the bottling-inclusive Gearing cut at G ≥ 1. Before that, Faster Delivery is slack for manual Sell taps plus the Auto-Sell gate.
- **Crate tiers** (adopted: they hold more jars and a bigger load) can raise truck load and would change the truck row. They are out of scope here and still need values.

## Decisions needed from the designer
1. **Accept the costs and gates in §3** as 0.2 placeholders: motor $150 at Gearing 2; Faster Delivery $60 × 1.30, max 4, −15% trip per level; Auto-Sell $250 at Delivery 1; Long Fork $200 at Heated 3; auto-scraper $400.
2. **Does the post-automation Gearing cut also speed bottling?** Recommended yes (`gearing_post_auto_cut_includes_bottling = true`). It is the only lever here that lifts the bottling ceiling. The alternative is a new bottling-speed upgrade.
3. **Heated Fork after automation:** +4% per level (recommended; +20% at L5) or +3% (+15%; slower)?
4. **Order:** confirm that Auto-Sell comes before the auto-scraper (≈ 12 vs ≈ 20 min). This puts the pause's end at about 20 minutes, past the 10-15 minute window.
5. **Playtest calibration:** after the first 0.2 playtest, report the real minutes to the motor and to Auto-Sell, plus the measured uncap seconds per frame. If Auto-Sell comes after 15 min, lower `auto_sell_cost` to $200 first.
6. **Before final:** Patricia confirms assumption A5 (serial centrifuge), and the reference sims re-derive J_ref and check the station cap against it (§4.3).
