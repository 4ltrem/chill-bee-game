---
name: variant-shots
description: "Milo's prop variants are shot on one shared grid in one load, each close up (designer feedback 2026-11-05)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: cbb6da0e-d437-4e4a-8094-be94d2d136c8
  modified: 2026-11-08T07:48:18.160Z
---

When a run makes several variants of a model, put them all on the same grid (one Godot load, side by side) and zoom
in close on each model for its screenshot. Done 2026-11-05 in `game/tests/model_shots.gd` (others hidden per shot,
ortho size fitted to the variant's bounds; `model_shots.py --size N` still forces a fixed size).

**Why:** the designer wants it faster (one load instead of one per variant) and the old whole-grid shots (size 12)
showed the prop too small to judge.

**One folder per vote round** (2026-11-08): Milo writes `game/scenes/variants/<prop>-r<N>/`, and `model_shots.py` refuses a name without `-r<N>` (`--unnumbered` for old folders), because round 9 overwrote round 8's hive scenes before any commit.

**How to apply:** keep it this way in any new shot tool (Bob's comparison shots too); Milo only writes the `.tscn`
files, so the change lives in the renderer, not in his definition. Related: [[ab-comparison-page]].
