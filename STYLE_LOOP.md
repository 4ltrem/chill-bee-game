---
author: orchestrator
type: write-up
status: approved
milestone: M2 (Assignment 6)
description: How Chill Bee Game enforces its style guide with two self-correcting Generator → Evaluator → Refiner loops (visual and voice), with the demo runs, their blackboards and their cost
---
# The style loops (Assignment 6)

**The assignment:** "Build an automated, self-correcting AI loop (Generator → Evaluator → Refiner) that rigorously enforces the specific aesthetic and narrative rules of your existing capstone game."

The rules are the approved [STYLE_GUIDE.md](STYLE_GUIDE.md): **V1–V15** for the look (palette tokens by role, glow, accents, primitives, chunky shapes, calm diorama, honey as hero, contrast, touch and text sizes, glass) and **T1–T6** for the voice. One guide drives two loops; the plan is [game/specs/m2-style-loop.md](game/specs/m2-style-loop.md).

## The two loops

```
                 VISUAL (style_loop.py)                              VOICE (generate.py)

  sandbox: a copy of game/ (the game itself never changes)    request ──► William (writer) drafts content/<slug>.md
                 │                                                           │  only the open FAIL rows
  FAIL rows ─► Bob: the 3D scene's rows (colours, materials)                 ▼
           ─► Patricia: the UI rows (text colours, sizes)           voice_check.py (T5 sources, T2 terms,
                 │  each turn: guard puts back motion, picked-prop          empty table cells): FAIL ─► William
                 │  size and UI layout; unit-suite gate, undo on FAIL        │
                 ▼                                                           ▼
           style_shots.gd renders 6 shots + measure.json             Clara (content critic), with Ruth's
                 │                                                     cached source quotes: T1–T6, scored
                 ▼                                                           │
           style_check.py  (script rules: V1 V2 V3 V4 V5 V6               PASS ─► draft, for the designer
                            V10 V11 V12 V14 V15)                       FAIL ─► back to William (max 3 rounds)
                 │
                 ▼
           Vera (style critic) reads the shots (V3 V6 V7 V8 V9 V10 V13 V15), scores every asset
                 │
     PASS (Vera PASS and no blocking script row) ─► done; sandbox.patch for the designer
     FAIL ─► next round (max 3 rounds, token cap); a row with options A/B ─► the loop takes A
     only a row nothing in the guide can fix (a new token or rule) ─► held for the designer
```

| Role | Visual loop | Voice loop |
|---|---|---|
| Generator | Bob (Sonnet) | William (Sonnet) |
| Evaluator, measurable | `_tools/style_check.py` (stdlib, no Godot, no tokens) over `game/materials/`, `game/scenes/` and the shots' `measure.json` | — |
| Evaluator, judgement | Vera, the Style Critic (Sonnet, Read/Grep/Glob, looks at the PNG shots) | Clara, the Content Critic (Sonnet) |
| Refiner | Bob for the 3D scene's rows, Patricia (Sonnet) for the UI rows, each given only their open FAIL rows, on a sandbox copy | William, given only the open FAIL rows |
| Controller | `_tools/style_loop.py` | `_tools/generate.py` |
| Shared record | `game/reports/style/<slug>/run-N/blackboard.md` | `content/_runs/<slug>/run-N/blackboard.md` |
| Record format | `_templates/blackboard.md`, shared with the goal agent: inputs linked, outputs inline, one Result | same |
| Evaluator calibration | `_tools/style_critic_check.py` on `_tools/fixtures/style/` | `_tools/critic_check.py` on `_tools/fixtures/` |

### What makes it rigorous
- **Measure first, judge second.** Everything a number can settle is a script row with the rule ID, `file:line`, the measured value and a Fix: palette distance in CIE Lab (ΔE ≤ 12 to a token *in the role allowed for that object*), emission only on Honey, at most 2 accent colours, primitive meshes and no textures, parts ≥ 0.05 units, button text contrast ≥ 4.5:1 (WCAG), touch targets ≥ 120 px, fonts ≥ 28/32 px with the ink outline, cells ≥ 20 px at the zoom, glass alpha ≤ 0.35 with back faces drawn. The palette is parsed from the guide on every run, so the designer's edits to the guide take effect without code changes.
- **The critic sees only what scripts can't measure**: clutter and cut-off objects (V7), honey as the brightest thing (V8), state by more than colour (V9), overlap with the HUD (V13), glass reading as glass (V15), plus a second look at accents, shapes and on-screen contrast.
- **The loop can't pass by persuasion.** A round passes only when Vera says PASS *and* `style_check.py` has no blocking row.
- **Vera scores every asset** (designer, 2026-11-05). Under her findings table, each prop and UI element gets a score out of 10 with a one-line reason, on the look words (cozy, whimsical, chunky/round, calm, pastel) and on her rules that apply to it, e.g. "hive: whimsical 3/10, chunky/round 9/10". A score below 6 is also a blocking findings row with a fix for Bob. Score rows start with the asset name, so `style_loop.py` reads only the numbered rows as findings.
- **Clara scores every check** (designer, 2026-11-20). Under her findings table, each of her seven checks (Lore, Tone & Glossary, Child safety & spending, Facts & French, Sources, Look & words, Completeness) gets a score out of 10 with a one-line reason quoting the draft. A check with a blocking row scores below 6, and a score below 6 needs a blocking row with a fix for William.
- **Refiners get a slice, not the board.** Bob sees only open FAIL rows; Vera sees the shots, the script table and (from round 2) her previous verdict plus Bob's diff. No agent reads the blackboard.
- **The loop makes its own creative choices** (designer, 2026-11-20: the assets are generated, so the loop decides). A Fix with two acceptable answers ends in `(designer)` with options A and B, and option A is always the one that fits the current guide. The loop sends A to the refiner without stopping, lists it under *Loop's choices* on the blackboard, tells Vera next round, and adds it to the Design Votes page afterwards so the designer can reverse it. Only a row that nothing in the current guide can fix (a new token or a rule change) still stops the loop. The first visual run (below) predates this rule and stopped twice for the designer.
- **The refiners can't break the game** (designer, 2026-11-20, after a run where Bob turned the truck's exit diagonal, shrank the truck, enlarged the jars and moved the Spin icon to please the critic). The loop works on a sandbox copy and ends with `sandbox.patch` for the designer to apply. After each refiner's turn, a guard puts back any change to motion, to the size or place of the props the designer picked, or to the UI's layout. Then the unit suite runs on the copy (the test gate), and a turn that fails it is undone. The UI is not Bob's: UI rows go to Patricia, who may restyle but never move it.
- **The evaluators are tested.** `style_critic_check.py` must catch every known-bad fixture: six script fixtures (neon → V1, glowing hive → V2, texture + imported mesh → V4, third accent → V3, 90 px button → V11, low-contrast disabled text → V10) and two rendered shots Vera must fail (a cluttered, accent-heavy diorama → V3 + V7; a grey-on-grey disabled button → V10). `test_generate.py` checks the controller with fake agents (PASS in round 1, FAIL then PASS, max rounds, token cap, the loop's option-A choice, a true designer stop and resume, the sandbox and its patch, a gate failure undoing a turn, UI rows to Patricia, and the guard on motion, picked-prop size and the UI).

## Demo runs

### Visual: the 0.2 farm, no designer step (`game/reports/style/0.2.0-farm/run-5/blackboard.md`)
`python -I _tools/style_loop.py farm-0-2-0-r5` (run 5 of the 0.2.0 farm; slugs are `<version>-<scene>` with `run-N/` inside since 2026-11-21), on the 0.2 build, 2026-11-20, with the sandbox, the guards, the test gate and the UI refiner. No designer step from start to end.

**Baseline:** the unit suite on the untouched copy, 195 passed, 0 failed.

**Round 1: FAIL.** `style_check.py` had no rows. Vera found 3 blocking rows and scored 25 assets:
- V10 (UI): the disabled Harvest button's grey-green text on olive is about 2:1. Harvest button V10: **3/10**.
- V8 (UI): the full-width gold Journal bar outshines the honey. Journal button V8: **5/10**.
- V15: the empty jars on the crate read as ghosts, not glass. Jars (empty) V15: **4/10**.

**Round 2: FAIL.** The two UI rows went to Patricia, the jar row to Bob.
- Bob gave the glass a rim effect and raised its alpha to 0.35 (the limit). The gate passed (195/195), so it stayed.
- Patricia restyled both buttons. The gate failed on `t_camera_pan_seconds`, a real-time timing test her colours can't have affected (the pan took 2.25 s, not 2.5 s, under load). Her turn was undone anyway: the gate does not judge cause.
- Vera: all three rows still open, and the scores unchanged.

**Round 3: FAIL, at max rounds.**
- Bob tried to add two steel rim rings to the jar. The jar is a prop the designer picked, so the guard put back their meshes and placement. The gate passed.
- Patricia made the Harvest button's disabled state cream on dark brown with the ink outline, and the Journal button cream with a border. The gate passed.
- Vera closed both UI rows. Harvest button V10 went from **3 to 8/10**, and Journal button V8 from **5 to 8/10**. She kept one row open: the empty jars are still ghosts (V15 **4/10**), because the rim rings have no mesh.

**Result: `needs-review`, 768,463 tokens.** Two of three findings were fixed and verified by the critic, with no human step. The third is open on purpose: the only fix Vera could see changes the shape of a prop the designer play-tested, which the loop is built to refuse. The game itself did not change. The surviving edits are in [`sandbox.patch`](game/reports/style/0.2.0-farm/run-5/sandbox.patch) for the designer to review: the glass rim effect, the two button restyles, and two empty rim nodes. The guard now removes parts added to a picked prop entirely, so a later run won't leave empty nodes.

**What this run shows about the limits.** The gate undoes a turn on any new failure, including a flaky timing test, which cost Patricia one round. Vera was told which props are locked, yet her jar fix asked for added rim parts while calling it "materials only". The guard, not the critic's wording, is what kept the prop's shape. A next step would be to re-run a failing real-time test once before undoing a turn.

**What led here.** The first 0.2 run, `0.2.0-farm/run-1` (581,609 tokens, no designer step), ended at max rounds with 4 open rows. Watching the renders, the designer saw that Bob had changed the truck's motion and size, and the unit suite then caught the truck off its cell and 7 enlarged jars overhanging the crate. A second run was stopped in round 2 after he moved the Spin icon. A third (`run-3`, with the sandbox) was stopped in round 2 because its test gate failed on tests the refiners had not broken: a test that reads `../STYLE_GUIDE.md` (missing from the copy) and a zoom value left out of step by the revert. The copy now includes the guide, and the gate compares against a baseline run before any edit. A fourth (`run-4`) passed both gates in round 2 but its render failed: the shot set's crank step sometimes bottled no jar. Quinn made it wait on the real state (3 clean renders in a row), and the loop now retries a failed render once. Every edit Bob made was reverted, and the sandbox, guards, gate and UI refiner were built (see *What makes it rigorous*). Two rows from the first run were fixed outside the loop: Patricia restyled the Dev label, and found that the config's `zoom_size` overrode the scene's. Quinn's shot set now cranks real jars before shots 05 and 06, because Vera had judged jars that the shot set kept empty.

### Visual, first version: the 0.1.2 farm (`game/reports/style/0.1.2-farm/run-1/blackboard.md`)
`python -I _tools/style_loop.py farm-0-1-2` (now folder `0.1.2-farm/run-1`), on the 0.1.2 build, 2026-11-05. This run predates the loop's own choices: it stopped twice for the designer.

**Round 1: FAIL.**
- **`style_check.py`: 9 blocking rows.** These include the two the spec predicted:
  - V1, white disabled-button text, ΔE 13.9 from cream;
  - V1/V3, `rim_mark.tres`, ΔE 16 from truck red and a third accent colour.

  It also found rows nobody had predicted:
  - V6: hive walls and floor 0.03–0.04 units thick, and the jar lid 0.04;
  - V11: the Upgrade button is 110 px tall;
  - V12: the Harvest tag uses 28 px text.
- **Vera: 5 blocking rows** (plus 1 minor) that no script could find:
  - V7: the "Harvest" label spills out of a narrow pill over a flower;
  - V7: the spin hint is hidden behind that button;
  - V8: the gold UI, the buttercup and the red truck outshine the honey;
  - V9: the Upgrade button shows "can't afford" by colour alone;
  - V7: cells cut off at the zoom's left edge, which Quinn had also noticed.

**Designer stop.** The rim-mark rows have two acceptable answers:
- A: recolour the mark to charcoal;
- B: approve it as a third accent.

The loop held them back from Bob and added the question, with votes, to the one comparison page **Design Votes** (https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa, `compare_page.py add`). Meanwhile Bob fixed the other rows that could be fixed in scenes:
- cream disabled text;
- a 120 px Upgrade button;
- a 240 × 120 Harvest tag with 32 px text;
- hive walls, floor and jar lid at 0.05.

The diff is on the blackboard. Result: `waiting-designer`.

**The designer picked A.** The rim mark was recoloured to charcoal and moved to the Shadow role, and `style_check.py` then passed with 0 rows. The loop was resumed with `--resume`; Vera's round-1 verdict and Bob's diff carry over.

**Round 2: FAIL.** `style_check.py` had no rows. Vera found that two earlier fixes had not worked yet:
- the hint was still behind the wider Harvest button;
- the zoom's left cells were still cut off.

She also held one new row for the designer: V8, honey as the hero, with two options (A: shrink the truck; B: bigger honey props). The question went on Design Votes with A rendered. Meanwhile Bob fixed these in scenes:
- moved the hint clear of the button;
- drew the disabled Upgrade button shorter, a shape cue for V9;
- shifted the zoom framing.

Quinn's suites stayed green after his edits (unit 110, ui 13, touch 4, play 205, measure 17).

**The designer chose "neither for now".** The loop was resumed with `--note`, so Vera knew V8 was deferred.

**Round 3: FAIL at max rounds.** Vera confirmed two fixes from round 2 and dropped their rows:
- the hint is readable;
- the disabled button now differs in shape as well as colour.

She listed V8 and the "x30" label as minor. One blocking row is left open: V7, the glass bucket crowding the zoom view and a slab cut off at its left edge. That needs camera or script work, so it goes to the next spec for Patricia.

Result: `needs-review`. This is the spec's "stops at max rounds with its FAIL rows listed".

Some of Vera's rows (V8 honey brightness, the V9 "Need $25" cue, the zoom framing) need script or config changes. Bob may only edit `scenes/` and `materials/`, so they stay open and come back in round 2. That is a real limit of a scene-only refiner. It is recorded here rather than widened: those rows become spec items for Patricia, the programmer.

### Voice: Biome intros (`content/_runs/biome-intros/run-2/blackboard.md`)
`python -I _tools/generate.py biome-intros --revise` re-checked the approved Biome intros against the T1–T6 rules.

**Round 1: FAIL.** Clara found:
- a T1 lore line made stale by the GDD's newer Tree C flower table;
- an unsourced real-world flower colour (T4);
- "altitude gives your honey a character", read as a real-world claim (T4).

She also ran the new T6 check (Look & words): every hive described matches the GDD.

**Round 2: PASS.** William revised, and only 1 minor note remains. The draft goes back to `status: draft` for the designer to re-approve.

### Voice, scored: Biome intros again (`content/_runs/biome-intros/run-3/blackboard.md`)
Re-run on 2026-11-20 with Clara's scores, the cached source quotes and the new script checks, with no designer step.
- **Round 1: script check PASS, Clara FAIL.** Two blocking rows: the guide is still offered as "GDD: TBD" with a non-candidate "Wren" (Lore), and an unsourced fireweed colour and a "tried-and-true" Langstroth claim (Facts & French). Scores: Lore 5/10, Facts & French 5/10, Look & words 7/10, Tone & Glossary 9/10, Completeness 9/10, Child safety 10/10, Sources 10/10 (checked by script).
- **Round 2: PASS.** William listed the six GDD guide candidates and removed the unsourced claims. Lore went to 9/10 and Facts & French to 9/10. Two minor Look & words notes remain ("little suns", "warm amber light"), so Look & words stays at 7/10.
- 196,227 tokens for both rounds (Clara × 2, William × 1). This is not comparable with the first run, because the draft and the GDD have both changed since then.

### Props: Milo → vote page with no hand steps (spec item 11)
1. Milo wrote three flower-patch variants (`game/scenes/variants/flower-patch/`).
2. `python -I _tools/model_shots.py flower-patch` rendered them on the 5 × 5 test grid, ran `style_check.py` on each (3/3 PASS), and built the yes / maybe / no vote page.
3. Added to **Design Votes** (https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa). The designer voted B yes, A maybe, C no.

### Evaluator calibration
- `style_critic_check.py`: the 6 script fixtures were caught, and Vera caught both rendered fixtures on her first run (clutter → V3 + V7; low-contrast disabled text → V10).
- `critic_check.py` before and after Clara's T1–T6 change: PASS both times. All three known errors were caught each time (10, then 12 blocking findings).

## Cost
Tokens are total processed, from the run log (`_meta/agent-runs.csv`, tables "Style loop", "Content generation" and "Subagent runs").

| What | Calls | Tokens |
|---|---|---|
| Visual loop, 0.2 farm (`0.2.0-farm/run-5`), 3 rounds, no designer step | Vera × 3, Bob × 2, Patricia × 2 | 768,463 (Vera 56–58k per round; Bob 194k and 152k; Patricia 137k and 115k). The 5 unit-suite runs (baseline + 4 gates, about 4 min each) cost no tokens |
| Visual loop, 0.2 farm, earlier runs (`0.2.0-farm/run-1` to `run-4`) | Vera, Bob, Patricia | `run-1`: 581,609; `run-2` and `run-3` were stopped and `run-4` failed in round 2 (their boards hold whatever per-call rows they wrote) |
| Visual loop, 0.1.2 farm, 3 rounds and 2 designer stops | Vera × 3, Bob × 2 | 466,798 (round 1: 103,927; round 2: 309,760, of which Bob 255,831; round 3: 53,111) |
| Voice loop, Biome intros scored re-run (`biome-intros/run-3`) | Clara × 2, William | 196,227 |
| Voice loop, Biome intros first run (`biome-intros/run-2`) | Clara × 2, William | 131,695 |
| Clara calibration after the scores and the script checks | Clara × 2 | 88,838 and 92,879 |
| Vera calibration | Vera × 2 | 83,171 |
| Clara before / after | Clara × 2 | 161,219 |
| Building M2: Vera's hire (Martin), shot scripts (Quinn), compare_page move, Milo's variants | 4 subagents | ≈ 202,500 |

Vera costs about 53k tokens per round. Bob costs 51k on a small fix list and 256k when his rows need layout reasoning (round 2: 17 turns). He is the cost to watch, and it argues for sending him script-only rows less often. The script half of the evaluator (`style_check.py`, renders, `model_shots.py`) costs no tokens.

## Files

| File | What |
|---|---|
| `STYLE_GUIDE.md` | the rules (designer-approved) |
| `_tools/style_check.py` | script evaluator |
| `.claude/agents/style-critic.md` | Vera, the judgement evaluator |
| `game/tests/style_shots.gd` | the fixed shot set and `measure.json` |
| `_tools/style_loop.py` | the visual loop controller: sandbox, loop's choices, guard, test gate, Bob/Patricia routing |
| `_tools/voice_check.py`, `_tools/source_cache.py` | the voice loop's script checks and Ruth's cached source quotes |
| `_tools/compare_page.py` | A/B comparison and vote pages (`stop` for designer stops, `variants` for Milo's props) |
| `_tools/model_shots.py`, `game/tests/model_shots.gd` | prop variants: render on the 5 × 5 grid, check, vote page |
| `_tools/style_critic_check.py`, `_tools/fixtures/style/` | evaluator calibration |
| `_tools/test_generate.py` (StyleLoop) | controller tests with fake agents |
