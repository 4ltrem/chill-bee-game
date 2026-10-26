# Chill Bee Game - the design loop

The flow in one line: the designer asks, an agent proposes, the designer decides, the decision lands in the GDD.

| Step | Who | Job |
|---|---|---|
| 1. Request | designer | name the question and the agent (`gameplay-architect`, `progression-tree-expert`, `compliance-officer`; roster in `_meta/team.md`) |
| 2. Propose | agent | copy `_templates/proposal.md` into `proposals/<type>/`, `status: proposed` |
| 3. Decide | designer | read the proposal; accept, change or reject. This is the check |
| 4. Apply | designer + agent | edit the accepted decisions into `GDD.md`, update the README TBD list, set `status: applied` (or `rejected`) |
| 5. Log | agent | add the run's tokens, tool calls and duration to `_meta/agent-runs.md`, phase `post-ICM` |
| 6. Verify | script | `python -I _tools/index.py proposals/design proposals/balance` then `python -I _tools/links.py` |

Each shelf's own `CONTEXT.md` holds its inputs, outputs and check.

Factory (stable, every run): `GDD.md`, `_templates/`, `.claude/agents/`, `_meta/team.md`
Product (new each run): one file per proposal under `proposals/`

Status is on disk: each proposal's `status:` line (`proposed`, `applied`, `rejected`, `superseded`), rolled up in the generated `proposals/*/_index.md`. Open game questions live only in the README's Outstanding TBDs list.

Review rounds (`gdd-review/`, `gdd-review-v2/`) come from the external gdd-review-kit and keep its folder names on purpose (owner's call); they are history, never edited, and the GDD snapshot inside each is what was reviewed.
