#!/usr/bin/env python3
"""Check that the visual style evaluator still catches known errors: style_check.py and Vera on the fixtures.

    python -I _tools/style_critic_check.py [--script-only]

Like critic_check.py for Clara. Vera is the last automated check in the visual loop, so nothing
downstream measures her. Two kinds of known-bad fixture in _tools/fixtures/style/:
  - script fixtures: tiny game folders (materials/, scenes/) that style_check.py must FAIL with the
    expected rule IDs (neon → V1, glowing hive → V2, texture and imported mesh → V4, third accent → V3,
    90 px button → V11, low-contrast disabled text → V10);
  - critic fixtures: rendered 720 × 1280 shots (shots/<case>/) that Vera must FAIL, shown exactly as
    style_loop.py shows round 1, with a blocking row naming each expected rule.
Run it before and after any change to Vera's model or definition, or to style_check.py. Exit 0 means
every fixture was caught. Vera's calls are logged to the run log (table "Style loop"), and her full
reply is saved beside each fixture as last-verdict.md. Standard library only.
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402
import style_check  # noqa: E402
import style_loop  # noqa: E402

FIX = Path("_tools") / "fixtures" / "style"
SCRIPT_FIXTURES = {  # folder -> rule IDs style_check.py must report as blocking
    "neon": {"V1"},
    "glowing-hive": {"V2"},
    "textured": {"V4"},
    "third-accent": {"V3"},
    "small-button": {"V11"},
    "low-contrast": {"V10"},
}
CRITIC_FIXTURES = {  # shots/<case> -> {error: pattern a blocking row must match}
    "cluttered": {"third accent (V3)": r"\bV3\b", "clutter / cut off (V7)": r"\bV7\b"},
    "low-contrast": {"disabled text contrast (V10)": r"\bV10\b"},
}


def check_script():
    ok = True
    for case, want in SCRIPT_FIXTURES.items():
        rows = style_check.run(g.ROOT / FIX / case, g.ROOT / "STYLE_GUIDE.md")
        got = {r["rule"] for r in rows if not r["minor"]}
        missed = want - got
        ok = ok and not missed
        print(f"script {case}: {'caught' if not missed else 'MISSED ' + ', '.join(sorted(missed))} "
              f"(reported {', '.join(sorted(got)) or 'nothing'})")
    return ok


def check_critic(case, expect):
    shots = (FIX / "shots" / case).as_posix()
    reply, usage = g.run_agent(style_loop.CRITIC, style_loop.critic_prompt(1, shots, ""))
    g.keep_transcript(usage, g.ROOT / g.RUNS / f"{g.datetime.date.today()}-style-critic-check", f"vera-{case}")
    (g.ROOT / FIX / "shots" / case / "last-verdict.md").write_text(
        f"<!-- style_critic_check.py, {g.datetime.date.today()}; overwritten each run -->\n\n{reply}\n",
        encoding="utf-8", newline="\n")
    block = g.critic_block(reply, 1)
    if block is None:
        return False, ["no verdict block in Vera's reply"], usage
    rows = g.fail_rows(block)
    passed = g.verdict_of(block) == "FAIL"
    report = [f"verdict: {g.verdict_of(block)} ({len(rows)} blocking row(s))"]
    for error, pattern in expect.items():
        found = any(re.search(pattern, r) for r in rows)
        report.append(f"{'caught ' if found else 'MISSED '} {error}")
        passed = passed and found
    return passed, report, usage


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--script-only", action="store_true", help="skip Vera (no agent calls)")
    a = ap.parse_args(argv)
    results = [check_script()]
    if not a.script_only:
        for case, expect in CRITIC_FIXTURES.items():
            print(f"critic {case}: Vera checking...", flush=True)
            try:
                passed, report, usage = check_critic(case, expect)
            except g.AgentError as e:
                sys.exit(f"critic {case}: {e}")
            g.log_runs(f"style critic check {case}", [(style_loop.CRITIC, 1, usage)], table=style_loop.LOG_TABLE)
            print("\n".join(f"  {line}" for line in report))
            print(f"  {'PASS' if passed else 'FAIL'} ({usage['tokens']:,} tokens)")
            results.append(passed)
    print("style_critic_check:", "every fixture caught" if all(results) else "a fixture was MISSED")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
