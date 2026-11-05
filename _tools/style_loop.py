#!/usr/bin/env python3
"""Check Bob's scenes against STYLE_GUIDE.md and have Bob fix them until they pass (the visual style loop).

    python -I _tools/style_loop.py SLUG [--request "TEXT"] [--max-rounds 3] [--max-tokens N]
    python -I _tools/style_loop.py SLUG --resume [--max-rounds 3] [--max-tokens N]

Generator → Evaluator → Refiner, built like generate.py. Each round:
  1. (from round 2) Bob gets only the open FAIL rows not held for the designer and edits
     game/scenes/ and game/materials/ (the diff goes on the blackboard);
  2. game/tests/style_shots.gd renders the fixed shot set into game/reports/style/SLUG/round-N/;
  3. style_check.py measures the script rules (its table goes on the blackboard);
  4. Vera, the style critic, judges the shots and the table and replies with a verdict block.
The round passes only when Vera says PASS and style_check.py has no blocking row.

Designer stops: a row whose Fix ends "(designer)" (a new token, a rule change, two or more
acceptable answers) is never sent to Bob. If a round has any, Bob fixes the other rows, the rows
are listed under `## Waiting for the designer`, and the run stops with `result: waiting-designer`.
Build the comparison page for each (`_tools/compare_page.py stop`), link it on the blackboard,
and once the designer has edited STYLE_GUIDE.md or picked an option, `--resume SLUG` continues
from the next round. A run also stops at PASS, at --max-rounds (counted over the whole run) or
past --max-tokens (checked after each FAIL).

The blackboard is game/reports/style/SLUG/blackboard.md; no agent reads it. Every agent call is
logged to the run log (table "Style loop") and its transcript kept under _meta/sessions/runs/.
Tests: python -I _tools/test_generate.py (StyleLoop cases). Standard library only.
"""
import argparse
import datetime
import difflib
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402
import style_check  # noqa: E402

BUILDER, CRITIC = "builder", "style-critic"
g.NAMES.update({BUILDER: "Bob", CRITIC: "Vera"})
LOG_TABLE = "Style loop"
GODOT = os.environ.get("GODOT", r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe")
WATCHED = ("scenes", "materials")  # what Bob may edit, relative to the game folder
ROW = re.compile(r"^\|\s*\d+\s*\|")


class LoopError(Exception):
    pass


def render(game, out):
    """Render the style shot set into out (absolute). Replaced by a fake in the tests."""
    out.mkdir(parents=True, exist_ok=True)
    cmd = [GODOT, "--path", str(game), "--resolution", "720x1280", "--position", "0,0",
           "-s", "res://tests/style_shots.gd", "--", f"--out={out}"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        raise LoopError("style_shots.gd timed out after 300 s")
    if "COMPLETED" not in proc.stdout:
        tail = "\n".join((proc.stdout + proc.stderr).splitlines()[-8:])
        raise LoopError(f"style_shots.gd did not complete (exit {proc.returncode}):\n{tail}")


def snapshot(game):
    files = {}
    for sub in WATCHED:
        for p in sorted((game / sub).rglob("*")):
            if p.suffix in (".tscn", ".tres") and "variants" not in p.parts:
                files[p.relative_to(game).as_posix()] = p.read_text(encoding="utf-8")
    return files


def diff(before, after):
    out = []
    for name in sorted(set(before) | set(after)):
        a, b = before.get(name, ""), after.get(name, "")
        if a != b:
            out += difflib.unified_diff(a.splitlines(), b.splitlines(), f"a/{name}", f"b/{name}", n=1, lineterm="")
    return "\n".join(out)


def critic_prompt(n, shots, table, previous=None, changes=None):
    """What Vera sees in round n. style_critic_check.py builds round-1 prompts with this too."""
    later = (f"\n\nYour round {n - 1} verdict:\n\n{previous}\n\nBob's changes since then:\n\n~~~~diff\n"
             f"{changes or '(no changes)'}\n~~~~") if previous else ""
    return (f"Style loop, round {n}.\n\nShot folder: `{shots}` (Glob `*.png` there and Read each).\n\n"
            f"style_check.py's table for this round (script rules, already measured; blocking unless "
            f"marked (minor)):\n\n{table or '(no rows: the script rules all pass)'}{later}\n\n"
            f"Reply with only your `### Critic, round {n}` block.")


def open_rows(script_rows, block):
    """(for Bob, for the designer): open blocking rows as table lines, script rows first."""
    lines = [f"| {i} | {r['rule']} | `{r['where']}` | {r['finding']} | {r['fix']} |"
             for i, r in enumerate((r for r in script_rows if not r["minor"]), 1)]
    lines += [r for r in g.fail_rows(block or "")]
    held = [r for r in lines if "(designer)" in r]
    return [r for r in lines if r not in held], held


def round_dirs(base):
    return sorted((int(p.name.split("-")[1]) for p in base.glob("round-*") if p.name.split("-")[1].isdigit()))


def finish(board, slug, usage, result, summary, run_folder):
    rows = "\n".join(f"| {g.NAMES[a]}, round {n} | {u['tokens']:,} | {g.fmt(u.get('final'))} | {u['turns']} | "
                     f"{u['seconds']} s |" for a, n, u in usage)
    total = sum(u["tokens"] for *_, u in usage)
    kept = (f"\n\nTranscripts: `{run_folder.relative_to(g.ROOT).as_posix()}/`" if run_folder.is_dir() else "")
    g.append(board, f"\n## Result\n\n{summary}{kept}\n\n| Call | Total processed | Final context | Turns | Duration |\n"
                    f"|---|---|---|---|---|\n{rows}\n| **Total** | **{total:,}** | | | |\n")
    g.set_front(board, result=result)
    g.log_runs(f"style {slug}", usage, table=LOG_TABLE)
    return total


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("slug", help="run name, e.g. farm-0-1-2")
    ap.add_argument("--request", default="Check the current farm against STYLE_GUIDE.md and fix what fails.")
    ap.add_argument("--resume", action="store_true", help="continue a run stopped for the designer")
    ap.add_argument("--root", default="game", help="the Godot project folder")
    ap.add_argument("--max-rounds", type=int, default=3)
    ap.add_argument("--max-tokens", type=int, default=600_000)
    a = ap.parse_args(argv)
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", a.slug):
        sys.exit("slug must be kebab-case")
    game = (g.ROOT / a.root).resolve()
    base = g.ROOT / "game" / "reports" / "style" / a.slug
    board = base / "blackboard.md"
    rel_board = board.relative_to(g.ROOT).as_posix()
    if a.resume:
        if not board.is_file() or g.get_front(board, "result") != "waiting-designer":
            sys.exit(f"--resume needs {rel_board} with result: waiting-designer")
        start = (round_dirs(base) or [0])[-1] + 1
        g.set_front(board, result="running")
        g.append(board, f"\n## Resumed {datetime.date.today()}\n\nThe designer has answered the rows "
                        f"waiting above; the loop goes on from round {start}.\n")
    else:
        if board.exists() and g.get_front(board, "result") not in ("failed",):
            sys.exit(f"{rel_board} already exists; use --resume or a new slug")
        base.mkdir(parents=True, exist_ok=True)
        board.write_text(
            f"---\nslug: {a.slug}\nstarted: {datetime.date.today()}\nmax_rounds: {a.max_rounds}\n"
            f"max_tokens: {a.max_tokens}\nresult: running\n---\n# Style blackboard: {a.slug}\n\n"
            f"The shared record of this visual style loop. `style_loop.py` writes every section and hands "
            f"each agent only its slice; no agent reads this file.\n\n## Request\n{a.request}\n",
            encoding="utf-8", newline="\n")
        start = 1
    run_folder = g.ROOT / g.RUNS / f"{datetime.date.today()}-style-{a.slug}"
    usage, v, n, block, bob_rows, result = [], None, start - 1, None, [], "needs-review"
    previous_block, changes = None, None
    try:
        for n in range(start, a.max_rounds + 1):
            g.append(board, f"\n## Round {n}\n")
            if bob_rows:
                print(f"round {n}: Bob fixing {len(bob_rows)} row(s)...", flush=True)
                before = snapshot(game)
                _, u = g.run_agent(BUILDER, bob_prompt(n, bob_rows))
                g.keep_transcript(u, run_folder, f"bob-round-{n}")
                usage.append((BUILDER, n, u))
                changes = diff(before, snapshot(game))
                g.append(board, f"\n### Changes (Bob), round {n}\n\n~~~~diff\n{changes or '(no changes)'}\n~~~~\n")
            shots = base / f"round-{n}"
            print(f"round {n}: rendering shots...", flush=True)
            render(game, shots)
            rows = style_check.run(game, g.ROOT / "STYLE_GUIDE.md", shots=shots)
            table = style_check.table(rows) if rows else ""
            blocking = [r for r in rows if not r["minor"]]
            g.append(board, f"\n### style_check.py, round {n}\n\nShots: `{shots.relative_to(g.ROOT).as_posix()}/`\n\n"
                            f"{table or 'No rows: every script rule passes.'}\n")
            print(f"round {n}: style_check {len(blocking)} blocking row(s); Vera checking...", flush=True)
            prompt = critic_prompt(n, shots.relative_to(g.ROOT).as_posix(), table, previous_block, changes)
            reply, u = g.run_agent(CRITIC, prompt)
            g.keep_transcript(u, run_folder, f"vera-round-{n}")
            block = g.critic_block(reply, n)
            if block is None:
                reply, u2 = g.run_agent(CRITIC, prompt + " Your last reply had no such block with a VERDICT line.")
                g.keep_transcript(u2, run_folder, f"vera-round-{n}-retry")
                u = {k: u[k] + u2[k] for k in ("tokens", "turns", "seconds")} | {"final": u2.get("final")}
                block = g.critic_block(reply, n)
            usage.append((CRITIC, n, u))
            if block is None:
                raise g.AgentError(f"Vera returned no verdict for round {n}")
            g.append(board, f"\n{block}\n")
            v = "PASS" if g.verdict_of(block) == "PASS" and not blocking else "FAIL"
            print(f"round {n}: {v}", flush=True)
            if v == "PASS":
                result = "pass"
                break
            bob_rows, held = open_rows(rows, block)
            previous_block = block
            if held:
                g.append(board, "\n## Waiting for the designer\n\nThese rows need a creative choice, so Bob "
                                "does not get them. Each gets a comparison page (`_tools/compare_page.py stop`); "
                                "its link goes here. Resume with `style_loop.py " + a.slug + " --resume` once "
                                "the designer has picked.\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
                                + "\n".join(re.sub(r"^\|\s*\d+\s*\|", f"| {i} |", r) for i, r in enumerate(held, 1))
                                + "\n\nComparison pages:\n")
                if bob_rows:
                    print(f"round {n}: designer stop; Bob fixing the other {len(bob_rows)} row(s) meanwhile...", flush=True)
                    before = snapshot(game)
                    _, u = g.run_agent(BUILDER, bob_prompt(n + 1, bob_rows))
                    g.keep_transcript(u, run_folder, f"bob-round-{n}-meanwhile")
                    usage.append((BUILDER, n, u))
                    g.append(board, f"\n### Changes (Bob, meanwhile), after round {n}\n\n~~~~diff\n"
                                    f"{diff(before, snapshot(game)) or '(no changes)'}\n~~~~\n")
                result = "waiting-designer"
                break
            spent = sum(x["tokens"] for *_, x in usage)
            if n < a.max_rounds and spent >= a.max_tokens:
                print(f"token cap reached ({spent:,} >= {a.max_tokens:,}); stopping", flush=True)
                break
    except (g.AgentError, LoopError, KeyboardInterrupt) as e:
        reason = str(e) or "interrupted"
        finish(board, a.slug, usage, "failed", f"Failed in round {n}: {reason}.", run_folder)
        sys.exit(f"run failed: {reason}. Blackboard: {rel_board}")

    summary = {"pass": f"PASS in round {n}.",
               "waiting-designer": f"Stopped after round {n} for the designer: see Waiting for the designer.",
               }.get(result, f"Still FAIL after round {n} (max rounds {a.max_rounds} or the token cap).")
    total = finish(board, a.slug, usage, result, summary, run_folder)
    print(f"{rel_board}: {result} after round {n}, {total:,} tokens")
    return 0 if result == "pass" else 1


def bob_prompt(n, rows):
    return (f"Style loop, round {n}. Fix every FAIL row below by editing `game/scenes/` and "
            f"`game/materials/` only, with Edit on the lines concerned (no rewrites, no new palette colours: "
            f"use the token the Fix names). Do not touch scripts, tests or STYLE_GUIDE.md. Reply in at most "
            f"80 words: the files and lines you changed.\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
            + "\n".join(rows))


if __name__ == "__main__":
    sys.exit(main())
