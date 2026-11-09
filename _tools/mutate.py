#!/usr/bin/env python3
"""Prove the tests catch real breakage: apply named code mutations to a copy of the game and run the tests.

    python -I _tools/mutate.py [NAME ...] [--since GIT_REF] [--file game/tests/mutations.json] [--suite unit] [--root game]

--since REF runs only the mutations that are new or changed since that commit (designer, 2026-11-06: a
checkpoint proves its new tests, not all 45 again). Temp copies left by killed runs (older than 6 h) are
removed at the start.

Replaces the hand-made "broken copies" Quinn built for each new test (8 full project copies in the
0.1.0 run). Mutations live in game/tests/mutations.json, Quinn's file:

    [{"name": "pop starts at 1.0", "file": "scripts/honeycomb.gd",
      "find": "Vector3(1.3, 1.0, 1.3)", "replace": "Vector3(1.0, 1.0, 1.0)",
      "expect": ["t_pop_tween_unchanged"], "suite": "unit"}]

`find` must occur exactly once in `file` (relative to the game folder). The game folder is copied once
to a temp folder (without builds/ and reports/); each mutation is applied, the suite is run there through
godot_run.py, and the file is restored. A mutation is CAUGHT when every test in `expect` fails (or, with
`expect` empty, when anything fails). A unit mutation with `expect` runs only those tests, alone, through
the CB_ONLY env var of run_tests.gd (minutes saved per mutation); without `expect` the whole suite runs.
Each mutation logs to its own file. Exit 0 only when every mutation was caught. Standard library only.
"""
import argparse
import json
import os
import shutil
import sys
import re
import tempfile
import time

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


def verdict(mutation, result, red_before=frozenset()):
    """Pure: CAUGHT / MISSED / BROKEN for one mutation's suite result (tested in test_generate.py).
    red_before: tests already failing on the unmutated copy; a catch by one of them, or by a script error, proves
    nothing (D160: tests that prove more)."""
    if result["status"] == "TIMEOUT":
        return "BROKEN", "suite timed out"
    failed = failed_tests(result)
    expect = mutation.get("expect") or []
    stale = [t for t in expect if t in red_before]
    if stale:
        return "BROKEN", f"already failing without the mutation: {', '.join(stale)}"
    crashed = [t for t in expect if t in failed and all("script error" in l for l in result["fails"]
                                                        if l.split()[1:2] == [t])]
    if crashed:
        return "BROKEN", f"stopped by a script error, not an assertion: {', '.join(crashed)}; make the mutation a valid change"
    if expect:
        missing = [t for t in expect if t not in failed]
        return ("CAUGHT", f"failed: {', '.join(expect)}") if not missing else ("MISSED", f"still passing: {', '.join(missing)}")
    return ("CAUGHT", f"{len(failed)} tests failed") if result["status"] == "FAIL" else ("MISSED", "every test passed")


def mutation_env(mutation, suite):
    """Pure: extra env for the suite run; unit mutations with `expect` run only those tests (CB_ONLY)."""
    expect = mutation.get("expect") or []
    return {"CB_ONLY": ",".join(expect)} if expect and suite == "unit" else None


def changed_since(mutations, old):
    """Pure: the mutations that are new, or whose entry differs, compared with the list `old` (tested in test_generate.py)."""
    before = {m.get("name"): m for m in old}
    return [m for m in mutations if before.get(m.get("name")) != m]


def old_mutations(ref, path):
    """mutations.json as it was at git commit `ref` ([] when the file did not exist there)."""
    import subprocess
    rel = os.path.relpath(os.path.abspath(path), REPO).replace(os.sep, "/")
    out = subprocess.run(["git", "-C", REPO, "show", f"{ref}:{rel}"], capture_output=True, text=True, encoding="utf-8")
    return json.loads(out.stdout) if out.returncode == 0 else []


def sweep_stale(hours=6):
    """Remove cbg-mutate-* temp copies left by killed runs (older than `hours`)."""
    base = tempfile.gettempdir()
    for name in os.listdir(base):
        p = os.path.join(base, name)
        if name.startswith("cbg-mutate-") and os.path.isdir(p) and time.time() - os.path.getmtime(p) > hours * 3600:
            shutil.rmtree(p, ignore_errors=True)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("names", nargs="*", help="run only these mutations (default: all)")
    ap.add_argument("--since", help="run only mutations new or changed since this git commit")
    ap.add_argument("--file", default=os.path.join(REPO, "game", "tests", "mutations.json"))
    ap.add_argument("--suite", default=None, help="override every mutation's suite")
    ap.add_argument("--root", default=os.path.join(REPO, "game"))
    ap.add_argument("--timeout", type=int, default=900)
    args = ap.parse_args(argv)
    mutations = json.load(open(args.file, encoding="utf-8"))
    if args.names:
        mutations = [m for m in mutations if m["name"] in args.names]
    if args.since:
        mutations = changed_since(mutations, old_mutations(args.since, args.file))
    sweep_stale()
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
        expected = sorted({t for m in mutations if (args.suite or m.get("suite", "unit")) == "unit"
                           for t in m.get("expect") or []})
        red_before = set()
        if expected:   # the baseline: an expected test that fails unmutated catches every mutation for free
            base = godot_run.run_suite("unit", copy, logdir, args.timeout, env={"CB_ONLY": ",".join(expected)},
                                       log_name="unit-0-baseline")
            red_before = failed_tests(base) if base["status"] != "TIMEOUT" else set(expected)
            print(f"mutate baseline: {len(expected)} expected tests, {len(red_before)} already failing",
                  file=sys.stderr, flush=True)
        for i, m in enumerate(mutations, 1):
            path = os.path.join(copy, m["file"])
            original = open(path, encoding="utf-8").read()
            count = original.count(m["find"])
            if count != 1:
                rows.append((m["name"], "BROKEN", f"`find` occurs {count} times in {m['file']}"))
                all_caught = False
                continue
            open(path, "w", encoding="utf-8", newline="").write(original.replace(m["find"], m["replace"]))
            suite = args.suite or m.get("suite", "unit")
            slug = re.sub(r"[^a-z0-9]+", "-", m["name"].lower()).strip("-")[:40]
            started = time.time()
            try:
                result = godot_run.run_suite(suite, copy, logdir, args.timeout, env=mutation_env(m, suite),
                                             log_name=f"{suite}-{i}-{slug}")
            finally:
                open(path, "w", encoding="utf-8", newline="").write(original)
            v, why = verdict(m, result, red_before if suite == "unit" else frozenset())
            print(f"mutate {i}/{len(mutations)}: {m['name']} ... {v} in {int(time.time() - started)}s", file=sys.stderr, flush=True)
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
