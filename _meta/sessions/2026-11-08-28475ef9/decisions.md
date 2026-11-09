---
session: 28475ef9-e95c-4529-bb2f-7df1fc9c11f8
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: goal-agent blockers, the lid still clipping after a logged "fix", fix-needs-commit gates, Rex runs every script
---
# Decisions: session 28475ef9 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D170 · 2026-11-08 · Pipeline design · Fix the goal agent's blockers before the next run
- Decided: before the next goal run, fix the two approved items: the goal agent credited new test line T14.4 as done because another item 14 test passed (line IDs are positional), and fix rounds get the 15-turn cap with a "don't run the suite" brief.
- Why: "look into your memory for the best leverage tasks before starting another goal run"; the previous fix round cost 777k tokens.
- Files: `_tools/goal_agent.py`, `_tools/test_goal_agent.py` (commit `fcde905`)

### D171 · 2026-11-08 · Cost & structure · Budget guard overridden again for the T14 goal runs
- Decided: "override" for 60 minutes for the first T14.4 run; again at 16:46 ("yes, then override and run the goal agent") and 19:03 for `/goal finish 0.1.4`. That makes about eight overrides since D148.
- Files: `_tools/budget_guard.py`

### D172 · 2026-11-08 · Pipeline design · A fix is done only when a code change is committed (A–D)
- Decided: after the lid still clipped although a handoff said "fixed (designer confirmed)", the designer approved "a-d": (A) a test marked "shown failing" must fail on its first run, else Quinn is sent back; (B) a play-test goal that changed only test files is held, not committed; (C) `guard_shell` refuses main-session edits to `game/` while a goal run is live; (D) the lid test is rewritten until it fails on the clipping build.
- Why: "this shouldn't have happened, a fix should always be committed". T14.3 passed on the clipping build; the fix commit `720d42d` only resized combs.
- Files: `_tools/goal_agent.py`, `_tools/guard_shell.py`, `_meta/memory/fix-needs-commit.md`, `game/tests/lid_shots.gd`

### D173 · 2026-11-08 · Workspace & agents · Main-session edits during a goal run go in a worktree
- Decided: "if this main session has to edit files the goal agent is working on it should do so in a worktree"; built into D172's run lock.
- Files: `_tools/guard_shell.py`, `_tools/goal_agent.py`

### D174 · 2026-11-08 · Game build · T14.4 fix-round edits reverted, Quinn's tests kept
- Decided: "Revert them" for the uncommitted fix-round script and scene edits; the lid clips on "Every close". The reverted diff is kept.
- Files: `game/reports/goal/0.1.4/T14.4-fix-rounds-reverted.diff`, `game/specs/0.1.4-ui-placement.md`

### D175 · 2026-11-08 · Game build · Lid test: a 1° tilt is fine, it just can't clip (T14.5)
- Decided: "1 percent tilt is fine it just can't clip". T14.5: the lid sinks no more than 0.005 into any hive part at any frame of the close.
- Files: `game/specs/0.1.4-ui-placement.md`, `game/tests/lid_shots.gd`

### D176 · 2026-11-08 · Workspace & agents · Prefer Linux tools over PowerShell
- Decided: "prefer linux tools over powershell".
- Files: `_meta/memory/prefer-bash.md`

### D177 · 2026-11-08 · Pipeline design · The goal board logs each agent call's command, turns and end state
- Decided: "yes, log the command and turns on the blackboard": one line under every agent reply with the exact `claude` command, turns against the cap and how it ended.
- Files: `_tools/goal_agent.py`, `_tools/test_goal_agent.py` (commit `3eb1c7e`)

### D178 · 2026-11-08 · Workspace & agents · Rex runs every script; Quinn no longer runs tests
- Decided: "rex is supposed to run scripts". Every `godot_run`, `build`, `mutate` or shot run goes to Rex; Quinn's briefs say the goal agent runs the checks after him.
- Why: suite runs on Sonnet took 21% of the plan on 11/4; Quinn's last write step was 974k tokens.
- Files: `_meta/memory/rex-runs-scripts.md`, `_tools/goal_agent.py` (commit `b9f9347`)

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
