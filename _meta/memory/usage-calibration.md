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
main session had processed ~153.5M tokens over 400 calls (151.5M of them cache reads), against under 8M for all its
subagents. The orchestrator is the main cost, so a calibration that leaves it out is wrong.

**How to apply:** until hooks capture this automatically, ask the designer for the `/usage` figures before the first
agent call and after the last one in a batch, rather than every single call. Don't launch until they have given the
readings, or have said to skip them.
