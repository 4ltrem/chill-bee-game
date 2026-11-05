#!/usr/bin/env python3
"""Run the Godot test suites and print a short summary instead of the raw log.

    python -I _tools/godot_run.py [SUITE ...] [--root game] [--refresh] [--json FILE] [--markdown] [--timeout S]

Suites: unit (run_tests.gd, headless), start (a headless start, errors only), play (play_loop.gd),
measure (r4_measure.gd), snapshot (snapshot_pop.gd), ui (ui_bounds_pixels.gd), touch (touch_windowed.gd);
the windowed ones open a 720x1280 window. `all` runs every suite; no suite means `unit start`.

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
import time

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
GODOT = os.environ.get("GODOT", r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe")
WINDOW = ["--resolution", "720x1280", "--position", "0,0"]

SUITES = {
    "unit": {"script": "res://tests/run_tests.gd", "headless": True},
    "start": {"script": None, "headless": True},
    "play": {"script": "res://tests/play_loop.gd", "headless": False},
    "measure": {"script": "res://tests/r4_measure.gd", "headless": False},
    "snapshot": {"script": "res://tests/snapshot_pop.gd", "headless": False},
    "ui": {"script": "res://tests/ui_bounds_pixels.gd", "headless": False},
    "touch": {"script": "res://tests/touch_windowed.gd", "headless": False},
}
ALL = list(SUITES)

# Engine noise: printed by Godot 4.2.1's headless dummy renderer when meshes are freed (0.1 report).
NOISE = [re.compile(p) for p in (
    r'Parameter "m" is null',
    r"mesh_get_surface_count",
    r"^\s*at: mesh_get_surface_count",
    r"^\s*at: \w+ \(servers/rendering/dummy",
)]
TOTAL = re.compile(r"^---- (\d+) (passed|checks), (\d+) failed")
ERROR = re.compile(r"^(ERROR|SCRIPT ERROR|WARNING|USER ERROR|USER WARNING|Parse Error)\b")


def command(suite, root):
    spec = SUITES[suite]
    cmd = [GODOT]
    if spec["headless"]:
        cmd.append("--headless")
    cmd += ["--path", root]
    if spec["script"]:
        if not spec["headless"]:
            cmd += WINDOW
        cmd += ["-s", spec["script"]]
    else:
        cmd += ["--quit-after", "300"]
    return cmd


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
        elif s.startswith("COMPLETED"):
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
    else:
        ok = code == 0 and not fails and total is not None and total["failed"] == 0
        if not SUITES[suite]["headless"]:
            ok = ok and completed
        status = "PASS" if ok else ("TIMEOUT" if code is None else "FAIL")
    return {"suite": suite, "status": status, "exit": code, "total": total, "fails": fails,
            "measures": measures, "errors": errors[:20], "noise_dropped": noise, "completed": completed}


def progress(msg):
    print("godot_run: " + msg, file=sys.stderr, flush=True)


def run_suite(suite, root, logdir, timeout, env=None, log_name=None):
    """Run one suite; `env` is merged over os.environ, `log_name` names the log (default: the suite)."""
    cmd = command(suite, root)
    full_env = {**os.environ, **env} if env else None
    progress(f"{suite} ...")
    started = time.time()
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout, env=full_env)
        text, code = proc.stdout + proc.stderr, proc.returncode
    except subprocess.TimeoutExpired as exc:
        out = exc.stdout or b""
        text = out.decode("utf-8", "replace") if isinstance(out, bytes) else out
        code = None
    log = os.path.join(logdir, (log_name or suite) + ".log")
    with open(log, "w", encoding="utf-8") as fh:
        fh.write(" ".join(cmd) + "\n\n" + text)
    result = summarise(suite, text, code)
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
        lines.append(f"{r['status']:7} {r['suite']:9} {counts}  (exit {r['exit']}, {r['noise_dropped']} noise lines dropped)  {r['log']}")
        for f in r["fails"][:15]:
            lines.append("    " + f)
        if len(r["fails"]) > 15:
            lines.append(f"    ... {len(r['fails']) - 15} more FAIL lines in the log")
        for e in r["errors"][:5]:
            lines.append("    " + e)
        for m in r["measures"]:
            lines.append("    " + m)
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("suites", nargs="*")
    ap.add_argument("--root", default=os.path.join(REPO, "game"))
    ap.add_argument("--refresh", action="store_true", help="rebuild the import and class cache first")
    ap.add_argument("--json", help="also write the summary as JSON to this file")
    ap.add_argument("--markdown", action="store_true", help="print a Markdown table for reports")
    ap.add_argument("--timeout", type=int, default=900, help="seconds per suite")
    args = ap.parse_args(argv)
    suites = args.suites or ["unit", "start"]
    if suites == ["all"]:
        suites = ALL
    bad = [s for s in suites if s not in SUITES]
    if bad:
        ap.error(f"unknown suite(s) {bad}; choose from {ALL} or all")
    root = os.path.abspath(args.root)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    logdir = os.path.join(root, "reports", "_runs", stamp)
    os.makedirs(logdir, exist_ok=True)
    if args.refresh:
        refresh(root, args.timeout)
    results = [run_suite(s, root, logdir, args.timeout) for s in suites]
    print(render(results, args.markdown))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(results, fh, indent=2)
    return 0 if all(r["status"] == "PASS" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
