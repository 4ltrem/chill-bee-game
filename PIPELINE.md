---
author: orchestrator
type: write-up
status: proposed
milestone: M5 (Assignment 7)
description: The complete AI dev pipeline: the playable link and how to play it in two minutes, the automated flow from spec to web build, and the one-page pipeline audit (manual steps, architecture change, cost); the full audit is in _meta/drafts/a7/audit.pdf
---
# The complete AI dev pipeline (Assignment 7)

## ▶ Play it now: [4ltrem.itch.io/chill-bee-game](https://4ltrem.itch.io/chill-bee-game)

Runs in the browser, nothing to install. Open the link, click **Run game**, wait a few seconds for it to load (about 8 MB), then tap **Play**. A hint bubble points at each step the first time:

1. **Wait** for the bees to fill the hive (the count above it).
2. **Tap the fork icon** over the full hive to harvest.
3. **Swipe across the comb** to uncap the cells.
4. **Tap the centrifuge icon**, then **tap or hold the crank** to spin the honey out.
5. **Tap Sell** to send the honey off in the truck.
6. **Open the Shop** and spend your earnings: upgrades, automation, and a wildflower patch for the wild bees.

Mouse or touch both work. The gear icon opens Settings (English / français). Version 0.3.2.

## The pipeline

| | |
|---|---|
| **Game** | Chill Bee Game: a cozy beekeeping idle game. Harvest honey by hand (uncap, spin, bottle, sell), then automate the farm step by step while planting habitat for wild bees. |
| **Playable link** | https://4ltrem.itch.io/chill-bee-game (web, Godot HTML5 export) |
| **Pipeline repository** | https://github.com/4ltrem/chill-bee-game (this repo: agents in `.claude/agents/`, loop scripts in `_tools/`) |
| **Pipeline run video** | *to be added* |
| **Target engine** | Godot 4.2.1 (GDScript) |
| **Full audit** | [`_meta/drafts/a7/audit.pdf`](_meta/drafts/a7/audit.pdf): pipeline audit and cost analysis, more than 20 pages |

**Automated flow.** An accepted design becomes a build spec (`game/specs/<version>.md`). `_tools/goal_agent.py` parses it into goals and builds them one by one with headless agents: Patricia writes the GDScript into `game/scripts/`, Bob writes the `.tscn` scenes into `game/scenes/`, and Quinn writes the tests into `game/tests/`. Each agent writes straight into the Godot project. Scripts then run the tests, mutation checks and screenshots (`godot_run.py`, `mutate.py`, `ui_shots.py`), and `contract_check.py` proves every node a script looks up exists in a scene. Text goes through the content loop (`generate.py`: William writes EN/FR, Clara checks it against the GDD), and `journal_csv.py` turns the approved Markdown into Godot's translation CSV, which `TranslationServer` loads. No file is reformatted by hand between an agent and the running game. `build.py 0.3.2 --targets web` exports and zips the web build for itch.

### Pipeline audit (summary)

**What the pipeline produced, present in the playable build.** All of the game's code and scenes: the harvest loop (uncap, spin, bottle, sell), the camera zooms, the Shop sheet with its upgrades and the self-driving truck, Settings, the welcome and victory screens, and Dev mode, built from specs 0.1 to 0.3.1 by the goal agent and subagents. 249 tests and 215 mutation checks guard it. Every line of player-facing text in `game/translations/journal.csv` came through the content loop and is shown in English and French: the 9 first-time hints (`content/first-time-hint.md`, e.g. "Tap the fork to harvest the hive!"), the Shop, farm, Settings and toast labels (`content/ui-labels.md`), the victory text (`content/course-ending-text.md`) and the Bee Journal's bumble bee entry (`content/bee-journal-real.md`, facts sourced by Ruth with verbatim quotes).

**Manual steps that remain, and what would remove them.**

| Step | Why it is manual | To automate it |
|---|---|---|
| Designer approvals (proposals, content, Design Votes picks) | by design: nothing reaches the GDD or the game without the designer's yes | auto-accept content that passes Clara and the script checks with no open rows, and keep votes only for new looks |
| Play-testing | layout and visibility bugs (a hidden message, a moved button) pass every test and reach the designer (L52) | a visual check on every build: `ui_shots.py` frames judged by Vera against `UI_DESIGN.md`, and overlap tests on drawn rectangles |
| A goal whose two fix rounds fail | the goal agent stops (5 times in 0.3.1) for hand debugging or acceptance by note | a third round with a stronger model and the failing test's diag lines, then a skip-and-report instead of a stop |
| Content export and itch upload | `journal_csv.py` is one command after approval; the zip is uploaded on itch's web page | run the export from the approval step, and upload with itch's `butler` CLI from `build.py` |

**Architectural change.** The weak point is the long-lived Opus main session that orchestrates everything: it holds the whole day's context and re-reads it on every call, which is 80% of the cost. An agent operator on Sonnet was tried to take routing and waiting off it, and retired because it stopped at the first real task (L55). **Alternative:** a script orchestrator, `pipeline.py`, that chains the stages goal_agent.py already chains for one spec (spec → build → tests → shots → web export → upload), keeps all state on the run board, and starts a short Opus session only at a decision, briefed with that board's open rows rather than a day of history.

**Cost** (API list prices applied to the transcripts' own token counts by `_tools/run_cost.py`; the plan itself is flat-rate):

- **Total actual run cost: USD 730.25 (CAD 1,036.96)** for the whole project to 2026-11-26 (1.86 billion tokens, mostly cache reads; CAD at 1.42 per USD, mid-November 2026). One actual content run (`guides-run-5`, William and Clara, two rounds): **USD 0.32 (CAD 0.45)** for 186,229 tokens. One goal-agent build of a version's spec: USD 6.51–10.72 (CAD 9.24–15.22).
- **Most expensive step:** the Opus 5.5 orchestrator session, USD 584 (CAD 829) (80%), about half of it cache reads from re-reading a long context. The costliest single session, building Prototype 0, came to USD 57.78 (CAD 82.05). Within the headless pipeline: Quinn's test fix calls (0.3.1 T4.3: USD 1.72, CAD 2.44).
- **Sustainability:** yes for a solo developer or small team. About USD 27 (CAD 38) per working day and about USD 80 (CAD 114) per playable version at list prices, and flat-rate on a plan. The agents that build, write and check cost only USD 146 (CAD 207) of the total, so the lever is the orchestrator: Sonnet instead of Opus there would save about USD 290 (CAD 412), and short sessions save more.

**Mid-project cost reduction: scripts run by a Haiku runner instead of the QA agent** (2026-11-08, L21).

| | Strategy | Tokens / cost |
|---|---|---|
| **Before** | Quinn (Sonnet) ran the Godot suites himself and read the full logs in his context | 1.16M–9.06M tokens per run; USD 0.64–2.41 (CAD 0.91–3.42), USD 1.50 (CAD 2.13) on average |
| **After** | `godot_run.py` summarises each suite; Rex (Haiku) runs it and replies with counts and first errors only | about 88k tokens per run; 122 runs for USD 0.44 (CAD 0.62) in all, under half a cent each |
