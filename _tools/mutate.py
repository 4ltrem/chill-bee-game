#!/usr/bin/env python3
"""Prove the tests catch real breakage: apply named code mutations to a copy of the game and run the tests.

    python -I _tools/mutate.py [NAME ...] [--file game/tests/mutations.json] [--suite unit] [--root game]

Replaces the hand-made "broken copies" Quinn built for each new test (8 full project copies in the
0.1.0 run). Mutations live in game/tests/mutations.json, Quinn's file:

    [{"name": "pop starts at 1.0", "file": "scripts/honeycomb.gd",
      "find": "Vector3(1.3, 1.0, 1.3)", "replace": "Vector3(1.0, 1.0, 1.0)",
      "expect": ["t_pop_tween_unchanged"], "suite": "unit"}]

`find` must occur exactly once in `file` (relative to the game folder). The game folder is copied once
to a temp folder (without builds/ and reports/); each mutation is applied, the suite is run there through
godot_run.py, and the file is restored. A mutation is CAUGHT when every test in `expect` fails (or, with
`expect` empty, when anything fails). Exit 0 only when every mutation was caught. Standard library only.
"""
import argparse
import json
import os
import shutil
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import godot_run  # noqa: E402


def failed_tests(result):
    names = set()
    for line in result["fails"]:
        parts = line.split()
        if len(parts) >= 2:
            names.add(parts[1])
    return names


def verdict(mutation, result):
    """Pure: CAUGHT / MISSED / BROKEN for one mutation's suite result (tested in test_generate.py)."""
    if result["status"] == "TIMEOUT":
        return "BROKEN", "suite timed out"
    failed = failed_tests(result)
    expect = mutation.get("expect") or []
    if expect:
        missing = [t for t in expect if t not in failed]
        return ("CAUGHT", f"failed: {', '.join(expect)}") if not missing else ("MISSED", f"still passing: {', '.join(missing)}")
    return ("CAUGHT", f"{len(failed)} tests failed") if result["status"] == "FAIL" else ("MISSED", "every test passed")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("names", nargs="*", help="run only these mutations (default: all)")
    ap.add_argument("--file", default=os.path.join(REPO, "game", "tests", "mutations.json"))
    ap.add_argument("--suite", default=None, help="override every mutation's suite")
    ap.add_argument("--root", default=os.path.join(REPO, "game"))
    ap.add_argument("--timeout", type=int, default=900)
    args = ap.parse_args(argv)
    mutations = json.load(open(args.file, encoding="utf-8"))
    if args.names:
        mutations = [m for m in mutations if m["name"] in args.names]
    if not mutations:
        print("mutate: no mutations to run")
        return 1
    tmp = tempfile.mkdtemp(prefix="cbg-mutate-")
    copy = os.path.join(tmp, "game")
    shutil.copytree(os.path.abspath(args.root), copy, ignore=shutil.ignore_patterns("builds", "reports"))
    os.makedirs(os.path.join(copy, "reports"), exist_ok=True)
    logdir = os.path.join(copy, "reports", "_runs", "mutate")
    os.makedirs(logdir, exist_ok=True)
    rows, all_caught = [], True
    try:
        for m in mutations:
            path = os.path.join(copy, m["file"])
            original = open(path, encoding="utf-8").read()
            count = original.count(m["find"])
            if count != 1:
                rows.append((m["name"], "BROKEN", f"`find` occurs {count} times in {m['file']}"))
                all_caught = False
                continue
            open(path, "w", encoding="utf-8", newline="").write(original.replace(m["find"], m["replace"]))
            try:
                result = godot_run.run_suite(args.suite or m.get("suite", "unit"), copy, logdir, args.timeout)
            finally:
                open(path, "w", encoding="utf-8", newline="").write(original)
            v, why = verdict(m, result)
            all_caught = all_caught and v == "CAUGHT"
            rows.append((m["name"], v, why))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    for name, v, why in rows:
        print(f"{v:7} {name}: {why}")
    print(f"mutate: {sum(1 for r in rows if r[1] == 'CAUGHT')} of {len(rows)} caught")
    return 0 if all_caught else 1


if __name__ == "__main__":
    sys.exit(main())
