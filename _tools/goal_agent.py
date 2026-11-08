#!/usr/bin/env python3
"""The goal-oriented coding agent (M3, Assignment 5): find what a spec asks for that the game lacks, order it, build it.

    python -I _tools/goal_agent.py SPEC --plan                 # scan, gaps, scores: no agents, no game changes
    python -I _tools/goal_agent.py SPEC --dry-run              # the plan, then the next step's briefs and commands
    python -I _tools/goal_agent.py SPEC [--max-goals N] [--goal ID] [--run NAME]   # the loop

SPEC is a file in game/specs/ (e.g. 0.1.4-ui-placement.md). Spec: game/specs/m3-goal-agent.md.

The reasoning layer is plain code, tested in _tools/test_goal_agent.py, and spends no tokens:
  - parse_spec(): each numbered Change becomes a goal (C1, C2, ...), each Quinn contract line a test goal
    (T1.1 = item 1's first line), and Patricia's "node-name changes first, as a handoff" line a handoff goal (H).
  - scan() + gaps(): the evidence for each goal in the game: config keys (`@export var` in game_config.gd),
    node names (in any scene), tests registered in tests/run_tests.gd under a group comment that names the spec
    (or its version and step, e.g. "# 0.1.3a speed"), their PASS/FAIL in the newest unit.log, the node handoff
    file, and the goal ledger (game/reports/goal/ledger.json: goals this agent built to green). Each goal is
    done, partial or missing, with that evidence.
  - priority_score(): a weighted sum (WEIGHTS below) of unblocks, value and cost, times ready.
The loop (only the code-writing step calls agents): until gaps() has nothing left to build, re-scan, score,
take the top goal and build it: Patricia's handoff, Patricia and Bob in parallel for a Change, Quinn for test
goals (all ready test goals of the same item in one call). Each agent is a fresh headless `claude -p` given only
its spec slice (generate.run_agent). Then contract_check.py, godot_run.py (unit + start), ui_shots.py after
scene work, mutate.py --since after new tests. Failures go to the folder's owners, at most MAX_FIX_ROUNDS
rounds, then the run stops for the designer. A green step gets a ledger line and a checkpoint commit on the
milestone branch (never main, never a push); a step green only because no file changed is held for the
designer instead, like an open question, until its spec text changes or --accept. It stops when nothing is left, when budget_guard denies an agent
(the run pauses: run it again to resume), when a goal is ambiguous (Process 1), or after the fix rounds.

The blackboard is game/reports/goal/RUN/blackboard.md (RUN defaults to the spec's version), in the shared format of
_templates/blackboard.md: front matter with `result:`, the Request, each pass (in full the first time, then only the
rows that changed), each step with its briefs linked from briefs/, Waiting for the designer / Resumed, and one Result
rewritten in place with every call of the run (blackboard.calls.json). Only build runs and --accept write it; --plan
and --dry-run print to the console (--plan still writes gaps.json). No agent reads it. Agent calls are logged to the run log (table "Goal agent").
Standard library only.
"""
import argparse
import concurrent.futures
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import budget_guard  # noqa: E402
import generate as g  # noqa: E402
import pick_match  # noqa: E402
import runlog  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
PROGRAMMER, BUILDER, QA = "programmer", "builder", "qa-build-engineer"
OWNERS = {"Patricia": PROGRAMMER, "Bob": BUILDER, "Quinn": QA}
CRITIC = "style-critic"   # Vera: the style check and the pick match on every Bob scene change (designer, 2026-11-08)
g.NAMES.update({PROGRAMMER: "Patricia", BUILDER: "Bob", QA: "Quinn", CRITIC: "Vera"})
LOOKS = ("pick match", "style")   # checks whose failures are Bob's alone
FOLDERS = {PROGRAMMER: "scripts/", BUILDER: "scenes/ and materials/", QA: "tests/"}
LOG_TABLE = "Goal agent"
TOOLS = "Bash,Read,Grep,Glob,Write,Edit"   # Patricia, Bob and Quinn run contract_check and Godot

# priority_score(): every weight in one place. score = ready * sum(weight * factor).
WEIGHTS = {
    "unblocks": 3.0,   # per not-done goal that waits on this one (node contract and config before scripts, scripts before tests)
    "value": 2.0,      # 3 = a play-test fix, 2 = a designer feature, 1 = housekeeping or a handoff
    "cost": -1.0,      # the owners' average 5-hour usage per run in agent-runs.csv, in units of 10%
}
VALUE = {"playtest": 3, "feature": 2, "housekeeping": 1}
COST_UNIT = 10.0
MAX_FIX_ROUNDS = 2
FIX_MAX_TURNS = 15   # approved 2026-11-08: Patricia's T14 fix 1 ran 36 turns, 777k tokens, 25 min
REMOVED = re.compile(r"\b(removed?|retired?|goes away|deleted?)\b", re.I)   # a node in such a sentence must be absent
AMBIGUOUS = re.compile(r"\bTBD\b|\bto be decided\b|\bopen question", re.I)
ENV = {"CB_TIME_SCALE": "6", "CB_SKIP_X1": "1"}   # routine runs: x6, the real-time tests are the designer's (D102)

STOP = {"a", "an", "the", "and", "or", "of", "to", "in", "on", "at", "is", "it", "its", "as", "by", "be", "for", "with",
        "from", "that", "this", "each", "every", "any", "no", "not", "its", "than", "are", "one", "two", "stay", "stays",
        "designer", "item", "items", "test", "tests", "when", "only", "same", "way", "view", "views", "shot", "spec"}


# ---------------------------------------------------------------------------------------------- spec parsing
def words(text):
    """Distinct content words, crudely stemmed (frames -> frame), for keyword matching."""
    out = set()
    for w in re.findall(r"[a-z]{3,}", text.lower()):
        if w in STOP:
            continue
        out.add(w[:-1] if w.endswith("s") and not w.endswith("ss") and len(w) > 4 else w)
    return out


def backticked(text):
    return re.findall(r"`([^`]+)`", text)


def is_key(tok):
    return re.fullmatch(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)+", tok) is not None


def is_node(tok):
    return re.fullmatch(r"[A-Z][a-z0-9]+(?:[A-Z][A-Za-z0-9]*)+", tok) is not None


def item_numbers(text):
    """Item numbers named in a line: "Item 2", "items 1 and 3", "Item 3: ... Item 4: ..."."""
    nums = []
    for m in re.finditer(r"\bitems?\s+(\d+(?:\s*(?:,|and|&)\s*\d+)*)", text, re.I):
        nums += [int(n) for n in re.findall(r"\d+", m.group(1))]
    return sorted(set(nums))


def section(text, title):
    m = re.search(rf"^## {re.escape(title)}\b.*?$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def front(text):
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    return dict(re.findall(r"^(\w+):\s*(.*)$", m.group(1), re.M)) if m else {}


def parse_changes(body):
    """[(number, title, text)] of the numbered Changes, and the text of a top-level Config paragraph."""
    changes, config, cur = [], "", None
    for line in body.splitlines():
        m = re.match(r"^(\d+)\.\s+\*\*(.+?)\*\*(.*)$", line)
        if m:
            cur = [int(m.group(1)), m.group(2).strip(), line]
            changes.append(cur)
        elif re.match(r"^\*\*Config and Dev mode\*\*", line):
            config, cur = line, None
        elif re.match(r"^\S", line):
            cur = None
        elif cur is not None and line.strip():
            cur[2] += "\n" + line
    return [tuple(c) for c in changes], config


def parse_contract(body):
    """{owner: [lines]} for Patricia, Bob and Quinn; Quinn's lines carry the "Item N" header above them."""
    blocks, owner = {}, None
    for line in body.splitlines():
        m = re.match(r"^- \*\*(\w+)\b", line)
        if m:
            owner = m.group(1) if m.group(1) in OWNERS else None
            if owner:
                blocks.setdefault(owner, [])
                head = re.sub(r"^- \*\*\w+ \(`[^`]*`\):?\*\*:?,?\s*", "", line).strip()
                if owner == "Quinn":
                    blocks[owner].append(("head", head))
                elif head:
                    blocks[owner].append(("line", head))
            continue
        if owner is None or not line.strip():
            continue
        s = line.strip()
        if s.startswith("- "):
            blocks[owner].append(("line", s[2:]))
        elif owner == "Quinn":
            blocks[owner].append(("head", s))
    return blocks


def match_items(text, changes):
    """Items a line belongs to: named ones, else the change(s) sharing the most content words (all on 0 or a tie).
    A line about mutations proves every new test, so it covers every change."""
    numbers = [n for n, _, _ in changes]
    named = [n for n in item_numbers(text) if n in numbers]   # "report open item 6" is not a change of a 2-change spec
    if named:
        return named
    if re.search(r"\bmutations?\b", text, re.I):
        return numbers
    w = words(text)
    scores = {n: len(w & words(t)) for n, _, t in changes}
    best = max(scores.values(), default=0)
    top = [n for n, s in scores.items() if s == best]
    return top if best else [n for n, _, _ in changes]   # a tie covers the tied changes, not every change


def value_of(title, text):
    first = text.splitlines()[0] if text else ""
    if re.search(r"housekeeping", title, re.I):
        return VALUE["housekeeping"]
    if re.search(r"play-?test", first + " " + text, re.I):
        return VALUE["playtest"]
    return VALUE["feature"]


def parse_spec(path):
    """The spec's goals: {id: goal}. Goal fields: id, kind, item(s), title, text, owners, keys, nodes, value, depends."""
    text = Path(path).read_text(encoding="utf-8")
    meta = front(text)
    version = meta.get("version") or re.match(r"[\d.]+[a-z]?", Path(path).stem).group(0)
    changes, config = parse_changes(section(text, "Changes"))
    contract = parse_contract(section(text, "Contract"))
    steps = {}   # "0.1.3a speed row (item 1)" -> {"a": [1]}
    for m in re.finditer(rf"\*\*{re.escape(version)}([a-z])\*\*[^(]*\(([^)]*)\)", text):
        steps[m.group(1)] = item_numbers(m.group(2))
    goals = {}
    for n, title, body in changes:
        goals[f"C{n}"] = {"id": f"C{n}", "kind": "change", "items": [n], "title": title, "text": body,
                          "owners": [], "keys": [], "nodes": [], "lines": {}, "value": value_of(title, body),
                          "depends": []}
    # config keys: those inside a change belong to it; a top-level Config paragraph's go to the change they name best
    for n, _, body in changes:
        if "Config and Dev mode" in body:
            goals[f"C{n}"]["keys"] += [t for t in backticked(body.split("Config and Dev mode", 1)[1]) if is_key(t)]
    loose = []
    for key in [t for t in backticked(config) if is_key(t)]:
        kw = words(key.replace("_", " "))
        scores = {n: len(kw & words(body)) for n, _, body in changes}
        best = max(scores.values(), default=0)
        top = [n for n, s in scores.items() if s == best]
        if best and len(top) == 1:
            goals[f"C{top[0]}"]["keys"].append(key)
        else:
            loose.append(key)
    if loose:
        goals["CFG"] = {"id": "CFG", "kind": "change", "items": [], "title": "Config and Dev mode", "text": config,
                        "owners": ["Patricia"], "keys": loose, "nodes": [], "lines": {}, "value": VALUE["feature"],
                        "depends": []}
    handoff = False
    for owner in ("Patricia", "Bob"):
        for _, line in contract.get(owner, []):
            nums = item_numbers(line)
            if owner == "Patricia" and re.search(r"\bhandoff\b", line, re.I):
                handoff = True
                continue
            if not nums and re.search(r"config keys", line, re.I):
                nums = [n for n, *_ in changes if goals[f"C{n}"]["keys"]]
                if "CFG" in goals:
                    goals["CFG"]["lines"].setdefault(owner, []).append(line)
            for n in nums:
                if f"C{n}" in goals:
                    goal = goals[f"C{n}"]
                    goal["lines"].setdefault(owner, []).append(line)
                    if owner not in goal["owners"]:
                        goal["owners"].append(owner)
    for goal in goals.values():
        if goal["keys"] and "Patricia" not in goal["owners"]:
            goal["owners"].insert(0, "Patricia")
        own = goal["text"] + " " + " ".join(l for ls in goal["lines"].values() for l in ls)
        gone = {t for s in re.split(r"(?<=[.;])\s", own) if REMOVED.search(s) for t in backticked(s) if is_node(t)}
        goal["nodes"] = sorted({t for t in backticked(own) if is_node(t)} - gone)
        goal["removed"] = sorted(gone)
        goal["picks"] = pick_match.pairs(own) if goal["kind"] == "change" else []   # (live prop, picked variant)
    if handoff:
        goals = {"H": {"id": "H", "kind": "handoff", "items": [], "title": "Node handoff (Patricia to Bob)",
                       "text": "She writes any node-name changes first, as a handoff (Process 5).",
                       "owners": ["Patricia"], "keys": [], "nodes": [], "lines": {}, "value": VALUE["housekeeping"],
                       "depends": []}, **goals}
        for goal in goals.values():
            if goal["kind"] == "change" and "Bob" in goal["owners"]:
                goal["depends"].append("H")
    # Quinn: each line a test goal, on the item(s) it names, its "Item N" header, or the best keyword match
    counts, context = {}, None
    for kind, line in contract.get("Quinn", []):
        if kind == "head":
            context = item_numbers(line) or None
            body = re.sub(r"^Items?\s+\d+[^:]*:\s*", "", line) if context else line
            if not body or re.match(r"^Items?\s+\d+[^:]*:?\s*$", line) or re.search(r"measured (on|at)", line) \
                    and len(line) < 120:
                continue
            line = body
        items = context if context and not item_numbers(line) else match_items(line, changes)
        first = items[0] if len(items) == 1 else 0
        counts[first] = counts.get(first, 0) + 1
        gid = f"T{first}.{counts[first]}" if first else f"T.{counts[first]}"
        deps = [f"C{n}" for n in items if f"C{n}" in goals]
        val = VALUE["housekeeping"] if re.search(r"\bmutations?\b", line, re.I) else \
            max((goals[d]["value"] for d in deps), default=VALUE["feature"])   # mutations verify; they come last
        goals[gid] = {"id": gid, "kind": "test", "items": items, "title": line[:70], "text": line,
                      "owners": ["Quinn"], "keys": [], "nodes": [], "lines": {"Quinn": [line]}, "value": val,
                      "depends": deps}
    return {"file": Path(path).name, "version": version, "status": meta.get("status", ""), "steps": steps,
            "goals": goals}


# ---------------------------------------------------------------------------------------------- the scan
def newest_unit_log(game):
    logs = sorted((game / "reports" / "_runs").glob("*/unit.log"), key=lambda p: p.parent.name)
    return logs[-1] if logs else None


def scan(game, ledger_path=None):
    """What exists in the game: config keys, node names, registered tests by group comment, last unit results."""
    game = Path(game)
    cfg = (game / "scripts" / "game_config.gd")
    keys = set(re.findall(r"^@export var (\w+)", cfg.read_text(encoding="utf-8"), re.M)) if cfg.is_file() else set()
    nodes = set()
    for scene in game.rglob("*.tscn"):
        if "variants" in scene.parts or "retired" in scene.parts:
            continue
        nodes |= set(re.findall(r'^\[node name="([^"]+)"', scene.read_text(encoding="utf-8"), re.M))
    groups, x1 = [], set()
    runner = game / "tests" / "run_tests.gd"
    if runner.is_file():
        src = runner.read_text(encoding="utf-8")
        m = re.search(r"const X1_TESTS[^=]*=\s*\[(.*?)\]", src, re.S)
        x1 = set(re.findall(r'"(t_\w+)"', m.group(1))) if m else set()
        body = re.search(r"var tests: Array\[String\] = \[(.*?)^\s*\]", src, re.S | re.M)
        comment = ""
        for line in (body.group(1) if body else "").splitlines():
            s = line.strip()
            if s.startswith("#"):
                comment = s.lstrip("# ").strip()
                groups.append((comment, []))
            elif groups or s:
                if not groups:
                    groups.append(("", []))
                groups[-1][1].extend(re.findall(r'"(t_\w+)"', s))
    results, log = {}, newest_unit_log(game)
    if log:
        for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^(PASS|FAIL)\s+(t_\w+)", line)
            if m:
                results[m.group(2)] = m.group(1)
    handoffs = sorted(p.name for p in (game / "specs").glob("*handoff*.md"))
    handoff_text = {p.name: p.read_text(encoding="utf-8") for p in (game / "specs").glob("*handoff*.md")}
    ledger = {}
    ledger_path = Path(ledger_path) if ledger_path else game / "reports" / "goal" / "ledger.json"
    if ledger_path.is_file():
        ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    return {"keys": keys, "nodes": nodes, "groups": groups, "x1": x1, "results": results,
            "handoff_text": handoff_text,
            "unit_log": log.relative_to(game.parent).as_posix() if log and game.parent in log.parents else
            (str(log) if log else None), "handoffs": handoffs, "ledger": ledger}


def tests_for(spec, found, items):
    """Tests registered under a group comment for this spec, restricted to the given items when the comment says."""
    v, out = re.escape(spec["version"]), []
    for comment, tests in found["groups"]:
        m = re.match(rf"^{v}(?:([a-z])\b|\s|$)", comment)
        if not (spec["file"] in comment or m):
            continue
        named = item_numbers(comment)
        if not named and m and m.group(1):
            named = spec["steps"].get(m.group(1), [])
        if not items or not named or set(named) & set(items):
            out += tests
    return out


def gaps(spec, found):
    """Each goal's status (done | partial | missing), its evidence, and whether it is built and waits on its tests."""
    report = {}
    ledger = found["ledger"].get(spec["file"], {})
    questions = open_questions(spec, found)
    changes = [g for g in spec["goals"].values() if g["kind"] == "change" and g["items"]]
    for gid, goal in spec["goals"].items():
        ev = []
        for k in goal["keys"]:
            ev.append({"kind": "config", "name": k, "ok": k in found["keys"]})
        for nm in goal["nodes"]:
            ev.append({"kind": "node", "name": nm, "ok": nm in found["nodes"]})
        for nm in goal.get("removed", []):
            ev.append({"kind": "node removed", "name": nm, "ok": nm not in found["nodes"]})
        if goal["kind"] == "handoff":
            hand = [h for h in found["handoffs"] if h.startswith(spec["version"])]
            ev.append({"kind": "handoff", "name": hand[0] if hand else f"game/specs/{spec['version']}-node-handoff.md",
                       "ok": bool(hand)})
        tests = tests_for(spec, found, goal["items"]) if goal["kind"] != "handoff" else []
        for t in tests:
            r = found["results"].get(t)
            ok = r == "PASS" or (r is None and t in found["x1"])
            ev.append({"kind": "test", "name": t, "ok": ok, "result": r or ("x1, designer plays" if t in found["x1"]
                                                                           else "not run")})
        entry = ledger.get(gid, {})
        held = entry.get("held") if entry.get("text") == text_hash(goal) else None   # a spec edit lifts the hold
        built = gid in ledger and "held" not in entry
        if built:
            ev.append({"kind": "ledger", "name": ledger[gid].get("commit") or ledger[gid].get("run", ""), "ok": True})
        present = [e for e in ev if e["ok"] or (e["kind"] == "test")]
        code = [e for e in ev if e["kind"] in ("config", "node", "node removed", "handoff")]
        if goal["kind"] == "handoff":
            status = "done" if built or all(e["ok"] for e in code) else "missing"
        elif tests and all(e["ok"] for e in ev):
            status = "done"
        elif present or (code and any(e["ok"] for e in code)):
            status = "partial"
        else:
            status = "missing"
        # a Quinn line added after the spec's tests were built (0.1.4 T14.4) shares its item's green tests: once
        # the ledger holds a test goal of the same single item, this one is done only when it is in the ledger too
        # (lines Quinn built before the goal agent, and spec-wide mutation lines, keep the old evidence rule)
        siblings = [g for g in ledger if g != gid and spec["goals"].get(g, {}).get("kind") == "test"
                    and spec["goals"][g]["items"] == goal["items"]]
        if goal["kind"] == "test" and status == "done" and not built and len(goal["items"]) == 1 and siblings:
            status = "partial"
            ev.append({"kind": "ledger", "name": "not built: its item's tests predate this line", "ok": False})
        # only the ledger says a change was built: a node it names may predate it (0.1.4 item 8's HintLabel)
        waits = status == "partial" and goal["kind"] == "change" and built
        asks = [q for q in questions if goal["kind"] == "change" and set(q[0]) & set(goal["items"])
                and len(q[0]) < len(changes)]
        report[gid] = {"status": status, "evidence": ev, "built": built, "waits_on_tests": waits,
                       "questions": [q[1] for q in asks] + ([held] if held else []),
                       "ambiguous": (bool(AMBIGUOUS.search(goal["text"])) or bool(asks) or bool(held))
                                    and status != "done"}
    return report


def open_questions(spec, found):
    """[(items, question)] from the "## Open questions" of this version's node handoff (Process 1: they stop a goal).
    The designer answers by editing the question out, or marking it "(answered"."""
    changes = [(g["items"][0], g["title"], g["text"]) for g in spec["goals"].values() if g["kind"] == "change"
               and g["items"]]
    out = []
    for name, text in found.get("handoff_text", {}).items():
        if not name.startswith(spec["version"]):
            continue
        for q in re.findall(r"^\d+\.\s+(.+)$", section(text, "Open questions"), re.M):
            if "(answered" not in q.lower():
                out.append((match_items(q, changes), q.strip()))
    return out


# ---------------------------------------------------------------------------------------------- scoring
def owner_costs(rows):
    """Average 5-hour usage per run for each owner, from the run log rows (agent-runs.csv)."""
    sums = {}
    for r in rows:
        name = (r.get("agent") or "").split(" (")[0]
        if name not in OWNERS:
            continue
        try:
            d = float(r["five_hour_after"]) - float(r["five_hour_before"])
        except (KeyError, TypeError, ValueError):
            continue
        if d >= 0:
            sums.setdefault(name, []).append(d)
    out = {n: sum(v) / len(v) for n, v in sums.items()}
    for n, agent in OWNERS.items():
        out.setdefault(n, float(budget_guard.COST.get(agent, budget_guard.UNKNOWN)) / 2)
    return out


def priority_score(goal, report, goals=None, costs=None):
    """(score, factors) for one goal. goals: all goals (for unblocks), report: gaps(), costs: owner_costs()."""
    goals, costs = goals or {}, costs or {}
    blocked = [d for d in goal["depends"] if report.get(d, {}).get("status") == "missing"]
    factors = {
        "unblocks": sum(1 for o in goals.values() if goal["id"] in o["depends"]
                        and report.get(o["id"], {}).get("status") != "done"),
        "value": goal["value"],
        "cost": round(sum(costs.get(o, 0) for o in goal["owners"]) / COST_UNIT, 2),
        "ready": 0 if blocked else 1,
    }
    raw = sum(WEIGHTS[k] * factors[k] for k in WEIGHTS)
    factors["blocked_by"] = blocked
    return round(factors["ready"] * raw, 2), factors


def order(spec, report, costs):
    """The buildable goals, best first, each with its score and factors; ambiguous goals are listed apart."""
    ranked, ambiguous = [], []
    for gid, goal in spec["goals"].items():
        r = report[gid]
        if r["status"] == "done" or r["waits_on_tests"]:
            continue
        if r["ambiguous"]:
            ambiguous.append(gid)
            continue
        score, f = priority_score(goal, report, spec["goals"], costs)
        ranked.append({"id": gid, "score": score, "factors": f})
    kind = {"handoff": 0, "change": 1, "test": 2}
    ranked.sort(key=lambda x: (-x["score"], kind[spec["goals"][x["id"]]["kind"]], x["id"]))
    return ranked, ambiguous


def why(spec, entry):
    f, goal = entry["factors"], spec["goals"][entry["id"]]
    if not f["ready"]:
        return "waits on " + ", ".join(f["blocked_by"])
    bits = []
    if f["unblocks"]:
        bits.append(f"{f['unblocks']} goal(s) wait on it")
    bits.append({3: "play-test fix", 2: "designer feature", 1: "housekeeping/handoff"}[goal["value"]])
    bits.append(f"cost {f['cost']} ({', '.join(goal['owners'])})")
    return "; ".join(bits)


# ---------------------------------------------------------------------------------------------- the blackboard
# The shared format of generate.py (_templates/blackboard.md). --plan and --dry-run never write it (board is None).
def say(board, text):
    if board is not None:
        g.append(board, text)


def gaps_table(spec, report, only=None):
    rows = ["| Goal | Kind | Owners | Status | Evidence |", "|---|---|---|---|---|"]
    for gid, goal in spec["goals"].items():
        if only is not None and gid not in only:
            continue
        r = report[gid]
        ev = ", ".join(f"{'✓' if e['ok'] else '✗'} {e['kind']} {e['name']}" + (f" ({e['result']})" if e.get("result")
                       and e["result"] != "PASS" else "") for e in r["evidence"]) or "none found"
        if len(ev) > 300:
            ok = sum(e["ok"] for e in r["evidence"])
            ev = f"{ok}/{len(r['evidence'])} present: " + ev[:240] + " ..."
        status = r["status"] + (" (built, waits on its tests)" if r["waits_on_tests"] else "") + \
            (" AMBIGUOUS" if r["ambiguous"] else "")
        rows.append(f"| {gid} {goal['title'][:60]} | {goal['kind']} | {', '.join(goal['owners']) or '-'} | {status} | {ev} |")
    return "\n".join(rows)


def scores_table(spec, ranked, only=None):
    rows = ["| Rank | Goal | Score | unblocks | value | cost | ready | Why |", "|---|---|---|---|---|---|---|---|"]
    for i, e in enumerate(ranked, 1):
        if only is not None and e["id"] not in only:
            continue
        f = e["factors"]
        rows.append(f"| {i} | {e['id']} {spec['goals'][e['id']]['title'][:50]} | {e['score']} | {f['unblocks']} | "
                    f"{f['value']} | {f['cost']} | {f['ready']} | {why(spec, e)} |")
    w = ", ".join(f"{k} {v:+}" for k, v in WEIGHTS.items())
    return "\n".join(rows) + f"\n\nWeights: {w}; score = ready × Σ weight × factor."


def now():
    return datetime.datetime.now().astimezone().isoformat(timespec="seconds")


def write_gaps(folder, spec, found, report, ranked, ambiguous):
    folder.mkdir(parents=True, exist_ok=True)
    data = {"spec": spec["file"], "version": spec["version"], "at": now(), "unit_log": found["unit_log"],
            "goals": {gid: {**{k: spec["goals"][gid][k] for k in ("kind", "title", "owners", "items", "depends")},
                            **report[gid]} for gid in spec["goals"]},
            "order": ranked, "ambiguous": ambiguous}
    (folder / "gaps.json").write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")


def board_start(board, spec, run, command):
    """Open the run's board on its first build (or --accept) invocation; True if it already existed."""
    if board.is_file():
        return True
    g.board_start(board, {"spec": spec["file"], "version": spec["version"], "run": run,
                          "started": datetime.date.today()}, f"Goal agent: {spec['file']} (run {run})",
                  f"Build what `game/specs/{spec['file']}` (version {spec['version']}) asks for that the game lacks. "
                  f"Agent: `_tools/goal_agent.py` (spec `game/specs/m3-goal-agent.md`).\n\nCommand: `{command}`")
    return False


def pass_state(report, ranked):
    """What a pass row shows, per goal: the diff-only passes compare this with the last pass on the board."""
    rows = {gid: {"gap": [r["status"], r["waits_on_tests"], r["ambiguous"],
                          [[e["kind"], e["name"], e["ok"], e.get("result")] for e in r["evidence"]]]}
            for gid, r in report.items()}
    for e in ranked:
        rows[e["id"]]["score"] = [e["score"], e["factors"]]
    return rows


def plan_pass(spec, game, folder, board, costs, n):
    """One scan-gaps-score pass: returns (report, ranked, ambiguous) and writes gaps.json. On a build run it also
    writes the pass to the blackboard: in full the first time, then only the rows that changed since the last pass
    on the board (kept in blackboard.pass.json, since --plan rewrites gaps.json without touching the board)."""
    found = scan(game)
    report = gaps(spec, found)
    ranked, ambiguous = order(spec, report, costs)
    write_gaps(folder, spec, found, report, ranked, ambiguous)
    if board is None:
        return report, ranked, ambiguous
    state, side = pass_state(report, ranked), board.with_name(f"{board.stem}.pass.json")
    last = json.loads(side.read_text(encoding="utf-8")) if side.is_file() else None
    side.write_text(json.dumps(state, ensure_ascii=False), encoding="utf-8")
    done = sum(r["status"] == "done" for r in report.values())
    head = f"\n## Pass {n}: scan ({now()})\n\nUnit results from `{found['unit_log']}`. {done} of {len(report)} goals done."
    if last is None:
        say(board, f"{head}\n\n### Gaps\n\n{gaps_table(spec, report)}\n\n"
                   f"### Order\n\n{scores_table(spec, ranked) if ranked else 'Nothing left to build.'}\n")
    else:
        gap = {gid for gid in state if state[gid]["gap"] != last.get(gid, {}).get("gap")}
        score = {gid for gid in state if state[gid].get("score") != last.get(gid, {}).get("score")}
        body = (f"\n\n### Gaps changed ({len(gap)} of {len(report)})\n\n{gaps_table(spec, report, gap)}" if gap
                else "\n\nNo gap changed.")
        body += (f"\n\n### Order: new or rescored ({len(score & {e['id'] for e in ranked})} of {len(ranked)})\n\n"
                 f"{scores_table(spec, ranked, score)}" if score & {e["id"] for e in ranked} else
                 "\n\nNo score changed." if ranked else "\n\nNothing left to build.")
        say(board, f"{head} Only what changed since the last pass is shown.{body}\n")
    if ambiguous:
        say(board, "\n### Ambiguous (not scored; built after the designer answers)\n\n" + "\n".join(
            f"- {a}: {spec['goals'][a]['title']}" + "".join(f"\n  - Question: {q}" for q in report[a]["questions"])
            for a in ambiguous) + "\n")
    return report, ranked, ambiguous


# ---------------------------------------------------------------------------------------------- the build step
def spec_slice(spec, goal):
    """The spec text an agent needs for one goal: the change(s) it touches and that owner's contract lines."""
    parts = []
    for n in goal["items"]:
        c = spec["goals"].get(f"C{n}")
        if c:
            parts.append(c["text"])
    if goal["kind"] == "change" and goal["id"] == "CFG":
        parts.append(goal["text"])
    return "\n\n".join(parts)


def briefs(spec, goal, batch, run, branch):
    """{agent: prompt} for the step that builds goal (and, for tests, the batch of sibling test goals)."""
    head = (f"Goal agent run `{run}`, spec `game/specs/{spec['file']}`, goal {', '.join(b['id'] for b in batch)}. "
            f"Work in the main folder on branch `{branch}`; do not commit, switch branch or edit outside your folder. "
            f"Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.\n\n")
    tail = "\n\nReply in at most 150 words: files changed, node names used, open questions."
    handoff = [h for h in scan_handoffs() if h.startswith(spec["version"])]
    hand_ref = f"Node handoff: `game/specs/{handoff[0]}` (read it first).\n" if handoff else ""
    out = {}
    if goal["kind"] == "handoff":
        bob_items = [g2 for g2 in spec["goals"].values() if g2["kind"] == "change" and "Bob" in g2["owners"]]
        text = "\n\n".join(f"Change {c['items'][0]}: {c['text']}\nBob's lines: " + " / ".join(c["lines"].get("Bob", []))
                           for c in bob_items)
        out[PROGRAMMER] = head + (
            f"Write the node handoff `game/specs/{spec['version']}-node-handoff.md` (Process 5; model it on "
            f"`game/specs/0.1.3c-node-handoff.md`): every node Bob must add, rename, move or remove for the changes "
            f"below, with exact names and parents in `scenes/main.tscn` or the prop scenes, and the nodes your scripts "
            f"will look up. Read the scenes and scripts you need; write no code yet.\n\n{text}") + tail
        return out
    if goal["kind"] == "test":
        lines = "\n".join(f"- {b['id']}: {b['text']}" for b in batch)
        items = sorted({n for b in batch for n in b["items"]})
        label = f"{spec['version']} item{'s' if len(items) > 1 else ''} {', '.join(map(str, items))}"
        out[QA] = head + (
            f"Write the tests for these contract lines, from the spec, not the code (Process 2): every expected "
            f"number read from the config. Register them in `tests/run_tests.gd` under one group comment that starts "
            f"`# {label} (written from game/specs/{spec['file']} before the code)` (the goal agent finds them by it). "
            f"Add a mutation per new test to `tests/mutations.json`. Run only your tests: "
            f"`CB_ONLY=<names> CB_TIME_SCALE=6 python -I _tools/godot_run.py unit`. A failing test is a finding: report "
            f"it, never bend the test to the code.\n\nContract lines:\n{lines}\n\nSpec text:\n{spec_slice(spec, goal)}\n"
            f"{hand_ref}") + tail
        return out
    for owner in goal["owners"]:
        agent = OWNERS[owner]
        if agent == QA:
            continue
        lines = "\n".join(f"- {l}" for l in goal["lines"].get(owner, []))
        keys = (f"\nConfig keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, "
                f"marked PLACEHOLDER, live in the Dev panel): {', '.join(goal['keys'])}." if goal["keys"] and
                agent == PROGRAMMER else "")
        other = "Bob works on the scenes in parallel" if agent == PROGRAMMER else "Patricia works on the scripts in parallel"
        out[agent] = head + (
            f"Build your part ({FOLDERS[agent]}) of this change. {other}; the handoff is your contract. Run "
            f"`python -I _tools/contract_check.py` before you finish.{keys}\n{hand_ref}\nYour contract lines:\n{lines}\n\n"
            f"Spec text:\n{spec_slice(spec, goal)}") + tail
    return out


def scan_handoffs(game=None):
    return sorted(p.name for p in ((game or ROOT / "game") / "specs").glob("*handoff*.md"))


def run_agent(agent, prompt, max_turns=None):
    """One fresh headless agent (generate.run_agent with file and shell tools; Vera reads only). Replaced by a fake in the tests."""
    return g.run_agent(agent, prompt, tools="Read,Grep,Glob" if agent == CRITIC else TOOLS, max_turns=max_turns)


def run_cmd(cmd, env=None, timeout=3600):
    """(exit code, output) of one check command, run from the repo root. Replaced by a fake in the tests."""
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           env={**os.environ, **(env or {})}, timeout=timeout)
        return p.returncode, (p.stdout + p.stderr)
    except subprocess.TimeoutExpired:
        return 124, f"timed out after {timeout} s"


def budget_ok(agent):
    """budget_guard.decide for a headless call (the PreToolUse hook only sees the Agent tool)."""
    if budget_guard.overridden():
        return True, "override"
    reading = budget_guard.latest()
    verdict, msg = budget_guard.decide(reading, agent)
    age = ""
    if reading:
        age = f" (reading {int((budget_guard.now() - budget_guard.parse_ts(reading['ts'])).total_seconds() // 60)} min old)"
    return verdict != "deny", (msg or f"allow{age}")


def checks(spec, goal, base, version):
    """The check commands for a step, in order: [(label, cmd, env)]."""
    py = [sys.executable, "-I"]
    out = [("contract", py + ["_tools/contract_check.py"], None),
           ("tests", py + ["_tools/godot_run.py", "unit", "start"], ENV)]
    if goal["kind"] == "change" and "Bob" in goal["owners"]:
        out.append(("ui shots", py + ["_tools/ui_shots.py", f"{version}={ROOT}"], None))
        # one style-loop round (render, style_check, Vera; no Bob): a FAIL goes to Bob in the fix round. {round} is
        # filled per round, since a style board can't be reused.
        slug = f"goal-{version}-{goal['id']}-r{{round}}".lower().replace(".", "-")
        out.append(("style", py + ["_tools/style_loop.py", slug, "--max-rounds", "1", "--request",
                                   f"goal_agent {version} {goal['id']}: check Bob's change against STYLE_GUIDE.md"], None))
    if goal["kind"] == "test":
        out.append(("mutations", py + ["_tools/mutate.py", "--since", base], None))
    return out


def summary_of(output, n=12):
    keep = [l for l in output.splitlines() if re.match(r"^(FAIL|RESULT|----|ERROR|SCRIPT ERROR|MISSING|NOT CAUGHT|"
                                                        r"\S+\.gd:\d+|ui_shots|mutate)", l.strip())]
    return "\n".join((keep or output.splitlines())[-n:])


def git(*args):
    return run_cmd(["git", *args])


BUILD_PATHS = ["game/scripts", "game/scenes", "game/materials", "game/tests", "game/specs"]


def tree_state():
    """The build folders' uncommitted state; the same before and after a step means the agents changed nothing."""
    return git("status", "--porcelain", "--", *BUILD_PATHS)[1] + git("diff", "HEAD", "--", *BUILD_PATHS)[1]


def text_hash(goal):
    return hashlib.sha1(goal["text"].encode("utf-8")).hexdigest()[:12]


def hold(spec, goal, run, ledger_path, question):
    """Record a goal the agents left unchanged as held, not built (0.1.4 C7 was committed green with no change).
    The hold lifts when the goal's spec text changes (the designer's answer) or with --accept."""
    ledger = json.loads(ledger_path.read_text(encoding="utf-8")) if ledger_path.is_file() else {}
    ledger.setdefault(spec["file"], {})[goal["id"]] = {"run": run, "at": now(), "held": question,
                                                         "text": text_hash(goal)}
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    ledger_path.write_text(json.dumps(ledger, indent=1), encoding="utf-8")


def checkpoint(spec, batch, run, folder, ledger_path):
    """Record the goals in the ledger and make a checkpoint commit of the game folders (never main, never a push)."""
    code, branch = git("rev-parse", "--abbrev-ref", "HEAD")
    branch = branch.strip()
    if code or branch in ("main", "master"):
        return f"no commit: on `{branch}`"
    ledger = json.loads(ledger_path.read_text(encoding="utf-8")) if ledger_path.is_file() else {}
    for b in batch:
        ledger.setdefault(spec["file"], {})[b["id"]] = {"run": run, "at": now()}
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    ledger_path.write_text(json.dumps(ledger, indent=1), encoding="utf-8")
    paths = BUILD_PATHS + [ledger_path.relative_to(ROOT).as_posix(), folder.relative_to(ROOT).as_posix()]
    git("add", "--", *paths)
    ids = ", ".join(b["id"] for b in batch)
    msg = (f"{spec['version']} goal {ids}: {batch[0]['title'][:60]} (goal_agent run {run})\n\n"
           f"Built by _tools/goal_agent.py; blackboard {folder.relative_to(ROOT).as_posix()}/blackboard.md\n\n"
           f"Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>")
    code, out = git("commit", "-m", msg)
    if code:
        return "commit failed: " + summary_of(out, 6)
    _, sha = git("rev-parse", "--short", "HEAD")
    for b in batch:
        ledger[spec["file"]][b["id"]]["commit"] = sha.strip()
    ledger_path.write_text(json.dumps(ledger, indent=1), encoding="utf-8")
    return f"checkpoint `{sha.strip()}` on `{branch}`"


def ensure_branch(version):
    branch = f"milestone/{version}"
    _, cur = git("rev-parse", "--abbrev-ref", "HEAD")
    if cur.strip() == branch:
        return branch, "already on it"
    exists = git("rev-parse", "--verify", "--quiet", branch)[0] == 0
    code, out = git("checkout", branch) if exists else git("checkout", "-b", branch)
    if code:
        raise SystemExit(f"goal_agent: cannot check out {branch}: {out.strip()}")
    return branch, f"checked out from `{cur.strip()}`" + ("" if exists else " (new)")


def step(spec, goal, batch, run, folder, board, branch, usage, dry=False):
    """Build one goal (and its test batch) to green: agents, checks, fix rounds, checkpoint. Returns a result word."""
    ids = ", ".join(b["id"] for b in batch)
    plan = briefs(spec, goal, batch, run, branch)
    _, base = git("rev-parse", "--short", "HEAD")
    base = base.strip()
    cmds = checks(spec, goal, base, spec["version"]) if goal["kind"] != "handoff" else []
    if dry:   # the console only: no brief files, no board
        print(f"\nStep {ids}: {len(plan)} agent(s) in parallel: {', '.join(g.NAMES[a] for a in plan)}")
        for agent, prompt in plan.items():
            print(f"\n----- brief for {g.NAMES[agent]} ({agent}) -----\n{prompt}")
        print("\n----- checks -----\n" + "\n".join(" ".join(c[1]) + (f"   env {c[2]}" if c[2] else "") for c in cmds))
        return "dry-run"
    say(board, f"\n### Step: {ids} ({now()})\n\n")
    keep_briefs(folder, board, plan, goal["id"])
    before = tree_state()
    if not call_agents(plan, board, usage, run, ids):
        return "paused"
    for rnd in range(MAX_FIX_ROUNDS + 1):
        failed = []
        for label, cmd, env in cmds:
            code, out = run_cmd([c.replace("{round}", str(rnd)) for c in cmd], env=env)
            say(board, f"- Check `{label}`: {'PASS' if code == 0 else f'FAIL (exit {code})'}\n")
            if code:
                text = style_report(out) if label == "style" else summary_of(out)
                failed.append((label, text))
                say(board, "\n```\n" + text + "\n```\n")
                if label in ("contract", "tests"):
                    break
        if not any(l in ("contract", "tests") for l, _ in failed):
            for live, pick in goal.get("picks", []):   # look before done: the live prop beside the designer's pick
                rows = match_pick(spec, goal, live, pick, folder, rnd, board, usage, run, ids)
                if rows is None:
                    return "paused"
                if rows:
                    failed.append(("pick match", rows))
        if not failed:
            break
        if rnd == MAX_FIX_ROUNDS:
            g.waiting(board, f"{MAX_FIX_ROUNDS} fix rounds failed on {ids}: " + ", ".join(f"`{l}`" for l, _ in failed)
                      + " still fail (output above). The designer decides: change the spec or the test, or fix it "
                      f"by hand and record it with `goal_agent.py {spec['file']} --accept {goal['id']} --note "
                      f"\"<the change>\"`. Then rerun the same command to go on.")
            return "waiting-designer"
        fix = fix_briefs(spec, goal, batch, failed, run, branch, rnd + 1)
        say(board, f"\n#### Fix round {rnd + 1}: to {', '.join(g.NAMES[a] for a in fix)}\n\n")
        keep_briefs(folder, board, fix, f"{goal['id']}-fix{rnd + 1}")
        if not call_agents(fix, board, usage, run, f"{ids} fix {rnd + 1}", max_turns=FIX_MAX_TURNS):
            return "paused"
    if goal["kind"] == "handoff" and not [h for h in scan_handoffs() if h.startswith(spec["version"])]:
        say(board, "\n**Stop:** Patricia's reply came back without the handoff file.\n")
        return "failed"
    if goal["kind"] != "handoff" and tree_state() == before:   # green only because nothing moved: not built
        question = (f"The agents changed no file for {ids} and the checks were already green, so it is not built. "
                    f"Their replies on the board (step {ids}, {now()}) say why; answer by editing the spec item.")
        hold(spec, goal, run, folder.parent / "ledger.json", question)
        say(board, f"- **Held:** no file changed in {', '.join(BUILD_PATHS)}; not committed. {question}\n")
        return "held"
    msg = checkpoint(spec, batch, run, folder, folder.parent / "ledger.json")
    say(board, f"- Green: {msg}\n")
    return "green"


def style_report(out):
    """The Result of the style board a failed `style` check names (its open rows), else the output's tail."""
    m = re.search(r"game/reports/style/[\w-]+/blackboard\.md", out)
    board = ROOT / m.group(0) if m else None
    if board and board.is_file():
        result = board.read_text(encoding="utf-8").split("\n## Result", 1)
        if len(result) == 2:
            return f"Style board `{m.group(0)}`, Result:{result[1].rstrip()}"
    return summary_of(out)


def match_pick(spec, goal, live, pick, folder, rnd, board, usage, run, ids):
    """Render the live prop beside the pick and ask Vera whether they match. "" on PASS, the rows on FAIL,
    None when the budget guard pauses the run."""
    out = folder / "pick" / f"{goal['id']}-r{rnd}"
    code, text = run_cmd(pick_match.render_cmd(live, pick, out))
    say(board, f"- Check `pick match` render ({live} beside {pick}): {'done' if code == 0 else f'FAIL (exit {code})'}\n")
    if code:
        return "The pick-match render failed:\n" + summary_of(text)
    ok, msg = budget_ok(CRITIC)
    if not ok:
        say(board, f"\n**Paused:** {msg}\nRun the same command again to resume.\n")
        return None
    g.set_live_tag(f"goal {run} · {ids} pick match")
    prompt = pick_match.prompt(live, pick, out, spec_slice(spec, goal))
    verdict, rows = None, []
    for attempt in range(2):
        reply, u = run_agent(CRITIC, prompt if not attempt else prompt + " Your last reply had no such block with a VERDICT line.")
        usage.append((CRITIC, f"{ids} pick match", u))
        say(board, f"\n**Vera, pick match** ({u['tokens']:,} tokens):\n\n{reply.strip()}\n\n")
        verdict, rows = pick_match.judge(reply)
        if verdict:
            break
    if verdict is None:
        raise g.AgentError("Vera returned no pick-match verdict")
    say(board, f"- Check `pick match`: {verdict}\n")
    shots = ", ".join(f"`{s.relative_to(ROOT).as_posix()}`" for s in pick_match.shots(live, pick, out))
    return "" if verdict == "PASS" else f"Shots (live, pick): {shots}\n" + "\n".join(rows)


def keep_briefs(folder, board, plan, name):
    """Save each brief beside the board and link it (inputs go by reference)."""
    bdir = folder / "briefs"
    bdir.mkdir(parents=True, exist_ok=True)
    for agent, prompt in plan.items():
        f = bdir / f"{name}-{g.NAMES[agent].lower()}.md"
        f.write_text(prompt, encoding="utf-8")
        say(board, f"- Brief for {g.NAMES[agent]}: `{f.relative_to(ROOT).as_posix()}` ({len(prompt)} chars)\n")


def fix_briefs(spec, goal, batch, failed, run, branch, rnd):
    """Failures go to the owners of the folders involved (Process 9): code owners for test failures."""
    report = "\n\n".join(f"{label}:\n{text}" for label, text in failed)
    owners = [OWNERS[o] for o in goal["owners"]] if goal["kind"] != "test" else \
        sorted({OWNERS[o] for n in goal["items"] for o in spec["goals"].get(f"C{n}", {}).get("owners", [])}
               - {QA}) or [PROGRAMMER]
    if any(l == "contract" for l, _ in failed) and BUILDER not in owners and goal["kind"] == "change":
        owners.append(BUILDER)
    if [l for l, _ in failed] == ["mutations"]:   # a missed mutation means a test proves too little: Quinn's folder
        owners = [QA]
    if failed and all(l in LOOKS for l, _ in failed):   # how the scene looks: Bob's folder
        owners = [BUILDER]
    head = (f"Goal agent run `{run}`, fix round {rnd} for goal {', '.join(b['id'] for b in batch)} of "
            f"`game/specs/{spec['file']}`, branch `{branch}`. These checks failed after the last step. Fix what is in "
            f"your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. "
            f"Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have "
            f"{FIX_MAX_TURNS} turns.\n\n")
    looks = ("A `pick match` row means the live prop must match the designer's picked variant: open both shots and "
             "the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: "
             "leave it and list it in your reply.\n\n") if any(l in LOOKS for l, _ in failed) else ""
    out = {a: head + f"Your folder: {FOLDERS[a]}\n\n{looks if a == BUILDER else ''}{report}\n\nSpec text:\n"
                     f"{spec_slice(spec, goal)}\n\nReply in at most 150 words." for a in owners}
    if goal["kind"] == "change" and any(l == "tests" for l, _ in failed):
        # an older test may pin what this change was asked to change (e.g. the removed Hive bar): Quinn's folder
        out[QA] = head + (f"Your folder: {FOLDERS[QA]}. Update only a test whose expectation this change of the "
                          f"spec replaces, and quote the spec line in a comment beside it. Any other failure is a "
                          f"finding against the code: leave the test and say which. Rerun only the tests you touch "
                          f"(CB_ONLY).\n\n{report}\n\nSpec text:\n{spec_slice(spec, goal)}\n\nReply in at most 150 words.")
    return out


def transcripts(run):
    """Where this run's agent transcripts are kept today (gitignored)."""
    return ROOT / g.RUNS / f"{datetime.date.today().isoformat()}-goal-{run}"


def call_agents(plan, board, usage, run, label, max_turns=None):
    """Run the briefs in parallel after the budget check; False when the budget guard pauses the run."""
    for agent in plan:
        ok, msg = budget_ok(agent)
        if not ok:
            say(board, f"\n**Paused:** {msg}\nRun the same command again to resume.\n")
            return False
        say(board, f"- Budget guard for {g.NAMES[agent]}: {msg}\n")
    rundir = transcripts(run)
    g.set_live_tag(f"goal {run} · {label}")
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(plan)) as pool:
        cap = {"max_turns": max_turns} if max_turns else {}
        futures = {pool.submit(run_agent, a, p, **cap): a for a, p in plan.items()}
        for fut in concurrent.futures.as_completed(futures):
            agent = futures[fut]
            try:
                reply, u = fut.result()
            except g.AgentError as e:
                say(board, f"\n**{g.NAMES[agent]} failed:** {e}\n")
                raise
            try:
                g.keep_transcript(u, rundir, f"{label.replace(' ', '-').replace(',', '')}-{g.NAMES[agent].lower()}")
            except Exception:
                pass
            usage.append((agent, label, u))
            say(board, f"\n**{g.NAMES[agent]}** ({u['tokens']:,} tokens, {u['turns']} turns, {u['seconds']} s):\n\n"
                            f"{reply.strip()}\n\n")
    return True


def log_usage(usage, run):
    for agent, label, u in usage:
        start, end = runlog.parse_ts(u.get("start")), runlog.parse_ts(u.get("end"))
        f0, w0 = runlog.usage_at(start, ROOT)
        f1, w1 = runlog.usage_at(end, ROOT, after=True)
        runlog.upsert({"start": u.get("start"), "end": u.get("end"), "table": LOG_TABLE,
                       "run": f"goal {run}, {label}", "agent": f"{g.NAMES[agent]} ({agent})", "phase": "post-ICM",
                       "model": u.get("model") or g.model_of(agent), "final_context": u.get("final"),
                       "total_processed": u["tokens"], "turns": u["turns"], "duration_s": u["seconds"],
                       "five_hour_before": f0, "five_hour_after": f1, "seven_day_before": w0,
                       "seven_day_after": w1}, ROOT)


# ---------------------------------------------------------------------------------------------- the loop
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("spec", help="a file in game/specs/, e.g. 0.1.4-ui-placement.md")
    ap.add_argument("--plan", action="store_true", help="scan, gaps and scores only")
    ap.add_argument("--dry-run", action="store_true", help="the plan, then the next step's briefs and commands")
    ap.add_argument("--max-goals", type=int, default=0, help="stop after this many green steps (0 = no limit)")
    ap.add_argument("--goal", help="build this goal next instead of the top score (it must be ready)")
    ap.add_argument("--run", help="run folder name under game/reports/goal/ (default: the spec's version)")
    ap.add_argument("--accept", metavar="GOAL", help="after a stop: record GOAL as green with a manual fix (Process 9), "
                    "checkpoint it, and exit; run the checks first")
    ap.add_argument("--note", default="", help="with --accept: the manual change, for the blackboard and GOAL_AGENT.md; "
                    "otherwise: the designer's answer the run resumes on (written under Resumed)")
    a = ap.parse_args(argv)
    path = Path(a.spec)
    if not path.is_file():
        path = ROOT / "game" / "specs" / a.spec
    spec = parse_spec(path)
    if spec["status"] != "approved":
        print(f"goal_agent: {spec['file']} is `{spec['status'] or 'no status'}`, not approved; nothing is built.")
        return 2
    import spec_lint   # the spec-consistency rule: a FAIL stops a build run; --plan/--dry-run only print it
    if spec_lint.lint(path, out=lambda line: print("goal_agent: " + line)) and not (a.plan or a.dry_run):
        print("goal_agent: fix the FAIL lines in the spec first (python -I _tools/spec_lint.py SPEC)")
        return 2
    run = a.run or spec["version"]
    folder = ROOT / "game" / "reports" / "goal" / run
    board = folder / "blackboard.md"
    costs = owner_costs(runlog.read(ROOT))
    command = f"goal_agent.py {' '.join(argv or sys.argv[1:])}"
    if a.accept and (a.accept not in spec["goals"] or not a.note):
        print("goal_agent: --accept needs a goal of this spec and a --note naming the manual change")
        return 2
    if board.is_file() and not board.read_text(encoding="utf-8").startswith("---"):
        print(f"goal_agent: {board.relative_to(ROOT).as_posix()} is in the old format (no front matter); convert it "
              f"to _templates/blackboard.md first, or pass a new --run")
        return 2
    if a.plan or a.dry_run:   # the console only: the board records what was built, not what was looked at
        shown, board = board, None
        n = 1
    else:
        if board_start(board, spec, run, command):
            before = g.get_front(board, "result") or "unknown"
            g.resumed(board, f"Command: `{command}` (the run had stopped: `{before}`)."
                      + (f"\n\nDesigner's answer: {a.note}" if a.note and not a.accept else ""))
        n = len(re.findall(r"^## Pass \d+", board.read_text(encoding="utf-8"), re.M)) + 1
    if a.accept:
        goal = spec["goals"][a.accept]
        say(board, f"\n### Manual fix: {goal['id']} ({now()})\n\n- Change (orchestrator, Process 9): {a.note}\n")
        msg = checkpoint(spec, [goal], run, folder, folder.parent / "ledger.json")
        say(board, f"- Accepted: {msg}\n")
        g.finish_board(board, [], "stopped", f"{goal['id']} accepted with a manual fix ({msg}). Rerun "
                       f"`goal_agent.py {spec['file']}` to build the rest.", transcripts(run))
        print(f"goal_agent: {goal['id']} accepted: {msg}")
        return 0
    usage, built, result = [], 0, "done"
    branch = f"milestone/{spec['version']}"
    if not (a.plan or a.dry_run):
        branch, note = ensure_branch(spec["version"])
        say(board, f"Branch `{branch}`: {note}.\n")
    try:
        while True:
            report, ranked, ambiguous = plan_pass(spec, ROOT / "game", folder, board, costs, n)
            n += 1
            print_plan(spec, report, ranked, ambiguous, folder)
            if a.plan:
                return 0
            ready = [e for e in ranked if e["factors"]["ready"]]
            if ambiguous and not ready:   # the other goals were built first; now only the designer can unblock the rest
                result = "waiting-designer"
                if board is not None:
                    g.waiting(board, "Every goal left waits on an open question (Process 1):\n\n" + "\n".join(
                        f"- {x}: {spec['goals'][x]['title']}" + "".join(f"\n  - {q}" for q in report[x]["questions"])
                        for x in ambiguous) + "\n\nAnswer each in the spec, or mark it \"(answered: ...)\" in the "
                        f"handoff, then rerun `goal_agent.py {spec['file']} --note \"<the answer>\"`.")
                break
            if a.goal and built == 0:
                ready = [e for e in ranked if e["id"] == a.goal and e["factors"]["ready"]] or []
                if not ready:
                    print(f"goal_agent: {a.goal} is not a ready, unbuilt goal")
                    result = "stopped (--goal was not a ready, unbuilt goal)"
                    return 2
            if not ready:
                left = [gid for gid, r in report.items() if r["status"] != "done"]
                result = "done" if not left else "waiting-tests" if all(report[x]["waits_on_tests"] for x in left) \
                    else "blocked"
                say(board, f"\n**Stop:** nothing ready to build ({result}); not done: {', '.join(left) or 'none'}.\n")
                break
            top = spec["goals"][ready[0]["id"]]
            batch = [top]
            if top["kind"] == "test":   # one Quinn call per item: its other ready test goals ride along
                batch += [spec["goals"][e["id"]] for e in ready[1:] if spec["goals"][e["id"]]["kind"] == "test"
                          and set(spec["goals"][e["id"]]["items"]) & set(top["items"])]
            say(board, f"\nNext: **{top['id']}** (score {ready[0]['score']}: {why(spec, ready[0])})" +
                     (f", with {', '.join(b['id'] for b in batch[1:])}" if batch[1:] else "") + ".\n")
            outcome = step(spec, top, batch, run, folder, board, branch, usage, dry=a.dry_run)
            if outcome == "held":   # like an open question: the rest is built, then the run waits on the designer
                continue
            if outcome != "green":
                result = outcome
                break
            built += 1
            if a.max_goals and built >= a.max_goals:
                result = f"stopped after {built} goal(s) (--max-goals)"
                say(board, f"\n**Stop:** {result}.\n")
                plan_pass(spec, ROOT / "game", folder, board, costs, n)   # the re-scan after the last write
                break
    except Exception as e:   # an agent or check crashed: never record it as done (generate.py marks `result: failed`)
        result = f"failed ({type(e).__name__}: {e})"
        say(board, f"\n**Stop:** the run crashed: {result}. A rerun re-scans and continues from the ledger.\n")
        raise
    finally:
        if board is not None:   # one Result, rewritten in place, with every call of the run so far
            word = result.split(" ")[0] if not result.startswith("stopped after") else "stopped"
            g.finish_board(board, [(f"{g.NAMES[agent]}, {label}", u) for agent, label, u in usage], word,
                           f"Last invocation ({now()}): {result}.", transcripts(run))
        if usage:
            log_usage(usage, run)
    print(f"goal_agent: {result}. Blackboard: {(board or shown).relative_to(ROOT).as_posix()}"
          + (" (not written: --plan/--dry-run)" if board is None else ""))
    return 0 if result in ("done", "dry-run") or result.startswith("stopped after") else 1


def print_plan(spec, report, ranked, ambiguous, folder):
    done = [gid for gid, r in report.items() if r["status"] == "done"]
    print(f"{spec['file']}: {len(done)}/{len(report)} goals done" + (f" ({', '.join(done)})" if done else ""))
    for gid, r in report.items():
        if r["status"] != "done":
            extra = " (built, waits on tests)" if r["waits_on_tests"] else ""
            print(f"  {gid:6} {r['status']:8}{extra} {spec['goals'][gid]['title'][:60]}")
    if ranked:
        print("Order:")
        for i, e in enumerate(ranked, 1):
            print(f"  {i:2}. {e['id']:6} {e['score']:6}  {why(spec, e)}")
    if ambiguous:
        print("Ambiguous: " + ", ".join(ambiguous))
    print(f"gaps.json: {(folder / 'gaps.json').relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    sys.exit(main())
