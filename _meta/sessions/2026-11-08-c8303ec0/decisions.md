---
session: c8303ec0-c282-4c53-8485-6ddd8b591b5e
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: /goal run fixing the design loop: fix-round discipline, tests that prove more, learnings file and checkpoints
---
# Decisions: session c8303ec0 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D184 · 2026-11-08 · Pipeline design · Loop fixes: fix-round discipline, tests that prove more, learnings and checkpoints
- Decided: `/goal fix the current workspace and design loop to avoid previous mistakes`; the designer picked fix-round discipline, learnings + checkpoint and tests that prove more (not live.json), on the lean budget. Built: one owner per fix round, "change only what failed" briefs, a scope check, a keep-test line from Quinn; a `mutate.py` baseline run; `_meta/learnings.md` linked from `AGENTS.md`; `_tools/checkpoint.py`.
- Why: D160's repeat-failure list; settles where the learnings file lives (D92).
- Rejected: `live.json` in this round.
- Files: `_tools/goal_agent.py`, `_tools/mutate.py`, `_tools/checkpoint.py`, `_meta/learnings.md`, `AGENTS.md`, `.claude/skills/end-of-day/SKILL.md` (commit `3bb2012`)

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
