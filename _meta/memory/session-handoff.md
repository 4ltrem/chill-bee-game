---
name: session-handoff
description: "Where work stands (2026-11-23 late): 0.3.1 built, play-tested and fixed (build exe local, not tagged); 0.3.2 test list drafted; decisions of 11/23 not logged yet; A7 + final due 11/29; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 385322cc-1787-4260-a67d-1d43a99c3e18
  modified: 2026-11-24T04:09:55.377Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**State (2026-11-23 late, `main` at the handoff commit after `b40c9d8`):** `v0.3.0` tagged at `830416b`, local only; ~118 commits ahead of `origin/main`. **0.3.1 is built and play-tested** (designer 11/23 late: "ok it works"), Windows build `game/builds/windows/ChillBeeGame.exe` (22:40, local only); `game/project.godot` says 0.3.1. Not yet: tag `v0.3.1`, push, itch (each a yes; itch only at a new milestone number or an assignment demo, [[itch-upload-rule]]). Uncommitted, not this session's: `GDD.md`, `STYLE_GUIDE.md`, `UI_DESIGN.md`, `MILESTONES.md`, `.gitignore` (root `*.mp4`), `content/_index.md`, proposals (course-ending, roadmap, indexes): another session's apply step; check with the designer before committing them. `_meta/agent-runs.*` stay for end-of-day.

**NEXT:**
1. **End of day** (`end-of-day` skill): log the 11/23 decisions, next ID **D284**. Sessions `5c77a6f2`, the 11/23 item 6-Back/8 session, maigd-a6 (L53/L54 tooling, item 7 ModalPanel, Oscar retired L55, roadmap Q3/Q5) and `385322cc` (this one). This session's decisions: build 0.3.1; Spin like the fork (88 drawn, 120 button, in every view); icon overlap judged on drawn circles, not touch rects; UI vote shots with `ui_bounds=true` ([[ui-vote-shots]]); Design Votes spin-farm (no sideways shift) and spin-farm-height A (`spin_farm_offset_y` 30, version 29 of the page); the hanging hint walk test set aside for 0.3.2; fix the 3 failing hint tests before play-testing; play-test fixes (Settings panel script, tabs fit their words, Coming soon in ink, fork fill at full + smooth circles, lid lifts for the pile, gear hides under sheets, Spin in the zoom resumes a paused crank); all those become 0.3.2 tests.
2. **0.3.1 wrap-up:** checkpoint green 11/23 (528/528, `_runs/20261123-224854`); goal_agent left 14/18 partial (no tests for items 1, 2, 3, 5, 6, 7); designer closed 0.3.1 by note (blackboard `result: closed-by-designer`), the six test lines moved to the 0.3.2 draft. Log this as a decision at end-of-day. Tag `v0.3.1` / push: asked the designer 11/23, see the decision log. Play-test placeholders still to confirm: welcome/victory/Settings/hint bubble sizes and minutes to victory (Terry: 25).
3. **0.3.2 spec:** start from `_meta/drafts/0.3.2/tests-from-0.3.1-playtest.md` (12 tests the play-test showed were missing, incl. the set-aside `t_hint_steps_follow_state_in_order_twice`, which hangs after the crank; WALK markers in `test_helpers_4.gd` `_hi_walk`) plus the earlier 0.3.2 list: balance sim, mutation 25 + adversarial QA, bottom-slot switch, the canvas sticky "Need previews for the upgrade screen". Loop fix noted there: T3.1/T7.1 were accepted as "already tested" by tests that never checked them.
4. **A7 (due 11/29):** the designer records the run video. Before submitting: `python -I _tools/audit_data.py`, refresh §4.1 / §7.2 of `_meta/drafts/a7/audit.md` with the 0.3.1 run (goal ledger, agent-runs), set its frontmatter status to final, then `python -I _tools/md_to_pdf.py _meta/drafts/a7/audit.md --min-pages 20`.
5. **Final 11/29 leftovers:** UI pass (ui-screens decisions 2-4 + skin), adversarial QA, balance sim, polish.

**Budget:** week ~70% on 11/23 evening (35% gone), reset 11/28; the 5-hour window hit 96% once tonight. Heavy agents need the designer's `python -I _tools/budget_guard.py --allow-for N`.

**Lessons from this run (see [[test-speed-fixes]]):** after a hand fix, Rex runs only `start` + `unit --only <real names, grepped> --time-scale 6`; the full suite only at the checkpoint. The loop's fix round 2 went to Bob for script faults (fixed in L54, `7d78a1b`). Approving a spec changes its text: re-run `spec_factcheck.py` after setting `status: approved`. All tests run with `show_hint=false`, so bugs only seen with the hint on reach the play-test.

**Still open:** L52 check 3 (event shots, `_meta/drafts/0.3/l52-deferred-checks.md`); mutation 25 (second crank dead); [[pending-approvals]]; `proposals/design/roadmap.md` (Q3/Q5 answered, still `proposed`: rows 1-16 re-layer and Gerard's watering proposal); the side pane untested; first `/dream` pass; stale README TBD boxes (ask first). UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca; Design Votes https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (version 29).

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); stage by glob (the hook matches script names in `git add`); don't kill the designer's running game; questions in AskUserQuestion ([[ask-with-quiz-tool]]); [[one-folder-rule]], [[spec-consistency]], [[test-speed-fixes]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]], [[french-house-style]], [[ui-vote-shots]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
