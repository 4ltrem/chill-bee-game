---
name: usage-calibration
description: "Every agent run logs plan usage before and after, plus the orchestrator's own tokens; calibrate the daily budget from those readings"
metadata:
  node_type: memory
  type: feedback
  originSessionId: fa5df4be-6365-415d-bd06-9f0be0bb573b
  modified: 2026-11-03T23:23:09.168Z
---

Rule (designer, 2026-11-03): every agent run, of any agent or kind (Agent tool, `generate.py`, headless `claude -p`),
records plan usage before and after it. The orchestrator's (main session's) tokens are logged too, never left out.

Each run's record holds:
- the 5-hour % and weekly % before and after (`/usage`; the status line JSON exposes them as
  `rate_limits.five_hour.used_percentage` and `rate_limits.seven_day.used_percentage`);
- the subagent's final context and total processed (already logged by the SubagentStop hook);
- the orchestrator's tokens over the same span, summed from the main session transcript's per-call `usage`
  (input, cache write, cache read and output kept separate).

Tokens per 1% then come from the usage change ÷ (subagent + orchestrator tokens). Record each reading in
`_meta/agent-runs.md` (Daily Budget) and refine the ~2.0M/day budget from them.

**Why:** the budget rests on a single 1% reading (3x uncertainty), and the logs omit the orchestrator. On 2026-11-03 the
main session had processed ~156.5M tokens over 421 calls (154.4M of them cache reads), against ~11.1M for every
post-ICM agent run in the log. The orchestrator is the main cost, so a calibration that leaves it out is wrong.

**Budget guard (2026-11-05):** after a run hit the 5-hour limit mid-task, `_tools/budget_guard.py` runs as a PreToolUse hook on Agent/Workflow: it denies launches at >= 80% of the 5-hour window or >= 90% weekly, warns at 65%. The designer can lift it for N minutes with `python -I _tools/budget_guard.py --allow-for N`. When it warns, finish the current step and pause rather than starting a batch.

**How to apply:** since 2026-11-03 the hooks do this automatically (`_tools/runlog.py`, `log_subagent.py`,
`log_session.py`, `statusline.py`; rows in `_meta/agent-runs.csv`). Before a batch of agent runs, check that
`_meta/usage/readings.jsonl` is getting fresh readings. If it isn't (the status line may not run in the VS Code
extension), ask the designer for the `/usage` figures before the first agent call and after the last one in the batch.
Calibrate with `python -I _tools/runlog.py --calibrate SINCE [UNTIL]`.
