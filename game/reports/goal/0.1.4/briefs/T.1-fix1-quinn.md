Goal agent run `0.1.4`, fix round 1 for goal T.1, T.2, T8.1, T.3 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: tests/

mutations:
mutate: no mutations to run

Spec text:
3. **Back in one fixed place** (play-test: "the back button isn't consistent"). It is a screen-space button in the **top-right** corner in the first zoom and at the second stop, not found by a scan (designer, 2026-11-06: "top right to not interfear with the labels").

8. **Instruction text below Back** (designer's review of the 0.1.4 build, 2026-11-07: "back button overlaps instruction text at top, can fix by lowering instruction test below the back button").
   - The instruction text at the top of the zoom (`HintLabel`) moves down so it sits below Back's top-right rect, in the first zoom and at the second stop. Back stays where item 3 puts it.

Reply in at most 150 words.