#!/usr/bin/env python3
"""Shoot any scene alone in a dummy scene (farm light and camera angle, fitted) to a square PNG. No agent.

    python -I _tools/model_snap.py SCENE --out PATH [--px 288] [--fit NODE] [--hide A,B]
                                   [--set N:prop=JSON]... [--call N:method=JSON-array]... [--bg transparent|R,G,B]
    python -I _tools/model_snap.py --recipe NAME        (shots listed in _tools/snap_recipes.json)

Builds a job list, writes it to game/reports/snaps/_jobs.json, and runs game/tests/model_snap.gd once (a window, not
--headless) for all the shots. Each target PNG (and its .import) is deleted first so a stale file can't pass. Then it
checks each PNG: it exists, its IHDR size is px x px, and its coverage (from Godot's line) is at least 0.02. A PNG under
game/ also gets an import pass (godot --headless --editor --quit-after 1500, as godot_run.py; 4.2.1 has no --import, L58) and must have its .import file. For a recipe, each shot id
must be a key of PreviewTile.FILES (game/scripts/preview_tile.gd). Exit 0 only when every check passes. Standard library only.
"""
import argparse
import json
import re
import struct
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
from godot_path import GODOT  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
JOBS = GAME / "reports" / "snaps" / "_jobs.json"
MIN_COVERAGE = 0.02


def fail(msg):
    sys.exit(msg)


def tail(proc):
    return "\n".join((proc.stdout + proc.stderr).splitlines()[-8:])


def parse_bg(text):
    if text == "transparent":
        return "transparent"
    try:
        rgb = [float(x) for x in text.split(",")]
    except ValueError:
        rgb = []
    if len(rgb) != 3:
        fail(f"--bg '{text}': use transparent or R,G,B")
    return rgb


def parse_pairs(items, what, want_list):
    out = []
    for item in items or []:
        node, sep, rest = item.partition(":")
        name, eq, raw = rest.partition("=")
        if not sep or not eq or not name:
            fail(f"--{what} '{item}': use NODE:name=JSON")
        try:
            val = json.loads(raw)
        except json.JSONDecodeError as e:
            fail(f"--{what} '{item}': value is not JSON ({e})")
        if want_list and not isinstance(val, list):
            fail(f"--{what} '{item}': args must be a JSON array")
        out.append([node, name, val])
    return out


def abs_out(text):
    p = Path(text)
    p = (p if p.is_absolute() else ROOT / p).resolve()
    if ROOT.resolve() not in p.parents:
        fail(f"--out {p} is outside the repo")
    return p


def make_job(scene, out, px, fit, hide, sets, calls, bg):
    if not scene.startswith("res://"):
        scene = "res://" + scene.lstrip("/")
    return {"scene": scene, "out": str(out), "px": px, "fit": fit or "", "hide": hide or [],
            "set": sets or [], "call": calls or [], "bg": bg}


def recipe_jobs(name):
    path = ROOT / "_tools" / "snap_recipes.json"
    recipes = json.loads(path.read_text(encoding="utf-8"))
    if name not in recipes:
        fail(f"recipe '{name}' not in {path.name} (has: {', '.join(recipes)})")
    r = recipes[name]
    src = (GAME / "scripts" / "preview_tile.gd").read_text(encoding="utf-8")
    block = re.search(r"const FILES[^{]*\{(.*?)\n\t?\}", src, re.S)
    ids = set(re.findall(r'"(\w+)"\s*:', block.group(1))) if block else set()
    if not ids:
        fail("could not parse FILES from game/scripts/preview_tile.gd")
    jobs = []
    for s in r["shots"]:
        if s["id"] not in ids:
            fail(f"recipe id '{s['id']}' is not in PreviewTile.FILES ({', '.join(sorted(ids))})")
        out = abs_out(f"{r['out_dir']}/{s['id']}.png")
        jobs.append(make_job(s["scene"], out, s.get("px", r.get("px", 288)), s.get("fit", ""), s.get("hide", []),
                             s.get("set", []), s.get("call", []), s.get("bg", "transparent")))
    return jobs


def imported(out):
    """True when Godot imports this PNG: under game/ and in no folder holding a .gdignore (game/reports/ has one)."""
    p, game = Path(out).resolve(), GAME.resolve()
    if game not in p.parents:
        return False
    return not any((d / ".gdignore").exists() for d in p.parents if d == game or game in d.parents)


def png_size(path):
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", data[16:24])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("scene", nargs="?", help="res:// path (or path under game/) of the scene to shoot")
    ap.add_argument("--out", help="PNG path (inside the repo)")
    ap.add_argument("--recipe", help="name in _tools/snap_recipes.json")
    ap.add_argument("--px", type=int, default=288)
    ap.add_argument("--fit", default="", help="node path to fit the camera to (default: the scene root)")
    ap.add_argument("--hide", default="", help="comma-separated node paths to hide")
    ap.add_argument("--set", action="append", default=[], metavar="N:prop=JSON")
    ap.add_argument("--call", action="append", default=[], metavar="N:method=JSON-array")
    ap.add_argument("--bg", default="transparent", help="transparent or R,G,B (0-1 floats)")
    a = ap.parse_args(argv)

    if a.recipe:
        if a.scene or a.out:
            fail("--recipe takes no SCENE or --out")
        jobs = recipe_jobs(a.recipe)
    else:
        if not a.scene or not a.out:
            fail("give SCENE and --out, or --recipe NAME")
        hide = [h for h in a.hide.split(",") if h]
        jobs = [make_job(a.scene, abs_out(a.out), a.px, a.fit, hide, parse_pairs(a.set, "set", False),
                         parse_pairs(a.call, "call", True), parse_bg(a.bg))]

    for j in jobs:  # no stale file may pass the checks
        out = Path(j["out"])
        out.parent.mkdir(parents=True, exist_ok=True)
        for f in (out, Path(str(out) + ".import")):
            f.unlink(missing_ok=True)

    JOBS.parent.mkdir(parents=True, exist_ok=True)
    JOBS.write_text(json.dumps(jobs, indent=1), encoding="utf-8")
    try:
        cmd = [GODOT, "--path", str(GAME), "--resolution", "720x1280", "--position", "0,0",
               "-s", "res://tests/model_snap.gd", "--", f"--jobs={JOBS}"]
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
        if "COMPLETED" not in proc.stdout:
            fail("model_snap.gd did not complete:\n" + tail(proc))

        cov = {}
        for m in re.finditer(r"^shot (.+?) (\d+)x(\d+) coverage=([0-9.eE+-]+)", proc.stdout, re.M):
            cov[str(Path(m.group(1)))] = float(m.group(4))

        problems = []
        for j in jobs:
            out = Path(j["out"])
            if not out.is_file():
                problems.append(f"{out.name}: missing PNG")
                continue
            size = png_size(out)
            if size != (j["px"], j["px"]):
                problems.append(f"{out.name}: size {size} is not {j['px']}x{j['px']}")
            c = cov.get(str(out))
            if c is None:
                c = next((v for k, v in cov.items() if Path(k).name == out.name), None)
            if c is None or c < MIN_COVERAGE:
                problems.append(f"{out.name}: coverage {c} is under {MIN_COVERAGE}")
        if problems:
            fail("; ".join(problems))

        if any(imported(j["out"]) for j in jobs):
            imp = subprocess.run([GODOT, "--headless", "--editor", "--path", str(GAME), "--quit-after", "1500"], capture_output=True,
                                 text=True, encoding="utf-8", errors="replace", timeout=300)
            missing = [Path(j["out"]).name for j in jobs
                       if imported(j["out"]) and not Path(str(j["out"]) + ".import").is_file()]
            if missing:
                fail(f"no .import for {', '.join(missing)} after the import pass:\n" + tail(imp))
    finally:
        JOBS.unlink(missing_ok=True)

    for j in jobs:
        print(f"ok {j['out']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
