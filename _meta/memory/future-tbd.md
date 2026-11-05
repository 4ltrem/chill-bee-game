---
name: future-tbd
description: "Designer's backlog for the workspace's own tooling - episodic memory upgrade, a dream skill, syncing transcripts between machines"
metadata:
  node_type: memory
  type: project
  originSessionId: 472d224a-a84f-4a66-bfff-00b669226a91
  modified: 2026-11-05T20:58:10.773Z
---

TBD items the designer named on 2026-11-01, not started:

1. **Episodic memory upgrade.** Use the session records (`_meta/sessions/*/decisions.md` in git; transcripts,
   subagent and `runs/` transcripts kept locally) so a future session can recall what happened in past ones,
   not only the short facts in `_meta/memory/`.
2. **Dream skill.** A skill that consolidates memories between sessions (reviews recent sessions, merges,
   corrects and prunes memories). Claude Code has a built-in background consolidation switch,
   `autoDreamEnabled`, worth checking before building one.
3. **Sync transcripts between machines** (desktop PC and laptop). Transcripts stay out of git (designer's
   decision, 2026-11-01: they hold the account email, my reasoning and everything read, and add 2-4 MB per
   session), so they need another route.
4. **Learnings file** (added 2026-11-05, D92). One file listing everything that broke, how it was noticed and how
   it was fixed. Seed it from the decision logs, the memories and the QA reports. Examples: Quinn's hour-long
   mutate run (D89), the agent run that hit the 5-hour limit (which led to the budget guard), and the red 0.1.3
   step b.

**Why:** the designer keeps every session for analysis and wants memory to work across machines.

**How to apply:** when the designer asks what's next for the workspace tooling, or touches memory, sessions or
exports, raise these. Don't start them unasked. Related: [[end-of-day-routine]].
