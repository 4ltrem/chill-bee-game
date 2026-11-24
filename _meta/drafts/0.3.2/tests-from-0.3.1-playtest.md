---
type: draft
status: for the 0.3.2 spec
version: 0.3.2
decided: 2026-11-23, designer ("should include those in the next batch of tests as well as the other issues I encountered in my 0.3.1 play test")
---
# Tests for 0.3.2: what the 0.3.1 play-test found that no test caught

Every row was fixed by hand on 2026-11-23 (commits named) and needs a test that fails on the old code (add a mutation for each in `tests/mutations.json`). Quinn writes them in the 0.3.2 build; the orchestrator puts them in the spec's test lines.

| # | Found | Fixed in | Test to add (fails on the old code) |
|---|---|---|---|
| 1 | The hint walk test `t_hint_steps_follow_state_in_order_twice` hangs after the crank: its `_until` for SellIcon never returns (WALK markers in `test_helpers_4.gd` `_hi_walk`); set aside in `run_tests.gd` | not fixed | Find why the test clock stops after bottling, fix it, put the test back in the suite |
| 2 | Settings gear did nothing: `SettingsPanel` had no `ModalPanel` script; no Settings test existed (T7.1 was accepted as "already tested") | `77f8c49` | A real tap on `SettingsButton` opens `SettingsPanel`; English / Français switch the labels; Close and the dim close it |
| 3 | "Coming soon" invisible (white text on the cream sheet); no test checked it rendered | `77f8c49` | On Research and Refinery, `ComingSoonLabel` is visible, reads `tr("shop_coming_soon")` and its font colour contrasts with the sheet (not white) |
| 4 | "Research" lost its "h" (equal-width tabs with `clip_text`) | `77f8c49` | Each tab's text fits its button at 28 px, in English and French (no clipping) |
| 5 | Fork icon read as empty at full (the honey fill hid at full, leaving the white circle) | `77f8c49` | At a full hive `HarvestFill` shows and covers the whole circle |
| 6 | Fork and icon circles looked jagged (StyleBoxFlat's 8 corner segments) | `77f8c49` | Every FloatingIcon's circle style has `corner_detail` >= 24 and anti-aliasing on |
| 7 | The centrifuge lid never lifted for the pile (the close tween killed the open one) | `d42377f`, `77f8c49` | After bottling with a pile, the lid's visual progress reaches open before the first pile cell lands, then closes |
| 8 | Spin in the zoom did nothing with a paused crank (Back mid-crank, uncap more, tap Spin) | `6131bfd` | Crank at the second stop, Back, open the zoom, tap Spin: the camera reaches the second stop and the crank resumes |
| 9 | The Shop sheet's Close sat on the Settings gear | `77f8c49` | With any sheet or panel open, `SettingsButton` is hidden |
| 10 | The gear covered the Habitat pill and stayed over Back at the second stop | `37acad8` (C7 accept) | Gear rect clears `HabitatPill` and `SkipIcon` on the farm view; hidden in both zooms (t_second_stop_back_tap covers the second half) |
| 11 | A tap on the Tools sheet's dim at the second stop counted a crank turn | `47000ad` | Already covered by `t_tools_second_stop_sheet_gearing_spigot_buy_blocks_exits_twice`; keep its mutation |
| 12 | Spin drawn smaller / bigger by view; glyph out of its circle | `d42377f`, `064b241` | Spin's drawn circle equals the fork's (88) in the farm view and the first zoom; `SpinGlyph` stays inside the circle |

## 0.3.1 test lines with no test (designer 2026-11-23: 0.3.1 closed by note, these move here)

The 0.3.1 checkpoint was green (528/528, `game/reports/_runs/20261123-224854/`), but `goal_agent.py` left 14 goals partial: the ledger shows T1.1, T2.1, T3.1, T5.1, T6.1 and T7.1 as built, yet `run_tests.gd` has 0.3.1 tests only for items 4 and 8. The designer checked items 1, 2, 3, 5, 6 and 7 by hand in the play-test. Carry those six test lines from `game/specs/0.3.1-playtest-fixes.md` into the 0.3.2 spec word for word, each test marked `# goal T<n>.1` and listed under a `# 0.3.1 item <n>` group in `run_tests.gd` (rows 2-4 and 9 above already cover part of items 3 and 7). `goal_agent.py` cannot close goals by a designer's decision: `--accept` only rewrites a ledger entry, and a goal with no tests stays partial (tooling, for a planner session).

Also for the goal loop (tooling, not tests): a test goal whose item already "has its marked test" was accepted although those tests did not check the item (T3.1, T7.1). The scan should match a test to the item's own nodes, not to any test the step's names touch.
