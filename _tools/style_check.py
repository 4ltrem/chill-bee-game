#!/usr/bin/env python3
"""Check the measurable visual rules of STYLE_GUIDE.md over the game's materials, scenes and shot measures.

    python -I _tools/style_check.py [--root game] [--shots DIR] [--phase colorbox|art] [--json FILE]
                                    [--guide STYLE_GUIDE.md] [--threshold 12]

Rules checked (the guide's "script" rules): V1 palette ΔE by role, V2 emission, V3 accent count,
V4 primitives and no textures (colorbox), V5 vertex budget (art), V6 thin parts (size only),
V10 contrast of button text, V11 touch sizes, V12 font sizes and outline, V14 cell width (from
DIR/measure.json, written by game/tests/style_shots.gd), V15 glass alpha and back faces.

The palette is read from the guide each run, so a token the designer adds there counts at once.
Prints a FAIL table (rule ID, file:line, finding, Fix) and exits 1 if any row is blocking, else 0.
A Fix that needs a creative choice (two or more acceptable answers, or a new token) ends with
"(designer)" and lists the options; style_loop.py does not send those rows to Bob.
Standard library only, no Godot. Tests: python -I _tools/test_style.py
"""
import argparse
import colorsys
import json
import math
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent

# Which palette roles each material may use, by file stem (materials/*.tres) or sub-resource id
# (inline materials and UI colours). A material not listed may use any role; its nearest token
# decides. Keep this small: a new material gets a row when Bob adds it.
ROLES = {
    "Material_meadow": ["Meadow"], "background_color": ["Meadow"],
    "flower_default": ["Blossom"],
    "cell_capped": ["Honey"], "cell_uncapped": ["Honey"], "cell_extracted": ["Honey"],
    "comb_melting": ["Honey"], "honey_level": ["Honey"], "jar_amber": ["Honey"],
    "hive_body": ["Wood"], "hive_lid": ["Wood"], "wood": ["Wood"], "crate_wood": ["Wood"],
    "steel": ["Metal"], "steel_dark": ["Metal"], "spigot": ["Metal"], "crank_arm": ["Metal"],
    "rim_grey": ["Metal"], "rim_mark": ["Shadow"],  # designer 2026-11-05: A, charcoal (Design Votes v3-rim)
    "glass": ["Glass"],
    "truck_chassis": ["Shadow"], "tyre": ["Shadow"],
    "truck_paint": ["Accent"], "crank_handle": ["Accent"],
    "ui": ["UI"],
}
GLOW_ROLES = {"Honey", "Biome glow"}
PRIMITIVES = {"BoxMesh", "CylinderMesh", "SphereMesh", "PlaneMesh", "PrismMesh", "CapsuleMesh",
              "QuadMesh", "TorusMesh"}
THIN_OK = re.compile(r"rim|handle|lip|line|mark|border|edge", re.I)
COLOR = re.compile(r"Color\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+))?\s*\)")
GODOT_BUTTON_FONT = (0.875, 0.875, 0.875)  # Godot 4 default theme
GODOT_DEFAULT_FONT_SIZE = 16


# ---- palette -------------------------------------------------------------------------------

def load_palette(guide):
    """Tokens from the guide's `## Palette` section: [{name, role, rgb, alpha_max, provisional}]."""
    text = guide.read_text(encoding="utf-8")
    sec = re.search(r"^## Palette.*?$(.*?)^## ", text, re.M | re.S)
    if not sec:
        sys.exit(f"{guide}: no '## Palette' section")
    tokens, role = [], None
    for line in sec.group(1).splitlines():
        m = re.match(r"^- \*\*(.+?)\*\*", line)
        if m:
            role = m.group(1).strip()
            continue
        m = re.match(r"^\s+- (.+?) \(([\d.]+),\s*([\d.]+),\s*([\d.]+)\)(.*)$", line)
        if m and role:
            alpha = re.search(r"alpha\s*≤\s*([\d.]+)", m.group(5))
            tokens.append({"name": m.group(1).strip(), "role": role,
                           "rgb": tuple(float(m.group(i)) for i in (2, 3, 4)),
                           "alpha_max": float(alpha.group(1)) if alpha else None,
                           "provisional": "provisional" in m.group(5)})
    return tokens


def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lab(rgb):
    r, g, b = (_lin(c) for c in rgb)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 1.0
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = [t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116 for t in (x, y, z)]
    return 116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])


def delta_e(a, b):
    """CIE76 distance between two sRGB colours (0-1)."""
    return math.dist(lab(a), lab(b))


def nearest(rgb, tokens, roles=None):
    pool = [t for t in tokens if roles is None or t["role"] in roles]
    return min(((delta_e(rgb, t["rgb"]), t) for t in pool), key=lambda p: p[0]) if pool else (999, None)


def luminance(rgb):
    r, g, b = (_lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def fmt_rgb(rgb):
    return "(" + ", ".join(f"{c:g}" for c in rgb) + ")"


# ---- Godot text resources ------------------------------------------------------------------

def sections(path):
    """[(header, kind, attrs, line_no, {key: (value, line_no)})] for a .tres/.tscn file."""
    out, cur = [], None
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith("["):
            m = re.match(r"\[(\w+)(.*)\]", line)
            if m:
                attrs = dict(re.findall(r'(\w+)=("[^"]*"|\S+)', m.group(2)))
                attrs = {k: v.strip('"') for k, v in attrs.items()}
                cur = (m.group(1), attrs, i, {})
                out.append(cur)
            continue
        m = re.match(r"^([\w/]+)\s*=\s*(.+)$", line)
        if m and cur:
            cur[3][m.group(1)] = (m.group(2).strip(), i)
    return out


def color(value):
    m = COLOR.search(value)
    if not m:
        return None, 1.0
    return tuple(float(m.group(i)) for i in (1, 2, 3)), float(m.group(4) or 1.0)


class Report:
    def __init__(self, root):
        self.root, self.rows = root, []

    def add(self, rule, path, line, finding, fix, minor=False):
        rel = path.relative_to(self.root).as_posix() if path.is_relative_to(self.root) else path.as_posix()
        self.rows.append({"rule": rule, "where": f"{rel}:{line}", "finding": finding,
                          "fix": fix, "minor": minor, "designer": fix.endswith("(designer)")})


ONLY = None  # set by run(scenes=...): check just these scene files and the materials they use


def scene_files(root):
    """The scenes to check: ONLY, or every scene except Milo's variants (history, checked by model_shots.py)."""
    if ONLY is not None:
        return list(ONLY)
    return [p for p in sorted(root.glob("scenes/**/*.tscn")) if "variants" not in p.relative_to(root).parts]


def materials(root):
    """Every material: (key, path, line, props) from materials/*.tres and inline scene materials."""
    found = []
    used = None
    if ONLY is not None:
        used = {a.get("path", "").split("/")[-1][:-5] for p in ONLY for k, a, _, _ in sections(p) if k == "ext_resource"}
    for p in sorted((root / "materials").glob("*.tres")) if (root / "materials").is_dir() else []:
        if used is not None and p.stem not in used:
            continue
        for kind, attrs, line, props in sections(p):
            if kind == "resource":
                found.append((p.stem, p, line, props))
    for p in scene_files(root):
        for kind, attrs, line, props in sections(p):
            if kind == "sub_resource" and attrs.get("type") in ("StandardMaterial3D", "ORMMaterial3D"):
                found.append((attrs.get("id", "?"), p, line, props))
    return found


# ---- rules ---------------------------------------------------------------------------------

def accent_limit(guide_text):
    """V3's limit, read from the guide's rule text ("at most N accent-role colours"), default 2."""
    m = re.search(r"\|\s*V3\s*\|[^|]*at most (\d+) accent", guide_text or "")
    return int(m.group(1)) if m else 2


def check_materials(root, tokens, rep, threshold, phase, guide_text=""):
    accents = {}
    for key, path, line, props in materials(root):
        rgb, alpha = color(props.get("albedo_color", ("Color(1, 1, 1, 1)", line))[0])
        ln = props.get("albedo_color", (None, line))[1]
        roles = ROLES.get(key)
        d_any, t_any = nearest(rgb, tokens)
        d, t = nearest(rgb, tokens, roles) if roles else (d_any, t_any)
        role = t["role"] if t else "?"
        _, sat, val = colorsys.rgb_to_hsv(*rgb)
        loud = d > threshold and sat > 0.6 and val > 0.5 and not (roles and set(roles) & GLOW_ROLES)
        if t_any and t_any["role"] == "Accent" and d_any <= 2 * threshold or "Accent" in (roles or []) or loud:
            accents[key] = (path, ln, rgb)
        if d > threshold:
            where = f"{'/'.join(roles)} role" if roles else "any role"
            if t_any is not t and d_any <= threshold:
                fix = (f"A: recolour to {t['name']} {fmt_rgb(t['rgb'])} (ΔE {d:.1f}); B: allow the "
                       f"{t_any['role']} role for `{key}` (it is ΔE {d_any:.1f} from {t_any['name']}) (designer)")
            else:
                fix = f"recolour `{key}` to {t['name']} {fmt_rgb(t['rgb'])}"
            rep.add("V1", path, ln, f"`{key}` albedo {fmt_rgb(rgb)} is ΔE {d:.1f} from the nearest "
                                    f"token in {where} ({t['name']}); limit {threshold}", fix)
        # V2: emission
        if props.get("emission_enabled", ("false",))[0] == "true":
            glow_roles = set(roles or [role])
            if not glow_roles & GLOW_ROLES:
                rep.add("V2", path, props["emission_enabled"][1],
                        f"`{key}` emits light but its role is {'/'.join(sorted(glow_roles))}; only Honey "
                        f"(and Biome glow on its flora) may glow", f"set `emission_enabled = false` on `{key}`")
        # V4: textures
        if phase == "colorbox":
            for k, (v, l) in props.items():
                if "texture" in k and "null" not in v:
                    rep.add("V4", path, l, f"`{key}` uses a texture (`{k}`)", f"remove `{k}`; use a flat palette colour")
        # V15: glass
        if (roles or [role]) == ["Glass"] or role == "Glass" and roles is None:
            tok = next((x for x in tokens if x["role"] == "Glass"), None)
            amax = tok["alpha_max"] if tok and tok["alpha_max"] else 0.35
            if alpha > amax:
                rep.add("V15", path, ln, f"glass `{key}` alpha {alpha:g} > {amax:g}", f"set albedo alpha to {amax:g} or less")
            if props.get("transparency", ("0",))[0] in ("0", "false"):
                rep.add("V15", path, line, f"glass `{key}` has no transparency mode", "set `transparency = 1`")
            if props.get("cull_mode", ("0",))[0] != "2":
                rep.add("V15", path, line, f"glass `{key}` culls back faces", "set `cull_mode = 2` (back faces drawn)")
    # V3: accents
    limit = accent_limit(guide_text)
    if len(accents) > limit:
        names = ", ".join(f"`{k}`" for k in accents)
        approved = [k for k in accents if ROLES.get(k) == ["Accent"] and nearest(accents[k][2], tokens, ["Accent"])[0] <= threshold]
        extra = [k for k in accents if k not in approved] or list(accents)[2:]
        for k in extra:
            path, ln, rgb = accents[k]
            rep.add("V3", path, ln, f"{len(accents)} accent colours in the scene set ({names}); at most {limit}",
                    f"A: recolour `{k}` to a calm non-accent token (e.g. charcoal or steel); "
                    f"B: approve `{k}` as a new accent: add its token to the Accent role and raise V3's limit to "
                    f"{len(accents)} in STYLE_GUIDE.md (designer)")
    # a V1 row on a material held by a V3 designer stop waits for the same decision
    held = {r["where"] for r in rep.rows if r["rule"] == "V3"}
    for r in rep.rows:
        if r["rule"] == "V1" and r["where"] in held and not r["designer"]:
            r["fix"] += "; or per the V3 decision on the same line (designer)"
            r["designer"] = True


def meshes(root, rep, phase, budget):
    for p in scene_files(root):
        for kind, attrs, line, props in sections(p):
            typ = attrs.get("type", "")
            if kind == "ext_resource" and re.search(r"\.(obj|glb|gltf|fbx|mesh|res|dae)$", attrs.get("path", ""), re.I):
                if phase == "colorbox":
                    rep.add("V4", p, line, f"imported mesh `{attrs['path']}`", "replace with primitive meshes")
                else:
                    vertex_budget(root, p, line, attrs["path"], rep, budget)
            if kind == "ext_resource" and "Texture" in typ and phase == "colorbox":
                rep.add("V4", p, line, f"texture `{attrs.get('path')}`", "remove the texture; use a flat palette colour")
            if kind == "sub_resource" and (typ.endswith("Mesh") or "Texture" in typ):
                if phase == "colorbox" and typ not in PRIMITIVES:
                    rep.add("V4", p, line, f"`{typ}` `{attrs.get('id')}` is not a primitive mesh",
                            "use BoxMesh, CylinderMesh, SphereMesh, PlaneMesh, PrismMesh or CapsuleMesh")
                if typ in PRIMITIVES and not THIN_OK.search(attrs.get("id", "")):
                    dims = []
                    if "size" in props:
                        dims = [float(x) for x in re.findall(r"[\d.]+", props["size"][0])]
                    for k in ("height", "top_radius", "bottom_radius", "radius"):
                        if k in props:
                            v = float(props[k][0])
                            dims.append(v * 2 if "radius" in k else v)
                    thin = [d for d in dims if 0 < d < 0.05]
                    if thin:
                        rep.add("V6", p, line, f"`{attrs.get('id')}` is {min(thin):g} units thin (< 0.05) and is not a rim or handle",
                                "make its thinnest dimension 0.05 units")


def vertex_budget(root, scene, line, res_path, rep, budget):
    f = root / res_path.replace("res://", "")
    if not f.is_file():
        return
    n = 0
    if f.suffix.lower() == ".obj":
        n = sum(1 for ln in f.read_text(encoding="utf-8", errors="ignore").splitlines() if ln.startswith("v "))
    elif f.suffix.lower() == ".gltf":
        data = json.loads(f.read_text(encoding="utf-8"))
        for mesh in data.get("meshes", []):
            for prim in mesh.get("primitives", []):
                n = max(n, data["accessors"][prim["attributes"]["POSITION"]]["count"])
    if n > budget:
        rep.add("V5", scene, line, f"`{res_path}` has {n:,} vertices > budget {budget:,}",
                "use a lower-poly model or decimate it")


def check_ui(root, tokens, rep, threshold):
    for p in scene_files(root):
        secs = sections(p)
        styles = {}
        for kind, attrs, line, props in secs:
            if kind == "sub_resource" and attrs.get("type") == "StyleBoxFlat":
                styles[attrs["id"]] = props
                for k in ("bg_color", "border_color"):
                    if k in props:
                        check_ui_colour(p, props[k], f"{attrs['id']}.{k}", tokens, rep, threshold)
            if kind == "sub_resource" and attrs.get("type") == "Environment" and "background_color" in props:
                rgb, _ = color(props["background_color"][0])
                d, t = nearest(rgb, tokens, ["Meadow"])
                if d > threshold:
                    rep.add("V1", p, props["background_color"][1], f"sky {fmt_rgb(rgb)} is ΔE {d:.1f} from {t['name']}",
                            f"recolour to {t['name']} {fmt_rgb(t['rgb'])}")
        panels = set()
        for kind, attrs, line, props in secs:
            if kind != "node":
                continue
            typ, name = attrs.get("type", ""), attrs.get("name", "?")
            path = (attrs.get("parent", "") + "/" + name).lstrip("./")
            if typ in ("PanelContainer", "Panel"):
                panels.add(path)
            inside_panel = any(path.startswith(pp + "/") for pp in panels)
            for k, v in props.items():
                if k.startswith("theme_override_colors/"):
                    check_ui_colour(p, v, f"{name}.{k.split('/')[1]}", tokens, rep, threshold)
            size = props.get("theme_override_font_sizes/font_size")
            if typ in ("Label", "Button", "RichTextLabel") and props.get("visible", ("true",))[0] != "false":
                minimum = 32 if typ == "Button" else 28
                if typ == "Button" and not props.get("text"):
                    minimum = 0  # an icon-only button has no text
                fs = int(float(size[0])) if size else GODOT_DEFAULT_FONT_SIZE
                if minimum and fs < minimum:
                    rep.add("V12", p, size[1] if size else line,
                            f"{typ} `{name}` font size {fs} px{'' if size else ' (Godot default)'} < {minimum}",
                            f"set `theme_override_font_sizes/font_size = {minimum}` or more")
                if typ == "Label" and not inside_panel and "theme_override_colors/font_outline_color" not in props:
                    rep.add("V12", p, line, f"Label `{name}` over the scene has no ink outline",
                            "add `theme_override_colors/font_outline_color` (ink) and `outline_size = 6`")
            if typ in ("Button", "TextureButton"):
                ms = props.get("custom_minimum_size")
                if ms:
                    w, h = (float(x) for x in re.findall(r"[\d.]+", ms[0].split("(", 1)[-1])[:2])
                    small = [f"{lbl} {v:g}" for lbl, v in (("width", w), ("height", h)) if 0 < v < 120]
                    if small:
                        rep.add("V11", p, ms[1], f"Button `{name}` touch area {', '.join(small)} px < 120",
                                f"raise `custom_minimum_size` to at least 120 in each dimension")
                for state, fkey in (("normal", "font_color"), ("disabled", "font_disabled_color")):
                    sk = props.get(f"theme_override_styles/{state}")
                    sid = re.search(r'SubResource\("([^"]+)"\)', sk[0]).group(1) if sk else None
                    bg = styles.get(sid, {}).get("bg_color")
                    if not bg or not props.get("text"):
                        continue
                    fg = props.get(f"theme_override_colors/{fkey}")
                    fg_rgb = color(fg[0])[0] if fg else GODOT_BUTTON_FONT
                    c = contrast(fg_rgb, color(bg[0])[0])
                    if c < 4.5:
                        rep.add("V10", p, fg[1] if fg else line,
                                f"Button `{name}` {state} text {fmt_rgb(fg_rgb)} on {fmt_rgb(color(bg[0])[0])}: contrast {c:.1f}:1 < 4.5",
                                "use ink text on light backgrounds or cream text on dark ones")


def check_ui_colour(path, value, label, tokens, rep, threshold):
    rgb, _ = color(value[0])
    if rgb is None:
        return
    d, t = nearest(rgb, tokens, ["UI"])
    if d > threshold:
        rep.add("V1", path, value[1], f"UI colour `{label}` {fmt_rgb(rgb)} is ΔE {d:.1f} from the nearest UI token ({t['name']}); limit {threshold}",
                f"recolour to {t['name']} {fmt_rgb(t['rgb'])}")


def check_shots(shots, rep, min_px=20.0):
    if not shots:
        return
    m = Path(shots) / "measure.json"
    if not m.is_file():
        rep.add("V14", m, 0, "no measure.json in the shot folder", "render the shots with game/tests/style_shots.gd")
        return
    data = json.loads(m.read_text(encoding="utf-8"))
    px = data.get("cell_px_min")
    if px is None or px < min_px:
        rep.add("V14", m, 1, f"smallest cell at the uncapping zoom is {px} px wide < {min_px:g}",
                "frame the zoom closer (zoom_size) or enlarge the comb (designer)")


def run(root, guide, phase="colorbox", threshold=12.0, shots=None, budget=2000, scenes=None):
    global ONLY
    ONLY = [Path(x).resolve() for x in scenes] if scenes is not None else None
    tokens = load_palette(guide)
    rep = Report(root)
    check_materials(root, tokens, rep, threshold, phase, Path(guide).read_text(encoding="utf-8"))
    meshes(root, rep, phase, budget)
    check_ui(root, tokens, rep, threshold)
    check_shots(shots, rep)
    order = {f"V{i}": i for i in range(1, 16)}
    rep.rows.sort(key=lambda r: (order.get(r["rule"], 99), r["where"]))
    return rep.rows


def table(rows):
    lines = ["| # | Rule | Where | Finding | Fix |", "|---|---|---|---|---|"]
    for i, r in enumerate(rows, 1):
        fix = r["fix"] + (" (minor)" if r["minor"] else "")
        lines.append(f"| {i} | {r['rule']} | `{r['where']}` | {r['finding']} | {fix} |")
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(ROOT / "game"), help="Godot project folder (or a fixture folder)")
    ap.add_argument("--guide", default=str(ROOT / "STYLE_GUIDE.md"))
    ap.add_argument("--phase", choices=("colorbox", "art"), default="colorbox")
    ap.add_argument("--threshold", type=float, default=12.0, help="V1 ΔE limit")
    ap.add_argument("--budget", type=int, default=2000, help="V5 vertices per mesh (provisional)")
    ap.add_argument("--shots", help="shot folder with measure.json (V14)")
    ap.add_argument("--json", help="also write the rows as JSON here")
    a = ap.parse_args(argv)
    rows = run(Path(a.root).resolve(), Path(a.guide), a.phase, a.threshold, a.shots, a.budget)
    blocking = [r for r in rows if not r["minor"]]
    if a.json:
        Path(a.json).write_text(json.dumps(rows, indent=1, ensure_ascii=False), encoding="utf-8")
    if rows:
        print(table(rows))
    print(f"\nstyle_check: {'FAIL' if blocking else 'PASS'}, {len(blocking)} blocking row(s), "
          f"{sum(r['designer'] for r in rows)} for the designer ({a.phase} phase)")
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
