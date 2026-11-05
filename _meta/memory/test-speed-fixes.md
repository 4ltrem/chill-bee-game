---
name: test-speed-fixes
description: Slow Godot tests and mutate.py - fixes 1-2 done 2026-11-05 (D89, D90); fix 3 (time_scale via Quinn) and the budget guard still open
metadata:
  node_type: memory
  type: project
  originSessionId: 4297b6fb-4f37-489e-a81b-e6e820fcf5da
  modified: 2026-11-05T20:21:24.770Z
---

On 2026-11-05 the designer found test runs slow and Quinn's latest revision took over an hour, most of it waiting on `_tools/mutate.py`. The tests do NOT read .md files (only comments name the specs); values already come from `scripts/default_config.tres`. The time is real-time gameplay: animations, 3 s/jar bottling, `_until` timeouts up to 40 s.

Measured 2026-11-05: unit ~3.5 min (110 tests), play ~2 min, measure ~1 min; full run 6-7 min, all passing. Slowest unit tests: t_resume_pending_pile_loads_while_zoom_open 29 s, t_zoom_bucket_lid_pile_flow 28 s, t_back_keeps_half_frame 22 s. Already done: `game/tests/run_tests.gd` prints ms per test on each PASS/FAIL line.

Fixes (1 and 2 DONE 2026-11-05, commit f5a0cbd: mutate run ~1 h -> ~36 s; 3 still to do):
1. **mutate.py runs only the `expect` tests**: `godot_run.run_suite` gets an optional env; mutate passes `CB_ONLY=",".join(expect)` (run_tests.gd already honours CB_ONLY). Today it runs all 110 tests x 8 mutations (~30-60 min, longer because broken tests wait out timeouts). Also give each mutation its own log name (they overwrite `unit.log`). Should drop to a few minutes.
2. **godot_run.py progress lines**: print each suite's start/finish with elapsed time, so a 7-minute run doesn't look stalled.
3. **Unit speed-up via Engine.time_scale** (e.g. 4x, env-controlled): brief Quinn, since timing tests (t_bottling_timing, t_pop_tween_unchanged) may need adjusting. Check it doesn't clash with the 0.1.3 build (see [[session-handoff]]).

**Why:** agent runs block on the tests; see [[cost-rules]] (godot_run/mutate were cost cuts).
**How to apply:** start tomorrow with 1 and 2 (tool changes); test with `python -I _tools/test_generate.py` and one `mutate.py` run.
