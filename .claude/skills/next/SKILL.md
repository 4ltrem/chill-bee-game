---
name: next
description: Show where the workspace stands and offer the next job for Chill Bee Game's designer to pick. Use when the designer says "next", "what's next", "what should we do", runs /next, or at the start of a session.
---

# Next

1. Run `python -I _tools/status.py` and show its output as is, in a code block. Facts only, read-only.
2. Read only the **NEXT** and **Still open** sections of `_meta/memory/session-handoff.md`. Do not read the rest.
3. Pick the top two or three jobs from those sections and offer them in AskUserQuestion. Label each option with its owner from the route table in `AGENTS.md` (for example "Patricia", "Rex", "the main session", "the designer"), and describe it with the stop it ends at (the designer's decision, Quinn's report, a PASS, and so on).
4. Start nothing until the designer picks. The picked job is this session's one job (`AGENTS.md`, Session flow): do it up to its stop and then end the session's work, rather than chaining more jobs.

## Pitfalls

- Do not paste the whole handoff into a reply. Name a job in one line and point to the section.
- Do not decide on the designer's behalf: no picking a job for them, no answering an open question, no accepting a proposal.
- Do not offer a job whose owner or stop you cannot find in the route table; say so and ask instead.
