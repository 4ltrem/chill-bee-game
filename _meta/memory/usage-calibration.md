---
name: usage-calibration
description: "Before the Prototype 0 revision 3 agent run, take /usage readings before and after to recalibrate the daily token budget"
metadata:
  node_type: memory
  type: project
  originSessionId: fa5df4be-6365-415d-bd06-9f0be0bb573b
  modified: 2026-11-03T23:19:47.359Z
---

The designer asked (2026-11-03) to calibrate the usage metrics before the next agent run, which is Prototype 0
revision 3 (Patricia, Bob, Quinn). The ~2.0M/day budget in `_meta/agent-runs.md` (Daily Budget) rests on a single 1%
weekly reading, so it could be anywhere from about 1.3M to 4M. It was also taken in *final context*, while the daily
usage table mostly sums *total processed*.

Procedure:
1. Before launching, ask the designer for `/usage` weekly % and 5-hour session %. Claude cannot read `/usage` itself.
   Ask them to keep other Claude sessions closed during the run.
2. Run the three agents back to back. The SubagentStop hook logs each run's final context and total processed.
3. After the run, ask for `/usage` again. Compute tokens per 1% both ways (final context and total processed) and note
   which one matches the first calibration. Record that in Daily Budget as the second calibration.
4. The main session's own tokens also move the bar, and the hook doesn't log them; say so with the result.

Revision 2 (Patricia, Bob, Quinn) processed about 2.66M tokens in total, so revision 3 should move the weekly bar by
several points, enough for a useful reading.

**Why:** the provisional budget's whole-percent resolution leaves a 3x range, and the day's usage is compared against it
in mismatched units.

**How to apply:** do step 1 before the first Agent call of revision 3. Don't launch until the designer has given the
readings, or has said to skip them.
