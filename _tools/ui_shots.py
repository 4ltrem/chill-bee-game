#!/usr/bin/env python3
"""Capture the standard UI moments of the game in one or more worktrees, for side-by-side comparison.

    python -I _tools/ui_shots.py LABEL=WORKTREE [LABEL=WORKTREE ...] [--script game/tests/ui_compare_shots.gd]
                                 [--collect DIR] [--timeout 600]

Each WORKTREE is a checkout's root (the folder holding game/). The moment list lives in one place, the
MOMENTS list of game/tests/ui_compare_shots.gd. This tool copies that script (from this repository unless
--script names another) into each worktree, so every version is shot at the same moments. It runs Godot windowed at
720x1280 with `-- LABEL`, then tiles the shots with contact_sheet.py. Shots and shots.json land in
WORKTREE/game/reports/ui-compare/LABEL/. --collect DIR also copies each label's folder to DIR/LABEL/.

Designer rule (2026-11-06): the same moments are captured by this script, not by an agent. An agent (Bob) is
only called when a new screen, phase or menu enters the game, to add its entry to MOMENTS.
Standard library only (contact_sheet.py needs Pillow and is run without -I).
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from godot_run import GODOT  # noqa: E402

REL_SCRIPT = os.path.join("game", "tests", "ui_compare_shots.gd")


def shoot(label, tree, script, timeout):
    game = os.path.join(tree, "game")
    if not os.path.isfile(os.path.join(game, "project.godot")):
        return f"{label}: no game/project.godot under {tree}"
    dest = os.path.join(tree, REL_SCRIPT)
    if os.path.abspath(dest) != os.path.abspath(script):
        shutil.copyfile(script, dest)
    out = os.path.join(game, "reports", "ui-compare", label)
    os.makedirs(out, exist_ok=True)
    cmd = [GODOT, "--path", game, "--resolution", "720x1280", "--position", "0,0",
           "-s", "res://tests/ui_compare_shots.gd", "--", label]
    print(f"ui_shots: {label} ...", file=sys.stderr, flush=True)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)
        log = proc.stdout + proc.stderr
    except subprocess.TimeoutExpired:
        return f"{label}: timed out after {timeout} s"
    with open(os.path.join(out, "ui_shots.log"), "w", encoding="utf-8") as fh:
        fh.write(" ".join(cmd) + "\n\n" + log)
    subprocess.run([sys.executable, os.path.join(TOOLS, "contact_sheet.py"), out, "--match", ".png"],
                   capture_output=True, text=True)
    pngs = sorted(f for f in os.listdir(out) if f.endswith(".png") and not f.startswith("_"))
    missing = []
    meta = os.path.join(out, "shots.json")
    if os.path.isfile(meta):
        data = json.load(open(meta, encoding="utf-8"))
        missing = [k for k, v in data.items() if isinstance(v, str) and v.startswith("missing")]
    errors = [ln for ln in log.splitlines() if "SCRIPT ERROR" in ln or ln.startswith("ERROR")][:3]
    line = f"{label}: {len(pngs)} shots in {os.path.relpath(out, REPO)}"
    if missing:
        line += f"; missing: {', '.join(missing)}"
    if errors:
        line += "; first errors: " + " | ".join(errors)
    return line


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("targets", nargs="+", help="LABEL=WORKTREE")
    ap.add_argument("--script", default=os.path.join(REPO, REL_SCRIPT))
    ap.add_argument("--collect")
    ap.add_argument("--timeout", type=int, default=600)
    a = ap.parse_args(argv)
    if not os.path.isfile(a.script):
        sys.exit(f"ui_shots: no shot script at {a.script}")
    lines = []
    for t in a.targets:
        label, _, tree = t.partition("=")
        if not tree:
            sys.exit(f"ui_shots: expected LABEL=WORKTREE, got {t}")
        lines.append(shoot(label, os.path.abspath(tree), os.path.abspath(a.script), a.timeout))
        if a.collect:
            src = os.path.join(tree, "game", "reports", "ui-compare", label)
            if os.path.isdir(src):
                shutil.copytree(src, os.path.join(a.collect, label), dirs_exist_ok=True)
    print("\n".join(lines))


if __name__ == "__main__":
    main()
