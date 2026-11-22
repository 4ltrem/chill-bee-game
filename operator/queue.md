# queue - workspace tooling the operator owns

Each row is one job and its status (`open`, `held`, `built`, `done`). The designer adds rows; the operator updates the status when it changes. Design and judgement work is not here: it stays in [future-tbd](../_meta/memory/future-tbd.md) for an Opus session. Source: [analysis](../_meta/drafts/operator/analysis.md) section D.

| # | Job | Status | Notes |
|---|---|---|---|
| 1 | Merge `fix/cli-args-not-env-prefix` and `feat/voice-check` | held | after the desktop pull, in one pass with the M4 commits (designer, 2026-11-18) |
| 2 | First dream pass (`/dream`): six preferences, about 33 to 22 memory files | held | after #1; proposals in the analysis, sections A1 and A2; also the `rex-runs-scripts` wording from [wiring](../_meta/drafts/operator/wiring.md) section 5 |
| 3 | Republish the decision page | held | after the pull (the live page has D200-D218 from the desktop) |
| 4 | Tick the stale README TBD boxes (milestone dates, daily token budget) | open | ask the designer before ticking |
| 5 | Stop committing goal state on every goal commit (`blackboard.md`, `ledger.json`, `gaps.json`) | built | 2026-11-21: once per run (`goal_agent.commit_state`, `--only` its own paths at the run's end); kept tracked for the A7 history |
| 6 | Hook: scripts go to Rex (L21) | built | 2026-11-21: `guard_shell.py` rule 7 |
| 7 | Script: commit to main (L24) | built | 2026-11-21: `_tools/commit_main.py` (`--push` only with the designer's yes) |
| 8 | End-of-day mechanical steps as one script; the decision log stays in the skill | built | 2026-11-21: `_tools/end_of_day.py prep` / `checks`, wired into the skill |
| 9 | Generate the handoff and `MEMORY.md` status lines from git and the run log | built | 2026-11-21: `_tools/status.py` (`/status`; `--markdown` facts block for the handoff); the judgement lines stay hand-written |
| 10 | `live.json` covers the scripts' own steps, then `watch.py` (future-tbd 5a and 5b) | built | 2026-11-21: `_tools/live.py`, `watch.py`, the side pane `_tools/live-pane/` (5c) |
| 11 | A7 deliverable 3: the run-log tables | open | the operator drafts the tables; an Opus session writes the analysis |
