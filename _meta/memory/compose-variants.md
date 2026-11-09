---
name: compose-variants
description: "Vote rounds that only recombine seen parts are compose_variant.py recipes, not Milo runs (designer, 2026-11-09)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 14aa3b08-e4b9-4359-8fa9-02129adf502f
  modified: 2026-11-09T20:34:09.953Z
---

A variant round that only recombines parts the designer already saw (add B's part to A, drop a part, swap a
material, nudge a part) is built with `_tools/compose_variant.py` (graft/drop/material/move on node paths), not a
Milo run. Milo is for new shapes only, and builds each feature as one named group with any tilt on one `Pose` node.

**Why:** the designer asked to cut tokens on permutation runs; 0.2 rounds 2–3 cost 34k–112k tokens per Milo run for
what was mostly copy-and-recombine.

**How to apply:** after reading votes, write one compose command per wanted file into the next `-r<N>` folder, then
one Rex call shoots all props. A note that needs a number ("handle deeper") becomes 2–3 `--move` values side by side.
Related: [[variant-shots]], [[ab-comparison-page]], [[rex-runs-scripts]].
