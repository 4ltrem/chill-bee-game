---
session: 8e027381-9874-42d4-a37b-9092ca5be3f9
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: A3 grader's next steps scheduled; Claude Code's /goal compared with goal_agent.py
---
# Decisions: session 8e027381 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D194 · 2026-11-08 · Pipeline design · The A3 grader's next steps: M3 cap-stop summary, M4 content in Godot strings
- Decided: "schedule them that way": the `generate.py` cap-stop summary (open FAIL rows, owner, re-run command) in M3; one approved Bee Journal entry (EN/FR) through Godot's translation CSV on one screen in M4 (counts toward A7 deliverable 2).
- Files: `MILESTONES.md`, `_meta/memory/future-tbd.md` (commit `6959925`)

### D195 · 2026-11-08 · Pipeline design · Compare `/goal` with `goal_agent.py`; do both
- Decided: "it seems to be running better than the goal agent script ... can you compare both", then "do both": the comparison is written for A5 and the combined setup is backlog item 8. `goal_agent.py` stays the A5 artefact; `/goal` is the outer loop with a checkable condition.
- Files: `GOAL_AGENT.md`, `_meta/memory/future-tbd.md` (commit `6959925`)

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
