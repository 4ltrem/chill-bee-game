---
name: test-speed-fixes
description: Slow Godot tests and mutate.py - fixes 1-2 done 2026-11-05 (D89, D90); fix 3 (time_scale) in progress; Quinn split applied 2026-11-05
metadata:
  node_type: memory
  type: project
  originSessionId: 4297b6fb-4f37-489e-a81b-e6e820fcf5da
  modified: 2026-11-24T01:09:18.793Z
---

On 2026-11-05 the designer found test runs slow and Quinn's latest revision took over an hour, most of it waiting on `_tools/mutate.py`. The tests do NOT read .md files (only comments name the specs); values already come from `scripts/default_config.tres`. The time is real-time gameplay: animations, 3 s/jar bottling, `_until` timeouts up to 40 s.

Measured 2026-11-05: unit ~3.5 min (110 tests), play ~2 min, measure ~1 min; full run 6-7 min, all passing. Slowest unit tests: t_resume_pending_pile_loads_while_zoom_open 29 s, t_zoom_bucket_lid_pile_flow 28 s, t_back_keeps_half_frame 22 s. Already done: `game/tests/run_tests.gd` prints ms per test on each PASS/FAIL line.

Fixes (1 and 2 DONE 2026-11-05, commit f5a0cbd: mutate run ~1 h -> ~36 s; 3 still to do):
1. **mutate.py runs only the `expect` tests**: `godot_run.run_suite` gets an optional env; mutate passes `CB_ONLY=",".join(expect)` (run_tests.gd already honours CB_ONLY). Today it runs all 110 tests x 8 mutations (~30-60 min, longer because broken tests wait out timeouts). Also give each mutation its own log name (they overwrite `unit.log`). Should drop to a few minutes.
2. **godot_run.py progress lines**: print each suite's start/finish with elapsed time, so a 7-minute run doesn't look stalled.
3. **Unit speed-up via Engine.time_scale** (e.g. 4x, env-controlled): brief Quinn, since timing tests (t_bottling_timing, t_pop_tween_unchanged) may need adjusting. Check it doesn't clash with the 0.1.3 build (see [[session-handoff]]).

**2026-11-05 evening, designer: "these qa runs are way too long, after this one it's time to upgrade".** Right after the current 0.1.3c QA round, before any new build work: fix 3 (time_scale), apply [[quinn-split-pending]] (Quinn writes tests, Rex runs them), and iterate with CB_ONLY on the affected tests, keeping the full `godot_run.py all` for checkpoints only. Agent QA rounds took 12–57 min each in 0.1.3c.

**2026-11-06, done; designer: "anything that needs to be tested in real time I can do, I do not want to wait an hour for tests".** Standard checkpoint run (Rex): `python -I _tools/godot_run.py all --time-scale 6 --skip-x1` plus `python -I _tools/mutate.py --since <last checkpoint>` (only new or changed mutations; ~1 min for 11). The 10 X1_TESTS (real-time) are played by the designer instead. The hour-long mutate run came from a worktree holding an old mutate.py without per-mutation CB_ONLY: a milestone worktree must take `_tools/` fixes from its parent branch (`git checkout milestone/m2 -- _tools/<file>`).

**2026-11-08, designer approved (backlog, after the 0.1.4 goal run): parallel test runs** ("why arent the tests running in parallel like multiple game windows"). Today `godot_run.py` runs suites one after another (line 186) and `mutate.py` runs mutations one at a time in one copy. To run them in parallel: give each windowed suite its own `--position`, give each run its own `user://` folder (saves and recordings collide; T6.1 checks recordings), give each parallel mutation its own game copy, and keep real-time/FPS-sensitive suites alone. The gain is modest now that mutations run only their `expect` tests (~1 min): mainly the 6–7 min `all` run. Don't change these scripts mid goal-agent run (Quinn's lines call them).

**2026-11-08, missed:** the orchestrator sent Rex plain `godot_run.py unit start` three times (15 min each) instead of the fast run; designer asked why tests take 15 min and said yes to using time_scale + CB_ONLY. Every Rex brief names the speed flags: `godot_run.py unit --only <tests> --time-scale 6` while iterating, `godot_run.py all --time-scale 6 --skip-x1` at checkpoints. **2026-11-17:** flags, not `CB_*=` shell prefixes: the prefixes made Claude Code permission warnings (laptop) and the shell blocked them for Quinn in 0.1.4; the flags set the same env vars inside godot_run.py.

**2026-11-23, missed again (designer: "not the first time you don't follow the rule"):** during the 0.3.1 run the orchestrator sent Rex the full `unit` (8½ min) plus `play` after every small hand fix, six times or more, about an hour of waiting. Rule, no exceptions: after a hand fix, Rex runs `start` plus `unit --only <the failing or touched tests> --time-scale 6` and nothing else. Look up the real test names first (grep `func t_` in game/tests; a name that matches nothing runs 0 tests). Full suites only at a checkpoint the designer is waiting on, or leave them to goal_agent's end-of-run suite. Never add a "fallback: run everything" line to a Rex brief.

**Why:** agent runs block on the tests; see [[cost-rules]] (godot_run/mutate were cost cuts).
**How to apply:** start tomorrow with 1 and 2 (tool changes); test with `python -I _tools/test_generate.py` and one `mutate.py` run.
