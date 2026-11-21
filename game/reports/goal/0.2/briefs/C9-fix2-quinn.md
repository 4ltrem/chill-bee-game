Goal agent run `0.2`, fix round 2 for goal C9 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Do not run the tests: the goal agent runs them after you.

tests:
    FAIL  t_resume_pending_pile_loads_while_zoom_open  Back: the full bucket panned to the second stop: expected true got false | Back: the fork is hidden at the second stop (frames 4 and 5 hold Capped cells) | Spin: CRANKING: expected 3 got 2 
    FAIL  t_camera_second_stop_hud_clear  no HUD control overlaps the hive's visible screen rect [P: (386.4121, 8.572388), S: (330, 300)]: expected [] got ["CentrifugeLabel [P: (242.1172, 16), S: (271, 87)]"]  (4669 ms)
    FAIL  t_camera_pan_seconds  the pan took 3.601 s; camera_pan_seconds is 1.200 s +- 0.060 s (one frame) | after a live change to 2.5 the pan took 4.930 s +- 0.064 s  (9356 ms)
    FAIL  t_second_stop_spin_icon_tap  Spin shows at the second stop (bucket FULL) | Spin sits at its anchor's projected point or clamped inside the screen (off by 497 px)  (3166 ms)
    FAIL  t_icons_never_overlap  second stop: at least one icon shows (0)  (3528 ms)
    FAIL  t_hud_no_overlap_no_cutoff  the second stop was reached (size 20)  (4722 ms)
    FAIL  t_buttons_at_anchor_or_clamped  the second stop was reached (size 20) | buttons were measured (1)  (4476 ms)
    FAIL  t_harvest_hidden_at_second_stop  self-check: Spin still shows at the second stop, so only Harvest is hidden  (3705 ms)
    FAIL  t_back_fixed_top_right  the second stop was reached (size 20) | Back was measured in both views (["first zoom"])  (4367 ms)
    FAIL  t_centrifuge_label_on_centrifuge  Spin shows at the second stop  (3234 ms)
    FAIL  t_crank_pauses_on_back_and_resumes_on_spin  Spin shows at the second stop  (4589 ms)
    FAIL  t_paused_crank_never_finishes_in_farm_view  Spin shows at the second stop | 18 taps in the farm view counted no turn: expected 0 got 1  (4337 ms)

Spec text:
9. **The second stop only after Spin** (designer's play-test of 0.2.0, 2026-11-09: "camera should only zoom to second zoom screen after spin is tapped"). A full bucket no longer ends the first zoom or pans the camera: the player keeps harvesting (cells go to the pile), and when the zoom ends (all frames done, or Back) the camera returns to the farm view. The camera goes to the second stop only when Spin is tapped (0.1.4 item 11, unchanged). Replaces the 0.1.3 play-test rule "a full bucket pans to the second stop" (`_filled_in_zoom`, `_closing_to_second` in `main.gd`) and its test in `test_camera.gd`.

Reply in at most 150 words.