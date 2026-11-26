---
author: orchestrator
type: plan
status: done
description: Plan for _tools/model_snap.py, the reusable dummy-scene snapshot script of 0.3.2 spec item 14 (upgrade icons as PNGs from existing models); tooling, built by a fresh session
---
# Plan: `model_snap.py`

## Goal and done

As the designer, I want one reusable script that loads any `.tscn` into a dummy scene (neutral background, the farm's camera angle and light, the model fitted to the frame), optionally puts it in an upgrade's state, and writes a PNG, so that the upgrade rows get real icons from the models we already have (spec `game/specs/0.3.2-tests-and-quick-buy.md` item 14), and vote shots, Journal pictures and the quick-buy icon can reuse it later.

Acceptance criteria:

1. `python -I _tools/model_snap.py res://scenes/props/truck.tscn --out game/reports/snaps/truck.png` writes a square PNG of `--px` pixels (default 288, twice the 144 px tile of `game/scripts/preview_tile.gd:11`), the model filling it with a margin, and exits 0; a missing scene, a failed save, a wrong size or an empty image (model covers under 2 % of pixels) exits 1 with one line saying which.
2. `--set Node:prop=JSON` and `--call Node:method=JSON-array` change the loaded model before the shot (path relative to the scene root, `.` = root); a node, property or method that does not exist exits 1 naming it (never a silent plain shot).
3. `--fit NodePath` fits the camera to that node's bounds while the rest of the scene stays drawn (e.g. the centrifuge's `Spigot`); `--hide A,B` hides nodes as `model_shots.gd --hide` does.
4. `--bg transparent` (default) writes alpha (the tile's white sheet is the neutral background); `--bg R,G,B` (0–1) writes an opaque colour.
5. `--recipe upgrades` reads `_tools/snap_recipes.json` and writes `game/assets/icons/upgrades/<id>.png` for the five upgrades with a model (spec item 14: `heated_fork`, `gearing`, `spigot_flow`, `faster_delivery`, `plant_patch`) in ONE Godot launch; every recipe id must be a key of `PreviewTile.FILES` (`preview_tile.gd:12-15`) or the script exits 1 before rendering. Heated Fork is shot heated (head at crank orange).
6. PNGs written under `game/` get their Godot `.import` files (an import pass after the shots), so `load("res://assets/icons/upgrades/<id>.png")` works for the goal run's item 14 `TextureRect`.
7. The hook treats `model_snap.py` as a Rex script (L21): `guard_shell.py`'s `REX_SCRIPTS` names it, Rex's definition lists it, `_tools/CONTEXT.md` has its row.

Not in this plan: swapping `PreviewTile` from `SubViewport` to `TextureRect`, hiding the three model-less tiles, and Milo's vote. Those are spec items 7 and 14 for `goal_agent.py`.

## Read first

- `game/specs/0.3.2-tests-and-quick-buy.md` item 14 (line 74): what the script is for; item 7 for the preview tiles.
- `game/tests/model_shots.gd` (200 lines): the staging to copy.
  - `:41-54` `_bounds()`: merged AABB of visible visuals, copy as is.
  - `:101-118` reads the farm's `WorldEnvironment`, `Sun` and `Camera3D` basis/projection from `res://scenes/main.tscn` and frees it: copy (never edit `main.tscn`).
  - `:158-159` wait 3 frames so a prop's `_ready` rescale settles; `:160-165` `--hide`.
  - `:172-186` camera-space fit of the 8 box corners, ortho size with 1.15 margin, camera 20 units back, 5 frames + `frame_post_draw`: copy, with aspect 1.0 (square).
  - `:196-200` print `COMPLETED`, `quit(0)`; `_fail` at `:36-38`.
- `_tools/model_shots.py:1-48`: the Python wrapper shape (docstring usage, `sys.path` insert for `-I`, `from godot_path import GODOT`, `subprocess.run(..., timeout=300)`, "COMPLETED" check, last 8 lines on failure).
- `game/scripts/preview_tile.gd`: `FILES` ids (`:12-15`) and the current in-game `SubViewport` camera (`:44-51`), which the PNG replaces.
- `game/scripts/uncap_fork.gd:14-15` (`heated_level_override`), `:43-44`, `:116-126` (`_apply(blend)` sets the head colour toward `hot_color`; `_head_material` is set up in `_ready`).
- Props: `game/scenes/props/uncapping_fork.tscn` (root `Fork`), `centrifuge_gears.tscn`, `centrifuge.tscn` (`Spigot` at `:100`, `SpigotJar` `:104`), `truck.tscn`, `flower_patch.tscn`.
- `_tools/guard_shell.py:133-134` (`REX_SCRIPTS`), `_tools/test_generate.py:1051-1056` (the Rex guard test to extend).
- `.claude/agents/script-runner.md:13` (Rex's script list), `_tools/CONTEXT.md:20` (the Votes rows).
- `_meta/learnings.md` L21 (scripts in Rex's shell), L57 (a vote stop ignored: this plan makes no vote), and memories `test-speed-fixes`, `look-before-done`, `edit-lines-only`.

## Tasks

Owners: script work goes to a general-purpose subagent with `model: sonnet`; the agent-definition line goes to Martin (`hiring-manager`). Each brief carries only its task's rows below.

**T1 `game/tests/model_snap.gd`** (new, SceneTree script). Args after `--`: `--jobs=<ABS json>` only (the Python side writes the job list; one launch, many shots). Each job: `scene` (res://), `out` (ABS png), `px`, `fit` (node path or ""), `hide` (list), `set` (list of `[path, prop, value]`), `call` (list of `[path, method, args]`), `bg` ("transparent" or `[r,g,b]`). Per job: a `SubViewport` of `px × px` (`own_world_3d`, `transparent_bg` when transparent, `UPDATE_ALWAYS` while shooting), holding the farm's environment (for an opaque `bg`, a duplicate of it with `background_mode = BG_COLOR`; for transparent, `BG_CLEAR_COLOR` + transparent viewport), the farm's sun, an ortho camera with the farm's basis, and the instanced scene. No ground, no grid. After 3 frames apply `hide`, `set` (`node.get(prop)` must not be null via `prop in node`, else `_fail`), `call` (`has_method` else `_fail`), wait 2 frames, fit to `fit` node (or the root) as `model_shots.gd:172-183` with aspect 1, wait 5 frames + `frame_post_draw`, `vp.get_texture().get_image()`, count pixels that differ from the background (alpha > 0.1 when transparent), save PNG, print `shot <out> <w>x<h> coverage=<0..1> err=<n>`. Free each job's viewport before the next. `COMPLETED` only when every job saved. Copy: `model_shots.gd:36-54, 101-118, 158-186, 196-200`. Pitfalls: a `SubViewport` must be in the tree to render (add it under `root`); headless rendering draws nothing, so the window must not be `--headless` (as `model_shots.py`); `_apply` needs `_head_material` from `_ready`, so `call` runs after the 3 frames. Proof command (Rex): AC1 command below.

**T2 `_tools/model_snap.py`** (new). CLI: `SCENE --out PATH [--px 288] [--fit NODE] [--hide A,B] [--set N:prop=JSON]... [--call N:method=JSON]... [--bg transparent|R,G,B]`, or `--recipe NAME` (reads `_tools/snap_recipes.json`). Builds the job list (OUT made absolute; refuses an `--out` outside the repo), writes it to a temp file in `game/reports/snaps/_jobs.json`, runs Godot like `model_shots.py:42-48` (`--resolution 720x1280 --position 0,0 -s res://tests/model_snap.gd -- --jobs=...`), then checks each PNG with stdlib only: exists, IHDR width/height = px (`struct` on bytes 16-24), coverage from the Godot line ≥ 0.02. For `--recipe upgrades`: before rendering, parse `FILES` keys from `game/scripts/preview_tile.gd` with a regex and refuse any recipe id not in them. After any PNG under `game/`, run the import pass: `[GODOT, "--headless", "--path", game, "--import"]` (Godot 4.2.1, `project.godot:17`, `godot_path.py:14`), then check `<png>.import` exists. Delete each target PNG (and its `.import`) before rendering so a stale file can't pass the checks; create the out folder (`game/assets/icons/` does not exist yet); delete `_jobs.json` after the run. Exit 0 only when all pass. Copy `model_shots.py:1-48`. Proof (Rex): AC1 and AC5 commands.

**T3 `_tools/snap_recipes.json`** (new; same subagent as T2, same checkpoint, so it owns both files). `{"upgrades": {"out_dir": "game/assets/icons/upgrades", "px": 288, "shots": [...]}}` with:
- `heated_fork`: `res://scenes/props/uncapping_fork.tscn`, set `[".", "visible", true]` (`uncap_fork.gd:26` hides the fork in `_ready`; `_bounds` skips hidden nodes), call `[".", "_apply", [1.0]]` (sticks: `_process` returns early when not dragging, `:114`);
- `gearing`: `res://scenes/props/centrifuge_gears.tscn`;
- `spigot_flow`: `res://scenes/props/centrifuge.tscn`, fit `Spigot`;
- `faster_delivery`: `res://scenes/props/truck.tscn`;
- `plant_patch`: `res://scenes/props/flower_patch.tscn`.

**T4 `_tools/guard_shell.py` + `_tools/test_generate.py`** (one general-purpose task, both files): add `model_snap` to the `REX_SCRIPTS` alternation (`guard_shell.py:134`) and its docstring line (`:24-25`); add `"python -I _tools/model_snap.py --recipe upgrades"` to the list at `test_generate.py:1052-1053`. Proof: `python -I _tools/test_generate.py` green.

**T4b `game/.gitignore`** (same subagent as T5): add `reports/snaps/` under the `reports/_runs/` line.

**T5 `_tools/CONTEXT.md`** (lead may brief a cheap subagent): one row after `:20`, Votes area: "`model_snap.py` | shoots any scene in a dummy scene (farm camera angle and light, fitted, transparent or flat background) to a square PNG, with `--set`/`--call` for an upgrade's state and `--fit` for a part; `--recipe upgrades` writes the upgrade icons to `game/assets/icons/upgrades/` (Rex runs it)".

**T6 `.claude/agents/script-runner.md:13`** (Martin): add `_tools/model_snap.py` after `_tools/model_shots.py` in the list.

Parallel: T1, T2+T3, T4, T4b+T5 in checkpoint 1 (no file shared). T6 waits for checkpoint 2 only to keep Martin's run after the script is proven (it is one line; it may also go in checkpoint 1 if budget allows).

## Checkpoints

**CP1: the script shoots one scene.** T1, T2+T3, T4, T5 in one message. Check:
- lead: `python -I _tools/test_generate.py`, `python -I _tools/links.py`, `python -I _tools/consistency.py` all green;
- Rex: `python -I _tools/model_snap.py res://scenes/props/truck.tscn --out game/reports/snaps/truck.png` exits 0, line `288x288 coverage=` ≥ 0.02;
- lead looks at `game/reports/snaps/truck.png` (Read the image): whole truck, centred, farm angle, transparent around it.
Commit (stage by path: the four new/changed tool files, `_tools/CONTEXT.md`; not `game/reports/snaps/`).

**CP2: the upgrade icons.** T6. Rex: `python -I _tools/model_snap.py --recipe upgrades` exits 0; five PNGs and five `.png.import` in `game/assets/icons/upgrades/`. Lead looks at each of the five (look-before-done): heated fork's head orange, spigot framed with the tap readable, nothing clipped. Commit the PNGs, their `.import` files and `script-runner.md`.

## How to run it

- The lead (main session) reads this whole plan and writes no code.
- At each checkpoint, launch every parallel task as a subagent in one message. Each brief names its task, its files only, the quality bar (edit-lines-only: change only the needed lines; new files written whole), a reply of at most 150 words with the files changed and the command result, and forbids git.
- Only the lead runs the checks, commits and updates **Progress**. Commits on `main` through the pre-commit gate, never `--no-verify`; stage by path.
- Every `model_snap.py` run goes to Rex (`script-runner`), which the hook enforces once T4 lands; before T4 lands, still send it to Rex. Godot test runs, if any, with `--time-scale 6` (test-speed-fixes). Tooling tests the lead runs by path with `python -I`, never inline Python.
- The goal-run lock: if `_meta/usage/goal-run.lock` exists, the 0.3.2 run is live; stop and ask the designer (CP2 writes into `game/`).
- Anything unplanned is written into this plan before anyone builds it. Something that broke gets an L-number in `_meta/learnings.md`.
- If the context is half full after a checkpoint, write the next checkpoint into **Progress** and stop for a fresh session.

## Proof

For each criterion, the test and the one-line breaking edit that must make it fail:

| AC | Test | Breaking edit (then revert with the exact inverse Edit) |
|---|---|---|
| 1 size | CP1 Rex command, IHDR check | `model_snap.gd`: `vp.size = Vector2i(px, px)` → `Vector2i(px, px / 2)`: exits 1 "size" |
| 1 empty | same | `model_snap.gd`: after instancing, add `model.visible = false`: exits 1 "coverage" |
| 2 | `--set .:no_such_prop=1` on the fork (Rex) | none needed: the command itself must exit 1 naming `no_such_prop` |
| 3 | `--fit NoSuchNode` on the centrifuge (Rex) | none needed: must exit 1 naming the node |
| 4 | Rex: truck with `--bg 0.95,0.95,0.95`; lead views: flat grey, no alpha | `model_snap.gd`: ignore `bg` (always transparent): lead sees alpha, criterion fails |
| 5 | `--recipe upgrades` | `snap_recipes.json`: `gearing` → `gears`: exits 1 before rendering, naming `gears` |
| 6 | `.import` check | `model_snap.py`: comment out the import call: exits 1 "no .import" |
| 7 | `test_generate.py` guard test | `guard_shell.py:134`: remove `|model_snap`: the new case fails |

Whole build: `python -I _tools/test_generate.py`, `python -I _tools/links.py`, `python -I _tools/consistency.py`; the pre-commit gate on each commit.

At the end: apply each breaking edit, confirm the failure, revert it with the exact inverse Edit (never `git checkout` or a reset). Before each commit, check the actual files, not the subagents' reports. Commit only when every check passes (fix-needs-commit).

Real entry point: the designer's use is `python -I _tools/model_snap.py --recipe upgrades` (through Rex). Run it once more after the reverts and confirm the five icons are unchanged and `python -I _tools/model_shots.py` still runs for an existing round (Rex: `model_shots.py hive-frames --unnumbered --no-render`), since both copy the same staging.

## Progress

- 2026-11-26: plan written. The planner's step-7 review (a fresh subagent answering: serves the goal, complete, safe, buildable first time) was **not run**: the budget guard blocked the general-purpose agent (week 88%, ahead of pace). **First step of the running session:** run that review (after the 11/28 reset or with the designer's `budget_guard.py --allow-for 60`), especially on: Godot's `--import` flag for the version in use, `SubViewport` with `transparent_bg` in a SceneTree script, and whether `_apply(1.0)` alone shows the heated head. Write its findings here before CP1.
- 2026-11-26: review run (the designer allowed agents). Findings, checked by the lead and written into the tasks above: the fork hides itself in `_ready` (recipe now sets `visible`); `_apply(1.0)` alone keeps the heated colour (`heated_level_override` dropped); Godot is 4.2.1 and has `--import` (fallback dropped); stale PNGs deleted before shooting; `game/assets/icons/` created; `reports/snaps/` gitignored (T4b); no gate (`pre-commit`, `consistency.py`, `contract_check.py`, `links.py`) needs a change for the new files. **Still to do in CP1, before T1's full build:** a spike, with Rex shooting one scene through a `SubViewport` under `root` (GL Compatibility, `transparent_bg`, `own_world_3d`, ortho camera `current = true`, `msaa_3d` set, a `process_frame` after `add_child`), to prove that it renders at all. `model_shots.gd:187` reads the root window, not a child viewport. If it doesn't render, shoot the root window at `px × px` (`--resolution`) instead. **Check in CP2:** that gearing, spigot and truck draw something at level 0 (`centrifuge.gd:580` hides gears by level, `:627` honey, `:656` the jar). If one is empty, add `set`/`call` rows to its recipe.
- 2026-11-26: CP1 built (T1-T5; T4b/T5 also done). First truck run: the PNG was written in seconds, but the import pass hung 300 s: Godot 4.2.1 has no `--import` (L58). The import pass is now `--headless --editor --quit-after 1500` (as `godot_run.py:208`). The SubViewport spike passed: the truck PNG renders whole and centred at the farm angle. Then `.import` was missing for `game/reports/snaps/truck.png` because `game/reports/` holds a `.gdignore`; the `.import` check now covers only PNGs Godot imports (`imported()`). AC1 passes (exit 0, 288×288 RGBA). CP1 committed (`9547163`). CP2: T6 done; recipe run wrote 5 PNGs + `.import`. Lead's look: fork orange, gears, truck, patch fine; `fit: Spigot` gave a grey cylinder filling the frame (no tap readable), so the designer picked the whole centrifuge (2026-11-26): the recipe drops `fit`. `--fit` itself stays (AC3). CP2 committed (`da961cc`).
- 2026-11-26: Proof done. Every breaking edit failed as listed (AC1 size "(288, 144)", AC1 empty "coverage 0.0", AC2 "no property no_such_prop on .", AC3 "no fit node NoSuchNode", AC4 corner (243,243,243,255) vs transparent (0,0,0,0), AC5 "recipe id 'gears'", AC6 "no .import for …", AC7 test_generate error) and was reverted by inverse Edit. The final recipe run gave byte-identical PNGs; `model_shots.py hive-frames --unnumbered --no-render` still runs. **Follow-up (not built):** deleting each `.import` before a run gives the icons new UIDs every run (restored to the committed ones); keep the `.import` and check the PNG instead, before anything references the icons by UID.
