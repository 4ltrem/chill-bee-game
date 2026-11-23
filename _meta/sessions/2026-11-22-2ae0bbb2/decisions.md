---
session: 2ae0bbb2
dates: 2026-11-21 to 2026-11-21
transcript: session.jsonl (this folder, gitignored)
description: A6 wrap-up: the NEXT commit, the A6 link and the r5 style patch (already D239), the flaky camera pan test, the milestone/0.2 push; logged after the fact on 2026-11-23 from `_tools/session_digest.py`
---
# Decisions: session 2ae0bbb2 (2026-11-21 to 2026-11-21)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

Logged on 2026-11-23, after D269, so these IDs are later than their dates. The A6 link (`STYLE_LOOP.md`, still approved) and the r5 `sandbox.patch` without `jar.tscn` ("b, skip the jar part") were made here and are already D239.

## Decisions

### D270 · 2026-11-21 · Game build · The flaky camera pan test gets a lower and an upper bound
- Decided: the designer sent the flaky `t_camera_pan_seconds` in the style loop's test gate to Quinn ("send 4"). He changed only `game/tests/test_camera.gd`: the measured pan time has both bounds, so a long frame under load can't fail it while a wrong-length pan still does; it follows `--time-scale 6`. Rex ran both camera pan tests 3 times, 3 of 3 green.
- Why: a load spike failed the style loop's unit gate on a correct game.
- Files: `game/tests/test_camera.gd`

### D271 · 2026-11-21 · Records & deliverables · milestone/0.2 pushed for A6
- Decided: "yes push it": `milestone/0.2` (29 commits ahead, full suite green) pushed with the r5 patch and the pan fix. Later the same night the branch was merged into `main` and deleted (D250).
- Why: the A6 link points at the repository.

## Still open

- None from this session.
