Goal agent run `0.2`, fix round 1 for goal C12 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. Do not run the tests: the goal agent runs them after you.

tests:
FAIL    unit      191 passed, 4 failed  (exit 1, 292 noise lines dropped)  game/reports/_runs/20261121-003300/unit.log
    FAIL  t_shop_buttons_disabled_unaffordable_maxed_locked  one row per upgrade: expected 6 got 7  (493 ms)
    FAIL  t_shop_rows_order_and_level_text  six rows: expected 6 got 7 | row 4 name: expected Faster Delivery got Spigot Flow | faster_delivery: level text: expected Lv 1 / 4 got Lv 0 / 5 | row 5 name: expected Auto-Sell got Faster Delivery | A
    FAIL  t_shop_auto_sell_locked_until_delivery_1  six rows expected, got 7  (493 ms)
    FAIL  t_shop_no_row_overlaps_other_controls  six rows: expected 6 got 7  (562 ms)

Spec text:
12. **Spigot Flow** (Tree B; designer's play-test of 0.2.0, 2026-11-09: "the jar filing rate has become the bottleneck"; moved from after 0.2 into 0.2.1, designer 2026-11-09). A new shop row after Centrifuge Gearing: base $30, 1.20× growth, max level 5 (provisional placeholders, erring slow; Terry checks them before 0.3.0). Bottling time per jar is `bottling_seconds_per_jar × (1 − spigot_flow_cut_per_level × level)` (−12%/level: 3.0 → 1.8 s at level 5); the jar's flight time is unchanged. No model change in 0.2.1.

Reply in at most 150 words.