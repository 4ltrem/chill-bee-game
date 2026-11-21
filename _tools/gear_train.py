"""Generate the Centrifuge Gearing gear train into a centrifuge variant scene. No agent.

Gear1 sits at the lid centre under the crank pivot; Gear2..GearN sit on one circle concentric with the lid
(designer, 2026-11-09: "align gears so they follow the circumference of the lid"), each meshing with the one
before. Every gear is a steel disc with a dark hub and box teeth around its rim; the tooth count comes from the
rim length at a fixed pitch, made unique per gear ("more teeth on all gears, every gear a different amount").

  python -I _tools/gear_train.py OUT --base BASE.tscn --radii 0.28,0.22,0.18,0.15,0.12,0.10 [--ring R]
      [--start DEG] [--pitch 0.11] [--show N]

OUT follows compose_variant.py's rule (a new file in game/scenes/variants/<prop>-r<N>/). --ring defaults to
Gear1's and Gear2's meshing distance. --start is Gear2's angle on the lid (degrees, 0 = +x, the crank arm's side;
-90 = toward -z). --show N keeps Gear1..GearN (default all): one file per level, same geometry.
"""
import argparse
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_variant as cv  # noqa: E402

DEPTH, HEIGHT, DISC_H, GAP = 0.08, 0.08, 0.1, 0.06


def tf(x=0.0, y=0.0, z=0.0, yaw=0.0):
    c, s = math.cos(yaw), math.sin(yaw)
    v = [c, 0, -s, 0, 1, 0, s, 0, c, x, y, z]
    return "transform = Transform3D(" + ", ".join(f"{round(n, 5):g}" for n in v) + ")"


def tooth_tf(phi, rr):
    """A PrismMesh tooth lying on the gear: its point (local +y) faces outward, local z is the gear's axis."""
    c, s = math.cos(phi), math.sin(phi)
    v = [-s, 0, c, c, 0, s, 0, 1, 0, rr * c, 0, rr * s]  # basis columns X (tangent), Y (radial), Z (up)
    return "transform = Transform3D(" + ", ".join(f"{round(n, 5):g}" for n in v) + ")"


def ext_id(scene, name):
    res = f"res://materials/{name}.tres"
    for i, h, _ in scene.ext:
        if cv.attr(h, "path") == res:
            return i
    rid = cv.unique(f"m_{name}", {e[0] for e in scene.ext})
    scene.ext.append([rid, f'[ext_resource type="Material" path="{res}" id="{rid}"]', ""])
    return rid


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("out")
    ap.add_argument("--base", required=True)
    ap.add_argument("--radii", required=True)
    ap.add_argument("--ring", type=float, default=0.0)
    ap.add_argument("--start", type=float, default=-55.0)
    ap.add_argument("--pitch", type=float, default=0.11)
    ap.add_argument("--show", type=int, default=0)
    ap.add_argument("--lid-radius", type=float, default=1.05)
    ap.add_argument("--tooth", choices=("prism", "box"), default="prism",
                    help="prism = pointed teeth (designer, 2026-11-09: 'all need to be pointy'); box = round 5's")
    a = ap.parse_args(argv)
    out = a.out.replace("\\", "/")
    if not cv.OUT_RE.match(out):
        sys.exit(f"'{out}': write to game/scenes/variants/<prop>-r<N>/<prop>-r<N>-<x>.tscn (a new round folder)")
    if (cv.ROOT / out).exists():
        sys.exit(f"{out} exists: each round is a new file, never an overwrite")
    radii = [float(r) for r in a.radii.split(",")]
    if len(set(radii)) != len(radii):
        sys.exit("--radii: every gear needs its own size (different tooth counts)")
    ring = a.ring or radii[0] + radii[1] + GAP
    # centres: Gear1 at the lid centre, the rest stepping along the ring by each meshing distance
    centres, ang = [(0.0, 0.0)], math.radians(a.start)
    for k in range(1, len(radii)):
        if k > 1:
            chord = radii[k - 1] + radii[k] + GAP
            if chord > 2 * ring:
                sys.exit(f"Gear{k + 1} cannot mesh on a ring of {ring:g}")
            ang -= 2 * math.asin(chord / (2 * ring))
        centres.append((ring * math.cos(ang), ring * math.sin(ang)))
    for k, ((x, z), r) in enumerate(zip(centres, radii)):
        if math.hypot(x, z) + r + DEPTH > a.lid_radius:
            sys.exit(f"Gear{k + 1} overhangs the lid (edge {math.hypot(x, z) + r + DEPTH:.2f} > {a.lid_radius:g})")
        for j in range(k):
            (x2, z2), r2 = centres[j], radii[j]
            if math.hypot(x - x2, z - z2) < r + r2 + GAP - 1e-6:
                sys.exit(f"Gear{k + 1} overlaps Gear{j + 1}")
    teeth, used = [], set()
    for r in radii:
        n = max(6, round(2 * math.pi * r / a.pitch))
        while n in used:
            n += 1
        used.add(n)
        teeth.append(n)

    base = cv.Scene((cv.ROOT / a.base).read_text(encoding="utf-8"), a.base)
    if "Lid" not in [n[0] for n in base.nodes]:
        sys.exit(f"{a.base}: no Lid node (use a centrifuge variant)")
    base.nodes = [n for n in base.nodes if not (n[0] == "Lid/Gears" or n[0].startswith("Lid/Gears/"))]
    steel, dark = ext_id(base, "steel"), ext_id(base, "steel_dark")
    taken = {s[0] for s in base.sub}

    def mesh(kind, rid, body):
        sid = cv.unique(rid, taken)
        taken.add(sid)
        base.sub.append([sid, f'[sub_resource type="{kind}" id="{sid}"]', body])
        return sid

    hub = mesh("CylinderMesh", "Mesh_gt_hub", f'material = ExtResource("{dark}")\ntop_radius = 0.06\nbottom_radius = 0.06\nheight = 0.05')
    nodes = [["Lid/Gears", '[node name="Gears" type="Node3D" parent="Lid"]', ""]]
    show = a.show or len(radii)
    for k, ((x, z), r, n) in enumerate(zip(centres, radii, teeth), start=1):
        if k > show:
            break
        g = f"Lid/Gears/Gear{k}"
        disc = mesh("CylinderMesh", f"Mesh_gt_disc{k}",
                    f'material = ExtResource("{steel}")\ntop_radius = {r:g}\nbottom_radius = {r:g}\nheight = {DISC_H:g}')
        if a.tooth == "box":
            width = max(0.05, round(0.5 * 2 * math.pi * r / n, 4))
            tooth = mesh("BoxMesh", f"Mesh_gt_tooth{k}",
                         f'material = ExtResource("{steel}")\nsize = Vector3({DEPTH:g}, {HEIGHT:g}, {width:g})')
        else:  # base width, radial depth, thickness along the gear axis
            width = max(0.05, round(0.75 * 2 * math.pi * r / n, 4))
            tooth = mesh("PrismMesh", f"Mesh_gt_tooth{k}",
                         f'material = ExtResource("{steel}")\nsize = Vector3({width:g}, {DEPTH:g}, {HEIGHT:g})')
        nodes.append([g, f'[node name="Gear{k}" type="Node3D" parent="Lid/Gears"]', tf(x, 0.125, z)])
        nodes.append([f"{g}/Disc", f'[node name="Disc" type="MeshInstance3D" parent="{g}"]', f'mesh = SubResource("{disc}")'])
        nodes.append([f"{g}/Hub", f'[node name="Hub" type="MeshInstance3D" parent="{g}"]', tf(y=0.075) + f'\nmesh = SubResource("{hub}")'])
        off = math.pi / n if k % 2 == 0 else 0.0  # neighbours' teeth interleave
        for t in range(n):
            phi = 2 * math.pi * t / n + off
            rr = r + DEPTH / 2 - 0.01
            place = tf(rr * math.cos(phi), 0, rr * math.sin(phi), -phi) if a.tooth == "box" else tooth_tf(phi, rr)
            nodes.append([f"{g}/Tooth{t + 1}", f'[node name="Tooth{t + 1}" type="MeshInstance3D" parent="{g}"]',
                          place + f'\nmesh = SubResource("{tooth}")'])
    idx = max(i for i, nd in enumerate(base.nodes) if nd[0] == "Lid" or nd[0].startswith("Lid/"))
    base.nodes[idx + 1:idx + 1] = nodes
    text = base.text()
    (cv.ROOT / out).parent.mkdir(parents=True, exist_ok=True)
    (cv.ROOT / out).write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {out}: ring {ring:g}, gears {show}/{len(radii)}, teeth {teeth[:show]}")


if __name__ == "__main__":
    main()
