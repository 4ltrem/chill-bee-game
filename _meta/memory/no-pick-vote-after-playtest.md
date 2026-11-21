---
name: no-pick-vote-after-playtest
description: "Don't put pick-match (live prop vs picked variant) images on Design Votes for models the designer has play-tested or will play-test; keep vote images small"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9ceb748d-2e54-44be-96d3-936a83f0e62e
  modified: 2026-11-10T06:14:44.696Z
---

Pick-match pairs (live prop beside the picked variant) do not go on Design Votes as a vote round when the designer has play-tested the build or will play-test it: the play-test is the model check. Also, full 720 x 1280 images stacked one per row were "way too big"; any vote section uses the 3-column grid, never a one-column stack.

**Why:** designer 2026-11-10 (D217): "the images on the new voting round are way too big, the models were fine when I playtested so no need for a voting round to check models if I will already be playtesting".

**How to apply:** `pick_match.py` stays a goal-agent step (Vera's automated check), never a designer vote. Before adding a Design Votes section, ask whether the designer's next play-test already covers it. Related: [[ab-comparison-page]], [[look-before-done]].
