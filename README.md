# chill-bee-game

Multi-Agent AI for Game Development Assignment repo.

## ▶ Play it now: [4ltrem.itch.io/chill-bee-game](https://4ltrem.itch.io/chill-bee-game)

Runs in the browser, nothing to install. Open the link, click **Run game**, wait a few seconds for it to load (about 8 MB), then tap **Play**. A hint bubble points at each step the first time:

1. **Wait** for the bees to fill the hive (the count above it).
2. **Tap the fork icon** over the full hive to harvest.
3. **Swipe across the comb** to uncap the cells.
4. **Tap the centrifuge icon**, then **tap or hold the crank** to spin the honey out.
5. **Tap Sell** to send the honey off in the truck.
6. **Open the Shop** and spend your earnings: upgrades, automation, and a wildflower patch for the wild bees.

Mouse or touch both work. The gear icon opens Settings (English / français). Version 0.3.1.

## Assignment 7: the complete AI dev pipeline

| | |
|---|---|
| **Game** | Chill Bee Game: a cozy beekeeping idle game. Harvest honey by hand (uncap, spin, bottle, sell), then automate the farm step by step while planting habitat for wild bees. |
| **Playable link** | https://4ltrem.itch.io/chill-bee-game (web, Godot HTML5 export) |
| **Pipeline repository** | https://github.com/4ltrem/chill-bee-game (this repo: agents in `.claude/agents/`, loop scripts in `_tools/`) |
| **Pipeline run video** | *to be added* |
| **Target engine** | Godot 4.2.1 (GDScript) |
| **Full audit** | [`_meta/drafts/a7/audit.pdf`](_meta/drafts/a7/audit.pdf): pipeline audit and cost analysis, more than 20 pages |

**Automated flow.** An accepted design becomes a build spec (`game/specs/<version>.md`). `_tools/goal_agent.py` parses it into goals and builds them one by one with headless agents: Patricia writes the GDScript into `game/scripts/`, Bob writes the `.tscn` scenes into `game/scenes/`, and Quinn writes the tests into `game/tests/`. Each agent writes straight into the Godot project. Scripts then run the tests, mutation checks and screenshots (`godot_run.py`, `mutate.py`, `ui_shots.py`), and `contract_check.py` proves every node a script looks up exists in a scene. Text goes through the content loop (`generate.py`: William writes EN/FR, Clara checks it against the GDD), and `journal_csv.py` turns the approved Markdown into Godot's translation CSV, which `TranslationServer` loads. No file is reformatted by hand between an agent and the running game. `build.py 0.3.1 --targets web` exports and zips the web build for itch.

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

- **Total actual run cost: $730.25** for the whole project to 2026-11-26 (1.86 billion tokens, mostly cache reads). One actual content run (`guides-run-5`, William and Clara, two rounds): **$0.32** for 186,229 tokens. One goal-agent build of a version's spec: $6.51–$10.72.
- **Most expensive step:** the Opus 5.5 orchestrator session, $584 (80%), about half of it cache reads from re-reading a long context. The costliest single session, building Prototype 0, came to $57.78. Within the headless pipeline: Quinn's test fix calls (0.3.1 T4.3: $1.72).
- **Sustainability:** yes for a solo developer or small team. About $27 per working day and about $80 per playable version at list prices, and flat-rate on a plan. The agents that build, write and check cost only $146 of the total, so the lever is the orchestrator: Sonnet instead of Opus there would save about $290, and short sessions save more.

**Mid-project cost reduction: scripts run by a Haiku runner instead of the QA agent** (2026-11-08, L21).

| | Strategy | Tokens / cost |
|---|---|---|
| **Before** | Quinn (Sonnet) ran the Godot suites himself and read the full logs in his context | 1.16M–9.06M tokens per run; $0.64–$2.41, $1.50 on average |
| **After** | `godot_run.py` summarises each suite; Rex (Haiku) runs it and replies with counts and first errors only | about 88k tokens per run; 122 runs for $0.44 in all, under half a cent each |

**Chill Bee Game** is a cozy, mobile-first beekeeping idle game. You start by harvesting honey by hand, automate the farm step by step, and then reset it for permanent bonuses. A share of the game's revenue funds real-world bee conservation. The working titles are *Digibees*, *My Bee Hotel* and *Pocket Hive*.

The full design is in [GDD.md](GDD.md). The document is a **first draft**: the systems are mostly defined, but most of the numbers are not yet (see [Outstanding TBDs](#outstanding-tbds)).

---

## Game Overview

### Pitch
The game is a cross between *Egg, Inc.* and *Factorio*. The player discovers a tiny magical pocket world that needs a beekeeper to restore it. You pan and zoom around a low-poly diorama farm as it grows, and upgrade three things: the bees, the hive and tools, and the native habitat. The habitat tree is measured in biodiversity rather than honey: native wild bees pollinate, boost production, and fill a Bee Journal, while too many managed hives without enough habitat lowers Habitat Health.

### Core Loop
**Bees forage → hive fills → uncap & extract → sell honey → reinvest**

| Phase | What the player does |
|---|---|
| **1. Manual** | Harvest by hand in a tactile three-stage minigame: swipe to uncap the comb, spin the centrifuge, then bottle the honey and send the truck to sell it. A small free overflow buffer keeps production going while the hive is full. |
| **2. Automation** | Buy automation upgrades (the centrifuge motor, the auto-scraper, a truck that sells by itself) to take over the manual work. |
| **Expansion** | Buy land and place hive and flower units on each biome's grid. Biomes can grow indefinitely, and higher-tier units cost more but fit more honey production into less space. |
| **3. Optimization** | Build the capstone Royal Honey Refinery and charge it with honey from every biome to earn a **Royal Crystal**. Then optionally reset: the swarm splits and leaves to restore a new pocket world. Crystals carry over, and each one gives a stacking production boost plus one starting upgrade for future runs. |

Within a run, the player moves through four biomes in order: Sunny Meadow → Alpine Valley → Enchanted Grove → Cloud Gardens. Reaching a biome's Habitat Synergy threshold (enough flowers for its bees) unlocks the next one, and earlier biomes keep producing. The capstone is normally reached in the last biome, but can be speedrun from the first. Each finished world is kept as its own save that can be loaded and played.

### Currencies
- **In-game money:** earned by selling honey; spent on land, units, upgrades and research; resets each run.
- **Royal Jelly (premium):** earned slowly through play and ads, or bought; spent on time skips; kept across resets.
- **Royal Crystal (prestige):** earned by charging the Refinery; each gives +15% production (additive) and one starting upgrade; account-wide.

### Leaderboards (post-launch, opt-in)
The game is cozy by default; players who want to compete opt into speed-run boards. These boards measure wall-clock time from the start of a run until the Royal Crystal forms, validated on the server. Players only race others with the same set of paid boosters and a similar Royal Crystal count. Watching free rewarded ads keeps a player on the unboosted board, but spending Royal Jelly on time skips puts the run in its own bracket.

### Real-World Impact
A fixed percentage of each revenue stream funds bee conservation (native bee habitat and managed hives), starting with Canadian partners. The revenue streams are rewarded ads, the Impact Pass and the Patron Pass.

### Audience & Scope
- **Audience:** adults and teens who play cozy games, with family-friendly content. An age gate turns on a kid mode for under-13s: no personalized ads, a parental gate on purchases, and no public username.
- **Team:** a solo developer directing AI agents in Claude Code. The agent roles are in [_meta/team.md](_meta/team.md).
- **Engine:** Godot (GDScript). Art comes from purchased low-poly asset packs.
- **Launch platforms:** iOS and Android, in English and French.
- **Timeline:** milestone-based, with no fixed launch date. The course builds have dates up to 0.3.0 (2026-11-29) in [MILESTONES.md](MILESTONES.md); the first playable is one full rough run in Sunny Meadow.
- **Launch scope:** Sunny Meadow and Alpine Valley, rewarded ads and the Impact Pass, local personal-best times.
- **Post-launch:** biomes 3–4, the Patron Pass, online leaderboards, the live Impact Dashboard, and possibly Switch and PC/Mac.

---

## Repository Contents

| Path | Contents |
|---|---|
| [AGENTS.md](AGENTS.md) | Entry file for AI agents: where everything lives and where to go for each task. |
| [CONTEXT.md](CONTEXT.md) | The design loop: request, proposal, decision, apply. |
| [GDD.md](GDD.md) | Game design document |
| [MILESTONES.md](MILESTONES.md) | Build stages, version numbers (`0.<milestone>.<build>`) and the milestones with their course deliverables |
| [STYLE_GUIDE.md](STYLE_GUIDE.md) | The approved look and voice rules (V1–V15, T1–T6) and palette tokens that scenes and text are checked against. |
| [STYLE_LOOP.md](STYLE_LOOP.md) | How the two style loops (visual: Bob, `style_check.py`, Vera; voice: William, Clara) enforce the guide, with the demo runs and their cost. |
| [UI_DESIGN.md](UI_DESIGN.md) | The designer's UI preferences and the UI canvas map; read before any UI work. |
| [GOAL_AGENT.md](GOAL_AGENT.md) | The goal agent (`_tools/goal_agent.py`) that builds a milestone spec goal by goal, with the 0.1.4 run and its cost. |
| [ONBOARDING.md](ONBOARDING.md) | A draft onboarding guide for working in this repository (unfinished). |
| [gdd-review/reviews/](gdd-review/reviews/) | A multi-agent design review of the first draft. Six reviewer agents each reviewed it independently, then cross-examined each other, and a moderator wrote a synthesis ([SYNTHESIS.md](gdd-review/reviews/SYNTHESIS.md)). It was run with [gdd-review-kit](https://github.com/GixGosu/gdd-review-kit). |
| [gdd-review/gdd.txt](gdd-review/gdd.txt) | Snapshot of the GDD as it was reviewed. Many review findings have since been addressed in `GDD.md`. |
| [proposals/design/](proposals/design/) | Feature design proposals, e.g. the capstone [Royal Honey Refinery](proposals/design/capstone-machine.md) (Gerard). |
| [proposals/balance/](proposals/balance/) | Balance reports, e.g. [Royal Crystal balance](proposals/balance/royal-crystal-balance.md) (Terry). |
| [CREW.md](CREW.md) | The content crew: three agents (Ruth, William, Clara) and the orchestrator that produce the game's player text, with a diagram and results. |
| [content/](content/) | Story outlines and Bee Journal text in English and French (William). |
| [research/](research/) | Checked sources (Ruth): each claim with a verbatim quote, URL and date, for William and Connie. |
| [audio/](audio/) | Licence-checked sound and music shortlists (Andrew). |
| [game/](game/) | The Godot project: scripts (Patricia), scenes (Bob), tests and reports (Quinn); `game/reports/` holds builds, goal runs, style runs, votes and variants. |
| [_tools/](_tools/CONTEXT.md) | The workspace scripts: checks, the content, style and goal loops, vote pages, Godot test and build runners, usage hooks, end-of-day helpers. |
| [operator/](operator/CONTEXT.md) | The operator's contract (Oscar, a Sonnet main session that routes the day's work), the stops it hands off and the job queue (retired 2026-11-23; kept as history). |
| [_templates/](_templates/) | Blank starters for proposals, content, research briefs, audio lists, run blackboards, decision logs and new agents. |
| [_meta/learnings.md](_meta/learnings.md) | Everything that broke, how it was noticed, its cause, fix and the check that now prevents it. |
| [_meta/](_meta/) | Workspace records: the roster, run log, learnings, project memories (`memory/`) and each session's decision log (`sessions/`). |
| [_meta/team.md](_meta/team.md) | The agent roster, each agent's model, and the rules they follow; each has a definition in `.claude/agents/`. |
| [_meta/agent-runs.md](_meta/agent-runs.md) | Token, tool-call and duration summary of every agent run; the rows are in `agent-runs.csv`. |
| [.claude/agents/](.claude/agents/) | Runnable Claude Code agent definitions, one per role in the roster. |
| [gdd-review-v2/](gdd-review-v2/) | Second review, of the GDD at commit `8ddb97a` after the first round of fixes and peer feedback. Its [SYNTHESIS.md](gdd-review-v2/reviews/SYNTHESIS.md) compares the results with the first review. |

---

## Outstanding TBDs

### Economy & Numbers
- [ ] Income side of the economy: base jar price, bee fill rate, harvest cycle time
- [ ] Habitat Health values (multipliers, costs, levels) and how much hive count lowers it
- [ ] Honey sale value for each biome
- [x] Automation upgrade costs (motor, auto-scraper, Faster Delivery): provisional, first-automation-values
- [ ] Spigot Flow (bottling speed): levels and costs (provisional placeholders in 0.2.1; Terry checks before 0.3.0)
- [ ] Bee Journal sources list in-game, so the entries' ⁵/⁶ markers (kept verbatim, designer 2026-11-09) point to their sources
- [ ] Heated Fork "clean cut" batch bonus: what counts as a clean cut (reach is its effect; a single sweep is the Long Fork)
- [ ] Upgrade mode UI: opening an automated unit's zoom screen (with the rest of the UI)
- [ ] Back button size (the arrow itself was decided 2026-11-23, 0.3.1 item 6; the size is a placeholder until the 0.3.1 play-test)
- [ ] Overflow Storage capacity and costs (free buffer is 1 extra frame)
- [ ] Land expansion costs
- [ ] Hive and flower unit tiers: costs, production and space per tier
- [ ] Research values (genetics multipliers and unit-tier unlocks)
- [x] Tool-upgrade flat bonuses after automation: provisional, first-automation-values
- [x] Auto-Sell costs (no discount: the truck leaves when full and sells at full price): provisional, first-automation-values
- [ ] Jar crate tiers: jars waiting and truck load per tier, upgrade costs
- [ ] Harvest logistics: centrifuge capacity (frames), truck capacity (jars) and truck trip time
- [ ] Centrifuge Gearing gears: look revision after 0.2 ("good enough for now, will need revision later", designer on `gearing-r6-b5`, 2026-11-09)
- [ ] Wider fork upgrade: a possible later upgrade, its look the wide rake head of `fork-r1-c` (designer, Design Votes 2026-11-09)
- [x] Long Fork: unlock condition, cost, and how it leads into automated uncapping: provisional, first-automation-values
- [ ] Royal Jelly prices, time-skip costs, and Patron daily stipend amount
- [ ] Impact Pass and Patron Pass prices

### Progression
- [ ] Refinery parameters (build cost, charge target, biome affinities, Habitat Synergy minimum): Terry
- [ ] Habitat Synergy threshold for each biome
- [ ] Royal Crystal starting-upgrade whitelist
- [ ] Max levels for the starting-hives and starting-wildflower-plot Crystal options
- [ ] Native bee species: provisional effects set (Terry); Glowcap digger pollination value, real values and run length with native bees still to confirm
- [ ] Flower list for the habitat tree

### Leaderboards
- [ ] Royal Crystal tier ranges: move the high split down to where the rush enters the 5% window (~92 Crystals at +15%)
- [ ] Re-check the Refinery research ladder for +15% Crystals (Terry)

### Real-World Impact
- [ ] Fixed donation percentage for each revenue stream (ads, Impact Pass, Patron Pass)
- [ ] Confirmed agreements with conservation partners

### Story & Characters
- [ ] Final game title
- [ ] Guide character's name and personality

### Production
- [ ] Milestone dates after the course (0.4 and later; the course builds are dated in [MILESTONES.md](MILESTONES.md))
- [ ] Daily token budget: first calibration gives ~2.0M tokens/day (provisional; refine with a larger task, see [_meta/agent-runs.md](_meta/agent-runs.md))
- [ ] Test device models and visual bee cap
- [ ] Backend provider (managed game-backend service)
