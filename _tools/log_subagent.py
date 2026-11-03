#!/usr/bin/env python3
"""SubagentStop hook: log a finished Agent-tool subagent to _meta/agent-runs.md.

Claude Code runs this when a subagent launched with the Agent tool stops, with the hook input as
JSON on stdin (agent_type, agent_transcript_path, ...). It reads the subagent's own transcript and
appends one row to the "Subagent runs" table:

    | Martin (hiring-manager): hire Ruth | post-ICM | 47,200 | 345,056 | 26 | 93 s | claude-haiku-... |

Two token measures, because they differ several-fold:
  final context   - size of the conversation at the subagent's last call; the figure the Agent
                    tool reports, and the measure of every pre-ICM row in the log
  total processed - the sum over all its calls (each call re-sends the conversation, mostly as
                    cache reads); the measure generate.py logs
A subagent that stops more than once (it handed back while its own background work was still running)
updates its row instead of adding one: each row carries its transcript id in a hidden comment.
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

ROOT = Path(__file__).resolve().parent.parent
TABLE = "### Subagent runs (Agent tool, logged by the SubagentStop hook)"
HEADER = ("| Run | Phase | Final context | Total processed | Tool calls | Duration | Model |\n"
          "|---|---|---|---|---|---|---|")
INTRO = ("Logged automatically when a subagent launched with the Agent tool finishes. *Final context* is "
         "the size of the conversation at the subagent's last call (the Agent tool's own figure, and the "
         "measure of the pre-ICM rows above); *total processed* is the sum over all its calls, the "
         "measure `generate.py` logs.")
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
    return {"final": per_call[-1] if per_call else 0, "total": sum(per_call), "tools": tools,
            "seconds": seconds, "model": model or "?"}


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


def append_row(row, log, key=None):
    """Insert row at the end of the table, or replace the row tagged with the same key."""
    text = log.read_text(encoding="utf-8") if log.is_file() else ""
    lines = text.splitlines()
    tag = f"<!-- {key} -->" if key else None
    if tag and any(tag in l for l in lines):  # the same subagent stopped again: update its row
        lines = [row if tag in l else l for l in lines]
        log.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
        return
    if TABLE not in lines:  # create the table just before the Daily Budget section (or at the end)
        block = ["", TABLE, INTRO, HEADER]
        at = next((i for i, l in enumerate(lines) if l.startswith("## Daily Budget")), len(lines))
        lines[at:at] = block + [""]
    i = lines.index(TABLE) + 1
    while i < len(lines) and not lines[i].startswith("|"):
        i += 1
    while i < len(lines) and lines[i].startswith("|"):
        i += 1
    lines.insert(i, row)
    log.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def log_run(agent_type, transcript, log=None):
    m = measure(transcript)
    what = describe(transcript)
    name = roster_name(agent_type) + (f": {what}" if what else "")
    key = transcript.stem  # e.g. agent-a0f6be1b5fea20964: one row per subagent, however often it stops
    row = (f"| {name} <!-- {key} --> | post-ICM | {m['final']:,} | {m['total']:,} | {m['tools']} | "
           f"{m['seconds']} s | {m['model']} |")
    append_row(row, log or ROOT / "_meta" / "agent-runs.md", key)
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
    print(log_run(agent_type, transcript))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as e:  # a logging hook must never break the session
        print(f"log_subagent: {type(e).__name__}: {e}; run not logged", file=sys.stderr)
    sys.exit(0)
