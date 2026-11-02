#!/usr/bin/env python3
"""Check that the critic still catches known errors: run it once on each known-bad fixture.

    python -I _tools/critic_check.py

The critic is the last automated check in the content loop, so nothing downstream measures it.
Each fixture in _tools/fixtures/ is a draft with errors the critic must find. The script shows
the critic the draft exactly as generate.py does in round 1, then checks that the verdict is FAIL
and that every expected error appears in a blocking (non-minor) finding row. Run it before and
after any change to the critic's model or rules. Exit code 0 means every fixture was caught.
Each call is logged to _meta/agent-runs.md. Standard library only.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402

FIXTURES = [
    {
        "name": "onboarding-bad",
        "draft": "_tools/fixtures/onboarding-bad.md",
        "request": "The guide character's script for a new player's first session (GDD Story Premise & "
                   "Onboarding): explain why the meadow matters and introduce the farm, guide the first "
                   "manual harvest (uncapping, then centrifuge extraction), and guide the first upgrade "
                   "purchase. Short lines suited to mobile dialogue bubbles. The guide's name and "
                   "personality are TBD in the GDD, so offer 2-3 options rather than choosing one.",
        "expect": {  # error -> pattern one blocking finding row must match
            "false bloom fact": r"bloom",
            "\"cheapest\" upgrade": r"cheapest",
            "wrong §9 citation": r"§\s*9",
        },
    },
]


def check(fixture):
    """Run the critic on one fixture; return (passed, report lines, usage)."""
    draft = (g.ROOT / fixture["draft"]).read_text(encoding="utf-8").strip()
    prompt = (f"Content loop, round 1.\n\nRequest:\n{fixture['request']}\n\nThe full draft of "
              f"`{fixture['draft']}`:\n\n~~~~markdown\n{draft}\n~~~~\n\n"
              f"Reply with only your `### Critic, round 1` block.")
    reply, usage = g.run_agent(g.CRITIC, prompt)
    g.keep_transcript(usage, g.ROOT / g.RUNS / f"{g.datetime.date.today()}-critic-check", f"critic-{fixture['name']}")
    # keep the critic's full reply: when it misses something, this is the evidence of why
    saved = g.ROOT / fixture["draft"].replace(".md", ".last-verdict.md")
    saved.write_text(f"<!-- critic_check.py, {g.datetime.date.today()}; overwritten each run -->\n\n{reply}\n",
                     encoding="utf-8", newline="\n")
    block = g.critic_block(reply, 1)
    if block is None:
        return False, ["no verdict block in the critic's reply"], usage
    rows = g.fail_rows(block)
    report = [f"verdict: {g.verdict_of(block)} ({len(rows)} blocking finding(s))"]
    passed = g.verdict_of(block) == "FAIL"
    for error, pattern in fixture["expect"].items():
        found = any(re.search(pattern, r, re.I) for r in rows)
        report.append(f"{'caught ' if found else 'MISSED '} {error}")
        passed = passed and found
    return passed, report, usage


def main():
    results = []
    for fixture in FIXTURES:
        print(f"{fixture['name']}: critic checking...", flush=True)
        try:
            passed, report, usage = check(fixture)
        except g.AgentError as e:
            sys.exit(f"{fixture['name']}: {e}")
        g.log_runs(f"critic check {fixture['name']}", [(g.CRITIC, 1, usage)])
        print("\n".join(f"  {line}" for line in report))
        print(f"  full verdict: {fixture['draft'].replace('.md', '.last-verdict.md')}")
        print(f"  {'PASS' if passed else 'FAIL'} ({usage['tokens']:,} tokens)")
        results.append(passed)
    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
