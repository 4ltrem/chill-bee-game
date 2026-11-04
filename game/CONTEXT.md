# game - the Godot project (Patricia, Bob, Quinn)

One job: turn applied designs into a running Godot game. Godot 4.2.1 (standard build, GDScript), Compatibility renderer, portrait; `scenes/main.tscn` is the Prototype 0 farm scene (hive, flowers, centrifuge, crate, truck and farm UI) under the isometric camera.

| Folder | Agent | Holds |
|---|---|---|
| `specs/` | the designer (with Claude) | work orders: scope, the script/scene contract, placeholder values |
| `scripts/` | Patricia, the Programmer | GDScript (and C# where the GDD calls for it) components and backend integration |
| `scenes/` | Bob, the Builder | `.tscn` biome dioramas and terrain chunks, one folder per biome |
| `assets/` | developer | purchased low-poly packs and selected audio; agents read, never add |
| `tests/` | Quinn, the QA & Build Engineer | automated tests |
| `reports/` | Quinn, the QA & Build Engineer | `<date>-<slug>.md` test, build and performance reports |

## Inputs
- Working (this run): the work order in `specs/` (e.g. `specs/prototype-0.md`), or the feature list, layout spec or build request
- Reference (every run): `../GDD.md` (Engine Integration, Technical Constraints, plus the sections the task touches)
- Reference (when cited): `../proposals/design/_index.md` and `../proposals/balance/_index.md`, then only the applied proposals they name

Do NOT load: the review folders, `_meta/agent-runs.md`, proposals still `proposed` or `rejected`.

## Process
1. Build only what the GDD or an applied proposal specifies. If the spec is ambiguous, stop and list the questions.
2. Patricia writes scripts, Bob writes scenes that attach those scripts by path, Quinn tests both. **Tests come from the spec, not the code** (designer, 2026-11-04): Quinn writes them from the approved spec in parallel with Patricia, without reading her in-progress code, and every expected number is read from the config. A test that fails then is a finding against the code or the spec, never a reason to change the test to match the code. No agent edits another agent's folder.
3. TBD balance values stay as marked placeholders in exported variables or config resources. Every tunable value lives in the config (never a literal in a script), is read when used rather than cached, and is adjustable live in the in-game **Dev mode** panel (`scripts/dev_panel.gd`). Every spec includes Dev mode and adds its new values to it (designer, 2026-11-04).
4. **Steps, not batches** (designer, 2026-11-04). A milestone's spec is built in small steps, each ending green and playable (e.g. 0.1a refactor with no behaviour change, 0.1b, 0.1c). Work happens on a `milestone/<version>` branch with a checkpoint commit after each green step, so each agent's diff can be reviewed and one step undone without losing the others; the end-of-day routine merges the branch into `main` when the milestone is done. The designer plays the build at the end of each step, not only at the end of the milestone.
5. **Contract and parallel start.** Node names are the contract between Patricia and Bob. The spec names them, including inside prop scenes; when Patricia must confirm or adjust them, she writes that section first, as its own short handoff, and Bob starts from it while she writes the scripts. `python -I _tools/contract_check.py` checks every `find_child`, `get_node`, `$` and `%` lookup and every scene `NodePath` against the scenes, without Godot; it runs in the pre-commit gate, and Bob and Patricia run it before handing off.
6. **Visual checks before Quinn.** Bob renders a fixed shot set: one screenshot per state in the spec's state table plus any new view, not only the starting state. The style evaluator (the A6 style guide agent, milestone M2) compares the shots with the spec and the style guide, and Bob refines until it passes; until M2 exists, the orchestrator reviews the shots.
7. **Snapshot tests for "do not change".** Whatever the designer marks as not to change (e.g. the comb pop) gets reference frames recorded once from the last approved build and compared on every build (pixel tolerance stated in the spec), not only its parameters.
8. **Fixes.** The owner of the folder fixes its bugs: Patricia `scripts/`, Bob `scenes/`, Quinn `tests/`. The orchestrator (the main session) may fix a bug itself only when the diagnosis is certain and the fix is a few lines; anything larger goes back to the owner with Quinn's report. Whoever fixes it, every fix is recorded: a **Fixes** section in the report names the bug, its owner and who fixed it, the bug is counted in the Rework tally in `../_meta/team.md`, and Quinn's tests are re-run before any build is exported.

## Outputs
- scripts, scenes and tests -> their folders above
- `<date>-<slug>.md` -> `reports/`

## Check
Quinn's report passes (tests green, 60 FPS on the test devices), then the developer reviews the git diff and plays the build.
