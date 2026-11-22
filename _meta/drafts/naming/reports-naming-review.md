# Naming review: `game/reports/` and nearby folders

Status: draft for the designer (2026-11-21). Nothing renamed yet, because goal_agent run 0.2 writes into `goal/0.2/` and `style/goal-0-2-*`. Apply only after that run ends and the designer picks a target.

## The main problem: `game/reports/` has no organising rule

`game/CONTEXT.md` says reports are `<date>-<slug>.md`. That is true for 4 of about 1,200 files. The top level mixes five ways of grouping:

| Grouped by | Folders |
|---|---|
| Date + slug (the documented rule) | `2026-11-03-prototype-0/`, `2026-11-04-0.1-harvest/`, `2026-11-04-prototype-0-r3/`, `2026-11-05-0.1.2.md` |
| Version + "-shots" | `0.1-shots/`, `0.1.1-shots/`, `0.1.2-shots/`, `0.1.3-shots/` |
| Tool / loop | `goal/`, `style/`, `pick/`, `variants/`, `ui-compare/` |
| One-off round | `round6-shots/` |
| Underscore "internal" | `_runs/` (gitignored), `_look/` (144 files, tracked), `style/_baseline/` |

The same kind of thing, "shots of build X", lives in three places: `0.1.1-shots/`, `ui-compare/0.1.4/` and `2026-11-04-0.1-harvest/`.

## Specific clashes

1. **"r" means at least five things.**
   - `variants/fork-r4`: design round of a prop
   - `style/farm-0-2-0-r3`: hand-named re-run of the style loop
   - `style/goal-0-2-c3-r0`: fix round inside a goal run (`goal_agent.py:880`)
   - `2026-11-04-prototype-0-r3` and the `r4-*.png` files: milestone review round
   - `tests/snapshots/pop-r3-reference`: the build the snapshot came from

   Inside those folders, `round-1/` adds another word for the same idea.
2. **Versions are written three ways:** `0.1.4` (goal, ui-compare, specs), `0-2-0` (style slugs; `goal_agent.py` replaces the dots), and `0.2` without the patch number (ui-compare, goal). `farm-0-1-2` names a version that never had a build of its own.
3. **Dates and run IDs are written four ways:**
   - `2026-11-04-…` (old reports)
   - `_runs/20261121-135945`
   - `goal/0.2/run1.log … run11.log`, then `run-2026-11-21b … f.log`. The scheme changed partway through one folder, and `run10` sorts before `run2`.
   - `_runs/2026-11-21-goal-<run>` (`goal_agent.py:1321`)
4. **Each loop marks a re-run its own way.**
   - Style loop: a new sibling folder (`farm-0-2-0-r2 … -r5`)
   - Content loop: a new file in the same folder (`blackboard-2.md`, `blackboard-3.md`, `blackboard-3-round-1.md`), plus a separate `onboarding-script-v1/` folder
   - Goal: the same folder, with a new log file
5. **Shot filenames have six numbering styles:** `q-01-…`, `b-01-…`, `r4-0-…`, `01-…`, `1-…`, `v2-1-…`, plus some with no number (`lidoff.png`, `zoom.png`). Some names carry the state in CAPS and run past 60 characters.
6. **`ui-compare/` holds four unrelated things:**
   - version snapshots: `0.1.4/`, `0.2/`, `0.1.3-before/`
   - a moving "latest": `now/`
   - Design Votes candidates: `vote-*`, `spin-a/b/c`, `shop-*`
   - loose files: `ab-A.png`, `decisions.json`, `spin-r1-decisions.json`, `0.1.3-merged.png`

   Slider values are baked into folder names (`vote-anchor-down40`, `vote-pan-954`), so nothing groups them into the one vote they belong to.
7. **`_look/` doesn't say what it is.** It holds the lid's "look before done" shots: `lid/`, `lid-before/`, `lid-now/`, plus loose `before-close.png` and `now-side.png`. Like `now/`, the `before`/`now` names lose their meaning once the next change lands. The underscore suggests scratch space, but the files are committed.
8. **The pick and variant folders don't line up.** `reports/pick/uncapping_fork/fork-r4-c.png` uses snake_case `uncapping_fork` where everywhere else says `fork`. `goal_agent.py:1208` writes `pick/<goal-id>-r<N>`, a different pattern. Older variant rounds have no number (`hive-frames`, `flower-patch`) next to `hive-frames-r9`.
9. **Leftovers with no owner:**
   - `2026-11-04-prototype-0-r3/broken-copy-runs/`
   - `.txt` logs mixed in with the shots (`exe_run_rev2.txt`, `export_run1_segfault.txt`)
   - `run_tests_output.txt` and `runs/run_tests.txt`, which do the same job
   - `goal/0.1.4/T14.4-fix-rounds-reverted.diff`

## Other folders (milder)

- **`content/_runs/<slug>/` vs `game/reports/<tool>/<slug>/`:** the same idea (a loop run's blackboard) under two names. `game/reports/_runs/` then means something else entirely: raw gitignored logs.
- **`_meta/sessions/2026-11-05-1f6110f3`** (date + session ID) is clear. It's the model to follow.
- **`game/specs/`** mixes version prefixes (`0.1.3c-node-handoff.md`, `0.1.3-farm-grid-layouts.md`), milestone codes (`m2-style-loop.md`, `m3-goal-agent.md`) and feature names (`prototype-0.md`, `flower-patch-b.md`). Also, `0.1.3c` sorts after `0.1.3-…`.
- **`game/tests/`** mixes `test_*.gd` suites with shot scripts tied to one milestone (`shots_0_1.gd`, `shots_0_1_3.gd`, `round6_shots.gd`, `r4_measure.gd`, `r3_trip.gd`). These created the odd report folders. `retired/` already exists as their place.
- **Repo root:** `convo-bak/`, `GOAL_AGENT.md`, `CREW.md` and `ONBOARDING.md` are missing from the AGENTS.md map. The Godot `.exe` folder also sits at the root.

## Possible target (for discussion)

```
game/reports/
  builds/<version>/          report.md, shots/, logs/   <- milestone reviews (replaces dated + -shots folders)
  goal/<version>/            runs/<YYYY-MM-DD>-<n>.log, blackboard.md, briefs/, gaps.json
  style/<version>-<scene>/   run-<n>/round-<n>/        <- re-run inside, not a sibling suffix
  votes/<vote-id>/<option>/  <- all Design Votes candidates (spin, shop, vote-*, _look/lid)
  variants/<prop>/round-<n>/ pick-<x>.png              <- pick/ folded in
  _runs/                     gitignored raw logs only
```

The rules behind it:
- one word per meaning: `round` = a design or critic round, `run` = re-running a tool, `r` dropped
- versions always `0.2.0` with dots; made safe for filenames only inside scripts
- dates always `YYYY-MM-DD`
- no `now`/`before` folders; use the version or date instead
- content runs follow the same `run-<n>/round-<n>` shape

Open for the designer (ask with the quiz tool):
- Accept this target or adjust it?
- Should `content/_runs/` move to the same shape?
- Should the history be moved, or only new output follow the new names?

**Designer's answers (2026-11-21):** target accepted as drafted (A); `content/_runs/` moves to the same `run-<n>/round-<n>` shape (A); history moved too, in a commit of `git mv` only (A).

## Where the paths are hard-coded (change before moving files)

- `_tools/`:
  - `goal_agent.py` (`reports/goal`, `reports/style`, the slug at line 880, pick at line 1208, runs at line 1321)
  - `style_loop.py`, `ui_shots.py`, `pick_match.py`, `model_shots.py`, `compare_page.py` (`reports/grid-shots`)
  - `godot_run.py` (`_runs`, `_look`), `build.py`, `guard_shell.py` (`_runs`, `ui-compare`)
- Tests: `_tools/test_generate.py`, `_tools/test_goal_agent.py`
- Godot scripts: `game/tests/style_shots.gd`, `ui_compare_shots.gd`, `play_loop.gd` (also names `reports/2026-11-04-prototype-0-r3.md`), `round6_shots.gd`, `shots_0_1.gd`, `shots_0_1_3.gd`, `r3_trip.gd`, `r4_measure.gd`, `snapshot_pop.gd`
- Docs: `game/CONTEXT.md` (the reports rows), `STYLE_LOOP.md`, `GOAL_AGENT.md`, `_tools/CONTEXT.md`, memories (session-handoff, scripted-shots, variant-shots), and blackboards and decision pages that link to old paths

## Order to apply

1. Wait until goal_agent run 0.2 has finished: `python -I _tools/status.py` shows nothing running and `_meta/usage/goal-run.lock` is gone.
2. Get the designer's pick of the target.
3. Change the scripts' path constants and the docs, so new output uses the new names. Run `test_generate.py` and `test_goal_agent.py`, then a Rex shot run.
4. Move the history in a separate commit made only of `git mv`.
5. Run `python -I _tools/links.py` and `consistency.py`, and fix any links that still point at old paths.
6. Update `game/CONTEXT.md` so the reports rule matches what is on disk.
