---
{run fields: slug and type (content, style) or spec, version and run (goal)}
started: {YYYY-MM-DD}
{caps, if any: max_rounds, max_tokens}
result: {running | draft | needs-review | pass | done | stopped | paused | blocked | waiting-designer | failed}
---
# {Blackboard: slug | Style blackboard: slug | Goal agent: spec (run name)}

The shared record of this run. The script writes every section and hands each agent only the slice it needs; no agent reads this file. Inputs (briefs, drafts, shots) are linked; what agents and checks return (verdicts, replies, scores) is written here.

## Request
{what the run was asked to do; the goal board adds the command}

## {Round N | Pass N}
{The first one in full (content: a link to the round-1 draft snapshot; style: the shots folder and the style_check table; goal: the gap table and the scores with their factors, the "why"). Later ones show only what changed: William's or Bob's diff, or the goal rows whose gap or score changed. Briefs are linked, never copied. Verdicts (`### Critic, round N`) and agent replies are written inline.}

## Waiting for the designer
{Only if the run stops for a creative choice or a failed fix: what it waits on, with any Design Votes link, and the command to resume.}

## Resumed {YYYY-MM-DD}
{The command and the designer's answer. The run goes on below.}

## Result
{One section, always last, rewritten in place at each stop: the summary, the `Transcripts:` link(s), and the per-call table covering every call of the run, kept across resumes in `<board>.calls.json` beside the board.}

| Call | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|
| {Agent, round N or goal label} | {tokens} | {tokens or —} | {n} | {s} s |
| **Total** | **{tokens}** | | | |

<!-- Written by generate.py (board_start, waiting, resumed, finish_board); used by generate.py, style_loop.py and goal_agent.py. --plan and --dry-run write nothing here. Designer decision 2026-11-07. -->
