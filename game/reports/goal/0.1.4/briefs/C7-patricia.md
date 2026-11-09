Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C7. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 7: the pile loads after a pour in every view, with no Spin press needed. Rework (play-test 2026-11-07): while the pile reloads after a pour, spin mode and its text stay and no "press Spin" prompt shows; with no pile waiting, spin mode exits.

Spec text:
7. **The pile loads on its own at the second stop** (designer's play-test of the merged build, 2026-11-06: "when in the second zoom screen the centrifuge fills up pours and then have to retap spin, this shouldn't be needed as we're already in the second zoom screen, the pile should just load up no matter if in the second screen or not").
   - When the centrifuge has finished a batch and poured, the waiting pile loads into it without a new Spin tap. This holds in every view, the second stop included.
   - Spin is needed only to start spinning a loaded centrifuge. The player is never asked to press Spin just to load the pile.
   - **What the designer saw (play-test of 0.1.4, 2026-11-07):** "the bucket pours then it loads the pile but prompts me to press spin again when already in spin mode, it should just keep the text while it loads again, if there's no pile it exits the spin mode". The pile does load; the bug is the prompt. While the pile reloads after a pour, spin mode stays on and its text stays as it was, with no "press Spin" prompt. If no pile is waiting after the pour, spin mode exits.

Reply in at most 150 words: files changed, node names used, open questions.