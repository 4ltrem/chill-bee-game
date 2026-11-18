# Wiring for the operator (proposed, not applied)

**Status: applied 2026-11-18 (designer's yes), except the `_meta/memory/rex-runs-scripts.md` line in section 5, which waits for the desktop pull (memory is frozen until then; `operator/queue.md` #2).**

Original note, kept as written: for the designer's review. Nothing here is applied: `_meta/team.md`, `AGENTS.md` and the memory and agent files named in section 5 are unchanged. Each link is written relative to the file its line goes into, so the lines apply as they stand.

## 1. `_meta/team.md`, Roster table (add after the Rex row)

```
| Oscar | Operator | Main session: routes each task to its owner, waits without spending turns, relays stops and does the mechanical upkeep. Run with `claude --agent operator` | Sonnet | Routing, waiting and upkeep need no judgement. The Opus main session used about 83% of logged tokens, and about half of that sat in routing and waiting. Each job still ends at its owner's check, and Phase 5 compares its cost with Opus sessions | [operator.md](../.claude/agents/operator.md) |
```

## 2. `_meta/team.md`, Roles (add after the Doris line)

- **Oscar, the Operator:** runs as the main session (`claude --agent operator`) for a day's routing, waiting and upkeep: sends each task to the agent or script that owns it, relays the stops in `operator/escalate.md`, and keeps the session handoff and `operator/queue.md` current. He decides nothing and writes none of the owners' output; each owner's output and check reach the designer as before.

## 3. `AGENTS.md`, "Route by task" (add before the "a skill gap no agent covers" row)

```
| a day's routing, waiting or upkeep work (run as the operator) | Oscar: `claude --agent operator` (`.claude/agents/operator.md`), contract [operator/CONTEXT.md](operator/CONTEXT.md) | the owner's check, or a stop handed off per [operator/escalate.md](operator/escalate.md) |
```

## 4. `AGENTS.md`, "Where things live" (add after the `_tools/` row)

```
| [operator/](operator/CONTEXT.md) | the operator's contract, the stops it hands off ([escalate.md](operator/escalate.md)) and the workspace job queue ([queue.md](operator/queue.md)) |
```

## 5. The "orchestrator" wording once the operator also dispatches Rex

The operator is a main session, not a subagent, so Rex's rule against dispatch by another agent still holds. The wording should name both main sessions, since either may now dispatch Rex. Each item is one Edit on the line named:

- `.claude/agents/script-runner.md`, line 3 (description): "Dispatched by the orchestrator, never by another agent." becomes "Dispatched by a main session (the orchestrator or the operator), never by another agent."
- `.claude/agents/script-runner.md`, line 8: "exactly as the orchestrator asks" becomes "exactly as the main session asks".
- `.claude/agents/script-runner.md`, line 17: "Failures go back to the orchestrator, which sends them to the owner" becomes "Failures go back to the main session that dispatched you, which sends them to the owner".
- `.claude/agents/script-runner.md`, line 20: "You are dispatched by the orchestrator or by a `_tools/` script" becomes "You are dispatched by a main session (the orchestrator or the operator) or by a `_tools/` script".
- `_meta/team.md`, line 46 (the Rex role): "exactly as the orchestrator gives them" becomes "exactly as the orchestrator or the operator gives them"; "the orchestrator sends failures to their owners" becomes "the dispatching main session sends failures to their owners"; "Dispatched only by the orchestrator" becomes "Dispatched only by the orchestrator or the operator".
- `_meta/memory/rex-runs-scripts.md`, line 11: "The orchestrator never runs the repo's test, build, mutation or shot scripts itself" becomes "The main session (the orchestrator or the operator) never runs the repo's test, build, mutation or shot scripts itself". Add one sentence: checkpoint.py and links.py are not on Rex's list, so the operator's Bash runs them.
- Leave the "orchestrator" cells in the `_meta/team.md` Rework tally as they are: they record who fixed a bug at the time.

## 6. Optional: `_meta/team.md`, Model reviews table (add a row)

| Oscar (Sonnet) | the designer, and the Phase 5 comparison with Opus sessions | routing misses that cost rework, or a stop that should have been handed off | the Orchestrator rows in `_meta/agent-runs.csv` |
