---
session: cf44f0d9-ea3d-41b5-a628-12e39e761cca
dates: 2026-11-21 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: Opus session closing the handoff's jobs (branch model, report naming, learnings and operator items, spec item 15, Godot loss guard); this log also records the 2026-11-20/21 laptop sessions' decisions from the session handoff, which had no end-of-day of their own
---
# Decisions: session cf44f0d9 (2026-11-21 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

D234-D248 come from the 2026-11-20 and 2026-11-21 sessions (laptop: e8567c58, the Oscar sessions and the Opus sessions of 11/21), taken from `_meta/memory/session-handoff.md` as those sessions left it; their transcripts were exported today but not re-read.

## Decisions

### D234 · 2026-11-20 · Workspace & agents · The desktop's 0.2 work and the laptop's main are combined in one merge
- Decided: `origin/milestone/0.2` merged into `main` with all 7 conflicts resolved by combining both machines ("combine them so we have the most accurate and complete one"); committed `1f07c88` with the designer's yes. The laptop's 11/17 learnings L25/L26 became L36/L37.
- Files: `_meta/learnings.md`, `_meta/memory/session-handoff.md`

### D235 · 2026-11-20 · Critic quality · Clara scores each of her checks 0-10 (A6 gap 1)
- Decided: Clara scores each of her 7 checks 0-10 with a reason; a score under 6 is a blocking row. Closes the A6 brief's "no binary pass/fail" gap for the voice loop; the scored re-run of Biome intros went FAIL to PASS (196k tokens).
- Files: `.claude/agents/content-critic.md`, `STYLE_LOOP.md`, `content/_runs/biome-intros/run-3/blackboard.md`

### D236 · 2026-11-20 · Pipeline design · The style loop decides option-A rows itself (A6 gap 2)
- Decided: a `(designer)` row that lists an option A (the one that fits the current guide) goes to Bob as A without stopping, listed under "Loop's choices" and added to Design Votes afterwards so the designer can reverse it; only a row with no in-guide option stops.
- Why: the assets are generated, so the loop decides; it answers the A6 brief's "no intervention".
- Files: `_tools/style_loop.py`, `.claude/agents/style-critic.md`

### D237 · 2026-11-20 · Critic quality · A4 item (a) built: a source-quote cache; the content-run gate is lifted
- Decided: `_tools/source_cache.py` caches source facts for Clara, placeholder cells and check 5 move to `voice_check.py`, and `critic_check.py` counts script rows. With both A4 grader items built, the 2026-11-17 gate on content runs is lifted.
- Files: `_tools/source_cache.py`, `_tools/voice_check.py`, `_tools/critic_check.py`, `MILESTONES.md`

### D238 · 2026-11-20 · Pipeline design · The style loop works on a sandbox, guarded and gated; Bob's live edits reverted
- Decided: after Bob changed truck motion and size, the crate jars and the Spin icon, all his edits were restored to HEAD ("Bob is breaking more than he's fixing"). The loop now edits a sandbox copy and ends with `sandbox.patch`; after each Bob turn a guard puts back motion, picked-prop size and place and UI, and the unit suite runs against a baseline (a failing turn is undone). UI rows go to Patricia.
- Files: `_tools/style_loop.py`, `_meta/learnings.md` (L43)

### D239 · 2026-11-21 · Records & deliverables · A6 demo = the 0.2.0 farm run 5; link = STYLE_LOOP.md
- Decided: the designer keeps run 5 (`game/reports/style/0.2.0-farm/run-5/`, needs-review at max rounds, 2 of 3 rows fixed, jar row open by design) as the A6 demo; `STYLE_LOOP.md` stays `approved` and is the A6 link. Its `sandbox.patch` was applied without `jar.tscn` (designer: b), checkpoint `3e7e65f`.
- Files: `STYLE_LOOP.md`, `game/reports/style/0.2.0-farm/run-5/`

### D240 · 2026-11-21 · Game build · Item 9: fix the tests, not the code; the second stop now needs Spin
- Decided: `main.gd` already implemented item 9 (no full-bucket pan), so the designer said "fix the test": Quinn moved the tests' second-stop setup to Spin and rewrote `play_loop.gd`; the full suite went green. `t_icons_never_overlap` now only asserts 0 icons at the second stop (weaker; to confirm).
- Files: `game/tests/`, `game/specs/0.2-first-automation.md`

### D241 · 2026-11-21 · Game build · Shop layout: the sheet behind a Shop button (item 14)
- Decided: `shop_layout` config, 0 compact / 1 sheet; on Design Votes the designer voted B (sheet) yes, A and the 0.2.0 panel no: "good the functionality is added, the ui design will be implemented later". Rows 64 px, 24 pt for now; the look waits for 0.3.0.
- Files: `game/reports/votes/shop-layout/decisions.json`, `game/scripts/shop_ui.gd`

### D242 · 2026-11-21 · Game build · Shop + Tools in the zooms (item 15)
- Decided: the Shop button stays available in both zooms, including the second stop, so the player can upgrade at any time; the Tools icon (the machine's own upgrades) sits beside it from 0.3.0. Written as 0.2 spec item 15 (goals C15, T15.1) on 2026-11-21, superseding 0.1-harvest items 3/8 on the shop. Canvas redraw left for the 0.3.0 UI pass.
- Rejected: the UI proposal's Tools-only zooms.
- Files: `UI_DESIGN.md` (row 3), `proposals/design/ui-screens.md` (decision 4), `game/specs/0.2-first-automation.md`, `_meta/drafts/0.2/item-15-shop-in-zoom.md`

### D243 · 2026-11-21 · Game build · Item 10 = A: a held press at zoom end keeps the fork shown, then it flies to the Harvest icon
- Decided: option A; spec line 55 edited to match.
- Files: `game/specs/0.2-first-automation.md`, `game/scripts/honeycomb.gd`

### D244 · 2026-11-21 · Game build · T9.1: the paused crank is kept (A)
- Decided: when a zoom ends mid-crank, the crank keeps its progress (A) rather than resetting (B).
- Files: `game/tests/test_zoom_end.gd`

### D245 · 2026-11-21 · Workspace & agents · Operator rules: "keep going" overrides the twice-failed stop; Quinn may probe with an allow file
- Decided: an in-session "keep going" or `/goal` overrides the same-failure-twice stop, never a designer stop (A). Quinn may run `godot_run.py --only` probes while `_meta/usage/quinn-probes.allow` is fresh (A).
- Files: `.claude/agents/operator.md`, `operator/CONTEXT.md`, `operator/escalate.md`, `_tools/guard_shell.py`

### D246 · 2026-11-21 · Cost & structure · goal_agent tests only what a change reaches; one full suite at the run's end
- Decided: after "these test runs take a long time ... we don't need to test things we know work already": test-impact lists (L39), one flaky rerun, timeouts and routing (L40-L42); no full unit gate per step, `all` once at the run's end.
- Files: `_tools/goal_agent.py`, `_meta/learnings.md` (L39-L42)

### D247 · 2026-11-21 · Workspace & agents · Live view and the QoL set
- Decided: the designer picked operator queue #5, #8+#9, #7 and #6: `live.py`, `watch.py`, the side pane, `status.py` + `/status`, `end_of_day.py prep|checks`, goal state committed once per run, Rex-only hook; committed in one tooling commit ("all can go in").
- Files: `_tools/live.py`, `_tools/watch.py`, `_tools/live-pane/`, `_tools/status.py`, `_tools/end_of_day.py`, `_tools/guard_shell.py`

### D248 · 2026-11-21 · Workspace & agents · Old branches cleaned up
- Decided: merged branches deleted; remote `milestone/0.1`, `0.1.3`, `0.1.4`, `m2`, `m2/flower-patch` deleted; `ab/centrifuge-by-crate` kept only as tag `archive/centrifuge-by-crate`; worktree `m02-play` removed (see D255 for what that removal also deleted).

### D249 · 2026-11-21 · Workspace & agents · One branch: work on main, tags mark shipped states
- Decided: branch review option A: no `milestone/<version>` branches; checkpoints and goal_agent commit on `main` (refused only on a detached HEAD); push only a green `main` with the designer's yes; a played milestone or an assignment's demo gets a tag (`v0.2.1`, `a6-demo`). `commit_main.py` retired. Commit `d3b3b5c`.
- Why: the split cost a big two-machine merge, a commit-to-main workaround and two commit gates; both branches were at `3e7e65f`, the cheapest moment to switch.
- Rejected: keep milestone branches (B); a branch only for goal runs (C).
- Files: `_tools/checkpoint.py`, `_tools/goal_agent.py`, `game/CONTEXT.md` (Process 4, 10), `.claude/skills/end-of-day/SKILL.md`, `_meta/memory/one-folder-rule.md`

### D250 · 2026-11-21 · Workspace & agents · Origin cleaned: milestone/0.2 deleted, main pushed
- Decided: with the designer's yes, `milestone/0.2` deleted on origin and `main` pushed at `d3b3b5c`.

### D251 · 2026-11-21 · Records & deliverables · Report naming: one layout for builds, goal, style, votes and variants
- Decided: the naming review's target (A), the same `run-N/round-N` shape for `content/_runs/` (A), and the history moved too (A). `game/reports/` now holds `builds/<version>/`, `goal/<version>/`, `style/<version>-<scene>/run-N/`, `votes/<vote-id>/<option>/`, `variants/<prop>/round-N|pick-match/` and `_runs/`. `round` = a design or critic round, `run` = a tool re-run; versions keep dots; dates `YYYY-MM-DD`; no `now`/`before` folders. Scripts `eb50160`, history `02e0e6d`.
- Files: `_meta/drafts/naming/reports-naming-review.md`, `_meta/drafts/naming/moves.tsv`, `game/CONTEXT.md`, `content/CONTEXT.md`

### D252 · 2026-11-21 · Workspace & agents · A rename script is a stated exception to the edit-lines rule
- Decided: option A: `_tools/rename_paths.py` swaps only old-path strings (227 in 121 files), keeping line endings, dry run first, instead of fixing the history's links by hand or leaving them stale. The move and the rewrite went in one commit, not two, because the commit gate's link check refuses a move-only commit and hooks are never skipped.
- Rejected: fix live docs only (B); don't move history (C).
- Files: `_tools/rename_paths.py`

### D253 · 2026-11-21 · Records & deliverables · The A6 demo evidence is committed
- Decided: the untracked style runs `0.2.0-farm/run-1..5` and the voice run `biome-intros/run-3`, which `STYLE_LOOP.md` links to, went into the history commit so the A6 link resolves once pushed.

### D254 · 2026-11-21 · Pipeline design · The goal scan takes each test's newest result
- Decided: `goal_agent.unit_results()` lays newer `--only` logs over the newest full unit log (obstacles item 23, L44); L43 written for the style loop's refiner regressions. Commit `aa5618e`.
- Files: `_tools/goal_agent.py`, `_meta/learnings.md`

### D255 · 2026-11-22 · Workspace & agents · Recursive deletes refuse folders that hold a junction
- Decided: the designer said "yes, build the guard": `guard_shell.py` rule 8 (link-delete) refuses `git worktree remove`, `rm -r`, `Remove-Item -Recurse` and `rmdir /s` on a folder holding a junction or symlink, naming the `cmd //c rmdir LINK` that removes the link alone. Commit `5ce4cc6`.
- What broke: D248's `git worktree remove --force .claude/worktrees/m02-play` followed that worktree's Godot junction and emptied the repo's Godot folder; the designer re-unpacked it.
- Files: `_tools/guard_shell.py`, `_tools/test_generate.py`, `_meta/learnings.md` (L45)

## Still open

- **A6 (due 11/22):** push `main` so `STYLE_LOOP.md`'s demo folders are on GitHub, then submit the link; offer the `a6-demo` tag.
- **0.2.1:** build item 15 (`goal_agent.py ... --goal C15,T15.1`), then the version build and itch upload as the A7 link (each needs a yes); was A7 submitted (due 11/18-19)? Tag `v0.2.1` once played.
- **`godot_run.py start --refresh`** printed PASS but exited 1 (`game/reports/_runs/20261122-000040/start.log`); check why.
- **`t_icons_never_overlap`** now only asserts 0 icons at the second stop (D240): confirm, or ask Quinn for a stronger check.
- **Operator items still open:** item 7's tail (only `ui_compare_shots.gd` reads `--set` overrides; `run_tests.gd` and the windowed suites don't); item 23's plan count (C14, CFG and T.1 not listed).
- **The side pane** (`claude --plugin-dir _tools/live-pane`) has not been loaded in a real session.
- **Roadmap** (`proposals/design/roadmap.md`): questions 3 (watering) and 5 (Connie timing) open; re-layer to build-from-start r2.
- **0.3.0 UI pass:** ui-screens decisions 2-4 and the skin; canvas boards 2-3 redrawn for Shop + Tools.
- **First `/dream` pass** (D231): the six preferences (A1), the memory cleanup (A2), the `rex-runs-scripts` wording.
- **Operator, Phase 5 proper:** one real multi-step job through `claude --agent operator`, compared with an Opus session (D233).
- **A7 deliverable 3** (pipeline audit and cost analysis): the M4 rows can now be written from the 0.2 history (`_meta/drafts/0.2/`).
- **Mutation 25** (second crank dead) still missed: a test for Quinn.
- **Transcripts of 11/20-11/21** were exported but not re-read for this log; D234-D248 come from the handoff.
- **Fast tests as the default (L17):** whether plain speed becomes opt-in is not decided.
- **GitHub repo visibility for A5:** if `4ltrem/chill-bee-game` is private, the grader needs access.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- **spec_lint warnings** in `0.1.4-ui-placement.md`: T.1/T.2/T.3 ties; reword or confirm.
- **Guide playtest briefs** (D143): briefs for Patricia (a guide switch) and Gerard; playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- `content/biome-intros.md` (re-run 3 passed) and `content/onboarding-script.md` need the designer's approval; onboarding needs the new harvest flow (D154) and the six guides' lines.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: add D192's three read-anywhere lines to `.claude/settings.local.json`.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
