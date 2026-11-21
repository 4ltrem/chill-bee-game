Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C9. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 9: `main.gd` drops the full-bucket pan and early zoom end; only `spin_tapped` sends the camera to the second stop.

Spec text:
9. **The second stop only after Spin** (designer's play-test of 0.2.0, 2026-11-09: "camera should only zoom to second zoom screen after spin is tapped"). A full bucket no longer ends the first zoom or pans the camera: the player keeps harvesting (cells go to the pile), and when the zoom ends (all frames done, or Back) the camera returns to the farm view. The camera goes to the second stop only when Spin is tapped (0.1.4 item 11, unchanged). Replaces the 0.1.3 play-test rule "a full bucket pans to the second stop" (`_filled_in_zoom`, `_closing_to_second` in `main.gd`) and its test in `test_camera.gd`.

Reply in at most 150 words: files changed, node names used, open questions.