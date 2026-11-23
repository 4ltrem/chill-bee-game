---
name: session-handoff
description: "Where work stands (2026-11-23): 0.3.1 spec ready to build (7 items, fact-checked, all content approved), waits for the designer's \"build\"; v0.3.0 tagged locally; 66 commits not pushed; A7 + final due 11/29; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: 5c77a6f2-f6b5-4ff0-a169-8eabbf24bafe
  modified: 2026-11-23T17:48:41.655Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**State (2026-11-23, `main` at `5d79b8e`):** `v0.3.0` tagged at `830416b`, local only. 66 commits ahead of `origin/main`. Designer: no push or itch upload until 0.3.1 is built and play-tested (each still a yes). Uncommitted on purpose: `_meta/agent-runs.*` (end-of-day). Today's decisions are not logged yet: run the `end-of-day` skill (this session `5c77a6f2`), next ID **D284**.

**NEXT:**
1. **Build 0.3.1** when the designer says "build": set `game/specs/0.3.1-playtest-fixes.md` to `status: approved`, then `/goal` around `python -I _tools/goal_agent.py 0.3.1-playtest-fixes.md`. The budget guard will likely hold Patricia/Bob/Quinn (week ~50% at ~30% gone on 11/23): the designer runs `python -I _tools/budget_guard.py --allow-for 60` or waits for the 11/28 reset. If the spec changes, re-run `python -I _tools/spec_factcheck.py game/specs/0.3.1-playtest-fixes.md` first (goal_agent refuses a build until `game/reports/goal/0.3.1/factcheck.md` matches; now 36/36 TRUE or NEW). Seven items:
   1. no Habitat +; Journal icon of its own above Shop; pill hidden in zooms
   2. toast queue waiting for the Shop / Journal / Settings / zooms; the patch toast wired
   3. Shop sheet with tabs by GDD tree ("À venir" on Research / Refinery)
   4. first-time hint (text approved: `content/first-time-hint.md`)
   5. 0.3's six Dev buttons, never built ("Show welcome", "Show victory", "+1 patch (free)", "Health to thriving − 1 patch", "Reset habitat", "Unlock Journal")
   6. drawn fork on Harvest (UI_DESIGN rule 4, canvas Prototype fork; colours now UI tokens) and the honey-drop Spin icon (Design Votes pick D, `game/reports/votes/spin-icon/decisions.json`, shape in `icons.html` option d)
   7. Settings gear (farm view only, top-right) with English | Français, every label through `tr()` from the approved `content/ui-labels.md` (French prices "%d $", "Paramètres")
2. **Play-test 0.3.1** (placeholders to confirm): welcome title 64 / outline 8 / Play 40 / gap 48 / dim 0.55; victory heading 64, body 36, button 320×120, column 640; pill flower dot 40; 120 px icons; Shop labels 28; skip icon position; hint bubble and Settings sheet sizes; minutes to victory (Terry: 25, range 20-38). Then tag, push, itch (each a yes).
3. **A7 (due 11/29):** the designer records the run video. Before submitting: `python -I _tools/audit_data.py`, refresh §4.1 / §7.2 of `_meta/drafts/a7/audit.md` if the 0.3.1 run adds data, set its frontmatter status to final, then `python -I _tools/md_to_pdf.py _meta/drafts/a7/audit.md --min-pages 20` (29 pages last time).
4. **Final 11/29 leftovers:** UI pass (ui-screens decisions 2-4 + skin), adversarial QA, balance sim, polish.

**Built 2026-11-23 (tooling):** `spec_factcheck.py` (L52 check 1, Doris); goal_agent assumption stops (reads first-round replies too) and a scan check for quoted Dev buttons (0.3 now shows CFG and C4 partial: true); `godot_run.py` refuses `--set` with any suite but unit; `session_digest.py` (designer messages + quiz answers of an exported session). `t_icons_never_overlap` strengthened (second stop + 0.3 HUD; mutation caught). Decision logs D270-D283 written for the five unlogged 11/21-11/22 sessions. test_goal_agent 83/83, test_generate 95/95, links 0 broken, style_check PASS.

**Still open:** L52 check 3 (event shots 1 s after each event, `ui_shots.py` + Quinn's `ui_compare_shots.gd`; `_meta/drafts/0.3/l52-deferred-checks.md`); mutation 25 (second crank dead) still missed (Quinn); [[pending-approvals]] (onboarding-script; biome-intros re-approval); `proposals/design/roadmap.md` Q3 watering, Q5 Connie timing; the side pane (`claude --plugin-dir _tools/live-pane`) untested in a real session; operator Phase 5 proper (one real job through `claude --agent operator`); first `/dream` pass. UI canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca; Design Votes https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa (version 27).

**Rules:** all Godot scripts go to Rex ([[rex-runs-scripts]]); the hook also matches script file names inside `git add` (stage by glob); don't kill the designer's running game; questions in AskUserQuestion ([[ask-with-quiz-tool]]); [[one-folder-rule]] (main only), [[spec-consistency]], [[test-speed-fixes]], [[fix-needs-commit]], [[look-before-done]], [[edit-lines-only]], [[french-house-style]].

**How to apply:** keep CLI replies short ([[cost-rules]]). At the end of each session, rewrite this file to the new current state.
