---
spec: 0.3-course-build.md
version: 0.3
run: 0.3
started: 2026-11-22
result: paused
---
# Goal agent: 0.3-course-build.md (run 0.3)

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
Build what `game/specs/0.3-course-build.md` (version 0.3) asks for that the game lacks. Agent: `_tools/goal_agent.py` (spec `game/specs/m3-goal-agent.md`).

Command: `goal_agent.py game/specs/0.3-course-build.md`
Branch `main`: stays on it.

## Pass 1: scan (2026-11-22T13:15:17-05:00)

Unit results from `game/reports/_runs/20261122-011146/unit.log`. 0 of 14 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| C1 Welcome screen. | change | Patricia | missing | none found |
| C2 Habitat Health. | change | Patricia | missing | none found |
| C3 Plant wildflower patch. | change | Patricia | missing | none found |
| C4 The bumble bee visitor. | change | Patricia | missing | none found |
| C5 Victory screen. | change | Patricia | missing | none found |
| C6 Skip to ending. | change | Patricia | missing | none found |
| T1.1 every test run sets `show_welcome = false` except the welcom | test | Quinn | missing | none found |
| T1.2 item 1: at launch with `show_welcome = true` the overlay sho | test | Quinn | missing | none found |
| T2.1 item 2: Health starts at `habitat_health_start`; `thriving`  | test | Quinn | missing | none found |
| T3.1 item 3: the row's cost equals `40 × 1.25^n` (floored) for n  | test | Quinn | missing | none found |
| T4.1 item 4: before thriving the Journal button is hidden; at thr | test | Quinn | missing | none found |
| T5.1 item 5: reaching thriving during a zoom shows no victory unt | test | Quinn | missing | none found |
| T6.1 item 6: the skip icon reaches thriving with money unchanged, | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests (at  | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C1 Welcome screen. | 12.67 | 3 | 2 | 0.33 | 1 | 3 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 2 | C2 Habitat Health. | 9.67 | 2 | 2 | 0.33 | 1 | 2 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 3 | C3 Plant wildflower patch. | 9.67 | 2 | 2 | 0.33 | 1 | 2 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 4 | C4 The bumble bee visitor. | 9.67 | 2 | 2 | 0.33 | 1 | 2 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 5 | C5 Victory screen. | 9.67 | 2 | 2 | 0.33 | 1 | 2 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 6 | C6 Skip to ending. | 9.67 | 2 | 2 | 0.33 | 1 | 2 goal(s) wait on it; designer feature; cost 0.33 (Patricia) |
| 7 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.27 | 0 | waits on C1, C2, C3, C4, C5, C6 |
| 8 | T1.1 every test run sets `show_welcome = false` except  | 0.0 | 0 | 2 | 0.27 | 0 | waits on C1 |
| 9 | T1.2 item 1: at launch with `show_welcome = true` the o | 0.0 | 0 | 2 | 0.27 | 0 | waits on C1 |
| 10 | T2.1 item 2: Health starts at `habitat_health_start`; ` | 0.0 | 0 | 2 | 0.27 | 0 | waits on C2 |
| 11 | T3.1 item 3: the row's cost equals `40 × 1.25^n` (floor | 0.0 | 0 | 2 | 0.27 | 0 | waits on C3 |
| 12 | T4.1 item 4: before thriving the Journal button is hidd | 0.0 | 0 | 2 | 0.27 | 0 | waits on C4 |
| 13 | T5.1 item 5: reaching thriving during a zoom shows no v | 0.0 | 0 | 2 | 0.27 | 0 | waits on C5 |
| 14 | T6.1 item 6: the skip icon reaches thriving with money  | 0.0 | 0 | 2 | 0.27 | 0 | waits on C6 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

Next: **C1** (score 12.67: 3 goal(s) wait on it; designer feature; cost 0.33 (Patricia)).

### Step: C1 (2026-11-22T13:15:18-05:00)

- Brief for Patricia: `game/reports/goal/0.3/briefs/C1-patricia.md` (1246 chars)
- Brief for Quinn: `game/reports/goal/0.3/briefs/C1-quinn.md` (2297 chars)

**Paused:** Budget guard: weekly usage is 31% with 17% of the week gone, more than 10 points ahead of pace, so heavy agents (programmer) wait (reading 21 min old). Don't start it: wait for the reset, or ask the designer to run `python -I _tools/budget_guard.py --allow-for 60`.
Run the same command again to resume.

## Result

Last invocation (2026-11-22T13:15:19-05:00): paused.

No agent calls.
