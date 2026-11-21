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
| Content loop | `voice_check.py` | checks the mechanical voice rules (T5 cited GDD sections, T2 Glossary terms from the GDD and `voice_terms.json`) before Clara; `generate.py` runs it each round |
| Content loop | `critic_check.py` | checks Clara against the known-bad drafts in `fixtures/` |
| Content loop | `test_generate.py` | tests the tools with fake agents |
| Style loop | `style_check.py` | measures the script rules of `STYLE_GUIDE.md` |
| Style loop | `style_loop.py` | runs the visual style loop (Bob → `style_check.py` + Vera → Bob) |
| Style loop | `style_critic_check.py` | checks both evaluators against `fixtures/style/` |
| Votes | `compare_page.py` | builds the A/B comparison and vote pages (`add --versions` for a versions vote) |
| Votes | `model_shots.py` | renders a prop's variants and builds their vote page |
| Votes | `gear_train.py` | generates the Centrifuge Gearing gear train (Gear1 under the crank, the rest on a ring concentric with the lid, unique tooth counts) into a centrifuge variant; refuses overhangs and overlaps |
| Votes | `compose_variant.py` | builds a new round's variant from seen ones (graft, drop, material, move on node paths), no agent; Milo only for new shapes |
| Votes | `pick_match.py` | renders a live prop beside the designer's picked variant (one load, `model_shots.gd --scenes`) and has Vera judge only the match; goal_agent runs it on every spec item naming a pick (`--no-agent` renders only) |
| Votes | `ui_shots.py` | shoots the same UI moments (`game/tests/ui_compare_shots.gd`) in several worktrees for a versions vote |
| Godot | `godot_run.py` | runs the Godot test suites and prints a short summary |
| Godot | `build.py` | exports and zips a version |
| Godot | `mutate.py` | proves tests catch named mutations; a catch by a test already red unmutated (one baseline run) or by a script error is BROKEN |
| Godot | `godot_path.py` | finds the Godot binary for the scripts: `GODOT` env var, else the copy unpacked in the repo folder (gitignored), else the desktop's `C:\Users\mtrem\Desktop\` copy; alone it prints the path in use, with arguments it runs Godot with them (Bob's renders, so no agent or permission rule names a machine's path) |
| Godot | `checkpoint.py` | commits work in progress on the milestone branch with the last unit run's counts in the message; refused off `milestone/*` or during a goal run |
| Godot | `contract_check.py` | checks that every node a script looks up exists in the scenes (pre-commit gate) |
| Godot | `contact_sheet.py` | tiles a shot set into one image |
| Goal agent | `goal_agent.py` | M3: finds a spec's missing goals, scores and orders them (`priority_score()`), and builds them with Patricia, Bob and Quinn (`--plan`, `--dry-run`); fix rounds go to one code owner each and a `scope` check lists files changed outside that owner's folder; each change's test-impact list (`--impact GOAL`) briefs Quinn beside the build and adds the windowed suites it reaches to that step's check, and a finished run runs the full suite (L39); blackboard in `game/reports/goal/` |
| Goal agent | `spec_lint.py` | lints a spec: FAIL on a Quinn line naming several items, WARN on keyword ties, REVIEW pairs where one item restricts a view another asserts (`--item N` after a play-test edit; `--staged` in the pre-commit gate; goal_agent refuses a build on FAIL) |
| Goal agent | `test_goal_agent.py` | tests the reasoning layer on `fixtures/goal/` and the loop with fake agents |
| Usage | `runlog.py` | keeps the run log (`_meta/agent-runs.csv`) and calibrates usage |
| Usage | `log_subagent.py`, `log_session.py` | SubagentStop and Stop hooks that log subagents and the orchestrator |
| Usage | `statusline.py` | saves plan-usage readings |
| Usage | `budget_guard.py` | PreToolUse hook on Agent/Workflow: blocks a new agent when its average logged cost (`budget_guard.py --costs` lists them) would take the 5-hour window past 95%, at 95% of the week, or (heavy agents: 10% or more on average, today general-purpose and Workflow) when the week runs 10 points ahead of pace |
| Rules | `guard_shell.py` | PreToolUse hook on Bash/PowerShell/Write/Edit/Artifact: refuses inline interpreter code, in-place and whole-file rewrites, `cd`/absolute repo paths, writes outside the repo, and any votes page that isn't the one Design Votes artifact |
| End of day | `export_session.py`, `decision_page.py` | serve the end-of-day routine |
