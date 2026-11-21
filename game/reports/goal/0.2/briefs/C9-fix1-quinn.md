Goal agent run `0.2`, fix round 1 for goal C9 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Do not run the tests: the goal agent runs them after you.

tests:
    FAIL  t_dev_button_clear_of_hud  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20) | second stop: the view could not be set up  (26726 ms)
    FAIL  t_camera_second_stop_in_frame  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5622 ms)
    FAIL  t_camera_second_stop_hive_share  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5622 ms)
    FAIL  t_camera_second_stop_hud_clear  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5630 ms)
    FAIL  t_camera_back_from_second_stop  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5760 ms)
    FAIL  t_camera_pan_seconds  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5669 ms)
    FAIL  t_second_stop_back_tap  the camera reached pan_zoom_size 9.54 once the bucket was full (now 20)  (5677 ms)
    FAIL  t_second_stop_spin_icon_tap  Back with the bucket full pans to the second stop (size 20)  (3988 ms)
    FAIL  t_second_stop_fork_icon_tap  Back with the bucket full pans to the second stop (size 20)  (3996 ms)
    FAIL  t_icons_never_overlap  the second stop was reached (size 20)  (4365 ms)
    FAIL  t_pan_after_all_frames_uncapped  all frames uncapped: the camera is at the second stop within camera_pan_seconds + 1 s of the last cell (size 20, at_second_stop false)  (4550 ms)
    FAIL  t_pan_after_back_then_harvest_again  Back with the bucket full pans to the second stop (size 20)  (4021 ms)

Spec text:
9. **The second stop only after Spin** (designer's play-test of 0.2.0, 2026-11-09: "camera should only zoom to second zoom screen after spin is tapped"). A full bucket no longer ends the first zoom or pans the camera: the player keeps harvesting (cells go to the pile), and when the zoom ends (all frames done, or Back) the camera returns to the farm view. The camera goes to the second stop only when Spin is tapped (0.1.4 item 11, unchanged). Replaces the 0.1.3 play-test rule "a full bucket pans to the second stop" (`_filled_in_zoom`, `_closing_to_second` in `main.gd`) and its test in `test_camera.gd`.

Reply in at most 150 words.