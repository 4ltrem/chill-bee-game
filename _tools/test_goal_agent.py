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
import shutil
import sys
import tempfile
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

    def test_item_numbers_outside_the_spec_are_ignored(self):
        changes = [(1, "Speed", "game speed row"), (2, "Camera", "camera stops")]
        self.assertEqual(ga.match_items("the speed row (report open item 6)", changes), [1])


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
        self.assertTrue(report["C2"]["waits_on_tests"])                     # its node is there; its test fails

    def test_ledger_marks_a_built_goal(self):
        _, report, _, _ = plan(ledger=["H", "C3"])
        self.assertEqual(report["H"]["status"], "done")
        self.assertEqual(report["C3"]["status"], "partial")
        self.assertTrue(report["C3"]["waits_on_tests"])


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
        self.assertNotIn("C2", ids)                                         # built, waits on its tests
        self.assertEqual(amb, [])
        _, _, ranked, _ = plan(ledger=["H"])
        self.assertEqual(ranked[0]["id"], "C3")
        _, _, ranked, _ = plan(ledger=["H", "C3"])
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
        self.saved = {k: getattr(ga, k) for k in ("ROOT", "run_agent", "run_cmd", "budget_ok", "log_usage")}
        ga.ROOT = self.tmp
        self.calls, self.cmds, self.check_codes, self.budget = [], [], [], (True, "allow")
        ga.run_agent = self.fake_agent
        ga.run_cmd = self.fake_cmd
        ga.budget_ok = lambda agent: self.budget
        ga.log_usage = lambda usage, run: None

    def tearDown(self):
        for k, v in self.saved.items():
            setattr(ga, k, v)
        shutil.rmtree(self.tmp, ignore_errors=True)

    def fake_agent(self, agent, prompt):
        self.calls.append((agent, prompt))
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
            return 0, ""
        return (self.check_codes.pop(0) if self.check_codes else 0), "FAIL  t_x  broken"

    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = ga.main(["9.9-fixture.md", "--run", "t", *args])
        return code, out.getvalue(), (self.tmp / "game" / "reports" / "goal" / "t" / "blackboard.md").read_text(
            encoding="utf-8")

    def test_plan_calls_no_agent(self):
        code, out, board = self.run_main("--plan")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("1. H", out)
        self.assertTrue((self.tmp / "game" / "reports" / "goal" / "t" / "gaps.json").is_file())
        self.assertIn("### Order", board)

    def test_dry_run_prints_briefs_and_spends_nothing(self):
        code, out, board = self.run_main("--dry-run")
        self.assertEqual((code, self.calls), (0, []))
        self.assertIn("brief for Patricia", out)
        self.assertFalse(any(c[0] == "git" and c[1] in ("commit", "checkout") for c in self.cmds))

    def test_one_green_step_commits_and_rescans(self):
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(code, 0)
        self.assertEqual([a for a, _ in self.calls], [ga.PROGRAMMER])
        ledger = json.loads((self.tmp / "game" / "reports" / "goal" / "ledger.json").read_text(encoding="utf-8"))
        self.assertEqual(ledger["9.9-fixture.md"]["H"]["commit"], "abc1234")
        self.assertTrue(any(c[:2] == ["git", "commit"] for c in self.cmds))
        add = next(c for c in self.cmds if c[:2] == ["git", "add"])
        self.assertNotIn("-A", add)
        self.assertIn("## Pass 2", board)                                   # re-scanned after the write
        self.assertIn("Next: **C3**", board.split("## Pass 2")[0] + "Next: **C3**")

    def test_a_step_builds_the_change_with_both_owners_in_parallel(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(sorted(a for a, _ in self.calls), [ga.BUILDER, ga.PROGRAMMER])
        pat = next(p for a, p in self.calls if a == ga.PROGRAMMER)
        self.assertIn("frame_scale", pat)
        self.assertIn("9.9-node-handoff.md", pat)
        self.assertNotIn("Speed tag moved", pat)                            # only its own change's slice
        self.assertTrue(any("ui_shots.py" in " ".join(c) for c in self.cmds))

    def test_failed_checks_get_two_fix_rounds_then_stop(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [1, 1, 1]                                        # the contract check fails every round
        code, out, board = self.run_main()
        self.assertEqual(code, 1)
        self.assertEqual(len(self.calls), 2 + 2 * 2)                        # C3 owners, then two fix rounds (contract: no Quinn)
        self.assertIn("fix round 2", self.calls[-1][1])
        self.assertIn("**Stop:** 2 fix rounds failed", board)
        self.assertFalse(any(c[:2] == ["git", "commit"] for c in self.cmds))

    def test_a_failing_old_test_after_a_change_also_goes_to_quinn(self):
        (self.tmp / "game" / "specs" / "9.9-node-handoff.md").write_text("# handoff\n", encoding="utf-8")
        self.check_codes = [0, 1]                                           # contract passes, the suite fails once
        code, out, board = self.run_main("--max-goals", "1")
        self.assertEqual(code, 0)
        fix = [a for a, p in self.calls if "fix round 1" in p]
        self.assertEqual(sorted(fix), sorted([ga.PROGRAMMER, ga.BUILDER, ga.QA]))
        self.assertIn("quote the spec line", next(p for a, p in self.calls if a == ga.QA))

    def test_a_crashed_agent_is_recorded_as_failed(self):
        def crash(agent, prompt):
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
        self.assertEqual([a for a, _ in self.calls], [ga.PROGRAMMER])        # the handoff is built; C3 never is
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

    def test_unapproved_spec_is_refused(self):
        spec = self.tmp / "game" / "specs" / "9.9-fixture.md"
        spec.write_text(spec.read_text(encoding="utf-8").replace("status: approved", "status: draft"), encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(ga.main(["9.9-fixture.md", "--run", "t", "--plan"]), 2)


if __name__ == "__main__":
    unittest.main(verbosity=1)
