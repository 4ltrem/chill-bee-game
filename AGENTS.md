# Chill Bee Game - design workspace

The design of a cozy mobile beekeeping idle game, built by one developer directing AI agents. What leaves it: `GDD.md`, kept current with each accepted proposal, and the content, audio and game built from it.

## Where things live

| Path | What it holds |
|---|---|
| [GDD.md](GDD.md) | the game design document: the single source of truth for every decision |
| [STYLE_GUIDE.md](STYLE_GUIDE.md) | the approved look and voice rules (V1–V15, T1–T6) and palette tokens that scenes and text are checked against |
| [STYLE_LOOP.md](STYLE_LOOP.md) | how the two style loops (visual: Bob, `style_check.py`, Vera; voice: William, Clara) enforce the guide, with the demo runs and their cost |
| [MILESTONES.md](MILESTONES.md) | build stages, version numbers and the milestones, fitted to the course deadlines |
| [README.md](README.md) | public overview and the Outstanding TBDs checklist |
| [CONTEXT.md](CONTEXT.md) | the design loop: request, proposal, decision, apply |
| [proposals/](proposals/CONTEXT.md) | agent proposals, one shelf per agent role, each with a status line |
| [content/](content/CONTEXT.md) | William's story outlines and Bee Journal text (EN/FR) |
| [audio/](audio/CONTEXT.md) | Andrew's licence-checked audio shortlists and picks |
| [research/](research/CONTEXT.md) | Ruth's checked sources: each claim with a verbatim quote, URL and date, for William and Connie |
| [game/](game/CONTEXT.md) | the Godot project: Patricia's scripts, Bob's scenes, Quinn's tests and reports |
| `gdd-review/`, `gdd-review-v2/` | multi-agent review rounds of past GDD snapshots (read-only history) |
| [_meta/team.md](_meta/team.md) | the agent roster: roles, models, and the rules every agent follows |
| [_meta/agent-runs.md](_meta/agent-runs.md) | summary of every agent run (rows in `agent-runs.csv`), the calibration and the daily budget |
| [_meta/memory/](_meta/memory/MEMORY.md) | Claude Code's project memories, shared across machines through git (each machine's `.claude/settings.local.json` points `autoMemoryDirectory` here) |
| `_meta/sessions/` | one folder per working session: `decisions.md` and the decision page are committed; transcripts stay local (gitignored) |
| `_templates/` | blank starters: `proposal.md`, `content.md`, `research-brief.md`, `audio-list.md`, `blackboard.md` (the one run-board format every loop script writes), and `agent.md` for a new agent |
| [_tools/](_tools/CONTEXT.md) | the workspace scripts: checks, content and style loops, vote pages, Godot test/build runners, usage hooks, end-of-day helpers |
| `.claude/agents/` | runnable agent definitions, one per roster role in [_meta/team.md](_meta/team.md) |

## Route by task

| If | Go to | Then stop at |
|---|---|---|
| a feature needs a design proposal | Gerard: `.claude/agents/gameplay-architect.md`, writing to [proposals/design/](proposals/design/CONTEXT.md) | the designer's decision |
| numbers need modelling | Terry: `.claude/agents/progression-tree-expert.md`, writing to [proposals/balance/](proposals/balance/CONTEXT.md) | the designer's decision |
| a feature touches kids, ads, purchases, donations or data (Connie) | `.claude/agents/compliance-officer.md` | its findings report |
| story, onboarding or Bee Journal text is needed | William: `.claude/agents/writer.md`, writing to [content/](content/CONTEXT.md) | the designer's approval |
| a content draft needs checking against the GDD | Clara: `.claude/agents/content-critic.md`, replying with a verdict that `generate.py` appends to the run's blackboard in [content/](content/CONTEXT.md) | a PASS verdict, or a FAIL for William to revise |
| a sound or music track is needed | Andrew: `.claude/agents/audiophile.md`, writing to [audio/](audio/CONTEXT.md) | the designer's approval |
| real-world facts or sources are needed | Ruth: `.claude/agents/research-assistant.md`, writing to [research/](research/CONTEXT.md) | the designer's review of the brief |
| an applied design needs code | Patricia: `.claude/agents/programmer.md`, writing to [game/](game/CONTEXT.md) `scripts/` | Quinn's report |
| a biome or layout needs a scene | Bob: `.claude/agents/builder.md`, writing to [game/](game/CONTEXT.md) `scenes/` | Quinn's report |
| a scene needs a style check | `python -I _tools/style_loop.py <slug>`: `style_check.py`, then Vera (`.claude/agents/style-critic.md`), then Bob, writing the blackboard to `game/reports/style/` | a PASS, or a designer stop with its question on the Design Votes page (`_tools/compare_page.py add`) |
| a prop needs colorbox variants to compare | Milo: `.claude/agents/modeler.md`, writing to [game/scenes/variants/](game/scenes/variants/CONTEXT.md) | the designer's pick on the compare page |
| a test suite, build, mutation or shot script needs running | Rex: `.claude/agents/script-runner.md`, dispatched by the orchestrator, reporting to the orchestrator | its reply (failures go to their owner) |
| a feature or build is ready to test | Quinn: `.claude/agents/qa-build-engineer.md`, writing to [game/](game/CONTEXT.md) `tests/` and `reports/` | the developer plays the build |
| a proposal was accepted | [CONTEXT.md](CONTEXT.md), step 4 (apply) | `python -I _tools/links.py` passes |
| asked for status | `proposals/*/_index.md` and the README TBD list | report what exists |
| a skill gap no agent covers | Martin: `.claude/agents/hiring-manager.md` | the designer reviews the diff |
| at end of day, docs need checking against the day's changes | the `end-of-day` skill runs Doris: `.claude/agents/doc-auditor.md` | her findings: plain corrections fixed in the routine, anything needing a decision listed for the designer |
| asked about agent cost | [_meta/agent-runs.md](_meta/agent-runs.md) | - |
| the designer says "end of work day" | the `end-of-day` skill: `.claude/skills/end-of-day/SKILL.md` (export, decisions, page, checks, commit) | the commit, reported |

## The one rule

Nothing reaches `GDD.md` until the designer has accepted it. Agents propose; they never edit the GDD.
