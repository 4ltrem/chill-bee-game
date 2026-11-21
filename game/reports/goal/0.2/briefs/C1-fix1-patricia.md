Goal agent run `0.2`, fix round 1 for goal C1 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). tests:
FAIL    unit      154 passed, 11 failed  (exit 1, 260 noise lines dropped)  game/reports/_runs/20261109-190341/unit.log
    FAIL  t_harvest_holds_anchor_spin_below  farm view: Spin does not overlap ShopPanel [P: (24, 620), S: (672, 628)] | farm view, Harvest placed first: Spin does not overlap ShopPanel [P: (24, 620), S: (672, 628)] | farm view, Spin placed firs
    FAIL  t_crank_ignored_outside_cranking  CRANKING: real clicks counted and finished the bucket (positive control) (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself) | DONE: no extra turn: expected 0 got 16 | BOTTLIN
    FAIL  t_real_mouse_taps_crank  exactly ceil(jars x taps_per_jar) real clicks finish the bucket: expected 16 got 32 | DONE (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself) | 15 real clicks in zero time were alread
    FAIL  t_real_touch_taps_crank  touch taps finished the bucket (32 sent) (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself)  (386 ms)
    FAIL  t_button_press_is_not_a_crank  clicks off the button finish the bucket (positive control) (state 3: DONE, BOTTLING or EMPTY expected; 0.1.2 starts bottling by itself)  (395 ms)
    FAIL  t_dev_button_clear_of_hud  farm: no HUD control overlaps the DevButton [P: (8, 600), S: (80, 80)]: expected [] got ["ShopPanel [P: (24, 620), S: (672, 628)]", "Row_swarm [P: (24, 620), S: (664, 120)]", "NameLabel [P: (24, 620), S: (49
    FAIL  t_barrel_eases_to_stop  no frame turns the barrel faster than the frame before it (worst rise 0.48 rad/s at sample 4)  (1226 ms)
    FAIL  t_camera_second_stop_in_frame  Centrifuge is wholly in frame at the second stop (screen box [P: (244.0349, -241.6409), S: (267.1646, 269.9258)], viewport [P: (0, 0), S: (720, 1280)])  (3465 ms)
    FAIL  t_camera_second_stop_hive_share  the hive is partly shown: 0.0% of its silhouette is on screen (want > 0 and < 100%; 0 of 810 points) | the visible part is in the upper-right quadrant (0% of its points; centroid (0, 0); want >= 90%)  
    FAIL  t_camera_second_stop_hud_clear  part of the hive shows (its visible box is the rect no control may cover)  (3474 ms)
    FAIL  t_camera_pan_seconds  after a live change to 2.5 the pan took 2.442 s +- 0.057 s  (7162 ms)

Spec text:
1. **Upgrade shop holds several rows.** Today `shop_ui.gd` shows one item (Worker Swarm Count). It becomes a list of rows, one per upgrade, each with name, level ("Lv 2 / 5", or "Owned" for one-time buys), and a buy button showing the next cost ($, rounded down) that is disabled when unaffordable, maxed or locked. A locked row shows its gate ("Needs Faster Delivery 1"). Costs follow GDD §3: `base × growth^level`. Rows, in order: Worker Swarm Count, Flight Endurance, Heated Uncapping Fork, Centrifuge Gearing, Faster Delivery, Auto-Sell. The panel scrolls if the rows do not fit at 720 × 1280. The look of the new UI (`UI_DESIGN.md`: icons over the shots, wrench icon) is **not** in 0.2; the existing panel is extended.

Reply in at most 150 words.