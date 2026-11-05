---
author: orchestrator
type: write-up
status: draft
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
- **Refiners get a slice, not the board.** Bob sees only open FAIL rows; Vera sees the shots, the script table and (from round 2) her previous verdict plus Bob's diff. No agent reads the blackboard.
- **Creative choices go to the designer.** A Fix with two or more acceptable answers, a new token or a rule change ends in `(designer)`. Bob never gets it; the loop fixes the rest, lists those rows under *Waiting for the designer*, builds an A/B comparison page (`compare_page.py stop`), and resumes with `--resume` after the designer picks.
- **The evaluators are tested.** `style_critic_check.py` must catch every known-bad fixture: six script fixtures (neon → V1, glowing hive → V2, texture + imported mesh → V4, third accent → V3, 90 px button → V11, low-contrast disabled text → V10) and two rendered shots Vera must fail (a cluttered, accent-heavy diorama → V3 + V7; a grey-on-grey disabled button → V10). `test_generate.py` checks the controller with fake agents (PASS in round 1, FAIL then PASS, max rounds, token cap, designer stop and resume).

## Demo runs

<!-- filled in from the runs -->

## Cost

<!-- filled in from the run log -->

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
