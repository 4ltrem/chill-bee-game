# Progression Levers: Run Length, Stronger Crystals, Researchable Charging Cap
**Author:** Terry, the Progression Tree Expert
**Sources:** `GDD.md` (Design Pillars, §3 Capstone and Native Habitat, §5 Leaderboards, Glossary "Comparing Routes"), `balance/native-species-balance.md` (latest model), `balance/refinery-parameters.md` (rev. 2), `balance/royal-crystal-balance.md`, `design/native-species.md` (Glowcap flavour).
**Settled inputs used:** option B (X[v1] = 67.5, no extra Alpine cost), Y_Alpine = 1.92, Y_Cloud = 30 with Stardust (base 27.27), per-biome bucket with sub-caps (Meadow fill 0, Meadow sale ≤ 0.15), abundance on sale value only. "Equal for veterans" is loose: rush gap G within 0.95–1.05 either way. Charging-speed cap is tolerant.
**Status:** Proposal. The stand-in model is the same as before. Re-derive once the reference sims exist (ΔF and the habitat cost per level are still unmeasured).

---

## 0. Summary

| Item | Result |
|---|---|
| Launch first run (v1, option B) | **65.8 h** (charge 40.9 h). G = 1.30 at n = 0, **1.006 at n = 150**. The rush enters the 5% window at **n ≈ 138**. |
| Post-launch first run (v2) | X[v2] = 83 now puts the veteran rush **outside** the window (G = 1.063 at n = 150), because option B shortens the normal route's build-up. **Re-derived X[v2] = 78 → v2 first run 43.2 h.** G(150) = 1.029; Alpine-stop min 0.988 and Grove-stop min 0.993, both inside the loose goal. |
| Structural finding | In this model the route gaps depend on Crystals **only through M**. A stronger Crystal therefore does not change *which* gaps occur, only **how many Crystals it takes to reach them**. κ does not need to change for the window, but the cap starts to bind at fewer Crystals. |
| Lever 1 (stronger Crystals) | +12%: the window opens at **n ≈ 115** (v1) / 120 (v2), and 150 Crystals take 2,033 h instead of 2,222 h. +15%: the window opens at n ≈ 92 / 96, and 150 Crystals take 1,838 h, but the flat cap then costs 19% at n = 150 and the v2 window is only n 96–120 wide. |
| Lever 2 (lower cap raised by research) | **It cannot move the window earlier.** A lower jar cap always hurts the rush more (its yield is 1 vs 1.5). Its value is elsewhere. It turns the cap into an in-run upgrade path (strong for both pillars), and its top step can sit above 16 under the tolerant rule. That keeps veterans in the window instead of drifting back out. Cost to normal-route players: **+0.6% / +1.6% / +0.8%** at n = 60 / 100 / 150 (v1, vs flat κ 16). |
| Glowcap digger | **+10% sale value** (Grove sale sub-cap 0.05 → 0.15). It is route-neutral (G changes by ≤ 0.004) and makes the Grove the third biome with a quality species. Fallback: Gerard's pollination +25%, which is equally safe. |
| **Recommendation** | **+12% per Crystal, plus a research-raised cap** (v1: 7 → 10 → 13 → 16 → 20; v2: 10 → 13 → 16 → 17.5), **X[v2] = 78**, Glowcap = sale +10%. The rush stays inside the window from n ≈ 115 onwards (v1, min G 0.975). v2 is inside the window from n ≈ 120 to 260. |

---

## 1. Task 1: run length under option B

### 1.1 Model inputs (stand-in, unchanged except option B)

T_k(n) = F_k + B_k / M + X / (min(M · J_k, κ) · Ȳ_k), with M = 1 + 0.1n and κ = 16 × J_ref.

| Route | F | B (M = 1) | J | Ȳ | Change from last report |
|---|---|---|---|---|---|
| v1 normal | 3 | **21.90** | 1.10 | 1.502 | Alpine absorption removed (−2.33 h) |
| Meadow rush | 2 | 16.03 | 1.00 | 1.00 | — |
| v2 Alpine-stop | 3 | **21.90** | 1.10 | 1.502 | −2.33 h |
| v2 Grove-stop | 4 | **26.76** | 1.344 | 2.416 | −2.33 h |
| v2 normal (Cloud) | 5 | **30.85** | 1.595 | 6.689 | −2.33 h |

The Alpine build cost is the same content in both versions, so dropping the +2.5 base-hours lowers every route that contains Alpine.

### 1.2 Launch (v1), X = 67.5, κ = 16

| n | M | T_normal (h) | T_rush (h) | **G** |
|---|---|---|---|---|
| 0 | 1 | **65.76** | 85.53 | **1.301** |
| 20 | 3 | 23.92 | 29.84 | 1.248 |
| 50 | 6 | 13.46 | 15.92 | 1.183 |
| 100 | 11 | 8.71 | 9.59 | 1.102 |
| 150 | 16 | 7.18 | 7.22 | **1.006** |
| 200 | 21 | 6.85 | 6.98 | 1.019 |
| 300 | 31 | 6.52 | 6.74 | 1.034 |

- **The first run is 65.8 h** (the GDD's "about 66 h" is confirmed), with a 40.9 h charge phase (62%).
- Min G = 1.006 at n = 150. The rush is in the 5% window from **n = 138** onwards and never leaves it (G ≤ 1.05 up to n ≈ 570).
- The normal route hits the cap from n ≈ 135 (M · 1.1 = 16).
- Tolerant κ check: v1 stays at G ≥ 0.95 for every κ up to about **23**. κ 16 is now conservative at launch (see §3).

### 1.3 Post-launch (v2), κ = 16: X = 83 (old) vs X = 78 (re-derived)

| n | T_normal, X 83 | Rush / Alpine-stop / Grove-stop G, X 83 | T_normal, **X 78** | Rush / Alpine-stop / Grove-stop G, **X 78** |
|---|---|---|---|---|
| 0 | 43.63 | 2.316 / 1.722 / 1.291 | **43.16** | **2.225 / 1.671 / 1.269** |
| 20 | 17.88 | 1.958 / 1.513 / 1.199 | 17.72 | 1.882 / 1.469 / 1.181 |
| 50 | 11.44 | 1.618 / 1.313 / 1.112 | 11.36 | 1.556 / 1.278 / 1.097 |
| 100 | 8.58 | 1.282 / 1.114 / 1.021 | 8.53 | 1.236 / 1.088 / 1.010 |
| 150 | 7.70 | **1.063** / 1.015 / 1.015 | 7.66 | **1.029** / 0.995 / 1.004 |
| 200 | 7.24 | 1.097 / 1.035 / 1.024 | 7.20 | 1.061 / 1.013 / 1.013 |
| Min over n | | 1.063 / 1.008 / 1.003 | | **1.029 / 0.988 / 0.993** |
| Rush in window | | **never** | | n 144–180 |

**X[v2] search (κ = 16):**

| X[v2] | v2 T0 | Rush G(150) | Alpine-stop min | Grove-stop min | Verdict |
|---|---|---|---|---|---|
| 83 | 43.6 h | 1.063 | 1.008 | 1.003 | Rush never in window |
| 80 | 43.4 h | 1.043 | 0.996 | 0.997 | Window only n 148–159 |
| **78** | **43.2 h** | **1.029** | **0.988** | **0.993** | **Recommended** |
| 75 | 42.9 h | 1.008 | 0.975 | 0.987 | Alpine-stop 2.5% faster at n ≈ 136 |
| 70 | 42.4 h | 0.973 | 0.954 | 0.977 | Alpine-stop on the edge |

- **X[v2] = 78 → v2 first run 43.2 h** (charge 7.3 h). That is 2.8 h shorter than the 46 h of the last report.
- Biomes 3–4 still cannot be skipped: Alpine-stop and Grove-stop are ≥ 1.27 at n = 0. At worst they are 1.2% and 0.7% faster for veterans, inside the loose goal and on separate route categories.
- **v2 weakness (unchanged in kind):** above n ≈ 180 the v2 rush drifts back out of the window on the slow side (1.10 at n = 300), because its capped charge X/κ is 4.9 h vs 0.73 h for the normal route. §3 fixes this with a tolerant top cap step.

---

## 2. Task 2, Lever 1: stronger Crystals (additive)

M = 1 + a·n. Normal-route production hours, κ = 16 flat, X[v1] = 67.5, X[v2] = 78.

### 2.1 Run length (normal route) and rush gap

| n | v1 T at 10% / **12%** / 15% | v1 G at 10% / 12% / 15% | v2 T at 10% / **12%** / 15% | v2 rush G at 10% / 12% / 15% |
|---|---|---|---|---|
| 0 | 65.8 / 65.8 / 65.8 | 1.301 (all) | 43.2 / 43.2 / 43.2 | 2.225 (all) |
| 5 | 44.8 / **42.2** / 38.9 | 1.287 / 1.284 / 1.280 | 30.4 / **28.9** / 26.8 | 2.13 / 2.11 / 2.08 |
| 20 | 23.9 / **21.5** / 18.7 | 1.248 / 1.238 / 1.224 | 17.7 / **16.2** / 14.5 | 1.88 / 1.83 / 1.75 |
| 60 | 12.0 / **10.7** / 9.3 | 1.164 / 1.144 / 1.116 | 10.5 / **9.7** / 8.8 | 1.48 / 1.40 / 1.29 |
| 100 | 8.7 / **7.8** / 7.2 | 1.102 / 1.076 / 1.006 | 8.5 / **8.1** / 7.7 | 1.24 / 1.14 / 1.03 |
| 150 | 7.2 / **7.0** / 6.7 | 1.006 / 1.014 / 1.024 | 7.7 / **7.4** / 7.0 | 1.03 / 1.05 / **1.07** |

### 2.2 Grind length, window and cap

| | 10% (current) | **12%** | 15% |
|---|---|---|---|
| First reset gain (money-gated part of run 2 vs run 1) | 9.1% shorter | **10.7% shorter** | 13.0% shorter |
| Cumulative hours to 50 / 100 / 150 Crystals (v1) | 1,301 / 1,834 / 2,222 | **1,195 / 1,671 / 2,033** | 1,074 / 1,491 / 1,838 |
| Same, v2 | 950 / 1,433 / 1,835 | **886 / 1,336 / 1,720** | 812 / 1,230 / 1,596 |
| Rush enters the 5% window (v1 / v2) | n 138 / 144 | **n 115 / 120** | n 92 / 96 |
| v2 window width (flat κ 16) | n 144–180 | n 120–150 | n 96–120 |
| Normal route hits κ 16 (v1 / v2) | n 135 / 90 | n 113 / 75 | n 90 / 60 |
| Cap cost vs uncapped at n = 150 (v1 / v2) | 3.7% / 3.7% | 10.4% / 4.9% | **18.9%** / 6.3% |
| Min G, all routes (unchanged) | 1.006 / 0.988 | 1.006 / 0.988 | 1.006 / 0.988 |
| Does κ have to change? | — | **No** (gaps are a function of M) | No for gaps; yes if the cap cost matters |

Readings:
- **The κ guarantee is unchanged.** Every route pair crosses at the same M. Stronger Crystals only reach that M sooner, so no κ change is needed for the 5% goal.
- **What does change is when the cap is felt.** With a flat κ, 15% puts v1 veterans behind the cap from n = 90, and the cap costs 19% at n = 150. That works against "optimization pays off": a 100–150 Crystal player's extra production stops speeding up the Refinery. Lever 2 is the remedy (§3).
- **Pillar 2 (Egg, Inc.):** 12% gives a felt first reset (+12%), and about 9% less grind to every milestone. 15% gives 17% less grind but compresses runs towards the 3 h floor sooner (v1 7.2 h at n = 100).
- **Leaderboard Crystal tiers:** the M spread inside each tier grows with a. For example, 21–50 is 2.05× at 15% vs 1.94× at 10%. That is acceptable, but the 101+ split proposed earlier should move down with the window (e.g. 81–120, 121+ at 12%).
- **Patron ×1.25 and ad ×2** reach the cap at lower n in the same proportion. Nothing new there.

---

## 3. Task 3, Lever 2: lower base cap raised by Refinery research

### 3.1 Why a lower cap cannot move the window earlier

Once both routes are capped, T_rush − T_normal = −ΔF − ΔB/M + X·(1 − 1/Ȳ_N)/κ = −1 − 5.87/M + 22.5/κ.
- A lower κ makes the last term larger, so the rush falls further behind. Its yield of 1 means it needs 1.5× as many jars.
- Example: a flat κ = 8 gives G = 1.16 at n = 63 and G → 1.43 at very high n.
- The window could only open at n ≈ 55 if the normal route were capped while the rush was not. That needs κ ≤ 5.8 and κ ≥ 6.5 at the same time, which is impossible with one jar cap.

**So Lever 2 is not a window lever.** It is a pillar lever: it turns an invisible wall into a visible upgrade path. Its top step can also safely sit above 16 under the tolerant rule.

### 3.2 Proposed research ladder (`CAP_THROUGHPUT_MAX` per research level, stored per content version)

| Level | v1 κ (× J_ref) | v2 κ | Research cost (base-hours of income, ÷M in play) | First worth buying (normal route, 10% / 12% Crystals) |
|---|---|---|---|---|
| Base | **7** (binds the v1 normal route at n ≈ 54) | **10** (binds v2 normal at n ≈ 53) | — | — |
| R1 "Wider intake" | 10 | 13 | 0.5 | n 55 / 46 (v1), 57 / 48 (v2) |
| R2 | 13 | 16 | 1.0 | n 84 / 70 (v1), 83 / 69 (v2) |
| R3 | 16 | **17.5** (tolerant top) | 1.5 | n 113 / 94 (v1), ~200 (v2) |
| R4 (v1 only) | **20** (tolerant top) | — | 2.0 | n 143 / 119 |

- The base is per version, because v2 intake (J = 1.595) is higher. The same absolute base 7 would bind v2 at n ≈ 34.
- Costs are small next to the Refinery build cost (≈ 2 base-hours). Together they add 5 base-hours (v1), which is 0.3 h of real time at n = 150.
- The research needs no biome gate, so the rush can buy it too (it does, in the model). Gating a step behind Alpine would make the rush slower, which is the wrong direction.
- The tolerant tops (20 / 17.5) come from the largest κ with min G ≥ 0.95 over all n: about 23 for v1 and 18 for v2, minus a margin.

### 3.3 Cost to normal-route players (optimal research purchases)

| n | v1 T (10%) | v1 vs flat κ 16 | v1 vs uncapped | v1 without research | v2 T (10%) | v2 vs flat 16 | v2 vs uncapped | v2 without research |
|---|---|---|---|---|---|---|---|---|
| 60 | 12.04 (R1) | **+0.6%** | +0.6% | 12.55 (+4%) | 10.52 (R1) | +0.7% | +0.7% | +0.5% |
| 100 | 8.84 (R2) | **+1.6%** | +1.6% | 11.41 (**+29%**) | 8.67 (R2) | +1.6% | +2.4% | +3.5% |
| 150 | 7.23 (R4) | **+0.8%** | +4.5% | 10.79 (**+49%**) | 7.75 (R2) | +1.2% | +5.0% | +4.4% |
| 200 | 6.53 | **−4.7%** (faster) | +9.0% | — | 7.27 | −0.9% | +6.6% | — |

At 12% Crystals the same ladder costs +0.6% / +2.9% / −4.3% at n = 60 / 100 / 150 (v1) and +0.7% / +1.4% / +1.1% (v2).

### 3.4 Pillar check

| Pillar | Effect |
|---|---|
| Optimization pays off | **Strong positive.** Every κ step is a visible, measurable speed-up once the cap binds. A v1 veteran who skips Refinery research is 29–49% slower at n = 100–150, so smarter upgrade choices clearly produce more. The cost is a small (≤ 3%) dip between steps, where extra production briefly stops speeding up the Refinery. Above 16, the tolerant top step makes veterans *faster* than today's flat cap (−4.7% at n = 200). |
| Thrill of the next unlock | **Positive.** Three or four new Refinery upgrades arrive at n ≈ 50–150, the stretch where Crystal gains have shrunk to 2–3% per reset and the earlier report flagged a "pointless reset" risk. |
| 5% goal | v1 min G **0.975** (n ≈ 200), and the rush stays in the window from n 138 onwards. v2 min 0.971 (Alpine-stop), and the rush window widens from n 144–180 to **n 144–315**. |

**UX note:** the panel's "at capacity" message should now point to the next research step ("Research Wider Intake to refine more").

---

## 4. Task 4: Glowcap digger (Enchanted Grove, fictional)

Grove sub-caps (from `native-species-balance.md` §3): fill 0.20 (lantern), pollination 0.25, sale 0.05 (abundance only), yield **hard 0**.

| Option | Sub-cap change | v2 T0 | Grove-stop min G | Alpine-stop min G | Rush min G | Notes |
|---|---|---|---|---|---|---|
| Pollination +25% (Gerard's draft) | none | 43.16 | 0.990 | 0.971 | 0.996 | Safe. It is the fourth pollinator (sweat, mason, drift), so there is little novelty. It helps Grove-stop's host-minimum bill slightly more than the full route. |
| **Sale value +10% (recommended)** | Grove sale 0.05 → **0.15** | 43.18 | **0.992** | 0.971 | 0.996 | Money only, with no Refinery effect. The full route earns it over two phases (Grove + Cloud ≈ 0.23 h saved) vs one for Grove-stop (≈ 0.10 h), so it leans slightly towards the full route. |
| Extra fill +10% | fill 0.20 → 0.30 | 42.91 | 0.984 | 0.972 | 0.997 | Not recommended. It is the only option that moves J and Ȳ for Grove-stop (the narrowest route), and it stacks on lantern bees. |
| Refinery yield | hard 0 | — | — | — | — | **Rejected by rule.** Only Stardust may raise yield. |

**Proposed values for the sale option:** `SPECIES_EFFECT_TYPE` = sale value, **+10%**, `SPECIES_HH_THRESHOLD` = raw **40**, `SPECIES_FLOWER_MIN` = 2 glowing-mushroom units, no tier gate. With no Grove pollinator, raw 40 is still below Synergy 5 (raw 50), so the normal route earns it before Cloud opens.

Flavour (needs William): "Glowcap diggers dust Moonlight Nectar with glowing spores, so Grove jars sell for more."

Pillar 2: each biome then has a distinct set of species (Meadow pollination + quality, Alpine fill + pollination + quality, Grove fill + quality, Cloud pollination + quality/yield).

---

## 5. Task 5: recommended combination

**+12% per Crystal (additive) + researchable cap ladder (§3.2) + X[v1] = 67.5, X[v2] = 78 + Glowcap sale +10%.**

| n | v1 T (h) | v1 rush G | v2 T (h) | v2 rush / Alpine-stop / Grove-stop G |
|---|---|---|---|---|
| 0 | 65.8 | 1.301 | 43.2 | 2.225 / 1.671 / 1.269 |
| 5 | 42.2 | 1.284 | 28.9 | 2.106 / 1.601 / 1.239 |
| 20 | 21.5 | 1.238 | 16.2 | 1.828 / 1.438 / 1.167 |
| 50 | 12.0 | 1.157 | 10.5 | 1.467 / 1.223 / 1.069 |
| 100 | 8.1 | 1.060 | 8.2 | 1.128 / 1.026 / 0.990 |
| 120 | 7.4 | 1.030 | 7.8 | 1.048 / 0.981 / 0.993 |
| 150 | 6.7 | 0.999 | 7.4 | 1.004 / 0.979 / 0.997 |
| 200 | 6.3 | 0.983 | 7.0 | 1.028 / 0.992 / 1.002 |
| 300 | 6.0 | 0.995 | 6.6 | 1.059 / 1.009 / 1.010 |
| Min G | | **0.975** | | **0.996 / 0.971 / 0.990** |
| Rush in window | | **n ≥ 115** | | n 120–262 |
| Hours to 150 Crystals | 2,041 | | 1,731 | |

Why this combination:
- **5% goal:** it is met for veterans in both versions, and the window opens about 23 Crystals earlier than today. Nothing is ever more than 3% faster than the full route, and new players still see the rush ≥ 30% slower at launch and ≥ 2× slower post-launch.
- **Optimization pays off:** the cap is no longer a silent wall. Each research step gives a visible speed-up, and researched veterans beat today's flat-cap times by about 4% at n = 150. The cap's real cost to an optimizing player stays ≤ 3% vs flat κ 16 at every n.
- **Thrill of the next unlock:** a bigger first reset (+12%), about 9% less grind to every Crystal milestone, and new Refinery upgrades exactly in the n ≈ 50–150 stretch where per-reset gains are smallest.
- **Why not +15%:** it opens the window earliest (n ≈ 92), but runs approach the floor sooner and the cap binds from n ≈ 60 (v2 from n ≈ 35). That puts 100+ Crystal players behind the cap for most of their play, against pillar 1, and the v2 rush leaves the window again by n ≈ 210. +12% is the better balance between both pillars.

---

## 6. Risks

1. **Stand-in model.** ΔF (1 h per biome) still drives every κ number. If ΔF = 1.5 h, the tolerant tops (20 / 17.5) are too high. Measure ΔF in the vertical slice before freezing the ladder.
2. **The ladder depends on research cost scaling ÷M.** If research prices grow with Crystal count or run number, the optimal-purchase points in §3.2 move and the dips get longer.
3. **v2 rush drift-back** (G 1.06 at n = 300, 12%) remains on the slow side. It is acceptable under "within about 5%", but a further v2 top step would be needed if veterans above 250 Crystals must stay in the window.
4. **Changing the Crystal percentage after launch** changes every stored M. Since run brackets are by Crystal count, decide before launch.
5. **Cumulative hours are production hours.** Free players with a 4 h offline cap take longer in calendar time (`refinery-parameters.md` A3).

---

## 7. Decisions for the designer

| # | Decision | Options | My recommendation |
|---|---|---|---|
| 1 | **X[v2]** (post-launch charge target) | 83 (rush never enters the window), **78** (v2 first run 43.2 h), 75 (Alpine-stop 2.5% faster at n ≈ 136) | **78**; update the GDD's "43–46 h" to **≈ 43 h** |
| 2 | **Crystal strength** | 10% (window n ≈ 138), **12%** (n ≈ 115), 15% (n ≈ 92, heavy cap cost) | **12%**, decided before launch. Update the GDD's Phase 3 and Glossary examples (20 Crystals = 3.4×, 100 = 13×). |
| 3 | **Researchable cap** | Flat κ 16, or ladder v1 7 → 10 → 13 → 16 → 20, v2 10 → 13 → 16 → 17.5 | **Ladder**. Accept that a lower cap is a pillar lever, not a window lever (§3.1). |
| 4 | **Tolerant top steps** above 16 (v1 20, v2 17.5) | Include, or stop at 16 | Include. They keep the rush inside the window at high n, and veterans get faster, not slower. |
| 5 | **Refinery research costs** | 0.5 / 1 / 1.5 / 2 base-hours (my placeholder), scaling ÷M like other research | Accept as placeholders until the sim exists |
| 6 | **Glowcap digger effect** | Sale +10% (Grove sale sub-cap 0.15), or pollination +25% (Gerard's draft) | **Sale +10%**; William to draft the Journal flavour |
| 7 | **Crystal tiers** | Shift the high-tier split down with the window (e.g. 81–120, 121+ at 12%) | Yes, before online leaderboards |
| 8 | **"At capacity" panel** | Point it to the next Refinery research step | Yes |
