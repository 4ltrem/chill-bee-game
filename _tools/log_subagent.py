#!/usr/bin/env python3
"""SubagentStop hook: log a finished Agent-tool subagent to _meta/agent-runs.csv.

Claude Code runs this when a subagent launched with the Agent tool stops, with the hook input as
JSON on stdin (agent_type, agent_transcript_path, ...). It reads the subagent's own transcript and
upserts one row in the "Subagent runs" table of the run log (see runlog.py for the columns):
  - two token measures, because they differ several-fold:
      final context   - size of the conversation at the subagent's last call; the figure the Agent
                        tool reports, and the measure of every pre-ICM row in the log
      total processed - the sum over all its calls (each call re-sends the conversation, mostly as
                        cache reads); the measure generate.py logs
  - the orchestrator's tokens over the subagent's span, from the main session's transcript
    (<session>.jsonl beside the subagents/ folder), by kind;
  - plan usage % at the start and end, from the status line's readings.
A subagent that stops more than once (it handed back while its own background work was still running)
updates its row instead of adding one: the key is its transcript id.
Runs from generate.py are logged by generate.py itself; they launch no subagents, so this hook
never sees them. Internal agents (empty agent_type) are skipped. A hook must never break the
session, so any failure prints a warning to stderr and exits 0.

Test by hand:  python -I _tools/log_subagent.py --transcript PATH [--agent-type NAME]
Standard library only.
"""
import datetime
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import runlog  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TABLE = "Subagent runs"
USAGE_KEYS = ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")


def measure(transcript):
    """Final context, total processed, tool calls, seconds and model from a subagent transcript."""
    seen, per_call, tools, stamps, model = set(), [], 0, [], ""
    for line in transcript.read_text(encoding="utf-8").splitlines():
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("timestamp"):
            stamps.append(entry["timestamp"])
        msg = entry.get("message") or {}
        if entry.get("type") != "assistant" or not isinstance(msg, dict):
            continue
        model = msg.get("model") or model
        content = msg.get("content") if isinstance(msg.get("content"), list) else []
        tools += sum(1 for c in content if isinstance(c, dict) and c.get("type") == "tool_use")
        if msg.get("id") in seen:  # one API call can be split over several entries
            continue
        seen.add(msg.get("id"))
        usage = msg.get("usage") or {}
        per_call.append(sum(usage.get(k, 0) or 0 for k in USAGE_KEYS))
    seconds = 0
    if len(stamps) > 1:
        parse = lambda s: datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
        seconds = round((parse(stamps[-1]) - parse(stamps[0])).total_seconds())
    return {"final": per_call[-1] if per_call else 0, "total": sum(per_call), "tools": tools, "calls": len(per_call),
            "seconds": seconds, "model": model or "?", "start": stamps[0] if stamps else "",
            "end": stamps[-1] if stamps else ""}


def roster_name(agent_type):
    """'Martin (hiring-manager)' from the agent definition's description, else the type alone."""
    definition = ROOT / ".claude" / "agents" / f"{agent_type}.md"
    if definition.is_file():
        m = re.search(r"^description:\s*([A-Z][\w-]*),", definition.read_text(encoding="utf-8"), re.M)
        if m:
            return f"{m.group(1)} ({agent_type})"
    return agent_type


def describe(transcript):
    """The task description the Agent tool recorded beside the transcript, if any."""
    meta = transcript.with_suffix(".meta.json")
    try:
        return json.loads(meta.read_text(encoding="utf-8")).get("description", "")
    except (OSError, ValueError):
        return ""


def log_run(agent_type, transcript, root=None):
    root = root or ROOT
    m = measure(transcript)
    what = describe(transcript)
    start, end = runlog.parse_ts(m["start"]), runlog.parse_ts(m["end"])
    main_t = runlog.main_transcript(transcript)
    orch = runlog.orchestrator(main_t, start, end) if main_t and start else {}
    f0, w0 = runlog.usage_at(start, root)
    f1, w1 = runlog.usage_at(end, root, after=True)
    row = {"start": m["start"], "end": m["end"], "table": TABLE, "run": what, "agent": roster_name(agent_type),
           "phase": "post-ICM", "model": m["model"], "final_context": m["final"], "total_processed": m["total"],
           "tool_calls": m["tools"], "duration_s": m["seconds"], **orch,
           "five_hour_before": f0, "five_hour_after": f1, "seven_day_before": w0, "seven_day_after": w1,
           "key": transcript.stem}  # e.g. agent-a0f6be1b5fea20964: one row per subagent, however often it stops
    runlog.upsert(row, root)
    return row


def main(argv):
    if "--transcript" in argv:  # manual use
        transcript = Path(argv[argv.index("--transcript") + 1])
        agent_type = argv[argv.index("--agent-type") + 1] if "--agent-type" in argv else ""
        if not agent_type:
            meta = transcript.with_suffix(".meta.json")
            agent_type = json.loads(meta.read_text(encoding="utf-8")).get("agentType", "") if meta.is_file() else ""
    else:  # hook use
        data = json.loads(sys.stdin.read() or "{}")
        agent_type, transcript = data.get("agent_type") or "", Path(data.get("agent_transcript_path") or "")
    if not agent_type:
        return  # internal agent (prompt suggestions, /btw): not one of ours
    transcript = Path(str(transcript).replace("~", str(Path.home()), 1)) if str(transcript).startswith("~") else transcript
    if not transcript.is_file():
        print(f"log_subagent: no transcript at {transcript}; run not logged", file=sys.stderr)
        return
    row = log_run(agent_type, transcript)
    print(f"logged {row['agent']}: {row['run']} ({row['total_processed']:,} total processed)")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as e:  # a logging hook must never break the session
        print(f"log_subagent: {type(e).__name__}: {e}; run not logged", file=sys.stderr)
    sys.exit(0)
