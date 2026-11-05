---
name: quinn-split-pending
description: "After 0.1.3 is done, apply Martin's replacement text to Quinn's definition so full suites, builds and mutate runs go to Rex (script-runner)"
metadata:
  node_type: memory
  type: project
  originSessionId: cbb6da0e-d437-4e4a-8094-be94d2d136c8
  modified: 2026-11-05T23:34:38.389Z
---

Rex, the Script Runner (`.claude/agents/script-runner.md`, Haiku) was hired 2026-11-05 to take script execution off
Quinn (Quinn caused 21% of the day's usage). Quinn's own definition is NOT changed yet, because another session was
building 0.1.3 with Quinn running full suites.

Once 0.1.3 is reported done, edit `.claude/agents/qa-build-engineer.md`:
- Replace the bullet "Use the scripts, not raw Godot output" with: "**Write tests; run only your own:** write tests and
  run only the tests you are writing, with `CB_ONLY=<names>`. Full suites, `--refresh` runs, builds and `mutate.py`
  go to Rex, the Script Runner, dispatched by the orchestrator. Read Rex's reply and open a log only to diagnose a
  failure. Paste `godot_run.py --markdown` tables from Rex's reply into reports. Prove new tests with `mutate.py`
  through Rex, using `game/tests/mutations.json`."
- Add: "You are relaunched only to diagnose failures, or to write the report."
- Keep the 150-word reply, stop-processes and input-path rules.
Also mention Rex in `game/CONTEXT.md` (Rex's definition names it as his contract), and log Rex's first real run
costs into `budget_guard.py` COST (estimate 3 today).

**Why:** designer's request to split Quinn into a generic executor other agents' runs can use.
**How to apply:** check with the designer that 0.1.3 is done first. Related: [[session-handoff]], [[usage-calibration]].
