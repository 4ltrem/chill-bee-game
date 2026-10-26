# Team - the AI agents that build Chill Bee Game

One job: the roster of agent roles, which model each runs on, and the rules every agent follows. A role becomes runnable when it has a definition in `.claude/agents/`, copied from [`_templates/agent.md`](../_templates/agent.md). Token costs and the daily budget live in [agent-runs.md](agent-runs.md).

## Roster

All agents run through Claude Code. Larger models use up the shared Pro limits faster, so each agent gets the smallest model that fits its task type, set with the `model:` field of its definition. Agent calls stay inside their own token window so contexts don't overlap.

| Agent | Role | Task type | Model | Why this model | Definition |
|---|---|---|---|---|---|
| Gerard | Gameplay Architect | Feature design: reasons across all systems | Opus | Must catch contradictions between systems (e.g., the "nothing transfers between worlds" conflict) | [gameplay-architect.md](../.claude/agents/gameplay-architect.md) |
| Terry | Progression Tree Expert | Balance analysis: multi-step progression math | Opus | Long, numeric, iterative modelling; errors compound across runs | [progression-tree-expert.md](../.claude/agents/progression-tree-expert.md) |
| Connie | Compliance Officer | Compliance review with web checks | Sonnet | Rule lookup and checklists; a human signs off anyway. Use Opus for the pre-submission review | [compliance-officer.md](../.claude/agents/compliance-officer.md) |
| Patricia | Programmer | Code generation (GDScript, backend) | Sonnet | Strong at routine code; escalate to Opus for architecture or backend design | not yet |
| Quinn | QA & Build Engineer | Tests, builds, profiling | Sonnet | Writes tests and reads build and profiler output | not yet |
| William | Writer | Story outlines, EN/FR Journal facts | Sonnet | Good writing and French; facts are reviewed by a partner | not yet |
| Bob | Builder | Godot scenes (`.tscn`) from a layout spec | Sonnet | Structured file output that follows a spec | not yet |
| Andrew | Audiophile | Search and curate audio | Haiku | Search and list-making; little reasoning needed | not yet |
| Martin | Hiring Manager | Agent definitions from a template | Haiku | Fills a fixed template; the developer reviews the diff | not yet |

A role gets its definition on its first real task, not before.

## Roles

Each agent is a module in the development workflow: a developer input triggers it, and it produces a structured output.

- **Gerard, the Gameplay Architect:** analyzes a proposed feature against the existing gameplay systems when the developer proposes a new feature, and the developer sees a structured representation of how the feature affects the others.
- **Bob, the Builder:** assembles biome dioramas and terrain chunks as Godot scene files (`.tscn`) from a layout description, and the developer sees the finished scene, following the layout's specs.
- **Patricia, the Programmer:** creates modular components and code for the game engine from a list of features, and the developer sees the completed components or scripts. Also owns backend integration.
- **William, the Writer:** writes the story outline from an idea for a story point, lesson or goal, and the developer sees a completed outline. Also drafts the Bee Journal's real-world facts in English and French, with cited sources, for review by a conservation partner.
- **Andrew, the Audiophile:** searches and curates sound effects and music from a description of a sound, environment, vibe or place, and the developer sees a curated, structured list and a folder with the selected audio files.
- **Terry, the Progression Tree Expert:** analyzes the balance of the progression tree (efficiency, cost, speed, space and other metrics) for a suggested upgrade or progression, and the developer sees a detailed report comparing it against the existing upgrades and progressions.
- **Martin, the Hiring Manager:** when the lead architect notices a skill gap, writes a new agent definition by copying [`_templates/agent.md`](../_templates/agent.md) into `.claude/agents/` and adds the role to the roster above; the developer reviews the git diff.
- **Connie, the Compliance Officer:** reviews features for child safety (kid mode, COPPA, app-store kids and families rules, ad SDK settings), charity and cause marketing (donation disclosures, partner agreements), privacy and data (PIPEDA, Quebec Law 25, privacy policy) and store policy (subscriptions, premium currency, rewarded ads, donations) when a feature touches those areas or before store submission. The developer sees a findings report and checklist in `proposals/compliance/`, citing official sources, with items needing lawyer or partner sign-off marked.
- **Quinn, the QA & Build Engineer:** writes and runs tests, produces mobile builds, and profiles performance against the 60 FPS target when a feature or build is ready for testing, and the developer sees a test report, build output and performance profile.

## Rules for every agent

1. **Scope boundary:** output only deliverables within the role's domain (e.g., Patricia handles GDScript/C#, Terry handles numeric balance).
2. **Deterministic formatting:** follow the predefined Markdown templates in `_templates/` or agreed JSON structures, so one agent's output is the next one's input.
3. **No invented systems:** ground every suggestion in `GDD.md`: the existing 3-phase progression model and the low-poly 3D constraints.
4. **Agents propose; the designer decides.** No agent edits `GDD.md` (see [AGENTS.md](../AGENTS.md)).
