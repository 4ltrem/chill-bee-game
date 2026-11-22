#!/usr/bin/env python3
"""Tests for goal_agent.py: the reasoning layer on a fixture, and the loop with fake agents and fake commands.

    python -I _tools/test_goal_agent.py

The fixture (_tools/fixtures/goal/game/) is a tiny game and spec built so that change 1 is done (node present,
its tests green), change 2 is partial (node present, its test failing) and change 3 is missing (config key
absent, a node it removes still there, no tests). The loop tests copy it to a temp folder, point goal_agent
at it and replace run_agent, run_cmd (git and the check scripts), budget_ok and the run log with fakes, so no
Claude account, Godot or git is touched. What this proves is the script's logic, not the agents' code.
Standard library only.
"""
import contextlib
import io
import json
import re
import shutil
import sys
import tempfile
import time
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))  # -I leaves the script's folder off sys.path
import goal_agent as ga  # noqa: E402

FIX = TOOLS / "fixtures" / "goal"
SPEC = FIX / "game" / "specs" / "9.9-fixture.md"


def plan(ledger=None):
    spec = ga.parse_spec(SPEC)
    found = ga.scan(FIX / "game", ledger_path=FIX / "none.json")
    if ledger:
        found["ledger"] = {spec["file"]: {gid: {"run": "t"} for gid in ledger}}
    report = ga.gaps(spec, found)
    ranked, amb = ga.order(spec, report, {"Patricia": 8.0, "Bob": 5.0, "Quinn": 10.0})
    return spec, report, ranked, amb


class Parse(unittest.TestCase):
    def test_goals_from_changes_contract_and_quinn_lines(self):
        spec = ga.parse_spec(SPEC)
        self.assertEqual(list(spec["goals"]), ["H", "C1", "C2", "C3", "T1.1", "T3.1", "T.1"])
        g = spec["goals"]
        self.assertEqual(g["C3"]["keys"], ["frame_scale"])                 # the Config paragraph's key, by its words
        self.assertEqual(g["C3"]["removed"], ["OldBar"])
        self.assertEqual(g["C1"]["nodes"], ["FillNode"])
        self.assertEqual(g["C2"]["owners"], ["Bob"])
        self.assertEqual(g["C3"]["owners"], ["Patricia", "Bob"])
        self.assertEqual(g["C2"]["depends"], ["H"])                        # Bob's scenes wait on the handoff
        self.assertEqual(g["C1"]["depends"], [])                           # Patricia only: no handoff needed
        self.assertEqual(g["T1.1"]["depends"], ["C1"])                     # matched by its words (meter, fill)
        self.assertEqual(g["T3.1"]["depends"], ["C3"])                     # named: "item 3"
        self.assertEqual(g["T.1"]["depends"], ["C1", "C2", "C3"])          # mutations prove every new test
        self.assertEqual(spec["steps"], {"a": [1], "b": [2, 3]})
        self.assertEqual(g["C1"]["value"], ga.VALUE["playtest"])

    def test_a_replaced_node_must_be_gone_and_code_built_nodes_count(self):
        """0.2 C14/C15 stayed partial: `ShopScroll` came after "Replaces", `ShopButton` is named in shop_ui.gd."""
        with tempfile.TemporaryDirectory() as tmp:
            game = Path(tmp) / "game"
            shutil.copytree(FIX / "game", game)
            spec_path = game / "specs" / "9.9-fixture.md"
            text = spec_path.read_text(encoding="utf-8").replace(
                "The `FillNode` shows the hive's fill.",
                "The `FillNode` shows the hive's fill. Replaces the C1 hand fix (`OldScroll` one-row height).")
            spec_path.write_text(text, encoding="utf-8")
            (game / "scripts" / "built.gd").write_text('func _ready():\n\tvar b := Button.new()\n\tb.name = "CodeButton"\n',
                                                       encoding="utf-8")
            g = ga.parse_spec(spec_path)["goals"]
            self.assertEqual(g["C1"]["nodes"], ["FillNode"])               # before "Replaces": still wanted
            self.assertIn("OldScroll", g["C1"]["removed"])
            self.assertIn("CodeButton", ga.scan(game, ledger_path=Path(tmp) / "none.json")["nodes"])

    def test_item_numbers_outside_the_spec_are_ignored(self):
        changes = [(1, "Speed", "game speed row"), (2, "Camera", "camera stops")]
        self.assertEqual(ga.match_items("the speed row (report open item 6)", changes), [1])

    def test_item_ranges_and_sub_bullets_go_to_their_item(self):
        # 0.2: "Items 3–5: promote the picks." was read as item 3, and its sub-bullets were dropped
        self.assertEqual(ga.item_numbers("Items 3–5: promote the picks."), [3, 4, 5])
        self.assertEqual(ga.item_numbers("Items 2-6 and item 8"), [2, 3, 4, 5, 6, 8])
        body = ("- **Bob (`scenes/`):**\n  - Items 1–2: promote the picks.\n    - A new fork prop from the fork pick.\n"
                "    - The truck groups added to the truck.\n  - Item 1: the shop list.\n")
        self.assertEqual(ga.parse_contract(body)["Bob"], [
            ("line", "Items 1–2: promote the picks."), ("sub", "A new fork prop from the fork pick."),
            ("sub", "The truck groups added to the truck."), ("line", "Item 1: the shop list.")])

    def test_style_rows_only_for_files_the_step_changed(self):
        body = ("\n\n| # | Rule | Where | Finding | Fix |\n|---|---|---|---|---|\n"
                "| 1 | V4 | `scenes/props/honey_cell.tscn:5` | ArrayMesh | use a primitive |\n"
                "| 2 | V13 | 06-truck-away.png | truck under the panel | stop above it |\n"
                "| 3 | V2 | 04-fork.png | fork head glows | albedo only |\n")
        kept, dropped = ga.rows_in_scope(body, {"game/scenes/props/uncapping_fork.tscn"})
        self.assertEqual(dropped, 2)
        self.assertIn("fork head glows", kept)
        self.assertNotIn("honey_cell", kept)
        self.assertEqual(ga.rows_in_scope(body, {"game/scripts/main.gd"}), (None, 3))
        kept, _ = ga.rows_in_scope(body, {"game/scenes/props/honey_cell.tscn"})
        self.assertIn("honey_cell", kept)


class LiveLabels(unittest.TestCase):
    def test_check_commands_get_short_live_names_and_git_reads_none(self):
        py = [sys.executable, "-I"]
        self.assertEqual(ga.cmd_label(py + ["_tools/godot_run.py", "unit", "start", "--time-scale", "6"]),
                         "godot_run unit start")
        self.assertEqual(ga.cmd_label(py + ["_tools/mutate.py", "--since", "abc"]), "mutate abc")
        self.assertEqual(ga.cmd_label(["git", "commit", "-m", "x"]), "git commit")
        self.assertEqual(ga.cmd_label(["git", "rev-parse", "HEAD"]), "")


class Gaps(unittest.TestCase):
    def test_done_partial_missing_with_evidence(self):
        _, report, _, _ = plan()
        self.assertEqual(report["C1"]["status"], "done")
        self.assertEqual(report["C2"]["status"], "partial")
        self.assertEqual(report["C3"]["status"], "missing")
        self.assertEqual(report["H"]["status"], "missing")
        self.assertEqual(report["T1.1"]["status"], "done")
        ev = {e["name"]: e for e in report["C1"]["evidence"]}
        self.assertTrue(ev["t_meter_fill"]["ok"])
        self.assertEqual(ev["t_meter_wall_clock"]["result"], "x1, designer plays")   # skipped real-time test is no failure
        c3 = {e["name"]: e for e in report["C3"]["evidence"]}
        self.assertFalse(c3["frame_scale"]["ok"])
        self.assertFalse(c3["OldBar"]["ok"])                                # removed by the spec, still in the scene
        self.assertFalse(report["C2"]["waits_on_tests"])                    # its node may predate it: only the ledger says built

    def test_ledger_marks_a_built_goal(self):
        _, report, _, _ = plan(ledger=["H", "C3"])
        self.assertEqual(report["H"]["status"], "done")
        self.assertEqual(report["C3"]["status"], "partial")
        self.assertTrue(report["C3"]["waits_on_tests"])

    def test_new_quinn_line_is_not_done_on_its_items_old_tests(self):
        spec = ga.parse_spec(SPEC)
        found = ga.scan(FIX / "game", ledger_path=FIX / "none.json")
        new = dict(spec["goals"]["T1.1"], id="T1.2")                        # a later Quinn line on the same item
        spec["goals"]["T1.2"] = new
        found["ledger"] = {spec["file"]: {"T1.1": {"run": "t"}}}             # its sibling was built by the agent
        report = ga.gaps(spec, found)
        self.assertEqual(report["T1.2"]["status"], "partial")               # green item tests, but never built
        self.assertEqual(report["T1.1"]["status"], "done")
        self.assertEqual(plan(ledger=["T3.1"])[1]["T1.1"]["status"], "done")   # no ledgered sibling: old rule

    def test_marked_tests_are_a_lines_only_evidence(self):
        # 0.2: T1.1 rode with the mutations line, its group comment named every item, and all 12 lines read as done
        spec = ga.parse_spec(SPEC)
        found = ga.scan(FIX / "game", ledger_path=FIX / "none.json")
        found["marks"] = {"T1.1": ["t_meter_fill"]}                         # one line marked, the others not
        report = ga.gaps(spec, found)
        self.assertEqual(report["T1.1"]["status"], "done")
        self.assertEqual([e["name"] for e in report["T1.1"]["evidence"] if e["kind"] == "test"], ["t_meter_fill"])
        others = [g for g, x in spec["goals"].items() if x["kind"] == "test" and g != "T1.1"
                  and not re.search(r"mutation", x["text"], re.I)]
        self.assertTrue(others)
        for g in others:
            self.assertNotEqual(report[g]["status"], "done", g)             # no mark of its own: not built

    def test_a_built_test_goal_on_a_red_item_waits_instead_of_rebuilding(self):
        spec, report, ranked, _ = plan(ledger=["H", "C2", "T.1"])           # T.1's evidence has C2's failing test
        self.assertEqual(report["T.1"]["status"], "partial")
        self.assertTrue(report["T.1"]["waits_on_tests"])
        self.assertNotIn("T.1", [e["id"] for e in ranked])


class Score(unittest.TestCase):
    def test_weighted_sum_and_ready(self):
        spec, report, _, _ = plan()
        score, f = ga.priority_score(spec["goals"]["H"], report, spec["goals"], {"Patricia": 10.0})
        self.assertEqual(f["unblocks"], 2)                                  # C2 and C3 wait on it
        self.assertEqual(score, 2 * ga.WEIGHTS["unblocks"] + 1 * ga.WEIGHTS["value"] + 1.0 * ga.WEIGHTS["cost"])
        score, f = ga.priority_score(spec["goals"]["C3"], report, spec["goals"], {})
        self.assertEqual((score, f["ready"], f["blocked_by"]), (0, 0, ["H"]))

    def test_order_handoff_then_scenes_then_tests(self):
        _, _, ranked, amb = plan()
        ids = [e["id"] for e in ranked]
        self.assertEqual(ids[0], "H")
        self.assertLess(ids.index("H"), ids.index("C3"))
        self.assertLess(ids.index("C3"), ids.index("T3.1"))
        self.assertNotIn("C1", ids)                                         # done
        self.assertIn("C2", ids)                                            # partial and not in the ledger: still to build
        self.assertEqual(amb, [])
        _, _, ranked, _ = plan(ledger=["H"])
        self.assertEqual(ranked[0]["id"], "C3")
        _, _, ranked, _ = plan(ledger=["H", "C2", "C3"])
        self.assertEqual(ranked[0]["id"], "T3.1")

    def test_owner_costs_from_the_run_log(self):
        rows = [{"agent": "Patricia (programmer)", "five_hour_before": "10", "five_hour_after": "20"},
                {"agent": "Patricia (programmer)", "five_hour_before": "30", "five_hour_after": "34"},
                {"agent": "Bob (builder)", "five_hour_before": "", "five_hour_after": "5"}]
        c = ga.owner_costs(rows)
        self.assertEqual(c["Patricia"], 7.0)
        self.assertEqual(c["Bob"], ga.budget_guard.COST["builder"] / 2)    # no usable row: half the guard's worst case


class Loop(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(FIX / "game", self.tmp / "game")
        self.saved = {k: getattr(ga, k) for k in ("ROOT", "run_agent", "run_cmd", "budget_ok", "log_usage",
                                                  "change_snapshot", "file_diff")}
        ga.ROOT = self.tmp
        self.calls, self.cmds, self.check_codes, self.budget, self.idle = [], [], [], (True, "allow"), False
        self.turn_caps, self.logs, self.code_idle, self.scope_rows, self.outs = [], [], False, [], []
        self.snapshot, self.diffs = {}, {}                                  # L42: what the step changed, per path
        ga.run_agent = self.fake_agent
        ga.run_cmd = self.fake_cmd
        ga.change_snapshot = lambda: {p: list(v) for p, v in self.snapshot.items()}
        ga.file_diff = lambda path: self.diffs.get(path, "")
        ga.budget_ok = lambda agent: self.budget
        ga.log_usage = lambda usage, run: None

    def tearDown(self):
        for k, v in self.saved.items():
            setattr(ga, k, v)
        shutil.rmtree(self.tmp, ignore_errors=True)

    def fake_agent(self, agent, prompt, max_turns=None):
        self.calls.append((agent, prompt))
        self.turn_caps.append((agent, max_turns))
        if agent == ga.PROGRAMMER and "node handoff" in prompt:
            (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        return "done", {"tokens": 10, "turns": 1, "seconds": 1, "start": None, "end": None}

    def fake_cmd(self, cmd, env=None, timeout=0):
        self.cmds.append(cmd)
        if cmd[0] == "git":
            if cmd[1:3] == ["rev-parse", "--abbrev-ref"]:
                return 0, "milestone/9.9\n"
            if cmd[1:3] == ["rev-parse", "--short"]:
                return 0, "abc1234\n"
            if "-uall" in cmd:                                              # file_states: the scope check's view
                return 0, self.scope_rows.pop(0) if self.scope_rows else ""
            if cmd[1] in ("status", "diff"):                               # each agent call changes the tree, unless idle
                if self.code_idle and "game/tests" not in cmd:             # only tests change, never scripts or scenes
                    return 0, ""
                return 0, "" if self.idle else f" M game/scripts/x.gd {len(self.calls)}\n"
            return 0, ""
        if any("godot_run.py" in c for c in cmd) and self.logs:             # each test run writes a newer unit log
            d = self.tmp / "game" / "reports" / "_runs" / f"2100{len(self.cmds):06d}"
            d.mkdir(parents=True)
            (d / "unit.log").write_text(self.logs.pop(0), encoding="utf-8")
        out = self.outs.pop(0) if self.outs and any("godot_run.py" in c for c in cmd) else "FAIL  t_x  broken"
        return (self.check_codes.pop(0) if self.check_codes else 0), out

    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = ga.main(["9.9-fixture.md", "--run", "t", *args])
        board = self.tmp / "game" / "reports" / "goal" / "t" / "blackboard.md"
        return code, out.getvalue(), board.read_text(encoding="utf-8") if board.is_file() else None

    def test_plan_calls_no_agent(self):
        code, out, board = self.run_main("--plan")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("1. H", out)
        self.assertTrue((self.tmp / "game" / "reports" / "goal" / "t" / "gaps.json").is_file())
        self.assertIsNone(board)                                            # the console only: no board

    def test_dry_run_prints_briefs_and_spends_nothing(self):
        code, out, board = self.run_main("--dry-run")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("brief for Patricia", out)
        self.assertFalse(any(c[0] == "git" and c[1] in ("commit", "checkout") for c in self.cmds))
        self.assertIsNone(board)
        self.assertFalse((self.tmp / "game" / "reports" / "goal" / "t" / "briefs").exists())

    def test_one_green_step_commits_and_rescans(self):
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(code, 0)
        self.assertEqual([a for a, _ in self.calls], [ga.PROGRAMMER])
        ledger = json.loads((self.tmp / "game" / "reports" / "goal" / "ledger.json").read_text(encoding="utf-8"))
        self.assertEqual(ledger["9.9-fixture.md"]["H"]["commit"], "abc1234")
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))
        add = next(c for c in self.cmds if c[:2] == ["git", "add"])
        self.assertNotIn("-A", add)
        self.assertFalse(any("ledger.json" in p or "goal/t" in p for p in add))   # queue #5: state not in a goal commit
        self.assertIn("## Pass 2", board)                                   # re-scanned after the write
        self.assertIn("Next: **C3**", board.split("## Pass 2")[0] + "Next: **C3**")

    def test_the_run_state_is_one_commit_of_its_own_paths(self):
        folder = self.tmp / "game" / "reports" / "goal" / "t"
        folder.mkdir(parents=True)
        (folder / "blackboard.md").write_text("x", encoding="utf-8")
        ledger = folder.parent / "ledger.json"
        ledger.write_text("{}", encoding="utf-8")
        staged = lambda cmd, env=None, timeout=0: (self.cmds.append(cmd) or
                                                   ((1, "") if cmd[1:3] == ["diff", "--cached"] else self.fake_cmd(cmd)))
        ga.run_cmd = staged
        spec = {"version": "9.9"}
        self.assertEqual(ga.commit_state(spec, "t", folder, ledger, "done"), "state committed")
        commit = next(c for c in self.cmds if c[:2] == ["git", "commit"])
        self.assertIn("--only", commit)
        self.assertEqual(commit[commit.index("--") + 1:], ["game/reports/goal/ledger.json", "game/reports/goal/t"])
        ga.run_cmd = self.fake_cmd                                          # nothing staged: no commit
        self.cmds.clear()
        self.assertEqual(ga.commit_state(spec, "t", folder, ledger, "done"), "state unchanged")
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_step_builds_the_change_with_both_owners_in_parallel(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(sorted(a for a, _ in self.calls), [ga.BUILDER, ga.PROGRAMMER])
        pat = next(p for a, p in self.calls if a == ga.PROGRAMMER)
        self.assertIn("frame_scale", pat)
        self.assertIn("9.9-node-handoff.md", pat)
        self.assertNotIn("Speed tag moved", pat)                            # only its own change's slice
        self.assertTrue(any("ui_shots.py" in " ".join(c) for c in self.cmds))

    def test_a_picked_variant_is_matched_by_vera_and_a_mismatch_goes_to_bob(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        spec = self.tmp / "game" / "specs" / "9.9-fixture.md"
        spec.write_text(spec.read_text(encoding="utf-8").replace(
            "The frames scale up;", "The frames scale up; `scenes/props/hive.tscn` must match "
            "`scenes/variants/hive-frames/hive-frames-a.tscn`;"), encoding="utf-8")
        self.assertEqual(ga.parse_spec(spec)["goals"]["C3"]["picks"],
                         [("game/scenes/props/hive.tscn", "game/scenes/variants/hive-frames/hive-frames-a.tscn")])
        verdicts = ["### Critic, round 1\nVERDICT: FAIL\n| # | Rule | Shot | Finding | Fix |\n|---|---|---|---|---|\n"
                    "| 1 | pick | hive.png | pick has 5 upright frames, live has 2 flat | rebuild the frames |",
                    "### Critic, round 1\nVERDICT: PASS\n| # | Rule | Shot | Finding | Fix |\n|---|---|---|---|---|"]
        fake = self.fake_agent
        def agent(a, prompt, **_):
            if a == ga.CRITIC:
                self.calls.append((a, prompt))
                return verdicts.pop(0), {"tokens": 5, "turns": 1, "seconds": 1, "start": None, "end": None}
            return fake(a, prompt)
        ga.run_agent = agent
        code, out, board = self.run_main("--max-goals", "1")
        who = [a for a, _ in self.calls]
        self.assertEqual(who.count(ga.CRITIC), 2)
        self.assertEqual(who[who.index(ga.CRITIC) + 1], ga.BUILDER)          # the FAIL goes to Bob alone
        self.assertNotIn(ga.PROGRAMMER, who[who.index(ga.CRITIC):])
        bob_fix = [p for a, p in self.calls if a == ga.BUILDER][-1]
        self.assertIn("5 upright frames", bob_fix)
        self.assertIn("pick/C3/round-0/hive.png", bob_fix)
        self.assertTrue(any("style_loop.py" in " ".join(c) and "9.9-goal-c3" in c for c in self.cmds))
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))  # PASS in fix round 1: committed
        self.assertIn("Check `pick match`: PASS", board)

    def test_failed_checks_get_two_fix_rounds_then_stop(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [1, 1, 1]                                        # the contract check fails every round
        code, out, board = self.run_main()
        self.assertEqual(code, 1)
        self.assertEqual(len(self.calls), 2 + 2 * 1)                        # C3 owners, then two fix rounds of one owner each
        self.assertIn("fix round 2", self.calls[-1][1])
        self.assertNotEqual(self.calls[-2][0], self.calls[-1][0])           # round 2 goes to the other owner
        self.assertIn("You alone work this round", self.calls[-1][1])
        self.assertIn("Change only what a failing row names", self.calls[-1][1])
        self.assertEqual([t for _, t in self.turn_caps], [ga.BUILD_MAX_TURNS] * 2 + [ga.FIX_MAX_TURNS] * 2)   # build calls 30, fix rounds 15
        self.assertIn("Do not run the test suite", self.calls[-1][1])
        quinn = ga.briefs(ga.parse_spec(SPEC), ga.parse_spec(SPEC)["goals"]["T3.1"],
                          [ga.parse_spec(SPEC)["goals"]["T3.1"]], "t", "b")[ga.QA]
        self.assertIn("Do not run the tests", quinn)                        # Quinn writes; the goal agent runs
        self.assertNotIn("CB_ONLY=", quinn)
        for step in ("leave mid-way", "come back", "twice", "NOTIFICATION_APPLICATION_PAUSED", "do not guess",
                     "runs on its own", "automation upgrade", "never that it stopped"):
            self.assertIn(step, quinn)                                      # Quinn's interaction checklist
        self.assertIn("(cap 15; CLI num_turns 1)", board)                   # every call's command and turns logged
        self.assertIn(f"(cap {ga.BUILD_MAX_TURNS}; CLI num_turns 1)", board)   # build calls capped too (0.2 C3)
        self.assertIn("**Over the turn cap:** 16", ga.call_line({"turns": 17, "calls": 16, "cmd": "claude -p"}, 15))
        self.assertNotIn("Over", ga.call_line({"turns": 20, "calls": 10, "cmd": "claude -p"}, 15))  # num_turns isn't the cap's unit
        self.assertNotIn("Over", ga.call_line({"turns": 20, "cmd": "claude -p"}, 15))   # no transcript: no claim
        self.assertIn("## Waiting for the designer\n\n2 fix rounds failed on C3", board)
        self.assertIn("result: waiting-designer", board)
        self.assertIn("_tools/checkpoint.py \"C3 fix-round edits\"", board)   # the edits are kept, not lost (L1)
        self.assertIn("briefs/C3-fix2-", board)                            # fix briefs go by reference too
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def fail_first_fixture(self):
        """T3.1 becomes a play-test bug line, C3 and the handoff are built, Quinn's test is marked `# goal T3.1`."""
        game = self.tmp / "game"
        (game / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        spec = game / "specs" / "9.9-fixture.md"
        spec.write_text(spec.read_text(encoding="utf-8").replace(
            "item 3: the frames scale", "item 3 (shown failing on the current build): the frames scale"), encoding="utf-8")
        (game / "reports" / "goal").mkdir(parents=True, exist_ok=True)
        (game / "reports" / "goal" / "ledger.json").write_text(json.dumps(
            {"9.9-fixture.md": {"H": {"run": "t"}, "C3": {"run": "t"}}}), encoding="utf-8")
        (game / "tests" / "test_frames.gd").write_text("# goal T3.1\nfunc t_frames_scale() -> void:\n\tpass\n",
                                                       encoding="utf-8")

    def test_a_bug_test_that_passes_first_goes_back_to_quinn_alone(self):
        self.fail_first_fixture()
        self.check_codes = [0, 0, 0, 0, 1, 1, 0, 0, 0, 0]                   # round 0 green, 1 red (rerun red), 2 green, gate
        self.logs = ["PASS  t_frames_scale  (3 checks, 5 ms)\n",
                     "FAIL  t_frames_scale  frames 1.0, expected 2.0  (5 ms)\n", "FAIL  t_x  broken  (5 ms)\n",
                     "PASS  t_frames_scale  (3 checks, 5 ms)\n"]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn("Check `fail-first`: FAIL (T3.1 not shown failing)", board)
        fix1 = [a for a, p in self.calls if "fix round 1" in p]
        self.assertEqual(fix1, [ga.QA])                                     # nothing to fix until the bug shows
        self.assertIn("does not reproduce it", next(p for a, p in self.calls if "fix round 1" in p))
        self.assertIn("Check `fail-first`: PASS (T3.1 shown failing)", board)
        self.assertEqual(len([a for a, p in self.calls if "fix round 2" in p]), 1)   # one code owner per round
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_real_time_bug_test_is_run_alone_at_x1(self):
        self.fail_first_fixture()                                           # T14.5: an X1 test the x6 run skips
        (self.tmp / "game" / "tests" / "test_frames.gd").write_text(
            "# goal T3.1\nfunc t_meter_wall_clock() -> void:\n\tpass\n", encoding="utf-8")
        envs = []
        fake = self.fake_cmd
        def cmd(c, env=None, timeout=0):
            envs.append(env)
            return fake(c, env, timeout)
        ga.run_cmd = cmd
        self.check_codes = [0, 0, 0, 1, 0, 0, 0, 0]                         # x1 red in round 0, green after the fix
        only = "CB_ONLY: running 1 test(s): [t_meter_wall_clock]\n"
        self.logs = ["PASS  t_meter_fill  (5 ms)\n", only + "FAIL  t_meter_wall_clock  lid sinks 0.015  (5 ms)\n",
                     "PASS  t_meter_fill  (5 ms)\n", only + "PASS  t_meter_wall_clock  (5 ms)\n"]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn({"CB_ONLY": "t_meter_wall_clock", "CB_TIME_SCALE": "1"}, envs)
        self.assertIn("Check `x1 tests` (t_meter_wall_clock): FAIL", board)
        self.assertIn("Check `fail-first`: PASS (T3.1 shown failing)", board)
        self.assertEqual([a for a, p in self.calls if "fix round 1" in p], [ga.PROGRAMMER])   # odd round, no file named
        self.assertIn("Check `x1 tests` (t_meter_wall_clock): PASS", board)
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))
        newest = ga.newest_unit_log(self.tmp / "game")                      # the scan skips the x1 check's log
        self.assertNotIn("CB_ONLY", newest.read_text(encoding="utf-8"))
        self.assertIn("CB_ONLY", ga.newest_unit_log(self.tmp / "game", partial=True).read_text(encoding="utf-8"))

    def test_the_scan_takes_each_tests_newest_result_across_only_logs(self):
        """Obstacles item 23: a newer `--only` PASS overrides the full log's FAIL; a partial log older than the
        newest full log is not read."""
        runs = self.tmp / "game" / "reports" / "_runs"
        logs = {"20990101-000001": "CB_ONLY: running t_a\nFAIL  t_a  old\n",
                "20990101-000002": "PASS  t_b  (1 ms)\nFAIL  t_a  stale\n",
                "20990101-000003": "CB_ONLY: running t_a\nPASS  t_a  (1 ms)\n"}
        for name, text in logs.items():
            (runs / name).mkdir(parents=True)
            (runs / name / "unit.log").write_text(text, encoding="utf-8")
        self.assertEqual(ga.unit_results(self.tmp / "game"), {"t_a": "PASS", "t_b": "PASS"})
        (runs / "20990101-000003" / "unit.log").unlink()
        self.assertEqual(ga.unit_results(self.tmp / "game")["t_a"], "FAIL")

    def test_tests_already_written_skip_quinn_and_go_to_the_code_owners(self):
        self.fail_first_fixture()                                           # test_frames.gd marks T3.1 already
        self.check_codes = [0, 1, 1, 0, 0, 0, 0]                            # t_x red again on its rerun: not flaky
        self.logs = ["FAIL  t_frames_scale  frames 1.0, expected 2.0  (5 ms)\n", "FAIL  t_x  broken  (5 ms)\n",
                     "PASS  t_frames_scale  (5 ms)\n"]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn("Quinn's step skipped", board)
        self.assertNotIn(ga.QA, [a for a, _ in self.calls])
        self.assertEqual([a for a, _ in self.calls], [ga.PROGRAMMER])         # one owner per fix round
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_script_stop_is_not_the_bug_showing(self):
        self.fail_first_fixture()
        self.logs = ["FAIL  t_frames_scale  test stopped before its final line (script error)  (5 ms)\n"]
        self.check_codes = [0, 1]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn("Check `fail-first`: FAIL", board)

    def test_a_bug_fixed_with_only_test_changes_is_held(self):
        self.fail_first_fixture()
        self.code_idle = True                                               # T14.3: the lid test, no lid change
        self.check_codes = [0, 1, 1, 0, 0, 0, 0]
        self.logs = ["FAIL  t_frames_scale  frames 1.0, expected 2.0  (5 ms)\n", "FAIL  t_x  broken  (5 ms)\n",
                     "PASS  t_frames_scale  (5 ms)\n"]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn("only tests changed", board)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))
        ledger = json.loads((self.tmp / "game" / "reports" / "goal" / "ledger.json").read_text(encoding="utf-8"))
        self.assertIn("held", ledger["9.9-fixture.md"]["T3.1"])

    def test_green_with_no_change_is_held_not_committed(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.idle = True                                                    # 0.1.4 C7: the agents changed nothing
        code, out, board = self.run_main()
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))
        ledger = json.loads((self.tmp / "game" / "reports" / "goal" / "ledger.json").read_text(encoding="utf-8"))
        first = next(gid for gid, e in ledger["9.9-fixture.md"].items())
        self.assertIn("held", ledger["9.9-fixture.md"][first])
        self.assertIn("**Held:**", board)
        self.assertIn("result: waiting-designer", board)                    # every change held: the designer answers
        steps = [l for l in board.splitlines() if l.startswith("### Step:")]
        self.assertEqual(len(steps), len(set(steps)))                       # a held goal is not retried in the same run

    def test_a_held_goal_waits_until_its_spec_text_changes(self):
        spec = ga.parse_spec(SPEC)
        found = ga.scan(FIX / "game", ledger_path=FIX / "none.json")
        c3 = spec["goals"]["C3"]
        found["ledger"] = {spec["file"]: {"C3": {"run": "t", "held": "changed nothing", "text": ga.text_hash(c3)}}}
        report = ga.gaps(spec, found)
        self.assertTrue(report["C3"]["ambiguous"])
        self.assertFalse(report["C3"]["built"])
        self.assertIn("changed nothing", report["C3"]["questions"])
        found["ledger"][spec["file"]]["C3"]["text"] = "an older text"     # the designer edited the item: build it again
        report = ga.gaps(spec, found)
        self.assertFalse(report["C3"]["ambiguous"])
        self.assertFalse(report["C3"]["built"])

    def test_a_failing_old_test_after_a_change_also_goes_to_quinn(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [0, 1, 1]                                        # contract passes, the suite fails (rerun too)
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(code, 0)
        fix = [a for a, p in self.calls if "fix round 1" in p]
        self.assertEqual(sorted(fix), sorted([ga.PROGRAMMER, ga.QA]))      # one code owner, plus Quinn's own folder
        self.assertIn("quote the spec line", next(p for a, p in self.calls if a == ga.QA))

    def test_checkpoint_commits_wip_on_main_never_detached(self):
        import checkpoint, subprocess
        repo = self.tmp / "repo"
        (repo / "game" / "scripts").mkdir(parents=True)
        run = lambda *a: subprocess.run(["git", *a], cwd=repo, capture_output=True, text=True)
        run("init", "-q"); run("symbolic-ref", "HEAD", "refs/heads/main")   # `init -b` needs git 2.28+
        run("config", "user.email", "t@t"); run("config", "user.name", "t")
        (repo / "README.md").write_text("r\n", encoding="utf-8")
        run("add", "README.md"); run("commit", "-q", "-m", "first")           # a branch needs a commit to leave
        (repo / "game" / "scripts" / "a.gd").write_text("x\n", encoding="utf-8")
        (repo / "game" / "project.godot").write_text('[application]\nconfig/version="9.9.3"\n', encoding="utf-8")
        said = io.StringIO()
        with contextlib.redirect_stdout(said):
            run("checkout", "-q", "--detach")
            self.assertEqual(checkpoint.main(["wip"], root=repo), 2)               # detached: refused
            run("checkout", "-q", "main")
            log = repo / "game" / "reports" / "_runs" / "1" / "unit.log"
            log.parent.mkdir(parents=True)
            log.write_text("PASS  t_a  (1 ms)\nFAIL  t_b  no  (1 ms)\n", encoding="utf-8")
            code = checkpoint.main(["lid edits"], root=repo)
        self.assertEqual(code, 0, said.getvalue())
        subject = run("log", "-1", "--format=%s").stdout.strip()
        self.assertEqual(subject, "9.9 checkpoint: lid edits (WIP, 1 unit fails)")
        self.assertNotIn("reports", run("show", "--name-only", "--format=").stdout)  # reports stay out
        self.assertEqual(run("rev-parse", "--abbrev-ref", "HEAD").stdout.strip(), "main")

    def test_checkpoint_label_counts_newer_only_runs(self):
        """L47: a green full run followed by an `--only` run with red tests is not "unit green"."""
        import checkpoint
        runs = self.tmp / "lbl" / "game" / "reports" / "_runs"
        for stamp, text in (("1", "PASS  t_a  (1 ms)\nPASS  t_b  (1 ms)\n"),
                            ("2", "CB_ONLY: running 1\nFAIL  t_b  no  (1 ms)\n")):
            (runs / stamp).mkdir(parents=True)
            (runs / stamp / "unit.log").write_text(text, encoding="utf-8")
        passed, failed, source = checkpoint.unit_counts(self.tmp / "lbl")
        self.assertEqual((passed, failed), (1, 1))
        self.assertIn("1 newer --only run", source)
        self.assertIn("WIP, 1 unit fails", checkpoint.message("9.9", "x", (passed, failed, source)))
        (runs / "3").mkdir()
        (runs / "3" / "unit.log").write_text("CB_ONLY: running 1\nPASS  t_b  (1 ms)\n", encoding="utf-8")
        self.assertIn("unit green", checkpoint.message("9.9", "x", checkpoint.unit_counts(self.tmp / "lbl")))

    def test_one_owner_follows_the_folder_the_failure_names(self):
        self.assertEqual(ga.one_owner("FAIL lid clips; see scenes/props/hive.tscn", 1), ga.BUILDER)
        self.assertEqual(ga.one_owner("error at scripts/lid_motion.gd:40", 2), ga.PROGRAMMER)
        self.assertEqual([ga.one_owner("FAIL t_x broken", r) for r in (1, 2, 3)],
                         [ga.PROGRAMMER, ga.BUILDER, ga.PROGRAMMER])        # no folder named: they take turns

    def test_out_of_scope_names_files_outside_the_round_owners_folders(self):
        before = {"game/scripts/lid_motion.gd": "a", "game/scenes/hive.tscn": "b"}
        after = {"game/scripts/lid_motion.gd": "c", "game/scenes/hive.tscn": "d", "game/tests/t.gd": "e"}
        self.assertEqual(ga.out_of_scope(before, after, [ga.BUILDER]),
                         ["game/scripts/lid_motion.gd", "game/tests/t.gd"])
        self.assertEqual(ga.out_of_scope(before, after, [ga.PROGRAMMER, ga.QA]), ["game/scenes/hive.tscn"])

    def test_a_fix_round_that_strays_gets_a_scope_row_next_round(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [1, 0, 0, 0]                                     # contract fails once, then green
        self.scope_rows = ["", " M game/tests/test_frames.gd\n"]            # before and after fix round 1
        code, out, board = self.run_main("--max-goals", "1")
        self.assertIn("Check `scope`: FAIL (`game/tests/test_frames.gd` changed outside", board)
        fix2 = next(p for a, p in self.calls if "fix round 2" in p)
        self.assertIn("changed these files outside its folder: `game/tests/test_frames.gd`", fix2)

    def test_a_crashed_agent_is_recorded_as_failed(self):
        def crash(agent, prompt, **_):
            raise ga.g.AgentError("simulated CLI failure")
        ga.run_agent = crash
        with self.assertRaises(ga.g.AgentError), contextlib.redirect_stdout(io.StringIO()):
            ga.main(["9.9-fixture.md", "--run", "t"])
        board = (self.tmp / "game" / "reports" / "goal" / "t" / "blackboard.md").read_text(encoding="utf-8")
        self.assertIn("## Result", board)
        self.assertIn("failed (AgentError", board.split("## Result")[-1])
        self.assertFalse((self.tmp / "game" / "reports" / "goal" / "ledger.json").is_file())

    def test_accept_records_a_manual_fix_and_commits(self):
        code, out, board = self.run_main("--accept", "C3", "--note", "widened the test's tolerance")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("Manual fix: C3", board)
        ledger = json.loads((self.tmp / "game" / "reports" / "goal" / "ledger.json").read_text(encoding="utf-8"))
        self.assertIn("C3", ledger["9.9-fixture.md"])
        self.assertEqual(self.run_main("--accept", "C3")[0], 2)            # a note is required

    def test_budget_guard_pauses_never_skips(self):
        self.budget = (False, "Budget guard: 5-hour usage is 90%")
        code, out, board = self.run_main()
        self.assertEqual((code, self.calls), (1, []))
        self.assertIn("**Paused:**", board)
        self.assertIn("Result", board)

    def test_ambiguous_goal_is_skipped_then_stops_the_run(self):
        spec = self.tmp / "game" / "specs" / "9.9-fixture.md"
        spec.write_text(spec.read_text(encoding="utf-8").replace("The frames scale up;", "The frames scale up (TBD);"),
                        encoding="utf-8")
        code, out, board = self.run_main()
        self.assertEqual(code, 1)
        self.assertEqual([a for a, _ in self.calls][0], ga.PROGRAMMER)       # the handoff first
        self.assertFalse(any(", goal C3" in p for _, p in self.calls))      # no step ever builds C3
        self.assertIn("Ambiguous", board)
        self.assertIn("## Result", board)
        self.assertIn("waiting-designer", board.split("## Result")[-1])

    def test_open_question_in_the_handoff_holds_its_change(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text(
            "# handoff\n\n## Open questions\n1. The bigger frames don't fit the body: which scale?\n"
            "2. Tag font (answered: 28).\n", encoding="utf-8")
        spec = ga.parse_spec(self.tmp / "game" / "specs" / "9.9-fixture.md")
        report = ga.gaps(spec, ga.scan(self.tmp / "game"))
        self.assertTrue(report["C3"]["ambiguous"])
        self.assertEqual(len(report["C3"]["questions"]), 1)                  # the answered one no longer holds it
        self.assertFalse(report["C2"]["ambiguous"])

    def test_board_format_one_result_across_invocations(self):
        self.run_main("--plan")                                             # leaves no trace on the board
        code, out, board = self.run_main("--max-goals", "1")
        self.assertTrue(board.startswith("---\nspec: 9.9-fixture.md\n"))
        self.assertIn("result: stopped", board)
        self.assertIn("## Request", board)
        self.assertIn("## Pass 1:", board)
        self.assertNotIn("## Pass 3", board)                                # the --plan pass was not written
        pass2 = board.split("## Pass 2")[1].split("\n## ")[0]
        self.assertIn("Only what changed since the last pass", pass2)
        self.assertIn("| H Node", pass2)                                     # H is now done: its row changed
        self.assertNotIn("| T1.1", pass2.split("### Order")[0])             # an unchanged gap is left out
        code, out, board = self.run_main("--max-goals", "1", "--note", "frames: 1.35x")
        self.assertIn("## Resumed", board)
        self.assertIn("Designer's answer: frames: 1.35x", board)
        self.assertEqual(board.count("## Result"), 1)
        self.assertGreater(board.index("## Result"), board.index("## Resumed"))
        result = board.split("## Result")[1]
        self.assertEqual(result.count("| Patricia, ") + result.count("| Bob, "), len(self.calls))   # both invocations

    def test_unapproved_spec_is_refused(self):
        spec = self.tmp / "game" / "specs" / "9.9-fixture.md"
        spec.write_text(spec.read_text(encoding="utf-8").replace("status: approved", "status: draft"), encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ga.main(["9.9-fixture.md", "--run", "t", "--plan"]), 2)

    def impact_fixture(self):
        """C3 (key frame_scale, removes OldBar) is read by one unit test and one play-suite helper."""
        game = self.tmp / "game"
        (game / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        (game / "tests" / "test_frames.gd").write_text(
            'func t_old_bar() -> void:\n\tvar n = m.get_node("OldBar")\n\n'
            "func t_untouched() -> void:\n\t# OldBar was here\n\tpass\n", encoding="utf-8")
        (game / "tests" / "play_loop.gd").write_text("func _round() -> void:\n\tprint(cfg.frame_scale)\n", encoding="utf-8")
        (game / "tests" / "round6_shots.gd").write_text("func _s() -> void:\n\tprint(cfg.frame_scale)\n", encoding="utf-8")

    def test_the_impact_list_briefs_quinn_beside_the_build(self):
        """L39 (b): existing tests reading what a change touches go to Quinn in the build step, and a windowed suite
        on the list runs with unit in that step's check (c)."""
        self.impact_fixture()
        goal = ga.parse_spec(self.tmp / "game" / "specs" / "9.9-fixture.md")["goals"]["C3"]
        self.assertEqual(ga.test_impact(goal), [("tests/play_loop.gd", "_round", "play", ["frame_scale"]),
                                                ("tests/test_frames.gd", "t_old_bar", "unit", ["OldBar"])])   # no shot script, no comment
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(sorted(a for a, _ in self.calls), sorted([ga.BUILDER, ga.PROGRAMMER, ga.QA]))
        quinn = next(p for a, p in self.calls if a == ga.QA)
        for text in ("`t_old_bar` (OldBar)", "[play]", "quote the spec line", "Test rules (L39)", "viewport_width"):
            self.assertIn(text, quinn)
        self.assertNotIn("t_untouched", quinn)
        test_cmd = next(c for c in self.cmds if any("godot_run.py" in x for x in c))
        self.assertEqual(test_cmd[-8:], ["unit", "start", "play", *ga.ONLY_FLAGS, "--only", "t_old_bar"])   # L40, L41
        self.assertIn("--refresh", test_cmd)   # L48: a step's new class_name or CSV key needs the import rebuilt
        gate = [c for c in self.cmds if any("godot_run.py" in x for x in c) and "--only" not in c]
        self.assertEqual([c[-4:] for c in gate], [ga.FULL_SUITE])            # L42: no step gate; the run's end, once

    def test_no_impact_no_quinn_call(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.run_main("--max-goals", "1")
        self.assertNotIn(ga.QA, [a for a, _ in self.calls])

    def suite_board(self):
        spec = ga.parse_spec(self.tmp / "game" / "specs" / "9.9-fixture.md")
        folder = self.tmp / "game" / "reports" / "goal" / "t"
        ga.board_start(folder / "blackboard.md", spec, "t", "goal_agent.py test")
        return spec, folder, folder / "blackboard.md"

    def test_full_suite_red_gets_one_quinn_round_then_commits(self):
        """L39 (c): the end of a run runs every suite; a red one goes to Quinn once, and a green rerun is committed."""
        spec, folder, board = self.suite_board()
        self.check_codes = [1, 0]
        self.assertEqual(ga.final_suite(spec, "t", folder, board, []), "done")
        suite = [c for c in self.cmds if any("godot_run.py" in x for x in c)]
        self.assertEqual([c[-4:] for c in suite], [ga.FULL_SUITE] * 2)
        self.assertEqual([a for a, _ in self.calls], [ga.QA])
        self.assertIn("Test rules (L39)", self.calls[0][1])
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))
        self.assertIn("briefs/suite-fix1-quinn.md", board.read_text(encoding="utf-8"))

    def test_full_suite_red_twice_waits_for_the_designer(self):
        spec, folder, board = self.suite_board()
        self.check_codes = [1, 1]
        self.assertEqual(ga.final_suite(spec, "t", folder, board, []), "waiting-designer")
        self.assertEqual(len(self.calls), 1)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))
        self.assertIn("full suite is red after Quinn's round", board.read_text(encoding="utf-8"))

    def written_fixture(self):
        """H and C3 built, T3.1's test written and marked (no `shown failing`): the step goes straight to the checks."""
        game = self.tmp / "game"
        (game / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        (game / "reports" / "goal").mkdir(parents=True, exist_ok=True)
        (game / "reports" / "goal" / "ledger.json").write_text(json.dumps(
            {"9.9-fixture.md": {"H": {"run": "t"}, "C3": {"run": "t"}}}), encoding="utf-8")
        (game / "tests" / "test_frames.gd").write_text("# goal T3.1\nfunc t_frames_scale() -> void:\n\tpass\n",
                                                       encoding="utf-8")

    def godot_cmds(self):
        return [c for c in self.cmds if any("godot_run.py" in x for x in c)]

    def test_a_fix_round_runs_its_own_and_failed_tests_then_the_full_suite_once(self):
        """L40 (item 18): T12.1 ran ~200 tests three times; a round now runs `--only` its own tests and last round's
        failures. L42: no full unit gate per step; every suite runs once, at the run's end."""
        self.written_fixture()
        self.check_codes = [0, 1, 1, 0, 0, 0, 0]                            # r0: t_x red (rerun red); r1 green; suite
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        runs = self.godot_cmds()
        only = [c[c.index("--only") + 1] for c in runs if "--only" in c]
        self.assertEqual(only, ["t_frames_scale", "t_x", "t_frames_scale,t_x"])   # round 0, the rerun, round 1
        self.assertEqual([c[-4:] for c in runs if "--only" not in c], [ga.FULL_SUITE])   # the run's end, once
        self.assertNotIn("Check `full unit`", board)
        self.assertIn("Check `full suite`: PASS", board)
        self.assertIn("- Tests this round (2): own (1): `t_frames_scale`; last failures (1): `t_x`", board)
        self.assertEqual([a for a, p in self.calls if "fix round 1" in p], [ga.PROGRAMMER])
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_green_full_run_newer_than_every_change_is_reused_at_the_end(self):
        """L42: the end-of-run check reuses an `all` run that is green in every suite and newer than every change."""
        import os
        self.written_fixture()
        run = self.tmp / "game" / "reports" / "_runs" / "20991231-000000"
        run.mkdir(parents=True)
        for s in ga.FULL_LOGS:
            (run / f"{s}.log").write_text("" if s == "start" else "PASS  t_frames_scale  (5 ms)\n---- 1 passed, 0 failed\n",
                                          encoding="utf-8")
        self.assertEqual(ga.fresh_green_full(), run / "unit.log")
        spec, folder, board = self.suite_board()
        self.assertEqual(ga.final_suite(spec, "t", folder, board, []), "done")
        self.assertIn("Check `full suite`: PASS (reused `game/reports/_runs/20991231-000000`",
                      board.read_text(encoding="utf-8"))
        self.assertEqual(self.godot_cmds(), [])                              # no second full run
        (run / "play.log").unlink()                                          # a unit-only run is not a full one
        self.assertIsNone(ga.fresh_green_full())
        (run / "play.log").write_text("FAIL  loop  no\n---- 5 checks, 1 failed\n", encoding="utf-8")
        self.assertIsNone(ga.fresh_green_full())                             # red in any suite: never reused
        (run / "play.log").write_text("---- 5 checks, 0 failed\n", encoding="utf-8")
        later = datetime_after(run.name)
        os.utime(self.tmp / "game" / "tests" / "test_frames.gd", (later, later))   # a build file changed since
        self.assertIsNone(ga.fresh_green_full())

    def test_a_test_that_passes_alone_on_rerun_is_flaky_not_a_fix_round(self):
        """Item 11: T11.1's two timing tests cost 2 fix rounds."""
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [0, 1, 0]                                        # contract, tests red, the rerun green
        code, out, board = self.run_main("--max-goals", "1")
        self.assertIn("Flaky: `t_x` failed, then passed alone on one rerun", board)
        self.assertFalse([p for _, p in self.calls if "fix round" in p])
        rerun = self.godot_cmds()[1]
        self.assertEqual(rerun[rerun.index("--only"):], ["--only", "t_x", *ga.ONLY_FLAGS])
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))
        board_file = self.tmp / "b.md"
        self.cmds.clear()
        self.assertEqual(ga.rerun_flaky("FAIL  t_frames_scale  no", ["t_frames_scale"], board_file), set())
        self.assertEqual(self.cmds, [])                                     # the goal's own test: never rerun
        out = ("FAIL    unit      9 passed, 1 failed  (exit 1)  game/reports/_runs/1/unit.log\n    FAIL  t_a  no\n"
               "FAIL    start     no total line  (exit 1)\n")
        self.assertEqual(ga.failing_tests(out), (["t_a"], False))           # a start failure can't be rerun by name
        self.assertEqual(ga.failing_tests(out.replace("FAIL    start", "PASS    start")), (["t_a"], True))
        self.assertEqual(ga.failing_tests(out.replace("FAIL    start     no total line  (exit 1)",
                                                      "    ... 3 more FAIL lines in the log"))[1], False)

    def test_a_fix_round_that_changes_a_visual_number_stops_for_a_vote(self):
        """Item 12: Bob shrank the shop rows 120 -> 64 px and fonts 28 -> 24 in a fix round, with no vote."""
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        scene = self.tmp / "game" / "scenes" / "main.tscn"
        fake = self.fake_agent
        def agent(a, prompt, max_turns=None):
            if "fix round 1" in prompt:
                scene.write_text(scene.read_text(encoding="utf-8") + "custom_minimum_size = Vector2(0, 64)\n",
                                 encoding="utf-8")
            return fake(a, prompt, max_turns)
        ga.run_agent = agent
        self.check_codes = [1]                                              # the contract fails: one fix round
        code, out, board = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("Never change a visual number", next(p for _, p in self.calls if "fix round 1" in p))
        self.assertIn("Check `visual numbers`: STOP (1 for the designer)", board)
        self.assertIn("Design Votes page (`_tools/compare_page.py add`)", board)
        self.assertIn("`game/scenes/main.tscn`: `(none)` -> `custom_minimum_size = Vector2(0, 64)`", board)
        self.assertIn("result: waiting-designer", board)
        self.assertFalse([p for _, p in self.calls if "fix round 2" in p])
        before = {"game/scenes/shop.tscn": ["theme_override_font_sizes/font_size = 28"]}
        after = {"game/scenes/shop.tscn": ["theme_override_font_sizes/font_size = 24"]}
        self.assertEqual(len(ga.visual_changes(before, after, "the shop rows")), 1)
        self.assertEqual(ga.visual_changes(before, after, "fonts drop to 24 px"), [])   # the spec named it
        for line in ("custom_minimum_size = Vector2(0, 120)", "offset_top = -4.0", "@export var row_height: float = 120.0",
                     "label.add_theme_font_size_override(\"font_size\", 24)", "scale = Vector3(1, 1, 1)"):
            self.assertTrue(ga.VISUAL.search(line), line)
        for line in ("spigot_flow_cut_per_level = 0.08", "if items.size() > 0:", "transform = Transform3D(1, 0, 0)"):
            self.assertFalse(ga.VISUAL.search(line), line)

    def test_a_designer_row_in_a_fix_reply_stops_for_a_vote(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        fake = self.fake_agent
        def agent(a, prompt, max_turns=None):
            reply, u = fake(a, prompt, max_turns)
            return ("- Row height: A: keep 120 px; B: 64 px (designer)" if "fix round" in prompt else reply), u
        ga.run_agent = agent
        self.check_codes = [1]
        code, out, board = self.run_main()
        self.assertIn("| 1 | ", board.split("## Waiting for the designer")[1])
        self.assertIn("Row height: A: keep 120 px; B: 64 px (designer)", board)
        self.assertIn("result: waiting-designer", board)

    def net_errors(self, n):
        fake, left = self.fake_agent, [n]
        def agent(a, prompt, max_turns=None):
            if left[0]:
                left[0] -= 1
                raise ga.g.AgentError("programmer reported an error: API Error: Can't reach the API server — check "
                                      "your internet or DNS (ENOTFOUND)")
            return fake(a, prompt, max_turns)
        ga.run_agent = agent

    def test_a_network_error_is_retried_once(self):
        self.net_errors(1)
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(code, 0)
        self.assertIn("transient error", board)
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_network_error_twice_pauses_the_run_not_fails_it(self):
        """Run 0.2 ended `failed` on ENOTFOUND (240952d); a rerun resumes it."""
        self.net_errors(2)
        code, out, board = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("**Paused:** Patricia:", board)
        self.assertIn("result: paused", board)
        self.assertNotIn("failed (", board)

    def test_goal_list_skips_done_goals_and_builds_the_rest_in_order(self):
        """Item 8: `--goal X` on a goal the scan counts done exited 1 and broke the operator's per-goal loop."""
        code, out, board = self.run_main("--goal", "C1")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("goal_agent: C1 is already done; skipped", out)
        code, out, board = self.run_main("--goal", "C1,H")
        self.assertEqual(code, 0)
        self.assertEqual([a for a, _ in self.calls], [ga.PROGRAMMER])       # H only, then the list is done
        self.assertIn("stopped after 1 goal(s) (--goal list done)", board)
        self.assertEqual(self.run_main("--goal", "C9")[0], 2)               # not a goal of the spec

    TIMEOUT = "TIMEOUT unit      no total line  (exit None, 0 noise lines dropped)  game/reports/_runs/1/unit.log\n"

    def test_a_timeout_with_no_failing_test_is_retried_once_then_pauses(self):
        """L41: T10.1's full unit run hit the 15 min cap twice, all green, and each TIMEOUT started a fix round."""
        self.written_fixture()
        self.check_codes, self.outs = [0, 1, 1], [self.TIMEOUT, self.TIMEOUT]   # contract; tests cut twice
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertEqual(code, 1)
        self.assertIn("TIMEOUT with no failing test; retrying once", board)
        self.assertIn("**Paused:** `tests` timed out twice with no failing test", board)
        self.assertIn("result: paused", board)
        self.assertFalse([p for _, p in self.calls if "fix round" in p])
        runs = self.godot_cmds()
        self.assertEqual(len(runs), 2)
        self.assertTrue(all(c[c.index("--time-scale"):c.index("--time-scale") + 3] == ga.ONLY_FLAGS for c in runs))

    def test_a_timeout_then_green_on_the_retry_goes_on(self):
        self.written_fixture()
        self.check_codes, self.outs = [0, 1, 0], [self.TIMEOUT, "PASS  t_frames_scale"]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertIn("retrying once", board)
        self.assertNotIn("**Paused:**", board)
        self.assertFalse([p for _, p in self.calls if "fix round" in p])
        self.assertIn("Check `tests`: PASS", board)
        self.assertNotIn("full unit", board)                                # L42: no step gate after it

    def test_a_green_step_runs_no_full_unit_gate(self):
        """L42: T9.1's step spent its wall time on ~220 tests; a green round goes straight to the checkpoint."""
        self.written_fixture()
        self.check_codes = [0, 0, 0]                                         # contract, tests, mutations
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        self.assertEqual([c for c in self.godot_cmds() if "--only" not in c], [])
        self.assertNotIn("full unit", board)

    def test_a_timeout_with_a_failing_test_still_gets_a_fix_round(self):
        self.assertTrue(ga.timed_out(self.TIMEOUT))
        self.assertTrue(ga.timed_out("timed out after 3600 s"))              # run_cmd's own cut
        self.assertFalse(ga.timed_out(self.TIMEOUT + "    FAIL  t_a  expected 3, got 2\n"))
        self.assertFalse(ga.timed_out("FAIL    unit      9 passed, 1 failed  (exit 1)\n    FAIL  t_a  no\n"))
        spec, folder, board = self.suite_board()                             # the end-of-run suite: no Quinn round
        self.check_codes, self.outs = [1, 1], [self.TIMEOUT, self.TIMEOUT]
        self.assertEqual(ga.final_suite(spec, "t", folder, board, []), "paused")
        self.assertEqual(self.calls, [])

    def test_godot_run_unit_timeout_follows_the_test_count_within_a_cap(self):
        """L41: a flat 900 s cut the 218-test unit suite at 198 passed."""
        import godot_run
        root = self.tmp / "game"
        tests = root / "tests"
        for f in tests.glob("test_*.gd"):
            f.unlink()
        (tests / "test_a.gd").write_text("func t_one():\n\tpass\nfunc t_two():\n\tpass\nfunc _helper():\n\tpass\n",
                                         encoding="utf-8")
        (tests / "play_loop.gd").write_text("func t_not_unit():\n\tpass\n", encoding="utf-8")
        self.assertEqual(godot_run.unit_test_count(str(root), {"CB_ONLY": ""}), 2)
        self.assertEqual(godot_run.suite_timeout("unit", str(root), env={"CB_ONLY": ""}), 900)   # the floor
        (tests / "test_b.gd").write_text("func t_x():\n\tpass\n" * 218, encoding="utf-8")
        self.assertEqual(godot_run.suite_timeout("unit", str(root), env={"CB_ONLY": ""}), 300 + 6 * 220)   # 26.7 min
        (tests / "test_c.gd").write_text("func t_y():\n\tpass\n" * 400, encoding="utf-8")
        self.assertEqual(godot_run.suite_timeout("unit", str(root), env={"CB_ONLY": ""}), godot_run.UNIT_CAP_S)
        self.assertEqual(godot_run.suite_timeout("unit", str(root), env={"CB_ONLY": "t_a,t_b"}), 900)
        self.assertEqual(godot_run.suite_timeout("play", str(root)), 900)
        self.assertEqual(godot_run.suite_timeout("unit", str(root), given=60), 60)   # --timeout wins

    def test_godot_run_set_passes_config_overrides_after_the_double_dash(self):
        """Item 7: the suites under a non-default config (shop_layout=0), as ui_shots.py --set does."""
        import godot_run
        cmd = godot_run.command("unit", "game", ["shop_layout=0", "grid_cols=5"])
        self.assertEqual(cmd[-5:], ["-s", "res://tests/run_tests.gd", "--", "shop_layout=0", "grid_cols=5"])
        self.assertEqual(godot_run.command("lid", "game", ["k=1"])[-3:],
                         ["--", f"--out=game/reports/votes/lid-close/{time.strftime('%Y-%m-%d')}", "k=1"])   # dated
        self.assertNotIn("--", godot_run.command("unit", "game"))
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()):
            godot_run.main(["unit", "--set", "shop_layout"])

    # ------------------------------------------------------------------ L42: impact-based tests, routing, designer rows
    def impact_game(self):
        """A tiny game: truck.gd on the Truck node, main.gd and the config (core), and tests that read them directly
        or through helpers. `_make` (every test's setup) reads `Truck` too, which must not reach every test."""
        game = self.tmp / "game"
        w = lambda rel, text: (game / rel).parent.mkdir(parents=True, exist_ok=True) or \
            (game / rel).write_text(text, encoding="utf-8")
        w("scripts/truck.gd", "extends Node3D\nclass_name Truck\nvar load_count: int = 0\nfunc depart() -> void:\n"
                              "\tload_count = 0\nfunc honk() -> void:\n\tpass\n")
        w("scripts/main.gd", "extends Node3D\nvar zoom: int = 0\nfunc at_second_stop() -> bool:\n\treturn zoom == 2\n"
                             "func _on_back() -> void:\n\tzoom = 0\n")
        w("scripts/pile.gd", "extends Node3D\nclass_name Pile\nvar cells: int = 0\nfunc add_cell() -> void:\n"
                             "\tcells += 1\nfunc clear() -> void:\n\tcells = 0\n")
        w("scripts/default_config.tres", "[resource]\nzoom_seconds = 1.0\ncell_fly_seconds = 0.5\n")
        w("scripts/game_config.gd", "extends Resource\nclass_name GameConfig\n@export var zoom_seconds: float = 1.0\n"
                                    "@export var cell_fly_seconds: float = 0.5\n")
        w("scenes/main.tscn", '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://scripts/truck.gd" id="1"]\n\n'
                              '[node name="Main" type="Node3D"]\n\n[node name="Truck" type="Node3D" parent="."]\n'
                              'script = ExtResource("1")\n')
        w("tests/test_base.gd", "extends SceneTree\nfunc _make() -> Node:\n\tvar p = {\"Hive\": 1, \"Truck\": 2}  # Pile\n"
                                "\treturn null\nfunc _wait_zoom() -> void:\n\tawait _wait(cv(\"zoom_seconds\"))\n")
        w("tests/test_a.gd", 'extends "res://tests/test_base.gd"\nfunc t_truck_departs() -> void:\n\t_make()\n'
                             '\tvar t = p["Truck"]\nfunc t_second_stop() -> void:\n\t_make()\n\tck(m.call("at_second_stop"))\n'
                             "func t_zoom_wait() -> void:\n\t_make()\n\tawait _wait_zoom()\n"
                             'func t_pile_grows() -> void:\n\t_make()\n\tget_node("X").call("add_cell")\n'
                             "func t_unrelated() -> void:\n\t_make()\n\teq(1, 1)\n")
        self.diffs = {"game/scripts/truck.gd": "@@ -7 +7 @@\n-\tpass\n+\tprint(1)\n",
                      "game/scripts/main.gd": "@@ -4 +4 @@\n-\treturn zoom == 1\n+\treturn zoom == 2\n",
                      "game/scripts/default_config.tres": "@@ -2 +2 @@\n-zoom_seconds = 2.0\n+zoom_seconds = 1.0\n",
                      "game/scripts/pile.gd": "@@ -7 +7 @@\n-\tcells = 1\n+\tcells = 0\n",
                      "game/tests/test_base.gd": "@@ -6 +6 @@\n-\tawait _wait(1)\n+\tawait _wait(cv(\"zoom_seconds\"))\n"}

    def test_change_impact_maps_each_changed_file_to_the_tests_that_read_it(self):
        """L42: a step runs the tests that read what its changed files define, not ~220."""
        self.impact_game()
        tests = lambda changes: set(ga.change_impact(changes)["tests"])
        self.assertEqual(tests({"game/scripts/truck.gd": False}), {"t_truck_departs"})   # its node, read directly
        self.assertEqual(tests({"game/scripts/main.gd": False}), {"t_second_stop"})      # core: the changed function only
        self.assertEqual(tests({"game/scripts/default_config.tres": False}), {"t_zoom_wait"})   # the key, via a helper
        imp = ga.change_impact({"game/tests/test_base.gd": False})                       # a changed helper: its callers
        self.assertEqual((set(imp["tests"]), imp["written"]), ({"t_zoom_wait"}, set()))
        (self.tmp / "game" / "tests" / "test_new.gd").write_text(
            'extends "res://tests/test_a.gd"\nfunc t_new_one() -> void:\n\t_make()\n', encoding="utf-8")
        imp = ga.change_impact({"game/tests/test_new.gd": True})                         # a new test file: its tests only
        self.assertEqual((imp["tests"], imp["written"]), ({"t_new_one": ["changed in `tests/test_new.gd`"]}, {"t_new_one"}))
        imp = ga.change_impact({"game/scripts/pile.gd": False})                          # `clear` read by no test: widened
        self.assertEqual((set(imp["tests"]), imp["widened"]), ({"t_pile_grows"}, ["game/scripts/pile.gd"]))
        (self.tmp / "game" / "scripts" / "bees.gd").write_text("extends Node\nfunc buzz() -> void:\n\tpass\n",
                                                              encoding="utf-8")
        imp = ga.change_impact({"game/scripts/bees.gd": True, "game/scripts/truck.gd": False})
        self.assertEqual(imp["uncovered"], ["game/scripts/bees.gd"])
        line = ga.tests_line(["t_own"], imp, {"t_x"}, ["t_own", "t_truck_departs", "t_x"])
        for text in ("- Tests this round (3): own (1): `t_own`", "impacted by `scripts/truck.gd` (via `Truck`) (1): "
                     "`t_truck_departs`", "last failures (1): `t_x`", "No test reads `scripts/bees.gd`"):
            self.assertIn(text, line)
        self.assertIn("`unit` skipped", ga.tests_line([], ga.change_impact({}), set(), []))

    def test_the_test_index_is_cached_and_reread_when_a_file_changes(self):
        self.impact_game()
        first = ga.test_index()
        cache = self.tmp / ga.TEST_MAP
        self.assertEqual(json.loads(cache.read_text(encoding="utf-8")), first)
        self.assertIn("at_second_stop", first["test_a.gd"]["funcs"]["t_second_stop"]["t"])
        self.assertNotIn("Pile", first["test_base.gd"]["funcs"]["_make"]["t"])        # comments are not read
        data = json.loads(cache.read_text(encoding="utf-8"))
        data["test_a.gd"]["funcs"] = {"t_cached": {"t": [], "c": []}}
        cache.write_text(json.dumps(data), encoding="utf-8")
        self.assertEqual(list(ga.test_index()["test_a.gd"]["funcs"]), ["t_cached"])     # same stamp: the cache
        f = self.tmp / "game" / "tests" / "test_a.gd"
        f.write_text(f.read_text(encoding="utf-8") + "func t_more() -> void:\n\tpass\n", encoding="utf-8")
        self.assertIn("t_more", ga.test_index()["test_a.gd"]["funcs"])                   # changed: read again
        self.assertEqual(ga.diff_lines("@@ -3,2 +3,0 @@\n-a\n-b\n@@ -9 +7,2 @@\n+c\n+d\n"), ({3, 4, 7, 8}, ["a", "b", "c", "d"]))
        self.assertIsNone(ga.diff_lines(""))

    def test_a_round_runs_the_tests_its_changes_impact_and_says_why(self):
        self.written_fixture()
        self.impact_game()
        snaps = [{}, {"game/scripts/main.gd": ["h", False]}]                    # the step's start, then its change
        ga.change_snapshot = lambda: snaps.pop(0) if len(snaps) > 1 else snaps[0]
        self.check_codes = [0, 0, 0]
        code, out, board = self.run_main("--goal", "T3.1", "--max-goals", "1")
        tests = next(c for c in self.godot_cmds() if "--only" in c)
        self.assertEqual(tests[tests.index("--only") + 1], "t_frames_scale,t_second_stop")
        self.assertIn("own (1): `t_frames_scale`; impacted by `scripts/main.gd` (via `at_second_stop`) (1): "
                      "`t_second_stop`", board)

    def test_a_failing_test_the_step_wrote_goes_to_quinn_first(self):
        """L42: T9.1's two fix rounds went to Patricia, though the only failing test was Quinn's new one."""
        game = self.tmp / "game"
        (game / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        (game / "reports" / "goal").mkdir(parents=True, exist_ok=True)
        (game / "reports" / "goal" / "ledger.json").write_text(json.dumps(
            {"9.9-fixture.md": {"H": {"run": "t"}, "C3": {"run": "t"}}}), encoding="utf-8")
        fake = self.fake_agent
        def agent(a, prompt, max_turns=None):
            if a == ga.QA and "fix round" not in prompt:                    # Quinn writes the test, a doc line under its mark
                (game / "tests" / "test_frames.gd").write_text(
                    "# goal T3.1\n## the frames scale\nfunc t_frames_scale() -> void:\n\tpass\n", encoding="utf-8")
                self.snapshot = {"game/tests/test_frames.gd": ["h", True]}
            return fake(a, prompt, max_turns)
        ga.run_agent = agent
        fail = "FAIL    unit      0 passed, 1 failed\n    FAIL  t_frames_scale  run 2: expected 2 got 3\nPASS    start\n"
        self.check_codes, self.outs = [0, 1, 0, 1, 0, 1], [fail] * 3
        code, out, board = self.run_main("--goal", "T3.1")
        self.assertIn("own (1): `t_frames_scale`", board)                    # the mark is found past the doc line
        fix1 = [(a, p) for a, p in self.calls if "fix round 1" in p]
        self.assertEqual([a for a, _ in fix1], [ga.QA])
        self.assertIn("You alone work this round: the failing tests are ones this step wrote", fix1[0][1])
        self.assertIn("Fix round 1: to Quinn (the failing tests are ones this step wrote)", board)
        fix2 = [a for a, p in self.calls if "fix round 2" in p]
        self.assertEqual(len(fix2), 1)
        self.assertIn(fix2[0], (ga.PROGRAMMER, ga.BUILDER))                  # a code owner: not Quinn twice running

    def test_a_code_owner_blaming_the_test_sends_the_next_round_to_quinn(self):
        self.written_fixture()                                              # the test is older than this step
        fake = self.fake_agent
        blame = "I changed nothing: the failing check is in `tests/test_frames.gd` (Quinn's folder)."
        def agent(a, prompt, max_turns=None):
            reply, u = fake(a, prompt, max_turns)
            return (blame if a == ga.PROGRAMMER else reply), u
        ga.run_agent = agent
        fail = "FAIL    unit      0 passed, 1 failed\n    FAIL  t_frames_scale  expected 2 got 3\nPASS    start\n"
        self.check_codes, self.outs = [0, 1, 0, 1, 0, 1], [fail] * 3
        code, out, board = self.run_main("--goal", "T3.1")
        self.assertEqual([a for a, p in self.calls if "fix round 1" in p], [ga.PROGRAMMER])
        fix2 = [(a, p) for a, p in self.calls if "fix round 2" in p]
        self.assertEqual([a for a, _ in fix2], [ga.QA])
        self.assertIn("Patricia put the fault in tests/", fix2[0][1])
        self.assertIn(blame, fix2[0][1])                                    # her reply goes with the brief
        for reply in ("the fault is in the test, not in `scripts/`", "That's Quinn's file.", "the bug is in tests/"):
            self.assertTrue(ga.QUINN_FAULT.search(reply), reply)
        self.assertFalse(ga.QUINN_FAULT.search("The fault is in scripts/main.gd line 40; the test is right."))
        self.assertTrue(ga.QUINN_FAULT.search("Cause unclear, diag needed: zoom state and cells per frame."))  # L47
        self.assertIn("diag needed", [p for a, p in self.calls if "fix round 1" in p][0])   # L47: no guessing
        self.assertIn("`diag:`", fix2[0][1])

    def test_a_behaviour_designer_row_is_a_question_not_a_visual_vote(self):
        """L42: T9.1 stopped for a Design Votes row on keeping or resetting the paused crank."""
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        row = ("The spec doesn't say what the bucket should be when Harvest is tapped again with a paused crank. "
               "(designer) A: keep the paused crank and fix the test. B: reset the crank on reopening the zoom.")
        fake = self.fake_agent
        def agent(a, prompt, max_turns=None):
            reply, u = fake(a, prompt, max_turns)
            return (row if "fix round" in prompt else reply), u
        ga.run_agent = agent
        self.check_codes = [1]
        code, out, board = self.run_main()
        self.assertIn("Check `visual numbers`: PASS", board)
        self.assertIn("Check `designer questions`: STOP (1)", board)
        wait = board.split("## Waiting for the designer")[1]
        self.assertIn("about how the game behaves", wait)
        self.assertIn("| 1 | Patricia | " + row, wait)
        self.assertNotIn("Design Votes page", wait)
        self.assertIn("result: waiting-designer", board)
        for visual in ("Row height: A: keep 120 px; B: 64 px (designer)", "A: font 28; B: 24 (designer)",
                       "Icon colour: A: amber; B: honey (designer)", "Back button offset A: -4 B: 0 (designer)"):
            self.assertTrue(ga.VISUAL_ROW.search(visual), visual)
        self.assertFalse(ga.VISUAL_ROW.search(row))
        self.assertTrue(ga.DESIGNER_ROW.search(row))
        self.assertFalse(ga.DESIGNER_ROW.search("I found no game bug, so nothing is marked `(designer)`."))   # L49


def datetime_after(stamp):
    """A POSIX time one hour after a godot_run log folder's stamp."""
    import datetime
    return datetime.datetime.strptime(stamp, "%Y%m%d-%H%M%S").timestamp() + 3600


if __name__ == "__main__":
    unittest.main(verbosity=1)
