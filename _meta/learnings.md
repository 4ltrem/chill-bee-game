# Learnings

Everything that broke in the workspace or the design loop, how it was noticed, why, how it was fixed, and what now stops it repeating (D92). One entry per break; new entries take the next number at the top. Add an entry whenever a fix lands for something that broke; the end-of-day skill checks the day's decisions for one. Decision IDs point to `_meta/sessions/*/decisions.md`.

Format: **What broke** · **How noticed** · **Cause** · **How fixed** · **Prevention** (the check, test or rule that now catches it).

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
- **How noticed:** designer play-test and the lid votes (`game/reports/_look/lid-close-r1-votes.json`).
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
- **Prevention:** still open: `live.json` for the scripts' own steps and `watch.py` (future-tbd 5).

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
