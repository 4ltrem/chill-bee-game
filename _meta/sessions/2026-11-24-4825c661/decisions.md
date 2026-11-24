---
session: 4825c661
dates: 2026-11-23 to 2026-11-24
transcript: session.jsonl (this folder, gitignored)
description: the 11/23-11/24 working day across sessions 5c77a6f2, b594236a, 385322cc, ecf90fb3 (maigd-a6), b7520e00, 41987031, d6d154f6, a4d73468, 5f3faf93 and this one (0.3.1 spec, build, play-test and close; Oscar retired; 0.3.2 spec and build); logged from `_tools/session_digest.py`
---
# Decisions: session 4825c661 (2026-11-23 to 2026-11-24)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

This log covers every session exported on 11/24 that had no log of its own; the session that made each decision is named in its bullets.

## Decisions

### D284 · 2026-11-23 · Records & deliverables · Finish L52 checks 1-2 and the open list; hold the v0.3.0 push and itch
- Decided: session 5c77a6f2 finishes L52 checks 1 and 2 and cleans the open list; v0.3.0 stays a local tag, with no push and no itch upload, until 0.3.1 is built and play-tested.
- Why: the designer asked to finish what could be finished without heavy agents.

### D285 · 2026-11-23 · Pipeline design · 0.3.1 content: hint text, Dev buttons and a stronger icon test
- Decided: run the 0.3.1 fact-check now; William and Clara write the first-time hint (`content/first-time-hint.md`), approved as written; the six 0.3 Dev buttons that were never built go into 0.3.1 with a scan check; Quinn writes a stronger `t_icons_never_overlap`; the five unlogged 11/22 sessions get a decision log.
- Why: the 0.3 scan checked config keys, nodes and tests but not Dev buttons, so it showed 14/14 with six buttons missing.
- Files: `game/specs/0.3.1-playtest-fixes.md`, `content/first-time-hint.md`

### D286 · 2026-11-23 · Bee Journal rules · UI labels in French, money as "Vendre 30 $"
- Decided: the canvas fork's greys and wood brown join the UI colour tokens; William and Clara write `content/ui-labels.md` (about 25 labels), approved as written; the language switch lives in the Settings gear on the farm view only, not on the welcome screen; French prices read "30 $" (Canadian order); empty tabs read "À venir"; Settings is "Paramètres".
- Why: the language switch needs every hard-coded English label translated first.
- Files: `content/ui-labels.md`, `STYLE_GUIDE.md`

### D287 · 2026-11-23 · Pipeline design · Back arrow and a Tools icon in the zooms; shape alone tells icons apart
- Decided: 0.3.1 adds the Back arrow and a Tools icon in the zooms (item 8, "Tools" / "Outils"); the Shop shows on the farm view only, so buying Bees, Habitat or truck upgrades means going Back, as the canvas boards draw it; icons with no word are enough for colour-blind players because their shapes differ.
- Why: the designer worried the Shop and Tools icons sat side by side; the UI canvas puts Tools alone in the zooms.
- Files: `UI_DESIGN.md`, `proposals/design/ui-screens.md`

### D288 · 2026-11-23 · Pipeline design · Approve a spec, then re-run its fact-check
- Decided: the 0.3.1 build starts; approving a spec changes its text, so the fact-check is re-run after `status: approved`.
- Why: goal_agent refused the first build because the fact-check no longer matched the approved spec.

### D289 · 2026-11-23 · Cost & structure · Faster goal runs: parse check, own tests first, code map, recipes, shared panel base
- Decided: session ecf90fb3 (maigd-a6) adds a parse check before the tests, runs each goal's own tests first and adds a duplicate node-name check, after the running build; builds a code map and `game/RECIPES.md` for the briefs; the shared panel base (one "any panel open?" check) is built as part of 0.3.1 C7; the victory also waits while the Journal or Settings panel is open. The stale run lock was deleted with the designer's yes.
- Why: the designer found the goal runs too slow and asked for reusable helpers and patterns.
- Files: `_tools/goal_agent.py`, `_tools/contract_check.py`, `game/RECIPES.md`

### D290 · 2026-11-23 · Game build · Spin behaves like the fork, and the lid opens for the pile
- Decided: the Spin icon is drawn at the fork's size (88 drawn, 120 button) in every view; the centrifuge lid opens fully before the pile's combs fly in, then closes.
- Why: play-test: the Spin icon looked smaller and jittered, and combs flew into a closed bucket.
- Files: `game/scripts/floating_icon.gd`, `game/scripts/centrifuge.gd`, `game/scripts/main.gd`

### D291 · 2026-11-23 · Pipeline design · Icon overlap is judged on drawn circles; Spin 30 px lower
- Decided: icon overlap is judged on the drawn circles, not the touch rects; UI vote shots use `ui_bounds=true`; Design Votes spin-farm: no sideways shift; spin-farm-height A: `spin_farm_offset_y` 30 (version 29 of the page).
- Why: the designer: "when comparing overlap compare visual not touch area"; Spin may cover part of the hive lid.
- Files: `game/reports/votes/spin-farm/`, `game/reports/votes/spin-farm-height/`

### D292 · 2026-11-23 · Records & deliverables · Design choices applied to the GDD, style guide and UI design
- Decided: session b7520e00 analysed the designer's choices and updated `GDD.md` §9, `STYLE_GUIDE.md`, `UI_DESIGN.md` rule 6 (Spin drop, Back arrow, no words on action icons) and set both course-ending proposals to `applied`; the open UI questions stay open.
- Why: the designer asked for the documents to follow the decisions made in play-tests.
- Files: `GDD.md`, `STYLE_GUIDE.md`, `UI_DESIGN.md`, `proposals/design/course-ending.md`

### D293 · 2026-11-23 · Workspace & agents · The planner skill, for tooling only
- Decided: the third-party planner skill becomes `.claude/skills/planner/`, for tooling work only (`_tools/`, skills, agents, loops); game features stay specs built by goal_agent; its plans follow the repo rules (Rex runs Godot, the main session commits).
- Why: game specs already go spec, fact-check, goal_agent.
- Files: `.claude/skills/planner/SKILL.md`, `AGENTS.md`

### D294 · 2026-11-23 · Workspace & agents · Oscar retired; the Opus main session keeps its own flow
- Decided: the Opus main session runs with flow rules (one job per session via /next, wait on notices, Rex for scripts, 150-word replies, handoff first, decisions in the quiz tool) and a context guard that warns at 50% and 75% of a 1M window; Oscar (the operator agent) is retired.
- Why: every 11/21 operator session stopped at its first real task and the designer kept switching to Opus (L55).
- Files: `AGENTS.md`, `_tools/context_guard.py`, `.claude/skills/next/SKILL.md`, `_meta/learnings.md`

### D295 · 2026-11-23 · Cost & structure · After a hand fix, run only the affected tests
- Decided: the full run in progress was stopped and the one-test result used; T8.1 written at once.
- Why: the designer: "not the first time you don't follow the rule" ([[test-speed-fixes]]).

### D296 · 2026-11-23 · Records & deliverables · Cost forecast in MILESTONES.md; roadmap Q3 later, Q5 during the slice
- Decided: the cost forecast to 1.0 and post-launch goes in a "Cost forecast (2026-11-23)" section of `MILESTONES.md`; root `*.mp4` files are gitignored; roadmap Q3 (starting upgrades bought with Royal Crystals) is decided later; Q5: Connie reviews the money and kids rows during the vertical slice, and Royal Jelly earned through play also waits for her.
- Why: MILESTONES.md is the approved plan; the roadmap is still a proposal.
- Files: `MILESTONES.md`, `.gitignore`, `proposals/design/roadmap.md`

### D297 · 2026-11-23 · Game build · The hanging hint walk test set aside; three hint tests fixed before the play-test
- Decided: `t_hint_steps_follow_state_in_order_twice` is set aside for 0.3.2; the three failing hint tests are fixed before the play-test; the play-test fixes (Settings panel script, tabs fit their words, Coming soon in ink, fork fill at full and smooth circles, lid lifts for the pile, gear under sheets, Spin in the zoom resumes a paused crank) all become 0.3.2 tests.
- Why: three diagnostic runs found no cause, and every other unit test passed.

### D298 · 2026-11-23 · Records & deliverables · 0.3.1 closed by note, tagged and pushed
- Decided: 0.3.1 closes by the designer's note (checkpoint 528/528 green), its six untested items' test lines move to 0.3.2, and `v0.3.1` is tagged and pushed with main; no itch upload.
- Why: `--accept` can't close goals that have no tests; 0.3.1 is not a new milestone number ([[itch-upload-rule]]).
- Files: `game/reports/goal/0.3.1/blackboard.md`, `_meta/drafts/0.3.2/tests-from-0.3.1-playtest.md`

### D299 · 2026-11-23 · Pipeline design · 0.3.2 scope: tests, quick-buy A, adversarial QA, previews after a Milo vote
- Decided: the 0.3.2 spec holds the hint-walk hang, the play-test tests, the six carried 0.3.1 lines, mutation 25, an adversarial QA pass, bottom slot A only (quick-buy with a Dev switch) and upgrade previews after a Milo vote of two variants per upgrade; balance sim and slots B-D are out. Approved, with fact-check rows 2 and 4 set TRUE by the designer.
- Why: the week is at 78% and the final is due 11/29.
- Files: `game/specs/0.3.2-tests-and-quick-buy.md`

### D300 · 2026-11-23 · Cost & structure · The 0.3.2 build runs in full, on budget overrides
- Decided: this session builds 0.3.2 with goal_agent, the full 30 goals, each hour on the designer's `budget_guard.py --allow-for 60`.
- Why: the designer picked the full run over a capped or delayed one.
- Rejected: capping at 8 goals; waiting for the 11/28 reset.

### D301 · 2026-11-23 · Workspace & agents · goal_agent records a change with no agent to brief as built
- Decided: a change goal with no code owner and no impacted test (0.3.2 C3) is recorded as built and its test lines build it, instead of crashing on an empty thread pool or being held.
- Why: the run crashed at C3 with `ValueError: max_workers must be greater than 0` (L56).
- Files: `_tools/goal_agent.py`, `_tools/test_goal_agent.py`, `_meta/learnings.md`

### D302 · 2026-11-24 · Game build · No hint said twice; quick-buy shows its price once
- Decided: 0.3.2 item 8: the zoom's "Drag across the cells" line and the centrifuge's "Tap or hold to spin" line go, the bubble versions stay; "All cells uncapped!" stays. Item 6: the quick-buy `QuickBuyPrice` label goes, the Buy button shows the price as on a Shop row.
- Why: play-test: "there's redundant hint messages now, keep the bubble hint versions"; "duplicate price label and button for the quick buy bar".
- Rejected: a "Buy" button with a separate price label.
- Files: `game/specs/0.3.2-tests-and-quick-buy.md`

### D303 · 2026-11-24 · Game build · Habitat Health as a fill bar reading "10/100"
- Decided: 0.3.2 item 9: `HabitatPill` becomes a wildflower glyph and a bar that fills toward thriving, labelled "health/thriving"; size and colours are placeholders; the flower centre is the gold token to pass V1 (C9 accepted).
- Why: play-test: "habitat health should be more obvious, the pink circle isn't obvious".
- Rejected: a Milo vote first; a bigger flower with no bar.
- Files: `game/scripts/habitat_pill.gd`, `game/scenes/main.tscn`

### D304 · 2026-11-24 · Pipeline design · Play-test notes during a run go to a draft
- Decided: while a goal run holds `_meta/usage/goal-run.lock`, the spec stays locked; play-test notes go to `_meta/drafts/<version>/` and into the spec once the run stops, with lint and fact-check re-run; a wanted change is worded as a change ("today X; after this change Y") so the fact-check reads it as NEW.
- Why: the hook blocked the spec edit mid-run, and the first fact-check called the wanted behaviour UNTRUE.

### D305 · 2026-11-24 · Pipeline design · Milo's preview vote next; goal_agent built C7 past its STOP
- Decided: C7's empty `PreviewTile`s stay; Milo's two variants per upgrade and the `upgrade-previews` Design Votes section come next, and the pick fills the tiles. The skipped STOP is learning L57, a planner job for goal_agent.
- Why: goal_agent committed C7 green although item 7 says "**Stop:** the designer's pick".
- Rejected: hiding the empty tiles until after 11/29.
- Files: `_meta/learnings.md`

### D306 · 2026-11-24 · Game build · The hint walk cranks every load; its post-sale check follows the state
- Decided: the hint walk cranks through every pile reload (the hang); Patricia's `truck.sold` signal ends the Sell hint at the sale; the post-sale check expects `hint_shop` on the farm view and no bubble at the second stop; C1 accepted (`e34a4c3`).
- Why: diagnostics showed the walk cranked one load and then waited for Sell for 15 minutes, and the game was already back on the farm view after the sale.
- Files: `game/tests/test_helpers_4.gd`, `game/scripts/hint.gd`, `game/scripts/truck.gd`

## Still open

- Doris: `UI_DESIGN.md:22` says round icons each have a label, while rule 6, STYLE_GUIDE V9 and GDD §9 say action icons carry no word; should rule 3 say "told apart by shape alone" for every icon, or keep labels on the non-action icons (Shop, Journal)?
- Whether `UI_DESIGN.md`'s "number and wildflower icon only" Habitat pill rule changes for the 0.3.2 Habitat bar (asked 11/24, no answer yet).
- The rest of the 0.3.2 run: C8 (hints said twice), C5 (adversarial QA) and the test lines, incl. T6.2 for the quick-buy price label.
- Milo's upgrade-preview vote (2 variants x 8 upgrades), then the pick.
- L57: goal_agent should stop before a change whose spec text holds a designer **Stop:** (planner job).
- goal_agent can't close goals by a designer's decision (`--accept` only rewrites ledger entries).
- Roadmap Q3 (starting upgrades bought with Royal Crystals) and the rows 1-16 re-layer; Gerard's watering proposal.
- Play-test placeholders: quick-buy bar, Habitat bar, welcome/victory/Settings/hint bubble sizes, minutes to victory (Terry: 25).
- A7 audit refresh and PDF, and the run video (due 11/29).
- L52 check 3 (event shots); [[pending-approvals]]; the first `/dream` pass; stale README TBD boxes (ask first).
