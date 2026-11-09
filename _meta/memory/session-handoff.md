---
name: session-handoff
description: "Where work stands (2026-11-09 evening): UI design session done (UI_DESIGN.md, canvas, proposal, L25-L30, all uncommitted on milestone/0.1.4); next = commit on milestone/0.2 from main, Terry, 0.2 spec, /goal + goal_agent; A6 fixes in parallel; read first"
metadata:
  node_type: memory
  type: project
  originSessionId: f6f4c6c0-43ee-4483-9665-cc6335d16443
  modified: 2026-11-09T19:46:01.699Z
---

Current state only; history lives in `_meta/sessions/*/decisions.md` and git. Replace, don't append.

**Setup:** main folder on `milestone/0.2`, branched from `origin/main` `6e22681` (local `main` is stale at `ad1cae9`; fast-forward it before the next merge). The 2026-11-09 work is committed there as `dbd1c3b`. End-of-day for 2026-11-09 has NOT run. No worktrees. Terry's `first-automation-values` is applied to the GDD (`3436b67`; designer: truck-only scope, Gearing doesn't speed bottling, spigot upgrades later, Heated +4%, Auto-Sell before scraper). `game/specs/0.2-first-automation.md` is written, **status proposed**, with 4 open questions at the bottom; questions answered. 0.2 runs in **two separate sessions** (designer, 2026-11-09): (1) models session: Milo makes 3–5 variants each of `fork-r1` (uncapping fork, heated blade pulses orange) and `gearing-r1` (extra gear at the crank-lid joint), Design Votes section per model, designer votes; (2) implementation session: write the picks into spec items 3–4, designer approves, `/goal` + `goal_agent.py` builds. Spec stays `proposed` until after the vote.

**UI design (2026-11-09, this session):** read `UI_DESIGN.md` first ([[ui-design-prefs]]). Canvas https://claude.ai/artifact/ErtHvkxYUpDQHRM8RLRLca, 7 pages; proposal `proposals/design/ui-screens.md` (status proposed, Gerard's run was stopped, so the orchestrator wrote it). Decided by the designer: icons over the spin-c shots, no nav bar; Harvest = white fork icon with honey meter behind; icons bee/wrench/gear/green leaf; Royal Jelly = variant K (60°, crown drop 1.8, lift −2.6). Open: bottom slot A–D by play-test; palette/biome skins; K big-preview slider fix unconfirmed (L28); the proposal's 7 decisions. The UI work is not yet in any spec or the game. Unclear: whether UI A/B choices should move to the Design Votes page ([[ab-comparison-page]]); the designer has been choosing on this canvas instead. Ask before the next UI round.

**Done 2026-11-09:** 0.1.4 web build uploaded to itch (designer). `GOAL_AGENT.md` is `status: final`: itch link added, run status line updated (finished in the `/goal` session, 178/178, merged), and the `/goal` + `goal_agent.py` combination marked adopted for 0.2. Links check 0 broken. Designer still to submit the A5 link (due 11/15): itch link + `GOAL_AGENT.md` as the README.

**Order agreed with the designer (2026-11-09):** A5 wrap-up first (done but the submission), then 0.2 (A7 playable link, ~11/19, the longest pipeline), with the A6 fixes done while the goal agent builds.

**Next, 0.2 "First automation" (MILESTONES M4):**
1. `git switch -c milestone/0.2 main`.
2. **Terry runs before the loop, not inside it** (designer asked; reasons: his numbers need the designer's decision, a human step would stall `/goal`'s condition, and `parse_spec()` reads specs, not proposals). He sets what the GDD leaves TBD: Heated Fork's flat bonus after automation, Centrifuge Gearing's flat value after automation, and the costs of the motor, auto-scraper, Faster Delivery and Auto-Sell. Flight Endurance (+10%/lvl, $15, 1.15×) and Centrifuge Gearing (−15%/lvl, $35, 1.20×, max 5) are already in GDD Tree A/B.
3. The orchestrator writes `game/specs/0.2-first-automation.md` with the accepted numbers as config defaults, for approval. Scope from MILESTONES: Flight Endurance, Centrifuge Gearing, Heated Fork, one automation step (the self-driving truck: Auto-Sell / Faster Delivery, GDD Phase 2), the Bee Journal entry (EN/FR) in Godot's translation CSV on one screen (A3 grader's next step), and the M3 cap-stop summary in `_tools/generate.py` (planned for M3, still unbuilt).
4. Build with `/goal` as the outer loop and `goal_agent.py` inside it. The condition is: "`goal_agent.py SPEC --plan` reports nothing left to build and the latest unit run is green". Keep human steps (play-test, itch) out of the condition.

**A6 fixes (due 11/22; MILESTONES says 11/12, fix it):** the course brief bans binary pass/fail and designer intervention.
- Clara (`.claude/agents/content-critic.md`) only gives PASS/FAIL: give her per-check scores 0–10 with a reason, like Vera's Scores table (the brief covers narrative rules too).
- `style_loop.py` stops for the designer on "(designer)" rows: for the graded run, the loop picks the option the guide favours, logs why on the blackboard, and lists the choice for review after the loop ends.

**Rules:** all scripts go to Rex ([[rex-runs-scripts]]) with the fast env vars ([[test-speed-fixes]]); [[fix-needs-commit]]; [[look-before-done]]; [[edit-lines-only]]; a fresh session per milestone ([[cost-rules]]).

**How to apply:** keep CLI replies short. At the end of each session, rewrite this file to the new current state.
