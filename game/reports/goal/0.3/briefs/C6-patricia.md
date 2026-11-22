Goal agent run `0.3`, spec `game/specs/0.3-course-build.md`, goal C6. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.

Your contract lines:
- Item 6: the skip icon script, using the same plant path as item 3 at no cost.

Spec text:
6. **Skip to ending.** A small skip icon at the farm view's edge (designer, 2026-11-22: visible for graders, not on the welcome screen), with the label `skip_icon_label` as its tooltip/accessibility text. Pressing it plants every remaining patch for free (each with its grow-in), so Health reaches thriving and items 4 and 5 follow as in normal play. It hides once thriving is reached. Clears every other farm-view control.

Reply in at most 150 words: files changed, node names used, open questions.