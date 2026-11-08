---
name: session-handoff
description: "Where work stands (2026-11-08, late): rules systemized (guard_shell, spec_lint, pick_match); next = goal agent on item 14 fixes (raised-frame combs, lid clipping); read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 29d5fe47-e6ee-4442-8475-6d6f066dfb69
  modified: 2026-11-08T08:56:57.295Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** terminal `claude` CLI in VS Code; status line logs plan usage ([[usage-calibration]]). Main folder on `milestone/0.1.4`, no worktrees ([[one-folder-rule]]). Last commit `d8f210a` (C15). **Everything below is uncommitted** (this session and the 11/7–11/8 ones); end-of-day has not run.

**Built this session (2026-11-08, ICM audit of the memories → rules as code):**
- `_tools/guard_shell.py`, a PreToolUse hook on Bash/PowerShell/Write/Edit/Artifact (`.claude/settings.json`): refuses inline interpreter code, `sed -i` / redirects onto existing files / Write over an existing file (except `_meta/memory/`), a `cd` prefix or absolute repo paths, writes outside the repo (plan files excepted), and a votes page published anywhere but Design Votes or opened. It also binds the headless agents of goal_agent/generate/style_loop: **watch the next goal run for agents refused on Write-over-existing** (they must use Edit).
- `_tools/spec_lint.py`: FAIL on a Quinn line naming several items, WARN on keyword ties (0.1.4 has `T.1`, `T.2`), REVIEW pairs where one item restricts a view another asserts. Runs in `.githooks/pre-commit` (`--staged`) and at goal_agent start (FAIL stops a build run). Use `--item N` after every play-test edit ([[spec-consistency]]).
- Look before done ([[look-before-done]]): `_tools/pick_match.py` renders a live prop beside the picked variant in one load (`game/tests/model_shots.gd --scenes`, `--hide=HiveLid`, settles before fitting, ignores hidden nodes) and has Vera judge only the match (~23k tokens; Vera's definition has a Pick match mode). goal_agent runs it on any change item naming a variant, plus one `style_loop.py --max-rounds 1` round on every Bob change; either FAIL goes to Bob alone. First real run on the live hive: FAIL (frames solid slabs without comb panel, packed with no gaps). Limitation: the hive's combs are drawn at run time, so the static render doesn't show them.
- Variants: one folder per vote round, `game/scenes/variants/<prop>-r<N>/` (Milo's definition, variants CONTEXT); `model_shots.py` refuses a name without `-r<N>` (`--unnumbered` for old folders). Round 8's hive scenes were lost this way (overwritten by round 9 before a commit; only its renders remain).
- Tests: test_goal_agent 23/23, test_generate 59/59, consistency, links, contract_check all pass.

**Play-test of the C14 build (2026-11-08), now in `game/specs/0.1.4-ui-placement.md` item 14:** combs way too small **when a frame is raised**; the lid **clips through the hive at an angle** when closing. Comb size is already decided, no new vote: round 9 variant a (`game/scenes/variants/hive-frames/hive-frames-a.tscn`, 5 × 2, cell radius 0.14, cells filling the frame with gaps; render `game/reports/variants/hive-frames-r9/hive-frames-r9-a.png`). Contract lines added: Patricia and Bob "Item 14 fix", Quinn `T14.2` (raised-frame cells ≥ 90% of frame, cell/frame ratio within 15% of the pick) and `T14.3` (lid intersects no wall at every 10% of its close; rests flat), both written to fail on the current build first.

**Next session, first:**
1. Start `python -I _tools/goal_agent.py 0.1.4-ui-placement.md` with `run_in_background`. `--plan` ranks T14.1, T14.2, T14.3 first. C14 is in the ledger as built, so it goes test-first: Quinn's failing tests send fix rounds to Bob and Patricia. **The pick match does not run on test steps**, so afterwards run `python -I _tools/pick_match.py game/scenes/props/hive.tscn game/scenes/variants/hive-frames/hive-frames-a.tscn --no-agent`, look at both shots, and check a raised frame in game against the r9-a render before reporting done.
2. The designer plays meanwhile: `! & "C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64.exe" --path game` (allowed). Don't run Godot shot scripts while they play (they stopped a `ui_shots.py` run mid-play-test this session).
3. Then `build.py 0.1.4 --smoke`, the designer uploads to itch, submits A5 (due 11/15, [[course-milestones]], [[itch-upload-rule]]). `GOAL_AGENT.md` rows from C6 on are drafted in `_meta/drafts/0.1.4/GOAL_AGENT-c6-onward.md`.

**State at end of 2026-11-08 (supersedes "Next session" below):** goal run done, 38/38 (`720d42d` T14.1–3, `d2d3b57` T15.1); lid fixed (designer confirmed). Smoke build: exe and web zip built, web smoke shot black (loading spinner) → designer browser-checks before the A5 upload. Designer play-test after T14: combs clip through the frame, are misaligned, and meet point to point instead of side to side. Spec item 14 now has the "item 14 align" Patricia/Bob/Quinn lines (90% cover rule dropped by the designer; cells inside the frame, centred, sides touching). **Blocker:** `goal_agent --plan` counts the new Quinn line (T14.4) done because evidence matches every test under item 14, and `--goal` refuses done goals. Next: fix that matching in goal_agent (or dispatch Quinn → Bob/Patricia directly), build item 14 align, then `pick_match` + `ui_shots` and compare the raised frame with r9-a.
**Approved, not built (in order):**
- Approved 2026-11-08, build right after the current goal run: fix briefs say "don't run the suite, the goal agent runs the checks after you" + a turn cap on fix rounds (`--max-turns 15`) (Patricia's T14 fix 1: 777k tokens, 36 turns, 25 min); then `live.json` + `_tools/watch.py` (future-tbd 5b/5c).
- Failure-mode fixes left from 2026-11-08: Quinn's interaction checklist (start, leave mid-way, come back, twice); goal_agent re-reads the spec each pass; goal_agent mutation check (`mutate.py --since` exits 1 "no mutations to run" when a batch's mutations were committed earlier: check the mutations whose `expect` names the goal's tests) plus a test; web smoke real-time wait or the designer's browser check as the official step; Design Votes before/after shot after each visible step.
- From the memory audit: `_tools/checkpoint.py` (godot_run all with `CB_TIME_SCALE=6 CB_SKIP_X1=1`, then mutate since the last checkpoint commit); a `consistency.py` check that every `default_config.tres` key is in `dev_panel.gd`; budget_guard warns on stale `readings.jsonl`; `build.py` prints itch upload yes/no; shrink duplicated memories to pointers, move `pending-approvals` to a generated `content/_index.md`, archive `flower-patch-followup` and `playtest-0-1-3`, move `future-tbd` into the README TBDs, and a `memory_index.py` to rebuild MEMORY.md (its lines are stale).
- Visibility (future-tbd 5b/5c): live.json for the scripts' own steps, `_tools/watch.py`, the live side pane. Then parallel test runs ([[test-speed-fixes]]).

**Still open (not blocking):** Bob's flower-patch shots ([[flower-patch-followup]]); content re-approvals ([[pending-approvals]]); guide playtest briefs drafted in `_meta/drafts/onboarding/` ([[guide-playtest]]); `ONBOARDING.md` left untracked on purpose; Design Votes v13 at https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa.

**Handy commands:**
- QA checkpoint: `CB_TIME_SCALE=6 CB_SKIP_X1=1 python -I _tools/godot_run.py all`, then `mutate.py --since <last checkpoint>`.
- Goal agent: `python -I _tools/goal_agent.py <spec> --plan`; the loop runs long, so `run_in_background`.
- Spec lint: `python -I _tools/spec_lint.py game/specs/<spec>.md --item N`.

**How to apply:** keep CLI replies short and long material in files ([[cost-rules]], [[model-routing]]). At the end of each session, rewrite this file to the new current state.
