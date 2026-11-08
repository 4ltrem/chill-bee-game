#!/usr/bin/env python3
"""Render a live prop beside the designer's picked variant, and (optionally) have Vera judge only whether they match.

    python -I _tools/pick_match.py game/scenes/props/hive.tscn game/scenes/variants/hive-frames/hive-frames-a.tscn
           [--out DIR] [--no-agent]

The look-before-done rule as a step (designer, 2026-11-08: C5 shipped a shallow hive with two flat frames instead of
round 9 pick "a", with every test green). One Godot load renders both scenes with the same staging and close camera
(game/tests/model_shots.gd --scenes) into DIR (default game/reports/pick/<live stem>/), as <stem>.png each.
Then Vera gets a pick-match prompt: shape, parts, counts, proportions and layout only, not the style rules.
Exit 0 on PASS (or after rendering, with --no-agent), 1 on FAIL with her rows printed, 2 when the render fails.
goal_agent.py uses render() and prompt() itself, so its budget guard and run log cover Vera's call.
Standard library only.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT", r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe")
CRITIC = "style-critic"
g.NAMES.setdefault(CRITIC, "Vera")
LIVE = re.compile(r"(?:game/)?scenes/props/[\w-]+\.tscn")
PICK = re.compile(r"(?:game/)?scenes/variants/[\w-]+/[\w-]+\.tscn")


def pairs(text):
    """(live scene, picked variant) pairs a spec item names: each props scene with the variant in the same text."""
    live = list(dict.fromkeys("game/" + m.removeprefix("game/") for m in LIVE.findall(text)))
    pick = list(dict.fromkeys("game/" + m.removeprefix("game/") for m in PICK.findall(text)))
    return [(live[0], pick[0])] if len(live) == 1 and len(pick) == 1 else list(zip(live, pick)) if len(live) == len(pick) else []


def res(path):
    return "res://" + Path(path).as_posix().removeprefix("game/")


def default_out(live):
    return ROOT / "game" / "reports" / "pick" / Path(live).stem


HIDE = "HiveLid,Lid"   # a live prop's closed lid hides the frames the pick shows; hidden in the live shot only


def render_cmd(live, pick, out, hide=HIDE):
    return [GODOT, "--path", str(ROOT / "game"), "--resolution", "720x1280", "--position", "0,0",
            "-s", "res://tests/model_shots.gd", "--", f"--scenes={res(live)},{res(pick)}", f"--out={Path(out).resolve()}"] \
        + ([f"--hide={hide}"] if hide else [])


def shots(live, pick, out):
    return [Path(out) / f"{Path(p).stem}.png" for p in (live, pick)]


def render(live, pick, out):
    """(ok, message). Both shots must exist after the run."""
    Path(out).mkdir(parents=True, exist_ok=True)
    try:
        p = subprocess.run(render_cmd(live, pick, out), capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=300)
    except subprocess.TimeoutExpired:
        return False, "model_shots.gd timed out after 300 s"
    missing = [s.name for s in shots(live, pick, out) if not s.is_file()]
    if "COMPLETED" not in p.stdout or missing:
        return False, "model_shots.gd did not complete:\n" + "\n".join((p.stdout + p.stderr).splitlines()[-8:])
    return True, "\n".join(l for l in p.stdout.splitlines() if l.startswith(("shot ", "camera:", "hidden")))


def rel(path):
    try:
        return Path(path).resolve().relative_to(ROOT).as_posix()
    except ValueError:   # outside this repo (a test's temporary copy): keep it whole
        return Path(path).as_posix()


def prompt(live, pick, out, item_text=""):
    a, b = (rel(s) for s in shots(live, pick, out))
    return (f"Pick match, round 1. This is not a style round: do not score assets or apply the V rules.\n\n"
            f"The designer picked the variant `{pick}` (shot `{b}`). The live prop `{live}` (shot `{a}`) must match "
            f"it. Read both shots. Compare only: the parts present (walls, frames, lid, legs ...), their counts, "
            f"orientation (upright or flat), proportions (deep or shallow, wide or narrow) and layout. Colour and "
            f"material differences are not findings, and neither is the camera fit. The live prop's lid is hidden in "
            f"its shot so its inside shows: a missing lid there is not a finding.\n\n"
            + (f"The spec item:\n\n{item_text.strip()}\n\n" if item_text else "")
            + "Reply with only a `### Critic, round 1` block: `VERDICT: PASS` when the live prop has the pick's parts, "
              "counts, orientation and proportions; otherwise `VERDICT: FAIL` and one row per difference, Rule `pick`, "
              f"Shot `{Path(a).name}`, the Finding saying what the pick has and what the live prop has instead, and "
              f"a Fix Bob can carry out in `{live}`. No Scores table.")


def judge(reply):
    """(verdict, blocking rows) from Vera's reply; verdict None when the block is missing."""
    block = g.critic_block(reply, 1)
    return (g.verdict_of(block), g.fail_rows(block)) if block else (None, [])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("live")
    ap.add_argument("pick")
    ap.add_argument("--out")
    ap.add_argument("--no-agent", action="store_true", help="render only; look at the two shots yourself")
    a = ap.parse_args(argv)
    out = Path(a.out) if a.out else default_out(a.live)
    ok, msg = render(a.live, a.pick, out)
    print(f"pick_match: {msg}")
    if not ok:
        return 2
    if a.no_agent:
        return 0
    reply, u = g.run_agent(CRITIC, prompt(a.live, a.pick, out), tools="Read,Grep,Glob")
    verdict, rows = judge(reply)
    print(f"pick_match: {verdict or 'no verdict'} ({u['tokens']:,} tokens)")
    print("\n".join(rows) if verdict else reply)
    g.log_runs(f"pick {Path(a.live).stem}", [(CRITIC, 1, u)], table="Pick match")
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
