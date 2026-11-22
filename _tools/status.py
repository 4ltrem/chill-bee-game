#!/usr/bin/env python3
"""Where the workspace stands, from git, the goal boards, the run log, usage and live.json (queue #9).

    python -I _tools/status.py              # the plain summary for the terminal (or /status)
    python -I _tools/status.py --markdown   # the same facts as a block to paste into the session handoff

It prints facts only: branch and sync with origin, uncommitted work by folder, the last commits, each goal run's
result, the newest test run, open STOP lines in the handoff, the next decision ID, the usage reading and what runs
now. The judgement in the handoff (what to do next, what the designer said) stays hand-written. Read-only;
standard library only.
"""
import argparse
import collections
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import live  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def git(*args, root=None):
    try:
        p = subprocess.run(["git", *args], cwd=root or ROOT, capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=30)
        return p.stdout.strip() if p.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def front(path):
    """A board's front matter as a dict."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return {}
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    return dict(l.split(":", 1) for l in m.group(1).splitlines() if ":" in l) if m else {}


def uncommitted(root=None):
    """{top folder: count} of changed and untracked paths."""
    counts = collections.Counter()
    for line in git("status", "--porcelain", "-uall", root=root).splitlines():
        path = line[3:].strip().strip('"').split(" -> ")[-1]
        top = path.split("/")[0] if "/" in path else "(root)"
        if top in ("game", "_meta", "_tools", "content", "proposals") and path.count("/") >= 2:
            top = "/".join(path.split("/")[:2])
        counts[top] += 1
    return counts


def goal_runs(root=None):
    out = []
    for board in sorted(((root or ROOT) / "game" / "reports" / "goal").glob("*/blackboard.md")):
        f = front(board)
        waiting = ""
        text = board.read_text(encoding="utf-8")
        m = re.search(r"^## Waiting for the designer\n\n(.+)", text, re.M)
        if m and f.get("result", "").strip() == "waiting-designer":
            waiting = m.group(1).strip()[:120]
        out.append((board.parent.name, f.get("result", "?").strip(), waiting))
    return out


def newest_tests(root=None):
    """(folder, {suite: 'PASS 195' ...}) of the newest godot_run log folder."""
    runs = sorted(p for p in ((root or ROOT) / "game" / "reports" / "_runs").glob("2*") if p.is_dir())
    if not runs:
        return None, {}
    d = runs[-1]
    res = {}
    for log in sorted(d.glob("*.log")):
        text = log.read_text(encoding="utf-8", errors="replace")
        m = re.findall(r"^---- (\d+) (passed|checks), (\d+) failed", text, re.M)
        if m:
            n, _, failed = m[-1]
            res[log.stem] = f"{'PASS' if failed == '0' else 'FAIL'} {n}" + (f", {failed} failed" if failed != "0" else "")
        else:
            res[log.stem] = "no total"
    return d.relative_to(root or ROOT).as_posix(), res


def stops(root=None):
    """The handoff's STOP lines, shortened."""
    try:
        text = ((root or ROOT) / "_meta" / "memory" / "session-handoff.md").read_text(encoding="utf-8")
    except OSError:
        return []
    return [re.sub(r"\*\*", "", l).strip()[:140] for l in text.splitlines() if l.startswith("**STOP")]


def next_decision(root=None):
    ids = [int(n) for p in ((root or ROOT) / "_meta" / "sessions").glob("*/decisions.md")
           for n in re.findall(r"^### D(\d+)", p.read_text(encoding="utf-8"), re.M)]
    return f"D{max(ids) + 1}" if ids else "D1"


def usage(root=None):
    try:
        lines = ((root or ROOT) / "_meta" / "usage" / "readings.jsonl").read_text(encoding="utf-8").splitlines()
        r = json.loads(lines[-1])
    except (OSError, ValueError, IndexError):
        return "no reading"
    return f"5h {r.get('five_hour')}% · week {r.get('seven_day')}% (at {r.get('ts', '?')[11:16]}Z)"


def facts(root=None):
    root = root or ROOT
    branch = git("rev-parse", "--abbrev-ref", "HEAD", root=root)
    ab = git("rev-list", "--left-right", "--count", f"origin/{branch}...HEAD", root=root).split()
    sync = f"{ab[1]} ahead, {ab[0]} behind origin/{branch}" if len(ab) == 2 else "no origin branch"
    folder, tests = newest_tests(root)
    return {
        "branch": f"{branch} ({sync})",
        "uncommitted": uncommitted(root),
        "commits": git("log", "--oneline", "-5", root=root).splitlines(),
        "goal runs": goal_runs(root),
        "tests": (folder, tests),
        "stops": stops(root),
        "next decision": next_decision(root),
        "usage": usage(root),
        "running": [f"{r['agent']} {r['mins']}m" + (f" [{r['tag']}]" if r.get("tag") else "")
                    for r in live.running(root)],
    }


def render(f, markdown=False):
    b = "- " if markdown else "  "
    unc = f["uncommitted"]
    lines = [f"{'**Branch:**' if markdown else 'Branch:'} {f['branch']}",
             f"{'**Uncommitted:**' if markdown else 'Uncommitted:'} {sum(unc.values())} path(s)"
             + (": " + ", ".join(f"{k} {v}" for k, v in unc.most_common(8)) if unc else "")]
    lines.append("Last commits:")
    lines += [b + c for c in f["commits"]]
    lines.append("Goal runs:")
    lines += [b + f"{run}: {res}" + (f" ({w})" if w else "") for run, res, w in f["goal runs"]] or [b + "none"]
    folder, tests = f["tests"]
    lines.append(f"Newest test run: {folder or 'none'}" + (" · " + ", ".join(f"{k} {v}" for k, v in tests.items())
                                                           if tests else ""))
    lines.append("Open STOPs in the handoff:")
    lines += [b + s for s in f["stops"]] or [b + "none"]
    lines.append(f"Next decision ID: {f['next decision']} · Usage: {f['usage']}")
    lines.append("Running now: " + (" · ".join(f["running"]) or "nothing"))
    return "\n".join(lines)


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--markdown", action="store_true", help="a block to paste into the session handoff")
    a = ap.parse_args(argv)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    print((f"**Facts ({stamp}, `_tools/status.py`):**\n\n" if a.markdown else f"Status {stamp}\n")
          + render(facts(), a.markdown))
    return 0


if __name__ == "__main__":
    sys.exit(main())
