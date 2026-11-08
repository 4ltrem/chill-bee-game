---
name: future-tbd
description: "Designer's backlog for the workspace's own tooling - episodic memory upgrade, a dream skill, syncing transcripts between machines"
metadata:
  node_type: memory
  type: project
  originSessionId: 472d224a-a84f-4a66-bfff-00b669226a91
  modified: 2026-11-07T22:07:55.806Z
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
5. **See the headless agents again** (added 2026-11-07). The script loops (`goal_agent.py`, `generate.py`,
   `style_loop.py`) run agents as `claude -p`, so they don't show in Claude Code's agent list as Agent-tool
   subagents did ("I can't see as clearly which sub agents are running"). Recommended, in order:
   (a) `generate.run_agent` writes `_meta/usage/live.json` on each agent start and end (agent, loop, run, goal or
   round, start time, model), and `statusline.py` shows it, e.g. `▶ goal 0.1.4 · C7 · Patricia 4m · Bob 2m`
   (about 30 lines and a test; all three loops share `run_agent`);
   (b) optionally `--output-format stream-json` teed to `<run>/live/<agent>.log`, plus `_tools/watch.py` that prints
   one line per tool call, to watch in a terminal split;
   (c) only if the status line is too small: a Claude Code mod side panel reading `live.json` (`plugin-authoring` skill).
   Do it after the shared blackboard format lands in `generate.py`.

6. **Onboarding guide** (deferred 2026-11-07, "not a priority rn"). `ONBOARDING.md` draft at the repo root, share
   link https://claude.ai/claude-code/onboard/34Mn5DdRy4BS (short_code 34Mn5DdRy4BS). Still to do: confirm the team
   name, fill Team Tips and Get Started, then refresh the link with ShareOnboardingGuide mode=update.

**Why:** the designer keeps every session for analysis and wants memory to work across machines.

**How to apply:** when the designer asks what's next for the workspace tooling, or touches memory, sessions or
exports, raise these. Don't start them unasked. Related: [[end-of-day-routine]].
