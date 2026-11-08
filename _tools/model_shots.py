#!/usr/bin/env python3
"""Render a prop's colorbox variants, check each against STYLE_GUIDE.md, and build their vote page. No agent.

    python -I _tools/model_shots.py PROP-rN [--size N] [--no-render] [--unnumbered]

Milo writes game/scenes/variants/PROP-rN/PROP-rN-a.tscn, -b, -c, a new folder per vote round (a name without -rN is
refused unless --unnumbered, so one round can't overwrite another). This script then:
  1. loads all the variants once, side by side on one shared test grid (cell 2.0), and shoots each
     close up (the others hidden) with the farm's light and camera angle at 720 × 1280 (game/tests/model_shots.gd) into game/reports/variants/PROP/;
  2. runs style_check.py on each variant alone (its scene and the materials it uses), and writes
     checks.json and checks.md there;
  3. builds the yes / maybe / no vote page (compare_page.py variants, at most 9 shots) as
     game/reports/variants/PROP/vote.html, for the orchestrator to publish.
--size fixes the camera's orthographic size; by default (0) the camera zooms in close on each
variant, fitted to its bounds (designer, 2026-11-05). Exit 0 when the page is built, whatever the checks say: a variant
that fails is shown with its FAIL pill so the designer can still pick it and Bob fixes it on
promotion. Standard library only.
"""
import argparse
import json
import os
import re
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
    ap.add_argument("--size", type=float, default=0.0, help="fixed camera orthographic size (default 0: fit each variant close)")
    ap.add_argument("--no-render", action="store_true", help="reuse the shots already in the folder")
    ap.add_argument("--unnumbered", action="store_true", help="re-render an old folder without -r<N> (hive-frames, flower-patch)")
    a = ap.parse_args(argv)
    if not re.search(r"-r\d+$", a.prop) and not a.unnumbered:
        sys.exit(f"'{a.prop}' has no round number: Milo writes each round to game/scenes/variants/<prop>-r<N>/ so no "
                 f"round overwrites another (game/scenes/variants/CONTEXT.md). Use --unnumbered for an old folder.")
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
