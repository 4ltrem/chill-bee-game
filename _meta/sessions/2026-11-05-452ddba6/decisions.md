---
session: 452ddba6-1b46-43f6-9e87-632fc9f4c407
dates: 2026-11-05 to 2026-11-05
transcript: session.jsonl (this folder, gitignored)
description: M2 built (style_check.py, style_loop.py, Vera, model_shots.py) and demoed on the 0.1.2 farm; the designer settled the rim-mark accent and deferred honey as the hero
---
# Decisions: session 452ddba6 (2026-11-05 to 2026-11-05)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D86 · 2026-11-05 · Game design · The truck red and crank gold stay the only accents; the rim mark turns charcoal
- Decided: the first visual-loop stop (V3) went to the designer, who picked A: `game/materials/rim_mark.tres` is recoloured to charcoal (0.25, 0.25, 0.28) and `style_check.py` counts it in the Shadow role. The scene keeps two accent colours, the crank handle and the truck paint, which also clears the V1 row on the rim mark.
- Why: the style guide allows at most 2 accents in a scene set, and the rim mark was a third (nearest token ΔE 16.0, limit 12.0).
- Rejected: B, approving the rim mark as a third accent in `STYLE_GUIDE.md`; recolouring it to truck red.
- Files: `game/materials/rim_mark.tres`, `_tools/style_check.py`, `game/reports/style/farm-0-1-2/blackboard.md`

### D87 · 2026-11-05 · Game design · Honey as the hero of the frame is deferred to a later spec
- Decided: at the V8 stop (round 2) the designer chose neither option for now. Vera's note that the gold progress bar, the Harvest and Spin buttons and the red truck out-shine the small honey coins stays a minor note in round 3, to be revisited in a later spec.
- Why: both options needed a design change of their own: A shrinks the truck, B enlarges the honey props.
- Rejected: A, shrink the truck; B, enlarge the honey props.
- Files: `game/reports/style/farm-0-1-2/blackboard.md`, `STYLE_LOOP.md`

## Still open

