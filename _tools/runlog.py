#!/usr/bin/env python3
"""The agent run log: one CSV row per agent run, plus the plan-usage readings around it.

    _meta/agent-runs.csv          every run (hooks, generate.py, critic_check.py, doc_audit.py append here)
    _meta/usage/readings.jsonl    plan-usage readings saved by the status line (local, gitignored)

Nobody reads the CSV whole: sync_docs.py writes its summary into _meta/agent-runs.md, and
`python -I _tools/runlog.py --calibrate SINCE [UNTIL]` works out tokens per 1% of plan usage over a span.

Columns (blank when not known):
  start, end            ISO UTC times of the run's first and last transcript entry
  table                 the task type, e.g. "Subagent runs", "Content generation", "Orchestrator"
  run, agent, phase, model, tool_calls, turns, duration_s
  final_context         size of the conversation at the run's last call
  total_processed       sum over all its calls
  orch_input, orch_cache_write, orch_cache_read, orch_output
                        the main session's (orchestrator's) tokens over the same span, by kind
  five_hour_before/after, seven_day_before/after
                        plan usage % at the start and end (the status line's rate_limits)
  key                   a stable id (transcript or session id): a run logged again replaces its row
  note
Standard library only.
"""
import csv
import datetime
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
ROOT = Path(__file__).resolve().parent.parent
FIELDS = ["start", "end", "table", "run", "agent", "phase", "model", "final_context", "total_processed",
          "tool_calls", "turns", "duration_s", "orch_input", "orch_cache_write", "orch_cache_read",
          "orch_output", "five_hour_before", "five_hour_after", "seven_day_before", "seven_day_after",
          "key", "note"]
ORCH = ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens")
ORCH_FIELDS = ("orch_input", "orch_cache_write", "orch_cache_read", "orch_output")


def log_path(root=None):
    return (root or ROOT) / "_meta" / "agent-runs.csv"


def readings_path(root=None):
    return (root or ROOT) / "_meta" / "usage" / "readings.jsonl"


def read(root=None):
    path = log_path(root)
    if not path.is_file():
        return []
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def upsert(row, root=None):
    """Append row, or replace the row with the same non-empty key."""
    rows = read(root)
    row = {k: ("" if row.get(k) is None else row.get(k)) for k in FIELDS}
    at = next((i for i, r in enumerate(rows) if row["key"] and r.get("key") == row["key"]), None)
    if at is None:
        rows.append(row)
    else:
        rows[at] = row
    path = log_path(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, lineterminator="\n")
        w.writeheader()
        w.writerows(rows)
    import sync_docs  # keep the summary in _meta/agent-runs.md current with the log
    sync_docs.sync(root=root or ROOT)


def parse_ts(s):
    return datetime.datetime.fromisoformat(s.replace("Z", "+00:00")) if s else None


def usage_at(ts, root=None, after=False):
    """(five_hour, seven_day) %: the last reading at or before ts, or with after the first at or after it."""
    path = readings_path(root)
    if not path.is_file() or ts is None:
        return None, None
    best = None
    for line in path.read_text(encoding="utf-8").splitlines():
        try:
            r = json.loads(line)
            t = parse_ts(r["ts"])
        except (ValueError, KeyError, TypeError):
            continue
        if not after and t <= ts:
            best = r
        elif after and t >= ts:
            best = r
            break
    if best is None and after:  # nothing newer yet: the latest reading
        return usage_at(datetime.datetime.max.replace(tzinfo=datetime.timezone.utc), root)
    return (best.get("five_hour"), best.get("seven_day")) if best else (None, None)


def calls(transcript):
    """(timestamp, usage) for each API call in a transcript, once per call."""
    seen, out = set(), []
    for line in Path(transcript).read_text(encoding="utf-8").splitlines():
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        msg = entry.get("message") or {}
        if entry.get("type") != "assistant" or not isinstance(msg, dict) or not msg.get("usage"):
            continue
        if msg.get("id") in seen:  # one API call can be split over several entries
            continue
        seen.add(msg.get("id"))
        out.append((parse_ts(entry.get("timestamp")), msg["usage"]))
    return out


def orchestrator(transcript, start=None, end=None):
    """The main session's tokens by kind, over [start, end] (the whole session when both are None)."""
    sums = dict.fromkeys(ORCH_FIELDS, 0)
    for ts, usage in calls(transcript):
        if ts is None or (start and ts < start) or (end and ts > end):
            continue
        for field, k in zip(ORCH_FIELDS, ORCH):
            sums[field] += usage.get(k, 0) or 0
    return sums


def main_transcript(agent_transcript):
    """<session>/subagents/agent-x.jsonl -> <session>.jsonl (the orchestrator's transcript)."""
    p = Path(agent_transcript)
    session = p.parent.parent if p.parent.name == "subagents" else None
    candidate = session.with_suffix(".jsonl") if session else None
    return candidate if candidate and candidate.is_file() else None


def session_transcript(session_id):
    """This machine's transcript of a session, found by id (paths are never stored in the log)."""
    hits = sorted((Path.home() / ".claude" / "projects").glob(f"*/{session_id}.jsonl"))
    return hits[0] if hits else None


def num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def calibrate(since, until=None, root=None):
    """Tokens per 1% of plan usage over a span, counting subagents and the orchestrator."""
    since, until = parse_ts(since), parse_ts(until) if until else datetime.datetime.now(datetime.timezone.utc)
    rows = [r for r in read(root) if r.get("table") != "Orchestrator" and parse_ts(r.get("start"))
            and since <= parse_ts(r["start"]) <= until]
    sub_final = sum(int(r["final_context"] or 0) for r in rows)
    sub_total = sum(int(r["total_processed"] or 0) for r in rows)
    orch = dict.fromkeys(ORCH_FIELDS, 0)
    for session in {r["key"] for r in read(root) if r.get("table") == "Orchestrator" and r.get("key")}:
        path = session_transcript(session)
        if path:
            for k, v in orchestrator(path, since, until).items():
                orch[k] += v
    f0, w0 = usage_at(since, root)
    f1, w1 = usage_at(until, root)
    return {"runs": len(rows), "subagent_final": sub_final, "subagent_total": sub_total, "orchestrator": orch,
            "five_hour": (f0, f1), "seven_day": (w0, w1)}


def main(argv):
    if argv[:1] == ["--calibrate"] and len(argv) >= 2:
        c = calibrate(argv[1], argv[2] if len(argv) > 2 else None)
        print(json.dumps(c, indent=2))
        w0, w1 = (num(x) for x in c["seven_day"])
        if w0 is None or w1 is None or w1 <= w0:
            print("no weekly change recorded over this span; nothing to calibrate")
            return
        o = c["orchestrator"]
        for label, tokens in [("subagent total processed + orchestrator, all kinds",
                               c["subagent_total"] + sum(o.values())),
                              ("subagent total processed + orchestrator, without cache reads",
                               c["subagent_total"] + sum(o.values()) - o["orch_cache_read"])]:
            print(f"{label}: {tokens:,} tokens / {w1 - w0:g}% = {tokens / (w1 - w0):,.0f} per 1% weekly")
        return
    print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
