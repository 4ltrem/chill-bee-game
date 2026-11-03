#!/usr/bin/env python3
"""Stop hook: log the orchestrator's (main session's) own tokens to _meta/agent-runs.csv.

Claude Code runs this when the main session finishes a turn, with the hook input as JSON on stdin
(session_id, transcript_path). It sums every API call in the session's transcript, by kind (input,
cache write, cache read, output), and upserts one "Orchestrator" row per session, keyed by the
session id, with plan usage % at the session's start and now. The SubagentStop hook logs subagents
separately; this row is the main session alone, so the two add up to the session's whole cost.

Headless `claude -p` runs started by generate.py set CHILLBEE_HEADLESS=1: they are agent runs that
generate.py logs itself, so they are skipped here. A hook must never break the session, so any
failure prints a warning to stderr and exits 0.

Test by hand:  python -I _tools/log_session.py --transcript PATH
Standard library only.
"""
import datetime
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import runlog  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TABLE = "Orchestrator"


def log_session(transcript, root=None):
    root = root or ROOT
    calls = runlog.calls(transcript)
    stamps = [ts for ts, _ in calls if ts]
    if not stamps:
        return None
    orch = runlog.orchestrator(transcript)
    start, end = min(stamps), max(stamps)
    f0, w0 = runlog.usage_at(start, root)
    f1, w1 = runlog.usage_at(end, root, after=True)
    models = []
    for line in Path(transcript).read_text(encoding="utf-8").splitlines():
        try:
            msg = json.loads(line).get("message") or {}
        except ValueError:
            continue
        if isinstance(msg, dict) and msg.get("model") and msg["model"] not in models and msg["model"] != "<synthetic>":
            models.append(msg["model"])
    iso = lambda t: t.astimezone(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    row = {"start": iso(start), "end": iso(end), "table": TABLE, "run": f"main session from {start.date()}",
           "agent": "Orchestrator (main session)", "phase": "post-ICM", "model": " ".join(models),
           "total_processed": sum(orch.values()), "turns": len(calls),
           "duration_s": round((end - start).total_seconds()), **orch,
           "five_hour_before": f0, "five_hour_after": f1, "seven_day_before": w0, "seven_day_after": w1,
           "key": Path(transcript).stem}
    runlog.upsert(row, root)
    return row


def main(argv):
    if os.environ.get("CHILLBEE_HEADLESS"):
        return
    if "--transcript" in argv:
        transcript = Path(argv[argv.index("--transcript") + 1])
    else:
        data = json.loads(sys.stdin.read() or "{}")
        if data.get("agent_id"):  # a Stop inside a subagent: SubagentStop logs it
            return
        transcript = Path(os.path.expanduser(data.get("transcript_path") or ""))
    if not transcript.is_file():
        print(f"log_session: no transcript at {transcript}; not logged", file=sys.stderr)
        return
    row = log_session(transcript)
    if row and "--transcript" in argv:
        print(f"logged orchestrator: {row['total_processed']:,} tokens over {row['turns']} calls")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as e:  # a logging hook must never break the session
        print(f"log_session: {type(e).__name__}: {e}; not logged", file=sys.stderr)
    sys.exit(0)
