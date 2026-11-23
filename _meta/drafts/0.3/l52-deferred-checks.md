---
author: orchestrator
type: draft
status: checks 1 and 2 built 2026-11-23 (`_tools/spec_factcheck.py`, goal_agent's assumption stop); check 3 (event shots) still waiting for Quinn and budget
description: The three L52 checks not built on 2026-11-22: a spec fact-check pass, assumption stops, event shots
---
# L52 deferred checks

Approved by the designer on 2026-11-22 (all four L52 fixes). Built the same day: the signal check (`contract_check.py`), the cover pairs (`spec_lint.py`), the "seen, not just visible" checklist line (`goal_agent.py` `INTERACTION_CHECKLIST`). These three wait. One general-purpose agent can build them all, since they share `_tools/test_goal_agent.py`.

1. **Fact-check pass.** New `_tools/spec_factcheck.py`. Deterministic: pull each sentence of a spec's `## Changes` that states existing behaviour ("like the", "as in 0.", "as today", "as before", "unchanged", "stays", "still", "only", "never", "Today ", "keeps"), with its item. Agent: send only the claims to one Haiku call through goal_agent's runner (`generate.run_agent`, with its logging and budget guard), asking TRUE / UNTRUE / UNCLEAR with the file:line read. Write `game/reports/goal/<version>/factcheck.md`. `--no-agent` prints the claims only. goal_agent: a build run refuses to start unless `factcheck.md` is newer than the spec and has no UNTRUE row; UNCLEAR rows become designer stops. The 0.3 case it must catch: item 2's "Farm view only, like the rest of the info row" (false: `farm_ui.gd` `fit_top_info` keeps `TopInfo` at the second stop).
2. **Assumption stops.** goal_agent already stops on `(designer)` rows in replies. Also find "I assumed", "assuming", "I guessed", "presumably", "I took it that" lines and list each as a designer stop ("Agent assumed: ...; confirm or correct the spec"), keeping L49's rule (a line that only mentions the tag isn't a question). The 0.3 case: Quinn's "I assumed `JournalButton` still sits in the shop sheet" (`game/reports/goal/0.3/blackboard.md`, around line 911).
3. **Event shots.** `ui_shots.py` (and Quinn's `game/tests/ui_compare_shots.gd`) take a shot 1 s after each event: a purchase, thriving, the last patch bought with the Shop open, a Shop close with a toast waiting. Investigate the two files first; the `.gd` side goes to Quinn.

Tests in `_tools/test_goal_agent.py` (no real agent calls); docs: `_tools/CONTEXT.md` rows, `GOAL_AGENT.md`, the fact-check step in `game/CONTEXT.md`; update L52's Prevention line when built.
