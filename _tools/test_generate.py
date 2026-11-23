#!/usr/bin/env python3
"""Tests for generate.py with fake agents: no Claude account, no tokens, nothing touched in the repo.

    python -I _tools/test_generate.py

Each test builds a throwaway workspace (content/, research/, the run log, agent definitions
and index.py), points generate.py at it, and replaces run_agent, the one function that calls
`claude -p`, with a fake. The fake William edits the draft the way the real one should, the fake
critic replies with a scripted verdict block, and the fake Ruth writes a brief. What this proves
is the script's logic: round order, what each agent is shown, verdict parsing, status rules, the
blackboard, research routing, the token cap, crash handling and run logging. Whether the real
agents write well is checked by real runs, not here. Standard library only.
"""
import contextlib
import datetime
import io
import json
import os
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

    def board(self, run=None):
        """Run N's board, by default the newest run's (content/_runs/x/run-N/blackboard.md)."""
        runs = self.root / "content" / "_runs" / "x"
        return ((runs / f"run-{run}" if run else g.run_dir(runs, newest=True)) / "blackboard.md").read_text(encoding="utf-8")


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
        self.assertNotIn(BAD, board)  # the draft goes by reference (an input), the verdict inline (an output)
        snap = self.root / "content" / "_runs" / "x" / "run-1" / "round-1.md"
        self.assertIn(BAD, snap.read_text(encoding="utf-8"))
        self.assertIn("`content/_runs/x/run-1/round-1.md`", board)
        self.assertTrue(board.startswith("---\nslug: x\n") and board.count("## Result") == 1)

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

    def test_token_cap_lists_open_rows_owner_and_rerun_command(self):
        out = self.new(Fake(self.root, ["FAIL", "PASS"], tokens=300_000), "--max-tokens", "500000")
        cmd = "python -I _tools/generate.py x --revise --max-tokens 500000"
        for text in (out, self.board()):
            self.assertIn("Open FAIL rows (1):", text)
            self.assertIn(f"- William: {ROWS['FAIL']}", text)
            self.assertIn(cmd, text)

    def test_token_cap_gives_source_rows_to_ruth_on_a_journal_run(self):
        out = self.new(Fake(self.root, ["FAIL:source", "PASS"], tokens=300_000), "--max-tokens", "500000",
                       kind="journal")
        self.assertIn(f"- Ruth: {ROWS['FAIL:source']}", out)
        self.assertIn(f"- Ruth: {ROWS['FAIL:source']}", self.board())

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
        self.assertIn("unchanged from the previous run", self.board(2))

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
        self.assertIn("result: failed", self.board(1))                      # the failed run stays as history
        self.assertEqual(sorted(p.name for p in (self.root / "content" / "_runs" / "x").iterdir()), ["run-1", "run-2"])

    def test_a_finished_run_is_not_overwritten(self):
        self.new(Fake(self.root, ["PASS"]))
        with self.assertRaises(SystemExit):
            self.new(Fake(self.root, ["PASS"]))

    def test_calls_are_logged_with_agent_names(self):
        self.new(Fake(self.root, ["FAIL:source", "PASS"]), kind="journal")
        import runlog
        rows = runlog.read(self.root)
        self.assertEqual(len(rows), 6)
        self.assertTrue(all(r["table"] == "Content generation" and r["phase"] == "post-ICM" for r in rows))
        ruth = next(r for r in rows if r["agent"] == "Ruth" and r["run"] == "x, round 2")
        self.assertEqual((ruth["model"], ruth["total_processed"], ruth["final_context"], ruth["turns"],
                          ruth["duration_s"]), ("Sonnet", "1", "", "1", "1"))
        self.assertIn(("Critic", "x, round 1"), [(r["agent"], r["run"]) for r in rows])

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
        self.assertTrue(runs[0].name.endswith("-x-run-1"))
        kept = sorted(p.name for p in runs[0].iterdir())
        self.assertEqual(kept, ["critic-round-1.jsonl", "critic-round-2.jsonl", "william-round-1",
                                "william-round-1.jsonl", "william-round-2.jsonl"])
        self.assertEqual(list(projects.iterdir()), [])  # nothing left behind
        self.assertIn(f"Transcripts: `_meta/sessions/runs/{runs[0].name}/`", self.board())
        import runlog
        william = next(r for r in runlog.read(self.root) if r["agent"] == "William" and r["run"] == "x, round 1")
        self.assertEqual((william["total_processed"], william["final_context"]), ("1", "701"))

    def test_a_repeated_label_never_overwrites_a_kept_transcript(self):
        projects, dest = self.root / "projects", self.root / "runs"
        projects.mkdir()
        saved, g.projects_dir = g.projects_dir, (lambda: projects)
        try:
            for n in (1, 2):   # 0.1.4: "T14.4 fix 1" ran at 15:25 and again at 16:46
                (projects / f"s{n}.jsonl").write_text('{"type":"assistant","message":{"id":"m%d","usage":{}}}\n' % n,
                                                      encoding="utf-8")
                u = {"session_id": f"s{n}"}
                g.keep_transcript(u, dest, "fix-1-bob")
                self.assertEqual(u["calls"], 1)
        finally:
            g.projects_dir = saved
        self.assertEqual(sorted(p.name for p in dest.iterdir()), ["fix-1-bob-2.jsonl", "fix-1-bob.jsonl"])


VC_GDD = ("# G\n## Game Mechanics\n### 2. Phase 1 Uncapping & Extraction Minigame\n* **Stage 1: Uncapping (Tactile)**\n"
          "### 4. Land, Grid & Units\n### 7. Story Premise & Onboarding\n* **Tree C: Native Habitat**\n"
          "### 9. UI & Screens\n## Environmental & Visual Identity\n### Progression Tiers & Biomes\n## Glossary\n"
          "### Currencies & Prestige\n| Term | Meaning |\n|---|---|\n| Frontier bonus | — | **Rejected.** Extra. |\n")
BAD_CITE = "| Biomes in order | GDD §9 Progression Tiers | ✓ GDD |"


def vc(text, terms=()):
    return g.voice_check.check(text, VC_GDD, terms=list(terms))


class VoiceCheckTest(unittest.TestCase):
    def test_sources_line_forms_that_name_real_sections_pass(self):
        v, block = vc('**Sources:** `GDD.md` (Story Premise & Onboarding: "a guide (e.g., a queen; TBD)", '
                      "Phase 1 Uncapping & Extraction Minigame §2, Land Grid & Units; Tree C: Native Habitat — "
                      "its table, Glossary > Currencies & Prestige), `content/CONTEXT.md`.\nGDD §2 Stage 1 says so.")
        self.assertEqual(v, "PASS", block)
        self.assertIn("Land Grid & Units", block)

    def test_a_wrong_number_or_an_unknown_name_fails(self):
        v, block = vc(f"**Sources:** `GDD.md` (Story Premise & Onboarding §4, Tree D).\n{BAD_CITE}\n{BAD_CITE}")
        self.assertEqual(v, "FAIL")
        self.assertIn("numbered §7, not §4", block)
        self.assertIn("| Sources | \"Tree D\"", block)
        self.assertIn('§9 is "UI & Screens"', block)
        self.assertEqual(block.count("GDD §9 Progression Tiers"), 2)  # listed once as checked, one row, though cited twice
        self.assertEqual(len(g.fail_rows(block)), 3)

    def test_empty_or_placeholder_table_cells_fail(self):  # A4 (a): the cell part of check 7 by script
        v, block = vc("# X\n| # | EN | FR |\n|---|---|---|\n| 1 | Hello | Bonjour |\n| 2 | Bye | à écrire |\n"
                      "| 3 | Hi | |\nThe name is TBD in the GDD.\n")
        self.assertEqual(v, "FAIL")
        self.assertEqual(len(g.fail_rows(block)), 2)  # rows 2 and 3; the sentence stays with Clara
        self.assertIn("Completeness (T7 cells only): 2", block)

    def test_source_cache_gives_fresh_quotes_for_cited_urls(self):
        import source_cache as sc
        brief = ("---\nstatus: approved\n---\n| # | Claim (as narrow as the quote) | Verbatim quote | URL | Source kind "
                 "| Date checked |\n|---|---|---|---|---|---|\n| R1 | Leafcutters nest in dead wood | \"prefer dead "
                 "trees\" | https://ex.ca/bees | NGO | 2026-11-01 |\n| R2 | Old | \"old\" | https://ex.ca/old | NGO | 2025-01-01 |\n")
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "research").mkdir()
            (Path(d) / "research" / "b.md").write_text(brief, encoding="utf-8")
            (Path(d) / "research" / "r.md").write_text(brief.replace("approved", "rejected")
                                                       .replace("ex.ca/bees", "ex.ca/no"), encoding="utf-8")
            text = "See https://ex.ca/bees. And https://ex.ca/old and https://ex.ca/no and https://other.ca/x"
            out = sc.for_draft(text, Path(d), today=datetime.date(2026, 11, 20))
        self.assertIn('https://ex.ca/bees (checked 2026-11-01, `research/b.md`)', out)
        self.assertIn('"prefer dead trees"', out)
        self.assertNotIn("ex.ca/old", out)    # older than MAX_AGE_DAYS: fetched as before
        self.assertNotIn("ex.ca/no", out)     # a rejected brief is not a source
        self.assertNotIn("other.ca", out)
        self.assertEqual(sc.for_draft("no links here", Path(d)), "")

    def test_glossary_terms(self):
        v, block = vc("# X\nThe frontier bonus helps.\n")  # Rejected in the GDD Glossary: blocks
        self.assertEqual((v, len(g.fail_rows(block))), ("FAIL", 1))
        terms = [{"pattern": "coins?", "use": "In-game money", "section": "Glossary", "confirmed": False}]
        v, block = vc("# X\nCoins appear.\n## 2. Texte (français)\nDans le coin.\n", terms)
        self.assertEqual(v, "PASS")  # unconfirmed: a (minor) row only
        self.assertIn('(minor) "Coins appear."', block)
        self.assertNotIn("le coin", block)  # French sections are skipped
        terms[0]["confirmed"] = True
        self.assertEqual(vc("Coins appear.", terms)[0], "FAIL")


class ScriptCheckLoopTest(Workspace):
    def agents(self, fake, bad_on, fixed_on):
        """The fake, with William adding a wrong GDD citation on his call bad_on and removing it on fixed_on."""
        (self.root / "GDD.md").write_text(VC_GDD, encoding="utf-8")
        draft, calls = self.root / "content" / "x.md", []

        def agent(name, prompt):
            reply = fake(name, prompt)
            if name == g.WRITER:
                calls.append(1)
                text = draft.read_text(encoding="utf-8")
                if len(calls) == bad_on:
                    draft.write_text(text + BAD_CITE + "\n", encoding="utf-8")
                elif len(calls) == fixed_on:
                    draft.write_text(text.replace(BAD_CITE + "\n", ""), encoding="utf-8")
            return reply
        return agent

    def test_script_fail_goes_to_william_without_a_critic_call(self):
        fake = Fake(self.root, ["PASS"])
        self.new(self.agents(fake, 1, 2))
        self.assertEqual(fake.calls, [g.WRITER, g.WRITER, g.CRITIC])
        self.assertIn("### Script check, round 1\nVERDICT: FAIL", self.board())
        self.assertIn("GDD §9 Progression Tiers", fake.prompts[1])  # William gets the script's row
        self.assertIn("~~~~markdown", fake.prompts[2])  # the critic's first look is the whole draft
        self.assertNotIn("Your round", fake.prompts[2])
        self.assertIn("### Script check, round 2\nVERDICT: PASS", self.board())
        self.assertEqual(self.status(), "draft")

    def test_critic_diff_starts_from_the_draft_she_judged(self):
        fake = Fake(self.root, ["FAIL", "PASS"])
        self.new(self.agents(fake, 2, 3))  # round 2: William fixes Clara's row but adds a bad citation
        self.assertEqual(fake.calls, [g.WRITER, g.CRITIC, g.WRITER, g.WRITER, g.CRITIC])
        critic2 = fake.prompts[4]
        self.assertIn("Your round 1 verdict", critic2)
        self.assertIn(f"-{BAD}", critic2)
        self.assertNotIn("§9", critic2)  # the citation came and went between her looks


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

    def test_score_rows_are_not_findings(self):  # Clara's Scores table (designer, 2026-11-20)
        scores = ("\n\nScores\n| Check | Score | Reason |\n|---|---|---|\n"
                  "| Lore | 4/10 | \"Tree A, cheapest\" is wrong |\n| Tone & Glossary | 9/10 | playful, Glossary terms |")
        passed, report, _ = self.check_with("FAIL", self.ALL + scores)
        self.assertTrue(passed)
        self.assertIn("(3 blocking finding(s))", report[0])

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

    def rows(self):
        import runlog
        return runlog.read(self.root)

    def test_logs_one_csv_row(self):
        self.ls.log_run("hiring-manager", self.transcript)
        (row,) = self.rows()
        self.assertEqual((row["table"], row["agent"], row["run"], row["final_context"], row["total_processed"],
                          row["tool_calls"], row["duration_s"], row["key"]),
                         ("Subagent runs", "Martin (hiring-manager)", "hire Ruth", "508", "944", "3", "67", "agent-x"))
        self.assertEqual((row["start"], row["end"]), ("2026-11-01T09:59:58Z", "2026-11-01T10:01:05Z"))

    def test_a_subagent_that_stops_twice_keeps_one_row(self):  # Patricia's double row
        self.ls.log_run("hiring-manager", self.transcript)
        with self.transcript.open("a", encoding="utf-8") as f:  # it carried on, then stopped again
            f.write(json.dumps({"type": "assistant", "timestamp": "2026-11-01T10:05:00Z", "message": {
                "id": "m4", "model": "claude-haiku-5-5", "content": [],
                "usage": {"cache_read_input_tokens": 900}}}) + "\n")
        self.ls.log_run("hiring-manager", self.transcript)
        (row,) = self.rows()
        self.assertEqual((row["final_context"], row["total_processed"]), ("900", "1844"))  # updated, complete

    def test_a_different_subagent_gets_its_own_row(self):
        other = self.transcript.with_name("agent-y.jsonl")
        shutil.copy(self.transcript, other)
        self.ls.log_run("hiring-manager", self.transcript)
        self.ls.log_run("hiring-manager", other)
        self.assertEqual(sorted(r["key"] for r in self.rows()), ["agent-x", "agent-y"])

    def write_main_session(self):
        """A main session (session-1.jsonl) with this subagent under session-1/subagents/, and two readings."""
        session = self.root / "session-1"
        (session / "subagents").mkdir(parents=True)
        sub = session / "subagents" / "agent-z.jsonl"
        shutil.copy(self.transcript, sub)
        main = [("o1", "2026-11-01T09:59:00Z", 7), ("o2", "2026-11-01T10:00:10Z", 40),  # before; inside
                ("o3", "2026-11-01T10:00:50Z", 60), ("o4", "2026-11-01T10:02:00Z", 9)]   # inside; after
        session.with_suffix(".jsonl").write_text("".join(json.dumps({"type": "assistant", "timestamp": ts,
            "message": {"id": i, "model": "claude-opus-5-5", "usage": {
                "input_tokens": 1, "cache_read_input_tokens": n, "output_tokens": 2}}}) + "\n"
            for i, ts, n in main), encoding="utf-8")
        readings = self.root / "_meta" / "usage" / "readings.jsonl"
        readings.parent.mkdir(parents=True)
        readings.write_text("".join(json.dumps(r) + "\n" for r in [
            {"ts": "2026-11-01T09:00:00Z", "five_hour": 10, "seven_day": 30},
            {"ts": "2026-11-01T10:03:00Z", "five_hour": 14, "seven_day": 31}]), encoding="utf-8")
        return sub, session.with_suffix(".jsonl")

    def test_orchestrator_tokens_and_usage_over_the_span(self):
        sub, _ = self.write_main_session()
        self.ls.log_run("hiring-manager", sub)
        (row,) = self.rows()
        self.assertEqual((row["orch_input"], row["orch_cache_read"], row["orch_output"]), ("2", "100", "4"))
        self.assertEqual((row["five_hour_before"], row["five_hour_after"], row["seven_day_before"],
                          row["seven_day_after"]), ("10", "14", "30", "31"))

    def test_session_hook_logs_the_whole_main_session_once(self):
        import log_session
        saved = log_session.ROOT
        log_session.ROOT = self.root
        try:
            _, main = self.write_main_session()
            log_session.log_session(main)
            log_session.log_session(main)  # every turn ends with a Stop: still one row
        finally:
            log_session.ROOT = saved
        (row,) = self.rows()
        self.assertEqual((row["table"], row["key"], row["turns"], row["orch_cache_read"], row["total_processed"],
                          row["model"]), ("Orchestrator", "session-1", "4", "116", "128", "claude-opus-5-5"))

    def test_session_hook_skips_headless_runs_and_never_fails(self):
        import subprocess
        env = {**__import__("os").environ, "CHILLBEE_HEADLESS": "1"}
        for payload, e in (("not json", None), ('{"transcript_path": "/nope"}', None), ("{}", env)):
            done = subprocess.run([sys.executable, "-I", str(TOOLS / "log_session.py")], input=payload, env=e,
                                  capture_output=True, text=True, encoding="utf-8")
            self.assertEqual(done.returncode, 0, payload)

    def test_status_line_saves_new_readings_only(self):
        import statusline
        status = lambda five: json.dumps({"session_id": "s", "model": {"display_name": "Opus"},
                                          "rate_limits": {"five_hour": {"used_percentage": five},
                                                          "seven_day": {"used_percentage": 20.5}}})
        self.assertEqual(statusline.main(status(12), self.root), "Opus · 5h 12% · week 20.5%")
        statusline.main(status(12), self.root)  # unchanged: not saved again
        statusline.main(status(13), self.root)
        saved = (self.root / "_meta" / "usage" / "readings.jsonl").read_text(encoding="utf-8").splitlines()
        self.assertEqual([json.loads(l)["five_hour"] for l in saved], [12, 13])
        self.assertEqual(statusline.main("{}", self.root), "usage: no reading yet")

    def test_live_agents_shown_while_running(self):
        import datetime, statusline
        live = self.root / "_meta" / "usage" / "live.json"
        g.set_live_tag("goal 0.1.4 · C5")
        g.live_update("a", {"agent": "Patricia", "tag": "goal 0.1.4 · C5", "start": "2026-11-07T20:00:00Z"}, live)
        g.live_update("b", {"agent": "Bob", "tag": "goal 0.1.4 · C5", "start": "2026-11-07T20:02:00Z"}, live)
        g.live_update("c", {"agent": "Old", "tag": "x", "start": "2026-11-07T10:00:00Z"}, live)  # killed run: hidden
        at = datetime.datetime(2026, 11, 7, 20, 4, tzinfo=datetime.timezone.utc)
        self.assertEqual(statusline.live(self.root, at), "▶ goal 0.1.4 · C5 · Patricia 4m · Bob 2m")
        g.live_update("a", None, live)
        self.assertEqual(statusline.live(self.root, at), "▶ goal 0.1.4 · C5 · Bob 2m")
        live.write_text("not json", encoding="utf-8")
        self.assertEqual(statusline.live(self.root, at), "")

    @contextlib.contextmanager
    def live_here(self):
        """Point live.py's files at the test folder."""
        import live
        base = self.root / "_meta" / "usage"
        saved = live.FILE, live.LOG, live.STREAMS, live.tag()
        live.FILE, live.LOG, live.STREAMS = base / "live.json", base / "live.log", base / "live"
        try:
            yield live
        finally:
            live.FILE, live.LOG, live.STREAMS = saved[:3]
            live.set_tag(saved[3])

    def test_live_steps_show_progress_and_log_events(self):
        import statusline
        with self.live_here() as live:
            live.set_tag("goal 0.2 · C14 checks")
            with live.step("unit") as s:
                s.note("45 passed, 1 failed · t_shop_rows")
                self.assertRegex(statusline.live(self.root), r"^▶ goal 0\.2 · C14 checks · unit 0m \(45 passed, 1 failed\)$")
                s.result = "exit 1"
                s.ok = False
            self.assertEqual(statusline.live(self.root), "")       # ended: gone from the line
            events = [json.loads(l) for l in live.LOG.read_text(encoding="utf-8").splitlines()]
            self.assertEqual([(e["kind"], e["name"], e["tag"]) for e in events],
                             [("start", "unit", "goal 0.2 · C14 checks"), ("end", "unit", "goal 0.2 · C14 checks")])
            self.assertEqual((events[1]["ok"], events[1]["text"]), (False, "exit 1"))
            import os
            self.assertEqual(os.environ[live.ENV_TAG], "goal 0.2 · C14 checks")   # child scripts inherit the tag

    def test_live_drops_dead_processes(self):
        import subprocess
        with self.live_here() as live:
            p = subprocess.Popen([sys.executable, "-I", "-c", "pass"])
            p.wait()
            live.update("dead", {"agent": "Bob", "kind": "agent", "start": live.now_iso(), "pid": p.pid})
            live.update("me", {"agent": "Rex", "kind": "agent", "start": live.now_iso(), "pid": __import__("os").getpid()})
            self.assertEqual([r["agent"] for r in live.running(self.root)], ["Rex"])

    def test_stream_agent_logs_tool_calls_and_returns_the_result(self):
        lines = [{"type": "system", "subtype": "init"},
                 {"type": "assistant", "message": {"content": [
                     {"type": "text", "text": "looking"},
                     {"type": "tool_use", "name": "Edit", "input": {"file_path": str(g.ROOT / "game" / "scripts" / "main.gd")}}]}},
                 {"type": "result", "subtype": "success", "result": "done", "num_turns": 2}]
        script = self.root / "fake_claude.py"
        script.write_text("import sys, json\nsys.stdin.read()\n" + "".join(
            f"print(json.dumps({l!r}))\n" for l in lines), encoding="utf-8")
        with self.live_here() as live:
            code, out, _ = g.stream_agent([sys.executable, "-I", str(script)], "brief", "Patricia", "k1")
            self.assertEqual((code, out["result"]), (0, "done"))
            tools = [json.loads(l) for l in live.LOG.read_text(encoding="utf-8").splitlines()]
            self.assertEqual([(e["kind"], e["name"], e["text"]) for e in tools],
                             [("tool", "Patricia", "Edit game/scripts/main.gd")])
            self.assertEqual(len((live.STREAMS / "k1.jsonl").read_text(encoding="utf-8").splitlines()), 3)

    def test_godot_run_streams_counts_and_times_out(self):
        import godot_run

        class Step:
            notes = []

            def note(self, t):
                self.notes.append(t)
        s = Step()
        text, code = godot_run.stream([sys.executable, "-I", "-c", "print('PASS t_a'); print('FAIL t_b x'); print('---- 1 passed, 1 failed')"],
                                      60, None, s)
        self.assertEqual(code, 0)
        self.assertIn("---- 1 passed", text)
        self.assertEqual(s.notes[-1], "1 passed, 1 failed · t_b")
        _, code = godot_run.stream([sys.executable, "-I", "-c", "import time; time.sleep(30)"], 1, None)
        self.assertIsNone(code)

    def test_watch_formats_events(self):
        import watch
        self.assertRegex(watch.fmt({"ts": "2026-11-21T18:28:41Z", "kind": "tool", "name": "Patricia",
                                    "tag": "goal 0.2 · C14", "text": "Edit game/scripts/main.gd"}),
                         r"^\d\d:\d\d:\d\d · Patricia\s+Edit game/scripts/main\.gd   \[goal 0\.2 · C14\]$")
        self.assertIn("✗ unit", watch.fmt({"ts": "x", "kind": "end", "name": "unit", "ok": False, "text": "exit 1",
                                           "seconds": 333}))
        self.assertIn("exit 1 in 5m33s", watch.fmt({"ts": "x", "kind": "end", "name": "unit", "ok": False,
                                                     "text": "exit 1", "seconds": 333}))

    def test_status_reads_boards_tests_stops_and_decisions(self):
        import status
        r = self.root
        (r / "game" / "reports" / "goal" / "0.9").mkdir(parents=True)
        (r / "game" / "reports" / "goal" / "0.9" / "blackboard.md").write_text(
            "---\nrun: 0.9\nresult: waiting-designer\n---\n# x\n\n## Waiting for the designer\n\nC3 needs a layout.\n",
            encoding="utf-8")
        for stamp, total in (("20261120-010101", "---- 5 passed, 0 failed"), ("20261121-010101", "---- 9 passed, 2 failed")):
            (r / "game" / "reports" / "_runs" / stamp).mkdir(parents=True)
            (r / "game" / "reports" / "_runs" / stamp / "unit.log").write_text(f"PASS t_a\n{total}\n", encoding="utf-8")
        (r / "_meta" / "memory").mkdir(parents=True, exist_ok=True)
        (r / "_meta" / "memory" / "session-handoff.md").write_text(
            "x\n**STOP (Oscar): C9 failed**, for an Opus session.\nnot a stop\n", encoding="utf-8")
        (r / "_meta" / "sessions" / "a").mkdir(parents=True, exist_ok=True)
        (r / "_meta" / "sessions" / "a" / "decisions.md").write_text("### D7 · x\n### D12 · y\n", encoding="utf-8")
        self.assertEqual(status.goal_runs(r), [("0.9", "waiting-designer", "C3 needs a layout.")])
        self.assertEqual(status.newest_tests(r), ("game/reports/_runs/20261121-010101", {"unit": "FAIL 9, 2 failed"}))
        self.assertEqual(status.stops(r), ["STOP (Oscar): C9 failed, for an Opus session."])
        self.assertEqual(status.next_decision(r), "D13")

    def test_end_of_day_refuses_transcripts_in_the_index(self):
        import end_of_day
        bad = ["_meta/sessions/2026-11-21-ab/session.jsonl", "_meta/sessions/x/subagents/a.jsonl",
               "_meta/sessions/runs/x/blackboard.md", "_meta/sessions/x/manifest.json"]
        good = ["_meta/sessions/x/decisions.md", "_meta/sessions/decision-comb.html"]
        self.assertEqual([bool(end_of_day.NEVER_STAGED.search(p)) for p in bad + good], [True] * 4 + [False] * 2)

    def test_display_names_come_from_the_agent_files(self):
        import live
        self.assertEqual((live.display("programmer"), live.display("content-critic"), live.display("nope")),
                         ("Patricia", "Clara", "nope"))

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
            if not decisions and "No decisions were made" in log.read_text(encoding="utf-8"):
                continue  # a session that holds no decisions says so in one line
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
        self.assertEqual(self.cc.check_readme_map(TOOLS.parent), [])   # the copy has no .git: check the real repo

    def test_a_top_level_file_missing_from_the_readme_map_fails(self):
        names = ["AGENTS.md", "CLAUDE.md", "README.md", "game", "NEW_DOC.md"]
        found = self.cc.check_readme_map(self.root, names)
        self.assertEqual(len(found), 2, found)                              # the maps themselves and CLAUDE.md are exempt
        self.assertTrue(found[0].startswith("README.md:") and "no row for `NEW_DOC.md`" in found[0])
        self.assertTrue(found[1].startswith("AGENTS.md:"))
        self.edit("README.md", "| [GDD.md](GDD.md) |", "| [NEW_DOC.md](NEW_DOC.md) | new |\n| [GDD.md](GDD.md) |")
        self.assertEqual(len(self.cc.check_readme_map(self.root, names)), 1)
        self.edit("AGENTS.md", "| [CREW.md](CREW.md) |", "| `NEW_DOC.md` | new |\n| [CREW.md](CREW.md) |")
        self.assertEqual(self.cc.check_readme_map(self.root, names), [])

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
        line = next(i for i, text in enumerate((self.root / "README.md").read_text(encoding="utf-8").splitlines(), 1)
                    if "The nine agents" in text)  # found, not hard-coded: README rows get added
        held = len(list((self.root / ".claude" / "agents").glob("*.md")))  # counted: agents get hired
        self.assertIn(f"README.md:{line}: says the nine agents, but .claude/agents/ holds {held}", self.problems())

    def test_an_estimate_saying_not_yet_run_beside_a_logged_run(self):  # the designer's catch
        self.edit("_meta/agent-runs.md", "| Doris, the Doc Auditor | Measured once,", "| Doris, the Doc Auditor | Not yet run. Measured once,")
        self.assertIn("Doris's estimate says 'Not yet run', but _meta/agent-runs.csv line", self.problems())

    def test_an_agent_with_no_roster_row_or_route(self):
        (self.root / ".claude" / "agents" / "new-agent.md").write_text(
            "---\nname: new-agent\ndescription: Nina, the New Agent. Does things.\ntools: Read\nmodel: haiku\n---\n",
            encoding="utf-8")
        found = self.problems()
        self.assertIn("no roster row links .claude/agents/new-agent.md (Nina)", found)
        self.assertIn("AGENTS.md: no route mentions .claude/agents/new-agent.md (Nina)", found)


class BuildToolsTest(unittest.TestCase):
    """godot_run.py summaries, mutate.py verdicts, build.py version and zip (no Godot needed)."""

    def setUp(self):
        import godot_run, mutate, build
        self.gr, self.mu, self.bu = godot_run, mutate, build

    def test_unit_summary_keeps_fails_and_drops_engine_noise(self):
        text = "\n".join(["PASS  t_a  (3 checks)", 'ERROR: Parameter "m" is null.', "   at: mesh_get_surface_count (x)",
                          "FAIL  t_b  expected 4 got 5", "MEASURE fps farm: 711 frames", "---- 1 passed, 1 failed", "RAN 2 of 2"])
        r = self.gr.summarise("unit", text, 1)
        self.assertEqual(r["status"], "FAIL")
        self.assertEqual(r["total"], {"passed": 1, "failed": 1, "checks": 2})
        self.assertEqual(r["fails"], ["FAIL  t_b  expected 4 got 5"])
        self.assertEqual(r["measures"], ["MEASURE fps farm: 711 frames"])
        self.assertEqual(r["noise_dropped"], 2)
        self.assertEqual(r["errors"], [])

    def test_windowed_suite_needs_completed(self):
        text = "PASS  x\n---- 5 checks, 0 failed"
        self.assertEqual(self.gr.summarise("play", text, 0)["status"], "FAIL")
        self.assertEqual(self.gr.summarise("play", text + "\nCOMPLETED", 0)["status"], "PASS")

    def test_start_suite_fails_on_script_errors_only(self):
        self.assertEqual(self.gr.summarise("start", "Godot Engine v4.2.1\n", 1)["status"], "PASS")
        bad = 'SCRIPT ERROR: Parse Error: Identifier "JarFlight" not declared in the current scope.'
        self.assertEqual(self.gr.summarise("start", bad, 1)["status"], "FAIL")

    def test_start_runs_first_and_a_parse_error_skips_the_rest(self):   # L53
        self.assertEqual(self.gr.start_first(["unit", "start", "play"]), ["start", "unit", "play"])
        self.assertEqual(self.gr.start_first(["unit", "ui"]), ["unit", "ui"])
        bad = self.gr.summarise("start", 'SCRIPT ERROR: Parse Error: Function "at_second_stop" has the same name', 1)
        self.assertTrue(self.gr.parse_broken(bad))
        other = self.gr.summarise("start", "ERROR: Condition \"!x\" is true.", 1)
        self.assertFalse(self.gr.parse_broken(other))   # a runtime error still lets the tests run and show it
        self.assertEqual(self.gr.skipped("unit")["status"], "SKIPPED")

    def test_contract_flags_a_name_two_nodes_share_under_one_search(self):   # L53
        import contract_check as cc
        with tempfile.TemporaryDirectory() as d:
            os.makedirs(os.path.join(d, "scenes"))
            os.makedirs(os.path.join(d, "scripts"))
            os.makedirs(os.path.join(d, "tests"))
            Path(d, "scenes", "main.tscn").write_text(
                '[gd_scene format=3]\n[ext_resource type="Script" path="res://scripts/a.gd" id="1"]\n'
                '[node name="Main" type="Node"]\n[node name="A" type="Node" parent="."]\nscript = ExtResource("1")\n'
                '[node name="Label" type="Label" parent="A"]\n[node name="B" type="Node" parent="."]\n'
                '[node name="Label" type="Label" parent="B"]\n', encoding="utf-8")
            Path(d, "scripts", "a.gd").write_text('func _ready():\n\tfind_child("Label")\n', encoding="utf-8")
            self.assertEqual(cc.check_duplicates(d, {})[0], [])   # A searches its own subtree: one Label
            Path(d, "tests", "test_x.gd").write_text('func t_x(m):\n\tm.find_child("Label")\n', encoding="utf-8")
            problems, _ = cc.check_duplicates(d, {})
            self.assertEqual(len(problems), 1)   # a test searching all of main.tscn finds two
            self.assertIn("'Label'", problems[0])
            problems, notes = cc.check_duplicates(d, {"Label": "renamed by item 9"})
            self.assertEqual((problems, len(notes)), ([], 1))

    def test_mutation_verdicts(self):
        fail = {"status": "FAIL", "fails": ["FAIL  t_pop  curve differs", "FAIL  t_other  x"]}
        ok = {"status": "PASS", "fails": []}
        self.assertEqual(self.mu.verdict({"expect": ["t_pop"]}, fail)[0], "CAUGHT")
        self.assertEqual(self.mu.verdict({"expect": ["t_pop", "t_missing"]}, fail)[0], "MISSED")
        self.assertEqual(self.mu.verdict({"expect": []}, ok)[0], "MISSED")
        self.assertEqual(self.mu.verdict({}, {"status": "TIMEOUT", "fails": []})[0], "BROKEN")
        # D160, tests that prove more: a catch by a test already red, or by a script error, proves nothing
        self.assertEqual(self.mu.verdict({"expect": ["t_pop"]}, fail, {"t_pop"})[0], "BROKEN")
        crash = {"status": "FAIL", "fails": ["FAIL  t_pop  test stopped before its final line (script error)  (5 ms)"]}
        self.assertEqual(self.mu.verdict({"expect": ["t_pop"]}, crash)[0], "BROKEN")

    def test_godot_run_flags_set_the_cb_env(self):
        import argparse
        ns = lambda **kw: argparse.Namespace(**{"only": None, "time_scale": None, "skip_x1": False, **kw})
        self.assertIsNone(self.gr.suite_env(ns()))                       # no flag: os.environ applies as before
        self.assertEqual(self.gr.suite_env(ns(only="t_a,t_b", time_scale="6", skip_x1=True)),
                         {"CB_ONLY": "t_a,t_b", "CB_TIME_SCALE": "6", "CB_SKIP_X1": "1"})

    def test_mutation_env_runs_only_expected_unit_tests(self):
        self.assertEqual(self.mu.mutation_env({"expect": ["a", "b"]}, "unit"), {"CB_ONLY": "a,b"})
        self.assertIsNone(self.mu.mutation_env({"expect": []}, "unit"))
        self.assertIsNone(self.mu.mutation_env({"expect": ["a"]}, "play"))

    def test_mutations_changed_since_keeps_new_and_edited_only(self):
        old = [{"name": "a", "find": "x"}, {"name": "b", "find": "y"}]
        new = [{"name": "a", "find": "x"}, {"name": "b", "find": "z"}, {"name": "c", "find": "w"}]
        self.assertEqual([m["name"] for m in self.mu.changed_since(new, old)], ["b", "c"])
        self.assertEqual(len(self.mu.changed_since(new, [])), 3)

    def test_mutations_file_is_valid_json_with_named_entries(self):
        # 2026-11-08: Quinn wrote raw tabs into two "find"/"replace" strings and mutate.py crashed on json.load
        path = Path(__file__).resolve().parent.parent / "game" / "tests" / "mutations.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        entries = data if isinstance(data, list) else data.get("mutations", [])
        self.assertTrue(entries)
        names = [e.get("name") for e in entries]
        self.assertTrue(all(names), "every mutation has a name")
        self.assertEqual(len(names), len(set(names)), "mutation names are unique")

    def test_budget_guard_blocks_warns_and_ignores_stale_readings(self):
        import budget_guard as b
        import datetime as d
        t = d.datetime(2026, 11, 5, 4, 0, tzinfo=d.timezone.utc)
        r = lambda five, week, mins=5: {"ts": (t - d.timedelta(minutes=mins)).isoformat(), "five_hour": five, "seven_day": week}
        reset = "2026-11-07T13:59:00+00:00"   # t is 4.6 days into that week: pace ~66%
        dec = lambda rd, agent: b.decide(rd, agent, t, reset=reset)[0]
        self.assertEqual(dec(r(78, 50), "doc-auditor"), "warn")          # 78 + 2 <= 95: a cheap agent still runs
        self.assertEqual(dec(r(70, 50), "qa-build-engineer"), "deny")    # 70 + 30 > 95
        self.assertEqual(dec(r(60, 50), "qa-build-engineer"), "allow")
        self.assertEqual(dec(r(60, 50), "mystery"), "allow")             # unknown counts as 25
        self.assertEqual(dec(r(40, 80), "builder"), "deny")              # 80 > pace 66 + 10
        self.assertEqual(dec(r(40, 80), "style-critic"), "allow")        # light agents ignore the pace
        self.assertEqual(dec(r(10, 95), "style-critic"), "deny")         # weekly cap
        self.assertEqual(dec(r(99, 50, 120), "builder"), "allow")        # stale reading
        self.assertEqual(dec(None, "builder"), "allow")
        self.assertAlmostEqual(b.week_pace(t, d.datetime(2026, 10, 24, 13, 59, tzinfo=d.timezone.utc)), 65.5, delta=0.5)
        # average, not highest (designer 2026-11-09): runs of 2 and 9 points average 6 (rounded up), a reset run is skipped
        with tempfile.TemporaryDirectory() as tmp:
            csv_path = str(Path(tmp) / "runs.csv")
            with open(csv_path, "w", encoding="utf-8", newline="") as fh:
                fh.write("agent,five_hour_before,five_hour_after\nPat (programmer),10,12\nPat (programmer),20,29\n"
                         "Pat (programmer),90,5\nOrchestrator,1,50\n")
            costs = b.average_costs(csv_path)
            self.assertEqual(costs["programmer"], 6)
            self.assertEqual(costs["builder"], b.COST["builder"])          # no logged run: the fixed table
            self.assertEqual(b.decide(r(85, 50), "programmer", t, reset=reset, costs=costs)[0], "warn")   # 85 + 6 <= 95

    def test_guard_shell_refuses_deleting_a_folder_that_holds_a_junction(self):
        """L45: a worktree's Godot junction was followed by `git worktree remove --force` and emptied the target."""
        import subprocess, guard_shell as gs
        with tempfile.TemporaryDirectory() as d:
            repo = Path(d) / "Repo"
            target, tree = repo / "Godot", repo / ".claude" / "worktrees" / "w"
            target.mkdir(parents=True)
            (target / "godot.exe").write_text("x", encoding="utf-8")
            (tree / "game").mkdir(parents=True)
            link = tree / "Godot"
            made = subprocess.run(["cmd", "/c", "mklink", "/J", str(link), str(target)], capture_output=True)
            if made.returncode:
                try:
                    os.symlink(target, link, target_is_directory=True)
                except (OSError, NotImplementedError):
                    self.skipTest("no junction or symlink can be made here")
            for cmd in ("git worktree remove --force .claude/worktrees/w", "rm -rf .claude/worktrees/w",
                        "Remove-Item -Recurse -Force .claude/worktrees/w"):
                reason = gs.decide("Bash", {"command": cmd}, str(repo))
                self.assertIn("link-delete", reason or "", cmd)
                self.assertIn(".claude/worktrees/w/Godot", reason)
            self.assertIsNone(gs.decide("Bash", {"command": "rm -rf .claude/worktrees/w/game"}, str(repo)))
            self.assertIsNone(gs.decide("Bash", {"command": "git worktree list"}, str(repo)))
            subprocess.run(["cmd", "/c", "rmdir", str(link)], capture_output=True)   # the link alone
            self.assertTrue((target / "godot.exe").is_file())
            self.assertIsNone(gs.decide("Bash", {"command": "git worktree remove --force .claude/worktrees/w"}, str(repo)))

    def test_guard_shell_refuses_the_standing_rules_and_lets_normal_calls_through(self):
        import guard_shell as gs
        with tempfile.TemporaryDirectory() as d:
            repo = str(Path(d) / "Repo")
            (Path(repo) / "_meta" / "memory").mkdir(parents=True)
            (Path(repo) / "GDD.md").write_text("x", encoding="utf-8")
            (Path(repo) / "_meta" / "memory" / "m.md").write_text("x", encoding="utf-8")
            sh = lambda c, tool="Bash": gs.decide(tool, {"command": c}, repo)
            wr = lambda p, tool="Write": gs.decide(tool, {"file_path": p}, repo)
            for bad in ['python -c "print(1)"', "python -I -c 'x'", "node -e 1", "python - <<'EOF'\nx\nEOF",
                        "cat a.py | python", "sed -i 's/a/b/' GDD.md", "echo x >> GDD.md", "echo x | tee GDD.md",
                        "cd _tools && ls", f'cd "{repo}" && git status', f"cat {repo}/GDD.md"]:
                self.assertIsNotNone(sh(bad), bad)
            self.assertIsNotNone(sh("'x' | Set-Content GDD.md", "PowerShell"))
            self.assertIsNotNone(sh("@'\nx\n'@ | python -", "PowerShell"))
            for ok in ["python -I _tools/links.py", "git commit -m \"$(cat <<'EOF'\nmsg\nEOF\n)\"",
                       "grep -n x GDD.md 2>&1 | head", "python -I _tools/links.py > /dev/null",
                       "echo x > new.txt", "sed -n '1,5p' GDD.md", "git log --oneline | head -5",
                       '& "C:\\Users\\me\\Godot.exe" --path game', "grep -n stream _tools/godot_run.py",
                       "python -I _tools/test_generate.py"]:
                self.assertIsNone(sh(ok), ok)
            rex = lambda c, agent: gs.decide("Bash", {"command": c}, repo, agent=agent)   # L21, queue #6
            for cmd in ["python -I _tools/godot_run.py all > /dev/null", "py -I _tools\\mutate.py --since abc",
                        "python -I _tools/ui_shots.py 0.2=game", "python -I _tools/build.py --smoke"]:
                self.assertIn("rex-runs-scripts", rex(cmd, None), cmd)              # the main session
                self.assertIn("rex-runs-scripts", rex(cmd, "qa-build-engineer"), cmd)
                self.assertIsNone(rex(cmd, "script-runner"), cmd)                  # Rex runs them
            probe = "python -I _tools/godot_run.py unit --only test_a,test_b --time-scale 6"   # item 19, option A
            self.assertIn("rex-runs-scripts", rex(probe, "qa-build-engineer"))   # no allow file yet
            gs.allow_probes(60, repo)
            self.assertIsNone(rex(probe, "qa-build-engineer"))                   # the operator allowed probes
            for cmd in ["python -I _tools/godot_run.py all --only test_a", "python -I _tools/godot_run.py unit",
                        "python -I _tools/mutate.py --only x", f"{probe} && python -I _tools/godot_run.py all"]:
                self.assertIn("rex-runs-scripts", rex(cmd, "qa-build-engineer"), cmd)   # full suites stay Rex's
            self.assertIn("rex-runs-scripts", rex(probe, None))                  # the main session: still Rex
            self.assertIn("rex-runs-scripts", rex(probe, "programmer"))
            gs.allow_probes(-1, repo)
            self.assertIn("rex-runs-scripts", rex(probe, "qa-build-engineer"))   # expired
            self.assertIsNotNone(wr("GDD.md"))                                 # overwrite: use Edit
            self.assertIsNone(wr("GDD.md", "Edit"))
            self.assertIsNone(wr(str(Path(repo) / "new.md")))
            self.assertIsNone(wr("_meta/memory/m.md"))                           # memories are replaced whole
            self.assertIsNotNone(wr("C:/Users/x/AppData/Local/Temp/draft.md"))   # drafts live in the repo
            self.assertIsNone(wr("C:/Users/x/.claude/plans/p.md"))
            art = lambda **k: gs.decide("Artifact", k, repo)
            self.assertIsNotNone(art(file_path="game/reports/votes/design-votes.html"))
            self.assertIsNotNone(art(file_path="game/reports/variants/fork/round-4/vote.html"))
            self.assertIsNone(art(file_path="game/reports/votes/design-votes.html", url=gs.DESIGN_VOTES))
            self.assertIsNotNone(art(action="open", url=gs.DESIGN_VOTES))
            self.assertIsNone(art(file_path="report.html"))
            self.assertIsNone(wr("game/tests/t.gd", "Edit"))                     # no goal run: the main session may edit
            lock = Path(repo) / gs.LOCK
            lock.parent.mkdir(parents=True, exist_ok=True)
            lock.write_text("{}", encoding="utf-8")
            self.assertIn("goal-run-owns-game", wr("game/tests/t.gd", "Edit"))  # a live run owns the build folders
            self.assertIn("goal-run-owns-game", wr("game/scripts/new.gd"))
            self.assertIsNone(wr("game/reports/goal/notes.md", "Edit"))         # its reports stay open
            self.assertIsNone(wr(".claude/worktrees/fix/game/tests/t.gd", "Edit"))   # the main session's way: a worktree
            import os, time
            from unittest import mock
            with mock.patch.dict(os.environ, {"CHILLBEE_HEADLESS": "1"}):
                self.assertIsNone(wr("game/tests/t.gd", "Edit"))                 # the run's own agents
            old = time.time() - gs.STALE - 60
            os.utime(lock, (old, old))
            self.assertIsNone(wr("game/tests/t.gd", "Edit"))                     # a stale lock is ignored

    def test_spec_lint_catches_the_item_13_contradiction_and_multi_item_lines(self):
        import spec_lint as sl
        spec = ("---\nversion: 9.9\n---\n# 9.9\n\n## Changes\n\n"
                "1. **Spin goes to the second stop** Pressing Spin moves the camera there. So the farm view never cranks.\n\n"
                "2. **Centrifuge text sits on the centrifuge** `CentrifugeLabel` follows the lid anchor.\n\n"
                "## Contract\n\n- **Quinn (`tests/`):**\n"
                "  - item 1: pressing Spin from the farm view ends at the second stop;\n"
                "  - item 2: while cranking, `CentrifugeLabel` stays on the anchor in the farm view and at the second stop;\n"
                "  - items 1 and 2: the label and Spin never overlap;\n"
                "  - mutations: items 1 and 2 each catch one mutation.\n")
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "9.9-x.md"
            p.write_text(spec, encoding="utf-8")
            fails, warns = sl.check_lines(p)
            self.assertEqual(len(fails), 1)                       # "items 1 and 2", not the mutations line
            self.assertIn("names items 1, 2", fails[0])
            pairs = sl.review(p, only=2)
            self.assertTrue(any(a[0] == 1 and b[0] == 2 and "crank" in shared for a, b, _, shared in pairs))
            self.assertEqual(sl.lint(p, out=lambda line: None), 1)

    def test_spec_lint_pairs_a_full_screen_cover_with_a_timed_toast(self):
        # L52: 0.3 item 3 made the Shop full-height; item 4's 4 s toast played under it, unread
        import spec_lint as sl
        head = "---\nversion: 9.9\n---\n# 9.9\n\n## Changes\n\n"
        cover = "1. **Shop** The open Shop is a full-height sheet over the whole screen.\n\n"
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "9.9-x.md"
            p.write_text(head + cover + "2. **Visitor** On `thriving` the toast `toast_x` shows for 4 s.\n", encoding="utf-8")
            self.assertEqual([(c, t) for c, _, t, _ in sl.cover_pairs(p)], [(1, 2)])
            p.write_text(head + cover + "2. **Visitor** On `thriving` the toast `toast_x` waits until the Shop closes, "
                         "then shows for 4 s.\n", encoding="utf-8")
            self.assertEqual(sl.cover_pairs(p), [])            # the timed item already says it waits

    def test_contract_check_fails_an_emitted_signal_nobody_connects(self):
        # L52: patch_slots.gd emitted toast_requested and nothing connected it, so the toast never showed
        import contract_check as cc
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "scripts").mkdir()
            (root / "tests").mkdir()
            (root / "scripts" / "a.gd").write_text(
                "signal said(k: String)\nsignal heard\nsignal hook\n"
                "func f():\n\tsaid.emit(\"x\")\n\theard.emit()\n\thook.emit()\n", encoding="utf-8")
            (root / "scripts" / "b.gd").write_text("func g(a):\n\ta.heard.connect(g)  # said.connect( in a comment\n",
                                                   encoding="utf-8")
            (root / "tests" / "t.gd").write_text("func t(a):\n\tawait a.hook\n", encoding="utf-8")
            problems, notes = cc.check_signals(str(root), known={})
            self.assertEqual(len(problems), 1)
            self.assertIn("signal said", problems[0])
            problems, notes = cc.check_signals(str(root), known={"a.gd:said": "item 9 connects it"})
            self.assertEqual(problems, [])
            self.assertTrue(notes[0].startswith("NOTE a.gd:said"))

    def test_build_sets_version_and_zips_web_at_root(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "project.godot").write_text('[application]\n\nconfig/name="X"\nconfig/version="0.1.0"\n', encoding="utf-8")
            self.bu.set_version(str(root), "0.1.2")
            self.assertIn('config/version="0.1.2"', (root / "project.godot").read_text(encoding="utf-8"))
            (root / "builds" / "web").mkdir(parents=True)
            (root / "builds" / "web" / "index.html").write_text("<html></html>", encoding="utf-8")
            ok, _ = self.bu.zip_web(str(root), "0.1.2")
            self.assertTrue(ok)


NEON, MEADOW = "0.2, 1.0, 0.1", "0.62, 0.84, 0.52"


class StyleLoop(unittest.TestCase):
    """style_loop.py with a fake renderer, a fake Bob and a fake Vera, in a throwaway workspace."""

    def setUp(self):
        import style_loop as sl
        self.sl = sl
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "game" / "materials").mkdir(parents=True)
        (self.root / "game" / "scenes").mkdir()
        (self.root / "_meta").mkdir()
        shutil.copy(TOOLS.parent / "STYLE_GUIDE.md", self.root / "STYLE_GUIDE.md")
        self.mat(MEADOW)
        self.saved = g.ROOT, g.run_agent, sl.render, sl.gate
        g.ROOT = self.root
        sl.render = self.fake_render
        self.gates = []
        sl.gate = lambda game: (self.gates.append(game) or (True, "unit PASS (fake)", set()))

    def tearDown(self):
        g.ROOT, g.run_agent, self.sl.render, self.sl.gate = self.saved
        self.tmp.cleanup()

    def mat(self, rgb, game="game"):
        (self.root / game / "materials" / "ground_patch.tres").write_text(
            f'[gd_resource type="StandardMaterial3D" format=3]\n\n[resource]\nalbedo_color = Color({rgb}, 1.0)\n',
            encoding="utf-8")

    @staticmethod
    def fake_render(game, out):
        out.mkdir(parents=True, exist_ok=True)
        (out / "measure.json").write_text('{"cell_px_min": 45.1}', encoding="utf-8")

    def fake(self, verdicts, fixes=True, tokens=1):
        calls, prompts = [], []

        def agent(name, prompt):
            calls.append(name)
            prompts.append(prompt)
            reply = ""
            if name == self.sl.BUILDER and fixes:  # Bob edits the folder his prompt names (the sandbox by default)
                self.mat(MEADOW, re.search(r"editing `([^`]+)/scenes/`", prompt).group(1))
            elif name == self.sl.CRITIC:
                n = re.search(r"round (\d+)", prompt).group(1)
                said = verdicts.pop(0)
                row = {"FAIL": "| 1 | V7 | 01-farm-start.png | clutter | move the truck |",
                       "FAIL:designer": "| 1 | V8 | 04-bucket-full.png | truck outshines honey | Mute the bar. "
                                        "(designer) A: shrink the truck. B: enlarge the honey props. |",
                       "FAIL:guide": "| 1 | V3 | 01-farm-start.png | a third accent | add a new token (designer) |",
                       "FAIL:ui": "| 1 | V7 | 01-farm-start.png | clutter | move the truck |\n"
                                  "| 2 | V13 | 06-truck-away.png | Dev label faint | (UI) cream text, ink outline |"
                       }.get(said, "")
                reply = (f"### Critic, round {n}\nVERDICT: {said.split(':')[0]}\n| # | Rule | Shot | Finding | Fix |\n"
                         f"|---|---|---|---|---|\n{row}\n")
            return reply, {"tokens": tokens, "turns": 1, "seconds": 1}
        g.run_agent = agent
        return calls, prompts

    def run_loop(self, *args):
        with contextlib.redirect_stdout(io.StringIO()):
            return self.sl.main(["s", *args])

    def board(self):
        return (g.run_dir(self.root / "game" / "reports" / "style" / "s", newest=True) / "blackboard.md").read_text(encoding="utf-8")

    def test_pass_in_round_one(self):
        calls, _ = self.fake(["PASS"])
        self.assertEqual(self.run_loop(), 0)
        self.assertEqual(calls, [self.sl.CRITIC])
        self.assertIn("result: pass", self.board())

    def test_script_fail_then_bob_fixes_then_pass(self):
        self.mat(NEON)
        calls, prompts = self.fake(["PASS", "PASS"])  # Vera passes, but the script blocks round 1
        self.assertEqual(self.run_loop(), 0)
        self.assertEqual(calls, [self.sl.CRITIC, self.sl.BUILDER, self.sl.CRITIC])
        self.assertIn("V1", prompts[1])
        self.assertIn("ground_patch", prompts[1])
        board = self.board()
        self.assertIn("### Changes (Bob), round 2", board)
        self.assertIn("No rows: every script rule passes.", board)
        self.assertIn("Your round 1 verdict", prompts[2])

    def test_max_rounds(self):
        calls, _ = self.fake(["FAIL", "FAIL"], fixes=False)
        self.assertEqual(self.run_loop("--max-rounds", "2"), 1)
        self.assertEqual(calls, [self.sl.CRITIC, self.sl.BUILDER, self.sl.CRITIC])
        self.assertIn("result: needs-review", self.board())

    def test_token_cap(self):
        calls, _ = self.fake(["FAIL"], tokens=10)
        self.assertEqual(self.run_loop("--max-tokens", "5"), 1)
        self.assertEqual(calls, [self.sl.CRITIC])

    def test_sandbox_leaves_the_game_alone_and_writes_a_patch(self):  # designer, 2026-11-20
        self.mat(NEON)
        calls, prompts = self.fake(["PASS", "PASS"])
        self.assertEqual(self.run_loop(), 0)
        self.assertIn("_meta/sessions/runs/style-s-run-1-sandbox/game/scenes/", prompts[1])
        live = (self.root / "game" / "materials" / "ground_patch.tres").read_text(encoding="utf-8")
        self.assertIn(NEON, live)                                    # the game itself is unchanged
        patch = (self.root / "game" / "reports" / "style" / "s" / "run-1" / "sandbox.patch").read_text(encoding="utf-8")
        self.assertIn("+++ b/game/materials/ground_patch.tres", patch)
        self.assertIn(MEADOW, patch)
        self.assertIn("sandbox.patch", self.board().split("## Result")[1])
        self.assertEqual(len(self.gates), 2)                          # the baseline, then Bob's one turn

    def test_a_round_that_fails_the_gate_is_undone(self):
        self.mat(NEON)
        runs = []   # the baseline already fails t_old; Bob's turn adds t_layout_objects_on_cells

        def gate(game):
            runs.append(game)
            return False, "unit FAIL", {"t_old"} | ({"t_layout_objects_on_cells"} if len(runs) > 1 else set())
        self.sl.gate = gate
        self.fake(["PASS", "PASS"])
        self.assertEqual(self.run_loop("--max-rounds", "2"), 1)        # script row stays: Bob's fix was undone
        sand = self.root / "_meta" / "sessions" / "runs" / "style-s-run-1-sandbox" / "game" / "materials" / "ground_patch.tres"
        self.assertIn(NEON, sand.read_text(encoding="utf-8"))
        self.assertIn("FAIL: Bob’s edits this round were undone, they broke t_layout_objects_on_cells", self.board())
        self.assertNotIn("broke t_old", self.board())                  # a baseline failure is not his

    def test_a_baseline_failure_does_not_undo_a_turn(self):
        self.mat(NEON)
        self.sl.gate = lambda game: (False, "unit FAIL", {"t_old"})
        self.fake(["PASS", "PASS"])
        self.assertEqual(self.run_loop(), 0)                           # Bob's fix stays and the round passes
        self.assertIn("PASS: no test fails that passed before the run", self.board())

    def test_ui_edits_are_put_back(self):  # designer, 2026-11-20: Bob moved the Spin icon; UI is not his
        game = self.root / "game"
        main = game / "scenes" / "main.tscn"
        old = ('[sub_resource type="StyleBoxFlat" id="StyleBox_tag"]\nbg_color = Color(0.38, 0.34, 0.3, 0.5)\n\n'
               '[node name="Ground" type="MeshInstance3D" parent="FarmWorld"]\nvisible = true\n\n'
               '[node name="SpinIcon" type="Button" parent="FarmUIRoot/FarmUI"]\nscreen_offset = Vector2(0, 0)\n')
        main.write_text(old, encoding="utf-8")
        before = self.sl.snapshot(game)
        main.write_text(old.replace("0.38, 0.34", "0.3, 0.22").replace("visible = true", "visible = false")
                        .replace("Vector2(0, 0)", "Vector2(-230, -60)")
                        + '\n[node name="NewLabel" type="Label" parent="FarmUIRoot/FarmUI"]\ntext = "x"\n',
                        encoding="utf-8")
        put_back = self.sl.guard_motion(before, game)
        text = main.read_text(encoding="utf-8")
        self.assertIn("Vector2(0, 0)", text)
        self.assertIn("0.38, 0.34", text)
        self.assertNotIn("NewLabel", text)
        self.assertIn("visible = false", text)                        # a 3D scene node is still Bob's
        self.assertTrue(all("(UI)" in x for x in put_back))

    def test_parts_added_to_a_picked_prop_are_removed(self):  # r5 left empty rim nodes in the patch
        game = self.root / "game"
        jar = game / "scenes" / "props" / "jar.tscn"
        jar.parent.mkdir(parents=True, exist_ok=True)
        old = '[sub_resource type="CylinderMesh" id="Mesh_glass"]\nheight = 0.26\n\n[node name="Jar" type="Node3D"]\n'
        jar.write_text(old, encoding="utf-8")
        before = self.sl.snapshot(game)
        jar.write_text(old.replace("\n\n[node", '\n\n[sub_resource type="TorusMesh" id="Mesh_rim"]\nrings = 16\n\n[node')
                       + '\n[node name="JarRimTop" type="MeshInstance3D" parent="."]\nmesh = SubResource("Mesh_rim")\n',
                       encoding="utf-8")
        put_back = self.sl.guard_motion(before, game)
        self.assertEqual(jar.read_text(encoding="utf-8").rstrip(), old.rstrip())  # a blank separator line may stay
        self.assertTrue(any("picked prop shape" in x for x in put_back))

    def test_ui_rows_go_to_patricia_and_3d_rows_to_bob(self):  # designer, 2026-11-20: UI is not Bob's
        calls, prompts = self.fake(["FAIL:ui", "PASS"])
        self.assertEqual(self.run_loop(), 0)
        self.assertEqual(calls, [self.sl.CRITIC, self.sl.BUILDER, self.sl.UI_FIXER, self.sl.CRITIC])
        self.assertIn("move the truck", prompts[1])
        self.assertNotIn("Dev label", prompts[1])
        self.assertIn("Dev label", prompts[2])
        self.assertIn("UI_DESIGN.md", prompts[2])
        self.assertNotIn("move the truck", prompts[2])
        self.assertIn("Start the Fix of every row about the UI with `(UI)`", prompts[0])
        bob, ui = self.sl.split_rows(["| 1 | V11 | `scenes/main.tscn:3` | 90 px | 120 px |",
                                      "| 2 | V1 | `materials/x.tres:2` | ΔE 14 | recolour |"], self.root / "game")
        self.assertEqual((len(bob), len(ui)), (1, 1))                 # V11 is a UI rule

    def test_patricia_may_restyle_the_ui_but_not_move_it(self):
        game = self.root / "game"
        main = game / "scenes" / "main.tscn"
        old = ('[node name="SpinIcon" type="Button" parent="FarmUIRoot/FarmUI"]\n'
               'theme_override_colors/font_color = Color(0.5, 0.5, 0.5, 1)\nscreen_offset = Vector2(0, 0)\n')
        main.write_text(old, encoding="utf-8")
        before = self.sl.snapshot(game)
        main.write_text(old.replace("0.5, 0.5, 0.5", "1, 0.96, 0.86").replace("(0, 0)", "(-230, -60)"), encoding="utf-8")
        self.mat(NEON)                                                 # a 3D material is not hers
        put_back = self.sl.guard_motion(before, game, self.sl.UI_FIXER)
        text = main.read_text(encoding="utf-8")
        self.assertIn("1, 0.96, 0.86", text)
        self.assertIn("Vector2(0, 0)", text)
        self.assertIn(MEADOW, (game / "materials" / "ground_patch.tres").read_text(encoding="utf-8"))
        self.assertEqual(len(put_back), 2)

    def test_loop_takes_option_a_without_stopping(self):  # designer, 2026-11-20
        calls, prompts = self.fake(["FAIL:designer", "PASS"])
        self.assertEqual(self.run_loop(), 0)
        self.assertEqual(calls, [self.sl.CRITIC, self.sl.BUILDER, self.sl.CRITIC])
        self.assertIn("shrink the truck (the loop's choice A)", prompts[1])
        self.assertNotIn("(designer)", prompts[1])
        self.assertNotIn("enlarge the honey", prompts[1])
        self.assertIn("chose A: shrink the truck", prompts[2])  # Vera is told what the loop picked
        board = self.board()
        self.assertIn("### Loop's choices, round 1", board)
        self.assertNotIn("Waiting for the designer", board)
        self.assertIn("result: pass", board)

    def test_motion_edits_are_put_back(self):  # designer, 2026-11-20: the truck's exit went diagonal
        scene = self.root / "game" / "scenes" / "t.tscn"
        scene.parent.mkdir(parents=True, exist_ok=True)
        old = '[node name="Truck"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3.8, 0, 5.2)\nspeed = 2.0\n'
        scene.write_text(old, encoding="utf-8")
        before = self.sl.snapshot(self.root / "game")
        scene.write_text(old.replace("3.8, 0, 5.2)", "4.6, 0, 6)").replace("speed = 2.0", "speed = 5.0")
                         + "exit_direction = Vector3(1, 0, -1)\n", encoding="utf-8")
        put_back = self.sl.guard_motion(before, self.root / "game")
        text = scene.read_text(encoding="utf-8")
        self.assertIn("4.6, 0, 6)", text)          # a placement change stays
        self.assertIn("speed = 2.0", text)          # motion changes are put back
        self.assertNotIn("exit_direction", text)
        self.assertEqual(len(put_back), 2)
        self.assertIn("Never change how anything moves", self.sl.bob_prompt(2, ["| 1 | V13 | x | y | z |"]))

    def test_picked_prop_size_and_placement_are_put_back(self):  # designer, 2026-11-20: truck shrunk, jars enlarged
        game = self.root / "game"
        (game / "scenes" / "props").mkdir(parents=True, exist_ok=True)
        main, jar = game / "scenes" / "main.tscn", game / "scenes" / "props" / "jar.tscn"
        main_old = ('[node name="Truck" parent="FarmWorld"]\ntransform = Transform3D(0.93, 0, 0, 0, 0.93, 0, 0, 0, 0.93, '
                    '3.8, 0, 5.2)\n\n[node name="JournalButton" type="Button"]\ncustom_minimum_size = Vector2(120, 120)\n')
        jar_old = '[sub_resource type="CylinderMesh" id="Mesh_glass"]\ntop_radius = 0.15\nheight = 0.26\n'
        main.write_text(main_old, encoding="utf-8")
        jar.write_text(jar_old, encoding="utf-8")
        mat = game / "materials" / "glass.tres"
        mat.parent.mkdir(parents=True, exist_ok=True)
        mat.write_text("albedo_color = Color(0.75, 0.85, 0.9, 0.28)\n", encoding="utf-8")
        before = self.sl.snapshot(game)
        main.write_text(main_old.replace("0.93, 0, 0, 0, 0.93, 0, 0, 0, 0.93, 3.8, 0, 5.2", "0.7, 0, 0, 0, 0.7, 0, 0, 0, "
                                         "0.7, 4.6, 0, 6").replace("(120, 120)", "(120, 88)"), encoding="utf-8")
        jar.write_text(jar_old.replace("0.15", "0.18").replace("0.26", "0.3"), encoding="utf-8")
        mat.write_text("albedo_color = Color(0.88, 0.95, 0.98, 0.3)\n", encoding="utf-8")
        put_back = self.sl.guard_motion(before, game)
        self.assertEqual(jar.read_text(encoding="utf-8"), jar_old)
        text = main.read_text(encoding="utf-8")
        self.assertIn("0.93, 3.8, 0, 5.2", text)       # the truck's size and place come back
        self.assertIn("(120, 88)", text)               # a UI node is Bob's to change
        self.assertIn("0.88, 0.95", mat.read_text(encoding="utf-8"))  # colours are Bob's
        self.assertEqual(len(put_back), 3)
        self.assertTrue(all("picked prop size" in x for x in put_back))

    def test_choose_splits_choices_from_true_stops(self):
        held = ["| 1 | V3 | `materials/rim.tres:4` | 3 accents | A: recolour `rim` to charcoal; B: approve `rim` "
                "as a new accent (designer) |",
                "| 2 | V1 | `materials/rim.tres:4` | ΔE 16 | recolour `rim` to truck red; or per the V3 decision on "
                "the same line (designer) |",
                "| 3 | V1 | `materials/x.tres:2` | ΔE 14 | A: recolour to cream (0.9, 0.85, 0.7) (ΔE 13.0); B: allow "
                "the Shadow role (designer) |",
                "| 4 | V3 | 01-farm-start.png | a third accent | add a new token (designer) |"]
        picked, stops = self.sl.choose(held)
        self.assertEqual(stops, [held[3]])
        fixes = {o: b for o, b, _ in picked}
        self.assertIn("| recolour `rim` to charcoal (the loop's choice A) |", fixes[held[0]])
        self.assertIsNone(fixes[held[1]])  # follows the V3 row, no Bob row of its own
        self.assertIn("recolour to cream (0.9, 0.85, 0.7) (ΔE 13.0) (the loop's choice A)", fixes[held[2]])

    def test_designer_stop_then_resume(self):
        self.mat(NEON)
        calls, prompts = self.fake(["FAIL:guide", "PASS"])
        self.assertEqual(self.run_loop(), 1)
        self.assertEqual(calls, [self.sl.CRITIC, self.sl.BUILDER])
        self.assertIn("V1", prompts[1])
        self.assertNotIn("(designer)", prompts[1])  # Bob never gets a held row
        board = self.board()
        self.assertIn("result: waiting-designer", board)
        self.assertIn("## Waiting for the designer", board)
        self.assertIn("new token (designer)", board.split("## Waiting for the designer")[1])
        self.assertNotIn("Loop's choices", board)
        self.assertEqual(self.run_loop("--resume"), 0)
        self.assertEqual(calls[-1], self.sl.CRITIC)
        self.assertIn("Your round 1 verdict", prompts[-1])  # Vera's context survives the stop
        self.assertIn("ground_patch", prompts[-1])  # with Bob's meanwhile diff
        self.assertTrue((self.root / "game" / "reports" / "style" / "s" / "run-1" / "round-2").is_dir())
        board = self.board()
        self.assertIn("result: pass", board)
        self.assertEqual(board.count("## Result"), 1)                    # one Result, rewritten on resume
        self.assertIn("## Resumed", board)
        result = board.split("## Result")[1]
        self.assertTrue(result.endswith("| **Total** | **3** | | | |\n"))  # all three calls of both invocations
        self.assertLess(board.index("## Resumed"), board.index("## Result"))   # Result stays last

    def test_designer_row_in_the_last_round_ends_at_max_rounds(self):
        calls, prompts = self.fake(["FAIL:guide", "FAIL:guide"], fixes=False)
        self.assertEqual(self.run_loop("--max-rounds", "2"), 1)  # round 1 stops for the designer
        self.assertEqual(self.run_loop("--resume", "--max-rounds", "2", "--note", "defer V3"), 1)
        self.assertIn("defer V3", prompts[-1])
        board = self.board()
        self.assertIn("result: needs-review", board)
        self.assertIn("new token (designer)", board.split("## Result")[-1])  # listed as open, not waiting

    def test_style_check_catches_every_fixture(self):
        import style_critic_check as scc
        saved, g.ROOT = g.ROOT, TOOLS.parent
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertTrue(scc.check_script())
        finally:
            g.ROOT = saved

    def test_palette_and_delta_e(self):
        import style_check as sc
        tokens = sc.load_palette(TOOLS.parent / "STYLE_GUIDE.md")
        self.assertIn("truck red", [t["name"] for t in tokens])
        self.assertAlmostEqual(sc.delta_e((1, 1, 1), (1, 0.96, 0.86)), 13.9, places=1)
        self.assertAlmostEqual(sc.delta_e((0.85, 0.2, 0.15), (0.75, 0.2, 0.2)), 16.0, places=1)
        self.assertEqual(sc.accent_limit((TOOLS.parent / "STYLE_GUIDE.md").read_text(encoding="utf-8")), 2)
        self.assertEqual(sc.accent_limit("| V3 | **Accents are rare:** at most 3 accent-role colours |"), 3)


if __name__ == "__main__":
    unittest.main(verbosity=2)
