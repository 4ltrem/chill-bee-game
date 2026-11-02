#!/usr/bin/env python3
"""Tests for generate.py with fake agents: no Claude account, no tokens, nothing touched in the repo.

    python -I _tools/test_generate.py

Each test builds a throwaway workspace (content/, research/, _meta/agent-runs.md, agent definitions
and index.py), points generate.py at it, and replaces run_agent, the one function that calls
`claude -p`, with a fake. The fake William edits the draft the way the real one should, the fake
critic replies with a scripted verdict block, and the fake Ruth writes a brief. What this proves
is the script's logic: round order, what each agent is shown, verdict parsing, status rules, the
blackboard, research routing, the token cap, crash handling and run logging. Whether the real
agents write well is checked by real runs, not here. Standard library only.
"""
import contextlib
import io
import json
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))  # -I leaves the script's folder off sys.path
import generate as g  # noqa: E402

BAD, GOOD = "Flowers can't bloom without bees.", "Bees help the meadow's flowers make seeds."
LOG = ("# Runs\n\n### Content generation: write or check player-facing text (`_tools/generate.py`)\n"
       "Turns are the CLI's `num_turns`, not tool calls.\n"
       "| Run | Phase | Total processed | Final context | Turns | Duration |\n|---|---|---|---|---|---|\n\n## Next\n")
ROWS = {  # the finding a scripted FAIL carries
    "FAIL": "| 1 | Lore | \"x\" | Story Premise | reword |",
    "FAIL:source": f"| 1 | Facts & French | \"{BAD}\" | Bee Journal | Find a source that supports it |",
    "FAIL:french": "| 1 | Facts & French | \"spores bioluminescents\" | Languages | spore is feminine |",
}


class Fake:
    """Stands in for run_agent. verdicts: what the critic says on each call, in order."""

    def __init__(self, root, verdicts, tokens=1, crash_on=None, projects=None):
        self.root, self.verdicts, self.tokens, self.crash_on = root, list(verdicts), tokens, crash_on
        self.projects = projects  # when set, each call leaves a transcript there, as the real CLI does
        self.calls, self.prompts = [], []

    def __call__(self, agent, prompt):
        self.calls.append(agent)
        self.prompts.append(prompt)
        if self.crash_on == len(self.calls):
            raise g.AgentError("simulated CLI failure")
        draft, reply = self.root / "content" / "x.md", ""
        if agent == g.WRITER:
            if draft.is_file():  # a revision: change only the bad line
                draft.write_text(draft.read_text(encoding="utf-8").replace(BAD, GOOD), encoding="utf-8")
            else:  # a new draft, with the known error in it
                draft.write_text(f"---\nauthor: william\nstatus: draft\n---\n# X\n**Sources:** GDD.md\n{BAD}\n",
                                 encoding="utf-8")
        elif agent == g.RESEARCHER:
            path = re.search(r"`(research/[^`]+\.md)`", prompt).group(1)
            (self.root / path).write_text("---\nauthor: ruth\ntype: research\nstatus: draft\n---\n# Brief\n",
                                          encoding="utf-8")
        else:
            n = re.search(r"round (\d+)", prompt).group(1)
            said = self.verdicts.pop(0)
            reply = (f"Here is my verdict.\n\n```\n### Critic, round {n}\nVERDICT: {said.split(':')[0]}\n"
                     f"Checked:\n- Lore: ok\n| # | Check | Quote from draft | GDD section | Fix |\n"
                     f"|---|---|---|---|---|\n{ROWS.get(said, '')}\n```")
        usage = {"tokens": self.tokens, "turns": 1, "seconds": 1}
        if self.projects:
            sid = f"session-{len(self.calls)}"
            msg = {"id": sid, "model": "m", "content": [], "usage": {"cache_read_input_tokens": 700 + len(self.calls)}}
            (self.projects / f"{sid}.jsonl").write_text(json.dumps({"type": "assistant", "message": msg}) + "\n",
                                                        encoding="utf-8")
            usage["session_id"] = sid
        return reply, usage


class Workspace(unittest.TestCase):
    """A throwaway workspace with generate.py pointed at it; no tests of its own."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for folder in ("content", "research", "_tools", "_meta", ".claude/agents"):
            (self.root / folder).mkdir(parents=True)
        shutil.copy(TOOLS / "index.py", self.root / "_tools" / "index.py")
        (self.root / "_meta" / "agent-runs.md").write_text(LOG, encoding="utf-8")
        for name in (g.WRITER, g.CRITIC, g.RESEARCHER):
            (self.root / ".claude" / "agents" / f"{name}.md").write_text(
                f"---\nname: {name}\nmodel: sonnet\n---\n", encoding="utf-8")
        self.saved = g.ROOT, g.run_agent
        g.ROOT = self.root

    def tearDown(self):
        g.ROOT, g.run_agent = self.saved
        self.tmp.cleanup()

    def run_main(self, fake, *args):
        g.run_agent = fake
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            g.main(["x", *args])
        return out.getvalue()

    def new(self, fake, *extra, kind="story"):
        return self.run_main(fake, "--type", kind, "--request", "a test request", *extra)

    def status(self):
        return g.get_front(self.root / "content" / "x.md", "status")

    def board(self, name="blackboard.md"):
        return (self.root / "content" / "_runs" / "x" / name).read_text(encoding="utf-8")


class GenerateTest(Workspace):
    def test_new_draft_passes_in_round_one(self):
        fake = Fake(self.root, ["PASS"])
        self.new(fake)
        self.assertEqual(fake.calls, [g.WRITER, g.CRITIC])
        self.assertEqual(self.status(), "draft")
        self.assertIn("result: draft", self.board())

    def test_critic_is_shown_the_draft_and_its_block_lands_on_the_blackboard(self):
        fake = Fake(self.root, ["PASS"])
        self.new(fake)
        self.assertIn(BAD, fake.prompts[1])  # the draft is in Clara's prompt
        self.assertNotIn("blackboard", fake.prompts[1].lower())  # she is never sent to the file
        board = self.board()
        self.assertIn("### Critic, round 1\nVERDICT: PASS", board)
        self.assertNotIn("```", board)  # fences and chatter are stripped

    def test_fail_then_pass_hands_out_slices(self):
        fake = Fake(self.root, ["FAIL", "PASS"])
        self.new(fake)
        william2, critic2 = fake.prompts[2], fake.prompts[3]
        self.assertIn(ROWS["FAIL"], william2)  # William gets the FAIL rows, not the blackboard
        self.assertNotIn("blackboard", william2.lower())
        self.assertIn(f"-{BAD}", critic2)  # the critic gets the diff and its old verdict
        self.assertIn("Your round 1 verdict", critic2)
        self.assertNotIn("author: william", critic2)  # not the full draft again
        round2 = self.board()[self.board().index("## Round 2"):]
        self.assertIn(f"+{GOOD}", round2)
        self.assertNotIn("~~~~markdown", round2)

    def test_three_fails_need_review(self):
        self.new(Fake(self.root, ["FAIL", "FAIL", "FAIL"]))
        self.assertEqual(self.status(), "needs-review")
        self.assertIn("Still FAIL after 3 round(s)", self.board())

    def test_unparseable_verdict_is_retried_then_fails_the_run(self):
        fake = Fake(self.root, ["PASS"])
        fake_reply = lambda agent, prompt: ("no block here", {"tokens": 1, "turns": 1, "seconds": 1}) \
            if agent == g.CRITIC else fake(agent, prompt)
        with self.assertRaises(SystemExit):
            self.run_main(fake_reply, "--type", "story", "--request", "r")
        self.assertIn("result: failed", self.board())

    def test_token_cap_stops_before_a_new_round(self):
        fake = Fake(self.root, ["FAIL", "PASS"], tokens=300_000)
        out = self.new(fake, "--max-tokens", "500000")
        self.assertEqual(fake.calls, [g.WRITER, g.CRITIC])
        self.assertIn("token cap reached", out)
        self.assertEqual(self.status(), "needs-review")

    def test_journal_runs_research_first_and_william_cites_the_brief(self):
        fake = Fake(self.root, ["PASS"])
        self.new(fake, kind="journal")
        self.assertEqual(fake.calls, [g.RESEARCHER, g.WRITER, g.CRITIC])
        self.assertIn("`research/x.md`", fake.prompts[1])
        self.assertIn("Brief: `research/x.md`", self.board())

    def test_no_research_skips_ruth(self):
        fake = Fake(self.root, ["PASS"])
        self.new(fake, "--no-research", kind="journal")
        self.assertEqual(fake.calls, [g.WRITER, g.CRITIC])

    def test_source_fail_goes_to_ruth_before_william(self):
        fake = Fake(self.root, ["FAIL:source", "PASS"])
        self.new(fake, kind="journal")
        self.assertEqual(fake.calls, [g.RESEARCHER, g.WRITER, g.CRITIC, g.RESEARCHER, g.WRITER, g.CRITIC])
        self.assertIn(ROWS["FAIL:source"], fake.prompts[3])
        self.assertTrue((self.root / "research" / "x-2.md").is_file())
        self.assertIn("`research/x.md`, `research/x-2.md`", fake.prompts[4])

    def test_french_only_fail_does_not_call_ruth(self):
        fake = Fake(self.root, ["FAIL:french", "PASS"])
        self.new(fake, kind="journal")
        self.assertEqual(fake.calls.count(g.RESEARCHER), 1)  # only the initial brief

    def test_revise_unedited_pass_keeps_status(self):
        self.new(Fake(self.root, ["PASS"]))
        g.set_front(self.root / "content" / "x.md", status="approved")
        fake = Fake(self.root, ["PASS"])
        self.run_main(fake, "--revise")
        self.assertEqual(fake.calls, [g.CRITIC])
        self.assertEqual(self.status(), "approved")
        self.assertIn("unchanged from the previous run", self.board("blackboard-2.md"))

    def test_revise_with_notes_calls_william_first(self):
        self.new(Fake(self.root, ["PASS"]))
        g.set_front(self.root / "content" / "x.md", status="approved")
        fake = Fake(self.root, ["PASS"])
        self.run_main(fake, "--revise", "--request", "fix the bloom line")
        self.assertEqual(fake.calls, [g.WRITER, g.CRITIC])
        self.assertIn("fix the bloom line", fake.prompts[0])
        self.assertEqual(self.status(), "draft")

    def test_revise_journal_without_a_brief_verifies_the_draft(self):
        self.new(Fake(self.root, ["PASS"]), "--no-research", kind="journal")
        fake = Fake(self.root, ["PASS"])
        self.run_main(fake, "--revise")
        self.assertEqual(fake.calls, [g.RESEARCHER, g.CRITIC])
        self.assertIn("Verify the real-world claims in `content/x.md`", fake.prompts[0])

    def test_crash_marks_failed_and_a_fresh_run_replaces_it(self):
        with self.assertRaises(SystemExit):
            self.new(Fake(self.root, [], crash_on=1))
        self.assertIn("result: failed", self.board())
        self.new(Fake(self.root, ["PASS"]))
        self.assertIn("result: draft", self.board())
        self.assertIn("result: failed", self.board("blackboard-failed-1.md"))

    def test_a_finished_run_is_not_overwritten(self):
        self.new(Fake(self.root, ["PASS"]))
        with self.assertRaises(SystemExit):
            self.new(Fake(self.root, ["PASS"]))

    def test_calls_are_logged_with_agent_names(self):
        self.new(Fake(self.root, ["FAIL:source", "PASS"]), kind="journal")
        log = (self.root / "_meta" / "agent-runs.md").read_text(encoding="utf-8")
        table = log[log.index("### Content generation"):log.index("## Next")]
        self.assertEqual(table.count("| post-ICM |"), 6)
        self.assertIn("| Ruth: x, round 2 (Sonnet) | post-ICM | 1 | — | 1 | 1 s |", table)
        self.assertIn("| Critic: x, round 1 (Sonnet) |", table)

    def test_transcripts_move_into_the_run_folder_and_give_final_context(self):
        projects = self.root / "projects"
        projects.mkdir()
        (projects / "session-1").mkdir()  # tool results saved beside William's transcript (call 1)
        self.saved_projects = g.projects_dir
        g.projects_dir = lambda: projects
        try:
            self.new(Fake(self.root, ["FAIL", "PASS"], projects=projects))
        finally:
            g.projects_dir = self.saved_projects
        runs = list((self.root / "_meta" / "sessions" / "runs").iterdir())
        self.assertEqual(len(runs), 1)
        self.assertTrue(runs[0].name.endswith("-x-run"))
        kept = sorted(p.name for p in runs[0].iterdir())
        self.assertEqual(kept, ["critic-round-1.jsonl", "critic-round-2.jsonl", "william-round-1",
                                "william-round-1.jsonl", "william-round-2.jsonl"])
        self.assertEqual(list(projects.iterdir()), [])  # nothing left behind
        self.assertIn(f"Transcripts: `_meta/sessions/runs/{runs[0].name}/`", self.board())
        log = (self.root / "_meta" / "agent-runs.md").read_text(encoding="utf-8")
        self.assertIn("| William: x, round 1 (Sonnet) | post-ICM | 1 | 701 | 1 | 1 s |", log)


class CriticCheckTest(Workspace):
    """critic_check.py: the critic must FAIL the known-bad fixture with every expected finding."""

    ALL = ("| 1 | Facts & French | \"flowers can't bloom\" | Bee Journal | reword |\n"
           "| 2 | Lore | \"Tree A, cheapest\" | Tree A | Flight Endurance costs less |\n"
           "| 3 | Sources | \"GDD §9 Progression Tiers\" | Progression Tiers & Biomes | fix heading |")

    def setUp(self):
        super().setUp()
        import critic_check
        self.cc = critic_check
        (self.root / "_tools" / "fixtures").mkdir()
        shutil.copy(TOOLS / "fixtures" / "onboarding-bad.md", self.root / "_tools" / "fixtures")

    def check_with(self, verdict, rows):
        reply = (f"### Critic, round 1\nVERDICT: {verdict}\n| # | Check | Quote from draft | GDD section | Fix |\n"
                 f"|---|---|---|---|---|\n{rows}")
        prompts = []
        g.run_agent = lambda agent, prompt: (prompts.append(prompt) or reply, {"tokens": 1, "turns": 1, "seconds": 1})
        passed, report, _ = self.cc.check(self.cc.FIXTURES[0])
        return passed, report, prompts

    def test_all_three_caught_passes(self):
        passed, _, prompts = self.check_with("FAIL", self.ALL)
        self.assertTrue(passed)
        self.assertIn("Without bees, the flowers can't bloom", prompts[0])  # Clara saw the bad draft

    def test_a_missed_error_fails(self):
        rows = "\n".join(r for r in self.ALL.splitlines() if "cheapest" not in r)
        passed, report, _ = self.check_with("FAIL", rows)
        self.assertFalse(passed)
        self.assertIn('MISSED  "cheapest" upgrade', report)

    def test_a_minor_row_does_not_count(self):
        rows = self.ALL.replace("| Lore |", "| Lore (minor) |")
        self.assertFalse(self.check_with("FAIL", rows)[0])

    def test_a_pass_verdict_fails_the_check(self):
        self.assertFalse(self.check_with("PASS", self.ALL)[0])


class LogSubagentTest(unittest.TestCase):
    """log_subagent.py: the SubagentStop hook's row, measures and failure handling."""

    def setUp(self):
        import log_subagent
        self.ls = log_subagent
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / ".claude" / "agents").mkdir(parents=True)
        (self.root / ".claude" / "agents" / "hiring-manager.md").write_text(
            "---\nname: hiring-manager\ndescription: Martin, the Hiring Manager. Writes agents.\n---\n", encoding="utf-8")
        self.log = self.root / "agent-runs.md"
        self.log.write_text("# Runs\n\n### Probes\n| a |\n|---|\n\n## Daily Budget\nx\n", encoding="utf-8")
        self.saved = self.ls.ROOT
        self.ls.ROOT = self.root
        # three API calls; the second is split over two entries with the same id
        calls = [("m1", 100, 10, "2026-11-01T10:00:00Z", 1), ("m2", 300, 20, "2026-11-01T10:00:30Z", 1),
                 ("m2", 300, 20, "2026-11-01T10:00:31Z", 1), ("m3", 500, 5, "2026-11-01T10:01:05Z", 0)]
        lines = [json.dumps({"type": "user", "timestamp": "2026-11-01T09:59:58Z", "message": {"role": "user"}})]
        for mid, cache, out, ts, tool in calls:
            content = [{"type": "tool_use", "name": "Read"}] if tool else [{"type": "text", "text": "done"}]
            lines.append(json.dumps({"type": "assistant", "timestamp": ts, "message": {
                "id": mid, "model": "claude-haiku-5-5", "content": content,
                "usage": {"input_tokens": 3, "cache_read_input_tokens": cache, "output_tokens": out}}}))
        self.transcript = self.root / "agent-x.jsonl"
        self.transcript.write_text("\n".join(lines) + "\n", encoding="utf-8")
        self.transcript.with_suffix(".meta.json").write_text(
            json.dumps({"agentType": "hiring-manager", "description": "hire Ruth"}), encoding="utf-8")

    def tearDown(self):
        self.ls.ROOT = self.saved
        self.tmp.cleanup()

    def test_measures_final_and_total_once_per_call(self):
        m = self.ls.measure(self.transcript)
        self.assertEqual(m["final"], 508)  # last call only: 3 + 500 + 5
        self.assertEqual(m["total"], 113 + 323 + 508)  # each call counted once, not per entry
        self.assertEqual(m["tools"], 3)
        self.assertEqual(m["seconds"], 67)
        self.assertEqual(m["model"], "claude-haiku-5-5")

    def test_creates_the_table_before_daily_budget_and_appends(self):
        self.ls.log_run("hiring-manager", self.transcript, log=self.log)
        self.ls.log_run("hiring-manager", self.transcript, log=self.log)
        text = self.log.read_text(encoding="utf-8")
        self.assertLess(text.index(self.ls.TABLE), text.index("## Daily Budget"))
        self.assertEqual(text.count(self.ls.TABLE), 1)
        self.assertEqual(text.count("| Martin (hiring-manager): hire Ruth | post-ICM | 508 | 944 | 3 | 67 s |"), 2)

    def run_hook(self, payload):
        import subprocess
        return subprocess.run([sys.executable, "-I", str(TOOLS / "log_subagent.py")], input=payload,
                              capture_output=True, text=True, encoding="utf-8")

    def test_hook_never_fails_the_session(self):
        for payload in ("not json", '{"agent_type": ""}', '{"agent_type": "x", "agent_transcript_path": "/nope"}'):
            self.assertEqual(self.run_hook(payload).returncode, 0, payload)


class DecisionPageTest(unittest.TestCase):
    """decision_page.py: every session's log becomes one page, newest session's open list wins."""

    def test_builds_one_page_from_all_sessions(self):
        import decision_page as dp
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "_templates").mkdir()
            shutil.copy(TOOLS.parent / "_templates" / "decision-page.html", root / "_templates")
            logs = {"2026-10-31-aaaa": ("D01", "2026-10-31", "Old item"), "2026-11-02-bbbb": ("D02", "2026-11-02", "New item")}
            for folder, (did, date, item) in logs.items():
                (root / "_meta" / "sessions" / folder).mkdir(parents=True)
                (root / "_meta" / "sessions" / folder / "decisions.md").write_text(
                    f"# Decisions\n\n## Decisions\n\n### {did} · {date} · Models · Use `Haiku` for Ruth\n"
                    f"- Decided: try it.\n- Files: `_meta/team.md`, `x.md`\n- Note: a long note\n  that wraps.\n\n"
                    f"## Still open\n\n- {item}\n", encoding="utf-8")
            data = dp.build(root)
            self.assertEqual([d["id"] for d in data["decisions"]], ["D01", "D02"])
            self.assertEqual(data["open"], ["New item"])  # newest session's list
            self.assertEqual(data["decisions"][0]["fields"][2], ["Note", "a long note that wraps."])
            html = (root / dp.PAGE).read_text(encoding="utf-8")
            self.assertNotIn("/*__DATA__*/", html)
            self.assertIn('"title": "Use `Haiku` for Ruth"', html)

    def test_real_logs_parse(self):
        import decision_page as dp
        for log in (TOOLS.parent / "_meta" / "sessions").glob("*/decisions.md"):
            decisions, _ = dp.parse(log)
            self.assertTrue(decisions, f"{log} has no decision headings in the expected format")
            for d in decisions:
                self.assertTrue(d["fields"], f"{d['id']} in {log} has no '- Label: text' bullets")


class ConsistencyTest(unittest.TestCase):
    """consistency.py and sync_docs.py on a copy of the real docs: clean passes, each kind of drift fails."""

    SKIP = {".git", "game", "gdd-review", "gdd-review-v2", "_runs", "sessions", "__pycache__", "research", "proposals"}

    def setUp(self):
        import consistency, sync_docs
        self.cc, self.sd = consistency, sync_docs
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        shutil.copytree(TOOLS.parent, self.root, dirs_exist_ok=True,
                        ignore=lambda d, names: [n for n in names if n in self.SKIP])

    def tearDown(self):
        self.tmp.cleanup()

    def edit(self, rel, old, new):
        p = self.root / rel
        text = p.read_text(encoding="utf-8")
        self.assertIn(old, text, f"test setup: '{old}' not in {rel}")
        p.write_text(text.replace(old, new, 1), encoding="utf-8")

    def problems(self):
        return "\n".join(self.cc.check(self.root))

    def test_the_real_docs_are_consistent(self):
        self.assertEqual(self.problems(), "")

    def test_todays_bug_a_model_change_not_carried_to_the_docs(self):
        self.edit(".claude/agents/research-assistant.md", "model: sonnet", "model: haiku")
        found = self.problems()
        self.assertIn("CREW.md: generated section 'crew-agents' is out of date", found)
        self.assertIn("Ruth listed as Sonnet, but research-assistant.md has model: haiku", found)
        self.assertIn("Ruth shown as Sonnet, but the agent runs on Haiku", found)  # Model reviews row
        self.assertIn("diagram shows Ruth on Sonnet, but the agent runs on Haiku", found)

    def test_sync_docs_repairs_the_generated_section(self):
        self.edit(".claude/agents/writer.md", "model: sonnet", "model: opus")
        self.sd.sync(root=self.root)
        self.assertIn("| **William**, Writer ([definition](.claude/agents/writer.md)) | Opus |",
                      (self.root / "CREW.md").read_text(encoding="utf-8"))
        self.assertNotIn("generated section", self.problems())

    def test_a_quoted_default_that_no_longer_matches_the_code(self):
        self.edit("_tools/generate.py", 'default=500_000', 'default=400_000')
        self.assertIn("token cap quoted as 500,000, but generate.py defaults to 400,000", self.problems())

    def test_a_quoted_budget_that_no_longer_matches_ruth(self):
        self.edit(".claude/agents/research-assistant.md", "at most 6 WebSearch", "at most 4 WebSearch")
        self.assertIn("Ruth's search budget quoted as 6, but her definition says 4", self.problems())

    def test_a_stated_agent_count_that_is_wrong(self):  # Doris's first real finding
        self.edit("README.md", "The agent roster, each agent's model", "The nine agents, each agent's model")
        self.assertIn("README.md:64: says the nine agents, but .claude/agents/ holds 12", self.problems())

    def test_an_estimate_saying_not_yet_run_beside_a_logged_run(self):  # the designer's catch
        self.edit("_meta/agent-runs.md", "| Doris, the Doc Auditor | Measured once,", "| Doris, the Doc Auditor | Not yet run. Measured once,")
        self.assertIn("Doris's estimate says 'Not yet run', but line", self.problems())

    def test_an_agent_with_no_roster_row_or_route(self):
        (self.root / ".claude" / "agents" / "new-agent.md").write_text(
            "---\nname: new-agent\ndescription: Nina, the New Agent. Does things.\ntools: Read\nmodel: haiku\n---\n",
            encoding="utf-8")
        found = self.problems()
        self.assertIn("no roster row links .claude/agents/new-agent.md (Nina)", found)
        self.assertIn("AGENTS.md: no route mentions .claude/agents/new-agent.md (Nina)", found)


if __name__ == "__main__":
    unittest.main(verbosity=2)
