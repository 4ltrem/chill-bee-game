#!/usr/bin/env python3
"""PreToolUse hook on Agent and Workflow: stop new agent launches before the plan's usage limit is hit.

Reads the newest plan-usage reading the status line saved (`_meta/usage/readings.jsonl`, written by
`_tools/statusline.py`) and, for a reading less than 60 minutes old, the agent type being launched:
  - 5-hour usage + that agent type's average logged cost (average_costs(), from `_meta/agent-runs.csv`; COST
    for types with no logged run; average not highest, designer 2026-11-09) > CAP (95%): deny,
    so a cheap agent (Doris, Vera: ~1%) still runs late in the window while Quinn (~29%) stops near 66%;
  - weekly >= WEEK_CAP (95%): deny every agent;
  - a heavy agent (cost >= 10: Bob, Patricia, Quinn, unknown) while weekly usage is more than WEEK_SLACK
    (10) points ahead of an even pace through the week: deny, so the week lasts until its reset;
  - 5-hour usage >= WARN (65%): allow, and say how close the limit is.
A denial tells the orchestrator to wait for the reset or ask the designer. The week's reset comes from the
reading (`week_resets`, when the status line provides it) or from WEEK_RESET, any past reset time, rolled
forward by 7 days. Set by the designer 2026-11-05 (the flat 80% block stopped a 1% Doris run with 22% left).
Environment overrides: BUDGET_GUARD_CAP, BUDGET_GUARD_WARN, BUDGET_GUARD_WEEK_CAP, BUDGET_GUARD_WEEK_SLACK,
BUDGET_GUARD_WEEK_RESET.

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
WEEK = datetime.timedelta(days=7)
WEEK_RESET = "2026-11-07T13:59:00+00:00"   # Sat 8:59am Toronto, from /usage (2026-11-05)
# largest 5-hour cost logged per agent type in _meta/agent-runs.csv (2026-11-05), rounded up; Workflow = several agents
COST = {"qa-build-engineer": 30, "programmer": 27, "builder": 16, "general-purpose": 10, "progression-tree-expert": 5,
        "modeler": 3, "style-critic": 3, "content-critic": 3, "writer": 3, "doc-auditor": 2, "hiring-manager": 2,
        "research-assistant": 3, "gameplay-architect": 5, "compliance-officer": 5, "audiophile": 5,
        "Explore": 3, "web-fetch": 2, "script-runner": 3, "Workflow": 40}   # script-runner (Rex, Haiku): estimate, no runs logged yet
UNKNOWN = 25
RUNS = os.path.join(REPO, "_meta", "agent-runs.csv")


def average_costs(path=RUNS):
    """Average 5-hour cost (five_hour_after - five_hour_before, rounded up) per agent type, from the logged runs.
    The type is the parenthesised part of the `agent` column ("Patricia (programmer)"); a run whose window reset
    mid-run (after < before) is skipped. Types with no logged run keep COST. Designer 2026-11-09: average, not highest."""
    import csv
    import math
    sums = {}
    try:
        with open(path, encoding="utf-8", newline="") as fh:
            for row in csv.DictReader(fh):
                name = row.get("agent") or ""
                if "(" not in name:
                    continue
                kind = name[name.rindex("(") + 1:].rstrip(") ")
                try:
                    delta = float(row["five_hour_after"]) - float(row["five_hour_before"])
                except (KeyError, TypeError, ValueError):
                    continue
                if delta < 0:
                    continue
                total, n = sums.get(kind, (0.0, 0))
                sums[kind] = (total + delta, n + 1)
    except OSError:
        return dict(COST)
    costs = dict(COST)
    costs.update({k: math.ceil(t / n) for k, (t, n) in sums.items()})
    return costs


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


def week_pace(at, reset):
    """Percent of the week elapsed at `at`, for a week ending at `reset` (any past or future reset, rolled by 7 days)."""
    while reset <= at:
        reset += WEEK
    while reset - WEEK > at:
        reset -= WEEK
    return 100.0 * (at - (reset - WEEK)) / WEEK


def decide(reading, agent, at=None, cap=95, warn=65, week_cap=95, slack=10, reset=None, costs=None):
    """Pure: ('deny'|'warn'|'allow', message) for one reading and the agent type launched (tested in test_generate.py).
    `costs`: per-type 5-hour cost (main passes average_costs()); COST when not given."""
    at = at or now()
    if not reading:
        return "allow", ""
    age = at - parse_ts(reading["ts"])
    if age > MAX_AGE:
        return "allow", ""
    five, week = reading.get("five_hour") or 0, reading.get("seven_day") or 0
    cost = (costs or COST).get(agent, UNKNOWN)
    reset = parse_ts(reading.get("week_resets") or reset or WEEK_RESET)
    pace = week_pace(at, reset)
    mins = int(age.total_seconds() // 60)
    tail = (f" (reading {mins} min old). Don't start it: wait for the reset, or ask the designer to run "
            f"`python -I _tools/budget_guard.py --allow-for 60`.")
    if five + cost > cap:
        return "deny", (f"Budget guard: 5-hour usage is {five}% and a {agent or 'agent'} run costs {cost}% on average, "
                        f"over the {cap}% cap" + tail)
    if week >= week_cap:
        return "deny", f"Budget guard: weekly usage is {week}% (cap {week_cap}%)" + tail
    if cost >= 10 and week > pace + slack:
        return "deny", (f"Budget guard: weekly usage is {week}% with {pace:.0f}% of the week gone, more than {slack} "
                        f"points ahead of pace, so heavy agents ({agent or 'agent'}) wait" + tail)
    if five >= warn:
        return "warn", (f"Budget guard: 5-hour usage is {five}%, week {week}% ({pace:.0f}% of the week gone). "
                        f"Keep this run small, or tell the designer before launching more agents.")
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
    if argv[:1] == ["--costs"]:
        for kind, cost in sorted(average_costs().items(), key=lambda kv: -kv[1]):
            print(f"{kind:26} {cost}%")
        return 0
    try:
        event = json.loads(sys.stdin.read() or "{}")
    except (OSError, ValueError):
        event = {}
    if overridden():
        return 0
    tool = event.get("tool_name", "")
    agent = "Workflow" if tool == "Workflow" else ((event.get("tool_input") or {}).get("subagent_type") or "general-purpose")
    env = os.environ.get
    verdict, msg = decide(latest(), agent, cap=int(env("BUDGET_GUARD_CAP", 95)), warn=int(env("BUDGET_GUARD_WARN", 65)),
                          week_cap=int(env("BUDGET_GUARD_WEEK_CAP", 95)), slack=int(env("BUDGET_GUARD_WEEK_SLACK", 10)),
                          reset=env("BUDGET_GUARD_WEEK_RESET"), costs=average_costs())
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
