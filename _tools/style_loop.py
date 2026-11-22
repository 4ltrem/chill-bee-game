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

Sandbox and guards (designer, 2026-11-20): by default the loop works on a copy of the game under
_meta/sessions/runs/style-SLUG-sandbox/ (gitignored), never on game/ itself, and ends by writing
game/reports/style/SLUG/sandbox.patch for the designer to review and `git apply` (--live edits the game).
After each Bob edit, the loop puts back any change to motion, to the size or place of the props the
designer picked, or to the UI (the FarmUIRoot tree and its StyleBoxes are not Bob's), then runs the
unit suite on the copy (the test gate, --no-gate skips it); a round that fails it is undone.

The loop's choices (designer, 2026-11-20: the assets are generated, so the loop decides): a row whose
Fix ends "(designer)" and lists an option A (by convention the option that fits the current guide,
the one Vera expects to score higher) goes to Bob as option A, without stopping. Each choice is listed
under `### Loop's choices` on the blackboard, Vera is told about it next round, and it is added to
the Design Votes page afterwards (`_tools/compare_page.py add`) so the designer can reverse it.
Designer stops: a "(designer)" row with no option A (only a new token or a rule change would fix it)
is never sent to Bob. If a round has any, Bob fixes the other rows, the rows
are listed under `## Waiting for the designer`, and the run stops with `result: waiting-designer`.
Add each as a question on the Design Votes page (`_tools/compare_page.py add`), link it on the blackboard,
and once the designer has edited STYLE_GUIDE.md or picked an option, `--resume SLUG` continues
from the next round. A run also stops at PASS, at --max-rounds (counted over the whole run) or
past --max-tokens (checked after each FAIL).

The blackboard is game/reports/style/SLUG/blackboard.md (format: _templates/blackboard.md); no agent reads it. Every agent call is
logged to the run log (table "Style loop") and its transcript kept under _meta/sessions/runs/.
Tests: python -I _tools/test_generate.py (StyleLoop cases). Standard library only.
"""
import argparse
import datetime
import difflib
import os
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402
import style_check  # noqa: E402

BUILDER, CRITIC, UI_FIXER = "builder", "style-critic", "programmer"
g.NAMES.update({BUILDER: "Bob", CRITIC: "Vera", UI_FIXER: "Patricia"})
LOG_TABLE = "Style loop"
from godot_path import GODOT  # noqa: E402
WATCHED = ("scenes", "materials", "scripts")  # what the refiners may edit, relative to the game folder
UI_SCRIPTS = {f"scripts/{s}.gd" for s in ("farm_ui", "shop_ui", "harvest_ui", "floating_icon", "dev_panel")}
UI_RULES = {"V10", "V11", "V12"}  # button text contrast, touch targets, fonts: always UI rows
ROW = re.compile(r"^\|\s*\d+\s*\|")


class LoopError(Exception):
    pass


def render(game, out):
    """Render the style shot set into out (absolute). Replaced by a fake in the tests."""
    out.mkdir(parents=True, exist_ok=True)
    cmd = [GODOT, "--path", str(game), "--resolution", "720x1280", "--position", "0,0",
           "-s", "res://tests/style_shots.gd", "--", f"--out={out}"]
    try:
        with g.live.step("render shots") as s:
            proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
            s.ok = "COMPLETED" in proc.stdout
    except subprocess.TimeoutExpired:
        raise LoopError("style_shots.gd timed out after 300 s")
    if "COMPLETED" not in proc.stdout:
        tail = "\n".join((proc.stdout + proc.stderr).splitlines()[-8:])
        raise LoopError(f"style_shots.gd did not complete (exit {proc.returncode}):\n{tail}")


def snapshot(game):
    files = {}
    for sub in WATCHED:
        for p in sorted((game / sub).rglob("*")):
            if p.suffix in (".tscn", ".tres", ".gd") and "variants" not in p.parts:
                files[p.relative_to(game).as_posix()] = p.read_text(encoding="utf-8")
    return files


# Motion is not the style loop's (designer, 2026-11-20, after Bob turned the truck's exit to a diagonal): the loop
# judges still shots, so nothing in it can judge how things move. Bob's edits to these properties are put back.
MOTION = re.compile(r"^\s*\S*(direction|speed|velocity|path|curve|anim|tween|duration|seconds|delay|exit|drive|"
                    r"route|waypoint|track)\S*\s*=", re.I)


# The props the designer picked and play-tested keep their size and shape (designer, 2026-11-20, after Bob shrank the
# truck and enlarged the jars to please the critic): geometry lines in their scenes, and their placement in main.tscn.
PICKED_PROPS = {f"scenes/props/{p}.tscn" for p in ("hive", "centrifuge", "centrifuge_gears", "jar", "jar_crate", "truck",
                                                   "uncapping_fork", "honey_cell")}
PICKED_NODES = {"Hive", "Centrifuge", "JarCrate", "Truck", "UncapFork"}
GEOMETRY = re.compile(r"^\s*(transform|scale|size|radius|top_radius|bottom_radius|height|width|depth|mesh)\s*=")
NODE = re.compile(r'^\[node name="([^"]+)"')


def is_ui(header):
    """UI is not Bob's (designer, 2026-11-20, after he moved the Spin icon): the FarmUIRoot tree and its StyleBoxes."""
    return bool(header) and ('parent="FarmUIRoot' in header or 'name="FarmUIRoot"' in header
                             or header.startswith('[sub_resource type="StyleBox'))


# Patricia fixes the UI rows (designer, 2026-11-20) but never moves the UI: icon places and layout are the designer's
# (UI_DESIGN.md). She may change text colours, outlines, font sizes, minimum sizes and StyleBoxes.
UI_LAYOUT = re.compile(r"^\s*\S*(screen_offset|anchor|offset_|position|grow_|layout_mode|size_flags|alignment)\S*\s*=")


def locked(name, line, header, who=BUILDER):
    """Why the loop puts this line back, or None if this refiner (Bob, or Patricia for the UI) may change it.
    header: the `[node ...]` or `[sub_resource ...]` line the line sits under (itself, for a header line)."""
    ui = name == "scenes/main.tscn" and is_ui(header) or name in UI_SCRIPTS
    if who == BUILDER and (ui or name.startswith("scripts/")):
        return "UI" if ui else "script"
    if who == UI_FIXER:
        if not ui:
            return "not UI"
        if UI_LAYOUT.match(line):
            return "UI layout"
    if MOTION.match(line):
        return "motion"
    node = NODE.match(header or "")
    if GEOMETRY.match(line) and (name in PICKED_PROPS or name == "scenes/main.tscn" and node
                                 and node.group(1) in PICKED_NODES):
        return "picked prop size"
    return None


def nodes_of(lines):
    """The section header each line sits under."""
    cur, out = None, []
    for x in lines:
        if x.startswith("["):
            cur = x.strip()
        out.append(cur)
    return out


def guard_motion(before, game, who=BUILDER):
    """Put back each line of a refiner's edits that `locked` forbids for them, keeping their other edits in the same
    hunk; a whole file that is not theirs (a script for Bob, a non-UI file for Patricia) goes back whole, and a file
    they added there is removed. Returns what was put back."""
    put_back = []
    for name in set(snapshot(game)) - set(before):
        if who == UI_FIXER or name.startswith("scripts/"):
            (game / name).unlink()
            put_back.append(f"{name}: new file removed (not {g.NAMES[who]}'s)")
    for name, old in before.items():
        path = game / name
        new = path.read_text(encoding="utf-8") if path.is_file() else ""
        if new == old:
            continue
        if (who == BUILDER and name.startswith("scripts/")
                or who == UI_FIXER and name != "scenes/main.tscn" and name not in UI_SCRIPTS):
            path.write_text(old, encoding="utf-8", newline="")
            put_back.append(f"{name}: whole file (not {g.NAMES[who]}'s)")
            continue
        a, b = old.splitlines(keepends=True), new.splitlines(keepends=True)
        na, nb = nodes_of(a), nodes_of(b)
        # a part added to a picked prop reshapes it: every line of an added section goes (r5 left empty rim nodes)
        added = set(nb) - set(na) - {None} if name in PICKED_PROPS else set()

        def why_b(j):
            return locked(name, b[j], nb[j], who) or ("picked prop shape" if nb[j] in added else None)
        out, changed = [], False
        for op, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
            if op != "equal" and (any(locked(name, a[i], na[i], who) for i in range(i1, i2))
                                  or any(why_b(j) for j in range(j1, j2))):
                # line by line: the other edits in the hunk stay; each locked line goes back to what it was
                old_locked = {(na[i], a[i].split("=")[0].strip()): a[i] for i in range(i1, i2)
                              if locked(name, a[i], na[i], who)}
                for j in range(j1, j2):
                    x, why = b[j], why_b(j)
                    if not why:
                        out.append(x)
                    elif (k := (nb[j], x.split("=")[0].strip())) in old_locked:
                        out.append(old_locked.pop(k))
                    if why and x not in a[i1:i2]:
                        put_back.append(f"{name}: {x.strip()} ({why})")
                out += old_locked.values()   # a locked line Bob deleted comes back
                changed = True
            else:
                out += b[j1:j2]
        if changed:
            path.write_text("".join(out), encoding="utf-8", newline="")
    return put_back


def motion_note(board, put_back, who=BUILDER):
    if put_back:
        g.append(board, f"\n### Guard ({g.NAMES[who]})\n\n{g.NAMES[who]} changed something that is not theirs to "
                        f"change (motion, a picked prop's size or place, the UI's layout, or another owner's file); "
                        f"the loop put these back:\n\n" + "\n".join(f"- `{x}`" for x in put_back) + "\n")


def diff(before, after, prefix="", context=1):
    out = []
    for name in sorted(set(before) | set(after)):
        a, b = before.get(name, ""), after.get(name, "")
        if a != b:
            out += difflib.unified_diff(a.splitlines(), b.splitlines(), f"a/{prefix}{name}", f"b/{prefix}{name}",
                                        n=context, lineterm="")
    return "\n".join(out)


# The sandbox (designer, 2026-11-20: "Bob is breaking more than he's fixing"): the loop works on a copy of the game, so
# the game itself never changes; the run ends with a patch the designer reviews. Tests reaching outside game/ need
# _tools/ and content/ beside the copy (as in mutate.py).
def make_sandbox(live, where):
    """A copy of the game under `where` (kept across --resume); returns the copy's game folder."""
    copy = where / "game"
    if not copy.is_dir():
        shutil.copytree(live, copy, ignore=shutil.ignore_patterns("builds", "reports"))
        (copy / "reports").mkdir(exist_ok=True)
        for sibling in ("_tools", "content"):
            if (live.parent / sibling).is_dir():
                shutil.copytree(live.parent / sibling, where / sibling, ignore=shutil.ignore_patterns("__pycache__"))
        for doc in ("STYLE_GUIDE.md", "GDD.md"):  # tests read the palette from ../STYLE_GUIDE.md
            if (live.parent / doc).is_file():
                shutil.copy(live.parent / doc, where / doc)
    return copy


GATE = ("unit",)  # the gate's suites: unit holds the layout, UI-placement and icon tests


def gate(game):
    """Run the gate's suites on a game folder (fast flags); return (passed, one-line summary)."""
    out = game / "reports" / "gate.json"
    cmd = [sys.executable, "-I", str(g.ROOT / "_tools" / "godot_run.py"), *GATE, "--root", str(game),
           "--time-scale", "6", "--skip-x1", "--json", str(out)]
    try:
        subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=1800)
        results = json.loads(out.read_text(encoding="utf-8"))
    except (subprocess.TimeoutExpired, OSError, ValueError) as e:
        return False, f"the gate did not run ({type(e).__name__})", {"(gate did not run)"}
    passed = all(r["status"] == "PASS" for r in results)
    failing = {m for r in results for f in r.get("fails", []) for m in re.findall(r"\bt_\w+", str(f))}
    if not passed and not failing:
        failing = {f"({r['suite']} {r['status']})" for r in results if r["status"] != "PASS"}
    parts = []
    for r in results:
        t = r.get("total") or {}
        fails = ", ".join(str(f.get("name", f)) if isinstance(f, dict) else str(f) for f in r.get("fails", [])[:5])
        parts.append(f"{r['suite']} {r['status']} ({t.get('passed', '?')} passed, {t.get('failed', '?')} failed)"
                     + (f": {fails}" if fails else ""))
    return passed, "; ".join(parts), failing


def restore(game, before):
    """Put the watched files back to a snapshot (a gate failure undoes Bob's whole round)."""
    now = snapshot(game)
    for name in set(now) - set(before):
        (game / name).unlink()
    for name, text in before.items():
        if now.get(name) != text:
            (game / name).write_text(text, encoding="utf-8", newline="")


def split_rows(rows, game):
    """(Bob's rows, Patricia's UI rows). A row is UI when Vera tagged it `(UI)`, its rule is a UI rule (V10-V12), or
    the script row points at a UI script or a line of main.tscn inside the UI tree."""
    bob, ui = [], []
    for r in rows:
        cells = [c.strip() for c in r.strip().strip("|").split("|")]
        rule, where = (cells[1], cells[2].strip("`")) if len(cells) > 2 else ("", "")
        is_row_ui = "(UI)" in r or rule in UI_RULES or where.split(":")[0] in UI_SCRIPTS
        m = re.match(r"(scenes/main\.tscn):(\d+)", where)
        if m and (game / m.group(1)).is_file():
            lines = (game / m.group(1)).read_text(encoding="utf-8").splitlines()
            is_row_ui = is_row_ui or is_ui(nodes_of(lines)[min(int(m.group(2)), len(lines)) - 1])
        (ui if is_row_ui else bob).append(r)
    return bob, ui


def refine(board, game, n, rows, who, usage, run_folder, test_gate, label):
    """One refiner's turn on its rows: the agent edits the copy, the guard puts back what is not theirs, then the test
    gate (a new failure undoes the whole turn). test_gate: the baseline's failing tests, or None for no gate.
    Returns the diff of what survived."""
    before = snapshot(game)
    print(f"round {n}: {g.NAMES[who]} fixing {len(rows)} row(s)...", flush=True)
    _, u = g.run_agent(who, (bob_prompt if who == BUILDER else ui_prompt)(n, rows, game))
    g.keep_transcript(u, run_folder, f"{g.NAMES[who].lower()}-{label}")
    usage.append((who, n, u))
    motion_note(board, guard_motion(before, game, who), who)
    if test_gate is not None and snapshot(game) != before:
        print(f"round {n}: test gate on {g.NAMES[who]}'s edits...", flush=True)
        _, summary, failing = gate(game)
        new = sorted(failing - test_gate)   # test_gate: what already failed before the run (the baseline)
        if new:
            restore(game, before)
        g.append(board, f"\n### Test gate ({g.NAMES[who]}), round {n}\n\n"
                        + (f"FAIL: {g.NAMES[who]}’s edits this round were undone, they broke {', '.join(new)}"
                           if new else "PASS: no test fails that passed before the run")
                        + f". ({summary})\n")
    return diff(before, snapshot(game))


def refine_all(board, game, n, rows, usage, run_folder, test_gate, heading, label):
    """Bob takes the 3D rows, then Patricia the UI rows; each diff goes on the board. Returns the combined diff."""
    parts = []
    for who, mine in zip((BUILDER, UI_FIXER), split_rows(rows, game)):
        if mine:
            d = refine(board, game, n, mine, who, usage, run_folder, test_gate, label)
            g.append(board, f"\n{heading.format(who=g.NAMES[who])}\n\n~~~~diff\n{d or '(no changes)'}\n~~~~\n")
            parts.append(d)
    return "\n".join(p for p in parts if p)


def critic_prompt(n, shots, table, previous=None, changes=None, note=None, choices=None):
    """What Vera sees in round n. style_critic_check.py builds round-1 prompts with this too."""
    later = (f"\n\nYour round {n - 1} verdict:\n\n{previous}\n\nBob's changes since then:\n\n~~~~diff\n"
             f"{changes or '(no changes)'}\n~~~~") if previous else ""
    if choices:  # the loop's own picks on (designer) rows: judge the result, don't ask the choice again
        later += (f"\n\nThe loop chose these options on last round's (designer) rows and Bob applied them:\n\n"
                  f"{choices}\n\nJudge the result on screen. Do not ask the same choice again as a (designer) row; "
                  f"if the chosen option still fails its rule, write a plain blocking row with a fix within it.")
    if note:  # the designer's answer to a stop: a deferred row is not repeated as blocking
        later += (f"\n\nThe designer's decision since your last verdict: {note}\nA row the designer has deferred "
                  f"goes in your table as (minor), not as a blocking or (designer) row.")
    later += ("\n\nWho fixes your rows: Bob the 3D scene (colours and materials, and its non-picked nodes; never "
              "motion, or the size, shape or place of the props the designer picked: hive, centrifuge, gears, jars, "
              "crate, truck, fork, honey cell); Patricia the UI (HUD, shop panel, buttons, labels, icons: colours, "
              "outlines, font and minimum sizes, never their places). Start the Fix of every row about the UI with "
              "`(UI)` so it goes to her. Judge and score exactly as before; where a Fix has a choice, prefer one "
              "they can make, and if only motion, moving the UI or a picked prop's size would fix a row, still report "
              "it and say so in the Fix.")
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


OPTION_A = re.compile(r"\bA:\s*(.+?)\s*(?:[;.,]?\s*\bB:|\(designer\)|$)")


def choose(held):
    """Split held rows into the loop's choices and true designer stops. A row whose Fix lists an option A
    goes to Bob with option A as its Fix; a V1 row waiting on the V3 decision for the same file follows
    that V3 row's choice (no Bob row of its own). Returns (choices, stops); a choice is
    (original row, row for Bob or None, what was chosen)."""
    choices, stops = [], []
    v3_files = set()
    for r in held:
        cells = [c.strip() for c in r.strip().strip("|").split("|")]
        m = OPTION_A.search(cells[-1])
        if m:
            fix = f"{m.group(1).rstrip('.;, ')} (the loop's choice A)"
            choices.append((r, "| " + " | ".join(cells[:-1] + [fix]) + " |", f"A: {m.group(1).rstrip('.;, ')}"))
            if cells[1] == "V3":
                v3_files.add(cells[2])
        else:
            stops.append(r)
    for r in [s for s in stops if "per the V3 decision" in s]:
        cells = [c.strip() for c in r.strip().strip("|").split("|")]
        if cells[2] in v3_files:
            stops.remove(r)
            choices.append((r, None, "follows the V3 row's choice A on the same file"))
    return choices, stops


def round_dirs(base):
    return sorted((int(p.name.split("-")[1]) for p in base.glob("round-*") if p.name.split("-")[1].isdigit()))


def finish(board, slug, usage, result, summary, run_folder):
    total = g.finish_board(board, [(f"{g.NAMES[a]}, round {n}", u) for a, n, u in usage], result, summary, run_folder)
    g.log_runs(f"style {slug}", usage, table=LOG_TABLE)
    return total


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("slug", help="run name, e.g. farm-0-1-2")
    ap.add_argument("--request", default="Check the current farm against STYLE_GUIDE.md and fix what fails.")
    ap.add_argument("--resume", action="store_true", help="continue a run stopped for the designer")
    ap.add_argument("--note", help="with --resume: the designer's decision on the waiting rows, passed to Vera")
    ap.add_argument("--root", default="game", help="the Godot project folder")
    ap.add_argument("--max-rounds", type=int, default=3)
    ap.add_argument("--max-tokens", type=int, default=600_000)
    ap.add_argument("--live", action="store_true", help="let Bob edit the game itself instead of a sandbox copy")
    ap.add_argument("--no-gate", action="store_true", help="skip the test gate after Bob's edits")
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
        text = board.read_text(encoding="utf-8")  # Vera's last verdict and Bob's meanwhile diff carry over
        blocks = re.findall(r"^### Critic, round \d+\b.*?(?=^#{2,3} |\Z)", text, re.M | re.S)
        resumed_block = blocks[-1].strip() if blocks else None
        diffs = re.findall(r"^### Changes \((?:Bob|Patricia), meanwhile[^\n]*\n\n~~~~diff\n(.*?)\n~~~~", text, re.M | re.S)
        resumed_changes = "\n".join(diffs[-2:]) if diffs else None  # Bob's and Patricia's of the last stop
        if start > a.max_rounds:
            sys.exit(f"round {start} would pass --max-rounds {a.max_rounds}; raise it to resume")
        g.resumed(board, f"The designer has answered the rows waiting above; the loop goes on from round {start}.\n"
                         + (f"\nDesigner's decision: {a.note}\n" if a.note else ""))
    else:
        if board.exists() and g.get_front(board, "result") not in ("failed",):
            sys.exit(f"{rel_board} already exists; use --resume or a new slug")
        g.board_start(board, {"slug": a.slug, "started": datetime.date.today(), "max_rounds": a.max_rounds,
                              "max_tokens": a.max_tokens}, f"Style blackboard: {a.slug}", a.request)
        start, resumed_block, resumed_changes = 1, None, None
    run_folder = g.ROOT / g.RUNS / f"{datetime.date.today()}-style-{a.slug}"
    live = game
    if not a.live:
        game = make_sandbox(live, g.ROOT / g.RUNS / f"style-{a.slug}-sandbox")
        if start == 1:
            g.append(board, f"\nSandbox: Bob edits `{game.relative_to(g.ROOT).as_posix()}/`, a copy; the game itself "
                            f"does not change. The run ends with `sandbox.patch` beside this board for the designer.\n")
    baseline = None   # the tests failing before any refiner edit: the gate undoes a turn only for a new failure
    if not a.no_gate:
        print("baseline test run before any edit...", flush=True)
        _, summary, baseline = gate(game)
        g.append(board, f"\nTest gate baseline (before any edit): {summary}\n")
    usage, v, n, block, bob_rows, result = [], None, start - 1, None, [], "needs-review"
    previous_block, changes, choices = resumed_block, resumed_changes, None
    try:
        for n in range(start, a.max_rounds + 1):
            g.append(board, f"\n## Round {n}\n")
            g.set_live_tag(f"style {a.slug} · r{n}")
            if bob_rows:
                changes = refine_all(board, game, n, bob_rows, usage, run_folder, baseline,
                                     "### Changes ({who}), round " + str(n), f"round-{n}")
            shots = base / f"round-{n}"
            print(f"round {n}: rendering shots...", flush=True)
            try:
                render(game, shots)
            except LoopError as e:  # one retry: a flaky render should not end a whole run (2026-11-20)
                print(f"round {n}: render failed, retrying once: {str(e).splitlines()[-1]}", flush=True)
                g.append(board, f"\nRender retried once after: `{str(e).splitlines()[-1]}`\n")
                render(game, shots)
            rows = style_check.run(game, g.ROOT / "STYLE_GUIDE.md", shots=shots)
            table = style_check.table(rows) if rows else ""
            blocking = [r for r in rows if not r["minor"]]
            g.append(board, f"\n### style_check.py, round {n}\n\nShots: `{shots.relative_to(g.ROOT).as_posix()}/`\n\n"
                            f"{table or 'No rows: every script rule passes.'}\n")
            print(f"round {n}: style_check {len(blocking)} blocking row(s); Vera checking...", flush=True)
            prompt = critic_prompt(n, shots.relative_to(g.ROOT).as_posix(), table, previous_block, changes,
                                   a.note if a.resume and n == start else None, choices)
            choices = None
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
            picked, held = choose(held)
            if picked:
                bob_rows += [b for _, b, _ in picked if b]
                choices = "\n".join(f"- {o.strip()} → chose {c}" for o, _, c in picked)
                g.append(board, f"\n### Loop's choices, round {n}\n\nThese rows had more than one acceptable answer. "
                                f"The loop took option A (it fits the current guide) without stopping; each goes on "
                                f"the Design Votes page afterwards (`_tools/compare_page.py add`) so the designer can "
                                f"reverse it.\n\n{choices}\n")
                print(f"round {n}: the loop chose option A on {len(picked)} (designer) row(s)", flush=True)
            previous_block = block
            if held and n < a.max_rounds:  # in the last round, held rows are listed with the others instead
                g.waiting(board, "These rows need a creative choice, so Bob "
                                "does not get them. Each becomes a question with votes on the Design Votes page "
                                "(`_tools/compare_page.py add`); "
                                "its link goes here. Resume with `style_loop.py " + a.slug + " --resume` once "
                                "the designer has picked.\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
                                + "\n".join(re.sub(r"^\|\s*\d+\s*\|", f"| {i} |", r) for i, r in enumerate(held, 1))
                                + "\n\nComparison pages:\n")
                if bob_rows:
                    print(f"round {n}: designer stop; fixing the other {len(bob_rows)} row(s) meanwhile...", flush=True)
                    refine_all(board, game, n, bob_rows, usage, run_folder, baseline,
                               "### Changes ({who}, meanwhile), after round " + str(n), f"round-{n}-meanwhile")
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
               }.get(result, f"Still FAIL after round {n} (max rounds {a.max_rounds} or the token cap). Open rows:\n\n"
                             "| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
                             + "\n".join(sum(open_rows(rows, block), [])))
    if game != live:  # the sandbox's changes, as a patch the designer reviews and applies (or not)
        patch = diff(snapshot(live), snapshot(game), prefix=f"{live.relative_to(g.ROOT).as_posix()}/", context=3)
        (base / "sandbox.patch").write_text(patch + "\n" if patch else "", encoding="utf-8", newline="\n")
        summary += (f"\n\nThe game was not changed. The refiners' surviving edits are in `{base.relative_to(g.ROOT).as_posix()}"
                    f"/sandbox.patch` ({sum(1 for x in patch.splitlines() if x[:1] in '+-' and x[:3] not in ('+++', '---'))}"
                    f" changed lines); "
                    f"review, then `git apply` it to keep them." if patch else
                    "\n\nThe game was not changed, and the sandbox has no changes to propose.")
    total = finish(board, a.slug, usage, result, summary, run_folder)
    print(f"{rel_board}: {result} after round {n}, {total:,} tokens")
    return 0 if result == "pass" else 1


def ui_prompt(n, rows, game=None):
    where = game.relative_to(g.ROOT).as_posix() if game else "game"
    scripts = ", ".join(f"`{where}/{s}`" for s in sorted(UI_SCRIPTS))
    return (f"Style loop, round {n}: you are the UI refiner (designer, 2026-11-20). Fix every UI row below in this "
            f"run's copy of the game only: the FarmUIRoot tree and its StyleBoxes in `{where}/scenes/main.tscn`, and "
            f"the UI scripts {scripts}. Edit nothing else. Read `UI_DESIGN.md` first: the icons' places and the layout "
            f"are the designer's, so never move anything (no screen_offset, anchor, offset, position, layout or "
            f"alignment change; the loop puts those back). Fix only what the rule measures: text and outline colours "
            f"from the STYLE_GUIDE.md palette, font sizes, minimum sizes, StyleBox fills. Use Edit on the lines "
            f"concerned; do not run tests (the loop runs them, and a round that breaks one is undone). If a row "
            f"can only be fixed by moving something, skip it and say so. Reply in at most 80 words: the files and "
            f"lines you changed.\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n" + "\n".join(rows))


def bob_prompt(n, rows, game=None):
    where = game.relative_to(g.ROOT).as_posix() if game else "game"
    return (f"Style loop, round {n}. Fix every FAIL row below by editing `{where}/scenes/` and "
            f"`{where}/materials/` only (this run's copy of the game: edit nothing under any other folder), with "
            f"Edit on the lines concerned (no rewrites, no new palette colours: "
            f"use the token the Fix names). Do not touch scripts, tests or STYLE_GUIDE.md. Never change how anything "
            f"moves (direction, speed, path, exit, animation, tween or timing properties), and never resize, reshape "
            f"or move the props the designer picked (hive, centrifuge, gears, jars, crate, truck, fork, honey cell), "
            f"and never edit the UI (the FarmUIRoot tree and its StyleBoxes are not yours): the loop puts such edits "
            f"back, and a round that breaks a test is undone. Colours and materials of the 3D scene are fine. If a "
            f"row can only be fixed that way, "
            f"skip it and say so. Reply in at most "
            f"80 words: the files and lines you changed.\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
            + "\n".join(rows))


if __name__ == "__main__":
    sys.exit(main())
