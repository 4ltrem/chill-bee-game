---
author: designer
type: spec
status: draft
milestone: M2 (Assignment 6, target 2026-11-12)
description: The style guide agent: one style guide (STYLE_GUIDE.md) enforced by two Generator → Evaluator → Refiner loops: visual (Bob → style_check.py + a new style critic → Bob) and voice (William → Clara → William, existing)
---
# M2: Style guide agent (Assignment 6)

**The assignment:** "Build an automated, self-correcting AI loop (Generator → Evaluator → Refiner) that rigorously enforces the specific aesthetic and narrative rules of your existing capstone game."

**Designer's choices (2026-11-04):** the guide covers both phases in layers (colorbox now, art packs later); the evaluator is a script for what can be measured plus a vision critic for what can't; one guide, two critics (visual: new; voice: Clara).

## What gets built

| # | Piece | Who | Notes |
|---|---|---|---|
| 1 | `STYLE_GUIDE.md` | orchestrator drafts, **designer approves** | rule IDs V1–V15, T1–T6, palette tokens by role, phases. Draft written 2026-11-04 |
| 2 | `_tools/style_check.py` | orchestrator | the measurable rules over `game/materials/`, `game/scenes/` and Quinn's measure output: V1 palette ΔE by role, V2 emission, V3 accent count, V4 primitives and no textures, V5 vertex budget (art phase), V10 contrast of scene colours, V11 touch sizes, V12 font sizes, V14 cell width, V15 glass alpha. Prints a FAIL table with rule ID, file:line and a Fix; exit 0/1. Standard library only, no Godot |
| 3 | the **style critic** agent | **Martin** writes `.claude/agents/style-critic.md` from `_templates/agent.md`, adds it to `_meta/team.md` | Read, Grep, Glob only (reads PNG shots). Judges the critic-rules (V3, V6–V10, V13, V15) on Bob's shot set plus `style_check.py`'s table, replies with a verdict block in Clara's format, every FAIL row naming a rule ID, the shot and a Fix. Sonnet, per the team's model rule (a critic with no check after it is calibrated on fixtures) |
| 4 | the shot renderer | **Quinn** writes `game/tests/style_shots.gd` | renders the fixed shot set (farm per state, zoom, bucket full, pile, truck away) at 720 × 1280 into a given folder; reuses `shots_0_1.gd` |
| 5 | `_tools/style_loop.py` | orchestrator | the controller, built like `generate.py`: per round, render shots → `style_check.py` → critic → if FAIL, Bob gets only the open FAIL rows and edits `scenes/`/`materials/` → next round; stop at PASS or `--max-rounds 3`/`--max-tokens`. Blackboard `game/reports/style/<slug>/blackboard.md` (request, each round's script table, verdict, Bob's diff), every agent call in the run log, transcripts kept under `_meta/sessions/runs/` |
| 6 | calibration fixtures | orchestrator + Quinn | `_tools/fixtures/style/`: known-bad cases the evaluator must fail with the expected rule IDs (a neon material → V1; a glowing hive → V2; a textured mesh → V4; a cluttered shot with a third accent → V3/V7; a 90 px button → V11; low-contrast disabled text → V10). `_tools/style_critic_check.py`, like `critic_check.py`, exits 0 only when every fixture is caught |
| 7 | the voice half | orchestrator | Clara's definition points to STYLE_GUIDE.md's Voice rules (T1–T6, T6 new). Per `_meta/team.md`, run `critic_check.py` before and after the change |
| 8 | tests | orchestrator | `test_generate.py` gains style-loop tests with fake agents (PASS in round 1, FAIL then PASS, max rounds, token cap), and `style_check.py` tests on the fixtures |
| 9 | the demo run and write-up | orchestrator, designer | one real visual loop on the 0.1.1 farm, one voice loop (an existing content revise), and `STYLE_LOOP.md`: diagram, both loops, the blackboards, cost from the run log (the A6 deliverable) |

## Order

1. Designer approves `STYLE_GUIDE.md` (palette and rules are the designer's call).
2. In parallel: `style_check.py` + fixtures + tests (orchestrator); Martin hires the critic; Quinn writes `style_shots.gd` (after 0.1.1 lands, so it renders the current farm).
3. `style_loop.py` with fake-agent tests; `style_critic_check.py` calibrates the critic on the fixtures (fix the critic's definition until it catches all).
4. Clara's pointer to the Voice rules, with `critic_check.py` before and after.
5. Demo runs, write-up, checkpoint commits on a `milestone/m2` branch.

## Expected first findings (honest test of the loop)
`style_check.py` will likely flag today's farm: the truck's red and the crank's orange are listed as approved accents, but the UI's dark gold and the shop panel need checking against V10, and any material Bob added off-palette fails V1. Findings the designer disagrees with become palette or rule changes, made by the designer in the guide.

## Done when
`style_critic_check.py` and `critic_check.py` exit 0; `test_generate.py` green; one visual loop run reaches PASS (or stops at max rounds with its FAIL rows listed) with its blackboard committed; `STYLE_LOOP.md` written; all agent calls in the run log.
