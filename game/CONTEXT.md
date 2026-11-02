# game - the Godot project (Patricia, Bob, Quinn)

One job: turn applied designs into a running Godot game. Godot 4.2.1 (standard build, GDScript), Compatibility renderer, portrait; `scenes/main.tscn` is a placeholder bootstrap scene with the isometric camera.

| Folder | Agent | Holds |
|---|---|---|
| `scripts/` | Patricia, the Programmer | GDScript (and C# where the GDD calls for it) components and backend integration |
| `scenes/` | Bob, the Builder | `.tscn` biome dioramas and terrain chunks, one folder per biome |
| `assets/` | developer | purchased low-poly packs and selected audio; agents read, never add |
| `tests/` | Quinn, the QA & Build Engineer | automated tests |
| `reports/` | Quinn, the QA & Build Engineer | `<date>-<slug>.md` test, build and performance reports |

## Inputs
- Working (this run): the feature list, layout spec or build request
- Reference (every run): `../GDD.md` (Engine Integration, Technical Constraints, plus the sections the task touches)
- Reference (when cited): `../proposals/design/_index.md` and `../proposals/balance/_index.md`, then only the applied proposals they name

Do NOT load: the review folders, `_meta/agent-runs.md`, proposals still `proposed` or `rejected`.

## Process
1. Build only what the GDD or an applied proposal specifies. If the spec is ambiguous, stop and list the questions.
2. Patricia writes scripts, Bob writes scenes that attach those scripts by path, Quinn tests both. No agent edits another agent's folder.
3. TBD balance values stay as marked placeholders in exported variables or config resources.

## Outputs
- scripts, scenes and tests -> their folders above
- `<date>-<slug>.md` -> `reports/`

## Check
Quinn's report passes (tests green, 60 FPS on the test devices), then the developer reviews the git diff and plays the build.
