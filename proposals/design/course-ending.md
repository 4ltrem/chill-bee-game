---
author: gerard
type: design
status: accepted (designer, 2026-11-22: option B; see Designer decisions)
description: 0.3.0 "Course build" start and end - a title screen with Play, and a victory screen when a thin slice of Tree C (Habitat Health raised by planting native wildflower patches) reaches thriving
---
# Course ending: welcome screen, Habitat Health slice and victory

**Sources:** `GDD.md` (Executive Summary; §1 Primary Game Loop & Phase Structure; §3 Tree C: Native Habitat, lines 111-144; §4 Land, Grid & Units; §5 Leaderboards; §6 Currencies & Offline Earnings; §7 Story Premise & Onboarding; §9 UI & Screens; Environmental & Visual Identity; Glossary, all tables, Habitat in particular), `UI_DESIGN.md`, `MILESTONES.md` (M5, A7 brief), `game/specs/0.2-first-automation.md`, `game/specs/flower-patch-b.md`, `proposals/design/ui-screens.md` (boards 4, 7, 14; icon timing), `proposals/design/roadmap.md` (rows 17-22, the 0.6 parameter names), `_meta/memory/dev-mode-and-pacing.md`. Code checked: `game/scripts` has no habitat, save or offline-earnings code; `main.tscn` has three decorative `FlowerPatch` instances that the bees forage on (`bees.gd`, group `flower_patch`).
**Trigger:** Designer, 2026-11-22: add a welcome screen (title and Play only) and a victory screen for 0.3.0 "Course build". The ending is the GDD's: the pocket world restored and thriving (§7 premise, Tree C Habitat Health). Due 2026-11-29 with A7; the goal agent has about 2-3 days for it.

---

## 1. Concept

The GDD's premise is that the player finds "a tiny magical pocket world that needs a beekeeper to restore it" (§7), and Tree C measures that restoration as **Habitat Health** (Glossary). The build so far has none of Tree C: honey makes money and money buys Tree A/B upgrades and the self-driving truck, but nothing restores anything. 0.3.0 needs a goal a grader can reach and an ending that says what the game is about.

The slice: give the money a second use. The player spends in-game money to **plant native wildflower patches**. Each patch raises Habitat Health. When Habitat Health reaches **thriving**, a victory screen says the meadow is restored, and the player keeps playing. A title screen with one Play button opens the game.

This is a thin slice of Tree C, Sunny Meadow only. It builds the first part of the GDD's Flower Patches (planting raises Habitat Health) and nothing else. It does not redesign Tree C. Hive Balance, Habitat Synergy level, patch tiers, native bee bonuses, biome unlocks and the Refinery habitat lock all stay as the GDD has them, to be built in 0.6 (`roadmap.md`). The slice's numbers are placeholders for the course build, not the 0.6 Tree C values.

Buildable by a solo developer: no new 3D model (patches reuse `flower_patch.tscn` with its per-instance colour and radius), two overlay screens drawn over the live farm, one shop row and one meter.

## 2. Options and recommendation

### 2.1 Options

| | A. Meter and plant row | B. A + the bumble bee arrives (recommended) | C. Mini Tree C |
|---|---|---|---|
| What it adds | Habitat Health number and meter; a repeatable "Plant wildflower patch" shop row; each purchase shows a patch in the next pre-placed slot and raises Health; victory at thriving | everything in A, plus: at thriving, the Sunny Meadow **bumble bee visitor** arrives (GDD §3: "None; Bee Journal entry only", attracted by meadow flowers). It unlocks the 0.2 Bumble Bees Journal entry, which until then is locked | A, plus Hive Balance (a second hive lowers Health), patch upgrades in place (tiers), named Habitat Synergy grades |
| New models | none | none (the visitor is a toast and the Journal unlock, no bee model) | none for tiers if scaled, but a second hive needs 0.4's free grid and bee carry |
| New UI | title overlay, victory overlay, Health pill, one shop row | the same, plus the Journal icon appearing at thriving (0.3.0 already draws the Journal icon; `ui-screens.md` already says "Journal at the first native bee") | A's UI plus a Habitat sheet (board 7) |
| Build cost (goal agent) | about 1 day | about 1.5 days | 3+ days; depends on 0.4 grid work; does not fit |
| Story | restored = a number | restored = a number and the first native bee: the GDD's "biodiversity rather than honey" made visible | closest to the GDD, but at stub depth |
| Risk | the ending is a bar filling | locks a 0.2 screen a grader might have opened earlier | breaks the GDD phase order (`roadmap.md` option C); too big for 7 days |

**Recommendation: B.** It costs about half a day more than A and needs no model, and it gives the ending real content: Habitat Health brings the first native bee, which is the habitat-and-bee link the Executive Summary promises. It reuses the Journal entry already approved and built in 0.2. C needs several hives on a grid (Hive Balance), so in 0.3.0 it would only be a stub.

Left out of every option: greening or desaturating the ground with Health. A "faded" ground colour would be a new `STYLE_GUIDE.md` token (designer only) and a new visual check. It could come later as an add-on to A or B.

### 2.2 Rules (option B)

- **Start.** Every new farm starts at `HABITAT_HEALTH_START`, below thriving. This is the "world that needs restoring" of §7. The three existing decorative patches stay as they are, and the bees still forage on them.
- **Earned.** The Shop gets one row in a new Tree C group: **Plant wildflower patch** (cost `PATCH_BASE_COST × PATCH_COST_GROWTH^planted`, GDD §3 cost model; level shown "n / `PATCH_SLOTS`"). A purchase shows the next hidden slot's patch with a short grow-in (scale from 0, the same tween family as existing pops), joins it to group `flower_patch` so the bees fly to it, and adds `HABITAT_HEALTH_PER_PATCH`.
- **Gate.** The row is available from the start, and its cost is the gate. It is not locked behind an upgrade, so a grader who never finds the automation rows can still finish. Terry sets the costs so a normal player reaches thriving after Auto-Sell (see 2.4).
- **Lost.** Nothing lowers Habitat Health in the slice. Patches never wilt (GDD §4: "nothing breaks, wears or decays"; Synergy has "no growth timers"). Hive Balance, the only GDD rule that lowers Health, needs more than one hive and waits for 0.6.
- **Thriving.** When Health ≥ `HABITAT_THRIVING`, the victory is queued. It shows when the player is next on the farm view with no zoom, sheet or drag in progress, after `VICTORY_DELAY_SECONDS`. It never interrupts a harvest.
- **Reward (B).** At thriving the bumble bee visitor arrives: a one-line toast, and the Journal icon appears with the Bumble Bees entry unlocked (before thriving the Journal is hidden, per `ui-screens.md`'s "Journal at the first native bee").
- **Reset.** None in the slice. There is no save, so every launch is a new farm (2.3). The GDD's reset (Swarm Splitting) stays out of scope.
- **Cap.** The row maxes at `PATCH_SLOTS` ("Thriving" in place of the price). The slots must be enough to reach thriving: `PATCH_SLOTS ≥ ceil((HABITAT_THRIVING − HABITAT_HEALTH_START) / HABITAT_HEALTH_PER_PATCH)`.

### 2.3 Scene flow

```
launch -> main.tscn loads, farm idle behind a dim -> Welcome overlay (title, Play)
       -> Play -> farm view, icons appear -> first-time hint (M5) -> loop
       -> Health reaches thriving -> (on farm view, idle) Victory overlay -> Keep playing -> loop
```

- **Welcome screen.** An overlay (CanvasLayer) over the live farm in `main.tscn`, not a separate scene. The real farm is the background, dimmed (`UI_DESIGN.md` rule 1: draw only the new UI on top of what the game already shows). It holds the game title and one **Play** button, with no how-to text and no icon rail. The farm is idle behind it: no hive fill and no input reach the world until Play.
- **Play** removes the overlay and shows the icon rail. On the web build it is also the first user tap. Patricia to confirm whether this is when Godot's web export can start audio (unverified browser behaviour).
- **How it fits the first-time hint (M5).** The hint starts on `play_pressed`, never under the welcome overlay, so the two never show together. The welcome screen says nothing about how to play, and the hint carries all of it. This proposal does not design the hint.
- **Returning players.** The build has no save system (no save or load code in `game/scripts`). Every launch, including a browser refresh on itch, is a new farm, so every launch shows the welcome screen and there is no returning player yet. GDD Offline Earnings and `ui-screens.md` board 4 ("Welcome back") need a save, so they are out of 0.3.0. For when a save exists, I propose this order: the welcome screen on every cold start, then Play, then the Welcome back sheet over the farm if offline earnings are due. The title screen stays the single entry point and the audio-unlock tap.
- **Victory screen.** An overlay over the live farm, dimmed, with the new patches visible behind it. It holds a headline that the meadow is thriving, one line on the bumble bee visitor (B), a small summary (patches planted, jars sold), and one button, **Keep playing**. It shows once per farm. Text goes through `tr()` keys (EN/FR) as the 0.2 Journal does. William drafts it and Clara checks it.
- **After victory.** Play continues unchanged: honey, upgrades and the truck all keep working, the Health pill stays at thriving with the row maxed, and the Journal stays unlocked. There is no "play again" button, because a fresh start would be a reset, which is out of scope. Reloading the page starts a new farm.

### 2.4 Interactions

- **Economy and Tree A/B (0.2).** Patches compete with the upgrades for the same money, which is the point: restore the meadow or speed the farm. In the slice, patches give **no production bonus** (decision 2). That keeps victory a separate goal and leaves the GDD's habitat-to-honey link (native-bee bonus, Synergy) for 0.6. Ordering: if patches are cheap, a player can win before buying any automation and never see 0.2's features. Terry sets the cost curve so a normal player reaches thriving after Auto-Sell (GDD: about 12 min). `VICTORY_TARGET_MINUTES` is that target.
- **Grader session length (A7 / final).** A stranger may play only a few minutes. The target time must suit a short session, and the Dev hooks (2.6) let a reviewer reach the ending at once. Is a visible shortcut needed for graders (for example a Dev-free "fast meadow" setting)? That is decision 4.
- **Shop (0.3.0 Shop sheet).** The row goes in the new Shop sheet that replaces the 0.2 panel (M5), in its own Tree C group under the Tree A/B rows. The 0.2 panel's "seven rows without scrolling" rule (item 14) becomes eight rows if the sheet is late. Bob checks the 720 × 1280 fit.
- **HUD (UI_DESIGN.md).** Health shows as a **count pill** in the top info, in rule 9 order: number first, then icon, then **+**. The + opens the Shop at the plant row. The icon is a wildflower, **not** a leaf: rule 6 gives the green leaf to Impact. There is no nav bar and no Habitat icon or sheet (board 7) in 0.3.0. The pill must clear the Harvest, Spin and Sell anchors and stays visible in the zooms only if the designer wants it (default: farm view only, like the rest of the info row).
- **Bottom slot (UI_DESIGN rule 5).** Slot C (habitat strip) is one of the play-test options. The pill covers Health whichever slot wins, so slot C can show the same number without depending on this slice.
- **Bees and flower patches.** New patches join `flower_patch`. `bees.gd` collects patches when it starts, so it must refresh when a patch is added (Patricia). The existing test "the bees still find 3 patches" becomes "3 + planted" (Quinn).
- **Placement (GDD §4, 0.4 grid).** There is no grid before 0.4, so patches appear in `PATCH_SLOTS` fixed slots that Bob places in `main.tscn`, clear of both camera stops and of the truck's path. In 0.4 the slots become free placement. Nothing carries over, because there is no save.
- **Journal (0.2 item 8).** With B, the shop's Journal button and the 0.3.0 Journal icon are hidden until the visitor arrives. Dev mode can unlock it. This changes 0.2 behaviour, so its test changes.
- **Rush gap and leaderboards.** The slice adds no Refinery, route, Crystal or run time, so Terry's rush gap does not change now. The victory is **not** a run end (Glossary: a run ends when a Royal Crystal forms). The victory screen shows no timer and records no personal best, so it does not create a second "run time" before the opt-in leaderboards exist. For later: once Health feeds Habitat Synergy, patch cost and Health per patch set how cheaply the rush keeps "just enough flowers for the habitat minimum" (§3 Speedrun route) and the worth of the Crystal "starting wildflower plot" (§1). The 0.3.0 values must not be copied into the GDD as Tree C values. Terry re-derives them in 0.6.
- **Phase flag (0.2 item 7).** Unrelated: planting does not change `Economy.phase`.

### 2.5 Impact table

| System | Effect | Risk |
|---|---|---|
| Economy (money) | a second, repeatable money sink | victory too early (before automation) or too late for a grader; Terry's target |
| Shop | one Tree C row, eight rows in all | 720 × 1280 fit if the 0.3.0 sheet slips |
| HUD top info | one count pill (number, wildflower, +) | crowding the anchors; Bob's placement check |
| Bees (`bees.gd`) | forage on new patches | patch list not refreshed; Quinn test |
| `main.tscn` | `PATCH_SLOTS` hidden patch instances | slots inside a camera stop's framing |
| Journal (0.2) | locked until thriving (B) | a grader who opened it in 0.2 finds it gone; one changed test |
| Tests (all suites) | the welcome overlay holds the world idle | **every existing test would stall behind it**: a config switch must skip it under tests (2.6) |
| Leaderboards / rush gap | none now | slice numbers mistaken for Tree C values later |
| Save / offline earnings | none (no save exists) | a returning-player flow is designed later, with the save |
| Text (EN/FR) | title, Play, victory, toast keys | real-world claims in victory text (below) |

**To check (not facts here):** patch labels stay generic ("native wildflower patch") in 0.3.0. The GDD's Sunny Meadow list (goldenrod, wild bergamot, New England aster, black-eyed Susan) is marked "to be fact-checked", so naming them needs William and a conservation partner. The victory text must make no real-world conservation or donation claim. If the designer wants one, Connie reviews it first.

### 2.6 Dev mode and config

Every value is in `default_config.tres` and live in the Dev panel (config keys are the parameters below in lower snake case). Dev controls:
- `show_welcome` (bool, default true; **false in every test run** unless a test is about the welcome screen);
- "Show welcome", "Show victory" buttons (show the overlay now, for shots and play-tests);
- "+1 patch (free)" and "Health to thriving − 1 patch", so one purchase triggers the victory;
- "Reset habitat" (Health to start, patches hidden, victory and visitor flags cleared, Journal locked again);
- "Unlock Journal" (B).

Tests read the values from the config (Process step 2). Shots: welcome, victory, the pill at start and at thriving, and the plant row are added to `ui_compare_shots.gd` / `ui_shots.py`.

### 2.7 Build cost

| Work | Owner | Size |
|---|---|---|
| `Economy`: Health, patch row on the upgrade table, thriving signal, victory queue | Patricia | S |
| welcome and victory overlays, idle-until-Play, Dev controls, `bees.gd` refresh, Journal lock (B) | Patricia | S-M |
| `PATCH_SLOTS` slots in `main.tscn`; overlay and pill layouts from the STYLE_GUIDE tokens | Bob | S |
| tests for the rules above, the test-run welcome skip, mutations | Quinn | S-M |
| title, victory, toast, pill strings EN/FR | William, Clara | S |
| placeholder values | Terry | S |

About 1.5 goal-agent days for B (A about 1), which leaves room for the rest of M5.

## 3. Parameters for Terry

Placeholders only, erring slow (`dev-mode-and-pacing.md`). Names follow `roadmap.md`'s 0.6 list where they overlap.

1. `HABITAT_HEALTH_START`: Health of a new farm (the "needs restoring" start).
2. `HABITAT_HEALTH_PER_PATCH`: Health added by one planted patch (the slice's single-tier form of `HABITAT_HEALTH_PER_FLOWER[tier]`).
3. `HABITAT_THRIVING`: the threshold that triggers the victory (and, in B, the bumble bee visitor).
4. `HABITAT_HEALTH_MAX`: the top of the meter; at or above `HABITAT_THRIVING`.
5. `PATCH_SLOTS`: how many patches can be planted. It must satisfy the reachability rule in 2.2; Bob places this many slots.
6. `PATCH_BASE_COST`: money for the first patch.
7. `PATCH_COST_GROWTH`: cost growth per patch planted (GDD §3 cost model).
8. `VICTORY_TARGET_MINUTES`: target time from Play to thriving for a new player who also buys upgrades, after Auto-Sell (about 12 min) and within a grader-length session.
9. `VICTORY_DELAY_SECONDS`: wait on the idle farm view before the victory overlay shows.

## Decisions needed from the designer

1. **Scope:** option A (meter and plant row), **B (A + the bumble bee visitor unlocking the Journal; recommended)**, or C (mini Tree C, does not fit the 7 days)?
2. **Patch effect on honey:** none in 0.3.0 (recommended; victory stays a separate goal and the habitat-to-honey link waits for 0.6's native bees), or a small production bonus per patch (Terry would model it)?
3. **Returning players and saving:** keep 0.3.0 save-free, so every launch is a new farm and shows the welcome screen (recommended; Welcome back and Offline Earnings wait for a save)? Do you accept the later order "title, Play, then Welcome back"?
4. **Reaching the ending in a grader session:** tune only by `VICTORY_TARGET_MINUTES`, or also offer a player-facing shortcut (for example a "short meadow" setting on the welcome screen)? Note that a shortcut would add a second button to your title-and-Play pick.
5. **Text:** the title on the welcome screen ("Chill Bee Game", or one of the GDD's working titles), and approval for William to draft the victory and toast lines (EN/FR) with generic patch names and no real-world conservation claim.

## Designer decisions (2026-11-22)

1. **Scope: B.** Habitat Health meter, "Plant wildflower patch" Shop row on fixed slots, bumble bee visitor at thriving unlocking the Bumble Bees Journal entry, then the victory screen.
2. **Patch effect: habitat only.** No honey bonus in 0.3.0.
3. **Saving: save-free.** Every launch is a new farm and shows the welcome screen; Welcome back and Offline Earnings wait for a save system.
4. **Grader path: a visible skip button**, as a small skip icon at the farm view's edge (the welcome screen stays title + Play). Tuning by `VICTORY_TARGET_MINUTES` still applies to a real run.
5. **Text:** the welcome screen title is "Chill Bee Game". William drafts the victory and toast lines (EN/FR), Clara checks, the designer approves; the lines go in the translation CSV.
