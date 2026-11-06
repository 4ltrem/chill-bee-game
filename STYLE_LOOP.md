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

  request ──► Bob (builder) edits scenes/ and materials/       request ──► William (writer) drafts content/<slug>.md
                 │  only the open, non-designer FAIL rows                    │  only the open FAIL rows
                 ▼                                                           ▼
           style_shots.gd renders 6 shots + measure.json             Clara (content critic)
                 │                                                     checks T1–T6 against the GDD
                 ▼                                                           │
           style_check.py  (script rules: V1 V2 V3 V4 V5 V6               PASS ─► draft, for the designer
                            V10 V11 V12 V14 V15)                       FAIL ─► back to William (max 3 rounds)
                 │
                 ▼
           Vera (style critic) reads the shots (V3 V6 V7 V8 V9 V10 V13 V15)
                 │
     PASS (Vera PASS and no blocking script row) ─► done
     FAIL ─► Bob, next round (max 3 rounds, token cap)
     FAIL row marked (designer) ─► held: comparison page ─► designer edits the guide or picks ─► --resume
```

| Role | Visual loop | Voice loop |
|---|---|---|
| Generator | Bob (Sonnet) | William (Sonnet) |
| Evaluator, measurable | `_tools/style_check.py` (stdlib, no Godot, no tokens) over `game/materials/`, `game/scenes/` and the shots' `measure.json` | — |
| Evaluator, judgement | Vera, the Style Critic (Sonnet, Read/Grep/Glob, looks at the PNG shots) | Clara, the Content Critic (Sonnet) |
| Refiner | Bob, given only the open FAIL rows not held for the designer | William, given only the open FAIL rows |
| Controller | `_tools/style_loop.py` | `_tools/generate.py` |
| Shared record | `game/reports/style/<slug>/blackboard.md` | `content/_runs/<slug>/blackboard*.md` |
| Evaluator calibration | `_tools/style_critic_check.py` on `_tools/fixtures/style/` | `_tools/critic_check.py` on `_tools/fixtures/` |

### What makes it rigorous
- **Measure first, judge second.** Everything a number can settle is a script row with the rule ID, `file:line`, the measured value and a Fix: palette distance in CIE Lab (ΔE ≤ 12 to a token *in the role allowed for that object*), emission only on Honey, at most 2 accent colours, primitive meshes and no textures, parts ≥ 0.05 units, button text contrast ≥ 4.5:1 (WCAG), touch targets ≥ 120 px, fonts ≥ 28/32 px with the ink outline, cells ≥ 20 px at the zoom, glass alpha ≤ 0.35 with back faces drawn. The palette is parsed from the guide on every run, so the designer's edits to the guide take effect without code changes.
- **The critic sees only what scripts can't measure**: clutter and cut-off objects (V7), honey as the brightest thing (V8), state by more than colour (V9), overlap with the HUD (V13), glass reading as glass (V15), plus a second look at accents, shapes and on-screen contrast.
- **The loop can't pass by persuasion.** A round passes only when Vera says PASS *and* `style_check.py` has no blocking row.
- **Vera scores every asset** (designer, 2026-11-05). Under her findings table, each prop and UI element gets a score out of 10 with a one-line reason, on the look words (cozy, whimsical, chunky/round, calm, pastel) and on her rules that apply to it, e.g. "hive: whimsical 3/10, chunky/round 9/10". A score below 6 is also a blocking findings row with a fix for Bob. Score rows start with the asset name, so `style_loop.py` reads only the numbered rows as findings.
- **Refiners get a slice, not the board.** Bob sees only open FAIL rows; Vera sees the shots, the script table and (from round 2) her previous verdict plus Bob's diff. No agent reads the blackboard.
- **Creative choices go to the designer.** A Fix with two or more acceptable answers, a new token or a rule change ends in `(designer)`. Bob never gets it; the loop fixes the rest, lists those rows under *Waiting for the designer*, adds an A/B question with votes to the Design Votes page (`compare_page.py add`), and resumes with `--resume` after the designer picks.
- **The evaluators are tested.** `style_critic_check.py` must catch every known-bad fixture: six script fixtures (neon → V1, glowing hive → V2, texture + imported mesh → V4, third accent → V3, 90 px button → V11, low-contrast disabled text → V10) and two rendered shots Vera must fail (a cluttered, accent-heavy diorama → V3 + V7; a grey-on-grey disabled button → V10). `test_generate.py` checks the controller with fake agents (PASS in round 1, FAIL then PASS, max rounds, token cap, designer stop and resume).

## Demo runs

### Visual: the 0.1.2 farm (`game/reports/style/farm-0-1-2/blackboard.md`)
`python -I _tools/style_loop.py farm-0-1-2`, on the 0.1.2 build, 2026-11-05.

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

### Voice: Biome intros (`content/_runs/biome-intros/blackboard-2.md`)
`python -I _tools/generate.py biome-intros --revise` re-checked the approved Biome intros against the T1–T6 rules.

**Round 1: FAIL.** Clara found:
- a T1 lore line made stale by the GDD's newer Tree C flower table;
- an unsourced real-world flower colour (T4);
- "altitude gives your honey a character", read as a real-world claim (T4).

She also ran the new T6 check (Look & words): every hive described matches the GDD.

**Round 2: PASS.** William revised, and only 1 minor note remains. The draft goes back to `status: draft` for the designer to re-approve.

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
| Visual loop, 3 rounds and 2 designer stops | Vera × 3, Bob × 2 | 466,798 (round 1: 103,927; round 2: 309,760, of which Bob 255,831; round 3: 53,111) |
| Voice loop, 2 rounds | Clara × 2, William | 131,695 |
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
| `_tools/style_loop.py` | the visual loop controller |
| `_tools/compare_page.py` | A/B comparison and vote pages (`stop` for designer stops, `variants` for Milo's props) |
| `_tools/model_shots.py`, `game/tests/model_shots.gd` | prop variants: render on the 5 × 5 grid, check, vote page |
| `_tools/style_critic_check.py`, `_tools/fixtures/style/` | evaluator calibration |
| `_tools/test_generate.py` (StyleLoop) | controller tests with fake agents |
