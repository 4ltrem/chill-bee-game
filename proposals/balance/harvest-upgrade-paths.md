---
author: terry
type: balance
status: applied
decided: 2026-11-05
decision: paths adopted as structure; motor = electric centrifuge, Auto-Sell = truck leaves when full at full price, Deep Frame 2x longer, crate tiers hold more jars and a bigger load, pause ends with motor + auto-scraper; numbers wait for the economy
description: Harvest upgrade paths (uncap, spin, sell, capacity) mapped onto Tree B; structure only, no numbers
---
# Harvest Upgrade Paths (structure only, no values)
**Sources:** `GDD.md` (§1 Phase 2 line, §2 Phase 1 Uncapping & Extraction Minigame, §3 Tree B, §4 Land, Grid & Units).
**Trigger:** The designer's harvest upgrade ideas (2026-11-05): a centrifuge motor, an auto-scraping apparatus after the Long Fork, auto-sell, faster delivery, Deep Frame as 2x longer frames, crate tiers 1-3, and the rule that the first zoom always keeps the hive and the centrifuge in focus. The designer asked for paths only. **No numbers are set here.** Balancing waits until the rest of the upgrades and the economy are defined.

---

## Summary

Mapping labels: **exists** (already a GDD line), **resolves TBD** (fills a TBD in an existing line), **splits** (breaks an existing bundle into separate buys), **conflicts** (differs from current GDD text), **new** (no GDD line yet).

| Path | Step (in order) | Manual tool / automation / capacity | GDD mapping |
|---|---|---|---|
| U. Uncap | U0 Basic uncapping fork (start) | manual | exists (§2 Stage 1) |
| U. Uncap | U1 Heated Uncapping Fork, levels | manual | exists (Tree B) |
| U. Uncap | U2 Long Fork (whole frame in one sweep) | manual | exists; unlock condition is TBD |
| U. Uncap | U3 Uncapping apparatus (auto-scrape) | automation | **splits** Automation (= "automated uncapping hubs"); **resolves TBD** "Long Fork ... link to automation" |
| S. Spin | S0 Hand crank, tap or hold (start) | manual | exists (§2 Stage 2) |
| S. Spin | S1 Centrifuge Gearing, levels | manual | exists (Tree B) |
| S. Spin | S2 Centrifuge motor (auto-spin) | automation | **splits** Automation (= "electric centrifuges") |
| L. Logistics | L0 Crate tier 1 (1 cell), Sell tap (start) | manual | exists (§2 Stage 3); "tier 1" is **new** wording |
| L. Logistics | L1 Crate tier 2 (2 cells) | capacity | **new** |
| L. Logistics | L2 Faster Delivery, levels (truck trip time) | capacity (useful before and after automation) | **new**; resolves nothing, since trip time is TBD |
| L. Logistics | L3 Crate tier 3 (3 cells) | capacity | **new** |
| L. Logistics | L4 Auto-dispatch: truck sells by itself when full | automation | **splits** Automation (= "self-driving sales truck"); one reading of "auto-sell", see §2.3 |
| C. Capacity | C1 Deep Frame | capacity | **conflicts**: GDD has a per-level 2 → 5 jars per frame; the idea is bought frames that are 2x longer |
| C. Capacity | C2 Overflow Storage | capacity | exists (optional) |
| C. Capacity | C3 Overflow Auto-Sell (sells overflow at a discount) | automation (passive) | exists (optional); the other reading of "auto-sell", see §2.3 |
| All | Rule: the first zoom keeps the hive and the centrifuge in focus | constraint | **new** rule; binds C1, S2 and U3 (see §2.6) |

The largest issue is that the motor, the apparatus and auto-dispatch **split the Automation bundle into three buys**. The GDD (§1 Phase 2, §3 Tree B Automation) says the *first* automation buy enters Phase 2 *and* removes the capacity pause. Once the bundle is split, that rule needs a decision (Decision 1).

## 1. Assumptions

1. A step is a **manual tool step** if the player still performs the action, only faster or better. It is an **automation step** if the action happens without input. It is a **capacity step** if it changes how much the chain holds or how fast it empties, without changing who does the work.
2. Each path is ordered internally, so each step unlocks the next. The order *across* paths is a recommendation only (§2.5). It has no numeric basis yet.
3. "Long Fork, then apparatus" is read as: the apparatus requires the Long Fork.
4. "Motor" is read as the GDD's electric centrifuge, not an extra step before it. If the designer means a separate step (a motor that still needs a tap to start, for example), the spin path gains one step, and Decision 2 covers it.
5. The farm currently has one harvest station: one hive, one centrifuge, one crate and one truck. Multi-hive scaling is a gap (§3.2).
6. Every Tree B line uses the exponential cost model in GDD §3. No values are set.

## 2. Paths and recommendation

### 2.1 Uncap path (U): fork, then Heated Fork, then Long Fork, then the apparatus
- **U1 Heated Uncapping Fork** stays as it is: a bigger swipe radius and a clean-cut batch bonus.
- **U2 Long Fork** stays manual: the player still taps the fork icon and makes one sweep. Its GDD unlock condition is TBD. The recommendation is to unlock it at a set Heated Fork level (parameter `long_fork_unlock_heated_level`) rather than at the maximum. That way the Heated Fork's last levels compete with the Long Fork rather than gating it.
- **U3 Uncapping apparatus** = the GDD's "automated uncapping hubs". It requires the Long Fork. This fills the Long Fork's "link to automation TBD" in Tree B.
- **Carry-over after automation:** the GDD turns the Heated Fork into a flat yield bonus once harvesting is automated. **The Long Fork has no carry-over:** after U3 it does nothing. This is a gap (§3.1). The options are (a) accept it, since the Long Fork is a stepping stone, or (b) give it a post-automation effect such as apparatus speed. This report does not choose one.

### 2.2 Spin path (S): crank, then Gearing, then the motor
- **S1 Centrifuge Gearing** stays as it is. After automation the GDD already turns it into a flat cut in extraction time, which then shortens the motor's spin.
- **S2 Centrifuge motor** = the GDD's "electric centrifuges". The recommendation is to require a set Gearing level (`motor_unlock_gearing_level`).
- The motor fits the zoom rule if it sits on the centrifuge's steel lid, in place of the crank.

### 2.3 Logistics path (L): crate tiers, Faster Delivery, auto-dispatch
- **"Auto-sell" has two readings**, and the GDD has room for both. They are different upgrades:
  - (a) **Overflow Auto-Sell** (exists, optional): sells honey that piles up in the overflow buffer, at a discount. It is a passive or offline feature on the capacity path.
  - (b) **Auto-dispatch** (= the GDD's "self-driving sales truck"): the truck leaves to sell by itself when full, so the Sell tap goes away. It is an automation step on the logistics path.
  
  The designer should say which one the idea means, or keep both. Either way, give them **distinct names** so that "Auto-Sell" does not mean two things (Decision 3).
- **Crate tiers 1-3.** The GDD has one jar crate. It holds the empty jars and the full jars that wait while the truck is away (§2 Stage 3). Bottling is one jar at a time, so **"more jars per batch" is ambiguous**. It could mean:
  - (i) a bigger buffer for full jars while the truck is away (fits current Stage 3 text);
  - (ii) several jars filling at once (needs more spigots, so it is a centrifuge change, not a crate change);
  - (iii) a bigger truck load per sale (truck capacity is a separate TBD).
  
  Reading (i) is recommended, because it touches only the crate (Decision 4).
- **Faster Delivery** shortens the truck's trip time (TBD in §2). Under reading (i), the crate tier and Faster Delivery **partly substitute for each other**. A shorter trip means fewer jars wait, and a bigger crate means more jars can wait. Interleaving them (crate T2, then Delivery levels, then crate T3) gives the player a real choice. Both keep their value after auto-dispatch, because the self-driving truck still travels.
- **Auto-dispatch** is recommended last on this path (requires crate T2 or a set Delivery level, `auto_dispatch_unlock`). Selling is a single tap per load, so it is the least repetitive action to automate.
- **Grid cells.** §4's grid holds hive and flower units and rewards honey per tile. A crate that takes 1, 2 or 3 cells either **competes with hives and flowers for tiles**, which is a real trade-off, or sits **off-grid** on a fixed farm plot. The GDD does not say whether the harvest station is on the grid (Decision 5).

### 2.4 Capacity path (C): Deep Frame, Overflow Storage, Overflow Auto-Sell
- **Deep Frame conflicts with the GDD** on two points:
  - **Form:** the GDD has a level upgrade for all frames (max level 3). The idea has *bought frames*, which reads as buying deep frames one by one, so a hive can mix normal and deep frames.
  - **Size:** the GDD has 2 → 5 jars per frame (2.5x at level 3). The idea has frames that are 2x longer. If jars scale with length, that is 2x, or 2 → 4 jars.
- **Knock-on effects:**
  - The free overflow buffer is "one extra full hive, growing with Deep Frame" (§2), so it inherits whichever form is chosen.
  - The bucket holds "several frames' worth of cells" (§2 Stage 2). If frames change size, a frame's worth changes meaning. The recommendation is to **define bucket capacity in cells**, not frames (`bucket_capacity_cells`).
  - More jars per harvest puts more pressure on the crate and truck, which is the motivation for the logistics path.
- **The zoom rule** binds Deep Frame hardest (§2.6).

### 2.5 Recommended order across paths (structure only)
1. Start with the manual tool lines (U1, S1) and the first capacity buy (C1), so harvests are bigger before they get faster.
2. **First automation buy: the motor (S2).** Spinning is the longest repetitive tap-or-hold, and the motor fits the zoom.
3. Then the Long Fork and the apparatus (U2, U3). Uncapping is the tactile heart of Phase 1, so it should stay manual longest.
4. Logistics (L1-L3) can run alongside the rest; auto-dispatch (L4) comes last.

This order is a suggestion for the designer. It cannot be tested until costs exist.

### 2.6 The zoom rule: "the first zoom keeps the hive and the centrifuge in focus"
- **Binds:**
  - **Deep Frame:** a frame twice as long, standing upright above the hive, roughly doubles the height the camera must fit. This adds up with taller hive tiers (§4: stacked hive, hive tower). Either the zoom target is fitted to the tallest frame and hive, or deep frames rise only partly.
  - **Motor:** fits if mounted on the centrifuge lid.
  - **Apparatus:** must stand between or beside the hive and the centrifuge, inside the zoom.
  - **Cell piles** beside the centrifuge: already in the zoom.
- **Does not bind:** the crate and the truck. They are outside the uncapping zoom today (§2 Stage 3 plays on the farm view).
- **Gap:** after full automation, does the zoom happen at all? §1 says manual screens "remain accessible". The question is whether the player can still choose to enter the zoom and watch or play by hand (Decision 6).

## 3. Gaps and parameters (names only, no values)

### 3.1 Gaps
1. **Phase 2 trigger and capacity pause after the split** (top issue). If the motor alone ends the capacity pause while uncapping is still manual, honey keeps flowing into a chain that still needs the player. One option is to enter Phase 2 on the first automation buy but end the pause only when the whole chain is automated (U3 + S2 + L4). This would change §1 (Phase 2 line) and §3 Tree B (Automation line).
2. **The Long Fork has no carry-over** after the apparatus (§2.1).
3. **There is no truck-capacity upgrade.** Truck capacity is TBD in §2, and no idea covers it.
4. **There is no bucket-capacity upgrade**, and the unit of bucket capacity is undefined (§2.4).
5. **Multi-hive scaling.** The GDD's plurals ("hubs", "electric centrifuges") suggest one harvest station per hive or per cluster in Phase 3. It is undefined whether each hive needs its own centrifuge, crate and truck, or whether one station serves many hives.
6. **Placement on the grid.** It is undefined whether the crate, centrifuge and apparatus use grid tiles (§2.3).
7. **Auto-dispatch versus Overflow Auto-Sell** naming and overlap (§2.3).
8. **Post-automation effect of Faster Delivery and crate tiers.** Both are recommended to stay useful after automation. This needs confirming.

### 3.2 Parameters to set later (names only)
- **Per line:** `base_cost`, `growth` and `max_level`, plus an unlock condition, for each of: `heated_fork`, `long_fork`, `uncap_apparatus`, `centrifuge_gearing`, `centrifuge_motor`, `crate_tier`, `faster_delivery`, `auto_dispatch`, `deep_frame`, `overflow_storage`, `overflow_auto_sell`.
- **Unlocks:** `long_fork_unlock_heated_level`, `uncap_apparatus_unlock` (requires Long Fork), `motor_unlock_gearing_level`, `auto_dispatch_unlock`, `crate_tier_unlock[2..3]`.
- **Uncap:** `apparatus_seconds_per_frame`, `heated_fork_post_auto_yield_bonus`, `long_fork_post_auto_effect` (if any).
- **Spin:** `bucket_capacity_cells`, `motor_spin_seconds_per_bucket`, `gearing_post_auto_time_cut`.
- **Logistics:** `crate_cells[1..3]`, `crate_jars[1..3]`, `truck_capacity_jars`, `truck_trip_seconds`, `faster_delivery_trip_cut_per_level`.
- **Capacity:** `deep_frame_length_factor`, `deep_frame_jars_per_frame`, `deep_frame_purchase_mode` (per level or per frame), `free_buffer_hives`, `overflow_storage_capacity_per_level`, `overflow_auto_sell_discount`.
- **Zoom:** `zoom_fit_max_frame_height` (the camera target that keeps hive and centrifuge in focus with the tallest frame and hive tier).
- **Phases:** `phase2_trigger` and `capacity_pause_removed_when` (which automation buys).

### 3.3 Standing targets (deferred, not computed)
No values are set, so none of the standing checks can be run yet. Each must be re-checked when values are set.
- **Target run length (§3 Capstone):** these upgrades shorten the time spent harvesting. Run length will fall unless costs absorb the gain.
- **Throughput cap κ (Glossary):** Deep Frame, crate tiers and every automation step raise jar intake. κ must be re-checked against the new intake.
- **Rush gap at 0, 20, 50 and 150 Crystals ("Equal for veterans"):** these lines are route-neutral if the Meadow rush and the normal route buy them the same way. The gap must still be re-checked, because a harvest station that uses grid tiles (Decision 5) would cost the tile-tight rush more.
- **The `refinery-parameters.md` §2 run model** has no harvest-chain stage. It will need one (time per harvest, from uncap, spin, bottle and trip) once values exist.

## Risks
- **Splitting the Automation bundle without settling Decision 1** could let a partial automation buy end the capacity pause, so honey piles up behind a manual step.
- **Deep Frame at 2x in height** may break the zoom rule on taller hive tiers. This should be checked in a screenshot before costs are set.
- **"Auto-Sell" naming two features** will confuse both players and later agents.
- **Crate cells on the production grid** would make logistics compete with honey per tile. That is a real design lever, but it also affects the rush gap.

## Decisions needed from the designer
1. **Phase 2 and the capacity pause:** with Automation split into the apparatus, the motor and auto-dispatch, which buy starts Phase 2, and which buy or set of buys removes the capacity pause? This affects §1 and §3 Tree B.
2. **Motor:** is it the GDD's electric centrifuge, or an extra step before it?
3. **"Auto-sell":** does it mean the overflow Auto-Sell, the truck's auto-dispatch, or both? Please confirm distinct names.
4. **Crate "more jars per batch":** is it a waiting buffer (recommended), multiple spigots, or a bigger truck load?
5. **Grid:** does the harvest station (crate, centrifuge, apparatus) use §4 grid tiles, or sit on a fixed farm plot?
6. **Deep Frame:** is it per level or bought per frame, and 2x or 2.5x? Should bucket capacity be redefined in cells?
7. **Zoom after automation:** can the player still enter the uncapping zoom by hand?
8. **Long Fork after the apparatus:** no effect, or a carry-over?
9. **Cross-path order** (§2.5): adopt it, or set a different one?
10. **Gaps to fill or drop:** a truck-capacity upgrade, a bucket-capacity upgrade, and multi-hive harvest scaling.

Once these are decided and the rest of the economy exists, the next balance pass sets every parameter in §3.2 and runs the §3.3 checks.
