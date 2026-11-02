---
name: end-of-day-routine
description: When the designer says "end of work day", run the end-of-day project skill; never export or commit mid-session on my own
metadata:
  type: feedback
---
When the designer says "end of work day" (or "done for the day", "wrap up"), invoke the `end-of-day` project skill
(`.claude/skills/end-of-day/SKILL.md`): export the session, log the day's decisions, rebuild and republish the
decision page, run the checks, commit.

**Why:** the designer keeps every session for analysis and a future episodic-memory upgrade, works on more than one
machine (a desktop PC and a laptop), and wants the record to cover the whole day.

**How to apply:** don't re-export, update decisions, republish the page or commit before the designer says the day is
done. Memories live in the repo (`_meta/memory/`) and travel with git; transcripts stay local on each machine
(designer's decision, 2026-11-01). Related: [[pending-approvals]].
