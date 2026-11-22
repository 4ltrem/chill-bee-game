"""Commit work in progress on the current branch (`main`), with the last unit run's counts in the message (learnings L1).

    python -I _tools/checkpoint.py "item 14 fix-round edits" [--dry-run] [path ...]

Paths default to the build folders (game/scripts, scenes, materials, tests, specs) and _tools/. The subject starts
with the milestone number from `game/project.godot` (0.2.0 -> 0.2). It refuses on a detached HEAD and while a goal run
holds its lock (the goal agent owns game/ then). Never pushes: origin gets a push only when green, with the designer's
yes (milestone branches dropped, designer 2026-11-21).
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PATHS = ["game/scripts", "game/scenes", "game/materials", "game/tests", "game/specs", "_tools"]
LOCK = "_meta/usage/goal-run.lock"
TRAILER = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"


def git(*args, root=None):
    p = subprocess.run(["git", *args], cwd=root or ROOT, capture_output=True, text=True, encoding="utf-8")
    return p.returncode, (p.stdout + p.stderr).strip()


def unit_counts(root=None):
    """(passed, failed, log path) from the newest full-suite unit log, or None."""
    logs = sorted(((root or ROOT) / "game" / "reports" / "_runs").glob("*/unit.log"), key=lambda p: p.parent.name)
    for log in reversed(logs):
        text = log.read_text(encoding="utf-8", errors="replace")
        if "CB_ONLY: running" in text:   # a partial run says nothing about the suite
            continue
        return (len(re.findall(r"^PASS\s", text, re.M)), len(re.findall(r"^FAIL\s", text, re.M)),
                log.relative_to(root or ROOT).as_posix())
    return None


def milestone(root=None):
    """`0.2` from `config/version="0.2.1"` in game/project.godot; `wip` when there is none."""
    proj = (root or ROOT) / "game" / "project.godot"
    m = re.search(r'^config/version="(\d+\.\d+)', proj.read_text(encoding="utf-8"), re.M) if proj.is_file() else None
    return m.group(1) if m else "wip"


def message(version, note, counts):
    state = (f"WIP, {counts[1]} unit fails" if counts[1] else "unit green") if counts else "WIP, no unit run"
    body = f"Last unit run: {counts[0]} passed, {counts[1]} failed ({counts[2]}).\n\n" if counts else ""
    return f"{version} checkpoint: {note} ({state})\n\n{body}{TRAILER}"


def main(argv=None, root=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("note")
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    root = root or ROOT
    code, branch = git("symbolic-ref", "--short", "HEAD", root=root)   # also names a branch with no commit yet
    if code or not branch:
        print("checkpoint: detached HEAD, not on a branch; refused")
        return 2
    if (root / LOCK).exists():
        print(f"checkpoint: a goal run is live ({LOCK}); it commits its own checkpoints; refused")
        return 2
    paths = a.paths or [p for p in DEFAULT_PATHS if (root / p).exists()]
    msg = message(milestone(root), a.note, unit_counts(root))
    _, changed = git("status", "--porcelain", "--", *paths, root=root)
    if not changed:
        print("checkpoint: nothing to commit in " + ", ".join(paths))
        return 0
    print(changed + "\n\n" + msg)
    if a.dry_run:
        return 0
    code, out = git("add", "--", *paths, root=root)
    if not code:
        code, out = git("commit", "-m", msg, root=root)
    print(out.splitlines()[0] if out else "")
    return code


if __name__ == "__main__":
    sys.exit(main())
