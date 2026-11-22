#!/usr/bin/env python3
"""Commit files to `main` while the main folder stays on a milestone branch (queue #7, L24).

    python -I _tools/commit_main.py -m "links.py: skip ignored folders" _tools/links.py AGENTS.md
    python -I _tools/commit_main.py -m "..." FILE... --push      # push only with the designer's yes
    python -I _tools/commit_main.py -m "..." FILE... --dry-run   # say what it would do

It does what the commit-to-main memory listed by hand: a worktree of local `main` inside the repo
(.claude/worktrees/commit-main, which the repo-only hook allows), the named files copied in as they stand in
this folder (a deleted file is deleted), a commit through main's own gate (`-c core.hooksPath=.githooks`: the
milestone's hook calls contract_check.py, which main lacks), an optional push that cannot hang on a hidden login
(GCM_INTERACTIVE=never, 90 s), and the worktree removed afterwards, also on failure (--keep keeps it to look at).
Prints the new commit. The milestone branch and this folder are never changed. Standard library only.
"""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WT = Path(".claude") / "worktrees" / "commit-main"


def git(root, *args, env=None, timeout=300):
    p = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8",
                       errors="replace", env={**os.environ, **(env or {})}, timeout=timeout)
    return p.returncode, (p.stdout + p.stderr).strip()


def ensure_ignored(root):
    """The worktree folder must be ignored, or links.py and `git status` see a second copy of the repo."""
    code, _ = git(root, "check-ignore", "-q", (WT / "x").as_posix())
    if code != 0:
        exclude = root / ".git" / "info" / "exclude"
        exclude.parent.mkdir(parents=True, exist_ok=True)
        with exclude.open("a", encoding="utf-8", newline="\n") as f:
            f.write("\n.claude/worktrees/\n")


def commit_main(root, message, files, branch="main", push=False, keep=False, dry=False, say=print):
    """Returns (exit code, text). files: repo-relative paths as they stand in `root`'s working tree."""
    root = Path(root)
    rel = [Path(f).as_posix() for f in files]   # Path drops a leading ./ (never lstrip: .claude would lose its dot)
    outside = [f for f in rel if f.startswith("../") or Path(f).is_absolute()]
    if outside or not rel:
        return 2, "name repo-relative files: " + (", ".join(outside) or "none given")
    code, cur = git(root, "rev-parse", "--abbrev-ref", "HEAD")
    if cur == branch:
        return 2, f"this folder is on {branch} already: commit here as usual"
    wt = root / WT
    if dry:
        return 0, (f"would: worktree {WT.as_posix()} of {branch}; copy {', '.join(rel)}; commit through "
                   f".githooks" + ("; push origin " + branch if push else "") + "; remove the worktree")
    if wt.exists():
        return 2, f"{WT.as_posix()} exists (a run left it): look, then `git worktree remove --force {WT.as_posix()}`"
    ensure_ignored(root)
    code, out = git(root, "worktree", "add", str(wt), branch)
    if code:
        return 1, "worktree add failed: " + out
    ok = False
    try:
        for f in rel:
            src, dst = root / f, wt / f
            if src.is_file():
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
            elif dst.exists():
                dst.unlink()
        code, out = git(wt, "add", "-A", "--", *rel)
        if code:
            return 1, "git add failed: " + out
        if git(wt, "diff", "--cached", "--quiet")[0] == 0:
            ok = True
            return 0, f"nothing to commit: {branch} already has these files as they are"
        code, out = git(wt, "-c", "core.hooksPath=.githooks", "commit", "-m", message)
        if code:
            return 1, "commit refused (main's gate or git): " + out[-1500:]
        _, sha = git(wt, "log", "--oneline", "-1")
        text = f"committed to {branch}: {sha}"
        if push:
            try:
                code, out = git(wt, "push", "origin", branch, env={"GCM_INTERACTIVE": "never"}, timeout=90)
            except subprocess.TimeoutExpired:
                code, out = 124, "timed out after 90 s"
            if code:
                return 1, text + f"; push failed ({out[-300:]}): the designer logs in, then `git push origin {branch}`"
            text += f"; pushed to origin/{branch}"
        ok = True
        return 0, text
    finally:
        if ok or not keep:
            git(root, "worktree", "remove", "--force", str(wt))
            git(root, "worktree", "prune")


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("files", nargs="+", help="repo-relative files to put on main as they stand here")
    ap.add_argument("-m", "--message", required=True)
    ap.add_argument("--branch", default="main")
    ap.add_argument("--push", action="store_true", help="push afterwards (only with the designer's yes)")
    ap.add_argument("--keep", action="store_true", help="keep the worktree when something fails")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    code, text = commit_main(ROOT, a.message, a.files, a.branch, a.push, a.keep, a.dry_run)
    print("commit_main: " + text)
    return code


if __name__ == "__main__":
    sys.exit(main())
