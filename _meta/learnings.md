# Learnings

Everything that broke in the workspace or the design loop, how it was noticed, why, how it was fixed, and what now stops it repeating (D92). One entry per break; new entries take the next number at the top. Add an entry whenever a fix lands for something that broke; the end-of-day skill checks the day's decisions for one. Decision IDs point to `_meta/sessions/*/decisions.md`.

Format: **What broke** · **How noticed** · **Cause** · **How fixed** · **Prevention** (the check, test or rule that now catches it).

## L57 · 2026-11-24 · C7 was committed green past the spec's vote STOP
- **What broke:** 0.3.2 item 7 says "**Stop:** the designer's pick" (Milo's two variants per upgrade on Design Votes) before the build. goal_agent briefed Bob and Patricia anyway and committed C7 green (`b0f3a7d`) with empty `PreviewTile`s. Bob refused to invent models and asked whether the vote should run first.
- **How noticed:** the main session read the C7 step on the blackboard after the run stopped on C9.
- **Cause:** not traced yet. goal_agent stops on a `(designer)` row with no visual value and on a fix round's unvoted visual number, but it seems to read no "**Stop:**" sentence in a spec item.
- **How fixed:** open. The designer chose Milo's vote next (11/24); the pick fills the tiles.
- **Prevention:** open: a planner job for goal_agent to stop before a change whose spec text holds a designer **Stop:**, with a test on the fixture.

## L56 · 2026-11-23 · The 0.3.2 run crashed on a change with no agent to brief
- **What broke:** the 0.3.2 build finished C2 (`6d9704d`) and then crashed at C3 ("The 0.3.1 test lines that never got a test") with `ValueError: max_workers must be greater than 0` (`c17fcfe`).
- **How noticed:** the background run exited 1; the traceback was in `game/reports/goal/0.3.2/run.log`.
- **Cause:** C3 has no code owner and no existing test reading its names, so `briefs()` returned `{}`, and `call_agents()` opened a `ThreadPoolExecutor` with zero workers. Had it not crashed, the "nothing moved" rule would have held C3 for the designer, which would have blocked its six T3.x test lines.
- **How fixed:** in `step()`, an empty plan records the change as built (checkpoint and ledger) and says so on the board. Its test lines then build it.
- **Prevention:** `test_goal_agent.py` `test_a_change_with_no_agent_to_brief_is_built_not_crashed` (fails with the ValueError without the fix).

## L55 · 2026-11-23 · Oscar stopped at the first real task in every session that ran him
- **What broke:** each 11/21 session that ran Oscar (`claude --agent operator`) stopped at its first real task: `cf1cdb1b` ("Opus session only: these change loop scripts"), `e8567c58` (the merge was synthesis), `f5b02912` (a designer stop, then about 8 stop-hook turns).
- **How noticed:** the designer kept switching from the operator session to an Opus one.
- **Cause:** `operator/escalate.md` hands loop changes, synthesis and trade-offs to Opus, which is most of the designer's work, and each hand-off meant a new session. The cost Oscar was built against (cache re-reads of a growing context) comes from session length, not from the model running the flow.
- **How fixed:** Oscar retired (`.claude/agents/operator.md` deleted, roster row gone, `operator/` kept as history). The Opus main session keeps its own flow: a Session flow section in `AGENTS.md`, the `/next` skill to pick one job per session, and `_tools/context_guard.py` (PostToolUse + UserPromptSubmit), which tells the session to rewrite the handoff and ask for /clear at 50% and 75% of the window.
- **Prevention:** `test_generate.py` `test_context_guard_warns_once_per_threshold` and `test_settings_wire_the_context_guard`; `consistency.py` (no roster row without a definition, no definition without a route).

## L54 · 2026-11-23 · Fix round 2 went to the owner who couldn't fix it, and the shots never left the welcome
- **What broke:** (1) 0.3.1 C7 and C8 stopped for the designer after fix round 2. Round 2 went to Bob and Quinn, who both changed nothing and named Patricia's one-line fix (C7: the Settings button left visible at the second stop, `main.gd`; C8: a typed-array ternary, `shop_ui.gd:372`). (2) `ui_shots.py` stopped at the 0.3 welcome overlay: moments 1-2 shot the welcome and 3-9 were missing, so the goal loop's `ui shots` check compared welcome screens.
- **How noticed:** the other session running the 0.3.1 build, after accepting C7 by hand (37acad8).
- **Cause:** (1) `one_owner()` routed a round both code owners could take by the folders the failure report named, else alternately (even rounds to Bob). A test failure names no folder, and nothing read the replies, and the run allowed no round after the one that found the cause. (2) Since 0.3 the shipped config sets `show_welcome = true`; `ui_compare_shots.gd` loads the shipped defaults and no moment presses Play.
- **How fixed:** (1) `named_owner()` reads the last round's replies (`OWNER_FAULT`: "Patricia's folder", "(Patricia, `main.gd`)", "next round, in `game/scripts/...`"), and `one_owner()` follows it first. `passed_on()`: when a round's code owner changed no file in their folder and the replies name the other owner, the step gets one extra round, which goes there. (2) `ui_shots.py` adds `--set show_welcome=false` unless the caller sets that key.
- **Prevention:** `test_goal_agent.py` `FixRouting` (C7's actual replies) and `test_generate.py` `test_ui_shots_skip_the_welcome_unless_asked`.

## L53 · 2026-11-23 · 0.3.1 goal steps took 30-60 min, about 10% of it agent work
- **What broke:** each 0.3.1 step took 30-60 min of wall time (C4 59 min, C3 41, C6 36, C8 30), of which the agent calls took 2.5-5 min. The first big calls were mostly searching: Patricia's C4 was 1.8M tokens and 58 turns, much of it `signal |^func |^var` greps; Bob read `main.tscn` 13 times in C6.
- **How noticed:** the designer ("the last few goal runs are too slow ... some of the things left to add are already existing systems"); the blackboard timestamps against `game/reports/_runs/20261123-*` and the transcripts' tool calls.
- **Cause:** (1) C4's duplicate `at_second_stop()` left `main.gd` unparsable, and every suite still ran to its timeout (13:23-13:53, one round). (2) A change to `main.gd` widens the impact list to every unit test (223 run for 13-57 own) plus the windowed suites, about 9 min a round, for two or three rounds per step. (3) Briefs gave no API map, so each agent rediscovered the scripts. (4) A second node named `HintLabel` silently retargeted three tests' `find_child` (C4 fix 2). (5) "Is a panel open?" lives in four places that disagree.
- **How fixed:** (1) `godot_run.py` runs `start` first, and a `Parse Error` / `Failed to load script` there SKIPS the other suites. (2) goal_agent's `own_first()` / `run_tests_first_then_rest()`: a round runs the own, written and last-failed tests alone first, and the widened list and windowed suites only once those pass (when splitting saves at least `FIRST_MIN_SAVED` tests). (3) `_tools/code_map.py` (each script's signals, public functions, config read, nodes found or created, tr() keys, and the node paths); goal_agent pastes the slice for the goal's names into each build brief (`code_help()`), with a pointer to `game/RECIPES.md` (panel, corner icon, translated label, config value, Dev button, toast, tests). (4) `contract_check.py` `check_duplicates()`: a name searched from above two nodes that carry it (a script's own subtree, its parent, or the whole scene from tests' `m.` / `main.`) fails, with `KNOWN_DUPLICATES` for named exceptions. (5) 0.3.1 item 7 now builds a `ModalPanel` base and `main.any_panel_open()` (designer; `_meta/drafts/0.3.1/shared-panel-check.md`). `spec_factcheck.py` keeps the verdicts of unchanged sentences, so a spec edited mid-build sends only its new sentences to Doris (4 of 55 for item 7).
- **Prevention:** `test_generate.py` (`test_start_runs_first_and_a_parse_error_skips_the_rest`, `test_contract_flags_a_name_two_nodes_share_under_one_search`) and `test_goal_agent.py` (`OwnTestsFirst`, `test_a_reworded_spec_rechecks_only_its_new_claims`).

## L52 · 2026-11-22 · 0.3.0 shipped green with four things the play-test found
- **What broke:** (1) the Habitat pill's + slid in the spin view; (2) the thriving toast played under the full-height Shop and vanished unread; (3) the approved "A new wildflower patch is blooming!" toast never showed; (4) the Journal opened only from inside the Shop.
- **How noticed:** the designer's play-test of 0.3.0 ("the + button moves in the zoom spin view", "a message ... vanished before I could read it"); (3) and the cause of (1) found while reading the code for it.
- **Cause:** (1) the spec stated old behaviour wrongly ("Farm view only, like the rest of the info row"), but `TopInfo` stays at the second stop and shrinks (`fit_top_info`, 0.1.3c); nobody checked the claim, and the 0.3.1 draft repeated it. (2) item 3 changed the Shop to full-height after item 4's toast was written; no check paired them, and the test only asserted `visible`. (3) `patch_slots.gd` emits `toast_requested` and nothing connects it; `contract_check.py` checked node lookups only, and item 3's test line didn't name the toast. (4) 0.2's "a Journal button in the shop panel" carried over unasked; Quinn's reply said "I assumed `JournalButton` still sits in the shop sheet", and nothing surfaced it.
- **How fixed:** `game/specs/0.3.1-playtest-fixes.md` items 1-3 (designer quiz 2026-11-22), with the pill claim corrected.
- **Prevention:** `contract_check.py` fails an emitted signal nothing connects (tests count; `KNOWN_UNHEARD` holds 0.3.1 item 2's until it lands, `HOOKS` the six checked harmless ones). `spec_lint.py` REVIEW (cover) pairs an item covering the screen with an item showing something timed, unless that item says it waits or draws on top (it pairs 0.3 items 3 and 4). goal_agent's `INTERACTION_CHECKLIST` asks for "seen, not just visible" tests. 2026-11-23: `spec_factcheck.py` pulls a spec's claims about existing behaviour (it finds 0.3 item 2's) and has Doris (read-only, Sonnet rather than the brief's Haiku: checking statements against code is her role) mark each TRUE / UNTRUE / UNCLEAR / NEW into `game/reports/goal/<version>/factcheck.md`; goal_agent refuses a build run unless that report matches the spec's text and every row is TRUE or NEW. goal_agent now keeps every reply of a step, first round included (Quinn's 0.3 C4 line came in a first round, where `(designer)` rows were never read either), and an "I assumed" line stops the run after the green commit. Still waiting ([brief](drafts/0.3/l52-deferred-checks.md)): `ui_shots.py` shots 1 s after each event (the `.gd` side is Quinn's).

## L51 · 2026-11-22 · 0.3's T6.1 took 0.2's Auto-Sell tests as its own
- **What broke:** the 0.3 step for T6.1 (skip-icon tests) skipped Quinn ("every line already has its marked test") and listed four `t_autosell_*` tests, then held the goal as unchanged.
- **How noticed:** the blackboard's step line named Auto-Sell tests for a skip-icon goal.
- **Cause:** goal ids repeat across specs (0.2 item 6 was Auto-Sell, with tests marked `# goal T6.1`), and `marked_tests()` matched marks by id alone.
- **How fixed / prevention:** marks may name a version (`# goal 0.3 T6.1`). `marked_tests(id, version)` prefers this spec's versioned marks, and the scan's mark regex skips the version token. Quinn's 0.3 item 6 tests use the versioned mark. Briefs should ask for versioned marks from now on.

## L50 · 2026-11-22 · Re-run steps failed on "no mutations to run"
- **What broke:** T2.1, then T1.1/T1.2, stopped after 2 fix rounds each with green tests and `mutate: no mutations to run`.
- **How noticed:** the blackboard's mutation check, repeated across fix rounds.
- **Cause:** the step's check runs `mutate.py --since <step base>`. The goal's mutations had been committed before that base: by the orchestrator's mid-step checkpoint (`ff4abe5`), or by an earlier step of the same goal. So nothing counted as new.
- **How fixed / prevention:** `goal_agent.item_mutations()` (the other session, maigd-6a) runs the mutations named "<version> item <n> ..." for the batch's items when `--since` finds none. `goal_agent.mutated_tests()` passes the check when every own test is already named by a mutation. No checkpoints mid-step. Tests: `test_item_mutations_fallback`, the `mutated_tests` assert (73/73).

## L49 · 2026-11-22 · goal_agent stopped on a "question" that said there was none
- **What broke:** the 0.3 run stopped `waiting-designer` on T1.1/T1.2 with the "question" "I found no game bug and no open spec question, so nothing is marked `(designer)`." (Quinn), before his fix (`Flow.no_welcome` in `ui_bounds_pixels.gd`) was ever run.
- **How noticed:** the blackboard's question table.
- **Cause:** the fix-round check took any reply line containing `(designer)` as a designer row, including a line that only mentions the tag in backticks.
- **How fixed / prevention:** `goal_agent.DESIGNER_ROW` matches `(designer)` only when it is not wrapped in backticks. Test: the `DESIGNER_ROW` asserts beside the L42 visual-row checks in `test_goal_agent.py`.

## L48 · 2026-11-22 · goal_agent stopped twice on code that was fine: Godot's class cache was stale
- **What broke:** the 0.3 run stopped `waiting-designer` on C1 and again on C3 after 2 fix rounds each: "Could not find type WelcomeOverlay" (then "PatchSlots"), `main.gd` / `flower_patch.gd` failing to load, and `tr(welcome_play)` returning the key. The fix rounds changed code that had no bug.
- **How noticed:** the blackboard's test output; Quinn's C1 fix-round reply named the stale global class cache.
- **Cause:** a step that adds a script with a new `class_name`, or a translation CSV row, needs Godot's import and class cache rebuilt; the step's `tests` check ran `godot_run.py unit start` without `--refresh`, so Godot never saw the new class or key.
- **How fixed:** C1 accepted with no code change after Rex ran `start --refresh` and the 7 tests went green (`_runs/20261122-132648/`, `04f72f9`).
- **Prevention:** `goal_agent.checks()` runs `godot_run.py --refresh unit start ...` every step (about 30 s). Test: the `--refresh` assert in `test_the_impact_list_briefs_quinn_beside_the_build` (66/66).

## L47 · 2026-11-22 · Two goal_agent fix rounds guessed at T15.1's failures; the bugs were in the new tests
- **What broke:** item 15's run stopped `waiting-designer` with 2 of 3 new tests red after Quinn's and Patricia's fix rounds. Both replies said "I'm guessing" and ran nothing; Patricia's `back()` fix was real, the rest missed. Separately, `checkpoint.py` labelled both WIP commits "(unit green)" from the last full run while 3 tests were red.
- **How noticed:** the blackboard's fix-round replies (D259).
- **Cause:** three test bugs, none in the game: a stray `_mk_main()` left two overlapping farms (the Harvest tap missed); the zoom-end exit waited for `LOWERING`, after which a refilled frame can rise again (only `CLOSE_DELAY` means the zoom ends on its own); and the test's 120 s cap counts game time (about 20 s real at `--time-scale 6`) with 40 Capped cells left in other frames. A one-line `diag:` failure message (zoom state, hive vs honeycomb cell counts, departures) showed the last cause in one run.
- **How fixed:** `7616d20` (test_shop_zoom.gd); C15 and T15.1 accepted after a green full suite (`_runs/20261122-011146/`).
- **Prevention:** `goal_agent.DIAG_RULE` in every fix-round brief: Quinn adds a one-line `diag:` to an unexplained FAIL message instead of guessing; a code owner writes `diag needed` (now a `QUINN_FAULT` match), which sends the next round to Quinn. `checkpoint.unit_counts()` lays newer `--only` logs over the newest full log, so the label says "WIP, N unit fails" while any test is red. Tests: `test_checkpoint_label_counts_newer_only_runs`, the diag asserts in `test_a_code_owner_blaming_the_test_sends_the_next_round_to_quinn` (66/66).

## L46 · 2026-11-22 · README.md fell 12 days behind and no check saw it
- **What broke:** README.md's Repository Contents had not changed since 2026-11-10: it lacked STYLE_GUIDE.md, STYLE_LOOP.md (the A6 write-up), GOAL_AGENT.md (the A5 write-up), UI_DESIGN.md, research/, operator/, _tools/, _templates/, _meta/learnings.md and CONTEXT.md as a row, still said `.claude/agents/` "starting with Connie" and the timeline had "no fixed date". AGENTS.md's map lacked CREW.md, GOAL_AGENT.md and ONBOARDING.md.
- **How noticed:** the designer, after the A6 push: "the readme is outdated, why didn't the gate catch that".
- **Cause:** every layer checks that what a doc says is true, none that it says enough. `consistency.py` checks scripted facts, `links.py` that links resolve, and Doris only statements the day's diff made untrue; an untouched README with missing rows contradicts nothing.
- **How fixed:** README and AGENTS.md maps completed; the two stale lines fixed.
- **Prevention:** `consistency.py` `check_readme_map()` (in the pre-commit gate): every top-level tracked file and folder needs a row in README.md's Repository Contents and AGENTS.md's Where things live, with `README_EXEMPT` for deliberate omissions; tests `test_a_top_level_file_missing_from_the_readme_map_fails` and the real-repo check (93/93). Doris's brief gains a coverage pass: each added, renamed or removed file must appear in the map that should list it (`_tools/CONTEXT.md`, AGENTS.md, the owning CONTEXT.md). Still open: the README's Outstanding TBDs list is not checked against the GDD.

## L45 · 2026-11-21 · Removing a worktree emptied the repo's Godot folder through a junction
- **What broke:** at 23:19 Oscar's branch cleanup ran `git worktree remove --force .claude/worktrees/m02-play` (designer's yes). The worktree held a junction `Godot_v4.2.1-stable_win64.exe` pointing at the repo root's Godot folder, made on 2026-11-20 so the worktree could run tests without a copy. The forced remove deleted through it, leaving the root folder empty; every Godot run then failed with `FileNotFoundError`.
- **How noticed:** Rex's `ui_shots.py` check after the naming restructure; the folder's mtime (23:19:22) matched the cleanup command in the session transcript (23:19:07).
- **Cause:** a recursive delete on Windows follows a directory junction into its target; nothing checked a folder for links before deleting it, and the junction was not recorded anywhere.
- **How fixed:** the designer re-unpacked Godot 4.2.1 (2026-11-22); Rex: `start --refresh`, then `ui_shots.py 0.2.1=.` wrote 12 shots to `builds/0.2.1/ui/`.
- **Prevention:** `guard_shell.py` rule 8 (link-delete) refuses `git worktree remove`, `rm -r`, `Remove-Item -Recurse` and `rmdir /s` on a folder that holds a junction or symlink, naming each link and the `cmd //c rmdir LINK` that removes the link alone. Test: `test_guard_shell_refuses_deleting_a_folder_that_holds_a_junction` (makes a real junction; 92/92). A worktree should find Godot through `godot_path.py` (`GODOT` env var) rather than a junction.

## L44 · 2026-11-21 · After an `--only` step the scan read an older full unit log and held a green goal
- **What broke:** T9.1's step passed on its own tests (21:47-21:55), but the next scan pass read the 21:08 full `unit.log`, where T9.1 still failed. It marked T9.1 "partial AMBIGUOUS", made no goal commit and skipped the end-of-run suite (obstacles item 23).
- **How noticed:** Oscar, reading the run's board after the stop.
- **Cause:** `scan()` took results only from the newest full unit log; L42 made steps run `--only`, so a step's own results were never in a full log until the run's end.
- **How fixed (2026-11-21, Opus session):** `goal_agent.unit_results()`: the newest full log, then every newer `--only` log laid over it, so each test has its newest result; older partial logs are not read.
- **Prevention:** `test_goal_agent.py` `test_the_scan_takes_each_tests_newest_result_across_only_logs` (64/64). Still open from item 23: the plan count no longer lists C14 (`--accept`ed), CFG or T.1.

## L43 · 2026-11-20 · The style loop's refiner broke more than it fixed: truck motion and size, jars, the Spin icon
- **What broke:** in the first 0.2 style runs (`game/reports/style/0.2.0-farm/run-1`, `run-2`), Bob, fixing Vera's rows, shrank and moved the truck (0.93 to 0.7) and gave it a diagonal exit, enlarged the 7 crate jars until they overhung the crate, and moved the Spin icon. All of it was in `game/scenes/main.tscn` and two materials of the live game.
- **How noticed:** the designer, watching the renders ("Bob is breaking more than he's fixing"); then the unit suite caught the truck off its cell and the overhanging jars.
- **Cause:** the loop let Bob edit the live game with no check between rounds. Nothing kept motion, the size and place of props the designer had picked, or the UI (not Bob's folder) out of his reach, and Vera's rows invited shape and layout changes.
- **How fixed:** all of Bob's edits restored to HEAD (designer). `style_loop.py` now works on a sandbox copy (`_meta/sessions/runs/style-<slug>-run-N-sandbox/`) and ends with `sandbox.patch` for the designer. After each Bob turn, `guard_motion` puts back motion, picked-prop size and place, added parts on picked props and any UI change, and the unit suite runs on the copy, compared with a baseline run (a turn that fails is undone). UI rows go to Patricia (`UI_FIXER`).
- **Prevention:** `test_generate.py` StyleLoop cases (sandbox, guard, gate and undo; 79/79 when built, 91/91 now). The A6 demo run `0.2.0-farm/run-5` passed every gate and changed nothing in the game. Still open: the gate undoes a turn on a flaky timing test too (STYLE_LOOP.md, "limits").

## L42 · 2026-11-21 · Each goal step still ran the full unit suite; T9.1's fix rounds were misrouted and its stop was a false vote
- **What broke:** (a) after L40/L41 every step still ran one full unit run (~220 tests, up to 27 min) as its gate, most of the 0.2.1 build's wall time (`game/reports/_runs/20261121-*`); T9.1's first check also ran all 206 tests, because its `# goal T9.1` mark sat above two `##` doc lines and `marked_tests()` found no own test. (b) T9.1's two fix rounds went to Patricia, though the only failing test was in Quinn's new `tests/test_zoom_end.gd` and she said so both times. (c) Fix round 2 then stopped as a Design Votes visual row on "A: keep the paused crank; B: reset the crank", a behaviour question with no visual number (`game/reports/goal/0.2/blackboard.md`, step T9.1 at 21:06).
- **How noticed:** the designer: "these test runs take a long time and is dragging down dev time, we don't need to test things we know work already, or won't be affected by a change"; the T9.1 board.
- **Cause:** (a) L40 narrowed the rounds but kept a full unit gate per step, and the mark regex allowed no line between mark and `func`. (b) `fix_briefs()` sends a test goal's failures to the code owners only; nothing read the failing test's origin or the replies. (c) every `(designer)` reply row counted as a visual vote.
- **How fixed (2026-11-21, Opus session):** `goal_agent.py`: (a) `change_impact()` maps the files the step changed (`step_changes()` against a start snapshot, `git diff -U0`) to the unit tests that read them, from a test index cached in `game/reports/_runs/test-map.json` (`test_index()`: each test function's identifiers and calls; a helper's reads reach its callers): a script's changed members, their in-file callers and the names on its changed lines reach tests through helpers; its stem, class, scene nodes and the state its changed functions read count only in a test's own body (every setup helper reads `Hive`); core files (`CORE_FILES`: main.gd, game_config.gd, default_config.tres, main.tscn, project.godot) count only their changed names; a file no test reads is widened to every name it defines, else listed uncovered; a change under `game/tests/` runs only the changed tests and the callers of a changed helper (a changed windowed suite file runs that suite). A round runs own + impacted + last failures, and the board logs each group and why (`tests_line()`); with none, `unit` is skipped. The per-step full unit gate is gone: `final_suite()` runs `all --time-scale 6 --skip-x1` once at the run's end (also after a `--goal`/`--max-goals` stop that built something), reusing a green `all` run newer than every build change (`fresh_green_full()`). `marked_tests()` and `scan()` read a mark past `#`/`##` lines. `--changed` prints the impact of the uncommitted files. (b) `quinn_round()`: when only `tests` fail, the next round goes to Quinn alone if a code owner's reply puts the fault in tests/ (`QUINN_FAULT`), or, on a test goal, every failing test is one the step wrote (not twice running). (c) a `(designer)` row is a vote only if it names a size, scale, offset, position, font, margin or colour (`VISUAL_ROW`); any other stops as a plain designer question.
- **Prevention:** `test_goal_agent.py` 63/63 (6 new, 5 updated): the impact per file kind, cache reuse and re-read, the `--only` list with its logged reasons, no step gate and the end-of-run reuse, Quinn first for a written test and after a blame, the behaviour row. On the current uncommitted tree `--changed` gives 98 of ~220 tests. Still open: no real Godot run of the new gate yet; the map is static (a test reaching a changed script only through `main.gd` behaviour it never names is caught by the end-of-run suite, not the step).

## L41 · 2026-11-21 · The full unit gate timed out, and each TIMEOUT started a fix round
- **What broke:** T10.1's L40 gate (`godot_run.py unit --time-scale 6 --skip-x1`) stopped at exactly 15m00s twice, `TIMEOUT unit no total line`, with every test it reached green (198 passed, 0 failed: `game/reports/_runs/20261121-195200/unit.log`, `-200958/unit.log`). Two fix rounds were spent on code that had no bug.
- **How noticed:** the operator's T10.1 run board.
- **Cause:** `godot_run.py` gave every suite a flat 900 s; the unit suite grew to 218 tests (T10-T14, some ~35 s such as `t_spigot_bottling_time_by_level`), past the 9m46s-12m30s it used to take. `goal_agent.py` treated a TIMEOUT like a FAIL. The step's `tests` check also set x6 only through `ENV`, not the flags.
- **How fixed (2026-11-21, Opus session):** `godot_run.py` `suite_timeout()`: unit gets 300 s + 6 s per test it will start (`unit_test_count()`: the CB_ONLY list or every `func t_` in `tests/test_*.gd`), at least 900 s, hard cap `UNIT_CAP_S` = 1800 s (218 tests: 1608 s, 26.8 min); other suites keep 900 s; `--timeout` overrides. `goal_agent.py` `run_tests_once_more()`: a test command that times out with no FAIL line (`timed_out()`) is rerun once; timed out again, the step (or `final_suite()`) pauses with the reason on the board, and no fix round starts. The step's `tests` check now carries `--time-scale 6 --skip-x1`; the x1 bug check keeps `CB_TIME_SCALE=1` on purpose.
- **Prevention:** `test_goal_agent.py` 57/57 (5 new): retry then pause, retry then green, the gate's pause, a TIMEOUT with a FAIL line still a fix round, the count-based timeout with its floor, cap and override. Still open: no real Godot run of the new timeout yet.

## L40 · 2026-11-21 · The goal gate ran the full unit suite every round
- **What broke:** T12.1 took 46 min of wall time for about 2 min of agent time; T13.1 took 17.5 min for 95 s. Two flaky timing tests (`t_camera_pan_seconds`, `t_barrel_eases_to_stop`) cost T11.1 two fix rounds, and run 0.2 ended `failed` on one ENOTFOUND network error (`240952d`).
- **How noticed:** the operator's 0.2.1 session (`_meta/drafts/operator/obstacles-2026-11-21.md` items 11 and 18).
- **Cause:** each round's `tests` check ran `godot_run.py unit start`, all ~200 tests (~12.5 min at x6): T12.1 ran it three times (`_runs/20261121-125612`, `-130850`, `-132430`). L39's windowing only added suites to a change's check; it never narrowed `unit`, and test goals had none. Any red test, flaky or not, started a fix round; any agent error crashed the run.
- **How fixed (2026-11-21, Opus session, the designer: "implement the faster tests"):** `goal_agent.py` `step()` runs `--only` the goal's own tests (`own_tests()`: a test goal's marked tests; a change's item tests and unit impact list) plus the last check's failures; once a round is green, the full unit run is the gate, once, before the checkpoint, or is reused when the newest full log is green and began after every build-file change (`fresh_green_unit()`). A failing test that is not the goal's own is rerun alone once (`rerun_flaky()`): passing, it is logged `Flaky:` and gets no fix round. `agent_once_more()` retries a transient API or network error once, then the run pauses. Also: `--goal` takes a list and skips done goals (exit 0), a fix round changing a visual number stops for a vote (item 12), `godot_run.py --set` (item 7).
- **Prevention:** `test_goal_agent.py` 52/52 (9 new): the `--only` lists per round and one gate run, the reuse and its two refusals, the flaky rerun, the network retry and pause. Still open: no real Godot run of the new gate yet; `run_tests.gd` and the windowed suites do not yet read `--set` overrides (a Patricia/Quinn change in `game/tests/`).

## L39 · 2026-11-21 · Tests break whenever a feature changes or is added
- **What broke:** 0.2.1 item 9 (Spin alone pans to the second stop, C9) left about 9 unit tests red, plus `t_replay_fill_and_back`; item 14 (the shop layout, C14) turned 6-11 red. The play suite had been red since 0.1.4 (54 failures) unseen; `play_loop.gd` was last green at 0.1.2. Most were stale tests, not game bugs.
- **How noticed:** only when the full suite ran (`all --time-scale 6 --skip-x1`). `goal_agent.py`'s check runs the unit suite only, so play, measure and snapshot drifted unseen for two versions.
- **Cause:** many tests copy the flow inline instead of sharing it (the old full-bucket pan, "Spin starts the crank", the shop panel always visible, cell indexes such as cell 17), so one behaviour change breaks every copy, each needing its own fix. Tests also hard-coded the window size, which the laptop screen clamped to 1175 px.
- **How fixed:** the stale tests were updated one by one in the 0.2.1 fix rounds (`game/reports/goal/0.2/briefs/C9-fix*`, `C12-fix1-*`).
- **Prevention (2026-11-21, Opus session, the designer: "fix it"):** (b) `goal_agent.py` `test_impact()` greps `game/tests/` for each change's nodes, keys, backticked code names and two-word phrases of its text (`second_stop`, `ShopPanel`), and briefs Quinn in parallel with Patricia and Bob to update the tests the spec makes stale; `--impact GOAL` prints the list (on the 0.2 spec, C9's list names the tests that went red). (c) The windowed suites on that list (play, measure, snapshot, ui, touch) run with `unit` in the step's check, and a finished run runs the full suite (`final_suite()`): red gets one Quinn round, then a designer stop. (a) and (d) are rules in Quinn's briefs (`TEST_RULES`) and `qa-build-engineer.md`: one shared helper per flow step (`tests/flow.gd` for the windowed suites), no literal cell index or screen size. Tests: `test_goal_agent.py` 41/41 (4 new). Still open: moving the existing copied flows onto helpers (Quinn applies the rule to each old test he touches; a one-off pass is [future-tbd](memory/future-tbd.md) item 12), and no script check for (d).

## L38 · 2026-11-20 · The style loop's first render failed on the laptop: no Godot import cache
- **What broke:** `style_loop.py farm-0-2-0` failed in round 1 (`Identifier "GameConfig" not declared`); two `godot_run.py` runs 4 s apart failed too (`test_journal.gd` unresolved, no journal `.translation`).
- **How noticed:** the loop's console and Rex's reports.
- **Cause:** `game/.godot/` did not exist after the 0.2 merge, and `godot_run.py`'s `refresh()` (`--quit-after 1500`) is too short to build the class cache and imports; `style_loop.py` has no refresh at all.
- **How fixed:** Patricia ran one `--headless --editor --path game --quit-after 3000` pass (no tracked file changed); the unit test then passed.
- **Prevention:** none yet (Still open): `refresh()` with a longer quit, or a full import when `.godot/` is missing, also called by `style_loop.py` before its first render.

## L37 · 2026-11-17 · No test or build could run on the laptop: Godot's path was the desktop's
- **What broke:** `godot_run.py`, `build.py` and the other scripts, Bob's render command and the settings rules all named `C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe`, which exists only on the desktop.
- **How noticed:** the laptop handoff (D220, Still open) and the designer: "make it computer agnostic".
- **Cause:** the path was written by hand into each tool when there was one machine.
- **How fixed:** `_tools/godot_path.py` (the `GODOT` env var, then the repo-folder copy, then the desktop path); everything calls it (`8011388`, D225).
- **Prevention:** no tracked file names a machine's Godot path; not yet checked by script, and the branch is unmerged (Still open).

## L36 · 2026-11-17 · Allow rules with `VAR=*` prefixes warned that they allow any command
- **What broke:** the Claude Code console warned that each rule like `Bash(CB_TIME_SCALE=* python -I _tools/godot_run.py *)` "allows any command at the * in its value".
- **How noticed:** the warnings on the laptop's console (D223).
- **Cause:** test speed settings were passed as shell env prefixes (L17), so the allow rules had to wildcard the value.
- **How fixed:** CLI flags `--only`, `--time-scale`, `--skip-x1` in `godot_run.py`; the `VAR=` rules removed (`51b775d`).
- **Prevention:** the memory rule "never VAR= prefixes"; the branch is unmerged (Still open).

## L35 · 2026-11-10 · `mutate.py` crashed on the Journal mutations
- **What broke:** `mutate.py --since 48afcd8` crashed at mutation 48/49 (FileNotFoundError on `game/../_tools/journal_csv.py`) twice, and mutation 45 "French title left empty" came back BROKEN.
- **How noticed:** Rex's rerun reports (2026-11-09 and 2026-11-10).
- **Cause:** `mutate.py` copied only `game/` to its temp folder, but `test_journal.gd` runs `../_tools/journal_csv.py`, which reads `content/bee-journal-real.md`, and mutation 48 edits that script itself.
- **How fixed:** `mutate.py` also copies `_tools/` and `content/` beside the copied `game/`. Rex's check: 48 and 45 CAUGHT, baseline 0 failing.
- **Prevention:** the copy in `mutate.py` (with a comment naming the test). Open: no unit test in `test_generate.py` checks the siblings are copied; mutation 25 (second crank dead) is still MISSED, a test gap for Quinn.

## L34 · 2026-11-09 · `--plan` said 21/21 done after Quinn wrote only the shop tests
- **What broke:** after T1.1 (7 shop tests) the plan marked all 12 test lines done; the `/goal` condition would have passed with 10 lines untested.
- **How noticed:** the orchestrator compared the plan with the `# goal` marks in `game/tests/` (7 × T1.1, nothing else).
- **Cause:** T1.1 was batched with T.1 (mutations, which covers every item), so the brief's group label read "0.2 items 1, …, 8"; `scan()` read only group comments, not the marks. Also the stale 0.1 `t_cost_formula` (roundi) went to Patricia and Bob, not Quinn, because a test goal's fix rounds go to code owners.
- **How fixed:** `scan()` reads the marks; once a spec's tests carry them, a line's evidence is its own marked tests (an unrun x1 test counts only once built); the label leaves out the mutations line's items; `t_cost_formula` floored by hand, quoting item 1.
- **Prevention:** `test_goal_agent` `test_marked_tests_are_a_lines_only_evidence`. Open: a stale older test in a test goal's fix round still goes to the code owners first.

## L32 · 2026-11-09 · Recombination rounds cost a full Milo run each
- **What broke:** 0.2 models rounds 2 and 3 were mostly "take A's part, add it to B, drop C, swap a material", yet each was a Milo run (34k–112k tokens) that re-read and rewrote whole centrifuge and truck copies.
- **How noticed:** the designer asked how to cut tokens on permutation runs.
- **Cause:** the only way to change a variant was an agent writing `.tscn` text.
- **How fixed:** `_tools/compose_variant.py` (graft, drop, material, move on node paths; prunes resources, recounts `load_steps`, writes only a new round file); Milo's parts convention (one named group per feature).
- **Prevention:** `game/scenes/variants/CONTEXT.md` Process: a round that only recombines seen parts is a recipe, not a Milo run; tested by an exact round-trip of three variants and a byte-identical rebuild of Milo's `truck-flames-r3-l4`.

## L31 · 2026-11-09 · A Milo round came back with parts not touching
- **What broke:** all four `fork-r1` forks had the handle beside the head, not on it; `truck-flames-r1` a, b, e failed V6 (0.02 decals).
- **How noticed:** the orchestrator looked at the shots before publishing ([[look-before-done]]); style_check caught the decals.
- **Cause:** each part was tilted on its own, so their ends drifted apart; the brief allowed decals thinner than V6.
- **How fixed:** Milo rebuilt the fork upright inside one tilted `Pose` node; the decals went to 0.05.
- **Prevention:** the parts convention in `.claude/agents/modeler.md`: a tilt or pose lives on one parent node, parts are built untilted; briefs never relax a V rule.

## L33 · 2026-11-09 · Bob's 0.2 C3 fork step rebuilt the honey cell and broke two frame tests
- **What broke:** in C3 (Heated Fork) Bob built the truck groups too, ran 47 turns / 1.09M tokens, then swapped `hex_cell_mesh.gd` for a CylinderMesh in a fix round; `t_raised_frame_cells_aligned` and `t_hive_frames_cells_aligned` failed and the run stopped.
- **How noticed:** the designer read the blackboard ("bob's prompt slice is too vast?"); the orchestrator diffed the fix-round edits.
- **Cause:** `item_numbers` read "Items 3–5" as item 3 and dropped the indented sub-bullets; fix briefs carried every open style row of the whole game (an old V4 row on `honey_cell.tscn`, truck, zoom, jars); build calls had no turn cap; V4 flagged the deliberate 0.1.4 scripted hex mesh.
- **How fixed:** ranges and sub-bullets go to their item (`parse_contract` "sub"); `rows_in_scope` keeps only style rows about files the step changed (none left = style PASS); `BUILD_MAX_TURNS` 30; `style_check.py` `PROCEDURAL_PRIMITIVES`; the honey cell and glass edits reverted, C3 accepted by hand.
- **Prevention:** `test_goal_agent`: item ranges and sub-bullets, style rows in scope, build-call cap.

## L30 · 2026-11-09 · The `/goal` stop hook kept firing after the designer said "stop"
- **What broke:** the designer stopped the UI work mid-turn; the goal judge re-sent "condition not met" six times while the session stayed paused.
- **How noticed:** six identical hook messages in a row.
- **Cause:** the `/goal` condition ("design created for the UI…") was still false, and the hook has no notion of a stop request.
- **How fixed:** the session kept honouring the stop and pointed to `/goal clear`; the designer then set a new direction.
- **Prevention:** when the designer says stop under an active `/goal`, say once that the hook will loop until `/goal clear` or "continue", then answer each hook message in one line (L23 is the same family: conditions holding human steps).

## L29 · 2026-11-09 · Icon geometry took many rounds when described in words
- **What broke:** the Royal Jelly icon went through drop → dipper → dipper rotated → rotated 180° → nine variants → G+H mixes before it settled; the designer also named "H" when meaning "K" once.
- **How noticed:** the designer's comments on the canvas, one geometry change per round.
- **Cause:** angles, positions and "on top of" were guessed from words; each guess cost a full round.
- **How fixed:** a variants board with letters and live sliders (angle, crown drop, lift) on the candidate; the designer set the numbers by hand (K: 60°, 1.8, −2.6).
- **Prevention:** `UI_DESIGN.md` working rules: for any shape, angle, offset or size, show 3+ lettered variants and expose sliders; restate the chosen letter and values before applying it everywhere.

## L28 · 2026-11-09 · A variant's large preview ignored the sliders its pill followed
- **What broke:** on the Royal Jelly variants board, K's pill moved with the Tweaks sliders but the 120 px preview did not, though both used the same markup.
- **How noticed:** the designer: "the tweaks work to the pill but not the big icon".
- **Cause:** not confirmed; most likely the canvas dropped `{{hole}}` values interpolated inside an SVG `transform` string.
- **How fixed:** both previews now bind the whole `transform` value, computed in `renderVals()` (`kRotT`, `kCrownT`, `kLiftT`). Not yet confirmed by the designer.
- **Prevention:** `UI_DESIGN.md` canvas rule: bind whole attribute values from `renderVals()`, never interpolate inside SVG attribute strings (Still open until confirmed).

## L27 · 2026-11-09 · Publishes raced the designer's own page edits
- **What broke:** two publishes were refused and four warned that a page save had landed minutes earlier; the designer was moving sliders and nudging elements while the orchestrator edited the same files.
- **How noticed:** the Artifact tool's refusal and "saved from the artifact's page" warnings.
- **Cause:** editing local copies read several minutes earlier.
- **How fixed:** read the live file right before each edit, diff it against the local copy, re-apply the change on the live version, then publish.
- **Prevention:** `UI_DESIGN.md` canvas rule: read → edit → publish in one step per change; never resend an older copy.

## L26 · 2026-11-09 · The "12" in the Jelly pill could not be selected on the canvas
- **What broke:** the designer could not swap the number and the icon, because the "12" had no element of its own.
- **How noticed:** "can't find the element for 12".
- **Cause:** the number was a bare text node inside the button.
- **How fixed:** every variant pill puts the 12, the icon and the + in separate elements.
- **Prevention:** `UI_DESIGN.md` canvas rule: every piece of text is its own element.

## L25 · 2026-11-09 · The first UI mockups redrew the harvest loop instead of using the game's shots
- **What broke:** the first boards were drawn from scratch, including the harvest screens the game already has, with a bottom navigation bar.
- **How noticed:** the designer: "screens were being invented for the harvest loop which we already know, use the screenshots we already have and build the UI on top, icons over the screen are preferred over a navigation bar". The designer also said "stop" mid-run.
- **Cause:** the brief started from the GDD's screen list, not from what the build already shows.
- **How fixed:** the canvas was rebuilt on `game/reports/votes/spin/round-1/c/` shots with floating icons; the invented boards were deleted.
- **Prevention:** `UI_DESIGN.md` rule 1: start every UI design from the latest scripted shots (`_tools/ui_shots.py`) and draw only the new UI on top.

## L24 · 2026-11-08 · A commit to `main` from a worktree failed the hooks and the push hung
- **What broke:** the first commit on a worktree from `origin/main` ran the milestone branch's pre-commit check, which calls `contract_check.py` that `main` does not have; `git push` hung over two minutes on a hidden login prompt.
- **How noticed:** the commit was rejected and the push never returned; the designer logged in and the retry went through.
- **Cause:** the hooks path setting points at the milestone branch's hooks; Git Credential Manager prompts non-interactively.
- **How fixed:** `-c core.hooksPath=.githooks` on the commit, `GCM_INTERACTIVE=never` on the push.
- **Prevention:** `_tools/commit_main.py` (2026-11-21, queue #7), then retired the same day: milestone branches were dropped (designer, 2026-11-21), so every commit is on `main` with one gate. The push rule stays in the end-of-day skill: `env GCM_INTERACTIVE=never timeout 90 git push`.

## L23 · 2026-11-08 · `/goal finish 0.1.4` was judged unmet 16 times
- **What broke:** with the code done and green, the goal judge kept sending the session back for the designer's play-test, web check and itch upload.
- **How noticed:** the `/goal` vs `goal_agent.py` comparison (D195).
- **Cause:** a vague condition holding steps only the designer can do.
- **How fixed:** a `/goal` condition holds only what the agent can make true (written in `GOAL_AGENT.md`).
- **Prevention:** a rule in `GOAL_AGENT.md` and backlog item 8.

## L22 · 2026-11-08 · Dev mode's saved snapshot overrode new defaults
- **What broke:** the designer saw small combs in a current build ("an old version").
- **How noticed:** the designer's play-test; `dev_config.tres` held `frame_scale = 0.85` against the new 2.7.
- **Cause:** the Dev panel saved every value and laid the snapshot over the defaults on launch; tests and shots don't read it, so they looked right.
- **How fixed:** the file renamed; Dev mode saves only edited values (item 16, `b385d39`).
- **Prevention:** the Dev save test.

## L21 · 2026-11-08 · The orchestrator and Quinn ran scripts themselves
- **What broke:** the main session ran the unit suite and lid test in its own Bash, and Quinn's briefs had him run his own tests (974k tokens, 38 turns); Rex had no script for the lid shots.
- **How noticed:** the designer: "rex is supposed to run scripts".
- **Cause:** a memory-only rule the orchestrator and briefs didn't follow, and no `lid` suite.
- **How fixed:** Quinn's briefs no longer say to run tests (`b9f9347`); `godot_run.py lid` and `fixture` suites.
- **Prevention:** the brief assertion in `test_goal_agent`; for every session and agent, `guard_shell.py` rule 7 (2026-11-21, queue #6): the Godot test, build, mutation and shot scripts are refused in any shell but Rex's (`agent_type` script-runner), checked live both ways.

## L20 · 2026-11-08 · Lid vote cards with spaces, % and brackets in their IDs saved no votes
- **What broke:** the designer voted on the lid section but no votes were stored.
- **How noticed:** "read my votes" found none for the lid.
- **Cause:** card IDs like `lid-close-r1-Before 0% (open)`; the store silently rejects spaces, `%` and brackets.
- **How fixed:** `compare_page.py` turns every card ID into a safe one; the page was republished and the designer voted again.
- **Prevention:** the safe-ID conversion in `_tools/compare_page.py`.

## L19 · 2026-11-08 · The goal agent skipped real-time tests, so Quinn rewrote a test that never ran
- **What broke:** Quinn spent three rounds (about 800k tokens) on T14.5, which was red from the start.
- **How noticed:** the designer: "800k wasted".
- **Cause:** the goal agent's routine run uses 6x speed, which skips real-time tests.
- **How fixed:** a real-time bug test also runs alone at normal speed for the fail-first check; a single-test log no longer counts as a suite run (`b4410cf`, `320fdb7`, `eb134fe`).
- **Prevention:** `test_goal_agent` cases.

## L18 · 2026-11-08 · A lid "fix" was logged as done with no code change
- **What broke:** the handoff said "lid fixed (designer confirmed)", but no lid code changed; T14.3 passed on the clipping build, and positional test IDs let the goal agent credit a new line from a passing sibling.
- **How noticed:** the designer played the exe and the lid still clipped: "a fix should always be committed".
- **Cause:** nothing checked that a "shown failing" test failed before the fix, nor that a bug fix changed code; the handoff was written from memory, not from git.
- **How fixed:** fail-first gate, code-change rule, run lock (D172); built-lines rule for positional IDs (`fcde905`); the lid test redone in `lid_shots.gd`.
- **Prevention:** the goal-agent gates and `test_goal_agent`; memory `fix-needs-commit`. Related: L1, L9.

## L17 · 2026-11-08 · Test runs at full real-time speed, one test cut off by the 15-minute cap
- **What broke:** three `godot_run.py unit start` runs took 14m52s–15m each; the third hit `godot_run`'s 15-minute timeout and never ran `t_paused_crank_never_finishes_in_farm_view` (177 of 178 reported).
- **How noticed:** Rex reported TIMEOUT; the designer asked "why does it take 15 minutes".
- **Cause:** the orchestrator briefed Rex with the plain command, without the fast settings approved on 2026-11-06 (`CB_TIME_SCALE=6 CB_SKIP_X1=1` for checkpoints, `CB_ONLY` while iterating); the suite has grown to about 15 minutes at real time.
- **How fixed:** the cut-off test re-ran alone with `CB_ONLY` (pass); the rule is now the `test-speed-fixes` memory's index line.
- **Prevention:** a memory rule only, so it can be missed again; a code guard (fast settings as `godot_run.py`'s default, plain speed opt-in) is listed under Still open.

## L16 · 2026-11-08 · A mutation passed because button placement depends on order
- **What broke:** the item 20 mutation (Harvest treats Spin as a blocker again) survived `t_harvest_holds_anchor_spin_below`.
- **How noticed:** Rex's `mutate.py` run reported MISSED.
- **Cause:** `floating_icon.gd` nudges each icon against the others' current rects, so the result depends on which icon updates first. The test placed Spin first, where the old and new rules agree; in play Harvest went first and moved up.
- **How fixed:** the test places the icons in both orders (Harvest first included).
- **Prevention:** the mutation itself: it is caught only when the Harvest-first order is tested. Rule for Quinn's placement tests: any nudge between two controls is tested in both update orders.

## L15 · 2026-11-08 · Raw tabs in mutations.json crashed mutate.py
- **What broke:** `mutate.py` died on `json.load` ("Invalid control character", line 853); then the item 21 mutation matched nothing (`find` occurs 0 times).
- **How noticed:** Rex's run of the items 19–21 mutations.
- **Cause:** Quinn wrote GDScript indentation as literal tab characters inside JSON strings; when they were escaped by hand, one got three tabs where `truck.gd` has two.
- **How fixed:** the strings use `\t`, matched to the file's real indentation.
- **Prevention:** `test_generate.test_mutations_file_is_valid_json_with_named_entries` parses the file and checks names are unique; a `find` that matches 0 times shows as BROKEN in `mutate.py`.

## L14 · 2026-11-08 · Turn-cap alarm compared two different counters
- **What broke:** the goal board flagged "20 turns with --max-turns 15" on Bob's 0.1.4 T14.4 fix 1 (16:46), so the cap looked broken.
- **How noticed:** the session handoff listed it as an open tooling issue.
- **Cause:** `call_line` checked the CLI's `num_turns` against the cap, but the cap counts model calls. That transcript has 10 model calls; the call that really reached the cap made 15 and ended `error_max_turns`.
- **How fixed:** `log_subagent.measure` counts model calls, `keep_transcript` records them, and `call_line` checks that count, not `num_turns`.
- **Prevention:** `test_goal_agent` asserts that `num_turns` above the cap with calls under it is not flagged.

## L13 · 2026-11-08 · A repeated step label overwrote kept transcripts
- **What broke:** the 15:25 transcripts for "T14.4, T14.5, T.3 fix 1/2/3" (Bob, Patricia) were replaced by the 16:46 step's, so the two runs couldn't be compared.
- **How noticed:** comparing transcripts for L14.
- **Cause:** `keep_transcript` named files only by label, and labels repeat when a goal is retried in the same run.
- **How fixed:** a taken name gets `-2`, `-3`.
- **Prevention:** `test_generate.test_a_repeated_label_never_overwrites_a_kept_transcript`.

## L12 · 2026-11-08 · Two owners fixed the same failure; fixes moved what was meant to stay
- **What broke:** item 14 fix rounds: Patricia and Bob both removed the same 30° cell turn; a lid fix asked to change only the end also moved the open pose; ForkIcon regressed.
- **How noticed:** designer play-test and the lid votes (`game/reports/votes/lid-close/round-1/decisions.json`).
- **Cause:** `fix_briefs` sent the same full report to every owner in parallel, and nothing pinned what the item said stays.
- **How fixed:** one code owner per fix round (the folder the failure names, else Patricia and Bob take turns); briefs say "change only what a failing row names"; a `scope` check lists files a round changed outside its owner's folder and hands them on; Quinn writes a keep test for what a play-test line says stays.
- **Prevention:** `test_goal_agent`: one-owner, scope and brief assertions.

## L11 · 2026-11-08 · A fix round ran 36 turns and 777k tokens (D168)
- **What broke:** Patricia's T14 fix 1 ran the suite herself and chased failures outside her brief.
- **How noticed:** the Monitor on the goal board.
- **Cause:** fix briefs neither banned running checks nor capped turns.
- **How fixed:** "do not run the suite" in every fix brief; `--max-turns 15` on fix rounds.
- **Prevention:** `test_goal_agent` asserts the brief text and the cap on fix rounds only.

## L10 · 2026-11-08 · A 90% comb-cover rule the pick itself broke (D169)
- **What broke:** agents grew cells past the frame to meet "cover 90%".
- **How noticed:** play-test; the r9-a pick covers only ~77%.
- **Cause:** a spec number never checked against the picked variant.
- **How fixed:** rule dropped; cells must lie inside the frame's inner rect at r9-a's proportion.
- **Prevention:** [[spec-consistency]]: check a spec number against the pick before adding it.

## L9 · 2026-11-08 · Model changes wrong for the third time while tests and style loop passed (D159, D160)
- **What broke:** hive and frame models changed wrongly; every check was green.
- **How noticed:** designer play-test ("the style loop should've caught this").
- **Cause:** tests checked numbers, not the look; nothing compared the result with the picked variant.
- **How fixed:** `pick_match.py` (Vera compares live prop and pick), one style round per Bob change, failing-first tests for play-test bugs, a code change required for a bug fix.
- **Prevention:** `goal_agent` checks `pick match` and `fail-first`; [[look-before-done]].

## L8 · 2026-11-08 · "Close this session" started the end-of-day routine (D164)
- **What broke / noticed:** the designer stopped it mid-run.
- **Cause:** a loose trigger phrase.
- **Fix / prevention:** only "end of work day" runs it ([[end-of-day-routine]]).

## L7 · 2026-11-07 · Design Votes cards tied clicks to the wrong option (Round 8)
- **What broke:** buttons voted for another card.
- **How noticed:** designer: "some of the buttons link to another cell".
- **Cause:** `compare_page.py add` gave every question every option, so card IDs repeated; later, spaces and `%` in vote IDs made the db drop votes.
- **How fixed:** options per question; IDs slugified.
- **Prevention:** `compare_page.py` refuses a page with two cards sharing an ID.

## L6 · 2026-11-06 · Decision IDs out of time order on the decision page (D114)
- **What broke:** D106 sat between D101 and D107; D100 before D101.
- **How noticed:** the designer saw it on the page.
- **Cause:** a session over midnight numbered decisions by log order.
- **How fixed:** renumbered by decision moment, Toronto dates.
- **Prevention:** end-of-day numbers by time; `decision_page.py` warns on an ID lower than an earlier-dated one.

## L5 · 2026-11-05 · Test runs looked stalled (D90)
- **What broke / noticed:** 6-7 silent minutes per full run; the designer thought it had hung (again for goal_agent's own `godot_run.py unit` on 11-08).
- **Fix:** progress and per-test times in `godot_run.py`, `mutate.py`, `run_tests.gd`; `live.json` in the status line.
- **Prevention:** `_tools/live.py` (2026-11-21): every suite (with pass/fail counts as they come), check, commit and render is in `live.json`, each agent's tool calls in `live.log`; shown by the status line, `watch.py` and the side pane (`_tools/live-pane/`).

## L4 · 2026-11-05 · Quinn's mutate run took an hour (D89)
- **Cause:** each of 8 mutations reran all 110 unit tests.
- **Fix:** `CB_ONLY=<expect list>` per mutation: ~36 s.
- **Prevention:** `test_generate` covers `mutate.py`'s CB_ONLY.

## L3 · 2026-11-05 · An agent run hit the 5-hour limit (D68, D95)
- **Fix / prevention:** `budget_guard.py` blocks a new agent that would pass the threshold, per agent and against the week's pace; goal runs pause and resume, never skip.

## L2 · 2026-11-05 · 0.1.3 step b left red mid-build in a worktree
- **What broke:** Bob and Quinn stopped part-way at the day's end; unit run 107/117 in `.claude/worktrees/0.1.3`.
- **Cause:** a big step started late in the window, in a worktree that hid it.
- **Fix / prevention:** [[one-folder-rule]]; WIP is checkpointed on the milestone branch with `_tools/checkpoint.py` (L1).

## L1 · 2026-11-08 · Fix-round edits sat uncommitted for a day
- **What broke:** item 14 fix-round edits and Quinn's tests lived only in the working tree from afternoon to late evening.
- **Cause:** a run that ends `waiting-designer` commits nothing, and a manual WIP commit was left to memory.
- **How fixed:** `_tools/checkpoint.py` commits WIP on the milestone branch with the red test count in the message.
- **Prevention:** [[end-of-day-routine]] allows milestone-branch checkpoints; the goal agent prints the checkpoint command when it stops waiting for the designer.
