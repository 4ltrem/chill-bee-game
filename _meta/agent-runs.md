# Agent Run Log & Token Estimates

Every agent run is one row of [agent-runs.csv](agent-runs.csv): the design-review runs from 2026-10-14 to 2026-10-26, logged by hand, and every run since. The SubagentStop hook (`_tools/log_subagent.py`) logs Agent-tool subagents, `generate.py`, `critic_check.py` and `doc_audit.py` log their headless calls, and the Stop hook (`_tools/log_session.py`) logs the orchestrating main session itself, one *Orchestrator* row per session. Each row since 2026-11-03 also carries the orchestrator's tokens over the run (input, cache write, cache read, output) and plan usage % before and after it, saved by the status line (`_tools/statusline.py`). Column meanings are in `_tools/runlog.py`. Nobody needs to read the CSV whole: the summary below is generated from it.

**Phase.** Every run is tagged `pre-ICM` or `post-ICM`. The design-review runs (2026-10-14 to 2026-10-26) happened before the repository was restructured into an ICM workspace (commit `4af8e88`, 2026-10-26), when agents were briefed by ad-hoc prompts and read the whole GDD. Every run logged after that is `post-ICM`: agents follow their `.claude/agents/` definition and their shelf's `CONTEXT.md`, and load only the GDD sections a task touches. Keep the two apart when averaging, so the restructure's effect on token cost shows.

**Measures.** Two token counts appear in this log, and they differ several-fold for the same run:
- *Final context*: the size of the conversation at an agent's last call. The Agent tool reports this, so every pre-ICM run and every Subagent run has it.
- *Total processed*: the sum over all of an agent's calls. Each call re-sends the conversation, mostly as cheap cache reads, so this grows with the number of turns. `generate.py`, `critic_check.py` and the hooks log it.
Martin's run hiring Clara was 39,232 final context but 234,632 total processed. Compare rows only within one measure. Which one Anthropic counts against the plan's limits is not published.

## Runs by Task Type

<!-- generated: run-summary (python -I _tools/sync_docs.py; do not edit by hand) -->
74 runs in [agent-runs.csv](agent-runs.csv). Averages by agent and phase; each measure averages only the runs that have it (— where none do).

**Document review** (12 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Feasibility Lead | pre-ICM | 2 | 41,283 | — | 60 s |
| Player Psychologist | pre-ICM | 2 | 39,914 | — | 52 s |
| Business Analyst | pre-ICM | 2 | 41,925 | — | 65 s |
| Adversarial QA | pre-ICM | 2 | 42,352 | — | 66 s |
| Systems Designer | pre-ICM | 2 | 42,907 | — | 75 s |
| Narrative Critic | pre-ICM | 2 | 41,284 | — | 62 s |
| **All** | | **12** | **41,611** | **—** | 64 s |

**Cross-examination** (12 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Player Psychologist | pre-ICM | 2 | 58,083 | — | 99 s |
| Adversarial QA | pre-ICM | 2 | 59,346 | — | 104 s |
| Narrative Critic | pre-ICM | 2 | 60,276 | — | 113 s |
| Systems Designer | pre-ICM | 2 | 58,271 | — | 104 s |
| Business Analyst | pre-ICM | 2 | 60,280 | — | 112 s |
| Feasibility Lead | pre-ICM | 2 | 64,264 | — | 128 s |
| **All** | | **12** | **60,086** | **—** | 110 s |

**Documentation research** (1 run)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Claude Pro usage-limits lookup | pre-ICM | 1 | 46,966 | — | 49 s |

**Feature design** (2 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Gerard | pre-ICM | 2 | 71,674 | — | 162 s |

**Balance analysis** (5 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Terry | pre-ICM | 5 | 126,566 | — | 840 s |

**Content generation** (26 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| William | post-ICM | 10 | — | 227,460 | 172 s |
| Clara | post-ICM | 5 | — | 111,377 | 151 s |
| Critic | post-ICM | 9 | — | 126,059 | 185 s |
| Ruth | post-ICM | 2 | — | 266,270 | 116 s |
| **All** | | **26** | **—** | **173,021** | 168 s |

**Doc audits** (1 run)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Doris | post-ICM | 1 | 102,299 | 493,700 | 284 s |

**Probes** (2 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| William, one empty turn ("reply OK", no tools) | post-ICM | 1 | — | 12,242 | — |
| Clara, one empty turn, prompt on stdin | post-ICM | 1 | — | 13,370 | — |
| **All** | | **2** | **—** | **12,806** | — |

**Subagent runs** (12 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Patricia (programmer) | post-ICM | 2 | 55,456 | 596,738 | 488 s |
| Bob (builder) | post-ICM | 2 | 33,148 | 186,456 | 71 s |
| Quinn (qa-build-engineer) | post-ICM | 2 | 77,778 | 1,570,326 | 668 s |
| claude-code-guide | post-ICM | 2 | 48,226 | 255,200 | 52 s |
| Martin (hiring-manager) | post-ICM | 4 | 40,258 | 222,278 | 61 s |
| **All** | | **12** | **49,187** | **508,879** | 234 s |

**Orchestrator** (1 run)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Orchestrator (main session) | post-ICM | 1 | — | 156,517,949 | 259,517 s |
<!-- /generated: run-summary -->

Notes on the Content generation runs:
- **Rows before `biome-intros`** were logged by hand; from `biome-intros` on, `generate.py` and `critic_check.py` append them.
- **William's 720,124-token `bee-journal-real` call** is research, not writing: 34 turns of WebSearch and WebFetch. It is why research moved to Ruth; leave it out of William's writing average.
- **Ruth's Haiku brief** (339,442 tokens) overclaimed and ignored the template; she is back on Sonnet (see [team.md](team.md), Model reviews).
- **Critic checks** (`_tools/critic_check.py` on `_tools/fixtures/onboarding-bad.md`, 3 known errors): the first (153,734) missed the false bloom fact; the second (72,423) missed the "cheapest" upgrade. Each caught 2 of 3; Clara's Lore check was then extended to game facts in tables and notes.
- **Before 2026-11-01** (rows down to the regression run), Clara read the whole blackboard herself and later rounds copied the full draft; afterwards she gets only her slice, and later rounds a diff.

A full design review (Round 1 + Round 2, 12 agent runs) used about 586k subagent tokens the first time and 634k the second. The orchestrator's synthesis is not included.

The Orchestrator row is the main session's whole cost. On 2026-11-03 it stood at about 156.5M tokens processed over 421 calls, 154.4M of them cache reads, against about 11.1M for every post-ICM agent run in the log combined (6.1M Agent-tool subagents, 5.0M headless content, audit and probe runs): the orchestrator is the largest cost by far, so it is logged and counted in every calibration.

## Daily Budget

All agents draw from one shared daily pool (no per-agent caps). The developer is on the Claude Pro plan, which has a rolling 5-hour limit and a weekly limit shared across Claude and Claude Code, including subagents. Anthropic does not publish a token count for these limits, so the absolute budget is calibrated:
1. Run a known task (e.g., one design-review round, about 250k tokens). The status line saves the weekly and 5-hour usage percentage before and after it (or note them from `/usage` where the status line does not run).
2. Tokens per 1% of the weekly limit = tokens used (subagents and orchestrator) ÷ percentage change. `python -I _tools/runlog.py --calibrate SINCE [UNTIL]` works it out from the log, with and without the orchestrator's cache reads.
3. **Daily budget** = 14.3% of the weekly limit (1/7) × tokens per 1%.

**Usage by day (subagent tokens; the main session is not included: it is logged from 2026-11-03, as the Orchestrator row).** Mostly *total processed* tokens, while the ~2.0M/day budget was calibrated with *final context* figures, so the comparison overstates usage; read it as an upper bound.

| Day | Tokens | Against ~2.0M/day | What |
|---|---|---|---|
| 2026-10-31 | ~1,108,000 | within | onboarding runs v1 and v2, "honey money" revision, regression fixture, Martin hiring Clara |
| 2026-11-01 | ~3,550,000 total processed, including the second `bee-journal-real` revision (1.17M) | over on paper; likely within the budget in its own measure | biome intros, both Journals, the Haiku research brief, two critic checks, Martin hiring Ruth, probes. The designer approved borrowing the next day's tokens while inside the 5-hour window, to meet a deadline |

**First calibration (2026-10-26, Terry's native-species run):**

| Measure | Before | After | Change |
|---|---|---|---|
| Weekly usage | 11% | 12% | 1% |
| Session (5 h) usage | 65% | 70% | 5% |
| Subagent tokens | | | 138,229 |

| Result | Value |
|---|---|
| Tokens per 1% of the weekly limit | ~138,000 |
| Weekly limit (estimate) | ~13.8M tokens |
| **Daily budget** | **~2.0M tokens/day** (14.3 × 138k) |
| Tokens per 1% of the 5-hour session | ~28,000 (so one session ≈ 2.8M tokens) |

In practice, a day's budget covers about 15 Terry runs, 28 Gerard runs, or 3 full design reviews (~600k each). The figure is provisional: `/usage` only shows whole percentages, so a 1% change could really be anywhere from about 0.5% to 1.5%, which puts the daily budget between roughly 1.3M and 4M tokens. A second reading (Terry's progression-levers run, 130,520 tokens) was taken mid-run and overlapped other sessions, so it only confirms the range: weekly went 12% → 14% (mid-run) → 15%, and the session window rose 3% for the tail of the run (~28k tokens per 1%, matching the first calibration). Refine it by measuring again on larger tasks (e.g., a full design review), which move the weekly bar by several points.

## Per-Task Estimates for the Agents

| Agent | Basis | Tokens per task | Runtime per task |
|---|---|---|---|
| Gerard, the Gameplay Architect | Measured, pre-ICM (average of 2 runs; 59.8k–83.5k) | 71,674 | ~3 min |
| Terry, the Progression Tree Expert | Measured, pre-ICM (average of 5 runs; range 54.5k–174k) | 126,566 | ~14 min |
| Connie, the Compliance Officer | Not yet run. Estimated from the document-review average (similar task: read the GDD, write findings) | ~42,000 | ~1 min |
| William, the Writer | Measured, post-ICM, Sonnet: first drafts average 125,847 (4 runs, 90k–178k); edit rounds 115,075 (3 runs, 67k–170k; 67k with diff-only rounds). Excludes his 720k research call | ~120,000 | ~2 min |
| Clara, the Content Critic | Measured, post-ICM, Sonnet: 12 checks averaging 118,401 (71k–170k), including the two critic checks | ~118,000 | ~3 min |
| Ruth, the Research Assistant | Measured once, post-ICM, on Haiku: 339,442 tokens, 18 turns (her full 6 + 12 call budget, each turn re-reading the fetched pages). Now on Sonnet; re-measure | ~340,000 | ~2 min |
| Bob, the Builder | No similar run | TBD | TBD |
| Patricia, the Programmer | No similar run | TBD | TBD |
| Andrew, the Audiophile | No similar run | TBD | TBD |
| Martin, the Hiring Manager | Measured, post-ICM, Haiku: average of 2 runs (39k, 47k) | ~43,000 | ~1.5 min |
| Quinn, the QA & Build Engineer | No similar run | TBD | TBD |
| Doris, the Doc Auditor | Measured once, post-ICM, Sonnet: 493,700 total processed, 102,299 final context, 10 turns, auditing two days of changes (58 files, 3,138 diff lines). A single day's diff should cost less | ~490,000 total | ~5 min |

Measures differ by row: Gerard, Terry, Connie and Martin are *final context*; William, Clara and Ruth are *total processed* (see Measures). Do not compare across the two. All estimates above come from pre-ICM runs; replace them with post-ICM averages once each agent has run under its contract. All runs above used Opus. The roster in [team.md](team.md) assigns smaller models to lighter agents, so re-measure those agents' costs once they run on Sonnet or Haiku.

Connie also checks official sources on the web. The documentation-research run (about 47k tokens) suggests a compliance review with web checks may need closer to 90k tokens. Update Connie's row after her first run.
