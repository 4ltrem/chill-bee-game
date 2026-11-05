---
name: cost-rules
description: Designer approved 9 token-cost rules (2026-11-04): scripts for tests/builds/mutations, split tests, spec slices, 150-word agent replies, sweeps by script, contact sheets, fresh session per milestone
metadata:
  type: feedback
---

Designer agreed to all nine cost cuts on 2026-11-04 after the run log showed ~60M agent tokens and 23.5M
orchestrator tokens in one day (weekly 33% -> 47%). Rules, recorded in `game/CONTEXT.md` Process 8 and the
Quinn/Patricia/Bob definitions:
1. `_tools/godot_run.py` for test suites (agents read summaries, not raw Godot logs).
2. `_tools/build.py VERSION --smoke` for exports.
3. `_tools/mutate.py` + `game/tests/mutations.json` instead of hand-made broken copies.
4. Tests split one file per area (Quinn does it on his next edit).
5. Briefs name only the spec sections needed; fold Clarifications into the spec body when a build closes.
6. Number-only questions (camera framing, config sweeps) go to a probe script, not one agent per value.
7. Agent final replies at most 150 words.
8. `_tools/contact_sheet.py` (run without -I, needs Pillow) so I review one image.
9. Start each milestone in a fresh orchestrator session; carry state in [[session-handoff]].

**Why:** the orchestrator's long context and Quinn's 22.7M-token build run were the biggest costs.

**How to apply:** use the scripts myself too; keep agent briefs short and sliced; suggest a fresh session at
each milestone boundary. Related: [[usage-calibration]], [[course-milestones]].
