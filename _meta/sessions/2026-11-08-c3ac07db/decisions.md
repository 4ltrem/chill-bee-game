---
session: c3ac07db-2f5d-4871-bc93-503eb6170e15
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: Quinn's interaction checklist and the rule for automatic steps when the player leaves
---
# Decisions: session c3ac07db (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D185 · 2026-11-08 · Pipeline design · Quinn's interaction checklist: four steps, one sequence test, ask don't guess
- Decided: contract lines for running interactions; exits = in-game plus app pause; when the spec is silent Quinn asks instead of guessing; the four checks (start, leave mid-way, come back, do it twice) as one sequence test, each with two mutations; in every Quinn test brief.
- Files: `_tools/goal_agent.py` (`INTERACTION_CHECKLIST`), `.claude/agents/qa-build-engineer.md`, `game/CONTEXT.md`, `_meta/drafts/0.1.4/quinn-interaction-checklist.md`

### D186 · 2026-11-08 · Pipeline design · Automatic steps and automation upgrades keep running after the player leaves
- Decided: "lets generalize it to anything that loads automatically because in future milestones we have automation upgrades". Leaving mid-way stops player input from counting; automatic steps (jar pour, pile loading) and owned automation keep going and the test waits for them; a silent spec is a question for the designer. Checkpoint `c2bfdc5`.
- Files: `_tools/goal_agent.py`, `.claude/agents/qa-build-engineer.md`, `game/CONTEXT.md`

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
