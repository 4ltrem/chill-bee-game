Goal agent run `0.2`, fix round 2 for goal C14 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Do not run the tests: the goal agent runs them after you.

tests:
    FAIL  t_real_touch_taps_crank  touch taps finished the bucket (32 sent) (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself)  (1214 ms)
    FAIL  t_button_press_is_not_a_crank  clicks off the button finish the bucket (positive control) (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself)  (1272 ms)
    FAIL  t_zoom_bucket_lid_pile_flow  round 1: ceil(jars x 4) = 16 real clicks: expected 16 got 22 | round 1: DONE (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself) | round 1: bottling started by itself, no input aft
    FAIL  t_no_crank_during_zoom  positive control: one real click on the farm counts one turn: expected 1 got 0 | clicks and a hold during the zoom counted no turn: expected 1 got 0 | a drag across the frame is never a crank turn: expected 1 g
    FAIL  t_dev_button_clear_of_hud  farm: no HUD control overlaps the DevButton [P: (8, 600), S: (80, 80)]: expected [] got ["ShopPanel [P: (24, 244), S: (672, 1004)]", "Row_heated_fork [P: (24, 496), S: (672, 120)]", "Row_gearing [P: (24, 622
    FAIL  t_camera_second_stop_in_frame  Centrifuge is wholly in frame at the second stop (screen box [P: (244.0346, -617.641), S: (267.1649, 269.926)], viewport [P: (0, 0), S: (720, 1280)]) | Crate is wholly in frame at the second stop (screen
    FAIL  t_camera_second_stop_hive_share  the hive is partly shown: 0.0% of its silhouette is on screen (want > 0 and < 100%; 0 of 810 points) | the visible part is in the upper-right quadrant (0% of its points; centroid (0, 0); want >= 90%)  
    FAIL  t_camera_second_stop_hud_clear  part of the hive shows (its visible box is the rect no control may cover)  (4919 ms)
    FAIL  t_second_stop_spin_icon_tap  no other control takes a press at Spin's centre: expected [] got ["ShopPanel [P: (24, 244), S: (672, 1004)]", "Row_heated_fork [P: (24, 496), S: (672, 120)]"]  (3901 ms)
    FAIL  t_second_stop_fork_icon_tap  no other control takes a press at Harvest's centre: expected [] got ["ShopPanel [P: (24, 244), S: (672, 1004)]", "Row_flight [P: (24, 370), S: (672, 120)]"]  (4320 ms)
    FAIL  t_icons_never_overlap  farm view: ForkIcon does not meet ShopPanel ([P: (330.5096, 359.7905), S: (240, 120)], [P: (24, 244), S: (672, 1004)]): expected false got true  (3844 ms)
    FAIL  t_hud_no_overlap_no_cutoff  farm view: no HUD controls overlap and none is cut off: expected [] got ["ForkIcon [P: (330.5096, 359.7905), S: (240, 120)] overlaps ShopPanel [P: (24, 244), S: (672, 1004)]", "ShopPanel [P: (24, 244), S: (

Spec text:
14. **The shop shows every row without scrolling** (same play-test: "I don't like the scrolling menu, the menus that have been implemented do work"). The shop panel is tall enough to show all seven rows at once at 720 × 1280, with no scroll container, and still clears the HUD. Replaces item 1's "the panel scrolls if the rows do not fit" and the C1 hand fix (`ShopScroll` one-row height). A stopgap: 0.3.0's Shop sheet replaces the panel.

Reply in at most 150 words.