#!/usr/bin/env python3
"""Run Doris, the Doc Auditor, on the staged changes and print her audit.

    git add -A
    python -I _tools/doc_audit.py [--since REF]

Builds the change set (`git diff --cached`, against REF if given, otherwise against HEAD), leaves
out history that records what was true at the time (blackboards, research briefs, content drafts,
session logs, fixtures, the run log), writes it to _meta/sessions/runs/<date>-doc-audit/ and runs
Doris headless (`claude -p --agent doc-auditor`), so she works the same in any session, including
one that has not loaded her agent type yet. Her transcript is kept beside the diff and her call is
logged to the Doc audits table in _meta/agent-runs.md. Prints her `DOC AUDIT:` block; exit 0 if CLEAN,
1 if she has findings or could not finish. Standard library only.
"""
import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402

AUDITOR = "doc-auditor"
LOG_TABLE = "### Doc audits"
HISTORY = ["content/_runs", "_meta/sessions", "research", "content/*.md", "_tools/fixtures", "_meta/agent-runs.md"]


def git(*args):
    out = subprocess.run(["git", *args], cwd=g.ROOT, capture_output=True, text=True, encoding="utf-8")
    if out.returncode:
        sys.exit(f"git {' '.join(args)} failed: {out.stderr.strip()}")
    return out.stdout


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--since", default="HEAD", help="compare the staged tree with this commit (default HEAD)")
    a = ap.parse_args()
    pathspec = ["--", "."] + [f":(exclude){h}" for h in HISTORY]
    stat = git("diff", "--cached", "--stat=120", a.since, *pathspec)
    diff = git("diff", "--cached", a.since, *pathspec)
    if not diff.strip():
        print("DOC AUDIT: CLEAN\n(no staged changes outside history)")
        return
    folder = g.ROOT / g.RUNS / f"{datetime.date.today()}-doc-audit"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "stat.txt").write_text(stat, encoding="utf-8")
    (folder / "diff.txt").write_text(diff, encoding="utf-8")
    rel = folder.relative_to(g.ROOT).as_posix()
    prompt = (f"End-of-day doc audit for Chill Bee Game: the staged changes since `{a.since}`. History is "
              f"excluded on purpose; do not audit it.\n\nRead the changed-file list first: `{rel}/stat.txt`.\n"
              f"Then the diff ({len(diff.splitlines()):,} lines), in parts if long: `{rel}/diff.txt`.\n\n"
              f"Many files may be new, so their whole text is the diff. Reply with only your audit block.")
    print(f"Doris auditing {len(stat.splitlines()) - 1} changed file(s)...", flush=True)
    try:
        reply, usage = g.run_agent(AUDITOR, prompt)
    except g.AgentError as e:
        sys.exit(f"doc audit failed: {e}")
    g.keep_transcript(usage, folder, "doris")
    g.NAMES[AUDITOR] = "Doris"
    g.log_runs(f"doc audit since {a.since}", [(AUDITOR, 1, usage)], table=LOG_TABLE)
    m = re.search(r"DOC AUDIT:.*", reply, re.S)
    block = "\n".join(l for l in (m.group(0) if m else reply).splitlines() if not l.strip().startswith("```"))
    (folder / "audit.md").write_text(block + "\n", encoding="utf-8")
    print(block)
    sys.exit(0 if block.startswith("DOC AUDIT: CLEAN") else 1)


if __name__ == "__main__":
    main()
