---
author: terry
type: balance
status: applied
description: Royal Crystal boost formula (+10% additive) and extra starting hives
---
# Royal Crystal Balance Report
**Author:** Terry, the Progression Tree Expert
**Source of truth:** `GDD.md` (Phase 3 / Royal Crystal, Tree C Hive Balance, Capstone, Leaderboards, Patron Pass). No separate progression file exists yet.
**Scope:** Task 1 (permanent production boost formula), Task 2 ("extra starting hives" and Habitat Health).

---

## Assumptions

Most economy numbers in the GDD are TBD, so this report uses explicit stand-in models. The conclusions depend on the *shape* of each formula, not on exact values.

1. **One Crystal per run.** The capstone produces one Royal Crystal and ends the run (GDD §3 Capstone). So `n` = the number of completed resets.
2. **The Crystal boost multiplies all honey income.** M(n) is a global multiplier on production, applied multiplicatively with research, native-bee synergy, biome honey value and Patron.
   - A: M = 1 + 0.10n
   - B: M = 1 + 0.05n
   - C: M = 1.03^n
3. **Three run-time models.** T(n) is run time relative to the n = 0 run (T0 = 1).
   - **Linear (upper bound on compression):** T = 1/M. Every phase is money-gated and scales with income.
   - **Floor (most realistic, used for the conclusions):** T = f + (1 − f)/M with f = 0.15. About 15% of a run is wall-clock time that does not scale with income: Phase 1 manual harvests (which the GDD says Crystals never skip), flower growth, native-bee attraction, Habitat Synergy build-up, and unit placement.
   - **Log (reinvestment-dominated):** T = 1 − ln M / ln G with G = 10⁴. In-run income grows exponentially through reinvestment, and the capstone needs about 10⁴× starting income. A multiplier then shaves off a *fixed amount* of time rather than a fraction.
4. **Patron +25% is a separate multiplicative layer** (×1.25), not added to the Crystal percentage pool (see Task 1 §4 for why this matters).
5. **Starting-upgrade whitelist items have max levels**, like Tree A/B upgrades. Their value is bounded, so at high n the percentage boost carries most of the prestige power.
6. **First-biome capstone rush** is modelled as T_route = F_route + W_route / M:
   - F = non-scaling floor time.
   - W = money-gated work at M = 1.
   - Illustrative values: normal route W = 10, F = 2 (four biome habitat setups). Rush W_r = 20 (only biome-1 honey value, so 2× less money-efficient), F_r = 0.5 (one habitat setup, no biome unlocks).
   - The rush wins when M > (W_r − W)/(F − F_r) = 10/1.5 ≈ **6.7**. The exact crossover is TBD. What matters is that **a crossover multiplier M\* exists**, and each option reaches it at a different n.

---

## Task 1 analysis

### 1.1 Multiplier and relative run time

| n | A: M | A: T lin / floor / log | B: M | B: T lin / floor / log | C: M | C: T lin / floor / log |
|---|---|---|---|---|---|---|
| 1 | 1.10 | 0.91 / 0.92 / 0.99 | 1.05 | 0.95 / 0.96 / 1.00 | 1.03 | 0.97 / 0.98 / 1.00 |
| 5 | 1.50 | 0.67 / 0.72 / 0.96 | 1.25 | 0.80 / 0.83 / 0.98 | 1.16 | 0.86 / 0.88 / 0.98 |
| 10 | 2.00 | 0.50 / 0.58 / 0.93 | 1.50 | 0.67 / 0.72 / 0.96 | 1.34 | 0.74 / 0.78 / 0.97 |
| 20 | 3.00 | 0.33 / 0.43 / 0.88 | 2.00 | 0.50 / 0.58 / 0.93 | 1.81 | 0.55 / 0.62 / 0.94 |
| 50 | 6.00 | 0.17 / 0.29 / 0.81 | 3.50 | 0.29 / 0.39 / 0.86 | 4.38 | 0.23 / 0.34 / 0.84 |
| 100 | 11.0 | 0.09 / 0.23 / 0.74 | 6.00 | 0.17 / 0.29 / 0.81 | 19.2 | 0.05 / 0.19 / 0.68 |

Worked example (floor model, A at n = 20): 0.15 + 0.85/3.0 = 0.15 + 0.283 = 0.433.

### 1.2 How rewarding each reset feels (marginal gain vs the previous run)

The gain from the n-th reset is M(n)/M(n−1) − 1.

| Reset # | A | B | C |
|---|---|---|---|
| 1st | +10.0% (1.10/1.00) | +5.0% | +3.0% |
| 5th | +7.1% (1.5/1.4) | +4.2% (1.25/1.20) | +3.0% |
| 20th | +3.4% (3.0/2.9) | +2.6% (2.0/1.95) | +3.0% |
| 50th | +1.7% (6.0/5.9) | +1.4% (3.5/3.45) | +3.0% |

- **A** front-loads its reward. The first reset gives a +10% run that is about 9% shorter. In a cozy game this first reset matters most, because it teaches "prestige is worth it". Gains shrink after about 20 resets.
- **B** has A's shape at half the size. The first reset (+5%, about a 4% shorter run) is barely noticeable, and by the 50th reset the gain is negligible.
- **C** gives a flat +3% forever. That is the weakest start: the first reset is about 2.5% shorter, which players will not perceive, and resets 1–10 feel pointless. Its relative gain only overtakes A after reset 33 (+3.0% vs 1/(1 + 0.1·32) = +2.4%).

**Mitigating factor:** each Crystal also grants a whitelisted starting upgrade, so even a small percentage reset delivers a felt, qualitative change in Phase 1. This helps B and C most early on, and A late.

### 1.3 Long-term motivation (indefinite expansion and stacking biomes)

Cumulative calendar time to earn n Crystals, in units of the first run's length (T0):

| Crystals | A | B | C |
|---|---|---|---|
| 20 | 11.3 | 14.1 | 15.3 |
| 50 | 18.3 | 25.4 | 26.5 |
| 100 | 24.4 | 36.3 | 32.5 |
| 200 | 30.9 | 48.4 | **34.2** |

Calculation: linear model, Σ_{k<n} 1/M(k).

- **C has a feedback loop that diverges.** Crystals per hour is proportional to M, so dn/dt ∝ 1.03^n. The sum Σ 1.03^−k converges to 1/(1 − 1/1.03) = **34.3 T0**. In the pure money model a player would earn *unlimited* Crystals in finite time. Only the non-scaling floors stop it: with the floor model, 200 Crystals take 59.1 T0, of which 30 T0 is pure floor. In practice, C players end up farming 15%-floor runs back to back. That is grind, not cozy.
- **A and B grow M only exponentially in calendar time** (dn/dt ∝ 1 + kn), so growth stays predictable and tunable.
- Indefinite land expansion and stacking biomes already provide in-run growth. The prestige boost does not need to supply open-ended power; it only needs to make each new world start faster and feel fresher. The additive options do this without competing with in-run growth for "where does the big number come from".

### 1.4 Speedrun considerations

**Bracket spread.** Spread is the M ratio between the top and bottom of a tier; lower is fairer.

| Tier | A | B | C |
|---|---|---|---|
| 0 | 1.00 | 1.00 | 1.00 |
| 1–5 | 1.5/1.1 = 1.36× | 1.25/1.05 = 1.19× | 1.159/1.03 = 1.13× |
| 6–20 | 3.0/1.6 = 1.88× | 2.0/1.3 = 1.54× | 1.806/1.194 = 1.51× |
| 21+ (capped at 100 for illustration) | 11/3.1 = 3.5× | 6/2.05 = 2.9× | 19.2/1.86 = **10.3×** |

- **C breaks the open-ended 21+ tier.** The tier's spread grows without bound. However, C has the neatest structure for *fixed-width* tiers: every 14 Crystals is exactly ×1.51.
- **A and B spreads shrink in relative terms as n grows.** Tiers can widen geometrically (e.g. 0, 1–5, 6–15, 16–35, 36–75, 76+), and the 21+ tier's spread stays under 2× up to n ≈ 60 for A.
- **Recommendation for any option:** split 21+ into at least two more tiers at launch of online leaderboards.

**First-biome capstone rush.** The rush becomes dominant when M ≥ M\*. Crystals needed to reach a given M:

| M | A: n = 10(M − 1) | B: n = 20(M − 1) | C: n = ln M / ln 1.03 |
|---|---|---|---|
| 2 | 10 | 20 | 23 |
| 5 | 40 | 80 | 54 |
| 6.7 (illustrative M\*) | 57 | 114 | 64 |
| 10 | 90 | 180 | 78 |
| 20 | 190 | 380 | 101 |
| 50 | 490 | 980 | 132 |

- Every option eventually makes the rush dominant, because a pure income multiplier only compresses the money-gated part of a run. Both routes speed up by the same factor, and the route with less floor time wins.
- **Under A and B this crossover is reached once and the gap then grows slowly.** The designer can push M\* out of reach of realistic play: at one run per day, 57 Crystals is two months for A and four months for B.
- **Under C,** the multiplier goes from M\* to 3× M\* in about 37 resets, and from 10× to 50× in 54 resets. At high n the rush becomes the *only* sensible route, and the normal route through all biomes stops being played in ranked runs. That undermines the GDD's intent that the capstone is "normally only affordable in the last biome".

**Run-time compression across resets (floor model).**

| Option | n = 10 | n = 50 | n = 100 |
|---|---|---|---|
| A | 0.58 | 0.29 | 0.23 |
| B | 0.72 | 0.39 | 0.29 |
| C | 0.78 | 0.34 | 0.19 |

- A compresses the most early. C ends up the most compressed and heads towards the floor (0.15).
- A run floor-dominated at about 15–20% of the original length is mostly Phase 1 and habitat timers. Speedrunners then compete on taps and timers, not optimisation, which is a weaker leaderboard.

**Time-skip (Royal Jelly) brackets.**
- Time skips remove the floor itself. A high-C time-skipped run approaches the linear model, 1/19 ≈ 5% of T0, so the time-skipped board's spread across Crystal tiers is extreme under C.
- Keeping it separate (as the GDD already does) is essential under every option, and doubly so under C.

### 1.5 Interaction with Patron +25% and the starting-upgrade whitelist

**Patron (multiplicative ×1.25, recommended).** The paid edge is a constant 25% under all options. Measured in Crystal-equivalents:
- **A:** 0.25 × M(n) / 0.10. That is 2.5 Crystals at n = 0, 5 at n = 10, and 15 at n = 50. Patron never becomes obsolete, but it also never becomes the main power source.
- **B:** 5 Crystals at n = 0, 10 at n = 10, 17.5 at n = 50. Patron is relatively stronger compared with the Crystal grind.
- **C:** ln 1.25 / ln 1.03 = **7.5 Crystals, always**. This is simple to communicate.

**If Patron were added to the same pool (+25 percentage points),** its value would fade: under A at n = 50, 6.25/6.0 = +4%. Subscribers would feel they lose value as they progress, and boosted brackets would converge with unboosted ones. **Keep it a separate multiplier.**

**Note:** the GDD calls Patron a "honey *value*" multiplier and the Crystal boost a "production" boost. Both multiply income, so they stack multiplicatively either way. Confirm that the wording is intentional.

**Whitelist.**
- Starting upgrades compress Phase 1 by flat amounts, and their value is bounded by item max levels. They therefore lower the *floor* f slightly but cannot eliminate it, because automation and the capstone cannot be pre-bought.
- Combined with C, starting land plus starting hives plus a very large M is the ideal first-biome rush loadout.
- Under A, the whitelist provides most of the felt novelty at high n, where the percentage gains have become small. This is a good division of labour.

### 1.6 Risk of runaway inflation or pointless resets

| Option | Inflation risk | "Pointless reset" risk |
|---|---|---|
| A | Low–moderate. M grows linearly in n (11× at 100). Big numbers in the UI still come from in-run growth. | Moderate after about 40 resets (each gives less than 2%). Mitigated by the whitelist. |
| B | Low (6× at 100). | **High.** The first reset gives +5% and late resets about 1%. Too weak to motivate resetting in a cozy game. |
| C | **High.** 19× at 100 and 132× at 165, with the diverging Crystal-farming loop (§1.3) and rush dominance (§1.4). Later content would need balancing against an unbounded multiplier. | **High early.** +3% for the first ~10 resets is invisible. Low late. |

---

## Task 1 recommendation

**Ranking: A > B > C.**

1. **A (+10% additive) is recommended.** It has the strongest first-reset hook, the most predictable growth (an economy designer can reason about it with one line), bounded bracket spreads, and it pushes the first-biome rush crossover to a high Crystal count. Its weak spot, diminishing late gains, falls exactly where the whitelist and new post-launch biomes add novelty.
2. **B** is safe but under-rewarding. Choose it only if final run lengths turn out short (for example under 1 hour), so players reset often and n climbs fast.
3. **C** is the most dangerous. It is weak exactly when players are deciding whether prestige is worth it (resets 1–10), runaway exactly when the leaderboard needs stability (21+), and it turns the first-biome rush into the dominant route.

**Hybrid.** A hybrid is worth prototyping but is *not clearly better* until run lengths are known. The candidate:
- +10% additive per Crystal, plus a ×1.10 **milestone** multiplier at each Crystal-tier boundary (e.g. 5, 20, 50, 100).
- At n = 100 that gives 11 × 1.10⁴ ≈ 16×.

This restores a noticeable "tier-up" moment late, aligns rewards with leaderboard brackets, and keeps growth piecewise-predictable. Do not use a soft cap on A: it worsens the late "pointless reset" feeling, which is A's only weakness.

**Implementation notes (any option):**
- The Crystal boost and Patron should be separate multiplicative layers.
- Split the 21+ tier further before online leaderboards launch.
- Tune the capstone's Habitat Synergy minimum and biome-unlock structure so that M\* (rush crossover) ≥ M(60) under A.

---

## Task 2 analysis

**The two versions:**
- **(i) Penalised:** extra starting hives obey Hive Balance and lower starting Habitat Health if flowers are insufficient. This is paired with a habitat-positive Crystal option, the starting wildflower plot.
- **(ii) Neutral:** extra starting hives are exempt from Hive Balance.

**Simple per-Crystal value model.**
- One starting hive gives production h.
- One starting plot gives habitat s and roughly supports one hive's flower demand.
- The capstone requires a Habitat Synergy minimum.

| Version | Cost of +h production | Habitat debt |
|---|---|---|
| (i) | 1 Crystal + habitat debt (repaid by 1 plot Crystal or in-run flower purchases) | Yes |
| (ii) | 1 Crystal | None |

**Player feel.**
- **(i)** risks feeling like a "gift that hurts": the meadow starts less healthy, which is off-tone for a cozy restoration game.
  - This is acceptable *if* the loadout screen previews the Habitat Health result, and the penalty is just the normal Hive Balance rule rather than an extra one.
  - The penalty teaches the GDD's educational pillar (managed honeybees compete with native bees) on every reset.
  - The paired plot option gives a satisfying ratio puzzle (Factorio-like), e.g. "3 hives + 2 plots".
- **(ii)** feels better at first glance: free bees, no downside. But it contradicts the rule taught every run. A hive that never competes for flowers is the "ghost bee" the habitat tree is meant to argue against.

**Balance.**
- **(ii)** is strictly dominant over most whitelist items:
  - Production with no trade-off.
  - Native-bee multipliers are untouched, because Habitat Health is not lowered.
  - It frees tiles that would otherwise go to flowers.

  Each extra starting-hive Crystal under (ii) is worth about one hive plus one plot under (i), so it is about twice as efficient. Expected pick rate approaches 100% once the item is affordable, which collapses the whitelist into a single choice.
- **(i)** keeps hives roughly cost-equivalent to other whitelist items. The hive/plot split becomes a real loadout decision that depends on route: the normal route favours more plots for faster biome unlocks, while the rush favours a hive-heavy mix with just enough plots.

**Speedrun potential.**
- **(ii) creates a dominant speedrun build.** All starting-hive Crystals, the Crystal production multiplier, and money-bought flowers only up to the capstone's synergy minimum. In the first-biome rush (§1.4), the only habitat gate is the capstone minimum, and neutral hives lower the cost of meeting it. Combined with Task 1 option C, this is the degenerate route.
  - **Ambiguity to resolve:** under (ii), do neutral hives still count towards the "enough flowers for its bees" Synergy ratio? If they do not, the exploit is larger still, because they become production with no flower requirement at all.
- **(i) has no single dominant build.** The best hive:plot ratio depends on route and Crystal tier, so it varies across brackets. This is desirable for leaderboard variety. The rush still exists but must pay its habitat debt before the capstone, so the GDD's "every run includes restoration" holds.

---

## Task 2 recommendation

**Choose (i): extra starting hives lower starting Habitat Health under the normal Hive Balance rule, paired with a starting wildflower plot option.**

Implementation guidance:
1. No extra penalty: a starting hive affects Habitat Health exactly as a hive placed in-run would.
2. Show a live Habitat Health preview on the Crystal loadout screen, so the trade-off is informed rather than a surprise.
3. Give each whitelist item a max level (e.g. hives and plots each capped around 5–10), so neither scales with n into a rush engine.
4. Optionally, make the wildflower plot cost slightly less Crystal value than a hive. This lets cozy players pick "healthy start" loadouts without feeling punished.

(ii) only makes sense if starting hives are hard-capped very low (about 1–2) and still count towards the Synergy ratio. At that point it is a minor convenience, not a design choice.

---

## Open questions for the designer

1. **Target run length.** What is the target length of run 1 and of a mature run (hours vs days)? This sets how fast n grows and whether option B would be viable.
2. **Non-scaling floor time.** Roughly what share of a run is not money-gated (Phase 1 timers, flower growth, native-bee attraction)? This sets the floor f and the rush crossover M\*.
3. **Biome honey values.** What are the honey value ratios between biomes? This sets how much less efficient the first-biome rush is (W_r/W).
4. **Patron multiplier.** Confirm that Patron +25% is a separate multiplicative layer and not added to the Crystal percentage pool.
5. **Whitelist rules.** Do whitelist items have max levels? Can several Crystals go to the same item?
6. **Leaderboard tiers.** Final Crystal tier boundaries: is a split of 21+ (e.g. 21–40, 41–75, 76+) acceptable?
7. **Neutral hives and Synergy.** If option (ii) is kept anywhere, do neutral hives count towards the Habitat Synergy flower-to-bee ratio?
8. **Milestone hybrid.** Should the milestone hybrid be prototyped alongside A in the vertical slice?
9. **Time-skipped runs.** Should time-skipped runs also have Crystal tiers, given that time skips remove the floor and so widen the spread?
