---
name: scripted-shots
description: Repeated screenshot moments are captured by a script (_tools/ui_shots.py); an agent is only called when a new screen/phase/menu is added
metadata:
  node_type: memory
  type: feedback
  originSessionId: 49ba7bdd-dbda-4adf-93f8-abf4c4364924
  modified: 2026-11-08T00:32:37.583Z
---

Capturing the same game moments across versions is a script job: `python -I _tools/ui_shots.py LABEL=WORKTREE ...` runs the MOMENTS list in `game/tests/ui_compare_shots.gd` in each worktree. Call Bob only when a new screen, phase or menu enters the game, to add its entry to MOMENTS.

**Why:** the designer, 2026-11-06: "the capturing shots routine should be done by a script since they're all the same moments and only need to call another agent when a new screen/phase/menu is added". Agent runs cost budget, and these shots are deterministic.

**Gradual animations get several shots** (designer, 2026-11-07): anything that changes over time (meter fill, pour, pile load) is shot at several points, at least empty, about half and full. A single shot hid the Harvest meter's unclipped rectangle in 0.1.4.

**How to apply:** for UI or layout comparisons, run ui_shots.py yourself or dispatch Rex, then build the Design Votes section ([[ab-comparison-page]]). Brief Bob only for new moments. The same thinking as [[cost-rules]].
