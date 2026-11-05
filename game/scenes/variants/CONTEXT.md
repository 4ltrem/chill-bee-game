# game/scenes/variants - colorbox prop variants (Milo, the Modeler)

One job: a few colorbox takes on each model (prop) requested, for the designer to pick from on a compare page. Each variant is a primitive-only `.tscn` in the approved palette. The picked variant is promoted by Bob into `game/scenes/props/`; the rest stay here as history.

## Inputs
- Working (this run): the request, which names the prop, its footprint in cells (cell size 2.0), and the variant count (default 3)
- Reference (every run): one existing prop scene from `../props/` named in the request
- Reference (every run): `../../../STYLE_GUIDE.md` (V1 to V6, palette tokens), and the material files in `../../materials/`

Do NOT load: `GDD.md` unless the request names a prop the style guide cannot place, `reports/`, `_meta/agent-runs.md`, and the review folders.

## Process
1. Check the request names a prop, a footprint and a variant count. If one is missing, stop and ask.
2. Read the style reference scene and the palette materials you need.
3. Write each variant as `<prop>/<prop>-a.tscn`, `-b`, `-c`: a root `Node3D` with primitive `MeshInstance3D` parts (Box, Cylinder, Sphere, Prism), palette materials only, origin at the footprint centre on the ground (y = 0).
4. Make the variants different takes on the same prop, with the same footprint.
5. Hand back the list of files and any palette token that had no material file.

## Outputs
- `game/scenes/variants/<prop>/<prop>-a.tscn`, `-b.tscn`, `-c.tscn` (only these)

## Check
- Shots and judgement are not this shelf's job. `_tools/model_shots.py <prop>` (to be built, M2 spec item 11) places each variant on the 5 × 5 test grid and runs `_tools/style_check.py`; `_tools/compare_page.py` builds the vote page (yes / maybe / no).
- The designer's pick on the compare page ends the run. Bob then promotes the picked variant into `game/scenes/props/`.
