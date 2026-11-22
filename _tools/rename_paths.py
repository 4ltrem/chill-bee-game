#!/usr/bin/env python3
"""Move report folders by a mapping file, then rewrite the old paths in the repo's text files (naming review, 2026-11-21).

    python -I _tools/rename_paths.py --move    [MAP]            # git mv each row (a plain move for untracked files)
    python -I _tools/rename_paths.py --rewrite [MAP] [--apply]  # dry run by default: per-file counts only

MAP (default _meta/drafts/naming/moves.tsv) holds `old<TAB>new` rows, repo-relative files or folders; `#` lines are
comments. Rows run in order, so a file row moves out of a folder before that folder's own row.

--rewrite is the one stated exception to the edit-lines rule (designer, 2026-11-21, option A): 512 references in
about 140 files. It changes only the old-path strings, never anything else: the text is matched as a whole path
(`reports/...` or `content/_runs/...`, not followed by a letter, digit, `_` or `-`, so `farm-0-2-0` never matches
inside `farm-0-2-0-r5`), line endings are kept byte for byte, and a file with no match is not written. It reads
tracked and untracked (not ignored) text files, minus the map itself, the naming review draft and this script.
Standard library only.
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP = "_meta/drafts/naming/moves.tsv"
TEXT = {".md", ".json", ".py", ".gd", ".txt", ".html", ".log", ".csv", ".tsv", ".cfg", ".yml", ".yaml", ".diff", ".patch"}
NEVER = {MAP, "_meta/drafts/naming/reports-naming-review.md", "_tools/rename_paths.py"}


def git(*args):
    p = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
    return p.returncode, (p.stdout + p.stderr).strip()


def rows(map_path):
    out = []
    for n, line in enumerate(Path(map_path).read_text(encoding="utf-8").splitlines(), 1):
        if line.strip() and not line.startswith("#"):
            old, sep, new = line.partition("\t")
            if not sep or not new.strip():
                sys.exit(f"{map_path}:{n}: expected old<TAB>new")
            out.append((old.strip().rstrip("/"), new.strip().rstrip("/")))
    return out


def move(pairs):
    moved = 0
    for old, new in pairs:
        src, dst = ROOT / old, ROOT / new
        if not src.exists():
            print(f"skip (not there): {old}")
            continue
        if dst.exists():
            sys.exit(f"stop: {new} already exists (row {old})")
        tracked = bool(git("ls-files", "--", old)[1])
        if new.startswith(old + "/"):   # a folder into its own subfolder: through a temporary name
            tmp = src.with_name(src.name + ".moving")
            step(old, tmp.relative_to(ROOT).as_posix(), tracked)
            old, src = tmp.relative_to(ROOT).as_posix(), tmp
        dst.parent.mkdir(parents=True, exist_ok=True)
        step(old, new, tracked)
        moved += 1
    print(f"moved {moved} of {len(pairs)} rows")


def step(old, new, tracked):
    if tracked:
        code, out = git("mv", "--", old, new)
        if code:
            sys.exit(f"git mv {old} {new} failed: {out}")
    else:
        shutil.move(str(ROOT / old), str(ROOT / new))


def short(path):
    """The form a doc writes: `reports/...` (also inside `game/reports/...`) or `content/_runs/...`."""
    return path[len("game/"):] if path.startswith("game/reports/") else path


def pattern(pairs):
    keys = sorted({short(o) for o, _ in pairs}, key=len, reverse=True)
    return re.compile(r"(?<![\w-])(" + "|".join(re.escape(k) for k in keys) + r")(?![\w-])")


def files():
    _, tracked = git("ls-files", "-z")
    _, other = git("ls-files", "-z", "--others", "--exclude-standard")
    names = [n for n in (tracked + "\0" + other).split("\0") if n]
    return sorted({n for n in names if Path(n).suffix.lower() in TEXT and n not in NEVER and (ROOT / n).is_file()})


def rewrite(pairs, apply):
    to = {short(o): short(n) for o, n in pairs}
    rx = pattern(pairs)
    total, touched = 0, 0
    for name in files():
        raw = (ROOT / name).read_bytes()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        new, n = rx.subn(lambda m: to[m.group(1)], text)
        if n:
            total, touched = total + n, touched + 1
            print(f"{n:4} {name}")
            if apply:
                (ROOT / name).write_bytes(new.encode("utf-8"))   # same bytes outside the matches: LF/CRLF kept
    print(f"{'rewrote' if apply else 'would rewrite'} {total} path(s) in {touched} file(s)")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("map", nargs="?", default=MAP)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--move", action="store_true")
    g.add_argument("--rewrite", action="store_true")
    ap.add_argument("--apply", action="store_true", help="with --rewrite: write the files (default: dry run)")
    a = ap.parse_args(argv)
    pairs = rows(ROOT / a.map)
    if a.move:
        move(pairs)
    else:
        rewrite(pairs, a.apply)
    return 0


if __name__ == "__main__":
    sys.exit(main())
