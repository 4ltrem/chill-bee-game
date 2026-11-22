---
name: future-tbd
description: "Designer's backlog for the workspace's own tooling - episodic memory upgrade, a dream skill, syncing transcripts between machines"
metadata:
  node_type: memory
  type: project
  originSessionId: 472d224a-a84f-4a66-bfff-00b669226a91
  modified: 2026-11-22T06:26:13.795Z
---

TBD items the designer named on 2026-11-01, not started:

1. **Episodic memory upgrade.** Use the session records (`_meta/sessions/*/decisions.md` in git; transcripts,
   subagent and `runs/` transcripts kept locally) so a future session can recall what happened in past ones,
   not only the short facts in `_meta/memory/`.
2. **Dream skill.** A skill that consolidates memories between sessions (reviews recent sessions, merges,
   corrects and prunes memories). Claude Code has a built-in background consolidation switch,
   `autoDreamEnabled`, worth checking before building one.
3. **Sync transcripts between machines** (desktop PC and laptop). Transcripts stay out of git (designer's
   decision, 2026-11-01: they hold the account email, my reasoning and everything read, and add 2-4 MB per
   session), so they need another route.
4. **Learnings file** (added 2026-11-05, D92; BUILT 2026-11-08 as `_meta/learnings.md`, kept by end-of-day step 2). One file listing everything that broke, how it was noticed and how
   it was fixed. Seed it from the decision logs, the memories and the QA reports. Examples: Quinn's hour-long
   mutate run (D89), the agent run that hit the 5-hour limit (which led to the budget guard), and the red 0.1.3
   step b.
5. **See the headless agents again** — **BUILT 2026-11-21 (Opus): `_tools/live.py` (scripts' own steps too), `watch.py`, side pane `_tools/live-pane/` (`claude --plugin-dir _tools/live-pane`, `/live`); uncommitted until the designer's yes.** History: (added 2026-11-07; (a) built 2026-11-07 late; (b) `watch.py` and (c) the live side pane both approved 2026-11-08 (designer: "I need everything visible, also the live pane"; the status line alone isn't enough). Also: live.json must cover the scripts' own steps, not only agents: unit/contract checks, mutate, shots, commits (on 2026-11-08 the status line showed nothing while goal_agent ran `godot_run.py unit` itself, and the designer thought it had stalled). The script loops (`goal_agent.py`, `generate.py`,
   `style_loop.py`) run agents as `claude -p`, so they don't show in Claude Code's agent list as Agent-tool
   subagents did ("I can't see as clearly which sub agents are running"). Recommended, in order:
   (a) `generate.run_agent` writes `_meta/usage/live.json` on each agent start and end (agent, loop, run, goal or
   round, start time, model), and `statusline.py` shows it, e.g. `▶ goal 0.1.4 · C7 · Patricia 4m · Bob 2m`
   (about 30 lines and a test; all three loops share `run_agent`);
   (b) optionally `--output-format stream-json` teed to `<run>/live/<agent>.log`, plus `_tools/watch.py` that prints
   one line per tool call, to watch in a terminal split;
   (c) only if the status line is too small: a Claude Code mod side panel reading `live.json` (`plugin-authoring` skill).
   Do it after the shared blackboard format lands in `generate.py`.

6. **Onboarding guide** (deferred 2026-11-07, "not a priority rn"). `ONBOARDING.md` draft at the repo root, share
   link https://claude.ai/claude-code/onboard/34Mn5DdRy4BS (short_code 34Mn5DdRy4BS). Still to do: confirm the team
   name, fill Team Tips and Get Started, then refresh the link with ShareOnboardingGuide mode=update.

7. **Assignment 3 grader's next steps** (feedback received 2026-11-08; grade comment: "Solid, honest work").
   SCHEDULED by the designer 2026-11-08 in MILESTONES.md Open: (b) in M3, (a) in M4 (0.2.x, A7 engine integration).
   (a) Wire one approved content file (e.g. a Bee Journal entry, EN/FR) into Godot's own string format
   (a `.csv`/`.po` translation file loaded by `TranslationServer`) so "passed" becomes "in-game".
   (b) Cap-stop summary: `generate.py` (~line 492) only says "Still FAIL ... stopped at the token cap"; add the
   last round's open FAIL rows, their owner (William or Ruth) and the exact re-queue command to the blackboard
   summary and the console line.

8. **`/goal` + `goal_agent.py` together** (designer, 2026-11-08, after running `/goal finish 0.1.4` in a parallel
   session and finding it more intuitive). Use native `/goal` as the outer loop with a checkable condition, e.g.
   "`python -I _tools/goal_agent.py SPEC --plan` reports nothing left to build and the latest unit run is green", so the
   script's gaps decide when the work is done. Pitfalls seen in that run: the judge reads only the transcript (it trusted an
   old unit.log), and it repeated "stuck at the same step" when budget_guard blocked it, so the condition should allow
   "paused by budget_guard" as a stop. Final run: "finish 0.1.4" was judged unmet 16× (it needed the designer's play-test
   and the itch upload), while "feedback for 0.1.4 implemented and bugs fixed" was met on its first check, so never put a
   human step in the condition. Comparison written up in GOAL_AGENT.md "Compared with Claude Code's `/goal`".

9. **Assignment 4 grader's next steps** (feedback received 2026-11-17; "Lovely, rigorous work ... Excellent pipeline";
   standout: Clara). SCHEDULED by the designer 2026-11-17: both (a) and (b) are built BEFORE the next
   `generate.py` content run, new or `--revise` (MILESTONES.md Open). If asked to start a content run first, build these first or say so.
   (a) Cut the content loop's token cost: a cheaper verification pass (e.g. Haiku or a script for Clara's mechanical
   checks, Sonnet only for tone/lore) and cached facts (Ruth's fetched source quotes reused by URL+date instead of
   Clara re-fetching every URL each round).
   (b) Promote a couple of voice rules (STYLE_GUIDE T1-T6) to hard script checks, as `style_check.py` does for the
   visual rules: T2 Glossary terms and T5 cited GDD sections are the mechanical candidates. (b) BUILT 2026-11-17
   as `_tools/voice_check.py` (run by generate.py each round). (a) BUILT 2026-11-20: `_tools/source_cache.py`
   (Ruth's quotes by URL + date in Clara's prompt, no re-fetch), placeholder cells and check 5 by script; no
   Haiku pass (see MILESTONES.md Open). The content-run gate is lifted.

10. **Godot 4.2.1 -> 4.7.2 upgrade** (designer, 2026-11-17: assessed by a subagent, "add it to future-tbd").
    NOT before the final deadline (11/29; moved from 11/24 on 2026-11-22); do it on a branch right after a milestone. Assessment (subagent, not yet
    re-checked): 4.7.2-stable is real (18 Aug 2026; 4.8 in beta); no GDScript API break found in the 4.3-4.7 guides;
    watch `scripts/ui_bounds_overlay.gd` lines in shots. One-way: the newer editor rewrites project.godot/.tscn/.tres,
    adds `.uid` sidecars, and 4.2.1 can't reopen it. To change: the hard-coded 4.2.1 exe path (`_tools/godot_run.py`,
    `build.py`, `model_shots.py`, `pick_match.py`, `style_loop.py`, `.claude/settings.json`, `builder.md`, `render.gd`,
    `game/CONTEXT.md`); 4.7.2 export templates; the Web preset turns single-threaded (fine for itch). Unverified until a
    real run: `godot_run.py` noise filter, the "exits 1 on empty project" workaround, `build.py`'s exit-139 retry, Android
    SDK/JDK needs. Procedure: (1) 4.7.2 alongside 4.2.1, `GODOT` env to the new exe, branch; (2) open/refresh once and
    commit the format-only rewrite alone; (3) Rex: unit then `all` vs 178/178; (4) `ui_shots.py` + style shots old vs
    new by eye; (5) `build.py --smoke` + a real browser check; (6) only then update paths and the workarounds.

11. **A UI agent** (designer, 2026-11-20: "Patricia for now, add the UI agent to backlog"). The visual style loop
    sends UI rows (Vera's `(UI)` rows, V10-V12, rows on the FarmUIRoot tree or UI scripts) to a UI refiner, not
    Bob; Patricia does it for now (`style_loop.py` `ui_prompt`, guard: no screen_offset/anchor/position/layout edits).
    A dedicated agent hired through Martin would read `UI_DESIGN.md` first, own the UI scenes and UI scripts, and
    later the 0.3.0 UI pass. Swap `UI_FIXER` in `style_loop.py` to it once hired.

12. **Tests that survive feature changes** (added 2026-11-21; learnings L39). Items 9 and 14 of 0.2.1 turned
    6-11 stale tests red each, and the play suite sat red from 0.1.4 unseen because `goal_agent.py` checks unit only.
    BUILT 2026-11-21 (Opus session): (b) `goal_agent.py` test-impact list briefs Quinn beside each change
    (`--impact GOAL`); (c) the windowed suites it reaches run in the step, and the full suite at the end of a run;
    (a)/(d) as rules in Quinn's briefs and agent file. Left: a one-off Quinn pass moving the existing copied flows
    (second stop, shop open, CRANKING waits, the 720x1280 literals in about 20 lines) onto shared helpers and
    `tests/flow.gd`, after C14 settles; optionally a lint for literal sizes and indexes in `game/tests/`.

**Why:** the designer keeps every session for analysis and wants memory to work across machines.

**How to apply:** when the designer asks what's next for the workspace tooling, or touches memory, sessions or
exports, raise these. Don't start them unasked. Related: [[end-of-day-routine]].
