Goal agent run `0.1.4`, fix round 1 for goal C7 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Rerun only the tests you touch (CB_ONLY).

tests:
FAIL    unit      137 passed, 1 failed  (exit 1, 202 noise lines dropped)  game/reports/_runs/20261107-205657/unit.log
    FAIL  t_zoom_bucket_lid_pile_flow  round 1: FULL again, Spin shows: expected 2 got 3 | round 2: Spin shows | round 2: ceil(jars x 4) = 16 real clicks: expected 16 got 15 | round 2: FULL again, Spin shows: expected 2 got 3 | round 3: Spin sh

Spec text:
7. **The pile loads on its own at the second stop** (designer's play-test of the merged build, 2026-11-06: "when in the second zoom screen the centrifuge fills up pours and then have to retap spin, this shouldn't be needed as we're already in the second zoom screen, the pile should just load up no matter if in the second screen or not").
   - When the centrifuge has finished a batch and poured, the waiting pile loads into it without a new Spin tap. This holds in every view, the second stop included.
   - Spin is needed only to start spinning a loaded centrifuge. The player is never asked to press Spin just to load the pile.
   - **What the designer saw (play-test of 0.1.4, 2026-11-07):** "the bucket pours then it loads the pile but prompts me to press spin again when already in spin mode, it should just keep the text while it loads again, if there's no pile it exits the spin mode". The pile does load; the bug is the prompt. While the pile reloads after a pour, spin mode stays on and its text stays as it was, with no "press Spin" prompt. If no pile is waiting after the pour, spin mode exits.

Reply in at most 150 words.