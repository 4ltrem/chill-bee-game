---
author: gerard
type: design
status: applied
description: Native bee species effects per biome; adopted into the GDD Tree C species table
---
# Native Bee Species: Biome Effects Proposal
**Author:** Gerard, the Gameplay Architect
**Sources:** `GDD.md` (Tree C: Flower Patches, Native Bees, Hive Balance, Habitat Synergy, Native Bee Species, Bee Journal, On Reset; Land, Grid & Units; Capstone; Biomes; Leaderboards; Glossary), `proposals/design/capstone-machine.md`, `proposals/balance/refinery-parameters.md` (Terry, revision 2).
**Trigger:** Peer feedback (Jaime): do bees behave differently by biome, e.g. how quickly the fill meter rises?
**Status:** Proposal. No numbers are final; every tunable is listed in §5 for Terry. Natural-history claims are working assumptions until William and a conservation partner check them (§1.3).

---

## 1. Species tables

### 1.1 Launch biomes (real Canadian native bee groups)

Design rules behind the assignment:
- **Meadow gets fewer species and no hive fill-rate species.** Anything that speeds Sunny Meadow production helps the Meadow rush on 100% of its jars but the normal route on only about 50% (Terry §2.2 jar mix). Terry's sensitivity table (§5.3) shows that a rush jar intake 10% higher than the normal route's (J_R = 1.1) makes the rush clearly better (G = 0.963). So Jaime's "faster fill meter" is answered in Alpine Valley, where only the normal route benefits.
- **No launch species touches Refinery yield.** Y_Meadow = 1 is the unit of Royal Honey and Y_Alpine = 2.0 is frozen by D4 (Terry §2.4). "Better honey quality" in launch biomes means higher sale value at the market stand only (§3.3).
- **Each launch biome teaches a different effect.** Meadow introduces pollination and quality; Alpine adds the fill-rate effect players can see on the hive.

| Biome | Species (group) | Effect type | Plain-language effect | Attracted by (GDD wildflowers) | Fact-check needed |
|---|---|---|---|---|---|
| Sunny Meadow | **Sweat bees** (Halictidae) | Faster pollination | "Sweat bees work every bloom, so your Meadow flowers raise Habitat Synergy faster." | Black-eyed Susan, goldenrod | Common in open, sunny meadows; visits to these two flowers. |
| Sunny Meadow | **Leafcutter bees** (Megachilidae) | Better honey quality (sale value) | "Leafcutters pollinate your wildflowers well, so Wildflower Gold Honey sells for more." | Wild bergamot, New England aster | Summer activity in open habitat; visits to bergamot and aster. The honey link is a game abstraction (see note below). |
| Alpine Valley | **Bumble bees** (*Bombus*) | Faster hive fill rate | "Bumble bees fly in cold mountain air, so your Alpine hives fill faster." | Fireweed, Alpine wildflower slot (TBD) | Cold tolerance and prominence at high elevation; fireweed visits. Bumble bees are also common in lowland meadows, so the Journal should not say they are alpine-only. |
| Alpine Valley | **Mason bees** (*Osmia*) | Faster pollination | "Mason bees are efficient pollinators, so Alpine Synergy rises faster from the same flowers." | Alpine wildflower slot (TBD) | Diversity of *Osmia* in Canadian montane habitats; which alpine flowers they visit. |
| Alpine Valley | **Mining bees** (*Andrena*) | Better honey quality (sale value) | "Mining bees nest in the valley soil, and their pollination makes Frosted Lavender Honey sell for more." | Fireweed, Alpine wildflower slot (TBD) | Presence in montane/subalpine habitat; nesting in open ground; seasonal timing (many are spring bees). |

Notes:
- **Honey quality is a game abstraction.** Native bees do not supply the player's honey (most native bees make no harvestable honey). The in-game story is "better-pollinated flowers feed your honeybees better". The Bee Journal must not claim native bees make honey; William should phrase the effect line as a game rule, separate from the real-world facts.
- **Alpine flowers:** the GDD lists only fireweed for Alpine Valley ("other alpine wildflowers TBD"). Species above use a placeholder "Alpine wildflower slot" until William proposes the list. Mason bees currently depend entirely on that TBD list.
- **Biome identity check:** Alpine Valley's art description includes lavender fields. Lavender is not a Canadian native wildflower; the conservation partner may want it presented as a farm crop rather than habitat, so it does not count as a native attractor.

### 1.2 Biomes 3–4 (fictional, post-launch)

All labelled **(fictional)** in the Bee Journal, with no real-world fact block.

| Biome | Species (fictional) | Effect type | Plain-language effect | Attracted by |
|---|---|---|---|---|
| Enchanted Grove | **Lantern bee** (fictional) | Faster hive fill rate | "Lantern bees forage by their own glow, so Grove hives fill through the night." | Fictional night-blooming flowers |
| Enchanted Grove | **Glowcap digger** (fictional) | Faster pollination | "Glowcap diggers spread spores and pollen alike; Grove Synergy rises faster." | Fictional glowing mushrooms / flowers |
| Cloud Gardens | **Drift bee** (fictional) | Faster pollination | "Drift bees ride the wind between sky islands, so Cloud Synergy rises faster." | Fictional rainbow blossoms |
| Cloud Gardens | **Stardust bee** (fictional) | Better honey quality (sale value; Refinery yield only if the designer approves, Q3) | "Stardust bees make Stardust Honey richer." | Fictional rainbow blossoms |

Grove gets no quality species because Grove-stop is a route Terry must keep slower than the full route (D4); a Grove sale-value bonus helps Grove-stop more than the full route.

### 1.3 Fact-check list for William and the conservation partner

Every row in §1.1 is a working assumption, not a fact. Before launch they must confirm, with cited sources in English and French:
1. Each group occurs in Canadian lowland meadows (Meadow rows) or montane/alpine habitat (Alpine rows), and is a fair representative of that habitat.
2. Each flower–bee link in the "Attracted by" column.
3. That the Journal does not imply bumble bees are alpine-only or that sweat/leafcutter bees are absent from mountains.
4. The Alpine wildflower list (TBD) and whether lavender is shown as habitat.
5. The wording of every effect line, so a game rule (e.g. "sells for more") is never read as a natural-history claim.

If the partner rejects an assignment, swap groups between biomes but keep the effect-type layout (no Meadow fill-rate species, no launch Refinery-yield species).

---

## 2. Attraction, stacking and loss

### 2.1 How a species is attracted
A species is **present** in a biome when all of these hold:
1. **Habitat Health threshold:** the biome's Habitat Health is at or above `SPECIES_HH_THRESHOLD[species]`.
2. **Flower requirement:** the biome has at least `SPECIES_FLOWER_MIN[species]` flower units of the species' listed wildflowers. This gives the flower choice in Flower Patches a purpose beyond raw Habitat Health.
3. **Unit tier (optional):** at most one species per biome may require a flower unit tier (e.g. raised bed) via `SPECIES_TIER_REQ[species]`. Default: none at launch, to avoid a research gate that the rush and the normal route value differently.

Rules for thresholds:
- **Deterministic, no chance rolls.** Attraction is a pure function of the save state, so it is fair on leaderboards and server validation needs nothing new.
- **Money-driven, no timers.** A species arrives the moment the conditions hold, matching D2.
- **Thresholds use raw Habitat Health, before pollination effects.** Otherwise pollination species raise Synergy, which attracts more species, which raises it further (a runaway loop).
- **Meadow thresholds sit between the starting wildflower plot cap and the unlock threshold.** Above the Habitat Health worth of Synergy 3 (so no species is present at minute zero from a starting upgrade, and every run re-earns them). At or below the unlock threshold U = 5 (so the normal route, which only needs Meadow at 5, gets both Meadow species too; a species above 5 would reward only the rush, which holds Meadow at `CAP_SYNERGY_MIN` 7).
- **Alpine thresholds** may sit anywhere up to Alpine's `CAP_SYNERGY_MIN` (6), since only the normal route uses Alpine at launch. In v2, keep them at or below Alpine's unlock threshold for the same reason as the Meadow (so Alpine-stop gains nothing the full route lacks).
- Order within a biome: the first species is reachable early (the teaching moment); the last one arrives near the unlock threshold.

### 2.2 Stacking
- **Within a biome: species stack.** Different effect types are independent. Two species with the same effect type add together (additive, not multiplicative), and the total for each effect channel is capped per biome by `NATIVE_CHANNEL_CAP[biome][channel]`.
- **Across biomes: no.** A species affects only the biome it lives in. Alpine bumble bees do not speed Meadow hives. This is what keeps launch effects out of the rush.
- **Same group in two biomes:** not used at launch. If the partner wants bumble bees in the Meadow too, they appear as a Journal entry only, with no Meadow effect (Q5).

### 2.3 Losing species
- If Habitat Health falls below `SPECIES_HH_THRESHOLD − SPECIES_LEAVE_MARGIN`, or the flower requirement is no longer met, the species **leaves**: its effect switches off and the biome shows it as "away" with the reason (e.g. "too many hives for the flowers").
- It returns the moment the conditions are restored. Nothing is lost permanently and nothing drains, matching the Refinery's "paused, never lost" rule.
- The margin (hysteresis) stops species flickering in and out when a hive is placed at the edge of a threshold.
- The Bee Journal entry is never removed.

---

## 3. Interactions

### 3.1 Hive Balance
- Placing hives without enough flowers lowers Habitat Health (GDD), which can now make species leave. This turns Hive Balance from a hidden number into something players see: "your mason bees left".
- Build mode should preview which species would leave before a hive is placed, the same way the Crystal screen previews Habitat Health.
- **Cascade risk:** a pollination species leaving lowers Synergy, which can drop the Refinery host below `CAP_SYNERGY_MIN` and pause charging. The Refinery panel must name the chain ("Synergy below 7: sweat bees left after hive placement").

### 3.2 The existing native-bee multiplier (no double counting)
The GDD already says native bees grant production multipliers across Trees A and B, and that they "pollinate flowers, speeding flower growth and Habitat Health". Species effects must not add a second, independent layer on top.

**Recommendation: one native bucket per biome, per channel.**
- **Native multiplier, per biome** = 1 + abundance term + Σ effects of present species in that channel, capped at `NATIVE_CHANNEL_CAP[biome][channel]`.
  - *Abundance term* (`NATIVE_ABUNDANCE_COEF`, `NATIVE_ABUNDANCE_CURVE`): the existing "more native bees, bigger multiplier", driven by Habitat Health. Small.
  - *Species terms*: the new biome-specific effects.
- Channels: **fill rate** (multiplies hive output, the same quantity Tree A's Worker Swarm Count raises), **sale value** (the same quantity Artisanal Branding raises), and **pollination** (Synergy gained per flower).
- The bucket is applied **once** as its own multiplier. It never adds to Tree A/B level percentages and is never applied again inside them.
- **Pollination exists only as species effects.** The GDD's generic "speeding flower growth" conflicts with D2 (no growth timers). Proposed GDD wording: "Pollination species make each flower count for more Habitat Synergy."
- The multiplier becomes **per biome** (the GDD does not say whether it is global). Per biome is required for the rush rules in §1.1.

### 3.3 Refinery affinity, yield and the rush gap
- **Royal Honey is computed from the base sale value.** Gerard's formula is "jar sale value × AFFINITY". If a quality species raised the sale value used here, it would silently raise Royal Honey per jar and break Terry's Y values. Rule: Royal Honey per jar = Y_b (= base S_b × `AFFINITY[b]`); species sale-value bonuses apply only to jars sold at the market stand.
- The GDD rule "Alpine honey must sell for less than 2× Sunny Meadow honey" applies to **base** sale values, before species bonuses.
- **No launch species changes Refinery yield** (Y_Meadow = 1, Y_Alpine = 2.0 frozen by D4).
- **How each species moves the rush gap G:**

| Species | Helps rush? | Helps normal route? | Direction on G | Terry's check |
|---|---|---|---|---|
| Sweat bees (Meadow pollination) | Yes: cheaper Meadow Synergy 7 | Yes: cheaper Meadow Synergy 5 | Slightly lowers G (rush's habitat bill is larger); small because it only trims the habitat-bill gap inside ΔB | Include in B_R/B_N |
| Leafcutter bees (Meadow sale value) | Yes: more money before charging | Yes, on Meadow jars only | Slightly lowers G; money only, so it barely moves ΔW; no charge effect | Include in B_R/B_N and I_ref |
| Bumble bees (Alpine fill rate) | No | Yes: higher jar intake J | Raises G at low n; normal route reaches κ earlier | Re-check where κ binds; v2 Alpine-stop gains more than the full route (0.50 vs 0.29 Alpine share) |
| Mason bees (Alpine pollination) | No | Yes | Raises G slightly | v2 Alpine-stop check |
| Mining bees (Alpine sale value) | No | Yes | Raises G slightly | v2 Alpine-stop check |

- **Net:** the two Meadow species shrink the rush's disadvantage only through money (B). That is safe because of size, not because money scales with Crystals (the charge term scales ÷M too until κ binds): they trim only the habitat-bill gap inside ΔB, while a Meadow fill-rate species would cut the rush's large charge term and roughly halve ΔW (Terry, `native-species-balance.md` §1). The rush-gap-critical region (n ≈ 100–150) is governed by jar intake and κ, which no Meadow species touches. The rush therefore cannot become clearly better through species, provided the Meadow channel caps stay small and Terry's reference sims run with species present.
- **v2 risk:** Alpine-stop already ties the full route at n ≈ 150 (Terry §4.2, G = 1.000). Any Alpine species effect helps Alpine-stop more than the full route. Terry must re-run the v2 search with Alpine species active; if Alpine-stop drops below 1.00, lower Alpine channel caps or add the Grove/Cloud fill-rate and pollination species to restore the margin.
- **Cloud Gardens yield (optional, Q3):** a Refinery-yield bonus on the last biome only helps the full route (no shortcut reaches it), so it can only raise G. It still shifts Terry's v2 parity window (G at n = 150) and must be folded into Y_Cloud, not added on top.

### 3.4 Opt-in leaderboards
- Species are earned in-run by everyone, with no purchase, so they add **no booster tag** and need no new bracket.
- Because attraction is deterministic (§2.1), two players with the same farm get the same species. No luck enters ranked runs.
- Species parameters change run times, so they are stored **per content version** with the capstone parameters (`CAP_PARAMS[content_version]`). Launch species values are frozen with the launch yields (D4); rebalancing them later needs a new content version.
- The run record may store which species were present at Crystal formation (cheap, optional), for future "habitat-friendly run" stats.

### 3.5 Starting upgrades
- **No "starting species" option** on the Crystal whitelist. It would hand the rush its Meadow bonuses at minute zero.
- The starting wildflower plot cap (Synergy 3 worth) sits below every species threshold (§2.1), so species are always re-earned.
- Extra starting hives lower starting Habitat Health and so delay species. The Crystal screen's Habitat Health preview should also show "first species at Habitat Health X".

### 3.6 Reset and the Bee Journal
- **Bee Journal: permanent and account-wide.** An entry is recorded the first time a species is present in any world. It grants **no production bonus** (a Journal bonus would be a second permanent multiplier alongside Crystals and would widen Crystal tiers).
- **Species presence resets with the world.** A new pocket world starts with no native species; they return as Habitat Health is rebuilt, which is the restoration story each run.
- Journal completion can be a cosmetic or educational goal (e.g. a badge), never a stat.

### 3.7 Old (kept) worlds
- Species stay present in kept worlds and their effects keep working there, because the world still produces and sells honey.
- The Refinery is a dormant monument there, so species in old worlds cannot affect Crystals or run times.
- A species first met in an old world (e.g. after expanding it further) still counts for the Journal.

### 3.8 UI and art
- Each biome shows its species roster: present, away (with reason), or not yet attracted (with the requirement).
- Species render as a few extra bees within the existing capped, instanced bee crowd (GDD Bee Rendering Plan), with a distinct low-poly colour and silhouette, not colour alone (accessibility).
- The hive fill bar shows the bumble bee bonus in Alpine so Jaime's question is answered on screen: "+X% fill (bumble bees)".

---

## 4. Impact table

| System | Effect | Risk |
|---|---|---|
| Tree C: Flower Patches | Flower choice matters (species need specific wildflowers) | Alpine flower list is still TBD; mason bees have no confirmed attractor |
| Tree C: Habitat Health | Thresholds gate species; species give Habitat Health a visible reward | Thresholds above U = 5 in the Meadow would reward only the rush |
| Habitat Synergy | Pollination species raise Synergy per flower | Runaway loop if thresholds used post-pollination values; cascade pauses the Refinery when a species leaves |
| Hive Balance | Overpacking hives makes species leave, with a visible reason | Feels punishing without a build-mode preview |
| Native-bee multiplier (Trees A/B) | Merged into one per-biome bucket per channel | Double counting if species are applied as a separate layer; GDD must state the multiplier is per biome |
| Tree A (fill rate) | Bumble bees and lantern bees add to the fill-rate channel | Stacks with Worker Swarm Count; channel cap needed |
| Tree B (sale value) | Quality species add to the sale-value channel alongside Artisanal Branding | If applied to the Refinery's per-jar value, it breaks Terry's yields |
| Refinery / affinity | Royal Honey uses base sale value; no launch yield effects | Optional Cloud yield effect shifts the v2 parity window |
| Rush gap (v1) | Meadow species help the rush only through money, which barely moves the rush's handicap ΔW | A Meadow fill-rate species would raise J_R and could make the rush clearly better (Terry §5.3) |
| Rush gap (v2) | Alpine species help Alpine-stop more than the full route | Alpine-stop already ties at n ≈ 150; needs a re-run |
| Biome unlocks | Cheaper Synergy (pollination) unlocks the next biome sooner | Shortens runs slightly; must be in the reference sims |
| Starting upgrades | No starting species; plots stay below species thresholds | A future "starting species" whitelist item would favour the rush |
| Leaderboards (opt-in) | No new tag; deterministic attraction | Species values must be stored per content version |
| Reset / Bee Journal | Journal permanent, presence resets, no Journal bonus | Pressure to add Journal bonuses later; resist it |
| Old worlds | Species keep working; Refinery dormant | None |
| Bee Journal content | 5 real groups plus fictional species | Natural-history errors in a conservation-funded game; needs William and partner review |
| Rendering / performance | Species bees share the capped instanced crowd | Low; a few extra meshes per biome |
| Localization | Species names and effect lines in English and French | Low |

---

## 5. Parameters for Terry

| Variable | Controls |
|---|---|
| `SPECIES_LIST[content_version][biome]` | Which species exist in each biome for each content version. |
| `SPECIES_EFFECT_TYPE[species]` | Channel: fill rate, pollination, or sale value (design-fixed by this document; yield only if Q3 is approved). |
| `SPECIES_EFFECT[species]` | Size of the species' effect in its channel. |
| `SPECIES_HH_THRESHOLD[species]` | Raw Habitat Health needed for the species to arrive. Meadow values must lie above the starting-plot cap (Synergy 3 worth) and at or below U = 5 worth. |
| `SPECIES_FLOWER_MIN[species]` | Minimum number of the species' listed wildflower units in the biome. |
| `SPECIES_TIER_REQ[species]` (optional) | Flower unit tier required, if any (default none at launch). |
| `SPECIES_LEAVE_MARGIN` | Hysteresis: how far below the threshold Habitat Health must drop before a species leaves. |
| `NATIVE_ABUNDANCE_COEF`, `NATIVE_ABUNDANCE_CURVE` | The existing abundance-driven native-bee multiplier, now the base of each per-biome bucket. |
| `NATIVE_CHANNEL_CAP[biome][channel]` | Maximum total native bonus per biome per channel (abundance plus species). The main lever keeping Meadow effects small for the rush. |
| `SPECIES_YIELD_BONUS[species]` (optional, Cloud Gardens only) | Refinery yield bonus, folded into Y_Cloud, if Q3 is approved. |

Terry's checks once values exist:
1. Run the v1 and v2 reference sims **with species present** at their expected arrival points; re-derive B_R/B_N, J, I_ref.
2. Re-derive κ (min G ≥ 1.00 over all n and all routes), with special attention to v2 Alpine-stop.
3. Confirm base S_Alpine < 2.0 × S_Meadow (bonuses excluded) and that Royal Honey uses base values.
4. Confirm no species threshold is reachable from starting upgrades alone.

---

## 6. Open questions for the designer

1. **Meadow fill-rate species:** Jaime's "faster fill meter" is answered by Alpine bumble bees. Is it acceptable that the Meadow has no fill-rate species (recommended, because Meadow fill rate is the rush's most sensitive lever), or do you want one there, which forces Terry to re-derive κ and likely raise its cost?
2. **Native-bee multiplier:** keep a small abundance term plus species effects in one per-biome bucket (recommended), or make species effects the whole multiplier (simpler, but the GDD line "more native bees means a bigger multiplier" becomes "more species")?
3. **Refinery yield as a quality effect:** drop it entirely (sale value only), or allow it for one Cloud Gardens species, folded into Y_Cloud?
4. **Bee Journal rewards:** confirm the Journal gives no production bonus (recommended), only cosmetic or educational recognition.
5. **Bumble bees in the Meadow:** they are realistic in lowland meadows too. Show them in the Meadow as a Journal-only visitor with no effect, or keep each group in one biome for clarity?
