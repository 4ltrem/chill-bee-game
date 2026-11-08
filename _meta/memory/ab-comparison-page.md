---
name: ab-comparison-page
description: "Every creative A/B choice gets a screenshot comparison artifact in the Zoom Framing Options layout (update it if same question, else new)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: e0d1da16-c10b-4153-9084-bbcd654fdb0b
  modified: 2026-11-07T19:17:49.272Z
---

Any creative A/B test (layout, framing, colour or token, look options; any choice with two or more acceptable answers)
gets a screenshot comparison page for the designer. **All of them go into the one existing comparison artifact**
(https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa): a new question becomes a new section on it, and earlier rounds
stay collapsed. Never publish a separate artifact and never open it in the browser; just give the link (designer,
2026-11-05: the V3 and Flower Patch pages opened in the browser as two separate artifacts). Layout reference: "Zoom Framing Options",
https://claude.ai/artifact/37Prvthj1P2Z2bQPokRkym (brief, one card per option with letter, title, 720 × 1280 shot,
measured numbers with pass/low pills, the current build as the reference). Nothing is applied until the designer picks.
The designer wants real screenshots (not just text/ASCII) and at most 9 images per page (e.g. 3 × 3 settings), each with
yes / maybe / no buttons and a note, saved in the artifact's db collection `votes` (capability `db`). On "read my votes",
read it with ArtifactData `list` and write the result to a decisions JSON next to the shots in the repo. Builder scripts:
`_tools/compare_page.py` (subcommands `page` = option cards, `round`/`votes` = vote grids, `stop` = one designer-stop row of a blackboard; layout in `_tools/compare_page_head.html`).
Current page: https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (grid zoom votes, 2026-11-05).

**Numerical visual changes too** (designer, 2026-11-07): any visual change that comes down to a number (a scale, an
offset, a margin, a size: e.g. 0.1.4's frame scale 1.35× vs a wider hive, or the anchor offsets) gets its own section on
Design Votes, built with the existing scripts (`ui_shots.py` / `model_shots.py` to render the values, then
`compare_page.py add --versions` or `--option`). "It's hard for me as a human to decide without a visual." Never ask the
designer to pick a visual number from text alone; a question in chat or a blackboard stop links the section.

**Contact sheets too small** (designer, 2026-11-07): when a section shows the combined sheet (`contact_sheet.py`, all
shots tiled in one image), it must take more space: full content width, and click-to-enlarge, or the shots shown as
separate cards instead. Fix it in `_tools/compare_page.py` / `compare_page_head.html` before the next votes page.

**Why:** the designer asked for it (2026-11-05), while reviewing the M2 style loop: creative choices are theirs, and
they decide by looking at the options side by side.

**How to apply:** in the M2 style loop it is spec item 5a (`_tools/compare_page.py`, designer stops); outside the loop,
build the page whenever a proposal or a build offers options. Related: [[dev-mode-and-pacing]], [[session-handoff]].
