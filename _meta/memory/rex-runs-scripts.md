---
name: rex-runs-scripts
description: "Test, build, mutation and shot scripts (godot_run, build, mutate, ui_shots, lid_shots) go to Rex (script-runner, Haiku), not the main session's own Bash and not Quinn"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 28475ef9-e95c-4529-bb2f-7df1fc9c11f8
  modified: 2026-11-08T23:15:39.501Z
---

The orchestrator never runs the repo's test, build, mutation or shot scripts itself. It dispatches Rex (`.claude/agents/script-runner.md`, Haiku) with the exact command, and Rex returns counts, failing names, log paths and first error lines. The goal agent's own `run_cmd` checks are the script's, not the orchestrator's, and stay as they are.

**Why:** the designer, 2026-11-08: "rex is supposed to run scripts", after the main session ran `godot_run.py unit` and a CB_ONLY lid test itself and had Quinn run `lid_shots.gd`. The roster (`_meta/team.md`) moved execution to Haiku because suite runs and log reading on Sonnet took 21% of plan usage on 2026-11-04.

**How to apply:** for any `godot_run.py`, `build.py`, `mutate.py`, `ui_shots.py`, `pick_match.py --no-agent` or Godot shot run, send Rex the command (inline env, repo-relative paths, Bash) and read back only its summary. Quick non-Godot checks (`links.py`, `consistency.py`, the Python unit tests of `_tools/`) are not on Rex's list. Since 2026-11-08 evening ("delegate any scripts to rex to keep this session slim") the shot follow-ups go to Rex too: `contact_sheet.py`, worktree setup + `godot_run.py --refresh`, `compare_page.py add`; the orchestrator only views the final images and publishes. Rex refuses a raw Godot `-s` call (e.g. `lid_shots.gd`): it needs a repo script route (a `lid` suite in `godot_run.py`) or an explicit go-ahead in the brief. Related: [[cost-rules]], [[model-routing]], [[prefer-bash]].
