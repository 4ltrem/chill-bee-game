#!/usr/bin/env python3
"""Render a prop's colorbox variants, check each against STYLE_GUIDE.md, and build their vote page. No agent.

    python -I _tools/model_shots.py PROP [--size 12] [--no-render]

Milo writes game/scenes/variants/PROP/PROP-a.tscn, -b, -c. This script then:
  1. renders each variant on the 5 × 5 test grid (cell 2.0) with the farm's light and camera at
     720 × 1280 (game/tests/model_shots.gd) into game/reports/variants/PROP/;
  2. runs style_check.py on each variant alone (its scene and the materials it uses), and writes
     checks.json and checks.md there;
  3. builds the yes / maybe / no vote page (compare_page.py variants, at most 9 shots) as
     game/reports/variants/PROP/vote.html, for the orchestrator to publish.
--size is the camera's orthographic size (default 12: the whole grid; the farm's uncapping zoom
is too close for a whole prop). Exit 0 when the page is built, whatever the checks say: a variant
that fails is shown with its FAIL pill so the designer can still pick it and Bob fixes it on
promotion. Standard library only.
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import compare_page  # noqa: E402
import style_check  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT", r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe")


def render(prop, out, size):
    out.mkdir(parents=True, exist_ok=True)
    cmd = [GODOT, "--path", str(ROOT / "game"), "--resolution", "720x1280", "--position", "0,0",
           "-s", "res://tests/model_shots.gd", "--", f"--prop={prop}", f"--out={out}", f"--size={size:g}"]
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
    if "COMPLETED" not in proc.stdout:
        sys.exit("model_shots.gd did not complete:\n" + "\n".join((proc.stdout + proc.stderr).splitlines()[-8:]))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("prop")
    ap.add_argument("--size", type=float, default=12.0, help="camera orthographic size")
    ap.add_argument("--no-render", action="store_true", help="reuse the shots already in the folder")
    a = ap.parse_args(argv)
    variants = sorted((ROOT / "game" / "scenes" / "variants" / a.prop).glob(f"{a.prop}-*.tscn"))
    if not variants:
        sys.exit(f"no variants in game/scenes/variants/{a.prop}/ (Milo writes {a.prop}-a.tscn, -b, -c)")
    out = ROOT / "game" / "reports" / "variants" / a.prop
    if not a.no_render:
        print(f"rendering {len(variants)} variant(s)...", flush=True)
        render(a.prop, out, a.size)
    checks, md = {}, [f"# style_check.py on the {a.prop} variants\n"]
    for v in variants:
        rows = style_check.run(ROOT / "game", ROOT / "STYLE_GUIDE.md", scenes=[v])
        blocking = [r for r in rows if not r["minor"]]
        summary = "no rows" if not rows else "; ".join(f"{r['rule']} {r['finding']}" for r in blocking[:3])
        checks[f"{v.stem}.png"] = {"pass": not blocking, "summary": summary, "rows": rows}
        md.append(f"## {v.stem}: {'PASS' if not blocking else 'FAIL'}\n\n{style_check.table(rows) if rows else 'No rows.'}\n")
        print(f"{v.stem}: style_check {'PASS' if not blocking else f'FAIL ({len(blocking)} row(s))'}")
    (out / "checks.json").write_text(json.dumps(checks, indent=1, ensure_ascii=False), encoding="utf-8")
    (out / "checks.md").write_text("\n".join(md), encoding="utf-8", newline="\n")
    missing = [v.stem for v in variants if not (out / f"{v.stem}.png").is_file()]
    if missing:
        sys.exit(f"no shot for {', '.join(missing)}")
    page = out / "vote.html"
    compare_page.cmd_variants(str(out), str(page), f"{a.prop.replace('-', ' ').title()} variants", str(out / "checks.json"))
    print(f"vote page: {page.relative_to(ROOT).as_posix()} ({len(variants)} shot(s)); add it to Design Votes with `compare_page.py add PAGE OUT --variants {out.relative_to(ROOT).as_posix()} {a.prop} TITLE --checks .../checks.json`")
    return 0


if __name__ == "__main__":
    sys.exit(main())
