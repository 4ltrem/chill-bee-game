#!/usr/bin/env python3
"""Run the Godot test suites and print a short summary instead of the raw log.

    python -I _tools/godot_run.py [SUITE ...] [--root game] [--refresh] [--json FILE] [--markdown] [--timeout S]
                                  [--only T1,T2] [--time-scale X] [--skip-x1] [--set KEY=VALUE ...]

--only, --time-scale and --skip-x1 set CB_ONLY, CB_TIME_SCALE and CB_SKIP_X1=1 for the Godot run (run_tests.gd
reads them), so no shell `VAR=value` prefix is needed: Claude Code cannot allow-list such prefixes cleanly. An
env var already set in the caller's environment still works when its flag is not given. --set KEY=VALUE goes after
`--`; run_tests.gd (unit) lays it over the reset config for the whole run and prints "Config overrides (--set)";
the windowed suites ignore it for now.

Suites: unit (run_tests.gd, headless), start (a headless start, errors only), play (play_loop.gd),
measure (r4_measure.gd), snapshot (snapshot_pop.gd), ui (ui_bounds_pixels.gd), touch (touch_windowed.gd);
the windowed ones open a 720x1280 window. `all` runs every test suite; no suite means `unit start`.
`start` always runs first when asked for; if a script fails to parse there, the other suites are SKIPPED (L53).
Shot runs (by name only, not in `all`; PASS = exit 0 + COMPLETED): lid (lid_shots.gd, the hive lid's close shot every
10% plus per-node penetration, into ROOT/../game/reports/votes/lid-close/<YYYY-MM-DD>/); fixture (make_recording_fixture.gd, rewrites
tests/fixtures/recording_fill_and_back.json; PASS = exit 0 + its "wrote" line).

Why: agents used to read Godot's raw output, hundreds of lines a run, much of it engine noise (the
headless dummy renderer's `mesh_get_surface_count` errors). Each raw log now goes to
game/reports/_runs/<stamp>/<suite>.log and the agent sees only: the result, the counts, each FAIL line,
each MEASURE line, and how many noise lines were dropped. `--refresh` first rebuilds Godot's import
and class cache (needed after a new `class_name` or in a fresh checkout or worktree).

Every suite prints `PASS  ...` / `FAIL  ...` lines, a `---- N passed|checks, M failed` total, optional
`MEASURE ...` lines and, for windowed suites, `COMPLETED`. Exit code 0 only when every suite passed.
Standard library only.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import threading
import time

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)  # -I leaves the script's folder off sys.path
from godot_path import GODOT  # noqa: E402
import live  # noqa: E402
WINDOW = ["--resolution", "720x1280", "--position", "0,0"]

SUITES = {
    "unit": {"script": "res://tests/run_tests.gd", "headless": True, "sets": True},   # reads --set (test_base.gd)
    "start": {"script": None, "headless": True},
    "play": {"script": "res://tests/play_loop.gd", "headless": False},
    "measure": {"script": "res://tests/r4_measure.gd", "headless": False},
    "snapshot": {"script": "res://tests/snapshot_pop.gd", "headless": False},
    "ui": {"script": "res://tests/ui_bounds_pixels.gd", "headless": False},
    "touch": {"script": "res://tests/touch_windowed.gd", "headless": False},
    # shot runs: no pass/fail total; PASS = exit 0 + COMPLETED. --out is relative to the checkout root (the folder above game/)
    "lid": {"script": "res://tests/lid_shots.gd", "headless": False, "shots": True, "args": ["--out=game/reports/votes/lid-close/{date}"]},
    # fixture runs: rewrite a test fixture by driving the game; PASS = exit 0 + the `done` line
    "fixture": {"script": "res://tests/make_recording_fixture.gd", "headless": True, "shots": True, "done": "wrote "},
}
ALL = [s for s in SUITES if not SUITES[s].get("shots")]   # `all` = the test suites; shot runs are asked for by name

# Engine noise: printed by Godot 4.2.1's headless dummy renderer when meshes are freed (0.1 report).
NOISE = [re.compile(p) for p in (
    r'Parameter "m" is null',
    r"mesh_get_surface_count",
    r"^\s*at: mesh_get_surface_count",
    r"^\s*at: \w+ \(servers/rendering/dummy",
)]
TOTAL = re.compile(r"^---- (\d+) (passed|checks), (\d+) failed")
# L41: a flat 900 s cut the grown unit suite (218 tests, ~4.5 s each at x6) at 198 passed, twice. The unit timeout now
# follows the test count, within a floor and a hard cap; other suites keep 900 s. `--timeout S` overrides both.
SUITE_TIMEOUT, UNIT_BASE_S, UNIT_PER_TEST_S, UNIT_CAP_S = 900, 300, 6, 1800
ERROR = re.compile(r"^(ERROR|SCRIPT ERROR|WARNING|USER ERROR|USER WARNING|Parse Error)\b")
# L53: 0.3.1 C4's duplicate `at_second_stop()` left main.gd unparsable and every suite still ran into its timeout (30 min
# for one round). `start` (a few seconds) now runs first; a script that fails to parse there skips the other suites.
PARSE_BROKEN = re.compile(r"Parse Error|Failed to load script")


def start_first(suites):
    """Pure: the suites in run order, `start` moved to the front when asked for (L53)."""
    return (["start"] + [s for s in suites if s != "start"]) if "start" in suites else list(suites)


def parse_broken(result):
    """Pure: the `start` result shows a script that does not parse (L53)."""
    return result["suite"] == "start" and any(PARSE_BROKEN.search(e) for e in result["errors"])


def skipped(suite):
    """The summary of a suite not run because a script does not parse (L53)."""
    return {"suite": suite, "status": "SKIPPED", "exit": None, "total": None,
            "fails": ["FAIL  not run: a script does not parse (see the start suite's errors)"], "measures": [],
            "errors": [], "noise_dropped": 0, "completed": False, "log": "-"}


def command(suite, root, sets=()):
    """`sets`: --set KEY=VALUE config overrides, passed as user args after `--`, as ui_shots.py passes them to
    ui_compare_shots.gd; the suite script applies them (obstacles item 7)."""
    spec = SUITES[suite]
    cmd = [GODOT]
    if spec["headless"]:
        cmd.append("--headless")
    cmd += ["--path", root]
    if spec["script"]:
        if not spec["headless"]:
            cmd += WINDOW
        cmd += ["-s", spec["script"]]
        if spec.get("args") or sets:
            today = time.strftime("%Y-%m-%d")   # dated shot folders, never a moving "now" (naming review)
            cmd += ["--"] + [x.replace("{date}", today) for x in spec.get("args", [])] + list(sets)
    else:
        cmd += ["--quit-after", "300"]
    return cmd


def deaf_to_sets(suites, sets):
    """Pure: the suites that would drop --set without a word (obstacles item 7's tail: only run_tests.gd applies
    config overrides; start, the windowed suites and the shot runs don't)."""
    return [s for s in suites if sets and not SUITES[s].get("sets")]


def summarise(suite, text, code):
    """Pure: turn one suite's raw output into a summary dict (tested in test_generate.py)."""
    fails, measures, errors, noise = [], [], [], 0
    total = None
    completed = False
    for line in text.splitlines():
        if any(p.search(line) for p in NOISE):
            noise += 1
            continue
        s = line.rstrip()
        if s.startswith("FAIL"):
            fails.append(s[:240])
        elif s.startswith("MEASURE"):
            measures.append(s[:300])
        elif s.startswith(SUITES[suite].get("done", "COMPLETED")):
            completed = True
        elif ERROR.match(s.strip()):
            errors.append(s.strip()[:240])
        m = TOTAL.match(s)
        if m:
            n, kind, failed = int(m.group(1)), m.group(2), int(m.group(3))
            total = {"passed": n if kind == "passed" else n - failed, "failed": failed, "checks": n if kind == "checks" else n + failed}
    if suite == "start":
        ok = code == 0 or (code == 1 and not errors)   # 4.2.1 exits 1 even for an empty project (0.1 report)
        status = "PASS" if ok and not errors else "FAIL"
    elif SUITES[suite].get("shots"):
        status = "PASS" if code == 0 and completed else ("TIMEOUT" if code is None else "FAIL")
    else:
        ok = code == 0 and not fails and total is not None and total["failed"] == 0
        if not SUITES[suite]["headless"]:
            ok = ok and completed
        status = "PASS" if ok else ("TIMEOUT" if code is None else "FAIL")
    return {"suite": suite, "status": status, "exit": code, "total": total, "fails": fails,
            "measures": measures, "errors": errors[:20], "noise_dropped": noise, "completed": completed}


def progress(msg):
    print("godot_run: " + msg, file=sys.stderr, flush=True)


def stream(cmd, timeout, env, step=None):
    """Run cmd, reading its output line by line so the live view can count PASS/FAIL lines as they come (L5);
    return (text, exit code), the code None on a timeout (the process is killed)."""
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                            errors="replace", env=env)
    timed = []
    timer = threading.Timer(timeout, lambda: (timed.append(1), proc.kill()))
    timer.start()
    lines, passed, failed = [], 0, 0
    try:
        for line in proc.stdout:
            lines.append(line)
            s = line.strip()
            if s.startswith(("PASS", "FAIL")) and step:
                passed, failed = passed + s.startswith("PASS"), failed + s.startswith("FAIL")
                name = (s.split()[1:2] or [""])[0]
                step.note(f"{passed} passed" + (f", {failed} failed" if failed else "") + f" · {name}"[:70])
        proc.wait()
    finally:
        timer.cancel()
    return "".join(lines), (None if timed else proc.returncode)


def run_suite(suite, root, logdir, timeout, env=None, log_name=None, sets=()):
    """Run one suite; `env` is merged over os.environ, `log_name` names the log (default: the suite)."""
    cmd = command(suite, root, sets)
    full_env = {**os.environ, **env} if env else None
    progress(f"{suite} ...")
    started = time.time()
    with live.step(suite + ("" if not log_name or log_name == suite else f" ({log_name})")) as step:
        text, code = stream(cmd, timeout, full_env, step)
        result = summarise(suite, text, code)
        t = result.get("total")
        step.result = result["status"] + (f" ({t['passed']} passed, {t['failed']} failed)" if t else "")
        step.ok = result["status"] == "PASS"
    log = os.path.join(logdir, (log_name or suite) + ".log")
    with open(log, "w", encoding="utf-8") as fh:
        fh.write(" ".join(cmd) + "\n\n" + text)
    secs = int(time.time() - started)
    progress(f"{suite} done in {secs // 60}m{secs % 60:02d}s ({result['status']})")
    result["log"] = os.path.relpath(log, REPO).replace(os.sep, "/")
    return result


def refresh(root, timeout):
    subprocess.run([GODOT, "--headless", "--editor", "--path", root, "--quit-after", "1500"],
                   capture_output=True, timeout=timeout)


def render(results, markdown=False):
    lines = []
    if markdown:
        lines += ["| Suite | Result | Passed | Failed | Log |", "|---|---|---|---|---|"]
        for r in results:
            t = r["total"] or {}
            lines.append(f"| {r['suite']} | {r['status']} | {t.get('passed', '-')} | {t.get('failed', '-')} | `{r['log']}` |")
        for r in results:
            for m in r["measures"]:
                lines.append(f"- {r['suite']}: {m}")
            for f in r["fails"]:
                lines.append(f"- {r['suite']}: {f}")
        return "\n".join(lines)
    for r in results:
        t = r["total"]
        counts = f"{t['passed']} passed, {t['failed']} failed" if t else "no total line"
        exit_note = f"godot exit {r['exit']}"
        if r["suite"] == "start":   # errors-only suite: no total line by design; 4.2.1 exits 1 on a clean start
            counts = f"{len(r['errors'])} errors"
            exit_note += " (1 is normal here)" if r["exit"] == 1 else ""
        lines.append(f"{r['status']:7} {r['suite']:9} {counts}  ({exit_note}, {r['noise_dropped']} noise lines dropped)  {r['log']}")
        for f in r["fails"][:15]:
            lines.append("    " + f)
        if len(r["fails"]) > 15:
            lines.append(f"    ... {len(r['fails']) - 15} more FAIL lines in the log")
        for e in r["errors"][:5]:
            lines.append("    " + e)
        for m in r["measures"]:
            lines.append("    " + m)
    return "\n".join(lines)


def unit_test_count(root, env=None):
    """The unit tests a run will start: the CB_ONLY list when one is set, else every `func t_` in tests/test_*.gd."""
    only = ({**os.environ, **(env or {})}).get("CB_ONLY", "")
    if only.strip():
        return len([t for t in only.split(",") if t.strip()])
    tests = os.path.join(root, "tests")
    n = 0
    for name in (os.listdir(tests) if os.path.isdir(tests) else []):
        if name.startswith("test_") and name.endswith(".gd"):
            with open(os.path.join(tests, name), encoding="utf-8", errors="replace") as fh:
                n += len(re.findall(r"^func t_", fh.read(), re.M))
    return n


def suite_timeout(suite, root, given=None, env=None):
    """Seconds one suite may run: `given` (--timeout) when set; for unit, UNIT_BASE_S + UNIT_PER_TEST_S per test,
    at least SUITE_TIMEOUT and at most UNIT_CAP_S; else SUITE_TIMEOUT."""
    if given:
        return given
    if suite != "unit":
        return SUITE_TIMEOUT
    return min(UNIT_CAP_S, max(SUITE_TIMEOUT, UNIT_BASE_S + UNIT_PER_TEST_S * unit_test_count(root, env)))


def suite_env(args):
    """Pure: the CB_* env the CLI flags ask for (None when no flag is given; os.environ then applies as before)."""
    env = {}
    if args.only:
        env["CB_ONLY"] = args.only
    if args.time_scale:
        env["CB_TIME_SCALE"] = str(args.time_scale)
    if args.skip_x1:
        env["CB_SKIP_X1"] = "1"
    return env or None


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):   # 0.2 T8.1: French/em-dash test output crashed the cp1252 console print
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("suites", nargs="*")
    ap.add_argument("--root", default=os.path.join(REPO, "game"))
    ap.add_argument("--refresh", action="store_true", help="rebuild the import and class cache first")
    ap.add_argument("--json", help="also write the summary as JSON to this file")
    ap.add_argument("--markdown", action="store_true", help="print a Markdown table for reports")
    ap.add_argument("--timeout", type=int, help="seconds per suite (default: 900; unit follows its test count, "
                                                 "capped at 1800, L41)")
    ap.add_argument("--only", help="comma list of test names to run alone (sets CB_ONLY)")
    ap.add_argument("--time-scale", help="Engine.time_scale for the unit tests, e.g. 6 (sets CB_TIME_SCALE)")
    ap.add_argument("--skip-x1", action="store_true", help="skip the real-time X1_TESTS (sets CB_SKIP_X1=1)")
    ap.add_argument("--set", action="append", default=[], metavar="KEY=VALUE",
                    help="a config override for the run (e.g. shop_layout=0), passed after `--` as ui_shots.py does; repeatable")
    args = ap.parse_args(argv)
    if any("=" not in s or s.startswith("=") for s in args.set):
        ap.error("--set takes KEY=VALUE")
    env = suite_env(args)
    suites = args.suites or (["unit"] if args.set else ["unit", "start"])
    if suites == ["all"]:
        suites = ALL
    bad = [s for s in suites if s not in SUITES]
    if bad:
        ap.error(f"unknown suite(s) {bad}; choose from {ALL} or all")
    deaf = deaf_to_sets(suites, args.set)
    if deaf:
        ap.error(f"--set is not read by {deaf} (only unit applies it); run those without --set")
    root = os.path.abspath(args.root)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    logdir = os.path.join(root, "reports", "_runs", stamp)
    os.makedirs(logdir, exist_ok=True)
    if args.refresh:
        refresh(root, args.timeout or SUITE_TIMEOUT)
    results = []
    for s in start_first(suites):   # L53: start first; an unparsable script skips the rest
        if results and parse_broken(results[0]):
            results.append(skipped(s))
            continue
        results.append(run_suite(s, root, logdir, suite_timeout(s, root, args.timeout, env), env=env, sets=args.set))
    print(render(results, args.markdown))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(results, fh, indent=2)
    return 0 if all(r["status"] == "PASS" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
