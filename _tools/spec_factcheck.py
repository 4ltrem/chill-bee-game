#!/usr/bin/env python3
"""Fact-check a game spec's claims about how the game behaves today, before agents build from it (L52).

    python -I _tools/spec_factcheck.py game/specs/<spec>.md             # claims -> Doris -> factcheck.md
    python -I _tools/spec_factcheck.py game/specs/<spec>.md --no-agent  # print the claims only, no agent call

A spec's `## Changes` (and contract lines) state existing behaviour as fact: "Farm view only, like the rest of the
info row", "as in 0.2", "stays", "unchanged". 0.3.0 item 2 said the top info row was farm-view only; `farm_ui.gd`
`fit_top_info` keeps `TopInfo` at the second stop, and nobody checked. This script pulls each such sentence (with its
item), sends only those to one read-only agent call (Doris, `doc-auditor`, who checks statements against code), and
writes `game/reports/goal/<version>/factcheck.md`: one row per claim, TRUE / UNTRUE / UNCLEAR with the file:line read,
or NEW for a sentence that only describes the change.

goal_agent's build run refuses to start unless that file matches the spec's current text (`spec_hash`) and every row
is TRUE or NEW: fix an UNTRUE claim in the spec (then re-run this), and settle an UNCLEAR one by editing the spec or by
changing the row's verdict to TRUE by hand after checking it (the designer's call). Standard library only, plus the
workspace's `generate.run_agent` runner (its live view) and `runlog` (the agent-runs log).
"""
import argparse
import hashlib
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))  # -I leaves the script's folder off sys.path
import spec_lint  # noqa: E402  (item_sentences reads the spec the way goal_agent does)

ROOT = TOOLS.parent
AGENT = "doc-auditor"
# Phrases that state existing behaviour (the L52 list). A sentence with one of them is a claim about today's game.
CLAIM = re.compile(r"\blike the\b|\bas in \d|\bas today\b|\bas before\b|\bunchanged\b|\bstays?\b|\bstill\b|\bonly\b|"
                   r"\bnever\b|\bToday\b|\bkeeps?\b|\balready\b|\bcurrently\b|\bexisting\b", re.I)
VERDICT_ROW = re.compile(r"^\|\s*(\d+)\s*\|\s*(TRUE|UNTRUE|UNCLEAR|NEW)\s*\|([^|]*)\|(.*)\|\s*$", re.M)


def spec_hash(spec_path):
    return hashlib.sha1(Path(spec_path).read_text(encoding="utf-8").encode("utf-8")).hexdigest()[:12]


def version_of(spec_path):
    m = re.match(r"[\d.]+[a-z]?", Path(spec_path).stem)
    return m.group(0) if m else Path(spec_path).stem


def claims(spec_path):
    """[(item, sentence)] for every Changes or contract sentence that states existing behaviour, deduplicated."""
    seen, out = set(), []
    for item, _where, s in spec_lint.item_sentences(spec_path):
        if CLAIM.search(s) and (item, s) not in seen:
            seen.add((item, s))
            out.append((item, s))
    return out


def prompt(spec_path, rows):
    listed = "\n".join(f"{i}. (item {item}) {s}" for i, (item, s) in enumerate(rows, 1))
    return (f"Fact-check these sentences from the game spec `{Path(spec_path).as_posix()}`. Each one states how the "
            f"game behaves today (before this spec is built). Do not judge the spec's new changes: only whether the "
            f"part about the current game is true of the code now in `game/scripts/`, `game/scenes/` and "
            f"`game/config/`. Read the code; quote nothing longer than a line. Reply with only this table, one row "
            f"per sentence, in order, no other text:\n\n| # | Verdict | Evidence | Why |\n|---|---|---|---|\n\n"
            f"Verdict is TRUE or UNTRUE for a claim about the current game; NEW when the sentence only describes "
            f"what this spec adds or changes (nothing about today's game to check); UNCLEAR when the code doesn't "
            f"settle it. Evidence is the `file:line` you read (blank for NEW). Why is one short sentence.\n\n{listed}\n")


def parse_reply(reply, n):
    """{number: (verdict, evidence, why)} for rows 1..n; a missing row is UNCLEAR (the agent said nothing on it)."""
    got = {int(m.group(1)): (m.group(2), m.group(3).strip(), m.group(4).strip()) for m in VERDICT_ROW.finditer(reply)}
    return {i: got.get(i, ("UNCLEAR", "", "no row in the reply")) for i in range(1, n + 1)}


def cell_text(t):
    """A claim as its table cell holds it (no pipes, no newlines)."""
    return str(t).replace("|", "/").replace("\n", " ")


ROW = re.compile(r"^\|\s*\d+\s*\|\s*(TRUE|UNTRUE|UNCLEAR|NEW)\s*\|(.*?)\|(.*?)\|\s*([^|]*?)\s*\|\s*(.*?)\s*\|\s*$", re.M)


def earlier_verdicts(path):
    """L53: {(item, claim cell): (verdict, evidence, why)} from an existing fact-check file. A spec edited mid-build
    (0.3.1 item 7 after C1-C8 were built) keeps the verdict each unchanged sentence had before the build changed the
    code it describes; only new or reworded sentences go to Doris."""
    if not path.is_file():
        return {}
    return {(m.group(4), m.group(5)): (m.group(1), m.group(2).strip(), m.group(3).strip())
            for m in ROW.finditer(path.read_text(encoding="utf-8"))}


def render(spec_path, rows, verdicts, note=""):
    cell = cell_text
    head = (f"---\nspec: {Path(spec_path).name}\nspec_hash: {spec_hash(spec_path)}\nclaims: {len(rows)}\n"
            f"untrue: {sum(v[0] == 'UNTRUE' for v in verdicts.values())}\n"
            f"unclear: {sum(v[0] == 'UNCLEAR' for v in verdicts.values())}\n---\n"
            f"# Fact-check: {Path(spec_path).name}\n\n"
            f"Written by `_tools/spec_factcheck.py` (L52). goal_agent builds only when every row is TRUE or NEW and "
            f"`spec_hash` matches the spec. Fix an UNTRUE claim in the spec and re-run; settle an UNCLEAR one in the "
            f"spec, or set its verdict to TRUE by hand once checked.{note}\n\n"
            f"| # | Verdict | Evidence | Why | Item | Claim |\n|---|---|---|---|---|---|\n")
    return head + "".join(f"| {i} | {v[0]} | {cell(v[1])} | {cell(v[2])} | {item} | {cell(s)} |\n"
                          for i, ((item, s), v) in enumerate(zip(rows, verdicts.values()), 1))


def report_path(spec_path, root=None):
    return (root or ROOT) / "game" / "reports" / "goal" / version_of(spec_path) / "factcheck.md"


def gate(spec_path, root=None):
    """(ok, message) for goal_agent: the fact-check exists for this exact spec text and has only TRUE rows."""
    path = report_path(spec_path, root)
    rel = path.relative_to(root or ROOT).as_posix()
    fix = f"run `python -I _tools/spec_factcheck.py {Path(spec_path).as_posix()}`"
    if not path.is_file():
        return False, f"no fact-check of the spec's claims yet ({rel}); {fix} first (L52)"
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^spec_hash: (\w+)", text, re.M)
    if not m or m.group(1) != spec_hash(spec_path):
        return False, f"{rel} is for an older text of the spec; {fix} again (L52)"
    bad = [(int(r.group(1)), r.group(2)) for r in re.finditer(r"^\|\s*(\d+)\s*\|\s*(UNTRUE|UNCLEAR)\s*\|", text, re.M)]
    if bad:
        return False, (f"{rel} has " + ", ".join(f"#{i} {v}" for i, v in bad) + ": fix an UNTRUE claim in the spec "
                       f"and re-run the fact-check; settle an UNCLEAR one in the spec, or set its verdict to TRUE by "
                       f"hand once checked (the designer's call)")
    return True, f"{rel}: every claim TRUE or NEW"


def ask(spec_path, rows):
    """One agent call (after the budget guard); returns (verdicts, note). Logged to the agent-runs table."""
    import budget_guard
    import generate as g
    import runlog
    if not budget_guard.overridden():
        verdict, msg = budget_guard.decide(budget_guard.latest(), AGENT)
        if verdict == "deny":
            raise SystemExit(f"spec_factcheck: {msg}")
    reply, u = g.run_agent(AGENT, prompt(spec_path, rows), tools="Read,Grep,Glob", max_turns=40)
    start, end = runlog.parse_ts(u.get("start")), runlog.parse_ts(u.get("end"))
    f0, w0 = runlog.usage_at(start, ROOT)
    f1, w1 = runlog.usage_at(end, ROOT, after=True)
    runlog.upsert({"start": u.get("start"), "end": u.get("end"), "table": "Goal agent",
                   "run": f"spec fact-check {Path(spec_path).name}", "agent": f"Doris ({AGENT})",
                   "phase": "post-ICM", "model": u.get("model") or g.model_of(AGENT), "final_context": u.get("final"),
                   "total_processed": u["tokens"], "turns": u["turns"], "duration_s": u["seconds"],
                   "five_hour_before": f0, "five_hour_after": f1, "seven_day_before": w0, "seven_day_after": w1}, ROOT)
    return parse_reply(reply, len(rows)), f" Doris: {u['tokens']:,} tokens, {u['turns']} turns."


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("spec")
    ap.add_argument("--no-agent", action="store_true", help="print the claims only")
    a = ap.parse_args(argv)
    path = Path(a.spec)
    if not path.is_file():
        path = ROOT / "game" / "specs" / a.spec
    rows = claims(path)
    if a.no_agent:
        for i, (item, s) in enumerate(rows, 1):
            print(f"{i:3}. (item {item}) {s}")
        print(f"{len(rows)} claims")
        return 0
    kept = earlier_verdicts(report_path(path))
    new = [r for r in rows if (str(r[0]), cell_text(r[1])) not in kept]
    if rows and not new:
        verdicts, note = {}, " Every claim kept its earlier verdict."
    elif rows:
        got, note = ask(path, new)
        fresh = dict(zip(new, got.values()))
        verdicts = {}
    else:
        verdicts, note = {}, " No claims found: nothing to check."
    if rows:   # L53: a mid-build spec edit re-checks only its new sentences; the rest keep the verdict they had
        verdicts = {i: fresh[r] if r in new else kept[(str(r[0]), cell_text(r[1]))]   # before the build changed
                    for i, r in enumerate(rows, 1)}                                   # the code they describe
        if len(new) < len(rows):
            note += f" {len(rows) - len(new)} unchanged claims kept their earlier verdicts; {len(new)} checked now."
    out = report_path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render(path, rows, verdicts, note), encoding="utf-8")
    ok, msg = gate(path)
    print(f"spec_factcheck: {len(rows)} claims; {msg}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
