#!/usr/bin/env python3
"""The goal-oriented coding agent (M3, Assignment 5): find what a spec asks for that the game lacks, order it, build it.

    python -I _tools/goal_agent.py SPEC --plan                 # scan, gaps, scores: no agents, no game changes
    python -I _tools/goal_agent.py SPEC --dry-run              # the plan, then the next step's briefs and commands
    python -I _tools/goal_agent.py SPEC [--max-goals N] [--goal ID[,ID...]] [--run NAME]   # the loop

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
its spec slice (generate.run_agent). A Change also gets Quinn, when existing tests read the names it touches
(test_impact(): its nodes, keys and backticked names, and two-word phrases of its text such as second_stop): he
updates the tests the spec makes stale beside the build (L39; `--impact GOAL` prints the list). Then
contract_check.py, godot_run.py (unit + start, plus the windowed suites the impact list reaches), ui_shots.py after
scene work, mutate.py --since after new tests. A round's unit run is `--only` the goal's own tests, the tests that read
what the step's changed files define (change_impact(), cached test index; core files count only their changed names),
and the last check's failures; the board says which ran and why. There is no full unit run per step (L42): the run's
end runs every suite once. A failing test that is not the goal's own is rerun alone once first: passing, it is
logged flaky and gets no fix round. Failures go to the folder's owners (to Quinn alone when the failing test is one the
step wrote, or a code owner's reply puts the fault in tests/), at most MAX_FIX_ROUNDS
rounds, then the run stops for the designer. A fix round that changes a visual number (size, scale, offset, font,
margin) the spec does not name, or replies with a `(designer)` row naming one, stops for a Design Votes question; any
other `(designer)` row stops as a plain designer question. An agent call
that fails on a network or API error is retried once, then the run pauses (resumable). A green step gets a ledger line and a checkpoint commit on the
current branch, `main` since 2026-11-21 (never a push, never a detached HEAD); a step green only because no file changed is held for the
designer instead, like an open question, until its spec text changes or --accept. When nothing is left (or a --goal
list or --max-goals stop built something) it runs every suite (`all --time-scale 6 --skip-x1`), or reuses a green one
newer than every build change: red gets one Quinn round for stale tests, then waits for the designer.
It stops when nothing is left, when budget_guard denies an agent
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
BUILD_MAX_TURNS = 30   # designer, 2026-11-09: Bob's 0.2 C3 build call ran 47 turns, 1.09M tokens with no cap
# a Quinn line saying its test is "shown failing on the current build" reports a bug the designer saw: its tests must
# fail before any fix counts, and only a script or scene change can fix it (0.1.4 T14.3: the lid test passed on a
# clipping lid, and the step was committed green with no lid change; approved 2026-11-08, A and B)
FAIL_FIRST = re.compile(r"shown failing", re.I)
# Quinn's interaction checklist (designer, 2026-11-08: the crank kept counting after Back because item 12's test only
# started a crank; spec 0.1.4 item 15). Draft and choices: _meta/drafts/0.1.4/quinn-interaction-checklist.md
INTERACTION_CHECKLIST = (
    " Interaction checklist: for a line about something the player starts that keeps running or holds state (crank, "
    "scrape, lid, pour, zoom, a hold), write one sequence test through real input, each assert naming its step: (1) "
    "start it from every place the spec allows, and not from places it rules out; (2) leave mid-way by every exit "
    "(Back, zoom out, another panel, app pause via NOTIFICATION_APPLICATION_PAUSED): the player's input no longer "
    "counts and nothing the player was driving keeps moving, progress kept or reset as the spec says, but anything "
    "that runs on its own keeps running and finishes as the spec says: automatic loads and pours (the jar pour, the "
    "pile loading into the centrifuge: 0.1.4 item 7, every view) and anything an owned automation upgrade does (the "
    "motor spinning the centrifuge: item 12), so wait for it and assert it finished, never that it stopped; (3) come "
    "back the way the spec names: it "
    "resumes or restarts as the spec says, nothing runs twice; (4) do it start to finish twice: the second run matches "
    "the first. A one-tap action gets only (4). Add two mutations per sequence test: one breaking (2), one breaking "
    "(4). Where the spec does not say what leaving or coming back does, or whether a step goes on by itself, do not guess: write no test for it and list "
    "it under open questions (\"Item N: what happens to <x> on <exit> mid-way?\").")
CODE_PATHS = ["game/scripts", "game/scenes", "game/materials"]
LOCK = "_meta/usage/goal-run.lock"   # exists while a build run is live; guard_shell reads it (rule C)
REMOVED = re.compile(r"\b(removed?|retired?|goes away|deleted?)\b", re.I)   # a node in such a sentence must be absent
REPLACES = re.compile(r"\b(replaces?|supersedes?)\b", re.I)   # a node after it is the old one, which must be absent
AMBIGUOUS = re.compile(r"\bTBD\b|\bto be decided\b|\bopen question", re.I)
ENV = {"CB_TIME_SCALE": "6", "CB_SKIP_X1": "1"}   # routine runs: x6, the real-time tests are the designer's (D102)
# L39: tests that copied a flow inline went stale on every feature change, and the windowed suites drifted unseen for two
# versions because each step ran `unit` only. The test files that are their own godot_run.py suite (the rest are `unit`):
SUITE_FILES = {"play_loop.gd": "play", "r4_measure.gd": "measure", "snapshot_pop.gd": "snapshot",
               "ui_bounds_pixels.gd": "ui", "touch_windowed.gd": "touch"}
UNIT_FILES = re.compile(r"^(test_\w+|farm_input)\.gd$")   # the unit chain (run_tests.gd only lists names); shot scripts are not checks
FULL_SUITE = ["all", "--time-scale", "6", "--skip-x1"]   # the end-of-run check: every suite, as at a checkpoint
# L40 (obstacles item 18): each round reran all ~200 unit tests (~12.5 min; T12.1 ran three for 2 min of agents), since
# L39 only added suites. A round now runs the goal's own tests plus last round's failures (`--only`); L42 added the
# tests the step's changes impact and dropped the step's full unit gate (the run's end runs every suite: final_suite()).
ONLY_FLAGS = ["--time-scale", "6", "--skip-x1"]
TRANSIENT = re.compile(r"ENOTFOUND|ECONNRESET|ECONNREFUSED|ETIMEDOUT|EAI_AGAIN|socket hang up|can't reach the API|"
                       r"API Error: (?:5\d\d|Connection error|Request timed out)|overloaded_error|network error", re.I)
# item 12: a fix round shrank the shop rows 120 -> 64 px and the fonts 28 -> 24 to pass a test, with no vote. A changed
# line setting one of these (scenes, materials, config, scripts) stops the step for the Design Votes page.
VISUAL = re.compile(r"^\s*(?:@export\S*\s+)?(?:(?:var|const)\s+)?[\w/.]*(?:size|scale|offset|font|margin|separation|"
                    r"height|width)[\w/]*\s*(?::\s*\w+\s*)?:?=\s*(?:Vector[23]i?\()?\s*-?\d|"
                    r"add_theme_(?:font_size|constant)_override\(.*\d", re.I)
VISUAL_RULE = ("Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those "
               "are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, "
               "change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. ")
# designer, 2026-11-22: a spec with `visuals: placeholder` in its front matter keeps the visual numbers a fix round sets
# and lists them for the play-test (placeholders.md) instead of stopping for a Design Votes row (0.3: 6 of 17 stops).
PLACEHOLDER_RULE = ("This spec's visuals are placeholders (front matter `visuals: placeholder`): you may set a size, "
                    "offset, font size or margin when a failing row needs it. Keep it close to the canvas board, change "
                    "only the numbers the row needs, and list each as `placeholder: <file>: <old> -> <new>`; the designer "
                    "confirms them at play-test. ")
# 0.3 C3 and C6 stopped twice on the same V11/V12 question: the style guide's minimums are approved values, not votes.
STYLE_MINIMUMS = ("STYLE_GUIDE minimums are approved values, not votes: raise a touch target below 120 px to 120 and a "
                  "font below 28 px to 28 without asking, and say so in your reply. ")
MINIMUM_VALUES = {28.0, 120.0}   # a changed line whose new numbers are only these is a minimum, not a vote
# designer, 2026-11-22: 0.3 T4.1 stopped on the shop layout, already drawn in the Claude Design canvas.
LAYOUT_RULE = ("Where a panel sits, how it opens and what fits on screen come from the designer's Claude Design canvas: "
               "read `UI_DESIGN.md` and the matching board in `proposals/design/ui-screens-mockup/project/` for the look "
               "and placement of what the spec item asks for. Build only what the spec asks (a board part it does not "
               "name, like tabs, waits for a later revision); where the spec text differs, the spec wins. "
               # designer, 2026-11-22: "I shouldn't have to specify something that is already built and on the todo
               # or tbd list". A question the workspace already answers is not a (designer) row.
               "Before writing any `(designer)` row, look for the answer in `UI_DESIGN.md`, the canvas boards, "
               "`README.md` (Outstanding TBDs), `proposals/design/ui-screens.md` and `_meta/sessions/*/decisions.md`: "
               "if one answers it, apply that answer and cite the file. If the topic is already a listed TBD, build "
               "the placeholder, name the TBD and go on; it is not a question. Ask only when none of them covers it. ")
QUESTION = re.compile(r"\?|\bA:")   # a `(designer)` row with no question and no options asks nothing (0.3 T1.1)
STALE_FIND = re.compile(r"^BROKEN\s.*`find` occurs 0 times", re.M)   # the code moved since the mutation was written


def mutated_tests(root=None):
    """Every test named in an `expect` list of game/tests/mutations.json (L50)."""
    path = (root or ROOT) / "game" / "tests" / "mutations.json"
    try:
        return {t for m in json.loads(path.read_text(encoding="utf-8")) for t in m.get("expect", [])}
    except (OSError, ValueError):
        return set()
# L42: T9.1's fix round 2 stopped for a Design Votes row on "A: keep the paused crank; B: reset the crank", no visual
# value in it. A `(designer)` row is a vote only when it names one of these; any other is a plain designer question.
# L49: Quinn's "nothing is marked `(designer)`" stopped the 0.3 run as a question; a tag quoted in backticks is a
# mention, not a row.
DESIGNER_ROW = re.compile(r"(?<!`)\(designer\)(?!`)")
VISUAL_ROW = re.compile(r"\b(?:sizes?|scales?|offsets?|positions?|fonts?|margins?|colou?rs?|px|pixels?|width|height|"
                        r"separation|spacing)\b", re.I)
# L42: T9.1's two fix rounds went to Patricia, who said each time the fault was in Quinn's new test. A reply like this
# sends the next round to Quinn.
QUINN_FAULT = re.compile(r"Quinn's (?:folder|file|tests?)\b|\b(?:fault|failure|cause|bug|problem)s? (?:is|are|lies|lie) "
                         r"in (?:the |a )?(?:tests?\b|`?(?:game/)?tests/)|\bnot in `?(?:game/)?(?:scripts|scenes)/|"
                         r"\bdiag needed\b", re.I)
# L47: both T15.1 fix rounds said "I'm guessing" and missed; one `diag:` line in the FAIL message (zoom state, cell
# counts, departures) showed the last cause in a single run. An unexplained failure gets a diag line, not a guess.
DIAG_RULE = {
    "qa": ("If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's "
           "FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, "
           "counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. "),
    "code": ("If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and "
             "write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. "),
}
IMPACT_MAX = 40   # test functions listed in a brief; the rest are counted
PHRASE_STOP = {"per", "max", "min", "level", "levels", "time", "rate", "base", "new", "model", "change", "growth"}   # in most upgrade tests' names
TEST_RULES = (
    " Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, "
    "wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which "
    "extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is "
    "missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, "
    "node count or screen size: read it from the config, the scene, or ProjectSettings "
    "(`display/window/size/viewport_width` and `_height`).")

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
    """Item numbers named in a line: "Item 2", "items 1 and 3", "Items 3–5", "Item 3: ... Item 4: ..."."""
    nums = []
    for m in re.finditer(r"\bitems?\s+(\d+(?:\s*(?:,|and|&|–|-|to)\s*\d+)*)", text, re.I):
        nums += [int(n) for n in re.findall(r"\d+", m.group(1))]
        for a, b in re.findall(r"(\d+)\s*(?:–|-|to)\s*(\d+)", m.group(1)):   # a range: 0.2 "Items 3–5" was read as 3 only
            nums += list(range(int(a), int(b) + 1))
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
    """{owner: [lines]} for Patricia, Bob and Quinn; Quinn's lines carry the "Item N" header above them. A sub-bullet
    (indented deeper than its owner's first bullet) under Patricia or Bob is ("sub", text): it inherits its parent's items."""
    blocks, owner, indent = {}, None, None
    for line in body.splitlines():
        m = re.match(r"^- \*\*(\w+)\b", line)
        if m:
            owner = m.group(1) if m.group(1) in OWNERS else None
            indent = None
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
            depth = len(line) - len(line.lstrip())
            indent = depth if indent is None else indent
            sub = depth > indent and owner != "Quinn"   # 0.2 Bob's fork/gears/truck lines sat under "Items 3–5" and were dropped
            blocks[owner].append(("sub" if sub else "line", s[2:]))
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
    m = re.match(r"[\d.]+[a-z]?", Path(path).stem)
    version = meta.get("version") or (m.group(0) if m else Path(path).stem)
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
        parent = []
        for kind, line in contract.get(owner, []):
            nums = item_numbers(line)
            if kind == "line":
                parent = nums
            elif not nums and parent:   # a sub-bullet: its parent's item, or the one of them it matches best
                nums = parent if len(parent) == 1 else match_items(line, [c for c in changes if c[0] in parent])
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
        sentences = re.split(r"(?<=[.;])\s", own)
        gone = {t for s in sentences if REMOVED.search(s) for t in backticked(s) if is_node(t)}
        # 0.2 C14: "Replaces ... the C1 hand fix (`ShopScroll` one-row height)": a node after replaces/supersedes goes
        gone |= {t for s in sentences for m in [REPLACES.search(s)] if m for t in backticked(s[m.end():]) if is_node(t)}
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
            "goals": goals, "placeholders": meta.get("visuals", "").strip().lower() == "placeholder"}


# ---------------------------------------------------------------------------------------------- the scan
def newest_unit_log(game, partial=False):
    """The newest full-suite unit log. A CB_ONLY run's log holds a few tests only (Quinn's own runs, the x1 check),
    so the scan skips it; the x1 check asks for it with partial=True."""
    logs = sorted((game / "reports" / "_runs").glob("*/unit.log"), key=lambda p: p.parent.name)
    for log in reversed(logs):
        if partial or "CB_ONLY: running" not in log.read_text(encoding="utf-8", errors="replace"):
            return log
    return None


def unit_results(game):
    """{test: PASS|FAIL}, each test's newest result: the newest full unit log, then every newer `--only` log laid
    over it (obstacles item 23: after an `--only` step the scan read T9.1's older full-log FAIL and held it)."""
    logs = sorted((Path(game) / "reports" / "_runs").glob("*/unit.log"), key=lambda p: p.parent.name)
    full = newest_unit_log(game)
    start = logs.index(full) if full in logs else 0
    results = {}
    for log in logs[start:]:
        for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^(PASS|FAIL)\s+(t_\w+)", line)
            if m:
                results[m.group(2)] = m.group(1)
    return results


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
    for script in (game / "scripts").glob("**/*.gd"):   # nodes built in code (0.2 C15: shop_ui.gd names ShopButton)
        nodes |= set(re.findall(r'\.name\s*=\s*"(\w+)"', script.read_text(encoding="utf-8", errors="replace")))
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
    results, log = unit_results(game), newest_unit_log(game)
    marks = {}   # {goal id: [tests]} from Quinn's `# goal <ID>` line above each test function
    for f in sorted((game / "tests").glob("*.gd")):
        for gid, t in re.findall(r"^\s*#\s*goal\s+(?:\d+\.\d+(?:\.\d+)?\s+)?(\S+).*\n(?:[ \t]*#(?![ \t]*goal\b).*\n)*[ \t]*func\s+(t_\w+)", f.read_text(encoding="utf-8", errors="replace"), re.M):   # L51: `# goal 0.3 T6.1`
            marks.setdefault(gid, []).append(t)
    handoffs = sorted(p.name for p in (game / "specs").glob("*handoff*.md"))
    handoff_text = {p.name: p.read_text(encoding="utf-8") for p in (game / "specs").glob("*handoff*.md")}
    ledger = {}
    ledger_path = Path(ledger_path) if ledger_path else game / "reports" / "goal" / "ledger.json"
    if ledger_path.is_file():
        ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    return {"keys": keys, "nodes": nodes, "groups": groups, "x1": x1, "results": results,
            "handoff_text": handoff_text, "marks": marks,
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
        entry = ledger.get(gid, {})
        built = gid in ledger and "held" not in entry
        by_marks = False
        if goal["kind"] == "test" and not re.search(r"\bmutations?\b", goal["text"], re.I):
            # once this spec's tests carry `# goal <ID>` marks, a line's evidence is its own marked tests: 0.2 T1.1
            # was batched with the mutations line, its group comment named items 1-8, and all 12 lines read as done
            mine = set(tests_for(spec, found, []))
            marked = {k: [t for t in v if t in mine] for k, v in found.get("marks", {}).items()}
            if any(marked.get(g) for g, x in spec["goals"].items() if x["kind"] == "test"):
                tests, by_marks = marked.get(gid, []), True
        for t in tests:
            r = found["results"].get(t)
            ok = r == "PASS" or (r is None and t in found["x1"] and (built or not by_marks))   # an unrun x1 test proves a built line only
            ev.append({"kind": "test", "name": t, "ok": ok, "result": r or ("x1, designer plays" if t in found["x1"]
                                                                           else "not run")})
        held = entry.get("held") if entry.get("text") == text_hash(goal) else None   # a spec edit lifts the hold
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
        # a built test goal whose item is red waits too: the failing tests are a newer line's (0.1.4 T14.4 made
        # T14.1-T14.3 partial), and rebuilding them would send Quinn back over tests already written
        waits = status == "partial" and goal["kind"] in ("change", "test") and built
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
        items = sorted({n for b in batch if not re.search(r"\bmutations?\b", b["text"], re.I) for n in b["items"]}
                       or {n for b in batch for n in b["items"]})   # the mutations line covers every item: not a label
        label = f"{spec['version']} item{'s' if len(items) > 1 else ''} {', '.join(map(str, items))}"
        out[QA] = head + (
            f"Write the tests for these contract lines, from the spec, not the code (Process 2): every expected "
            f"number read from the config. Register them in `tests/run_tests.gd` under one group comment that starts "
            f"`# {label} (written from game/specs/{spec['file']} before the code)` (the goal agent finds them by it). "
            f"Add a mutation per new test to `tests/mutations.json`. Do not run the tests, mutations or shots: the goal "
            f"agent runs every check right after you (team.md: scripts run on Rex, not Sonnet); a parse check with "
            f"Godot's `--check-only` is fine. A failing test is a finding: report it, never bend the test to the code. On the line just above each new test function, write "
            f"`# goal <ID>` with the contract line's ID below (the goal agent maps tests to lines by it)."
            + INTERACTION_CHECKLIST + TEST_RULES
            + (" A line saying \"shown failing on the current build\" is a bug the designer saw in play: its test "
               "must fail on this build, on the check that shows the bug (a script error does not count); if it "
               "passes, it does not reproduce the bug. Where the line or spec text says what stays (keep, only, "
               "not, as before), also write a keep test that pins each named thing at its current value, so a fix "
               "that moves it fails (0.1.4: a lid fix asked to change the end also moved the open pose)."
               if any(FAIL_FIRST.search(b["text"]) for b in batch) else "")
            + f"\n\nContract lines:\n{lines}\n\nSpec text:\n{spec_slice(spec, goal)}\n"
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
            f"`python -I _tools/contract_check.py` before you finish. {LAYOUT_RULE}{STYLE_MINIMUMS}{keys}\n{hand_ref}\nYour contract lines:\n{lines}\n\n"
            f"Spec text:\n{spec_slice(spec, goal)}") + tail
    rows = test_impact(goal)
    if rows:   # L39 (b): the stale tests are updated beside the build, from the spec, not found red in fix rounds
        out[QA] = head + (
            f"Patricia and Bob are building this change in parallel ({', '.join(goal['owners'])}). These existing "
            f"tests read names it touches:\n{impact_text(rows)}\n\nFor each, compare what it expects with the spec "
            f"text below. Update only a test whose expectation this change replaces (a flow step it now takes "
            f"differently, a node it renames or removes, a value it changes), and quote the spec line in a comment "
            f"beside it; most names on the list are only read, so leave those tests as they are. Change no "
            f"expectation the spec does not change, and write no new tests (the contract lines do that). Do not run "
            f"the tests: the goal agent runs them, with the windowed suites this list names, after the build."
            + TEST_RULES + f"\n\nSpec text:\n{spec_slice(spec, goal)}") + tail
    return out


def impact_tokens(goal):
    """The names a change touches that a test could read: its nodes (kept and removed), config keys, and the backticked
    code names in its text and contract lines (snake_case functions and keys, UPPER_CASE states, CamelCase nodes)."""
    own = goal["text"] + " " + " ".join(l for ls in goal["lines"].values() for l in ls)
    toks = set(goal["nodes"]) | set(goal.get("removed", [])) | set(goal["keys"])
    for t in (w for span in backticked(own) for w in re.findall(r"[A-Za-z_]\w*", span)):   # a formula holds several
        if is_key(t.lstrip("_")) or is_node(t) or re.fullmatch(r"[A-Z][A-Z0-9_]{3,}", t):
            toks.add(t)
    return sorted(toks)


def impact_phrases(goal):
    """Two-word phrases of the change's title and text, as identifier parts: "the second stop" -> second_stop and
    SecondStop, "the shop panel" -> shop_panel and ShopPanel. Item 9 and item 14 broke tests through names the spec
    wrote only in words (L39)."""
    out = set()
    prose = re.sub(r"`[^`]*`", ".", goal["title"] + ". " + goal["text"])   # code names are impact_tokens' job
    for part in re.split(r"[^\w\s']+|_", prose.lower()):
        ws = re.findall(r"[a-z']+", part)
        for a, b in zip(ws, ws[1:]):
            if min(len(a), len(b)) >= 3 and not {a, b} & (STOP | PHRASE_STOP) and "'" not in a + b:
                out.add(f"{a}_{b}")
    return sorted(out)


def test_impact(goal, tests=None):
    """[(file, function, suite, [names])]: each existing test function (or shared helper) in game/tests/ that reads a
    name the change touches, so Quinn updates the stale ones beside the build, not in fix rounds (L39, fix b)."""
    tests = tests or ROOT / "game" / "tests"
    toks, phrases = impact_tokens(goal), impact_phrases(goal)
    if not (toks or phrases) or not tests.is_dir():
        return []
    alts = [r"(?<!\w)" + re.escape(t) + r"(?!\w)" for t in sorted(toks, key=len, reverse=True)]
    camel = {p.replace("_", " ").title().replace(" ", ""): p for p in phrases}
    alts += [r"(?<![A-Za-z0-9])" + re.escape(p) + r"(?![a-z0-9])" for p in phrases]   # inside a snake_case name
    alts += [re.escape(c) + r"(?![a-z0-9])" for c in camel]                         # inside a CamelCase name
    pat = re.compile("(" + "|".join(alts) + ")") if alts else None
    out = []
    for f in sorted(tests.glob("*.gd")):
        suite = SUITE_FILES.get(f.name) or ("unit" if UNIT_FILES.match(f.name) else None)
        if not suite:
            continue
        hits, cur = {}, ""
        for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^(?:static\s+)?func\s+(\w+)", line)
            if m:
                cur = m.group(1)
            if cur and not line.lstrip().startswith("#"):
                for t in pat.findall(line):
                    hits.setdefault(cur, set()).add(camel.get(t, t))   # a CamelCase hit is named by its phrase
        out += [(f"tests/{f.name}", fn, suite, sorted(ts)) for fn, ts in hits.items()]
    return out


def impact_suites(rows):
    """The windowed suites a change's impact list reaches: run with `unit` in that step's test check."""
    return sorted({s for _, _, s, _ in rows if s != "unit"}, key=list(SUITE_FILES.values()).index)


def impact_text(rows):
    """The impact list for a brief: one line per file, its functions with the names each reads."""
    by_file = {}
    for f, fn, suite, ts in rows[:IMPACT_MAX]:
        by_file.setdefault((f, suite), []).append(f"`{fn}` ({', '.join(ts)})")
    more = f"\n- and {len(rows) - IMPACT_MAX} more functions" if len(rows) > IMPACT_MAX else ""
    return "\n".join(f"- `{f}` [{suite}]: " + ", ".join(fns) for (f, suite), fns in by_file.items()) + more


# ---------------------------------------------------------------------------------------------- change impact (L42)
# L42 (the designer: "we don't need to test things we know work already, or won't be affected by a change"): a step ran
# ~220 unit tests (up to 27 min) as its gate. A round now runs its own tests, the tests that read what the step's changed
# files define (change_impact()), and last round's failures; the full suite runs once, at the run's end (final_suite()).
CORE_FILES = {"game/scripts/main.gd", "game/scripts/game_config.gd", "game/scripts/default_config.tres",
              "game/scenes/main.tscn", "game/project.godot"}   # every test loads these: only their changed names count
IMPACT_PATHS = ["game/scripts", "game/scenes", "game/materials", "game/tests", "game/translations", "game/project.godot"]
TEST_MAP = "game/reports/_runs/test-map.json"   # the test index cache, by file mtime and size (gitignored with the logs)
HELPER_FILES = {"flow.gd", "replay_core.gd"}   # shared helpers the suites call, outside the unit chain
GD_DECL = re.compile(r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(func|var|const|signal|enum|class)\s+(\w+)")
GODOT_TYPES = re.compile(r"^(?:Node|Node2D|Node3D|Control|Label|Button|Panel|Camera3D|MeshInstance3D|Sprite3D|"
                         r"CanvasLayer|[HV]BoxContainer|MarginContainer|TextureRect|ColorRect|Timer|Area3D|"
                         r"CollisionShape3D|DirectionalLight3D|WorldEnvironment|Mesh|Body)\d*$")   # node names too generic to count
FULL_LOGS = ("unit", "start", "play", "measure", "snapshot", "ui", "touch")   # godot_run's `all`: one log each


def idents(text):
    return set(re.findall(r"[A-Za-z_]\w*", text))


def strip_comment(line):
    """A GDScript line without its comment (a # outside quotes)."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            quote = None if ch == quote else quote
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            return line[:i]
    return line


def index_file(text):
    """{function: {"t": [identifiers it reads, string contents included], "c": [names it calls or passes]}} of one test
    file; its top level (extends, vars) is under ""."""
    funcs, cur = {"": (set(), set())}, ""
    for line in text.splitlines():
        m = re.match(r"^(?:static\s+)?func\s+(\w+)", line)
        if m:
            cur = m.group(1)
            funcs.setdefault(cur, (set(), set()))
            line = line[m.end():]
        elif line and not line[0].isspace() and not line.startswith("#"):
            cur = ""
        code = strip_comment(line)
        funcs[cur][0].update(idents(code))
        funcs[cur][1].update(re.findall(r"([A-Za-z_]\w*)\s*\(", code))
    return {f: {"t": sorted(t), "c": sorted(c)} for f, (t, c) in funcs.items()}


def test_index(tests=None):
    """{file name: {"stamp", "suite", "funcs"}} for each unit test file, windowed suite and shared helper, cached in
    TEST_MAP and re-read only for a file whose mtime or size changed."""
    tests = tests or ROOT / "game" / "tests"
    cache_path = ROOT / TEST_MAP
    try:
        cache = json.loads(cache_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        cache = {}
    out = {}
    for f in sorted(tests.glob("*.gd")):
        suite = SUITE_FILES.get(f.name) or ("unit" if UNIT_FILES.match(f.name) else
                                            "helper" if f.name in HELPER_FILES else None)
        if not suite:
            continue
        st = f.stat()
        stamp = [st.st_mtime_ns, st.st_size]
        hit = cache.get(f.name)
        if not isinstance(hit, dict) or hit.get("stamp") != stamp or hit.get("suite") != suite:
            hit = {"stamp": stamp, "suite": suite,
                   "funcs": index_file(f.read_text(encoding="utf-8", errors="replace"))}
        out[f.name] = hit
    if out != cache:
        try:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_text(json.dumps(out), encoding="utf-8")
        except OSError:
            pass
    return out


def tests_reading(index, tokens, direct=frozenset()):
    """({unit test: [tokens]}, {windowed suite}) for the functions reading any of `tokens`, directly or through the
    helpers they call. Names are merged across files: the unit chain is one class (each file extends the one before).
    `direct`: names that count only in a test function's own body (a file's stem, class and scene nodes: every setup
    helper reads `Hive`, so through helpers they would reach nearly every test)."""
    reach, calls, units, suites = {}, {}, set(), {}
    for name, e in index.items():
        for fn, d in e["funcs"].items():
            if not fn:
                continue
            reach.setdefault(fn, set()).update((tokens - direct) & set(d["t"]))
            calls.setdefault(fn, set()).update(c for c in d["c"] if c != fn)
            if e["suite"] == "unit" and fn.startswith("t_"):
                units.add(fn)
            elif e["suite"] not in ("unit", "helper"):
                suites.setdefault(e["suite"], set()).add(fn)
    grew = True
    while grew:   # a test reaches what its helpers reach
        grew = False
        for fn, cs in calls.items():
            more = set().union(*(reach.get(c, set()) for c in cs)) - reach[fn]
            if more:
                reach[fn] |= more
                grew = True
    for name, e in index.items():
        for fn, d in e["funcs"].items():
            if fn in units or (fn and e["suite"] not in ("unit", "helper")):
                reach[fn] |= direct & tokens & set(d["t"])
    hit = {fn: sorted(reach[fn]) for fn in sorted(units) if reach[fn]}
    return hit, {s for s, fns in suites.items() if any(reach[f] for f in fns)}


def diff_lines(diff):
    """(new-side line numbers a `git diff -U0` touches, the texts of its added and removed lines); None: no hunk."""
    nums, texts, seen = set(), [], False
    for line in diff.splitlines():
        m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
        if m:
            seen = True
            start, n = int(m.group(1)), int(m.group(2)) if m.group(2) is not None else 1
            nums.update(range(start, start + n) if n else {max(start, 1), start + 1})   # a deletion: the lines around it
        elif seen and line[:1] in "+-" and not line.startswith(("+++", "---")):
            texts.append(line[1:])
    return (nums, texts) if seen else None


def gd_members(text):
    """([(first line, last line, kind, name)] of a GDScript file's top-level entries, 1-based and inclusive; a line that
    declares nothing (extends, class_name) has kind "top"."""
    src = text.splitlines()
    tops = []
    for i, line in enumerate(src, 1):
        if not line.strip() or line[0].isspace() or line.startswith("#"):
            continue
        m = GD_DECL.match(line)
        tops.append([i, i, m.group(1) if m else "top", m.group(2) if m else ""])
    for a, b in zip(tops, tops[1:]):
        a[1] = b[0] - 1
    if tops:
        tops[-1][1] = len(src)
    return [tuple(t) for t in tops]


def project_names():
    """(config keys, scene node names) of the game, as scan() reads them."""
    found = scan(ROOT / "game", ledger_path=ROOT / "game" / "reports" / "goal" / "none.json")
    return found["keys"], {n for n in found["nodes"] if not GODOT_TYPES.match(n)}


def scene_users(res_path, depth=2):
    """Node names that use a resource (a script, material or prop scene) in the game's scenes, and the nodes that
    instance those scenes (one level up), e.g. truck.gd -> Truck."""
    out = set()
    for scene in sorted((ROOT / "game" / "scenes").rglob("*.tscn")):
        if "variants" in scene.parts or "retired" in scene.parts:
            continue
        text = scene.read_text(encoding="utf-8", errors="replace")
        ids = re.findall(rf'^\[ext_resource[^\]]*path="{re.escape(res_path)}"[^\]]*id="([^"]+)"', text, re.M)
        ids += re.findall(rf'^\[ext_resource[^\]]*id="([^"]+)"[^\]]*path="{re.escape(res_path)}"', text, re.M)
        users = set()
        for sec in re.split(r"(?m)^(?=\[)", text):
            m = re.match(r'\[node name="([^"]+)"', sec)
            if m and any(f'ExtResource("{i}")' in sec for i in ids):
                users.add(m.group(1))
        out |= users
        if users and depth > 1 and scene.name != "main.tscn":
            out |= scene_users("res://" + scene.relative_to(ROOT / "game").as_posix(), depth - 1)
    return {n for n in out if not GODOT_TYPES.match(n)}


def file_tokens(path, text, touched, keys, nodes):
    """(names a test would read to exercise the change to one game file, the file's whole name set for widening).
    `touched`: (line numbers, changed texts), or None for a new or undiffable file (every line counts)."""
    rel = path[len("game/"):] if path.startswith("game/") else path
    core, stem = path in CORE_FILES, Path(path).stem
    src = text.splitlines()
    lines, texts = touched if touched else (set(range(1, len(src) + 1)), src)
    found = {w for t in texts for w in idents(t)} & (keys | nodes)
    own = {stem} | scene_users("res://" + rel) if not core else set()
    if path.endswith(".gd"):
        tops = gd_members(text)
        names = {n for _, _, k, n in tops if n}
        if any(k == "top" and any(a <= x <= b for x in lines) for a, b, k, _ in tops):   # extends / class_name changed
            lines = set(range(1, len(src) + 1))
        body = {n: "\n".join(strip_comment(l) for l in src[a - 1:b]) for a, b, k, n in tops if n}
        changed = {n for a, b, k, n in tops if n and any(a <= x <= b for x in lines)}
        funcs = {n for _, _, k, n in tops if k == "func"}
        callers, grew = changed & funcs, True
        while grew:   # a function calling (or connecting) a changed function changed too
            grew = False
            for f in funcs - callers:
                if idents(body[f]) & callers:
                    callers.add(f)
                    grew = True
        reads = set().union(*(idents(body[n]) for n in changed & funcs)) & (names | keys | nodes)
        found |= changed | callers | ({w for t in texts for w in idents(t)} & (names | keys | nodes))
        cls = re.search(r"^class_name\s+(\w+)", text, re.M)
        own |= ({cls.group(1)} if cls and not core else set()) | reads   # the state a changed function reads: direct only
        return found | own, names | own | found, own - found
    if path.endswith(".tscn"):
        secs = [(i, l) for i, l in enumerate(src, 1) if l.startswith("[")]
        subs = set()
        for x in lines:
            head = next((l for i, l in reversed(secs) if i <= x), "")
            m = re.match(r'\[(node|sub_resource|ext_resource)\b.*?(?:name|id)="([^"]+)"', head)
            if m and m.group(1) == "node":
                found.add(re.search(r'name="([^"]+)"', head).group(1))
            elif m and m.group(1) == "sub_resource":
                subs.add(re.search(r'id="([^"]+)"', head).group(1))
            p = re.search(r'path="res://([^"]+\.gd)"', head)
            if p and (ROOT / "game" / p.group(1)).is_file():
                g_text = (ROOT / "game" / p.group(1)).read_text(encoding="utf-8", errors="replace")
                cls = re.search(r"^class_name\s+(\w+)", g_text, re.M)
                found |= {Path(p.group(1)).stem} | ({cls.group(1)} if cls else set())
        found |= {n for t in texts for n in re.findall(r'name="([^"]+)"', t)}
        for sec in re.split(r"(?m)^(?=\[)", text):
            m = re.match(r'\[node name="([^"]+)"', sec)
            if m and any(f'SubResource("{s}")' in sec for s in subs):
                found.add(m.group(1))
        root = re.search(r'^\[node name="([^"]+)"', text, re.M)
        own |= {root.group(1)} if root and not core else set()
        found = {n for n in found if not GODOT_TYPES.match(n)}
        return found | own, found | own | set(re.findall(r'^\[node name="([^"]+)"', text, re.M)) - {""}, own - found
    # config resources, translations, project.godot, materials: the keys and names on the changed lines
    found |= {m for t in texts for m in re.findall(r"^\s*([A-Za-z_]\w*)\s*=", t)} - {"script", "metadata", "resource_name"}
    found |= {w for t in texts for w in idents(t.split(",")[0]) if path.endswith(".csv") and len(w) > 3}
    if path.endswith("project.godot"):
        found |= {w for t in texts for w in re.findall(r"(\w+)\s*=", t.replace("/", " ")) if len(w) > 3}
    return found | own, found | own, own - found


def change_snapshot():
    """{path: [content hash, untracked]} of the uncommitted files a test could depend on; a step's changes are the
    difference from its start (step_changes())."""
    out = {}
    for row in git("status", "--porcelain", "--untracked-files=all", "--", *IMPACT_PATHS)[1].splitlines():
        path = row[3:].strip().strip('"').split(" -> ")[-1]
        if not path or path.startswith("game/reports/") or path.endswith((".uid", ".import")):
            continue
        f = ROOT / path
        out[path] = [hashlib.sha1(f.read_bytes()).hexdigest() if f.is_file() else "deleted", row.startswith("??")]
    return out


def step_changes(start):
    """{path: untracked} of each file whose state differs from the step's start snapshot (changed, new or reverted)."""
    now_ = change_snapshot()
    return {p: (now_.get(p) or [None, False])[1] for p in set(now_) | set(start) if now_.get(p) != start.get(p)}


def file_diff(path):
    """The file's `git diff -U0` against HEAD (replaced by a fake in the tests)."""
    return git("diff", "-U0", "HEAD", "--", path)[1]


def change_impact(changes, tests=None):
    """L42: what a round runs for the files the step changed ({path: untracked}). Returns {"tests": {test: [reasons]},
    "suites": {suite: reason}, "uncovered": [paths no test reads], "widened": [paths], "written": {tests the step
    changed}}. A game file maps to the unit tests that read its names (directly or through helpers): a script's
    class, stem, scene nodes and changed members with their callers and the state they read; a scene's changed nodes; a
    config file's changed keys. A core file (CORE_FILES) counts only its changed names; a file no test reads is widened
    to every name it defines. A change under game/tests/ runs only the changed tests (and the tests calling a changed
    helper; a changed windowed suite file runs that suite). Conservative by design; the end-of-run suite backs it."""
    out = {"tests": {}, "suites": {}, "uncovered": [], "widened": [], "written": set()}
    if not changes:
        return out
    index = test_index(tests)
    keys, nodes = project_names()
    add = lambda names, why: [out["tests"].setdefault(t, []).append(why) for t in names if why not in out["tests"].get(t, [])]
    for path in sorted(changes):
        f, rel = ROOT / path, path[len("game/"):]
        text = f.read_text(encoding="utf-8", errors="replace") if f.is_file() else ""
        touched = None if changes[path] or not text else diff_lines(file_diff(path))
        if path.startswith("game/tests/"):
            name = f.name
            src = text.splitlines()
            lines, texts = touched if touched else (set(range(1, len(src) + 1)), src)
            if name in SUITE_FILES:
                out["suites"][SUITE_FILES[name]] = f"changed `{rel}`"
                continue
            if name == "run_tests.gd":   # a registration: the names on its changed lines
                direct = {t for x in texts for t in re.findall(r"\bt_\w+", x)}
                helpers = set()
            else:
                tops = gd_members(text) if name.endswith(".gd") else []
                if any(k == "top" and any(a <= x <= b for x in lines) for a, b, k, _ in tops):
                    lines = set(range(1, len(src) + 1))
                changed = {n for a, b, k, n in tops if k == "func" and any(a <= x <= b for x in lines)}
                direct = {n for n in changed if n.startswith("t_")}
                helpers = (changed - direct) if name.endswith(".gd") else {f.stem}
            units = {t for e in index.values() if e["suite"] == "unit" for t in e["funcs"] if t.startswith("t_")}
            direct &= units
            out["written"] |= direct
            add(sorted(direct), f"changed in `{rel}`")
            hit, suites = tests_reading(index, helpers) if helpers else ({}, set())
            add(sorted(hit), f"calls a helper changed in `{rel}`")
            for s in suites:
                out["suites"].setdefault(s, f"calls a helper changed in `{rel}`")
            if not (direct or hit or suites):
                out["uncovered"].append(path)
            continue
        tokens, every, direct = file_tokens(path, text, touched, keys, nodes)
        hit = tests_reading(index, tokens, direct)[0] if tokens else {}
        if not hit and every - tokens:   # no known coverage: widen to every name the file defines
            hit = tests_reading(index, every)[0]
            if hit:
                out["widened"].append(path)
        if hit:
            via = sorted(set().union(*map(set, hit.values())))
            add(sorted(hit), f"impacted by `{rel}` (via " + ", ".join(f"`{v}`" for v in via[:12])
                + (f" and {len(via) - 12} more" if len(via) > 12 else "") + ")")
        else:
            out["uncovered"].append(path)
    return out


def tests_line(own, impact, last, focus):
    """The board's record of which tests a round runs and why, so a missed impact can be traced (L42)."""
    names = lambda ts: ", ".join(f"`{t}`" for t in sorted(ts))
    parts = [f"own ({len(own)}): {names(own)}"] if own else []
    by_why = {}
    for t, whys in impact["tests"].items():
        for w in whys:
            by_why.setdefault(w, set()).add(t)
    parts += [f"{w} ({len(ts)}): {names(ts)}" for w, ts in sorted(by_why.items())]
    parts += [f"last failures ({len(last)}): {names(last)}"] if last else []
    text = (f"- Tests this round ({len(focus)}): " + "; ".join(parts) if focus else
            "- Tests this round: none (no unit test is the goal's own or reads what the step changed); `unit` skipped, "
            "the end-of-run full suite runs it")
    text += "".join(f"; suite `{s}` ({w})" for s, w in sorted(impact["suites"].items()))
    text += "".join(f"\n- Impact widened: no test reads the changed names of `{p[5:]}`; ran the tests reading any name "
                    f"it defines" for p in impact["widened"])
    text += "".join(f"\n- No test reads `{p[5:]}`: covered only by the end-of-run full suite" for p in impact["uncovered"])
    return text + "\n"


def scan_handoffs(game=None):
    return sorted(p.name for p in ((game or ROOT / "game") / "specs").glob("*handoff*.md"))


def run_agent(agent, prompt, max_turns=None):
    """One fresh headless agent (generate.run_agent with file and shell tools; Vera reads only). Replaced by a fake in the tests."""
    return g.run_agent(agent, prompt, tools="Read,Grep,Glob" if agent == CRITIC else TOOLS, max_turns=max_turns)


class Transient(Exception):
    """An agent call failed twice on a network or API error: the run pauses (resumable); it did not fail."""


def agent_once_more(agent, prompt, board, **kw):
    """run_agent, retried once on a transient API or network error (run 0.2 ended `failed` on ENOTFOUND, 240952d);
    a second one raises Transient, which pauses the run."""
    try:
        return run_agent(agent, prompt, **kw)
    except g.AgentError as e:
        if not TRANSIENT.search(str(e)):
            raise
        say(board, f"\n**{g.NAMES[agent]}:** transient error ({e}); retrying once\n")
    try:
        return run_agent(agent, prompt, **kw)
    except g.AgentError as e:
        if TRANSIENT.search(str(e)):
            raise Transient(f"{g.NAMES[agent]}: {e}") from e
        raise


def cmd_label(cmd):
    """The live view's name for a command ("godot_run unit start", "git commit"), or "" for a quick git read."""
    if cmd and cmd[0] == "git":
        return f"git {cmd[1]}" if len(cmd) > 1 and cmd[1] in ("commit", "push", "merge") else ""
    for i, c in enumerate(cmd):
        if str(c).endswith(".py"):
            args = [a for a in cmd[i + 1:i + 4] if not str(a).startswith("-") and "=" not in str(a)]
            return " ".join([Path(c).stem, *map(str, args)])[:40]
    return Path(str(cmd[0])).stem if cmd else ""


def run_cmd(cmd, env=None, timeout=3600):
    """(exit code, output) of one check command, run from the repo root. Replaced by a fake in the tests.
    Each one but a quick git read shows in the live view while it runs (L5: a silent unit run looked stalled)."""
    label = cmd_label(cmd)
    key = g.live.start(label) if label else None
    began, code = datetime.datetime.now(), 1
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           env={**os.environ, **(env or {})}, timeout=timeout)
        code = p.returncode
        return p.returncode, (p.stdout + p.stderr)
    except subprocess.TimeoutExpired:
        code = 124
        return 124, f"timed out after {timeout} s"
    finally:
        if key:
            g.live.end(key, label, "PASS" if code == 0 else f"exit {code}", ok=code == 0,
                       seconds=int((datetime.datetime.now() - began).total_seconds()))


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


def checks(spec, goal, base, version, suites=()):
    """The check commands for a step, in order: [(label, cmd, env)]. `suites`: the windowed suites the change's
    impact list reaches (L39), run with unit so a change that breaks play, measure or snapshot is seen in its step."""
    py = [sys.executable, "-I"]
    out = [("contract", py + ["_tools/contract_check.py"], None),
           ("tests", py + ["_tools/godot_run.py", "--refresh", "unit", "start", *suites, *ONLY_FLAGS], ENV)]   # L41: flags, not env alone; L48: a new class_name or CSV key needs the import rebuilt
    if goal["kind"] == "change" and "Bob" in goal["owners"]:
        out.append(("ui shots", py + ["_tools/ui_shots.py", f"{version}={ROOT}"], None))
        # one style-loop round (render, style_check, Vera; no Bob): a FAIL goes to Bob in the fix round. Each fix
        # round's call is the next run-N/ under style/<version>-goal-<id>/ (naming review, 2026-11-21).
        slug = f"{version}-goal-{goal['id']}".lower()
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


BUILD_PATHS = ["game/scripts", "game/scenes", "game/materials", "game/tests", "game/specs",
               "game/translations", "game/project.godot"]   # 0.2 C8's CSV and its project.godot registration were left out


def tree_state(paths=None):
    """The build folders' uncommitted state; the same before and after a step means the agents changed nothing."""
    paths = paths or BUILD_PATHS
    return git("status", "--porcelain", "--", *paths)[1] + git("diff", "HEAD", "--", *paths)[1]


def marked_tests(goal_id, version=None):
    """Test functions Quinn marked `# goal <id>` above, in game/tests/*.gd; `##` doc lines may come between (L42: T9.1's
    mark sat above two doc lines, so its step found no own test and ran the whole unit suite). L51: goal ids repeat
    across specs (0.2 and 0.3 both have T6.1), so a `# goal <version> <id>` mark for this spec's version wins over
    bare `# goal <id>` marks."""
    tail = r"\b.*\n(?:[ \t]*#(?![ \t]*goal\b).*\n)*[ \t]*func\s+(t_\w+)"
    texts = [f.read_text(encoding="utf-8", errors="replace") for f in sorted((ROOT / "game" / "tests").glob("*.gd"))]
    if version:
        out = [t for x in texts for t in re.findall(rf"^\s*#\s*goal\s+{re.escape(version)}\s+{re.escape(goal_id)}{tail}",
                                                    x, re.M)]
        if out:
            return out
    return [t for x in texts for t in re.findall(rf"^\s*#\s*goal\s+{re.escape(goal_id)}{tail}", x, re.M)]


def red_tests(partial=False):
    """{test: True} for each test the newest unit log shows failing on a real check, not only a script stop."""
    log, out = newest_unit_log(ROOT / "game", partial), {}
    for line in (log.read_text(encoding="utf-8", errors="replace").splitlines() if log else []):
        m = re.match(r"^FAIL\s+(t_\w+)\s+(.*?)(?:\s+\(\d+ ms\))?$", line)
        if m:
            reasons = [r.strip() for r in m.group(2).split(" | ")]
            out[m.group(1)] = any(r and not r.startswith("test stopped before its final line") for r in reasons)
    return out


def failing_tests(output):
    """([unit tests the check's output shows failing], whether they can be rerun by name): not when a start or
    windowed suite failed, nor when godot_run cut the FAIL list at 15 lines."""
    names, suite, whole = [], None, True
    for line in output.splitlines():
        s = line.strip()
        m = re.match(r"^(PASS|FAIL|TIMEOUT)\s+(\w+)", s)
        if "more FAIL lines" in s:
            whole = False
        if not m:
            continue
        if not m.group(2).startswith("t_"):   # godot_run's suite line
            suite = m.group(2)
            whole = whole and (m.group(1) == "PASS" or suite == "unit")
        elif m.group(1) == "FAIL" and m.group(2) not in names:
            names.append(m.group(2))
    return names, whole and bool(names)


def timed_out(output):
    """L41: a suite hit its timeout (godot_run's TIMEOUT line, or run_cmd's own cut) and no test failed: the suite
    outgrew the limit, not a code bug, so it gets no fix round."""
    cut = re.search(r"^\s*TIMEOUT\s", output, re.M) or output.startswith("timed out after")
    return bool(cut) and not failing_tests(output)[0]


def run_tests_once_more(cmd, board, label, env=None):
    """L41: a test command, rerun once when it timed out with no failing test (T10.1 lost two fix rounds to the 15 min
    unit cap). Returns (code, output, paused): paused when the rerun timed out too; the board then says why."""
    code, out = run_cmd(cmd, env=env)
    if not (code and timed_out(out)):
        return code, out, False
    say(board, f"- Check `{label}`: TIMEOUT with no failing test; retrying once\n")
    code, out = run_cmd(cmd, env=env)
    if not (code and timed_out(out)):
        return code, out, False
    say(board, f"- Check `{label}`: TIMEOUT again\n\n```\n{summary_of(out)}\n```\n\n**Paused:** `{label}` timed out "
               f"twice with no failing test: the suite outgrew godot_run's timeout (or a test hangs), which is not a "
               f"code bug, so no fix round was started. Check the newest `game/reports/_runs/*/unit.log` for the last "
               f"test it reached, raise the limit in `_tools/godot_run.py` (`UNIT_CAP_S`) if the suite only grew, then "
               f"run the same command again to resume.\n")
    return code, out, True


def own_tests(spec, goal, batch):
    """L40: the tests a round runs alone (`--only`): a test goal's marked tests; a change's registered item tests and the
    unit tests on its impact list. The round adds change_impact()'s tests and the last failures (L42)."""
    if goal["kind"] == "test":
        return sorted({t for b in batch for t in marked_tests(b["id"], spec["version"])})
    own = set(tests_for(spec, scan(ROOT / "game"), goal["items"]))
    own |= {fn for _, fn, s, _ in test_impact(goal) if s == "unit" and fn.startswith("t_")}
    return sorted(own)


def fresh_green_full():
    """L42 (was L40's fresh_green_unit): the newest `all` run folder (a log for every suite, unit not a CB_ONLY run) if
    every suite is green and it began after the last change to any build file, so the end-of-run check reuses it
    instead of running every suite again; else None."""
    runs = sorted((ROOT / "game" / "reports" / "_runs").glob("*/unit.log"), key=lambda p: p.parent.name)
    log = next((u for u in reversed(runs) if all((u.parent / f"{s}.log").is_file() for s in FULL_LOGS)), None)
    if not log or "CB_ONLY: running" in log.read_text(encoding="utf-8", errors="replace"):
        return None
    for s in FULL_LOGS:
        text = (log.parent / f"{s}.log").read_text(encoding="utf-8", errors="replace")
        if re.search(r"^\s*FAIL\s", text, re.M) or re.search(r"^\s*(?:SCRIPT ERROR|Parse Error)\b", text, re.M):
            return None
        if s != "start" and not re.search(r"^---- \d+ (passed|checks), 0 failed", text, re.M):
            return None
    try:
        began = datetime.datetime.strptime(log.parent.name, "%Y%m%d-%H%M%S").timestamp()
    except ValueError:
        return None
    for rel in BUILD_PATHS:
        p = ROOT / rel
        for f in ([p] if p.is_file() else p.rglob("*") if p.is_dir() else []):
            if f.is_file() and not f.name.endswith((".uid", ".import")) and f.stat().st_mtime > began:
                return None
    return log


def rerun_flaky(output, own, board):
    """Item 11: the failing tests that are not the goal's own, rerun alone once. Those that pass are logged as flaky and
    get no fix round (T11.1: two timing tests cost 2 fix rounds). Returns the flaky names."""
    names, whole = failing_tests(output)
    others = [t for t in names if t not in own]
    if not whole or not others:
        return set()
    code, out = run_cmd([sys.executable, "-I", "_tools/godot_run.py", "unit", "--only", ",".join(others), *ONLY_FLAGS])
    still = (set(failing_tests(out)[0]) or set(others)) if code else set()
    flaky = {t for t in others if t not in still}
    if flaky:
        say(board, f"- Flaky: {', '.join(f'`{t}`' for t in sorted(flaky))} failed, then passed alone on one rerun; "
                   f"no fix round for them\n")
    return flaky


def visual_lines():
    """{path: [lines]} of the lines setting a visual number (VISUAL) in the scenes, materials and scripts."""
    out = {}
    for rel in CODE_PATHS:
        for f in sorted((ROOT / rel).rglob("*")) if (ROOT / rel).is_dir() else []:
            if f.suffix in (".tscn", ".tres", ".gd") and f.is_file():
                rows = [l.strip() for l in f.read_text(encoding="utf-8", errors="replace").splitlines()
                        if VISUAL.search(l) and not l.lstrip().startswith("#")]
                if rows:
                    out[f.relative_to(ROOT).as_posix()] = rows
    return out


def visual_changes(before, after, spec_text=""):
    """Item 12: ["`path`: `old` -> `new`"] for each file whose visual numbers changed, unless every new number is
    one the spec text names (the spec asked for it)."""
    values = lambda text: {float(x) for x in re.findall(r"(?<![\w.])\d+(?:\.\d+)?", text)}   # 120.0 == 120; not Vector2's 2
    named, rows = values(spec_text), []
    for path in sorted(set(before) | set(after)):
        old, new = before.get(path, []), after.get(path, [])
        gone, came = [l for l in old if l not in new], [l for l in new if l not in old]
        if not (gone or came):
            continue
        nums = values(" ".join(came)) - values(" ".join(gone))
        if came and nums and nums <= named | MINIMUM_VALUES:
            continue
        rows.append(f"`{path}`: " + "; ".join(f"`{l}`" for l in gone or ["(none)"]) + " -> "
                    + "; ".join(f"`{l}`" for l in came or ["(removed)"]))
    return rows


def keep_placeholders(folder, ids, votes):
    """Append a placeholder-mode step's visual rows to the run's placeholders.md, the designer's play-test list."""
    path = folder / "placeholders.md"
    if not path.is_file():
        path.write_text("# Placeholder visuals to confirm at play-test\n\nKept by `goal_agent.py` (spec front matter "
                        "`visuals: placeholder`). Each row is in the tree; change it in Dev mode or the scene if it "
                        "looks wrong.\n", encoding="utf-8")
    with path.open("a", encoding="utf-8") as f:
        f.write(f"\n## {ids} ({now()})\n\n" + "\n".join(f"- {who}: {row}" for who, row in votes) + "\n")


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
    """Record the goals in the ledger and make a checkpoint commit of the game folders (never a push)."""
    code, branch = git("rev-parse", "--abbrev-ref", "HEAD")
    branch = branch.strip()
    if code or branch == "HEAD":   # detached: nowhere to commit
        return f"no commit: on `{branch}`"
    ledger = json.loads(ledger_path.read_text(encoding="utf-8")) if ledger_path.is_file() else {}
    for b in batch:
        ledger.setdefault(spec["file"], {})[b["id"]] = {"run": run, "at": now()}
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    ledger_path.write_text(json.dumps(ledger, indent=1), encoding="utf-8")
    paths = BUILD_PATHS   # queue #5: the run's state (ledger, blackboard, gaps) goes in one commit at the run's end
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


def commit_state(spec, run, folder, ledger_path, result):
    """One commit of the run's state (ledger.json and the run folder: blackboard, gaps, briefs) when the run ends,
    instead of a copy in every goal checkpoint (queue #5). Only those paths (`--only`), never on a detached HEAD."""
    code, branch = git("rev-parse", "--abbrev-ref", "HEAD")
    if code or branch.strip() == "HEAD":
        return "no state commit: on " + branch.strip()
    paths = [p.relative_to(ROOT).as_posix() for p in (ledger_path, folder) if p.exists()]
    if not paths:
        return "no state to commit"
    git("add", "--", *paths)
    code, out = git("diff", "--cached", "--quiet", "--", *paths)
    if code == 0:
        return "state unchanged"
    code, out = git("commit", "--only", "-m", f"{spec['version']} goal_agent run {run} state: {result}\n\n"
                    f"Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>", "--", *paths)
    return "state committed" if code == 0 else "state commit failed: " + summary_of(out, 6)


def ensure_branch(version):
    """The run commits on the branch the folder is on (`main`; milestone branches dropped, designer 2026-11-21)."""
    code, cur = git("rev-parse", "--abbrev-ref", "HEAD")
    if code or cur.strip() == "HEAD":
        raise SystemExit(f"goal_agent: not on a branch (detached HEAD); check out `main` first")
    return cur.strip(), "stays on it" + ("" if cur.strip() == "main" else " (not main: merge it after the run)")


def step(spec, goal, batch, run, folder, board, branch, usage, dry=False):
    """Build one goal (and its test batch) to green: agents, checks, fix rounds, checkpoint. Returns a result word."""
    ids = ", ".join(b["id"] for b in batch)
    plan = briefs(spec, goal, batch, run, branch)
    _, base = git("rev-parse", "--short", "HEAD")
    base = mutation_base(spec, folder.parent / "ledger.json", base.strip())
    suites = impact_suites(test_impact(goal)) if goal["kind"] == "change" else []
    cmds = checks(spec, goal, base, spec["version"], suites) if goal["kind"] != "handoff" else []
    if dry:   # the console only: no brief files, no board
        print(f"\nStep {ids}: {len(plan)} agent(s) in parallel: {', '.join(g.NAMES[a] for a in plan)}")
        for agent, prompt in plan.items():
            print(f"\n----- brief for {g.NAMES[agent]} ({agent}) -----\n{prompt}")
        print("\n----- checks -----\n" + "\n".join(" ".join(c[1]) + (f"   env {c[2]}" if c[2] else "") for c in cmds))
        return "dry-run"
    say(board, f"\n### Step: {ids} ({now()})\n\n")
    keep_briefs(folder, board, plan, goal["id"])
    before, code_before = tree_state(), tree_state(CODE_PATHS)
    start_files = file_states()   # style rows are kept only for files this step changes
    start_snap = change_snapshot()   # L42: the tests a round runs follow what the step changed since here
    needs_red = [b["id"] for b in batch if b["kind"] == "test" and FAIL_FIRST.search(b["text"])]
    seen_red = set()
    lines = [b for b in batch if b["kind"] == "test" and not re.search(r"\bmutations?\b", b["text"], re.I)]
    written = goal["kind"] == "test" and lines and all(marked_tests(b["id"], spec["version"]) for b in lines)
    if written:   # Quinn's tests exist (marked `# goal <ID>`): go straight to the checks; a red test goes to the code
        say(board, "- Quinn's step skipped: every line already has its marked test ("   # owners (0.1.4 T14.4/T14.5:
                   + ", ".join(f"{b['id']}: {', '.join(marked_tests(b['id'], spec['version']))}" for b in lines) + ")\n")   # ~800k saved)
    elif not call_agents(plan, board, usage, run, ids, max_turns=BUILD_MAX_TURNS):
        return "paused"
    rounds = MAX_FIX_ROUNDS + (1 if needs_red else 0)   # one round may go to Quinn alone, to reproduce the bug
    scope_rows = []   # files the last fix round changed outside its owners' folders
    prev_failed = set()   # L40: the tests the last check showed failing; the next round runs them with its own
    replies, last_fix = {}, []   # L42: the last fix round's replies and agents, for routing the next round
    for rnd in range(rounds + 1):
        failed = [("scope", scope_rows.pop())] if scope_rows else []
        g.set_live_tag(f"goal {run} · {ids} checks" + (f" r{rnd}" if rnd else ""))
        own = own_tests(spec, goal, batch) if cmds else []
        impact = change_impact(step_changes(start_snap)) if cmds else change_impact({})
        wrote = impact["written"]   # tests this step wrote or changed: a failure in one goes to Quinn first
        focus = sorted(set(own) | set(impact["tests"]) | prev_failed)
        if any(l == "tests" for l, _, _ in cmds):
            say(board, tests_line(own, impact, prev_failed, focus))
        red_now = {}
        for label, cmd, env in cmds:
            if label == "tests":   # L42: no full unit run per step; the run's end runs every suite once
                at = cmd.index("--time-scale")
                cmd = cmd[:at] + [s for s in impact["suites"] if s not in cmd] + cmd[at:]
                if focus:
                    cmd += ["--only", ",".join(focus)]
                else:
                    cmd.remove("unit")
            if label == "tests":
                code, out, stuck = run_tests_once_more(cmd, board, label, env)
                if stuck:
                    return "paused"
            else:
                code, out = run_cmd(cmd, env=env)
            if code and label == "mutations" and "no mutations to run" in out:   # 0.3 T1.1: committed earlier, so
                names = item_mutations(spec, batch)                               # --since finds none: run the items'
                if names:
                    say(board, f"- `mutate.py --since {base}` found none (committed earlier): running the "
                               f"{len(names)} mutations of this goal's items\n")
                    code, out = run_cmd([sys.executable, "-I", "_tools/mutate.py", *names], env=env)
            if code and label == "mutations":   # only stale `find` strings left: warn, the code moved, not the tests
                rows = re.findall(r"^(?:CAUGHT|MISSED|BROKEN)\s.*$", out, re.M)
                stale = [r for r in rows if STALE_FIND.search(r)]
                if stale and all(r.startswith("CAUGHT") or r in stale for r in rows):
                    say(board, f"- Check `mutations`: PASS with a warning ({len(stale)} stale `find` strings in "
                               f"`game/tests/mutations.json`; refresh them at the next Quinn step)\n\n```\n"
                               + "\n".join(stale) + "\n```\n")
                    continue
                if "no mutations to run" in out and own and set(own) <= mutated_tests():
                    # L50: a re-run step whose tests' mutations were committed earlier finds nothing "new since base"
                    say(board, "- Check `mutations`: PASS (no new mutations since the step's base; every own test is "
                               "already named by a mutation in `game/tests/mutations.json`)\n")
                    continue
            if label == "tests":
                red_now = red_tests(partial=True) if needs_red else {}   # this check's log, before any rerun
                if code:
                    names = [t for t in failing_tests(out)[0] if t not in rerun_flaky(out, set(own) | wrote, board)]
                    prev_failed = set(names)
                    if failing_tests(out)[1] and not names:
                        code = 0   # every failure was flaky
            if code and label == "style":
                now_files = file_states()
                text = style_report(out, {p for p, h in now_files.items() if start_files.get(p) != h})
                if not text:   # every open row is older than this step: not this goal's to fix
                    say(board, "- Check `style`: PASS (open rows only on files this step did not change)\n")
                    continue
            say(board, f"- Check `{label}`: {'PASS' if code == 0 else f'FAIL (exit {code})'}\n")
            if code:
                text = text if label == "style" else summary_of(out)
                failed.append((label, text))
                say(board, "\n```\n" + text + "\n```\n")
                if label in ("contract", "tests"):
                    break
        if needs_red and not any(l == "contract" for l, _ in failed):   # the tests ran: who has shown the bug
            red = dict(red_now)
            # a marked real-time test is skipped by the x6 run (CB_SKIP_X1): run it alone at x1, or it can never
            # fail nor pass (0.1.4 T14.5: three Quinn rounds on a test that never ran)
            x1 = sorted({t for gid in needs_red for t in marked_tests(gid, spec["version"])} & scan(ROOT / "game")["x1"])
            if x1:
                code, out = run_cmd([sys.executable, "-I", "_tools/godot_run.py", "unit", "start"],
                                    env={"CB_ONLY": ",".join(x1), "CB_TIME_SCALE": "1"})
                say(board, f"- Check `x1 tests` ({', '.join(x1)}): {'PASS' if code == 0 else f'FAIL (exit {code})'}\n")
                red.update({t: r for t, r in red_tests(partial=True).items() if t in x1})
                if code:
                    failed.append(("tests", summary_of(out)))
                    say(board, "\n```\n" + summary_of(out) + "\n```\n")
            seen_red |= {gid for gid in needs_red if any(red.get(t) for t in marked_tests(gid, spec["version"]))}
            missing = [gid for gid in needs_red if gid not in seen_red]
            if missing:
                rows = []
                for gid in missing:
                    names = marked_tests(gid, spec["version"])
                    rows.append(f"- {gid}: " + (f"its tests ({', '.join(f'`{t}`' for t in names)}) did not fail on a "
                                                f"real check" if names else f"no test is marked `# goal {gid}`")
                                + (" on the current build" if rnd == 0 else "") + ", but the designer sees this bug "
                                "in play, so the test does not reproduce it. Rewrite it to fail on the check that "
                                "shows the bug; change no file outside tests/.")
                failed.append(("fail-first", "\n".join(rows)))
                say(board, f"- Check `fail-first`: FAIL ({', '.join(missing)} not shown failing)\n")
            else:
                say(board, f"- Check `fail-first`: PASS ({', '.join(needs_red)} shown failing)\n")
        if not any(l in ("contract", "tests", "fail-first") for l, _ in failed):
            for live, pick in goal.get("picks", []):   # look before done: the live prop beside the designer's pick
                rows = match_pick(spec, goal, live, pick, folder, rnd, board, usage, run, ids)
                if rows is None:
                    return "paused"
                if rows:
                    failed.append(("pick match", rows))
        if not failed:
            break
        if rnd == rounds:
            g.waiting(board, f"{rounds} fix rounds failed on {ids}: " + ", ".join(f"`{l}`" for l, _ in failed)
                      + " still fail (output above). The designer decides: change the spec or the test, or fix it "
                      f"by hand and record it with `goal_agent.py {spec['file']} --accept {goal['id']} --note "
                      f"\"<the change>\"`. Then rerun the same command to go on. The fix rounds' edits are not "
                      f"committed: keep them with `python -I _tools/checkpoint.py \"{ids} fix-round edits\"`.")
            return "waiting-designer"
        quinn = quinn_round(goal, failed, prev_failed, wrote, replies, last_fix)
        fix = fix_briefs(spec, goal, batch, failed, run, branch, rnd + 1, quinn=quinn, replies=replies,
                         answers=earlier_answers(board))
        say(board, f"\n#### Fix round {rnd + 1}: to {', '.join(g.NAMES[a] for a in fix)}"
                   + (f" ({quinn})" if quinn else "") + "\n\n")
        keep_briefs(folder, board, fix, f"{goal['id']}-fix{rnd + 1}")
        states, looks_before, replies, last_fix = file_states(), visual_lines(), {}, list(fix)
        if not call_agents(fix, board, usage, run, f"{ids} fix {rnd + 1}", max_turns=FIX_MAX_TURNS, replies=replies):
            return "paused"
        stray = out_of_scope(states, file_states(), fix)
        say(board, f"- Check `scope`: " + (f"FAIL ({', '.join(f'`{p}`' for p in stray)} changed outside "
                                           f"{', '.join(FOLDERS[a] for a in fix)})\n" if stray else "PASS\n"))
        rows = [(g.NAMES[a], l.strip().lstrip("-* ")) for a, r in replies.items() if a != QA or quinn
                for l in r.splitlines() if DESIGNER_ROW.search(l) and QUESTION.search(l)]
        votes = [(who, row) for who, row in rows if VISUAL_ROW.search(row)]   # L42: only a visual value is a vote
        asks = [(who, row) for who, row in rows if not VISUAL_ROW.search(row)]
        votes += [("changed", row) for row in visual_changes(looks_before, visual_lines(), spec_slice(spec, goal))]
        table = lambda rs, col: (f"\n\n| # | Who | {col} |\n|---|---|---|\n" + "\n".join(
            f"| {i} | {who} | {row.replace('|', '/')} |" for i, (who, row) in enumerate(rs, 1)))
        if votes and spec.get("placeholders"):   # kept, listed for the play-test; the next check decides the step
            keep_placeholders(folder, ids, votes)
            say(board, f"- Check `visual numbers`: PLACEHOLDER ({len(votes)} kept for the play-test, listed in "
                       f"`placeholders.md`)" + table(votes, "Row") + "\n")
            votes = []
        say(board, "- Check `visual numbers`: " + (f"STOP ({len(votes)} for the designer)\n" if votes else "PASS\n"))
        if asks:
            say(board, f"- Check `designer questions`: STOP ({len(asks)})\n")
        if votes:   # item 12: the way style_loop.py stops on its (designer) rows
            g.waiting(board, f"Fix round {rnd + 1} on {ids} needs a visual number the designer has not voted on "
                      f"(sizes, scales, offsets, fonts and margins are the designer's). Each row becomes a question with "
                      f"votes on the Design Votes page (`_tools/compare_page.py add`); its link goes here. A `changed` "
                      f"row is already in the tree, uncommitted: undo it if the vote keeps the old value. Then rerun "
                      f"`goal_agent.py {spec['file']} --note \"<the pick>\"`." + table(votes, "Row")
                      + (f"\n\nAlso a question on behaviour (not a vote): answer it in the spec item."
                         + table(asks, "Question") if asks else "") + "\n\nComparison pages:\n")
            return "waiting-designer"
        if asks:   # L42: a behaviour question (T9.1: keep or reset the paused crank) is not a Design Votes row
            g.waiting(board, f"Fix round {rnd + 1} on {ids} raised a question the spec does not answer, about how the "
                      f"game behaves (no visual number, so no Design Votes row). Answer it in the spec item, then rerun "
                      f"`goal_agent.py {spec['file']} --note \"<the answer>\"`. The fix rounds' edits are not committed: "
                      f"keep them with `python -I _tools/checkpoint.py \"{ids} fix-round edits\"`."
                      + table(asks, "Question"))
            return "waiting-designer"
        if stray:
            scope_rows.append(f"Fix round {rnd + 1} ({', '.join(g.NAMES[a] for a in fix)}) changed these files outside "
                              f"its folder: " + ", ".join(f"`{p}`" for p in stray) + ". If one is in your folder, "
                              "keep the change only if the spec text asks for it, else undo it, and say which.")
    if goal["kind"] == "handoff" and not [h for h in scan_handoffs() if h.startswith(spec["version"])]:
        say(board, "\n**Stop:** Patricia's reply came back without the handoff file.\n")
        return "failed"
    if goal["kind"] != "handoff" and tree_state() == before:   # green only because nothing moved: not built
        question = (f"The agents changed no file for {ids} and the checks were already green, so it is not built. "
                    f"Their replies on the board (step {ids}, {now()}) say why; answer by editing the spec item.")
        hold(spec, goal, run, folder.parent / "ledger.json", question)
        say(board, f"- **Held:** no file changed in {', '.join(BUILD_PATHS)}; not committed. {question}\n")
        return "held"
    if needs_red and tree_state(CODE_PATHS) == code_before:   # B: a bug is fixed only by a script or scene change
        question = (f"{', '.join(needs_red)} report a bug the designer saw, but only tests changed: no file in "
                    f"{', '.join(CODE_PATHS)} moved, so the bug is not fixed. Check the test against the game, "
                    f"then answer by editing the spec item, or `--accept` with a note if it really was fixed earlier.")
        for b in batch:
            hold(spec, b, run, folder.parent / "ledger.json", question)
        say(board, f"- **Held:** {question}\n")
        return "held"
    msg = checkpoint(spec, batch, run, folder, folder.parent / "ledger.json")
    say(board, f"- Green: {msg}\n")
    return "green"


def final_suite(spec, run, folder, board, usage):
    """L39 (c): when a run has built every goal, run every suite (`all --time-scale 6 --skip-x1`), since a step checks
    `unit` and only the windowed suites its impact list names. Red: one round to Quinn for the stale tests, then the
    check again; still red, the run waits for the designer. Returns done, paused or waiting-designer."""
    cmd = [sys.executable, "-I", "_tools/godot_run.py", *FULL_SUITE]
    say(board, f"\n### Full suite ({now()})\n\n")
    reused = fresh_green_full()   # L42: the run's one full run, unless a green one is newer than every build change
    if reused:
        say(board, f"- Check `full suite`: PASS (reused `{reused.parent.relative_to(ROOT).as_posix()}`: every suite "
                   f"green, and no build file changed since it began)\n")
        return "done"
    for rnd in range(2):
        g.set_live_tag(f"goal {run} · full suite" + (f" r{rnd}" if rnd else ""))
        code, out, stuck = run_tests_once_more(cmd, board, "full suite")
        if stuck:
            return "paused"
        say(board, f"- Check `full suite`: {'PASS' if code == 0 else f'FAIL (exit {code})'}\n")
        if code == 0:
            if rnd:   # Quinn's test fixes made it green: keep them
                git("add", "--", "game/tests")
                c, o = git("commit", "-m", f"{spec['version']} full suite: stale tests updated (goal_agent run {run})"
                           f"\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>")
                say(board, "- Green: " + ("tests committed" if c == 0 else "commit failed: " + summary_of(o, 6)) + "\n")
            return "done"
        text = summary_of(out, 20)
        say(board, "\n```\n" + text + "\n```\n")
        if rnd:
            g.waiting(board, f"Every goal of `{spec['file']}` is built, but the full suite is red after Quinn's round "
                      f"(output above). The designer decides which failures are game bugs (they go to Patricia or "
                      f"Bob) and which tests are stale. Quinn's edits are not committed: keep them with "
                      f"`python -I _tools/checkpoint.py \"full suite fix-round edits\"`.")
            return "waiting-designer"
        plan = {QA: (
            f"Goal agent run `{run}` has built every goal of `game/specs/{spec['file']}`, but the full suite "
            f"(`godot_run.py {' '.join(FULL_SUITE)}`) is red. Your folder: {FOLDERS[QA]}. For each failing test, read "
            f"the spec item it covers: if its expectation is one the spec's changes replaced (a stale test), update it "
            f"and quote the spec line in a comment beside it; if the game breaks the spec, change nothing and list it "
            f"as a finding (test, spec line, likely file). Do not commit. Do not run the suites: the goal agent runs "
            f"them after you. You have {FIX_MAX_TURNS} turns.{TEST_RULES}\n\n{text}\n\nReply in at most 150 words.")}
        keep_briefs(folder, board, plan, "suite-fix1")
        if not call_agents(plan, board, usage, run, "full suite fix 1", max_turns=FIX_MAX_TURNS):
            return "paused"
    return "waiting-designer"


def style_report(out, changed=None):
    """The Result of the style board a failed `style` check names (its open rows), else the output's tail.
    With `changed` (paths this step changed), only rows about those files are kept: the board checks the whole game,
    and in 0.2 C3 Bob followed an older V4 row on honey_cell.tscn and broke two frame tests. "" when no row is left."""
    m = re.search(r"game/reports/style/[\w.-]+/run-\d+/blackboard\.md", out)
    board = ROOT / m.group(0) if m else None
    if board and board.is_file():
        result = board.read_text(encoding="utf-8").split("\n## Result", 1)
        if len(result) == 2:
            body = result[1].rstrip()
            if changed is not None:
                body, dropped = rows_in_scope(body, changed)
                if body is None:
                    return ""
                if dropped:
                    body += (f"\n\n({dropped} older row(s) about files this step did not change were left out: "
                             f"not yours this round, change nothing for them.)")
            return f"Style board `{m.group(0)}`, Result:{body}"
    return summary_of(out)


def rows_in_scope(body, changed):
    """(body with only the style rows this step's files caused, number dropped); (None, n) when no row is left.
    A row naming a .tscn/.tres/.gd is kept if that file changed; a shot row if it names a changed scene's word
    (e.g. `fork` for uncapping_fork.tscn)."""
    words = {w for p in changed if p.endswith((".tscn", ".tres")) for w in re.split(r"[_\-]", Path(p).stem) if len(w) >= 4}
    kept, out, dropped = 0, [], 0
    for line in body.splitlines():
        cells = [c.strip() for c in line.split("|")]
        data = line.startswith("|") and len(cells) > 4 and not set(line) <= set("|-: ") and cells[1] != "#"
        if data:
            refs = re.findall(r"[\w/.\-]+\.(?:tscn|tres|gd)", cells[3])
            mine = (any(p.endswith(r) for r in refs for p in changed) if refs
                    else any(re.search(rf"\b{re.escape(w)}", line, re.I) for w in words))
            if not mine:
                dropped += 1
                continue
            kept += 1
        out.append(line)
    return ("\n".join(out) if kept else None), dropped


def match_pick(spec, goal, live, pick, folder, rnd, board, usage, run, ids):
    """Render the live prop beside the pick and ask Vera whether they match. "" on PASS, the rows on FAIL,
    None when the budget guard pauses the run."""
    out = folder / "pick" / goal["id"] / f"round-{rnd}"
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
        try:
            reply, u = agent_once_more(CRITIC, prompt if not attempt else prompt + " Your last reply had no such block with a VERDICT line.", board)
        except Transient as e:
            say(board, f"\n**Paused:** {e} (a network or API error, twice). Run the same command again to resume.\n")
            return None
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


def quinn_round(goal, failed, failing, wrote, replies, last_fix):
    """L42: why the next fix round goes to Quinn alone, or "". Only when every failing check is `tests`: a code owner's
    last reply puts the fault in tests/ (QUINN_FAULT), or, on a test goal, every failing test is one this step wrote
    (not twice running: after Quinn's own round the code owners get the next)."""
    if not failed or {l for l, _ in failed} != {"tests"}:
        return ""
    blame = [g.NAMES[a] for a, r in replies.items() if a != QA and QUINN_FAULT.search(r)]
    if blame:
        return f"{' and '.join(blame)} put the fault in tests/"
    if goal["kind"] == "test" and failing and set(failing) <= set(wrote) and last_fix != [QA]:
        return "the failing tests are ones this step wrote"
    return ""


def visual_rule(spec):
    """The visual-number paragraph of a code owner's fix brief: minimums and the canvas always, then placeholder or vote."""
    return STYLE_MINIMUMS + LAYOUT_RULE + (PLACEHOLDER_RULE if spec.get("placeholders") else VISUAL_RULE)


def earlier_answers(board, n=5):
    """The designer's last n answers on this run's board (0.3 C6 asked what C3 had just been told)."""
    path = Path(board) if board is not None else None
    found = re.findall(r"^Designer's answer: (.+)$", path.read_text(encoding="utf-8"), re.M) if path and path.is_file() else []
    return ("The designer's earlier answers in this run still hold; do not ask them again:\n"
            + "\n".join(f"- {a}" for a in found[-n:]) + "\n\n") if found else ""


def mutation_base(spec, ledger_path, head):
    """The newest goal checkpoint of this spec that HEAD contains, for `mutate.py --since`: a mid-step
    `checkpoint.py` commit (0.3 T2.1, ff4abe5) must not hide the step's own mutations. HEAD when there is none."""
    ledger = json.loads(ledger_path.read_text(encoding="utf-8")) if ledger_path.is_file() else {}
    entries = sorted(ledger.get(spec["file"], {}).values(), key=lambda e: e.get("at", ""), reverse=True)
    for sha in [e["commit"] for e in entries if e.get("commit")]:
        if git("merge-base", "--is-ancestor", sha, "HEAD")[0] == 0:
            return sha
    return head


def item_mutations(spec, batch, path=None):
    """The mutation names of the batch's items (`<version> item <n> ...` in game/tests/mutations.json)."""
    path = path or ROOT / "game" / "tests" / "mutations.json"
    items = {n for b in batch for n in b["items"]}
    rows = json.loads(path.read_text(encoding="utf-8")) if path.is_file() else []
    return [m["name"] for m in rows
            if any(m["name"].startswith(f"{spec['version']} item {n} ") for n in items)]


def fix_briefs(spec, goal, batch, failed, run, branch, rnd, quinn="", replies=None, answers=""):
    """Failures go to the owners of the folders involved (Process 9): code owners for test failures; Quinn alone when
    quinn_round() names a reason (`quinn`), with the code owners' replies that blamed the test."""
    report = "\n\n".join(f"{label}:\n{text}" for label, text in failed)
    owners = [OWNERS[o] for o in goal["owners"]] if goal["kind"] != "test" else \
        sorted({OWNERS[o] for n in goal["items"] for o in spec["goals"].get(f"C{n}", {}).get("owners", [])}
               - {QA}) or [PROGRAMMER]
    if any(l == "contract" for l, _ in failed) and BUILDER not in owners and goal["kind"] == "change":
        owners.append(BUILDER)
    if [l for l, _ in failed] == ["mutations"]:   # a missed mutation means a test proves too little: Quinn's folder
        owners = [QA]
    if any(l == "fail-first" for l, _ in failed):   # nothing to fix until a test shows the bug: Quinn alone this round
        owners = [QA]
    if failed and all(l in LOOKS for l, _ in failed):   # how the scene looks: Bob's folder
        owners = [BUILDER]
    if PROGRAMMER in owners and BUILDER in owners:   # one owner per round: the 0.1.4 T14 rounds sent the same report
        owners = [one_owner(report, rnd)]            # to both, and both removed the same 30° cell turn
    other = {PROGRAMMER: "Bob (scenes/)", BUILDER: "Patricia (scripts/)"}
    head = (f"Goal agent run `{run}`, fix round {rnd} for goal {', '.join(b['id'] for b in batch)} of "
            f"`game/specs/{spec['file']}`, branch `{branch}`. These checks failed after the last step. Fix what is in "
            f"your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. "
            f"Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have "
            f"{FIX_MAX_TURNS} turns.\n\n")
    looks = ("A `pick match` row means the live prop must match the designer's picked variant: open both shots and "
             "the variant's .tscn, and rebuild what differs. A style row whose Fix ends `(designer)` is not yours: "
             "leave it and list it in your reply.\n\n") if any(l in LOOKS for l, _ in failed) else ""
    first = ("A `fail-first` row: rewrite only that line's test, keep its `# goal <ID>` mark, and change no script or "
             "scene; any other failing test is a finding for the code owners in the next round, so leave it.\n\n"
             ) if any(l == "fail-first" for l, _ in failed) else ""
    alone = {a: (f"You alone work this round. If the cause is in {other[a]}'s folder, change nothing and say which "
                 f"file and line: the next round goes to them. ") if a in other else "" for a in owners}
    keep = ("Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid "
            "fix asked to change the end also moved the open pose). ")
    out = {a: head + f"Your folder: {FOLDERS[a]}\n\n{alone[a]}{keep}{DIAG_RULE['qa' if a == QA else 'code']}{visual_rule(spec) if a != QA else ''}{looks if a == BUILDER else ''}{first if a == QA else ''}{answers}{report}\n\nSpec text:\n"
                     f"{spec_slice(spec, goal)}\n\nReply in at most 150 words." for a in owners}
    if goal["kind"] == "change" and any(l == "tests" for l, _ in failed):
        # an older test may pin what this change was asked to change (e.g. the removed Hive bar): Quinn's folder
        out[QA] = head + (f"Your folder: {FOLDERS[QA]}. Update only a test whose expectation this change of the "
                          f"spec replaces, and quote the spec line in a comment beside it. Any other failure is a "
                          f"finding against the code: leave the test and say which. {DIAG_RULE['qa']}Do not run the tests: the goal agent "
                          f"runs them after you.{TEST_RULES}\n\n{report}\n\nSpec text:\n{spec_slice(spec, goal)}\n\nReply in at most 150 words.")
    if quinn:   # L42: T9.1's failing test was Quinn's new one, and Patricia said so in both rounds
        said = "\n\n".join(f"{g.NAMES[a]} (last round):\n{r.strip()[:1500]}" for a, r in (replies or {}).items()
                           if a != QA and r.strip())
        out = {QA: head + (f"Your folder: {FOLDERS[QA]}. You alone work this round: {quinn}. Check each failing test "
                           f"against the spec text: if it expects what the spec does not say (a wrong expectation, or "
                           f"state left over from an earlier run in the same scene), fix the test and quote the spec "
                           f"line beside it; if the game breaks the spec, change nothing and say which file and line: "
                           f"the next round goes to the code owners. Where the spec does not say what the game should "
                           f"do, change nothing for it and write one line ending `(designer)`: the question, with "
                           f"options A: and B:. {DIAG_RULE['qa']}Do not run the tests: the goal agent runs them after you.{TEST_RULES}"
                           f"\n\n{report}" + (f"\n\n{said}" if said else "") + f"\n\nSpec text:\n"
                           f"{spec_slice(spec, goal)}\n\nReply in at most 150 words.")}
    return out


def one_owner(report, rnd):
    """Patricia or Bob for a fix round both could take: the folder the failure names, else Patricia on odd rounds and
    Bob on even ones, so a cause in the other folder reaches its owner next round."""
    scenes = len(re.findall(r"\.tscn\b|\.tres\b|scenes/|materials/", report))
    scripts = len(re.findall(r"\.gd\b|scripts/", report))
    if scenes != scripts:
        return BUILDER if scenes > scripts else PROGRAMMER
    return PROGRAMMER if rnd % 2 else BUILDER


SCOPE = {PROGRAMMER: ("game/scripts/",), BUILDER: ("game/scenes/", "game/materials/"), QA: ("game/tests/",)}


def file_states():
    """{path: content hash} of every uncommitted file under game/ outside reports/ (the goal agent writes those)."""
    out = {}
    for row in git("status", "--porcelain", "-uall", "--", "game")[1].splitlines():
        path = row[3:].strip().strip('"').split(" -> ")[-1]
        if path.startswith("game/reports/") or path.endswith((".uid", ".import")):   # Godot writes these itself
            continue
        f = ROOT / path
        out[path] = hashlib.sha1(f.read_bytes()).hexdigest() if f.is_file() else "deleted"
    return out


def out_of_scope(before, after, agents):
    """Files a fix round changed outside the folders of the agents it went to."""
    allowed = tuple(p for a in agents for p in SCOPE.get(a, ()))
    changed = {p for p in set(before) | set(after) if before.get(p) != after.get(p)}
    return sorted(p for p in changed if not p.startswith(allowed))


def transcripts(run):
    """Where this run's agent transcripts are kept today (gitignored)."""
    return ROOT / g.RUNS / f"{datetime.date.today().isoformat()}-goal-{run}"


def call_line(u, max_turns):
    """The board's record of one call: the exact command, the model calls counted in its transcript against the cap,
    and its end. The cap counts model calls; the CLI's num_turns is another count (Bob's 0.1.4 T14.4 fix 1 at 16:46:
    num_turns 20, 10 model calls, cap 15 never reached; the call that did reach it made 15 and ended
    `error_max_turns`), so only the transcript count is checked against the cap."""
    calls = u.get("calls")
    over = max_turns and calls is not None and calls > max_turns
    cap = f"cap {max_turns}" if max_turns else "no cap"
    return (f"- Call: `{u.get('cmd', '?')}`; model calls {calls if calls is not None else '?'} ({cap}; CLI num_turns "
            f"{u.get('turns', '?')}); end `{u.get('subtype') or '?'}`"
            + (f"\n- **Over the turn cap:** {calls} model calls with --max-turns {max_turns}; the cap did not apply. "
               f"Transcript: `{u.get('transcript', '?')}`.\n" if over else "\n"))


def call_agents(plan, board, usage, run, label, max_turns=None, replies=None):
    """Run the briefs in parallel after the budget check; False when the budget guard or a twice-failed network call
    (Transient) pauses the run. `replies`, if given, gets {agent: reply}."""
    for agent in plan:
        ok, msg = budget_ok(agent)
        if not ok:
            say(board, f"\n**Paused:** {msg}\nRun the same command again to resume.\n")
            return False
        say(board, f"- Budget guard for {g.NAMES[agent]}: {msg}\n")
    rundir = transcripts(run)
    g.set_live_tag(f"goal {run} · {label}")
    paused = False
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(plan)) as pool:
        cap = {"max_turns": max_turns} if max_turns else {}
        futures = {pool.submit(agent_once_more, a, p, board, **cap): a for a, p in plan.items()}
        for fut in concurrent.futures.as_completed(futures):
            agent = futures[fut]
            try:
                reply, u = fut.result()
            except Transient as e:   # the others still finish and are logged; the run pauses, resumable
                say(board, f"\n**Paused:** {e} (a network or API error, twice). Run the same command again to resume.\n")
                paused = True
                continue
            except g.AgentError as e:
                say(board, f"\n**{g.NAMES[agent]} failed:** {e}\n")
                raise
            try:
                g.keep_transcript(u, rundir, f"{label.replace(' ', '-').replace(',', '')}-{g.NAMES[agent].lower()}")
            except Exception:
                pass
            usage.append((agent, label, u))
            if replies is not None:
                replies[agent] = reply
            say(board, f"\n**{g.NAMES[agent]}** ({u['tokens']:,} tokens, {u['turns']} turns, {u['seconds']} s):\n\n"
                            f"{reply.strip()}\n\n{call_line(u, max_turns)}\n")
    return not paused


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
    ap.add_argument("--goal", help="build only these goals, in order (a comma list, e.g. T10.1,T12.1); one the scan "
                    "counts done is skipped with one line (exit 0), one not ready stops the run")
    ap.add_argument("--run", help="run folder name under game/reports/goal/ (default: the spec's version)")
    ap.add_argument("--accept", metavar="GOAL", help="after a stop: record GOAL as green with a manual fix (Process 9), "
                    "checkpoint it, and exit; run the checks first")
    ap.add_argument("--note", default="", help="with --accept: the manual change, for the blackboard and GOAL_AGENT.md; "
                    "otherwise: the designer's answer the run resumes on (written under Resumed)")
    ap.add_argument("--impact", metavar="GOAL", help="print the existing tests that read what GOAL touches (L39) and "
                    "the windowed suites its step would add, then exit; any goal, built or not")
    ap.add_argument("--changed", action="store_true", help="print the tests a round would run for every uncommitted "
                    "build file (L42's change impact, against HEAD), then exit")
    a = ap.parse_args(argv)
    if a.changed:
        imp = change_impact(step_changes({}))
        print(tests_line([], imp, set(), sorted(imp["tests"])), end="")
        print(f"{len(imp['tests'])} unit tests; written: {', '.join(sorted(imp['written'])) or 'none'}")
        return 0
    path = Path(a.spec)
    if not path.is_file():
        path = ROOT / "game" / "specs" / a.spec
    spec = parse_spec(path)
    if a.impact:
        if a.impact not in spec["goals"]:
            print(f"goal_agent: {a.impact} is not a goal of {spec['file']}")
            return 2
        rows = test_impact(spec["goals"][a.impact])
        print(impact_text(rows) or "no existing test reads what it touches")
        print(f"{len(rows)} functions; suites added to its step: {', '.join(impact_suites(rows)) or 'none'}")
        return 0
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
        commit_state(spec, run, folder, folder.parent / "ledger.json", f"{goal['id']} accepted")
        print(f"goal_agent: {goal['id']} accepted: {msg}")
        return 0
    usage, built, result = [], 0, "done"
    wanted = [x.strip() for x in a.goal.split(",") if x.strip()] if a.goal else None   # obstacles item 8
    if wanted and [x for x in wanted if x not in spec["goals"]]:
        print(f"goal_agent: not a goal of {spec['file']}: {', '.join(x for x in wanted if x not in spec['goals'])}")
        return 2
    branch = "main"
    if not (a.plan or a.dry_run):
        branch, note = ensure_branch(spec["version"])
        say(board, f"Branch `{branch}`: {note}.\n")
    lock = ROOT / LOCK if not (a.plan or a.dry_run) else None
    if lock:   # guard_shell refuses the main session's edits in the build folders while this exists (rule C)
        lock.parent.mkdir(parents=True, exist_ok=True)
        lock.write_text(json.dumps({"spec": spec["file"], "run": run, "pid": os.getpid(), "start": now()}),
                        encoding="utf-8")
    try:
        while True:
            report, ranked, ambiguous = plan_pass(spec, ROOT / "game", folder, board, costs, n)
            n += 1
            print_plan(spec, report, ranked, ambiguous, folder)
            if a.plan:
                return 0
            ready = [e for e in ranked if e["factors"]["ready"]]
            if wanted is not None:   # item 8: only the listed goals, in order; a done one is a clean skip, not exit 1
                while wanted and report[wanted[0]]["status"] == "done":
                    print(f"goal_agent: {wanted[0]} is already done; skipped")
                    if board is not None:
                        say(board, f"\n- `--goal`: {wanted.pop(0)} is already done; skipped.\n")
                    else:
                        wanted.pop(0)
                if not wanted:
                    result = f"stopped after {built} goal(s) (--goal list done)"
                    if board is not None:
                        say(board, f"\n**Stop:** {result}.\n")
                    break
                ready = [e for e in ready if e["id"] == wanted[0]]
                if not ready:
                    print(f"goal_agent: {wanted[0]} is not a ready, unbuilt goal")
                    result = f"stopped ({wanted[0]} is not ready)"
                    return 2
            if ambiguous and not ready:   # the other goals were built first; now only the designer can unblock the rest
                result = "waiting-designer"
                if board is not None:
                    g.waiting(board, "Every goal left waits on an open question (Process 1):\n\n" + "\n".join(
                        f"- {x}: {spec['goals'][x]['title']}" + "".join(f"\n  - {q}" for q in report[x]["questions"])
                        for x in ambiguous) + "\n\nAnswer each in the spec, or mark it \"(answered: ...)\" in the "
                        f"handoff, then rerun `goal_agent.py {spec['file']} --note \"<the answer>\"`.")
                break
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
            if wanted and outcome in ("green", "held"):
                wanted = [x for x in wanted if x not in {b["id"] for b in batch}]
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
        # L39 (c), L42: a step runs only its own and impacted tests; the run's end runs every suite once, also after a
        # --goal list or --max-goals stop that built something
        if board is not None and (result == "done" or (built and result.startswith("stopped after"))):
            end = final_suite(spec, run, folder, board, usage)
            result = result if end == "done" else end
    except Exception as e:   # an agent or check crashed: never record it as done (generate.py marks `result: failed`)
        result = f"failed ({type(e).__name__}: {e})"
        say(board, f"\n**Stop:** the run crashed: {result}. A rerun re-scans and continues from the ledger.\n")
        raise
    finally:
        if lock:
            lock.unlink(missing_ok=True)
        if board is not None:   # one Result, rewritten in place, with every call of the run so far
            word = result.split(" ")[0] if not result.startswith("stopped after") else "stopped"
            g.finish_board(board, [(f"{g.NAMES[agent]}, {label}", u) for agent, label, u in usage], word,
                           f"Last invocation ({now()}): {result}.", transcripts(run))
        if usage:
            log_usage(usage, run)
        if board is not None:
            print("goal_agent: " + commit_state(spec, run, folder, folder.parent / "ledger.json", result))
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
