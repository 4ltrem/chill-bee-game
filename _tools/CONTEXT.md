# _tools - the workspace scripts

Run them with `python -I _tools/<name>.py` (except `contact_sheet.py`, which needs Pillow: run without `-I`).

| Area | Script | What it does |
|---|---|---|
| Docs | `links.py` | checks every link and input path |
| Docs | `index.py` | rebuilds `_index.md` (`--decisions` prints the ledger) |
| Docs | `sync_docs.py` | writes the docs' generated sections |
| Docs | `consistency.py` | checks docs against code (run by the `.githooks/pre-commit` gate) |
| Docs | `doc_audit.py` | runs Doris on the day's changes |
| Content loop | `generate.py` | runs the content loop |
| Content loop | `critic_check.py` | checks Clara against the known-bad drafts in `fixtures/` |
| Content loop | `test_generate.py` | tests the tools with fake agents |
| Style loop | `style_check.py` | measures the script rules of `STYLE_GUIDE.md` |
| Style loop | `style_loop.py` | runs the visual style loop (Bob → `style_check.py` + Vera → Bob) |
| Style loop | `style_critic_check.py` | checks both evaluators against `fixtures/style/` |
| Votes | `compare_page.py` | builds the A/B comparison and vote pages (`add --versions` for a versions vote) |
| Votes | `model_shots.py` | renders a prop's variants and builds their vote page |
| Votes | `ui_shots.py` | shoots the same UI moments (`game/tests/ui_compare_shots.gd`) in several worktrees for a versions vote |
| Godot | `godot_run.py` | runs the Godot test suites and prints a short summary |
| Godot | `build.py` | exports and zips a version |
| Godot | `mutate.py` | proves tests catch named mutations |
| Godot | `contract_check.py` | checks that every node a script looks up exists in the scenes (pre-commit gate) |
| Godot | `contact_sheet.py` | tiles a shot set into one image |
| Goal agent | `goal_agent.py` | M3: finds a spec's missing goals, scores and orders them (`priority_score()`), and builds them with Patricia, Bob and Quinn (`--plan`, `--dry-run`); blackboard in `game/reports/goal/` |
| Goal agent | `test_goal_agent.py` | tests the reasoning layer on `fixtures/goal/` and the loop with fake agents |
| Usage | `runlog.py` | keeps the run log (`_meta/agent-runs.csv`) and calibrates usage |
| Usage | `log_subagent.py`, `log_session.py` | SubagentStop and Stop hooks that log subagents and the orchestrator |
| Usage | `statusline.py` | saves plan-usage readings |
| Usage | `budget_guard.py` | PreToolUse hook on Agent/Workflow: blocks a new agent when its largest logged cost would take the 5-hour window past 95%, at 95% of the week, or (Bob, Patricia, Quinn) when the week runs 10 points ahead of pace |
| End of day | `export_session.py`, `decision_page.py` | serve the end-of-day routine |
