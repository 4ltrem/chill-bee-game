---
name: end-of-day-routine
description: "When the designer says \"end of work day\", run the end-of-day project skill; never export or commit mid-session on my own"
metadata:
  node_type: memory
  type: feedback
  originSessionId: b89522de-aba2-47a2-852d-34d76b9bf1f3
  modified: 2026-11-08T07:32:40.797Z
---

When the designer says "end of work day" (or "done for the day", "wrap up"), invoke the `end-of-day` project skill
(`.claude/skills/end-of-day/SKILL.md`): export the session, log the day's decisions, rebuild and republish the
decision page, run the checks, commit.

**Why:** the designer keeps every session for analysis and a future episodic-memory upgrade, works on more than one
machine (a desktop PC and a laptop), and wants the record to cover the whole day.

Checkpoint commits on a `milestone/<version>` branch after each green build step are allowed mid-session (designer, 2026-11-04, `game/CONTEXT.md` Process 4); the end-of-day commit still covers the day, and the branch merges into `main` when the milestone passes.

"Time to close this session" is NOT end of day (2026-11-08: I started the routine and the designer stopped it: "not done working just need to move onto the next task"). Closing a session means: rewrite [[session-handoff]] to the current state so the next session can resume, nothing more. Only the explicit end-of-day phrases run the skill.

**How to apply:** don't re-export, update decisions, republish the page or commit before the designer says the day is
done. Memories live in the repo (`_meta/memory/`) and travel with git; transcripts stay local on each machine
(designer's decision, 2026-11-01). Related: [[pending-approvals]].
