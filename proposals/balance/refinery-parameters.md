---
author: terry
type: balance
status: applied
description: Refinery parameters, revision 2; stand-in model, re-derive after the reference sim
---
# Royal Honey Refinery Parameters (revision 2)
**Author:** Terry, the Progression Tree Expert
**Sources:** `GDD.md` (Capstone, Phase 3, Tree C, Land/Grid/Units, Leaderboards, Currencies, Patron Pass), `proposals/design/capstone-machine.md` (Gerard, Option 2 Refinery, §5 parameter list), `proposals/balance/royal-crystal-balance.md` (Terry, rush crossover model), and revision 1 of this file (superseded).
**Kept from approved inputs:** +10% additive per Crystal, M(n) = 1 + 0.1n. Patron +25% as a separate ×1.25 multiplier. Extra starting hives keep the Hive Balance penalty. Starting wildflower plots exist (cap reassessed in §2.3). Run time ends when the Crystal forms. Host-biome-only Synergy minimum. Crystals are account-wide.
**Status:** Proposal. All hour values come from the stand-in model in §2. They become real numbers only after the reference sim (§6) is run, and the cap must then be re-derived with the §5.1 formula.

---

## 1. Designer decisions (this revision)

| # | Decision | What it changes from revision 1 |
|---|---|---|
| D1 | **First run ≈ 72 h at launch** (two biomes, run start to first Crystal at n = 0). I propose the post-launch target. | Revision 1 assumed 24 h. |
| D2 | **Habitat Synergy is money-driven.** It rises as soon as flowers are placed, with no habitat timers. | Revision 1 equalised route floors with habitat time. That lever is gone. Habitat now costs money, which scales with M. So a **throughput cap `CAP_THROUGHPUT_MAX` is required**. |
| D3 | **Shortcut balance: "equal for veterans."** The Meadow rush is clearly slower for new and low-Crystal players, converges to within about 5% for veterans, and is never clearly better at any Crystal count. Minimise the cap's cost. | Revision 1 kept the rush 13–20% behind forever. |
| D4 | **No frontier bonus.** Meadow and Alpine yields stay unchanged post-launch. Biomes 3–4 get high enough base rates that they cannot be skipped, while D3 still holds. | Revision 1 dropped Alpine from 3.75 to 1.5 in v2. |

**Headline finding.** D3 and D4 can both hold in v2 only if two conditions are met. First, the *launch* Alpine yield is low (about 2× Meadow), which forces a long launch charge phase. Second, the v2 first run is about 2 days, not 3–4. Both conditions are derived in §2.4 and §4.3. This is the main trade-off the designer must accept (§6, item 1).

---

## 2. Assumptions

### 2.1 Run-length targets and time units
- **A1. Launch T0 = 72 h** (n = 0, normal route ending in Alpine, unboosted). This is D1.
- **A2. Post-launch T0 ≈ 47 h (≈ 2 days), proposed.** It is shorter than launch on purpose: it is the longest v2 first run for which D3 and D4 both hold (§4.3). A 72 h v2 run is possible, but then the veteran rush gap stays at 13% or more (§4.3, alternative B).
- **A3. Hours are production hours.** For Impact Pass players (12 h offline cap), production hours roughly equal wall-clock hours. A free player (4 h cap) who sleeps 8 h a night loses up to 4 h per night, so the launch run is about 84 h wall-clock (3 nights × 4 h). Idle time adds the same absolute hours to every route, so all ratios below are upper bounds for casual players.
- **A4. Charge at max divert with flat production.** While charging, the player holds the slider at `CAP_DIVERT_MAX` and production is roughly flat (Gerard §2.3). This is crude for a long charge phase. The sim should replace it.

### 2.2 Run model
For a route k at Crystal count n:

**T_k(n) = F_k + B_k / M + X / ( min(M · J_k, κ) · Ȳ_k )**, with M = 1 + 0.1n.

| Symbol | Meaning | Scales with Crystals? |
|---|---|---|
| F_k | Non-scaling floor: Phase 1 manual work, plus unlocking and hand-placing each extra biome. Habitat is now money, so it is **not** here. | No |
| B_k | Money-gated build-up before charging: units, land, research, flowers for Synergy (now money), and the Refinery build cost. | ÷M |
| X | `CAP_CHARGE_TARGET`, counted in Meadow-jar equivalents of Royal Honey | – |
| J_k | Jar intake into the Refinery at max divert, at M = 1, relative to **J_ref** (the reference launch normal run at charge start). | ×M |
| Ȳ_k | Mean Royal Honey per jar for the route's jar mix: Σ share_b × Y_b | – |
| κ | `CAP_THROUGHPUT_MAX`, max jars/h the Refinery accepts, in units of J_ref | **No (non-scaling)** |

**Floors (illustrative).** Phase 1 = 2.0 h. Each extra biome adds f = 1.0 h of non-scaling unlock and placement time. So F is 2.0 for the Meadow rush, 3.0 for routes ending in Alpine, 4.0 for Grove and 5.0 for Cloud. The floor gap between routes, **ΔF**, is the single most important number to measure (sensitivity in §5.3).

**Build-up B at M = 1:**
- Launch normal: B_N = 72 − 3 − 45 = 24 h.
- Meadow rush: B_R = 0.75 × B_N = 18 h. This covers top Meadow research, dense units, and the money for Meadow Synergy 7.
- Each v2 biome adds about 21% of B_N, so 5 h each. Grove-end: B = 29 h. Cloud-end: B = 34 h. The +21% ratio is the same per-biome ratio as revision 1 (3.0 / 14.4).

**Jar mix and intake** (same shares as revision 1):

| Route | Shares (Meadow / Alpine / Grove / Cloud) | J |
|---|---|---|
| Meadow rush | 1.00 | 1.00 |
| Alpine-end (launch normal, v2 "Alpine-stop") | 0.50 / 0.50 | 1.00 |
| Grove-end (v2 "Grove-stop") | 0.40 / 0.35 / 0.25 | 1.20 |
| Cloud-end (v2 normal) | 0.33 / 0.29 / 0.21 / 0.17 | 1.45 |

### 2.3 Why the cap counts jars, not Royal Honey
- **A cap on Royal Honey output** makes every saturated route charge in the same time X / R_cap. The route with the smallest floor (the rush) then wins by ΔF at every high n. It breaks D3.
- **A cap on jars entering** makes saturated charge time X / (κ · Ȳ_k). Routes are then ranked by F_k + X / (κ · Ȳ_k), so the rush's low yield becomes a **non-scaling penalty** that offsets its floor advantage. This is the only cap shape that can guarantee "never clearly better".
- The cap does not care which biome a jar comes from. Excess honey above the cap is not diverted; it is sold normally. The slider auto-limits and the panel shows "at capacity".

### 2.4 Why the launch Alpine yield must be low (derived from D4)
- In v2, "Alpine-stop" is exactly "Meadow rush + Alpine". It has 1 h more floor than the rush and 2 h less than the full route.
- Suppose the rush is within 5% of the full route for veterans (D3). Then Alpine-stop must not be faster than the rush, or biomes 3–4 become skippable (breaking D4).
- At saturation (κ binding) that requires (1 − 1/Ȳ_Alpine-end) · X/κ ≤ f. Rush parity requires X/κ ≈ 3f (three biomes of floor). Together: 1 − 1/Ȳ ≤ 1/3, so **Ȳ_Alpine-end ≤ 1.5**, which means **Y_Alpine ≤ 2.0**.
- Numeric check (best v2 outcome found by search, at any v2 run length):

| Launch Y_Alpine (launch charge phase) | Best v2 rush G(150) with Alpine/Grove-stop never faster |
|---|---|
| 4.25 (18 h) | 1.36 |
| 3.0 (27 h) | 1.17 |
| 2.5 (33.5 h) | 1.10 |
| **2.0 (45 h)** | **1.04** (v2 T0 ≈ 47 h) |

- Since D4 freezes launch yields, **this choice must be made now, before launch.**

### 2.5 Other assumptions
- Unboosted runs with no Jelly time skips. Time skips remove floors, so the time-skipped board is out of scope.
- Patron ×1.25 and rewarded-ad ×2 act like a larger M, so they reach the cap at a lower n (§5.4).
- Starting-upgrade whitelist items with a max level shorten Phase 1 by the same amount for every route (all routes start in the Meadow), so they do not change ΔF.

---

## 3. Parameter table

Unit conventions:
- **J_ref** = jars/h entering the Refinery at 80% divert in the reference launch normal run at charge start (≈ hour 27), n = 0, unboosted.
- **I_ref[v]** = money income/h (0% divert) at charge start in version v's reference run.
- **Royal Honey (RH)** is counted in Meadow-jar equivalents (one Meadow jar = 1 RH).

| Name | Launch (v1: Meadow, Alpine) | Post-launch (v2: + Grove, Cloud) | What it controls | Rationale |
|---|---|---|---|---|
| **Royal yield Y_b** (design quantity behind AFFINITY) | Meadow **1**, Alpine **2.0** | Meadow **1**, Alpine **2.0** (unchanged, D4), Grove **5**, Cloud **30** | How far one jar of each biome moves the meter | Alpine 2.0 is the highest value that keeps v2 feasible (§2.4). Grove 5 and Cloud 30 are the lowest found that keep Alpine-stop and Grove-stop ≥ 10% slower at n = 0 and never faster at any n (§4.2). The steep Cloud value is the price of D4 (§7, Q2). |
| **`AFFINITY[v][b]`** = Y_b / S_b | Example with sale values S = 1, 1.25: Meadow **1.00**, Alpine 2.0 / 1.25 = **1.60** | Example with S = 1, 1.25, 1.5625, 1.953: 1.00 / 1.60 / 5 / 1.5625 = **3.20** / 30 / 1.953 = **15.36** | RH per $1 of honey value (Gerard's definition) | AFFINITY is just Y in money terms once S exists. **Constraint:** S_Alpine < 2.0, otherwise Alpine affinity falls below Meadow's and breaks the GDD's "later biomes have higher affinity" (recommend S_Alpine ≤ 1.6). |
| **`CAP_CHARGE_TARGET[v]`** | **X = 67.5 × J_ref RH**: 45 h × 1.5 mean yield, i.e. a 45 h charge in the reference run | **X = 80 × J_ref RH** (1.185 × v1). Reference normal charge = 80 / (1.45 × 7.06) = **7.8 h** | Main "very high cost"; run length | v1: the 45 h charge (62% of the run) is forced by Y_Alpine = 2.0 and the parity target: ΔW = (B_R − B_N) + C_N(Ȳ − 1) = −0.25 × (69 − C_N) + 0.5 × C_N = 16.5, so C_N = 45. v2: 80 is the largest target for which D3 holds. A larger one slows the rush, because the rush pays the full X at yield 1. Stored per content version (GDD). |
| **`CAP_THROUGHPUT_MAX[v]`** (κ) | **16 × J_ref jars/h** | **16 × J_ref jars/h** (the same absolute number) | Non-scaling ceiling on charge speed; the D3 guarantee | v1 has a strict maximum of κ = ΔW / ΔF = 16.5 (§5.1). 16 makes it bind exactly at n = 150 for both launch routes, so **the cost is zero through n = 150**. v2 has a strict maximum of 16.0 (search). It binds the v2 normal route from M = 16 / 1.45 = 11.0 (n ≈ 100). One value for both versions keeps the rule simple. |
| `CAP_THROUGHPUT_MAX` tolerance variant (optional) | 19.0 × J_ref | 17.3 × J_ref | Same, allowing G down to 0.98 | Use only if "never clearly better" means "never more than 2% faster". It cuts the cost a little (§5.2). |
| **`CAP_SYNERGY_MIN[v][b]`** (graded 0–10, unlock U = 5) | Meadow **7**, Alpine **6** | Meadow **7**, Alpine **6**, Grove **6**, Cloud **6** | Habitat lock (host biome only). Under D2 it is a **money** cost inside B, no longer a time floor. | It stays above U so every Refinery host is restored beyond its unlock threshold (restoration pillar). Meadow 7 is the rush's restoration bill, included in B_R = 18 h. Revision 1's 8 and 10 were only there to equalise habitat *time*, which no longer exists. Raising Meadow's minimum only widens the low-n gap and fades at high n, so it is not a parity lever. |
| **`CAP_DIVERT_MAX`** | **80%** | 80% | Max share of honey diverted | The 20% remainder always lets the player buy flowers to recover a paused lock. It is folded into X, so it does not change route ratios. |
| **`CAP_BUILD_COST[v]`** | **2.0 × I_ref[v1]** (charge start ≈ hour 27) | **2.0 × I_ref[v2]** (charge start ≈ hour 39) | Commit point | Part of B. The rush earns about 1/1.125 of normal income (with S_Alpine = 1.25), so it pays ≈ 2.25 h, which is negligible. It should be ≥ 20× the income at first automation. |
| **`CAP_FOOTPRINT`** | **3×3 = 9 tiles** | 9 tiles | Grid space | Unchanged from revision 1. Use 2×2 if the host biome has fewer than about 80 tiles at charge start. |
| **`CAP_UNLOCK_CONDITION`** | First automation **and** any biome at Synergy ≥ 5 | Same | When the Refinery can be built | Unchanged. Every player sees Alpine open before they can commit a Refinery to the Meadow. |
| **`CAP_RESEARCH_GATE`** | None | None | Optional tech gate | Unchanged. Any prerequisite outside the Meadow would block the rush, which the GDD keeps open. |
| **`RUSH_GAP_TARGET`** G = T_rush / T_normal | n = 0: **≥ 1.20**. n = 100: **≤ 1.06**. n = 150: **1.00–1.05**. **Every n: G ≥ 1.00** (strict). | n = 0: ≥ 1.20. n = 150: 1.00–1.05. Every n: ≥ 1.00. Alpine-stop and Grove-stop: **≥ 1.10 at n = 0, ≥ 1.00 at every n**. | Design target from which X, Y and κ are derived | D3 and D4. Useful identity: G(0) − 1 ≈ (M\* − 1) · ΔF / T0. "Clearly slower at 0" and "parity at n\*" are the **same dial**. With ΔF = 1 h and T0 = 72 h, parity at n ≈ 150 forces G(0) ≈ 1.21. |
| **Starting wildflower plot, max level** | Enough plots to lift a fresh Meadow (with no extra hives) to **Synergy 3** | Same | Starting habitat | Under D2 a plot is a flat money gift that fades as 1/M, so it cannot become a rush engine. Plots up to U = 5 are route-neutral, but Synergy 5 at run start would open Alpine at minute 0 and skip Meadow restoration. Plots from 5 to 7 help only the rush. A cap at 3 sits safely below both. |
| Starting hive max level | Unchanged (5–10, TBD) with the Hive Balance penalty | Same | Starting production | Approved. Each hive lowers starting Synergy. The loadout screen previews it. |
| `CAP_THROUGHPUT_GRADUATED` (optional) | κ(n) = 16 up to n = 150, then rising to about 17.5 at n = 200, 18.9 at 300 and 21 at 1000 | Pointwise max per n (about 17–20) | Lower cap cost above n = 150 | §5.2. Not recommended for launch, because a Crystal-dependent cap is an extra rule to explain. |

**Superseded from revision 1:** `CAP_FRONTIER_BONUS` (D4), habitat-time floor equalisation and τ0 (D2), Synergy minima 8 and 10, the 24 h/32 h run targets, and Y_Alpine = 3.75.

---

## 4. Speedrun check

All times are production hours, unboosted, with κ = 16, from §2.2.

### 4.1 Launch (v1)
Inputs:
- Normal: F = 3, B = 24, J = 1, Ȳ = 0.5 × 1 + 0.5 × 2 = 1.5.
- Rush: F = 2, B = 18, J = 1, Ȳ = 1.
- X = 45 × 1.5 = 67.5.

Derived:
- Normal: C = 67.5 / 1.5 = 45, so W_N = 24 + 45 = 69.
- Rush: C = 67.5 / 1 = 67.5, so W_R = 18 + 67.5 = 85.5.
- ΔW = 16.5 and ΔF = 1.0, so the uncapped crossover is M\* = 16.5 (n\* = 155).
- κ = 16 binds when M · J ≥ 16, i.e. n ≥ 150, the same for both routes because J is equal.

| Crystals n | M | Normal T_N | Meadow rush T_R | G = T_R / T_N |
|---|---|---|---|---|
| 0 | 1.0 | 3 + 69 = **72.00** | 2 + 85.5 = **87.50** | **1.215** |
| 5 | 1.5 | 3 + 46.00 = **49.00** | 2 + 57.00 = **59.00** | **1.204** |
| 20 | 3.0 | 3 + 23.00 = **26.00** | 2 + 28.50 = **30.50** | **1.173** |
| 60 | 7.0 | 3 + 9.857 = **12.86** | 2 + 12.214 = **14.21** | **1.106** |
| 100 | 11.0 | 3 + 6.273 = **9.27** | 2 + 7.773 = **9.77** | **1.054** |
| 150 | 16.0 | 3 + 4.313 = **7.31** | 2 + 5.344 = **7.34** | **1.004** |
| (200, capped) | 21.0 | 3 + 24/21 + 67.5/(16 × 1.5) = 3 + 1.143 + 2.813 = **6.96** | 2 + 18/21 + 67.5/16 = 2 + 0.857 + 4.219 = **7.08** | 1.017 |
| (300) | 31.0 | 6.59 | 6.80 | 1.032 |
| (1000) | 101 | 6.05 | 6.40 | 1.057 |

- **The minimum G over all n is 1.004 (at n = 150).** The rush is never faster.
- **Without the cap**, the rush wins from n = 155: G = 0.966 at n = 200, 0.910 at 300, and 0.77 at 1000. The cap is what holds the line.
- Above n = 150 the rush drifts back to 3–6% slower, because its capped charge (X/κ = 4.22 h) is 1.5× the normal's (2.81 h). That still meets D3.

### 4.2 Post-launch (v2)
Inputs:
- Y = [1, 2, 5, 30] and X = 80.
- Normal (Cloud host): Ȳ = 0.33 × 1 + 0.29 × 2 + 0.21 × 5 + 0.17 × 30 = 0.33 + 0.58 + 1.05 + 5.10 = **7.06**. J = 1.45. F = 5, B = 34. C = 80 / (1.45 × 7.06) = 80 / 10.24 = 7.81.
- Meadow rush: F = 2, B = 18, J = 1, Ȳ = 1, C = 80.
- Alpine-stop: F = 3, B = 24, J = 1, Ȳ = 1.5, C = 53.33.
- Grove-stop: F = 4, B = 29, J = 1.2, Ȳ = 0.40 + 0.70 + 1.25 = 2.35, C = 80 / 2.82 = 28.37.

| Crystals n | M | Normal T_N | Meadow rush (G) | Alpine-stop (G) | Grove-stop (G) |
|---|---|---|---|---|---|
| 0 | 1.0 | 5 + 34 + 7.81 = **46.81** | 2 + 18 + 80 = **100.0 (2.14)** | 80.33 (1.72) | 61.37 (1.31) |
| 5 | 1.5 | **32.88** | **67.33 (2.05)** | 54.56 (1.66) | 42.25 (1.29) |
| 20 | 3.0 | **18.94** | **34.67 (1.83)** | 28.78 (1.52) | 23.12 (1.22) |
| 60 | 7.0 | **10.97** | **16.00 (1.46)** | 14.05 (1.28) | 12.20 (1.11) |
| 100 | 11.0 | **8.80** | **10.91 (1.24)** | 10.03 (1.14) | 9.22 (1.05) |
| 150 | 16.0 | **7.83** (capped) | **8.13 (1.037)** | 7.83 (1.000) | 7.94 (1.014) |
| (200) | 21.0 | 7.33 | 7.86 (1.07) | 7.48 (1.02) | 7.51 (1.03) |
| (300) | 31.0 | 6.80 | 7.58 (1.11) | 7.11 (1.04) | 7.06 (1.04) |

Arithmetic at n = 150:
- **Normal:** intake 1.45 × 16 = 23.2 > κ, so capped. T = 5 + 34/16 + 80/(16 × 7.06) = 5 + 2.125 + 0.708 = 7.83 (uncapped: 7.61).
- **Rush:** intake 16 = κ. T = 2 + 18/16 + 80/16 = 2 + 1.125 + 5.0 = 8.13.
- **Alpine-stop:** T = 3 + 24/16 + 80/(16 × 1.5) = 3 + 1.5 + 3.33 = 7.83.

Findings:
- **The minimum G over all n and all routes is 1.000 (Alpine-stop at n = 150).** Nothing is ever faster than the full route, and Alpine-stop exactly *ties* it there (§7, Q3).
- **Without the cap**, Grove-stop wins from n ≈ 150, and the rush and Alpine-stop win from n ≈ 180. By n = 300, Alpine-stop is 13% faster.
- **D3 in v2 is met later and more abruptly than at launch.** G is 1.24 at n = 100 and 1.04 at n = 150, because parity comes from the cap slowing the normal route from n ≈ 100. Above n ≈ 200 the rush drifts back to 7–19% slower. That is still never better, but the "within 5%" window is narrow: about n = 145–165 (G is 1.07 at 140, 1.037 at 150, 1.045 at 160 and 1.053 at 170).

### 4.3 v2 alternatives (the run-length trade-off)
With launch values fixed (Y_Alpine = 2.0, Alpine-stop and Grove-stop never faster), searching over Y_Grove, Y_Cloud, X and κ gives:

| v2 first-run T0 | Best rush G(150) | Cap cost at n = 150 |
|---|---|---|
| **≈ 47 h (recommended, A)** | **1.04** | 2.9% |
| ≈ 56 h | 1.08 | 2.8% |
| ≈ 72 h (B: "same 3 days") | 1.13; never reaches 1.05 at any n | 6% |
| ≈ 88 h | 1.19 | 11% |

- A longer v2 run means a larger X.
- The rush pays X at yield 1, while the full route pays X/10.2. So every extra hour of v2 charge target hurts the rush roughly 10× more.

---

## 5. Cost of the throughput cap

### 5.1 Derivation of the largest safe cap
- With equal jar intake (launch), the cap first binds both routes at M = κ.
- Before that point the routes are uncapped and cross at M\* = ΔW / ΔF.
- **So κ_max = ΔW / ΔF = 16.5 / 1.0 = 16.5.** Any larger κ lets the rush win between M\* and κ.
- Once both routes are saturated, T_R − T_N = −ΔF − ΔB/M + X(1 − 1/Ȳ)/κ = −1 − 6/M + 22.5/κ, which is ≥ 0 for κ ≤ 16.5 at every M ≥ 16. So the guarantee holds for all n.
- **κ = 16 is the smallest-cost cap that guarantees G ≥ 1.00.**
- In v2, intakes differ (normal J = 1.45), so κ_max was found numerically: 16.0.

### 5.2 Cost on the normal route (T_capped / T_uncapped − 1)

| n | v1 uncapped → κ 16 | v1 tolerance κ 19 | v1 graduated | v2 uncapped → κ 16 | v2 tolerance κ 17.3 |
|---|---|---|---|---|---|
| ≤ 100 | 0% | 0% | 0% | 0% | 0% |
| 120 | 0% | 0% | 0% | 8.22 → 8.32 (+1.3%) | +0.7% |
| 150 | **0%** (7.31) | 0% | 0% | 7.61 → 7.83 (**+2.9%**) | +2.2% |
| 200 | 6.29 → 6.96 (**+10.7%**) | +3.6% | +6.8% | 6.99 → 7.33 (+4.8%) | +4.0% |
| 300 | 5.23 → 6.59 (**+26%**) | +17.5% | +17.9% | 6.35 → 6.80 (+7.2%) | +6.3% |
| 500 | 4.35 → 6.28 (+44%) | +34% | +31% | 5.82 → 6.37 (+9.5%) | +8.6% |

- **In absolute terms the cost is small:** under 1.4 h per run at every n.
- **In percentage terms it grows above n = 150**, because the launch floors are small (3 h). With the cap, the launch normal run levels out at about 6 h instead of 3–4 h.
- **This cost cannot be avoided under D3.** To stop a rush with a 1 h smaller floor from winning, its non-scaling charge must exceed the normal's by at least 1 h. With Ȳ = 1.5, that forces the normal's capped charge to at least 2 h, so T_N,∞ ≥ 5 h versus 3 h uncapped.
- **The cost only applies to very experienced players.** Reaching n = 150 takes about **2,400 production hours (≈ 100 days of continuous production)** at launch and about 1,900 h in v2. In calendar time that is likely 4–6 months of daily play. So the cost applies only to the most invested players.
- Revision 1's habitat timers hid this cost inside the floors. D2 makes it visible.

### 5.3 Sensitivity: κ must be derived from the sim, not from this table

| Change (others as recommended) | v1 min G at κ = 16 | Strict κ re-derived | v1 cost at n = 150 at that κ |
|---|---|---|---|
| f = 0.5 h per biome | 1.078 (safe, wasted gap) | 33 | 0% |
| **f = 1.5 h per biome** | **0.940 (rush clearly better)** | **11.0** | **+16%** |
| B_R = 0.65 B_N | 0.984 | 14.1 | +5% |
| B_R = 0.85 B_N | 1.025 | 18.9 | 0% |
| Rush intake J_R = 1.1 | **0.963** | 11.4 | +15% |
| Rush intake J_R = 0.9 | 1.010 | 17.1 | 0% |

- v2 is less sensitive. Alpine-stop stays the binding route at κ ≈ 16 in every case above, with min G = 1.000.
- The exception is **f = 1.5**: there v2 needs **κ = 10.7** (cost **+6.3%** at n = 150). At κ = 16 the rush would be 13% faster (G = 0.871).
- **Rule: κ[v] = the largest jar rate for which the reference sim gives min G ≥ 1.00 over all n and all alternative routes.** With equal intakes this is simply ΔW / ΔF.

### 5.4 Boosts
- **Patron** (×1.25) reaches the cap at n = (16/1.25 − 1) × 10 = **118**.
- **Rewarded-ad ×2** reaches it at n = **70** while the ad is active. Above that, an ad boost does not speed the Refinery further.
- Both are on separate boards or are temporary, and the cap only ever narrows the rush gap. So no bracket breaks. The ad wording ("2× production") should not imply "2× charge" at high n.

---

## 6. Values the designer must still decide

| # | Value | Needed for | My placeholder |
|---|---|---|---|
| 1 | **Accept the v2 run-length trade-off**: (A) v2 T0 ≈ 47 h with D3 met, or (B) v2 T0 ≈ 72 h with the v2 rush staying ≥ 13% slower for veterans (D3 relaxed in v2 only) | `CAP_CHARGE_TARGET[v2]`, Y_Grove, Y_Cloud | **A** |
| 2 | **Accept a 45 h launch charge phase** (62% of the run, built ≈ hour 27). This is the price of Y_Alpine = 2.0. The alternative is Y_Alpine 4.25 with an 18 h charge, which makes D3 and D4 incompatible in v2 (§2.4). | Y_Alpine, X[v1] | 45 h |
| 3 | **Measured floor gap ΔF** per extra biome (unlock and placement taps that do not scale with income) | κ (very sensitive, §5.3) | 1.0 h |
| 4 | **Sale values S_b** | AFFINITY = Y/S | ×1.25 per biome; **S_Alpine must be < 2.0** |
| 5 | **Graded Synergy formula** (0–10, U = 5, money-driven: flower-to-bee ratio plus Habitat Health) | `CAP_SYNERGY_MIN`, plot cap | 0–10, U = 5 |
| 6 | **Reference sims** (n = 0, unboosted, one per content version): J_ref, I_ref, jar mix, B_R/B_N, J_R/J_N | X, κ, build cost | §2.2 |
| 7 | **Strict vs tolerance cap**: G ≥ 1.00 (κ 16/16) or G ≥ 0.98 (κ 19/17.3) | κ | Strict |
| 8 | **Flat vs graduated cap** | κ above n = 150 | Flat |
| 9 | **Starting-plot cap** in plots (= Synergy 3 at zero extra hives) | Whitelist | Synergy 3 |

Once items 3–6 exist, recompute in this order:
1. ΔF and ΔW from the sim.
2. Check G(0) − 1 ≈ (M\* − 1) · ΔF / T0, and adjust X[v1] if needed.
3. κ = largest value with min G ≥ 1.
4. Search Y_Grove, Y_Cloud and X[v2] against the v2 targets.
5. AFFINITY = Y/S.
6. Re-run §4 and §5.

---

## 7. Open questions

1. **Cap UX and fiction.** The Refinery "processes at most N jars per hour". The slider auto-limits and the panel shows "at capacity, extra honey is sold". Is a visible cap acceptable in a cozy game? It binds only above about 100–150 Crystals, or about 70 during an ad boost.
2. **Steep late affinity in v2.** With Cloud at Y = 30 (affinity ≈ 15), Meadow and Alpine supply about 13% of the v2 normal route's Royal Honey: (0.33 + 0.58) / 7.06. Gerard flagged "earlier biomes feel pointless" as a risk. Is that acceptable as the cost of D4?
3. **Alpine-stop ties the full route at n ≈ 150 in v2** (G = 1.000). It is never faster, but biomes 3–4 add no time advantage at exactly that Crystal count. Lowering κ to 15 gives Alpine-stop a 2% margin, but pushes the rush to G(150) = 1.07, outside D3. Which matters more there?
4. **v2 rush at n = 0 is 2.1× slower.** New post-launch players are clearly steered to the full route (good). For a speedrun board, though, Meadow-only v2 runs are a different sport below about 100 Crystals. Should a Meadow-only category open with v2? The data is already recorded.
5. **Leaderboard tiers.** v2 G falls from 1.24 to 1.04 between n = 100 and 150. The 101+ tier should be split (e.g. 101–150, 151+) so the rush's viability is consistent within a tier.
6. **Long charge feel.** A 45 h launch charge at 80% divert can feel stalled. The 20% remainder still grows the farm, and the ETA updates. Should the panel also show "Royal Honey per hour" growth so progress stays visible?
7. **Free-player wall-clock.** The 4 h offline cap turns the 72 h launch run into about 84 h for free players who sleep. Is the 3-day target meant for production time (my assumption) or for wall-clock time?
8. **Carried over from revision 1:**
   - Hysteresis on the Synergy pause.
   - Whether the Refinery can be moved between biomes before charging starts.
   - Whether intermediate v2 routes (Alpine-stop, Grove-stop) get visible categories.
