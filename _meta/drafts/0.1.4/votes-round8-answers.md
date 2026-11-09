# Design Votes Round 8: the designer's answers (read 2026-11-07)

Read from the Design Votes artifact's db, collection `votes`, using only the `r8-*` and `hive-frames-*` ids. The other ids are older rounds, or stale ids from the broken v11 page such as `c2-a` and `v014-0.1.4`. Page: https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (v12). Questions: `game/reports/goal/0.1.4/design-votes.md`.

| Question | Votes (note) | Decision | To do |
|---|---|---|---|
| Before/after | 0.1.3 no; 0.1.4 yes ("meter unknown if fills properly") | 0.1.4 accepted | Check that the Harvest meter fill shows (a test or a shot mid-fill) |
| C2 anchors | A −40 yes ("the best one"); B +40 no ("too low"); ref maybe ("close but not quite") | **A** | Set `harvest/spin/sell_anchor_offset` to −40 in `game_config.gd`; check that C2's tests still pass |
| C3 Back | A 96×96 maybe ("will replace with arrow in future, size to be determined later with ui mockups"); B lower no; ref yes | **Keep current** (576, 16, 120×120) | Accept the second-stop overlap for now (`goal_agent.py --accept C3 --note`); Back becomes an arrow later, sized in the UI mockups. Add that to the backlog |
| C1 count gap | A −12 maybe, B 12 maybe ("these are all the same"); ref yes | **Keep 4** | The renders differ by md5 but not visibly, so the vote mostly shows the change is too small to matter. `t_hud_no_overlap_no_cutoff` still fails on the count/Harvest pair: loosen that pair in the test, with a note quoting this vote, unless the designer says otherwise |
| pan_zoom_size | A 9.54 yes; ref maybe ("can barely tell these apart") | **9.54** | Set `pan_zoom_size` to 9.54 in `game_config.gd`; the warning should go away |
| C5 hive frames | a no ("frame model changed, frames too small"); b no ("too small but close"); c maybe ("hex are right size but again frame and hive model changed, unacceptable") | **None; redo** | Brief Milo again: keep the current hive and frame models exactly and change only the sizes. Use c's hex cell size and frames bigger than b's. Render, then add a new section to Design Votes (`compare_page.py add`) |

Then: write C5's answer into spec item 5 and rerun `goal_agent.py 0.1.4-ui-placement.md` in the background (C8, C5, test lines).
