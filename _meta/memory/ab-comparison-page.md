---
name: ab-comparison-page
description: "Every creative A/B choice gets a screenshot comparison artifact in the Zoom Framing Options layout (update it if same question, else new)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: e0d1da16-c10b-4153-9084-bbcd654fdb0b
  modified: 2026-11-05T07:54:21.929Z
---

Any creative A/B test (layout, framing, colour or token, look options; any choice with two or more acceptable answers)
gets a screenshot comparison page for the designer: modify the existing comparison artifact when it is the same
question, or make a new one in the same layout. Layout reference: "Zoom Framing Options",
https://claude.ai/artifact/37Prvthj1P2Z2bQPokRkym (brief, one card per option with letter, title, 720 × 1280 shot,
measured numbers with pass/low pills, the current build as the reference). Nothing is applied until the designer picks.
The designer wants real screenshots (not just text/ASCII) and at most 9 images per page (e.g. 3 × 3 settings), each with
yes / maybe / no buttons and a note, saved in the artifact's db collection `votes` (capability `db`). On "read my votes",
read it with ArtifactData `list` and write the result to a decisions JSON next to the shots in the repo. Builder scripts:
`_tools/compare_page.py` (subcommands `page` = option cards, `round`/`votes` = vote grids, `stop` = one designer-stop row of a blackboard; layout in `_tools/compare_page_head.html`).
Current page: https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (grid zoom votes, 2026-11-05).

**Why:** the designer asked for it (2026-11-05), while reviewing the M2 style loop: creative choices are theirs, and
they decide by looking at the options side by side.

**How to apply:** in the M2 style loop it is spec item 5a (`_tools/compare_page.py`, designer stops); outside the loop,
build the page whenever a proposal or a build offers options. Related: [[dev-mode-and-pacing]], [[session-handoff]].
