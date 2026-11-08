---
name: spec-consistency
description: "Before adding a play-test item to a spec, grep the spec for every line on the same object or view and fix contradictions in the same edit"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b89522de-aba2-47a2-852d-34d76b9bf1f3
  modified: 2026-11-08T07:25:56.997Z
---

When adding a play-test item or contract line to a `game/specs/*.md` spec, first search the spec for every line touching the same object, view or state (e.g. "farm view", "CentrifugeLabel", "crank") and update any line the new item contradicts, in the same edit. Also keep other item numbers out of a Quinn contract line: `goal_agent.parse_spec` maps a line naming several items to a `T.n` id.

**Why:** 2026-11-08, I wrote item 13's test line ("in the farm view and at the second stop") right after item 12 ruled out cranking in the farm view; the test could never pass and cost two fix rounds plus a manual accept. Designer approved this habit with the other failure-mode fixes.

**How to apply:** every spec edit from play-test feedback: after writing item N, run `python -I _tools/spec_lint.py game/specs/<spec>.md --item N` and read its REVIEW pairs (built 2026-11-08). A Quinn line naming several items is a FAIL there, in the pre-commit gate (`--staged`), and at the start of a goal_agent build run. Related: [[look-before-done]], [[session-handoff]].
