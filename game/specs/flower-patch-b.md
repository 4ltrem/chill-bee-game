---
author: orchestrator
type: spec
status: approved
decided: 2026-11-05, designer: "do the M2 tail flower patch" (flower-patch B, voted yes on Design Votes)
version: m2 tail
description: Promote Milo's flower-patch B into the game prop; flower_patch.gd colours its blossoms per instance
---
# Flower patch B

**Builds on** `game/specs/m2-style-loop.md` (item 11, Milo's variants) and `game/specs/0.1-harvest.md` ("Models as reusable scenes"). Process: `game/CONTEXT.md`. Branch `m2/flower-patch` (worktree `.claude/worktrees/flower-patch`), from `milestone/m2`. One step; one checkpoint commit when green.

**Do not touch** (the 0.1.3 build runs in parallel in another session): `game/scenes/main.tscn`, `hive.tscn`, `centrifuge*`, camera scripts, `run_tests.gd`, `game/specs/0.1.3-*`, `.claude/worktrees/0.1.3` and `.claude/worktrees/ab-centrifuge`.

## Changes

1. **Promote B.** `game/scenes/props/flower_patch.tscn` becomes `game/scenes/variants/flower-patch/flower-patch-b.tscn` (base disc, five stems, five blossom heads, one tall), with the contract below. The variant file stays as history.
2. **Per-instance colour.** `main.tscn` sets `color` (pink, lilac, buttercup) and `radius` (0.9, 0.8, 0.7) on its three patches. `flower_patch.gd` applies:
   - `color` to every blossom head, as a per-instance `material_override` (a new `StandardMaterial3D`). The shared `materials/flower_default.tres` is never modified.
   - `radius` as the patch size: 0.9 is the authored size. With k = `radius / 0.9`, the `Base` disc is scaled k in x and z, and every stem and blossom keeps its mesh but has its x and z position multiplied by k (heights and blossom shapes unchanged). The root's own transform is never written (main.tscn owns it).
3. **Leaf material (V1).** B's inline leaf green becomes `game/materials/leaf.tres`, albedo (0.62, 0.84, 0.52) (Meadow / ground token), used by the base and the stems.
4. **Ground.** The prop's origin is on the ground (y = 0), as for every variant. `main.tscn` still places the patches at y = 0.15 (the old centred cylinder), so they float 0.15 until a follow-up sets those three lines to 0. That follow-up waits until 0.1.3 is merged (it owns `main.tscn`); no build is exported from this branch before then.
5. **Config and Dev mode** (Process 3): no new values. Colour and radius are scene data per patch, not tunables.

## Contract (node names)

- Root `FlowerPatch` (Node3D), script `res://scripts/flower_patch.gd`, group `flower_patch` (bees find patches by this group, `bees.gd`).
- `Base` (MeshInstance3D): the leaf disc.
- `Stems` (Node3D) holding the stem meshes.
- `Blossoms` (Node3D) holding every blossom head (MeshInstance3D children; no other children).
- `PatchMesh` is removed; nothing may look it up.

## Tests (Quinn, from this spec)

Added to `game/tests/test_economy.gd` (where the props contract lives), so `run_tests.gd` is not touched:
- the prop scene has the contract nodes and is in group `flower_patch`; it has no `PatchMesh`;
- in `main.tscn`, every blossom of each patch shows that patch's `color` (± 0.01 per channel), and the three patches differ;
- `flower_default.tres`'s albedo is unchanged after main loads;
- with k = radius / 0.9: each patch's `Base` x/z scale is k (± 0.01), each blossom's x/z position is k × its authored position in `flower_patch.tscn` (± 0.01), and every y position and blossom scale is unchanged;
- the bees still find 3 patches;
- every material colour in the prop is near a palette token (`_tools/style_check.py` rule or a direct check);
- a mutation in `tests/mutations.json` proves the colour test (e.g. the script skips the override).
