---
name: session-handoff
description: "Where work stands (2026-11-07 evening): Round 8 votes cast and read; next: apply them (votes-round8-answers.md), redo C5 frames, rerun goal agent for C8, C5, tests; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 81c6a13d-f79a-4428-bc66-986f58e5b2ff
  modified: 2026-11-08T01:18:50.260Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** terminal `claude` CLI in VS Code. The status line (`_tools/statusline.py`) logs plan usage by itself ([[usage-calibration]]). Main folder on `milestone/0.1.4` (branched from `milestone/0.1` by the goal agent), no worktrees ([[one-folder-rule]]).

**Where things stand (2026-11-07):**
- **M3 built:** `_tools/goal_agent.py` (`--plan`, `--dry-run`, the loop, `--accept GOAL --note` for a manual fix), tests `_tools/test_goal_agent.py` (fixtures in `_tools/fixtures/goal/`), commits e5a2a0b, 91603c2 on `milestone/0.1`. `--plan` marks 0.1.2 and 0.1.3 done and 0.1.4 missing. Blackboard: `game/reports/goal/0.1.4/blackboard.md`; ledger `game/reports/goal/ledger.json`.
- **0.1.4 run (exited 15:09; the board can now be converted):** built and committed on `milestone/0.1.4`: H c31bbb8, C2 90e03c6 (accepted: `_nudged_clear` test fix), C4 fb94e04, C7 90b18b9, C3 747a5a1, C1 b431c26, C6 287bdd0, T2.1 b65f5e1 + T2.2 2c464bc (accepted). 27 agent calls, 6.1M tokens. Orchestrator fixes: regenerated `tests/fixtures/recording_fill_and_back.json` (it tapped 0.1.3's Harvest spot; both X1 replay tests pass again).
- **Left to build** (rerun `goal_agent.py 0.1.4-ui-placement.md` in the background, after the votes): C8 (spec item 8, Hint below Back; Bob already narrowed `HintLabel` in T2's fix round, so T8.1 may pass at once), test lines T1.1, T3.x, T4.x, T6.1, T7.1, T8.1 and the mutations line; C5 after its vote. From the 0.1.4 play-test (2026-11-07, in the spec): C1 rebuild (meter fill unclipped, drawn in front of the button), new item 9 (`PausedLabel` above the upgrades), new item 10 (combs visible in the hive before a frame pops out; built with C5), C7 rebuild, multi-point shots of gradual animations. C1 and C7 are in the ledger as built, so make sure they get redone. Open for Quinn: mutation "buttons are not nudged clear of each other" is MISSED (the nudge test proves too little).
- **Uncommitted `goal_agent.py` fixes from this session** (beside the format work, 20+ tests pass): a mutation-only failure goes to Quinn, only the ledger marks a change built (a node that predates it no longer counts), keyword ties map a test line to the tied changes only.
- `pan_zoom_size` 9.3 warns "needs 9.540" for the second stop (since 0.1.3c, not new): add it to the votes list.
- **C5 (bigger frames) waits on the designer:** Patricia's handoff, open question 1: 2.15× frames don't fit the hive body; about 1.35× with `grid_cols` 7→5, or a wider body.
- `GOAL_AGENT.md` (A5 README) is committed through the run's stop at 15:09 (c782135), with the rows from C6 on drafted in `_meta/drafts/0.1.4/GOAL_AGENT-c6-onward.md`. After the votes and the rest of the run: `build.py 0.1.4 --smoke`, itch upload by the designer, submit. A5 due 11/15 ([[course-milestones]]); 0.1.4 goes on itch as the A5 demo ([[itch-upload-rule]]).

**Next session, first: rerun the goal agent** (`goal_agent.py 0.1.4-ui-placement.md`, background). Round 8 and 9 votes are applied and in the spec (answers section, item 5); all suites green after the test fixes (unit 138, play 237). Left to build: C8, C5 (round 9 variant a: 5×2, more hex spacing, pile cells match frame cells), item 9, item 10, and rebuilds of C1 (meter clipping) and C7 (prompt). C1 and C7 are in the ledger as built: make the run redo them (spec text changed, or clear their ledger rows). The Design Votes page is v13 at https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (`game/reports/ui-compare/design-votes.html`); round 9 renders are in `game/reports/variants/hive-frames-r9/` (ids must be new per round).

**Content (2026-11-07):** `content/guides.md` holds six guides (Melli, Pip, Lady Aura, Miel, Queen Maeve, Lumi) with 60 signature lines, waiting for approval. GDD guide line and Meadow flowers applied. `ONBOARDING.md` (another session's team-onboarding page) is left untracked on purpose. `compare_page.py add` now takes per-stop `--stop/--option/--ref/--shot/--prefix` groups and refuses to write duplicate ids. Uncommitted: `compare_page.py`, `ui_shots.py --set`, `ui_compare_shots.gd`, the `vote-*` renders, `design-votes.md/.html`, the drafts, and the memory files. Bash: no `cd` prefix (the cwd is already the repo) and chain listed commands only ([[repo-only]]).

**Blackboard format (decided 2026-11-07, committed 037a1a2):** all three boards (content, style, goal) follow one format, `_templates/blackboard.md`. It has front matter `result:`, a Request, the first round or pass in full and then changes only, inputs linked and outputs inline, Waiting/Resumed sections, and one Result rewritten in place from `<board>.calls.json`. `--plan` and `--dry-run` write nothing to the board. The shared helpers are in `generate.py` (`board_start`, `waiting`, `resumed`, `finish_board`), with tests in both suites. The 0.1.4 board was converted once after its run ended. Old content and style boards stay as history.

**C7 answered (play-test 2026-11-07):** the pile loads, but the "press Spin" prompt comes back while already in spin mode. Spec item 7 now says: keep spin mode and its text while the pile reloads; exit spin mode if no pile waits. The next goal-agent run must rebuild C7 (the ledger marks it built at `90b18b9`, so check it gets redone).

**Still open (not blocking):** Bob's flower-patch shots ([[flower-patch-followup]]); `style_critic_check.py` with Vera's scores; content re-approvals ([[pending-approvals]]); deferred style items (V8 honey as hero, "x30" pile label).

**Handy commands:**
- QA checkpoint: `CB_TIME_SCALE=6 CB_SKIP_X1=1 python -I _tools/godot_run.py all`, then `mutate.py --since <last checkpoint>` ([[test-speed-fixes]]).
- Goal agent: `python -I _tools/goal_agent.py <spec> --plan`; the loop runs long, so start it with `run_in_background`.

**How to apply:** keep CLI replies short and put long material in Markdown files ([[dev-mode-and-pacing]], [[cost-rules]], [[model-routing]]). At the end of each session, rewrite this file to the new current state.
