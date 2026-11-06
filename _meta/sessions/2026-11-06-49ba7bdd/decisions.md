---
session: 49ba7bdd-dbda-4adf-93f8-abf4c4364924
dates: 2026-11-06 to 2026-11-06
transcript: session.jsonl (this folder, gitignored)
description: 0.1.3 play-test, merge of 0.1.3 + m2 + flower patch into milestone/0.1 and main, UI comparison by script (Round 7), one-folder rule, specs for 0.1.4 and M3 (A5)
---
# Decisions: session 49ba7bdd (2026-11-06 to 2026-11-06)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D107 · 2026-11-06 · Pipeline design · 0.1.3 merged despite its UI bugs; the fixes go to the next revision
- Decided: The designer played 0.1.3 and found the UI broken (Back inconsistent, Spin and Harvest moving between views, the x5 tag overlapping the top-left text). They chose "fix in next rev": `milestone/0.1.3`, `milestone/m2` and `m2/flower-patch` were merged into `milestone/0.1`, and the flower-patch follow-up was applied (patches at y 0, `t_flower_patch_b` registered, its mutation retargeted). Checkpoint at x6: unit 133/133, play 236, measure 17, snapshot 12, ui 13, touch 4; the one new mutation was caught. `main` was fast-forwarded to `milestone/0.1`.
- Why: The bugs are layout, not logic, and the merged branch unblocks everything else (A5, the next revision).
- Files: `_meta/memory/playtest-0-1-3.md`, `game/tests/test_layout.gd`, `game/tests/mutations.json`, `game/scenes/main.tscn`

### D108 · 2026-11-06 · Cost & structure · The same screenshot moments are taken by a script; an agent only for a new screen
- Decided: Comparing versions uses `_tools/ui_shots.py LABEL=WORKTREE ...`, which runs the `MOMENTS` list of `game/tests/ui_compare_shots.gd` (9 moments, from the farm at start to Dev speed x5) in each version and tiles a contact sheet. Bob is called only when a new screen, phase or menu enters the game, to add its entry. `compare_page.py add --versions` builds the vote section from the sheets.
- Why: Designer: "the capturing shots routine should be done by a script since they're all the same moments and only need to call another agent when a new screen/phase/menu is added".
- Files: `_tools/ui_shots.py`, `_tools/compare_page.py`, `game/tests/ui_compare_shots.gd`, `_meta/memory/scripted-shots.md`

### D109 · 2026-11-06 · Pipeline design · Round 7: 0.1.3's layout kept, with the designer's UI direction
- Decided: On Design Votes, 0.1.3 got yes and the archived mocks ab-A and ab-B got no (ab-A's Sell placement is the good one). Direction: bigger hive frames and combs; the honey meter becomes the Harvest button's fill with "7/10" above it; bees and money stay at the top; Harvest lower (above the hive lid); Spin above the centrifuge lid; Sell lower, as in ab-A.
- Why: The designer compared the same moments across versions to see which version placed things right.
- Files: `game/reports/ui-compare/decisions.json`, `game/specs/0.1.4-ui-placement.md`

### D110 · 2026-11-06 · Workspace & agents · One folder: worktrees only for parallel work, removed when merged
- Decided: Every worktree was removed and the main folder now sits on `milestone/0.1`; the branches stay. New rule, `game/CONTEXT.md` Process 10: before dispatching agents, the orchestrator decides where they work. The default is the main folder on the milestone branch; a worktree only when two sessions or agents must change the same files at once (or a long run must keep going while other work changes its files), removed the day its branch merges. The archived A/B mock is kept on branch `ab/centrifuge-by-crate` (2a5d5bc).
- Why: Designer: "it's difficult to navigate the workspace with this worktree stuff". The playable exe lived in a worktree and the main folder was on an old branch.
- Files: `game/CONTEXT.md`, `_meta/memory/one-folder-rule.md`

### D111 · 2026-11-06 · Pipeline design · 0.1.4 spec approved: UI placement and the pile loading on its own
- Decided: `game/specs/0.1.4-ui-placement.md` was approved with 7 changes: the Harvest button as the honey meter, buttons anchored to their props in every view, Back fixed top-right, the speed tag under the money and bees lines, bigger frames, tests no longer writing into `user://recordings`, and the pile loading into the centrifuge after a pour with no Spin re-tap (found in the designer's play-test of the merged build). Harvest is hidden at the second stop; the count reads "7/10" without "Hive".
- Why: The play-test notes and Round 7 votes, made measurable for Quinn.
- Files: `game/specs/0.1.4-ui-placement.md`

### D112 · 2026-11-06 · Records & deliverables · An assignment's demo build goes on itch; 0.1.4 is the A5 demo
- Decided: Exception to the itch rule (only new milestone numbers): a build that is an assignment's demo is also uploaded. 0.1.4 is built by the M3 agent as the A5 demo and goes on itch; the designer checks the web page loads, since the web smoke test is unconfirmed.
- Why: Designer: "0.1.4 can be the next demo so that means also on Itch".
- Files: `MILESTONES.md`, `_meta/memory/itch-upload-rule.md`

### D113 · 2026-11-06 · Pipeline design · M3 (A5) spec approved: the reasoning layer in code, no planner model
- Decided: `game/specs/m3-goal-agent.md` follows the course's A5 wording. One script, `_tools/goal_agent.py`, holds `scan()`, `gaps()`, `priority_score()` (a weighted sum of what a goal unblocks, its value, its cost from `agent-runs.csv`, and whether its dependencies are ready), and the loop that re-scans after each write and stops when all goals are met, the budget guard blocks, or after 2 failed fix rounds. The code-writing step calls Patricia, Bob and Quinn. Checkpoint commits on the milestone branch are allowed ("why not?"). README: `GOAL_AGENT.md` (what was built, why, manual changes).
- Why: The course grades "the reasoning layer" and asks for a `priority_score()` function; as code it is readable, testable, deterministic and free, and the blackboard's factors answer "why this feature". Ambiguous goals stop for the designer.
- Rejected: A planner agent (Sonnet or Haiku). If a model is ever needed to break ties or word a reason, Sonnet, like the other judgement agents.
- Files: `game/specs/m3-goal-agent.md`

## Still open

- **Build M3 in a fresh session after the weekly reset (Sat 11/7 9:00 Toronto):** `_tools/goal_agent.py` scan/gaps/priority_score with tests, then `--plan` on 0.1.4 for the designer, `--dry-run`, then the real run building 0.1.4 on `milestone/0.1.4` in the main folder; upload 0.1.4 to itch; write `GOAL_AGENT.md`. A5 due 11/15, 11:59 ET.
- `build.py`'s web smoke test: the 100 s wait still shows the loading spinner; it matters now, since 0.1.4 goes on itch.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 × 18, so the zoom shows no sky around the diorama; about 14 × 14 would bring the floating look back.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
- Budget guard: reworked on 2026-11-05 (D95); confirm the 80% complaint is resolved.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged. Session 29b33c17 was re-exported today for the same reason.
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" → "six" word change in `STYLE_GUIDE.md`.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- `content/onboarding-script.md`: narrative and onboarding come later; it needs the guide signature-lines revision and the new harvest flow.
- Guide character playtest: Melli, Pip, Lady Aura or Miel (D46).
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- Content follow-ups: a Sunny Meadow flower for the bumble bee visitor (then Journal Entry 3); name Glowbell and Skybloom in `content/biome-intros.md`; the "sweat name" wording.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Push: `main` is ahead of GitHub; push only when the designer says so (D45).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
- Learnings file (D92): one record of everything that broke, how it was noticed and how it was fixed; decide where it lives and whether it is kept by hand or built from the decision logs.
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `m2/flower-patch`, `ab/centrifuge-by-crate`): delete them, or keep them as history?
