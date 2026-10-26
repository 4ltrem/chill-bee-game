---
author: terry
type: balance
status: applied
description: Provisional native-species values; launch run length and Alpine affinity 1.92
---
# Native Bee Species Balance (provisional values)
**Author:** Terry, the Progression Tree Expert
**Sources:** `GDD.md` (Tree C, Native Bee Species table, Capstone, Land/Grid, Glossary), `proposals/design/native-species.md` (Gerard, §5 parameter list), `proposals/balance/refinery-parameters.md` (revision 2, the run model reused here), `proposals/balance/royal-crystal-balance.md`.
**Settled inputs (not changed here):** no Meadow fill-rate species; Meadow = sweat bees (pollination) + leafcutter bees (sale value) + bumble bees (Journal-only visitor); Alpine = bumble (fill rate), mason (pollination), mining (sale value); Grove/Cloud fictional, and only one Cloud species may raise Refinery yield. Quality = sale value only. One capped native bonus per biome (species + small abundance term), applied only in that biome. No Journal bonus. Rush "equal for veterans". First run ≈ 72 h at launch, ≈ 47 h post-launch. Base S_Alpine < 2× Meadow. Starting plot ≤ Synergy 3. Crystal = +10% additive.
**Status:** Proposal. Every number comes from the stand-in model in `refinery-parameters.md` §2, extended in §1 below. Re-derive once the reference sims exist.

---

## 0. Summary

| Item | Result |
|---|---|
| Species dropped into the old parameters | Normal launch run 72 → **64.6 h**, v2 run 46.8 → **42.8 h**. The rush gains only 2 h (85.5 h). In v2, **Alpine-stop becomes faster than the full route** (min G = 0.991 at n ≈ 135). The old parameters do not survive species. |
| Cause | Alpine bumble bees (+20% fill) raise the normal route's Royal Honey rate by 13% and shift its jar mix towards Alpine, which pushes Alpine-end Ȳ above the 1.5 bound from `refinery-parameters.md` §2.4. Pollination and sale-value species cut B by about 2 h on both routes (near neutral). |
| Fix (recommended) | (1) Fold the bumble bees into the Alpine yield: **Y_Alpine 2.0 → 1.92**, so Ȳ_Alpine-end stays 1.5 with bumble bees present. (2) Hold 72 h by adding **≈ 2.5 base-hours of Alpine build cost** (units/land), **not** by raising X. (3) **X[v1] 67.5 → 73.9**, **X[v2] 80 → 83**, **Y_Cloud base 27.3** (= 30 with the Stardust yield bonus). |
| Run length after the fix | Launch **72.0 h** (charge 44.8 h, unchanged share). Post-launch **46.0 h**. |
| Rush gap G at 0 / 20 / 50 / 150 Crystals (launch) | **1.276 / 1.229 / 1.171 / 1.003** (was 1.215 / 1.173 / 1.121 / 1.004). Never below 1.00. |
| κ verdict | **κ = 16 × J_ref still holds** in both versions. Strict maxima: v1 16.43 (was 16.5), v2 16.48 (was 16.0). The cost changes: the launch normal route now hits the cap from n ≈ 135, so cap cost at n = 150 rises **0% → 3.8%**. |

---

## 1. How species enter the model

Run model unchanged: **T_k(n) = F_k + B_k / M + X / (min(M · J_k, κ) · Ȳ_k)**, M = 1 + 0.1n.

| Channel | Enters the model as | Fades with Crystals? |
|---|---|---|
| Pollination (sweat, mason, glowcap, drift) | Synergy per raw flower × (1 + p). Lowers the habitat money inside B (Meadow to 5 or 7, Alpine to 5 or 6, etc.). | Yes (÷M) |
| Sale value (leafcutter, mining, Stardust, abundance) | Income × (1 + q) on that biome's share of income after the species arrives. Lowers B. **Never** enters Royal Honey (Royal Honey uses base S × AFFINITY). | Yes (÷M) |
| Fill rate (bumble, lantern) | That biome's jars × (1 + f): raises income (B), raises J, and shifts the jar mix (Ȳ). | J part does not fade until κ binds |
| Refinery yield (Stardust only) | Y_Cloud × (1 + y), folded into Y_Cloud | No |

Stand-in assumptions added to `refinery-parameters.md` §2:
- **Raw Habitat Health (HH) scale:** 10 HH = 1 Synergy level of raw flower habitat, before pollination. Synergy = raw × (1 + pollination). Thresholds use raw HH (Gerard §2.1, no runaway loop).
- **Habitat cost inside B (base hours):** Meadow 0.6 h per level to 5, 1.0 h per level from 5 to 7 (Meadow 5 = 3 h, Meadow 7 = 5 h, inside B_N = 24 and B_R = 18). Alpine 0.5 h/level. Grove 0.25, Cloud 0.21 h/level.
- Unit and habitat spending interleave evenly within a biome phase; income shares follow the jar mix × base sale values (S = 1, 1.25, 1.5625, 1.953).
- Launch phases: Meadow 10 h, Alpine 14 h (+2.5 h recommended absorption). v2 adds Grove 5 h, Cloud 5 h. Floors unchanged (ΔF = 1 h per biome).
- The throughput cap is applied to jars in proportion to the jar mix (as before).

---

## 2. Parameter table (provisional)

Raw HH thresholds are in the 0–100 scale above. U = unlock Synergy 5; host minima from `refinery-parameters.md` (Meadow 7, others 6).

| Biome | Species | `SPECIES_EFFECT_TYPE` | `SPECIES_EFFECT` | `SPECIES_HH_THRESHOLD` (raw) | `SPECIES_FLOWER_MIN` (units of listed flowers) | `SPECIES_TIER_REQ` |
|---|---|---|---|---|---|---|
| Sunny Meadow | Sweat bees | Pollination | **+25%** | **35** | 2 (black-eyed Susan / goldenrod) | None |
| Sunny Meadow | Leafcutter bees | Sale value | **+10%** | **40** | 2 (wild bergamot / New England aster) | None |
| Sunny Meadow | Bumble bees (visitor) | None (Journal only) | 0 | 40 | 1 any Meadow wildflower | None |
| Alpine Valley | Bumble bees | Fill rate | **+20%** | **25** | 2 (fireweed) | None |
| Alpine Valley | Mason bees | Pollination | **+25%** | **30** | 2 (Alpine wildflower slot, TBD) | None |
| Alpine Valley | Mining bees | Sale value | **+10%** | **40** | 3 (fireweed + Alpine slot, any mix) | None |
| Enchanted Grove | Lantern bee (fictional) | Fill rate | **+20%** | **25** | 2 | None |
| Enchanted Grove | Glowcap digger (fictional) | Pollination | **+25%** | **35** | 2 | None |
| Cloud Gardens | Drift bee (fictional) | Pollination | **+25%** | **25** | 2 | None |
| Cloud Gardens | Stardust bee (fictional) | Sale value + yield | **+10% sale**, `SPECIES_YIELD_BONUS` **+10%** | **40** | 3 | None (it is the only candidate if a tier gate is ever wanted: full route only, so harmless) |

| Global parameter | Value | Rationale |
|---|---|---|
| `SPECIES_LIST[v1]` | Meadow: sweat, leafcutter, bumble (visitor). Alpine: bumble, mason, mining. | Settled. |
| `SPECIES_LIST[v2]` | v1 + Grove: lantern, glowcap. Cloud: drift, Stardust. | Gerard §1.2. Stored per content version with `CAP_PARAMS`. |
| `SPECIES_LEAVE_MARGIN` | **5 raw HH** (half a Synergy level) | Big enough to stop flicker when one hive is placed. Sweat bees leave below 30, which is the starting-plot cap, so they can never be "kept" by starting plots alone. |
| `NATIVE_ABUNDANCE_COEF` | **0.05** (+5% max) | "Small". Normal Meadow at raw 40 gets +1.7%; the rush at raw 56 gets +4.3%. |
| `NATIVE_ABUNDANCE_CURVE` | Linear in raw HH from **30 → 60**, flat above; **sale-value channel only** | Zero at the starting-plot cap (no minute-zero bonus). Kept off the fill channel so the Meadow never gets a fill-rate bonus through the back door (see §6, "Meadow fill +5%"). |
| `SPECIES_YIELD_BONUS[Stardust]` | **+10%**, folded: Y_Cloud base **27.27** → **30.0** with Stardust present | Gerard §3.3: folded into Y_Cloud, not on top. |
| Y_Alpine (`AFFINITY` input) | **1.92** (was 2.0); AFFINITY_Alpine = 1.92 / 1.25 = **1.53** | Keeps Ȳ_Alpine-end = 1.5 with bumble bees present: (0.5 × 1 + 0.6 × 1.917) / 1.1 = 1.5. Must be fixed before launch (D4 freeze). |
| `CAP_CHARGE_TARGET` | v1 **73.9 × J_ref** (was 67.5); v2 **83 × J_ref** (was 80) | v1: holds T0 = 72 h with the same 44.8 h charge. v2: largest value with the rush G(150) ≤ 1.05 and every alternative route ≥ 1.00. |
| Alpine build cost absorption | **+2.5 base-hours** of Alpine unit/land cost (B_N 21.9 → 24.2) | Holds T0 = 72 h without raising X. See §4.2 for why X is the wrong lever. |
| `CAP_THROUGHPUT_MAX` (κ) | **16 × J_ref** both versions (unchanged) | §5. |

**Threshold checks (Gerard §2.1, §5 checks 3–4):**
- Meadow: plot cap 30 < sweat 35 < leafcutter 40 = raw HH at which Synergy reaches U = 5 with sweat bees (40 × 1.25 = 50). So the normal route earns both Meadow species exactly at the unlock point; nothing above U rewards only the rush. No species is reachable from starting upgrades.
- Alpine, Grove, Cloud: every threshold ≤ raw 40 = Synergy 5 with that biome's pollinator, so Alpine-stop and Grove-stop gain nothing the full route lacks. All are below the host operating point (raw 48 for Synergy 6).
- Base S_Alpine must now be **< 1.92 × S_Meadow** (not 2.0) for Alpine affinity to stay above Meadow's. The placeholder 1.25 is fine; recommend ≤ 1.6 as before.
- Royal Honey per jar uses base S × AFFINITY; sale bonuses are market-only (confirmed in the model).

---

## 3. Per-biome caps (`NATIVE_CHANNEL_CAP[biome][channel]`)

The designer's "one capped bonus per biome" is implemented as one bucket per biome with a sub-cap per channel, because the channels are different quantities (Synergy per flower, $ per jar, jars per hour) and cannot be summed meaningfully into one number. Each cap is exactly the sum of the effects that can reach it, so caps bind only if a future species or research is added.

| Biome | Fill rate | Pollination | Sale value (species + abundance) | Refinery yield | Bucket total |
|---|---|---|---|---|---|
| Sunny Meadow | **0 (hard)** | 0.25 | 0.15 | 0 (hard) | 0.40 |
| Alpine Valley | 0.20 | 0.25 | 0.15 | 0 (hard) | 0.60 |
| Enchanted Grove | 0.20 | 0.25 | 0.05 (abundance only) | 0 (hard) | 0.50 |
| Cloud Gardens | 0 | 0.25 | 0.15 | 0.10 | 0.60 |

- The Meadow fill and all launch yield caps are **hard zeros**: code should reject any source in those channels, including future research.
- Meadow sale cap 0.15 has little headroom: at 0.30 the launch rush becomes faster at n = 150 (G = 0.999, §6).

---

## 4. Effect on run length

### 4.1 Species added to the old parameters (no re-tune)

| Route (n = 0) | Without species | With species, old X/Y/κ | Change |
|---|---|---|---|
| Launch normal | 72.0 h | **64.6 h** | −7.4 h (B −2.1 h, charge −5.3 h from bumble bees) |
| Launch rush | 87.5 h | 85.5 h | −2.0 h (B only) |
| v2 normal | 46.8 h | **42.8 h** | −4.0 h |
| v2 Alpine-stop min G | 1.000 | **0.991 at n ≈ 135** | D4 broken |

### 4.2 Why not just raise X to get 72 h back
Raising X to 80.1 restores 72 h, but the rush pays X at yield 1 while the normal route pays it at 1.65 RH per jar-unit. The rush gap widens: G = 1.36 at n = 0 and **1.052 at n = 150**, just outside "equal for veterans", and fixing that needs κ ≈ 15.5 (cap cost ≈ 5.5% at n = 150). In v2 it is worse: holding 46.8 h needs X = 126 and the rush stays ≥ 1.36 slower forever. So the time species save must be absorbed in **build-up (B) of the biomes only the normal route uses**, not in X.

### 4.3 Recommended re-tune (Y_Alpine 1.92, +2.5 h Alpine cost, X 73.9 / 83, Y_Cloud base 27.27)

| Route | F | B (M = 1) | J | Ȳ | T at n = 0 |
|---|---|---|---|---|---|
| Launch normal | 3 | 24.23 | 1.10 | 1.50 | **72.0 h** (charge 44.8 h) |
| Launch rush | 2 | 16.03 | 1.00 | 1.00 | 91.9 h |
| v2 normal (Cloud) | 5 | 33.18 | 1.595 | 6.69 | **46.0 h** (charge 7.8 h) |
| v2 Alpine-stop | 3 | 24.23 | 1.10 | 1.50 | 77.5 h |
| v2 Grove-stop | 4 | 29.09 | 1.344 | 2.42 | 58.6 h |

Launch keeps its 45 h charge phase (62% of the run). v2 lands at 46 h, inside the ~47 h target.

---

## 5. Rush vs normal and the throughput cap

### 5.1 Rush gap G = T_route / T_normal (κ = 16, unboosted)

**Launch (v1):**

| n | M | T_normal | Old G (no species) | **New G** |
|---|---|---|---|---|
| 0 | 1 | 72.0 | 1.215 | **1.276** |
| 20 | 3 | 26.0 | 1.173 | **1.229** |
| 50 | 6 | 14.5 | 1.121 | **1.171** |
| 100 | 11 | 9.27 | 1.054 | 1.097 |
| 150 | 16 | 7.59 | 1.004 | **1.003** |
| 200 | 21 | 7.23 | 1.017 | 1.020 |
| 300 | 31 | 6.86 | 1.032 | 1.040 |

Min G = **1.003 at n = 150**. The rush is clearly slower for new players (27.6%, up from 21.5%) and converges to parity at the same Crystal count as before.

**Post-launch (v2):**

| n | T_normal | Rush (old → new) | Alpine-stop (old → new) | Grove-stop (old → new) |
|---|---|---|---|---|
| 0 | 46.0 | 2.14 → **2.20** | 1.72 → **1.69** | 1.32 → **1.28** |
| 20 | 18.65 | 1.83 → **1.88** | 1.52 → **1.49** | 1.23 → **1.19** |
| 50 | 11.83 | 1.53 → **1.57** | 1.33 → **1.30** | 1.14 → **1.11** |
| 100 | 8.79 | 1.24 → 1.25 | 1.14 → 1.11 | 1.05 → 1.02 |
| 150 | 7.85 | 1.037 → **1.043** | 1.000 → **1.016** | 1.016 → **1.015** |
| Min over all n | | 1.043 (n 150) | 1.000 → **1.009** (n ≈ 135) | 1.008 → **1.004** (n ≈ 109) |

- Alpine-stop's tie at n = 150 (old open question Q3) is gone: Grove/Cloud species give the full route something Alpine-stop cannot get.
- **Grove-stop is now the narrowest route** (1.004 at n ≈ 109) because lantern bees help it too.
- Alpine-stop and Grove-stop stay ≥ 1.10 at n = 0.

### 5.2 κ re-derived with species present

| | Strict κ_max (min G ≥ 1.00, all routes, all n) | Binding route | κ = 16 holds? | Cap cost on normal at n = 150 / 200 |
|---|---|---|---|---|
| v1 old | 16.5 | Rush | Yes | 0% / 10.7% |
| **v1 with species** | **16.43** | Rush | **Yes** | **3.8% / 15.0%** |
| v2 old | 16.0 | Alpine-stop | Yes (exactly) | 2.9% / 4.8% |
| **v2 with species** | **16.48** | Grove-stop | **Yes, with margin** | **3.8% / 5.8%** |

**Verdict: keep κ = 16 × J_ref for both versions.** The guarantee holds. The difference is cost: bumble bees give the launch normal route J = 1.1, so it hits the cap at M = 16 / 1.1 = 14.5 (**n ≈ 135**, was 150). Above that, the bumble bee "+20% fill" no longer speeds charging, only sales. In absolute terms this is still under 0.3 h per run at n = 150 and about 1 h at n = 200.

---

## 6. Sensitivity (tuned values fixed, one change at a time)

| Change | v1 G(150) | v1 κ_max | v2 min G | v2 κ_max |
|---|---|---|---|---|
| Recommended | 1.003 | 16.43 | 1.003 | 16.48 |
| No sweat bees | 1.014 | 17.74 | 1.005 | 16.62 |
| No leafcutter | 1.007 | 16.83 | 1.003 | 16.48 |
| **No bumble bees** (player skipped fireweed) | **0.986** | **14.27** | 1.004 | 16.56 |
| No mason / no mining | 1.002 | 16.2–16.3 | 1.003–1.005 | 16.5–16.7 |
| No lantern / no drift | 1.003 | 16.43 | 1.007 / 1.002 | 16.46 / 16.21 |
| Stardust away | — | — | **0.997** (Grove-stop) | 15.64 |
| Meadow sale cap 0.30 | **0.999** | 15.93 | 1.003 | 16.48 |
| Meadow pollination cap 0.50 | 1.001 | 16.17 | 1.003 | 16.46 |
| **Hypothetical Meadow fill +5%** | 1.002 (min **0.998**) | 15.80 | 1.003 | 16.48 |
| Bumble +30% (Y_Alpine not re-folded) | 1.011 | 17.33 | **1.000** | 15.98 |

Readings:
- **Meadow species are cheap to tune but have little headroom**: each +0.15 of Meadow sale or +0.25 of Meadow pollination costs ~0.3–0.5 of κ_max. Even a 5% Meadow fill bonus breaks strict parity, confirming the settled "no Meadow fill" decision.
- **The tuning assumes the normal route has its Alpine and Cloud species.** A normal-route player without bumble bees (or without Stardust in v2) can be beaten by the rush or Grove-stop at high n. That is a habitat-neglecting run, but it is also the main way κ could look wrong in playtests.
- **Bumble bee size and Y_Alpine are coupled.** If the bumble effect changes, re-fold Y_Alpine = (1.5 × (1 + f/2) − 0.5) / (0.5 × (1 + f)) before launch.

---

## 7. Risks

1. **Y_Alpine must change before launch** (2.0 → 1.92). After launch it is frozen (D4); species added later could not be re-folded without a new content version. The GDD rule "Alpine honey < 2× Meadow" becomes "< 1.92×".
2. **Run length now depends on species presence.** Losing bumble bees costs the launch normal route about 6.6 h (72 → 78.6 h). The build-mode "would leave" preview (Gerard §3.1) is a balance requirement, not just UX.
3. **Higher cap cost for veterans at launch** (0% → 3.8% at n = 150). Small in hours, but the "at capacity" panel appears ~15 Crystals earlier.
4. **v2 margins are thin.** Grove-stop at 1.004 and Alpine-stop at 1.009 depend on ΔF = 1 h, which is still unmeasured (`refinery-parameters.md` §5.3: ΔF = 1.5 h needs κ ≈ 11).
5. **Abundance curve favours the rush slightly** (its Meadow sits at raw 56 vs 40). Money-only and fades with M, but do not raise the coefficient above ~0.05 without re-running.
6. **Alpine flower list is still TBD**; mason and mining bees depend on the "Alpine wildflower slot". If fireweed is the only Alpine flower at launch, set mason's flower requirement to fireweed.
7. **Stand-in model.** Habitat costs per level, phase lengths and interleaving are guesses. The species' effect on B (~2 h) is the least certain number; the fill-rate effect on J and Ȳ is structural and reliable.

---

## 8. Open questions for the designer

1. **Absorb the species speed-up in Alpine build costs (recommended) or let the launch run shrink?** Options: (A) +2.5 h Alpine cost, X = 73.9, T0 = 72 h, G = 1.276 → 1.003; (B) keep X = 67.5 and accept T0 ≈ 66 h, G(150) ≈ 1.02 at κ = 16; (C) raise X to 80 with no cost change, T0 = 72 h but G(150) = 1.052 (misses "equal for veterans") unless κ drops to ~15.5.
2. **Approve Y_Alpine = 1.92** (fold bumble bees into the yield), or cut the bumble bee effect to keep Y_Alpine = 2.0? Cutting it to about +5% is roughly neutral but makes Jaime's "faster fill meter" barely visible.
3. **"One capped bonus" interpretation:** OK to implement it as one bucket per biome with per-channel sub-caps (§3)? A single scalar cap across different channels would need an exchange rate between Synergy, $ and jars.
4. **Abundance term on sale value only** (my proposal) or on all channels except Meadow fill?
5. **Stardust yield +10% folded into Y_Cloud = 30** (my proposal) vs on top (Y_Cloud 33, wider v2 margins but v2 runs ~0.5 h shorter)?
6. **v2 X = 83 gives T0 = 46 h.** Acceptable, or should Grove/Cloud costs absorb more so T0 = 47 h?
7. **Measure ΔF and the habitat cost per Synergy level** in the vertical slice; both feed directly into κ and into how much the Meadow species are worth to the rush.
