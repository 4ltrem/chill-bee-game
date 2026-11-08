# Agent Run Log & Token Estimates

Every agent run is one row of [agent-runs.csv](agent-runs.csv): the design-review runs from 2026-10-14 to 2026-10-26, logged by hand, and every run since. The SubagentStop hook (`_tools/log_subagent.py`) logs Agent-tool subagents, `generate.py`, `critic_check.py` and `doc_audit.py` log their headless calls, and the Stop hook (`_tools/log_session.py`) logs the orchestrating main session itself, one *Orchestrator* row per session. Each row since 2026-11-03 also carries the orchestrator's tokens over the run (input, cache write, cache read, output) and plan usage % before and after it, saved by the status line (`_tools/statusline.py`). Column meanings are in `_tools/runlog.py`. Nobody needs to read the CSV whole: the summary below is generated from it.

**Phase.** Every run is tagged `pre-ICM` or `post-ICM`. The design-review runs (2026-10-14 to 2026-10-26) happened before the repository was restructured into an ICM workspace (commit `4af8e88`, 2026-10-26), when agents were briefed by ad-hoc prompts and read the whole GDD. Every run logged after that is `post-ICM`: agents follow their `.claude/agents/` definition and their shelf's `CONTEXT.md`, and load only the GDD sections a task touches. Keep the two apart when averaging, so the restructure's effect on token cost shows.

**Measures.** Two token counts appear in this log, and they differ several-fold for the same run:
- *Final context*: the size of the conversation at an agent's last call. The Agent tool reports this, so every pre-ICM run and every Subagent run has it.
- *Total processed*: the sum over all of an agent's calls. Each call re-sends the conversation, mostly as cheap cache reads, so this grows with the number of turns. `generate.py`, `critic_check.py` and the hooks log it.
Martin's run hiring Clara was 39,232 final context but 234,632 total processed. Compare rows only within one measure. Which one Anthropic counts against the plan's limits is not published.

## Runs by Task Type

<!-- generated: run-summary (python -I _tools/sync_docs.py; do not edit by hand) -->
250 runs in [agent-runs.csv](agent-runs.csv). Averages by agent and phase; each measure averages only the runs that have it (— where none do).

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

**Content generation** (45 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| William | post-ICM | 18 | 20,671 | 157,931 | 107 s |
| Clara | post-ICM | 5 | — | 111,377 | 151 s |
| Critic | post-ICM | 20 | 26,078 | 84,268 | 95 s |
| Ruth | post-ICM | 2 | — | 266,270 | 116 s |
| **All** | | **45** | **23,802** | **124,835** | 107 s |

**Doc audits** (8 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Doris | post-ICM | 8 | 46,966 | 221,240 | 52 s |

**Probes** (2 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| William, one empty turn ("reply OK", no tools) | post-ICM | 1 | — | 12,242 | — |
| Clara, one empty turn, prompt on stdin | post-ICM | 1 | — | 13,370 | — |
| **All** | | **2** | **—** | **12,806** | — |

**Subagent runs** (97 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Patricia (programmer) | post-ICM | 19 | 75,587 | 2,018,299 | 1,407 s |
| Bob (builder) | post-ICM | 28 | 60,987 | 931,359 | 317 s |
| Quinn (qa-build-engineer) | post-ICM | 24 | 106,993 | 3,665,362 | 1,373 s |
| claude-code-guide | post-ICM | 2 | 48,226 | 255,200 | 52 s |
| Martin (hiring-manager) | post-ICM | 7 | 41,916 | 283,129 | 72 s |
| Ruth (research-assistant) | post-ICM | 1 | 37,318 | 203,725 | 107 s |
| general-purpose | post-ICM | 6 | 66,898 | 515,339 | 68 s |
| Terry (progression-tree-expert) | post-ICM | 1 | 34,830 | 142,788 | 168 s |
| Milo (modeler) | post-ICM | 3 | 135,542 | 1,926,113 | 331 s |
| Rex (script-runner) | post-ICM | 6 | 20,890 | 193,306 | 617 s |
| **All** | | **97** | **73,268** | **1,703,747** | 769 s |

**Orchestrator** (21 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Orchestrator (main session) | post-ICM | 21 | — | 25,791,390 | 21,654 s |

**Style loop** (7 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Vera | post-ICM | 5 | 22,004 | 48,632 | 14 s |
| Bob | post-ICM | 2 | 28,634 | 153,404 | 28 s |
| **All** | | **7** | **23,898** | **78,567** | 18 s |

**Goal agent** (38 runs)

| Agent | Phase | Runs | Final context | Total processed | Duration |
|---|---|---|---|---|---|
| Patricia (programmer) | post-ICM | 17 | 33,068 | 227,811 | 424 s |
| Bob (builder) | post-ICM | 15 | 26,165 | 167,042 | 28 s |
| Quinn (qa-build-engineer) | post-ICM | 6 | 37,242 | 364,591 | 207 s |
| **All** | | **38** | **31,002** | **225,420** | 234 s |
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

All agents draw from one shared daily pool (no per-agent caps). The developer is on the Claude Team plan for the duration of a course (this doc said Pro until 2026-11-03), which has a rolling 5-hour limit and a weekly limit shared across Claude and Claude Code, including subagents. Anthropic does not publish a token count for these limits, so the absolute budget is calibrated:
1. Run a known task (e.g., one design-review round, about 250k tokens). The status line saves the weekly and 5-hour usage percentage before and after it (or note them from `/usage` where the status line does not run).
2. Tokens per 1% of the weekly limit = tokens used (subagents and orchestrator) ÷ percentage change. `python -I _tools/runlog.py --calibrate SINCE [UNTIL]` works it out from the log, with and without the orchestrator's cache reads.
3. **Daily budget** = 14.3% of the weekly limit (1/7) × tokens per 1%.

**Usage by day (subagent tokens; the main session is not included: it is logged from 2026-11-03, as the Orchestrator row).** Mostly *total processed* tokens, while the ~2.0M/day budget was calibrated with *final context* figures, so the comparison overstates usage; read it as an upper bound.

| Day | Tokens | Against ~2.0M/day | What |
|---|---|---|---|
| 2026-10-31 | ~1,108,000 | within | onboarding runs v1 and v2, "honey money" revision, regression fixture, Martin hiring Clara |
| 2026-11-01 | ~3,550,000 total processed, including the second `bee-journal-real` revision (1.17M) | over on paper; likely within the budget in its own measure | biome intros, both Journals, the Haiku research brief, two critic checks, Martin hiring Ruth, probes. The designer approved borrowing the next day's tokens while inside the 5-hour window, to meet a deadline |

**First calibration (2026-10-26, Terry's native-species run, Team plan):**

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

**Second calibration (2026-11-04, Prototype 0 revision 3 batch, Team plan, status-line readings):** 4 runs (Quinn tests, Patricia, Bob, Quinn report) from 00:24Z, with the orchestrator included. Command: `runlog.py --calibrate 2026-11-04T00:24:00Z`.

| Measure | Before | After | Change |
|---|---|---|---|
| Weekly usage | 28% | 31% | 3% |
| Session (5 h) usage | 63% | 84% | 21% |
| Subagent tokens (total processed) | | | 11,057,200 |
| Orchestrator tokens | | | 2,582,350 (2,527,014 of them cache reads) |

| Result | Value |
|---|---|
| Tokens per 1% of the weekly limit | ~4.5M all kinds, ~3.7M without the orchestrator's cache reads |
| Tokens per 1% of the 5-hour session | ~650k (13.6M ÷ 21) |

This is measured in *total processed* tokens, while the first calibration used *final context*, so the two are not comparable: by total processed, a weekly limit is roughly 370M–450M tokens, and a 1/7 daily share is ~53M–65M. A 3% change is still coarse (±0.5% on each reading, so about ±30%). The binding limit in practice was the 5-hour window: this one batch took 21% of it.

## Per-Task Estimates for the Agents

Figures from [agent-runs.csv](agent-runs.csv), updated 2026-11-03. *Final* is final context, *total* is total processed (see Measures); where a run logged both, both are given.

| Agent | Basis | Tokens per task | Runtime per task |
|---|---|---|---|
| Gerard, the Gameplay Architect | Measured, pre-ICM, Opus: average of 2 runs (59.8k–83.5k final). No post-ICM run yet | ~72,000 final | ~3 min |
| Terry, the Progression Tree Expert | Measured, pre-ICM, Opus: average of 5 runs (54.5k–174k final). No post-ICM run yet | ~127,000 final | ~14 min |
| Connie, the Compliance Officer | Not yet run. Estimated from the document-review average (similar task: read the GDD, write findings) | ~42,000 final | ~1 min |
| William, the Writer | Measured, post-ICM, Sonnet. Story and intro first drafts: 125,847 average (4 runs, 90k–178k). Edit rounds: 115,075 (3 runs, 67k–170k; 67k with diff-only rounds). The real Bee Journal from Ruth's brief costs about 3x: 333,097 for the draft, 372,765 for its revision. Excludes his 720k research call | ~125,000 total; ~350,000 for a real Bee Journal | ~2–3 min |
| Clara, the Content Critic | Measured, post-ICM, Sonnet: 14 checks averaging 120,815 total (64.6k–206k), including the two critic checks; the log names her "Critic" from `biome-intros` on | ~121,000 total | ~3 min |
| Ruth, the Research Assistant | Measured, post-ICM: once on Sonnet, 193,098 total in 109 s (round 2 of `bee-journal-real`); once on Haiku, 339,442 total, 18 turns, the brief that was rejected | ~195,000 total | ~2 min |
| Bob, the Builder | Measured, post-ICM, Sonnet: 2 runs (Prototype 0 scenes; revision 2 fixes), 33,148 final / 186,456 total on average (175k–197k). Each now includes rendering and reading a screenshot | ~33,000 final / ~190,000 total | ~1–1.5 min |
| Patricia, the Programmer | Measured, post-ICM, Sonnet: 2 runs, 55,456 final / 596,738 total on average. The full Prototype 0 build was 716,297 total in 14 min; the revision 2 changes 477,179 total in 2 min | ~55,000 final / ~600,000 total | ~2 min (changes) to ~14 min (a new build) |
| Andrew, the Audiophile | No run yet | TBD | TBD |
| Martin, the Hiring Manager | Measured, post-ICM, Haiku: 4 runs (3 hires, 1 gap assessment), 40,258 final / 222,278 total on average; a hire is 235k–345k total, an assessment 37k | ~40,000 final / ~280,000 total per hire | ~1–1.5 min |
| Quinn, the QA & Build Engineer | Measured, post-ICM, Sonnet: 2 runs (test, build and report; revision 2 re-test and re-export), 77,778 final / 1,570,326 total on average (1.16M–1.98M). The costliest agent per task: long Godot runs and many turns | ~78,000 final / ~1,600,000 total | ~9–13 min |
| Doris, the Doc Auditor | Measured once, post-ICM, Sonnet: 493,700 total, 102,299 final, 10 turns, auditing two days of changes (58 files, 3,138 diff lines). A single day's diff should cost less | ~490,000 total | ~5 min |
| Orchestrator (main session) | Measured from 2026-11-03 (backfilled for 10 subagent runs): the main session's own tokens while a subagent runs, 340k–8.9M total, median ~763k, almost all cache reads. Each orchestrator call re-reads its whole context (100k+), so the turns around a run often cost more than the run. Highest when the orchestrator keeps working during a long run (8.9M during Patricia's 14-minute build) | ~760,000 total per agent run (median) | — |

Measures differ by row: Gerard, Terry and Connie are *final context* only, and William, Clara and Ruth *total processed* only. Bob, Patricia, Martin, Quinn and the orchestrator have both. Compare only within one measure. Gerard's and Terry's figures are still pre-ICM and on Opus; replace them with post-ICM averages after their next runs.

Connie also checks official sources on the web. The documentation-research run (about 47k tokens) suggests a compliance review with web checks may need closer to 90k tokens. Update Connie's row after her first run.
