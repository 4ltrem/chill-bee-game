Goal agent run `0.1.4`, fix round 1 for goal C14 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: scenes/ and materials/

tests:
FAIL    unit      146 passed, 4 failed  (exit 1, 224 noise lines dropped)  game/reports/_runs/20261108-020656/unit.log
    FAIL  t_hive_lid_leaning_pose  the risen frame clears the body with a visible gap (lowest frame point 0.843, body top 0.952; frame_rise 0.76)  (962 ms)
    FAIL  t_layout_hive_scale_follows_config  a live change down to 0.7 shrinks it: expected 0.7 (+-0.02) got 0.77901034498144  (638 ms)
    FAIL  t_spin_icon_in_first_zoom  Spin does not cover the rack (spin [P: (145.9278, 388.4834), S: (160, 160)], rack [P: (297.847, 272.9299), S: (370.5362, 426.5263)]): expected true got false  (2291 ms)
    FAIL  t_combs_fill_frame_and_hive_whole  frame 1, slot axis 0: the cells span 147% of the frame's inner area (0.90 to 1.10) | frame 1, slot axis 2: the cells span 160% of the frame's inner area (0.90 to 1.10) | frame 2, slot axis 0: the cel

Spec text:
14. **The hive is the round 9 pick** (designer's play-test of 0.1.4, 2026-11-08: "the hive and frame models were changed WRONG"). C5 built a shallow hive body with its front-left wall missing and two large flat frames, not the pick. `scenes/props/hive.tscn` must match `scenes/variants/hive-frames/hive-frames-a.tscn` (render `game/reports/variants/hive-frames-r9/hive-frames-r9-a.png`): a deep box with all four walls, five upright frames standing side by side, the comb cells on each frame filling it edge to edge, the lid hinged at the back. The frames still rise one at a time in the first zoom.

Reply in at most 150 words.