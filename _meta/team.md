# Team - the AI agents that build Chill Bee Game

One job: the roster of agent roles, which model each runs on, and the rules every agent follows. A role becomes runnable when it has a definition in `.claude/agents/`, copied from [`_templates/agent.md`](../_templates/agent.md). Token costs and the daily budget live in [agent-runs.md](agent-runs.md).

## Roster

All agents run through Claude Code. Larger models use up the shared Pro limits faster, so each agent gets the smallest model that fits its task type, set with the `model:` field of its definition. Agent calls stay inside their own token window so contexts don't overlap.

| Agent | Role | Task type | Model | Why this model | Definition |
|---|---|---|---|---|---|
| Gerard | Gameplay Architect | Feature design: reasons across all systems | Opus | Must catch contradictions between systems (e.g., the "nothing transfers between worlds" conflict) | [gameplay-architect.md](../.claude/agents/gameplay-architect.md) |
| Terry | Progression Tree Expert | Balance analysis: multi-step progression math | Opus | Long, numeric, iterative modelling; errors compound across runs | [progression-tree-expert.md](../.claude/agents/progression-tree-expert.md) |
| Connie | Compliance Officer | Compliance review from Ruth's research briefs | Sonnet | Rule lookup and checklists; a human signs off anyway. Use Opus for the pre-submission review | [compliance-officer.md](../.claude/agents/compliance-officer.md) |
| Patricia | Programmer | Code generation (GDScript, backend) | Sonnet | Strong at routine code; escalate to Opus for architecture or backend design | [programmer.md](../.claude/agents/programmer.md) |
| Quinn | QA & Build Engineer | Tests, builds, profiling | Sonnet | Writes tests and reads build and profiler output | [qa-build-engineer.md](../.claude/agents/qa-build-engineer.md) |
| William | Writer | Story outlines, EN/FR Journal facts | Sonnet | Good writing and French; facts are reviewed by a partner | [writer.md](../.claude/agents/writer.md) |
| Clara | Content Critic | Checks drafts against the GDD (lore, tone, child safety, facts and French, cited sources); PASS or FAIL verdict | Sonnet | Close reading across several GDD sections and EN/FR parity, with no multi-step math. Runs up to 3 times per output, so Opus would multiply cost. Haiku is cheaper, but a missed lore or child-safety FAIL ships to players | [content-critic.md](../.claude/agents/content-critic.md) |
| Ruth | Research Assistant | Finds and verifies sources: each claim with a verbatim quote, URL and date, or reported as not supported | Sonnet | Back on Sonnet after one Haiku brief (2026-11-01): it summarised 8 claims as "all supported" while its own notes called two only "predominately" or "plausible", Clara failed four of them, and it ignored the brief template (wrong frontmatter, set its own status, no findings table). Originally tried on Haiku: Search and quote-extraction within a fixed fetch budget. Haiku may misjudge whether a quote exactly supports a claim, but Clara (Sonnet) independently fetches every cited URL and FAILs any quote that does not, so a miss costs a round rather than shipping. Review after 5 briefs: back to Sonnet if 2 or more caused a source FAIL (a `## Research, round N` section on the blackboard), if 2 of the first 3 did, or at once if a wrong fact from Ruth gets past Clara | [research-assistant.md](../.claude/agents/research-assistant.md) |
| Bob | Builder | Godot scenes (`.tscn`) from a layout spec | Sonnet | Structured file output that follows a spec | [builder.md](../.claude/agents/builder.md) |
| Andrew | Audiophile | Search and curate audio | Haiku | Search and list-making; little reasoning needed | [audiophile.md](../.claude/agents/audiophile.md) |
| Martin | Hiring Manager | Agent definitions from a template | Haiku | Fills a fixed template; the developer reviews the diff | [hiring-manager.md](../.claude/agents/hiring-manager.md) |
| Doris | Doc Auditor | End-of-day check of docs against the day's changes: finds statements the changes made untrue; read-only | Sonnet | Close reading of prose against code and config, across many files, like Clara's check; no multi-step math. Runs once a day and nothing checks it after, so Haiku's misses would stay in the docs | [doc-auditor.md](../.claude/agents/doc-auditor.md) |

Every role has a definition. New roles come from Martin, copied from the template.

## Roles

Each agent is a module in the development workflow: a developer input triggers it, and it produces a structured output.

- **Gerard, the Gameplay Architect:** analyzes a proposed feature against the existing gameplay systems when the developer proposes a new feature, and the developer sees a structured representation of how the feature affects the others.
- **Bob, the Builder:** assembles biome dioramas and terrain chunks as Godot scene files (`.tscn`) from a layout description, and the developer sees the finished scene, following the layout's specs.
- **Patricia, the Programmer:** creates modular components and code for the game engine from a list of features, and the developer sees the completed components or scripts. Also owns backend integration.
- **William, the Writer:** writes the story outline from an idea for a story point, lesson or goal, and the developer sees a completed outline. Also drafts the Bee Journal's real-world facts in English and French, from Ruth's research briefs, for review by a conservation partner.
- **Ruth, the Research Assistant:** finds and verifies sources for real-world claims when William needs Bee Journal facts checked, or Connie needs a rule or policy sourced, or a Clara FAIL row asks for a better source; the developer sees a brief in `research/` with each claim, its verbatim quote, URL, source kind and date checked, and the claims it could not source.
- **Clara, the Content Critic:** checks William's content drafts against `GDD.md` for lore, tone and glossary, child safety and spending, facts and French, and cited sources, and replies with a PASS or FAIL verdict with findings, which the script appends to the run's blackboard; William revises the draft, and the developer sees the verdict.
- **Andrew, the Audiophile:** searches and curates sound effects and music from a description of a sound, environment, vibe or place, and the developer sees a curated, structured list and a folder with the selected audio files.
- **Terry, the Progression Tree Expert:** analyzes the balance of the progression tree (efficiency, cost, speed, space and other metrics) for a suggested upgrade or progression, and the developer sees a detailed report comparing it against the existing upgrades and progressions.
- **Martin, the Hiring Manager:** when the lead architect notices a skill gap, writes a new agent definition by copying [`_templates/agent.md`](../_templates/agent.md) into `.claude/agents/` and adds the role to the roster above; the developer reviews the git diff.
- **Connie, the Compliance Officer:** reviews features for child safety (kid mode, COPPA, app-store kids and families rules, ad SDK settings), charity and cause marketing (donation disclosures, partner agreements), privacy and data (PIPEDA, Quebec Law 25, privacy policy) and store policy (subscriptions, premium currency, rewarded ads, donations) when a feature touches those areas or before store submission. The developer sees a findings report and checklist in `proposals/compliance/`, citing official sources, with items needing lawyer or partner sign-off marked.
- **Quinn, the QA & Build Engineer:** writes and runs tests, produces mobile builds, and profiles performance against the 60 FPS target when a feature or build is ready for testing, and the developer sees a test report, build output and performance profile.
- **Doris, the Doc Auditor:** at the end of the working day, the `end-of-day` skill gives her the day's `git diff` and changed-file list, and she finds every doc statement those changes made untrue, citing the code, config or GDD line that contradicts it; the main session or the developer sees her findings table, and she edits nothing.

## Rules for every agent

1. **Scope boundary:** output only deliverables within the role's domain (e.g., Patricia handles GDScript/C#, Terry handles numeric balance).
2. **Deterministic formatting:** follow the predefined Markdown templates in `_templates/` or agreed JSON structures, so one agent's output is the next one's input.
3. **No invented systems:** ground every suggestion in `GDD.md`: the existing 3-phase progression model and the low-poly 3D constraints.
4. **Agents propose; the designer decides.** No agent edits `GDD.md` (see [AGENTS.md](../AGENTS.md)).

## Model reviews

Every model choice is a bet that the agent's mistakes are caught downstream. A cheaper model is safe when a stronger check follows it; the price of its mistakes is rework, which can be counted.

- **Review** an agent's model after 5 runs of its kind, counting its signal in the table below. Switch up (or back) when the rework costs more than the cheaper model saves: as a rule of thumb, when 2 or more of 5 runs (or 2 of the first 3) needed rework. Switch at once if a mistake gets past every agent and the designer catches it.
- **Switch down** only an agent that has a stronger check after it.
- **Critics have no check after them.** Before and after any change to Clara's model or rules, run `python -I _tools/critic_check.py`: she must FAIL each known-bad draft in `_tools/fixtures/` with every expected finding (for `onboarding-bad.md`: the false bloom fact, the "cheapest" upgrade, the wrong §9 citation). Exit code 0 means she caught them all. Add a fixture whenever she misses something real.

| Agent | Checked by | Signal (rework) | Recorded in |
|---|---|---|---|
| Ruth (Sonnet; Haiku tried once, reverted) | Clara | briefs that caused a source FAIL | `## Research, round N` sections on blackboards |
| William (Sonnet) | Clara | rounds per run (1 is clean) | each blackboard's Result |
| Clara (Sonnet) | the designer only | known errors missed | `_tools/critic_check.py` |
| Andrew (Haiku) | Connie, the designer | picks with a wrong or unclear licence | audio list reviews |
| Martin (Haiku) | the designer's diff review | definitions fixed after he wrote them | git history |
| Patricia, Bob (Sonnet) | Quinn | failing tests per feature, whoever fixed them | `game/reports/`, Rework tally |
| Quinn (Sonnet) | the designer playing the build | bugs found after a passing report; defects in Quinn's own tests found by anyone else | `game/reports/`, Rework tally |
| Gerard, Terry (Opus) | the designer's decision | proposals rejected or revised | `status:` and the ledger |
| Connie (Sonnet) | lawyer or partner sign-off | findings overturned | her reports |
| Doris (Sonnet) | the designer | findings later found wrong or missed | end-of-day reports |

### Rework tally

Every bug in an agent's work, counted against that agent whoever fixed it (`game/CONTEXT.md`, Fixes). It is the evidence for the Model reviews above. **Revisit a dedicated fixer agent** if cross-domain bugs (diagnosis spanning several owners) appear in 3 of the next 5 features, or Quinn's diagnosis names the wrong owner in 2 of 5 runs (Martin, 2026-11-03).

| Date | Feature | Agent | Rework | Fixed by | Recorded in |
|---|---|---|---|---|---|
| 2026-11-03 | Prototype 0 | Patricia | 1 blocking bug: `get_camera_3D()` for `get_camera_3d()` in `honeycomb.gd`; dragging could not uncap cells. Her checks never exercised input | orchestrator | `game/reports/2026-11-03-prototype-0.md` |
| 2026-11-03 | Prototype 0 | Quinn | 1 test defect: `play_loop.gd` sent drag coordinates in viewport pixels where `push_input` expects window pixels | orchestrator | `game/reports/2026-11-03-prototype-0.md` |
| 2026-11-03 | Prototype 0 | Bob | 0 failing tests; 4 cosmetic issues (fill bar, No-Rapid-Tap label contrast, backdrop bands, shop overlap), 3 fixed by Bob in revision 2 | Bob | `game/reports/2026-11-03-prototype-0.md` |
| 2026-11-03 | Prototype 0 rev 2 | Bob | 1 cosmetic issue left as fixed but still present: the shop panel covers the meadow's tip when the hive is full; his render showed only the starting state, where it doesn't. Open | — | `game/reports/2026-11-03-prototype-0.md`, Revision 2 |
| 2026-11-03 | Prototype 0 rev 2 | Quinn | 3 test defects, all found and fixed by Quinn before reporting (not counted: found by the owner) | Quinn | `game/reports/2026-11-03-prototype-0.md`, Revision 2 |
| 2026-11-03 | Prototype 0 rev 2 | Bob | 1 regression: the `Light` he added to `harvest.tscn` stacks with the farm's `Sun` and washes capped cells to the uncapped yellow, so uncapping no longer reads as a pop. Found by the designer playing. Open | — | `game/reports/2026-11-03-prototype-0.md`, Open for revision 3 |
| 2026-11-03 | Prototype 0 rev 2 | Quinn | 1 review miss: the report described the v2-2 capped cells as "darker orange" when the screenshot shows them nearly the same yellow as uncapped, so the regression passed | — | `game/reports/2026-11-03-prototype-0.md`, Revision 2 |
| 2026-11-04 | Prototype 0 rev 3 | Patricia | 0 bugs: 60/60 spec-first unit tests and 1015 real-input play_loop checks pass on her code; 5 mutation runs confirm the tests catch the targeted faults | — | `game/reports/2026-11-04-prototype-0-r3.md` |
| 2026-11-04 | Prototype 0 rev 3 | Bob | 0 failing tests; closes the rev 2 Light regression (capped vs uncapped measured 83/442 RGB apart) and the shop overlap; 2 minor layout items left (Sell icon over the hive, truck exit clips the shop corner) | — | `game/reports/2026-11-04-prototype-0-r3.md`, Open for revision 4 |
| 2026-11-04 | Prototype 0 rev 3 | Quinn | 2 harness defects (headless touch via `parse_input_event`; hold via `push_input` doesn't set the mouse-pressed state), found and fixed by Quinn before reporting (not counted: found by the owner) | Quinn | `game/reports/2026-11-04-prototype-0-r3.md` |
| 2026-11-04 | Prototype 0 rev 3 | Bob | 1 cosmetic bug found by the designer playing: opaque `focus` styles paint over the disabled style, so the disabled Upgrade button stays gold until focus moves (also on Continue, icons, OK, Back). Open, deferred to revision 4 | — | `game/reports/2026-11-04-prototype-0-r3.md`, Open for revision 4 |
| 2026-11-04 | Prototype 0 rev 3 | Quinn | 1 review miss: tests check `disabled`, not how a focused disabled button renders, so the gold-while-disabled Upgrade button passed | — | `game/reports/2026-11-04-prototype-0-r3.md`, Open for revision 4 |
