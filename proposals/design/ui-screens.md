---
author: orchestrator
type: design
status: proposed
description: UI for every player-facing GDD function - floating icons over the 0.1.4 farm (no navigation bar), sheets for each screen, and four bottom-slot options for the play-test
---
# UI Screens: icons over the farm
**Sources:** `GDD.md` (all sections with player-facing functions: §1–§9, Child Safety, Progression Tiers & Biomes, Conservation Partnerships, Monetization Architecture), `STYLE_GUIDE.md` (UI tokens, V9–V13), `game/specs/0.1.4-ui-placement.md` (items 1–4, 8, 9, 11, 18, 20), `game/reports/ui-compare/spin-c/` (the spin-r1 pick, used as the base shots).
**Trigger:** designer, 2026-11-09: "design created for the ui of the game to match the functions in the GDD"; then "use the screenshots we already have and build the UI on top, icons over the screen are preferred over a navigation bar"; on the bottom panel: "final decision to be decided by playtest, have both and also have 3 other options".

**Mockups:** Design canvas "Chill Bee UI Screens", https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca (source in `proposals/design/ui-screens-mockup/`). Each phone is 360×640, half of 720×1280, so a 60 px icon there is V11's 120 px.

**Revised later on 2026-11-09 (designer's canvas feedback; full list in `UI_DESIGN.md`):** Harvest became a white fork icon with the honey meter rising behind it; the Journal icon is a bee, Tools a wrench, Settings a gear, Impact a green leaf; the Royal Jelly icon is variant K (60° three-cell comb, upright crown); the canvas is split into pages; skins (five palettes, one per biome) and an interactive prototype were added.

---

## 1. Concept

- **The harvest loop is not redesigned.** The 0.1.4 HUD stays as approved and as shot: money and bees top-left, ×N under them, Harvest (meter, n/10) over the hive, Spin over the centrifuge, Sell over the truck, Back top-right in the zooms with the hint below it, the pause line above the bottom panel.
- **No navigation bar.** Round icons (cream, ink outline, gold when they need attention) float over the farm in the free sky and edges, clear of the top info and the button anchors (V13; icons may overlap props). Each icon has a 14 px label under it.

| Place (farm view) | Icons |
|---|---|
| Top row, right | Jelly pill (balance, opens Store), Worlds, Settings |
| Right rail, under the top row | Shop (gold + "!" badge when an upgrade is affordable), Build, Habitat |
| Left rail, under money and bees | Journal, Impact |
| On the farm, floating | Wild nectar drops and pests (tap), rewarded-ad 2× chip |

- **Zooms hide the rail.** Back is the only exit (0.1.4). One new icon, **Tools**, sits bottom-right in both zooms and opens the Tree B items for that machine (fork and frames on the hive, gearing and motor on the centrifuge). This answers GDD §1 Phase 2's "UI TBD": after automation, tapping the unit in Build mode offers **Open**, which goes to the same zoom.
- **Screens open as sheets** rising from the bottom over the dimmed farm, with Close at the sheet's top-right; tapping the dimmed farm also closes them (one-thumb reach, GDD §8).
- **Icons appear when their feature exists**, so Phase 1 starts calm: Shop from the start; Build at the first land or unit purchase; Habitat at the first flower patch; Journal at the first native bee; Worlds after the first reset; Impact and Store from the start (proposed, see decisions).

## 2. Screens (board → GDD functions)

| Board | Opens from | GDD functions |
|---|---|---|
| 1 Farm View | – | HUD, Harvest/Sell, nectar drops, ad boost, bottom slot A |
| 2, 3 Zooms | Harvest, Spin | uncap, crank (0.1.4) + Tools |
| 4 Welcome back | return after time away | offline earnings and cap, optional ad 2× |
| 5 Shop | Shop icon | Trees A/B/C, automation, research, Refinery build; cost, level/max, lock with condition |
| 6 Build mode | Build icon | land, place/move, upgrade in place, unit and crate tiers, Refinery placement, Open on an automated unit |
| 7 Habitat & Refinery | Habitat icon | Habitat Health, Synergy level, Hive Balance, next-biome unlock, native bees here/missing, per-biome bonus, biome switch, Refinery charge, divert slider, habitat lock |
| 8 Royal Crystal | the Crystal forming | count and +15% each, whitelisted starting upgrade, live Habitat preview, reset in the reset-story voice |
| 9 Bee Journal | Journal icon | species by biome, found / "?", real or fictional label, facts from William's approved entries |
| 10 Worlds | Worlds icon | saved worlds, dormant Refinery |
| 11 Impact | Impact icon | impact totals, donation % per stream, local best runs; ranked tab later |
| 12 Store | Jelly pill | Jelly time skips, Impact Pass, Patron Pass (later), Jelly packs, parental gate note |
| 13 Settings | Settings icon | vibration, sound, music, text size, language, ranked opt-in |
| 14 First launch | first start | age gate, then the guide's first beat |

The full function-by-function table (37 rows) is the canvas's Coverage board.

## 3. Bottom slot: options for the play-test

The 0.1.4 bottom panel (Worker Swarm Count, Upgrade $25) is kept or replaced by play-test (designer, 2026-11-09). The Shop icon is there in all four.

| Option | Board | What sits at the bottom | For | Against |
|---|---|---|---|---|
| **A** (current) | 1 | Quick-buy: the next upgrade and its price | one tap to buy; already built | only one tree visible |
| **B** | Opt B | Next-unlock goal: name, effect, progress to its price; tap opens it in the Shop | "thrill of the next unlock" pillar | not a buy button |
| **C** | Opt C | Habitat strip: Synergy level, native bees, next-biome threshold; in Phase 3 the Refinery charge and divert | keeps Tree C in sight | busier in Phase 3 |
| **D** | Opt D | Guide task strip: the current step ("Tap Harvest…"), hidden when there is none | onboarding and Phase changes | empty most of the time |

## 3b. Parameters for Terry
None. Every number on the boards is a GDD value or a [TBD] the GDD already lists.

## Decisions needed from the designer
1. Bottom slot: A, B, C or D, after the play-test (board 1 and Opt B–D).
2. Icon placement as in §1 (top row, right rail, left rail), or another split.
3. When each icon appears (§1 last bullet), or all from the start.
4. Tools icon in the zooms as the answer to GDD §1 Phase 2's "UI TBD", and Build › Open for automated units.
5. Habitat & Refinery on one sheet (board 7), or the Refinery on its own unit panel.
6. The parental gate screen and the kid-mode Store are not drawn yet; Connie should review the Store, ad and Welcome back copy before they are.
7. GDD TBDs these screens show as [TBD]: Long Fork unlock, automation costs, ad boost length, Alpine unlock level, Refinery synergy minimum, starting-upgrade max levels, donation percentages, Jelly prices and skip size, offline cap copy for passes.
