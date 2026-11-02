# Chill Bee Game - design workspace

The design of a cozy mobile beekeeping idle game, built by one developer directing AI agents. What leaves it: `GDD.md`, kept current with each accepted proposal, and the content, audio and game built from it.

## Where things live

| Path | What it holds |
|---|---|
| [GDD.md](GDD.md) | the game design document: the single source of truth for every decision |
| [README.md](README.md) | public overview and the Outstanding TBDs checklist |
| [CONTEXT.md](CONTEXT.md) | the design loop: request, proposal, decision, apply |
| [proposals/](proposals/CONTEXT.md) | agent proposals, one shelf per agent role, each with a status line |
| [content/](content/CONTEXT.md) | William's story outlines and Bee Journal text (EN/FR) |
| [audio/](audio/CONTEXT.md) | Andrew's licence-checked audio shortlists and picks |
| [research/](research/CONTEXT.md) | Ruth's checked sources: each claim with a verbatim quote, URL and date, for William and Connie |
| [game/](game/CONTEXT.md) | the Godot project: Patricia's scripts, Bob's scenes, Quinn's tests and reports |
| `gdd-review/`, `gdd-review-v2/` | multi-agent review rounds of past GDD snapshots (read-only history) |
| [_meta/team.md](_meta/team.md) | the agent roster: roles, models, and the rules every agent follows |
| [_meta/agent-runs.md](_meta/agent-runs.md) | token, tool-call and duration log of every agent run, and the daily budget |
| [_meta/memory/](_meta/memory/MEMORY.md) | Claude Code's project memories, shared across machines through git (each machine's `.claude/settings.local.json` points `autoMemoryDirectory` here) |
| `_meta/sessions/` | one folder per working session: `decisions.md` and the decision page are committed; transcripts stay local (gitignored) |
| `_templates/` | blank starters: `proposal.md`, `content.md`, `research-brief.md`, `audio-list.md`, and `agent.md` for a new agent |
| `_tools/` | `links.py` checks every link and input path; `index.py` rebuilds `_index.md` (`--decisions` prints the ledger); `generate.py` runs the content loop; `critic_check.py` checks Clara against the known-bad drafts in `fixtures/`; `test_generate.py` tests them with fake agents; `log_subagent.py` is the SubagentStop hook that logs Agent-tool runs; `export_session.py` and `decision_page.py` serve the end-of-day routine |
| `.claude/agents/` | runnable agent definitions, one per roster role in [_meta/team.md](_meta/team.md) |

## Route by task

| If | Go to | Then stop at |
|---|---|---|
| a feature needs a design proposal | Gerard: `.claude/agents/gameplay-architect.md`, writing to [proposals/design/](proposals/design/CONTEXT.md) | the designer's decision |
| numbers need modelling | Terry: `.claude/agents/progression-tree-expert.md`, writing to [proposals/balance/](proposals/balance/CONTEXT.md) | the designer's decision |
| a feature touches kids, ads, purchases, donations or data (Connie) | `.claude/agents/compliance-officer.md` | its findings report |
| story, onboarding or Bee Journal text is needed | William: `.claude/agents/writer.md`, writing to [content/](content/CONTEXT.md) | the designer's approval |
| a content draft needs checking against the GDD | Clara: `.claude/agents/content-critic.md`, appending her verdict to the run's blackboard in [content/](content/CONTEXT.md) | a PASS verdict, or a FAIL for William to revise |
| a sound or music track is needed | Andrew: `.claude/agents/audiophile.md`, writing to [audio/](audio/CONTEXT.md) | the designer's approval |
| real-world facts or sources are needed | Ruth: `.claude/agents/research-assistant.md`, writing to [research/](research/CONTEXT.md) | the designer's review of the brief |
| an applied design needs code | Patricia: `.claude/agents/programmer.md`, writing to [game/](game/CONTEXT.md) `scripts/` | Quinn's report |
| a biome or layout needs a scene | Bob: `.claude/agents/builder.md`, writing to [game/](game/CONTEXT.md) `scenes/` | Quinn's report |
| a feature or build is ready to test | Quinn: `.claude/agents/qa-build-engineer.md`, writing to [game/](game/CONTEXT.md) `tests/` and `reports/` | the developer plays the build |
| a proposal was accepted | [CONTEXT.md](CONTEXT.md), step 4 (apply) | `python -I _tools/links.py` passes |
| asked for status | `proposals/*/_index.md` and the README TBD list | report what exists |
| a skill gap no agent covers | Martin: `.claude/agents/hiring-manager.md` | the designer reviews the diff |
| asked about agent cost | [_meta/agent-runs.md](_meta/agent-runs.md) | - |
| the designer says "end of work day" | the `end-of-day` skill: `.claude/skills/end-of-day/SKILL.md` (export, decisions, page, checks, commit) | the commit, reported |

## The one rule

Nothing reaches `GDD.md` until the designer has accepted it. Agents propose; they never edit the GDD.
