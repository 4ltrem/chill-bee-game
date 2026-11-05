#!/usr/bin/env python3
"""PreToolUse hook on Agent and Workflow: stop new agent launches before the plan's usage limit is hit.

Reads the newest plan-usage reading the status line saved (`_meta/usage/readings.jsonl`, written by
`_tools/statusline.py`) and, for a reading less than 60 minutes old:
  - 5-hour usage >= BLOCK (80%) or weekly >= WEEK_BLOCK (90%): denies the launch, with the reason, so
    the orchestrator waits for the reset or asks the designer;
  - 5-hour usage >= WARN (65%): lets it run and tells the orchestrator how close the limit is.
Agent runs cost 3-30% of the 5-hour window each (`_meta/agent-runs.md`), so 80% leaves room for the
run already in flight to finish. Thresholds can be changed with the environment variables
BUDGET_GUARD_BLOCK, BUDGET_GUARD_WARN and BUDGET_GUARD_WEEK_BLOCK.

Designer override: `python -I _tools/budget_guard.py --allow-for 60` writes `_meta/usage/override.json`,
which lets launches through for that many minutes. With no recent reading, launches are allowed.
Added 2026-11-05 after a run hit the 5-hour limit mid-task. Standard library only.
"""
import datetime
import json
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
READINGS = os.path.join(REPO, "_meta", "usage", "readings.jsonl")
OVERRIDE = os.path.join(REPO, "_meta", "usage", "override.json")
MAX_AGE = datetime.timedelta(minutes=60)


def now():
    return datetime.datetime.now(datetime.timezone.utc)


def parse_ts(text):
    return datetime.datetime.fromisoformat(text.replace("Z", "+00:00"))


def latest(path=READINGS):
    """Newest reading with a 5-hour figure, or None."""
    best = None
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                try:
                    r = json.loads(line)
                except ValueError:
                    continue
                if r.get("five_hour") is None:
                    continue
                best = r
    except OSError:
        return None
    return best


def overridden(path=OVERRIDE):
    try:
        with open(path, encoding="utf-8") as fh:
            return parse_ts(json.load(fh)["until"]) > now()
    except (OSError, ValueError, KeyError):
        return False


def decide(reading, block, warn, week_block, at=None):
    """Pure: ('deny'|'warn'|'allow', message) for one reading (tested in test_generate.py)."""
    at = at or now()
    if not reading:
        return "allow", ""
    age = at - parse_ts(reading["ts"])
    if age > MAX_AGE:
        return "allow", ""
    five, week = reading.get("five_hour") or 0, reading.get("seven_day") or 0
    mins = int(age.total_seconds() // 60)
    if five >= block or week >= week_block:
        return "deny", (f"Budget guard: plan usage is {five}% of the 5-hour window and {week}% of the week "
                        f"(reading {mins} min old; limits {block}% / {week_block}%). Don't start new agents: "
                        f"wait for the reset, or ask the designer to run `python -I _tools/budget_guard.py --allow-for 60`.")
    if five >= warn:
        return "warn", (f"Budget guard: 5-hour usage is {five}% (blocks at {block}%). Keep this run small, "
                        f"or tell the designer before launching more agents.")
    return "allow", ""


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv[:1] == ["--allow-for"]:
        minutes = int(argv[1]) if len(argv) > 1 else 60
        os.makedirs(os.path.dirname(OVERRIDE), exist_ok=True)
        with open(OVERRIDE, "w", encoding="utf-8") as fh:
            json.dump({"until": (now() + datetime.timedelta(minutes=minutes)).isoformat()}, fh)
        print(f"budget_guard: agent launches allowed for {minutes} minutes")
        return 0
    try:
        sys.stdin.read()
    except OSError:
        pass
    if overridden():
        return 0
    block = int(os.environ.get("BUDGET_GUARD_BLOCK", 80))
    warn = int(os.environ.get("BUDGET_GUARD_WARN", 65))
    week_block = int(os.environ.get("BUDGET_GUARD_WEEK_BLOCK", 90))
    verdict, msg = decide(latest(), block, warn, week_block)
    if verdict == "deny":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                                 "permissionDecisionReason": msg},
                          "systemMessage": msg}))
    elif verdict == "warn":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg},
                          "systemMessage": msg}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
