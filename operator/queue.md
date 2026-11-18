# queue - workspace tooling the operator owns

Each row is one job and its status (`open`, `held`, `built`, `done`). The designer adds rows; the operator updates the status when it changes. Design and judgement work is not here: it stays in [future-tbd](../_meta/memory/future-tbd.md) for an Opus session. Source: [analysis](../_meta/drafts/operator/analysis.md) section D.

| # | Job | Status | Notes |
|---|---|---|---|
| 1 | Merge `fix/cli-args-not-env-prefix` and `feat/voice-check` | held | after the desktop pull, in one pass with the M4 commits (designer, 2026-11-18) |
| 2 | First dream pass (`/dream`): six preferences, about 33 to 22 memory files | held | after #1; proposals in the analysis, sections A1 and A2; also the `rex-runs-scripts` wording from [wiring](../_meta/drafts/operator/wiring.md) section 5 |
| 3 | Republish the decision page | held | after the pull (the live page has D200-D218 from the desktop) |
| 4 | Tick the stale README TBD boxes (milestone dates, daily token budget) | open | ask the designer before ticking |
| 5 | Stop committing goal state on every goal commit (`blackboard.md`, `ledger.json`, `gaps.json`) | open | an Opus session picks between once-per-run and gitignore |
| 6 | Hook: scripts go to Rex (L21) | open | |
| 7 | Script: commit to main (L24) | open | |
| 8 | End-of-day mechanical steps as one script; the decision log stays in the skill | open | |
| 9 | Generate the handoff and `MEMORY.md` status lines from git and the run log | open | |
| 10 | `live.json` covers the scripts' own steps, then `watch.py` (future-tbd 5a and 5b) | open | |
| 11 | A7 deliverable 3: the run-log tables | open | the operator drafts the tables; an Opus session writes the analysis |
