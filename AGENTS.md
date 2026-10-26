# Chill Bee Game - design workspace

The design of a cozy mobile beekeeping idle game, built by one developer directing AI agents. What leaves it: `GDD.md`, kept current with each accepted proposal.

## Where things live

| Path | What it holds |
|---|---|
| [GDD.md](GDD.md) | the game design document: the single source of truth for every decision |
| [README.md](README.md) | public overview and the Outstanding TBDs checklist |
| [CONTEXT.md](CONTEXT.md) | the design loop: request, proposal, decision, apply |
| [proposals/](proposals/CONTEXT.md) | agent proposals, one shelf per agent role, each with a status line |
| `gdd-review/`, `gdd-review-v2/` | multi-agent review rounds of past GDD snapshots (read-only history) |
| [_meta/team.md](_meta/team.md) | the agent roster: roles, models, and the rules every agent follows |
| [_meta/agent-runs.md](_meta/agent-runs.md) | token, tool-call and duration log of every agent run, and the daily budget |
| `_templates/` | blank starters: a new proposal is a copy of `proposal.md`, a new agent a copy of `agent.md` |
| `_tools/` | `links.py` checks every link and input path; `index.py` rebuilds `_index.md` |
| `.claude/agents/` | runnable agent definitions (Gerard, Terry, Connie) |

## Route by task

| If | Go to | Then stop at |
|---|---|---|
| a feature needs a design proposal | Gerard: `.claude/agents/gameplay-architect.md`, writing to [proposals/design/](proposals/design/CONTEXT.md) | the designer's decision |
| numbers need modelling | Terry: `.claude/agents/progression-tree-expert.md`, writing to [proposals/balance/](proposals/balance/CONTEXT.md) | the designer's decision |
| a feature touches kids, ads, purchases, donations or data (Connie) | `.claude/agents/compliance-officer.md` | its findings report |
| a proposal was accepted | [CONTEXT.md](CONTEXT.md), step 4 (apply) | `python -I _tools/links.py` passes |
| asked for status | `proposals/*/_index.md` and the README TBD list | report what exists |
| a role has no agent yet (Martin) | copy `_templates/agent.md` to `.claude/agents/`, add it to [_meta/team.md](_meta/team.md) | the designer reviews the diff |
| asked about agent cost | [_meta/agent-runs.md](_meta/agent-runs.md) | - |

## The one rule

Nothing reaches `GDD.md` until the designer has accepted it. Agents propose; they never edit the GDD.
