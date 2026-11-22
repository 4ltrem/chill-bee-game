#!/usr/bin/env python3
"""The end-of-day routine's mechanical steps as one script (queue #8); the decision log, Doris's findings, the
page publish and the commit stay in the skill (.claude/skills/end-of-day/SKILL.md), where judgement is needed.

    python -I _tools/end_of_day.py prep     # step 0 setup check, step 1 export, step 4.1 sync_docs; prints the
                                            # export folders and the next decision ID for step 2
    python -I _tools/end_of_day.py checks   # step 3 page rebuild, step 5 checks, step 6 staged-path guard

Each command stops at the first failing step and exits 1 with that step's last lines; on success it prints one
line per step. Standard library only.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import status  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
PY = [sys.executable, "-I"]
NEVER_STAGED = re.compile(r"(^|/)(session\.jsonl|manifest\.json)$|/subagents/|^_meta/sessions/runs/")


def run(label, cmd):
    """(ok, output) of one step, printed as one line."""
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           timeout=1800)
        out, ok = (p.stdout + p.stderr).strip(), p.returncode == 0
    except subprocess.TimeoutExpired:
        out, ok = "timed out after 30 min", False
    last = out.splitlines()[-1] if out else ""
    print(f"{'ok  ' if ok else 'FAIL'} {label}: {last[:160]}", flush=True)
    if not ok:
        print("\n".join(out.splitlines()[-15:]))
    return ok, out


def setup():
    """Step 0: the doc gate and the memory folder setting. Reports only; the skill fixes them."""
    problems = []
    if status.git("config", "--get", "core.hooksPath") != ".githooks":
        problems.append("core.hooksPath is not .githooks (run: git config core.hooksPath .githooks)")
    try:
        local = json.loads((ROOT / ".claude" / "settings.local.json").read_text(encoding="utf-8"))
        mem = str(local.get("autoMemoryDirectory", "")).replace("\\", "/").rstrip("/")
        if not mem.lower().endswith("_meta/memory"):
            problems.append("settings.local.json autoMemoryDirectory does not point at _meta/memory")
    except (OSError, ValueError):
        problems.append(".claude/settings.local.json missing or unreadable (autoMemoryDirectory)")
    print(("FAIL setup: " + "; ".join(problems)) if problems else "ok   setup: doc gate and memory folder set")
    return not problems


def prep():
    if not setup():
        return 1
    ok, out = run("export", PY + ["_tools/export_session.py", "--all"])
    if not ok:
        return 1
    folders = sorted(set(re.findall(r"-> (_meta/sessions/[^/\s]+)/", out)))
    print("     export folders: " + (", ".join(folders) or "none new (every export current)"))
    ok, _ = run("sync_docs", PY + ["_tools/sync_docs.py"])
    if not ok:
        return 1
    print(f"     next decision ID: {status.next_decision()} (step 2: write decisions.md, then stage and run Doris)")
    return 0


def staged_guard():
    bad = [p for p in status.git("diff", "--cached", "--name-only").splitlines() if NEVER_STAGED.search(p)]
    print(("FAIL staged: never-commit paths staged: " + ", ".join(bad[:5])) if bad
          else "ok   staged: no transcript, manifest or run folder staged")
    return not bad


def checks():
    steps = [("decision page", PY + ["_tools/decision_page.py"]),
             ("consistency", PY + ["_tools/consistency.py"]),
             ("test_generate", PY + ["_tools/test_generate.py"]),
             ("index", PY + ["_tools/index.py", "content", "research", "proposals/design", "proposals/balance"]),
             ("links", PY + ["_tools/links.py"])]
    for label, cmd in steps:
        if not run(label, cmd)[0]:
            return 1
    if not staged_guard():
        return 1
    print("     next: publish _meta/sessions/decision-comb.html to the page (Artifact tool), then commit (step 6)")
    return 0


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("phase", choices=["prep", "checks"])
    a = ap.parse_args(argv)
    return prep() if a.phase == "prep" else checks()


if __name__ == "__main__":
    sys.exit(main())
