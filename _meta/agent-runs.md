# Agent Run Log & Token Estimates

These are the subagent runs from the design-review sessions (2026-10-14 to 2026-10-26). For each run, the harness reported tokens, tool calls and duration. Tokens are what the subagent itself processed, including any cached context. They exclude the orchestrating main session, and they may not map one-to-one onto Claude Pro plan usage (see the calibration under Daily Budget below).

**Phase.** Every run is tagged `pre-ICM` or `post-ICM`. All runs logged so far happened before the repository was restructured into an ICM workspace (commit `4af8e88`, 2026-10-26), when agents were briefed by ad-hoc prompts and read the whole GDD. Every run logged after that is `post-ICM`: agents follow their `.claude/agents/` definition and their shelf's `CONTEXT.md`, and load only the GDD sections a task touches. Keep the two apart when averaging, so the restructure's effect on token cost shows.

**Measures.** Two token counts appear in this log, and they differ several-fold for the same run:
- *Final context*: the size of the conversation at an agent's last call. The Agent tool reports this, so every pre-ICM row and every row in the Subagent runs table uses it.
- *Total processed*: the sum over all of an agent's calls. Each call re-sends the conversation, mostly as cheap cache reads, so this grows with the number of turns. `generate.py` and `critic_check.py` log this, because the CLI reports it.
Martin's run hiring Clara was 39,232 final context but 234,632 total processed. Compare rows only within one measure. Which one Anthropic counts against the plan's limits is not published.

## Runs by Task Type

### Document review: read one document, write 3–5 findings
| Run | Phase | Tokens | Tool calls | Duration |
|---|---|---|---|---|
| Review 1: Feasibility Lead | pre-ICM | 37,139 | 3 | 40 s |
| Review 1: Player Psychologist | pre-ICM | 37,707 | 3 | 44 s |
| Review 1: Business Analyst | pre-ICM | 37,973 | 3 | 47 s |
| Review 1: Adversarial QA | pre-ICM | 37,999 | 3 | 46 s |
| Review 1: Systems Designer | pre-ICM | 38,144 | 3 | 48 s |
| Review 1: Narrative Critic | pre-ICM | 41,948 | 5 | 81 s |
| Review 2: Narrative Critic | pre-ICM | 40,619 | 3 | 44 s |
| Review 2: Player Psychologist | pre-ICM | 42,122 | 3 | 59 s |
| Review 2: Feasibility Lead | pre-ICM | 45,427 | 5 | 81 s |
| Review 2: Business Analyst | pre-ICM | 45,877 | 5 | 83 s |
| Review 2: Adversarial QA | pre-ICM | 46,705 | 4 | 87 s |
| Review 2: Systems Designer | pre-ICM | 47,670 | 5 | 102 s |
| **Average (12 runs)** | | **41,611** | | **64 s** |

### Cross-examination: read 6–7 documents, append a response
| Run | Phase | Tokens | Tool calls | Duration |
|---|---|---|---|---|
| Review 1: Player Psychologist | pre-ICM | 56,853 | 7 | 94 s |
| Review 1: Adversarial QA | pre-ICM | 57,907 | 9 | 99 s |
| Review 1: Narrative Critic | pre-ICM | 58,453 | 7 | 103 s |
| Review 1: Systems Designer | pre-ICM | 59,667 | 7 | 114 s |
| Review 1: Business Analyst | pre-ICM | 59,926 | 10 | 113 s |
| Review 1: Feasibility Lead | pre-ICM | 62,688 | 10 | 108 s |
| Review 2: Systems Designer | pre-ICM | 56,875 | 9 | 93 s |
| Review 2: Player Psychologist | pre-ICM | 59,313 | 8 | 104 s |
| Review 2: Business Analyst | pre-ICM | 60,634 | 7 | 112 s |
| Review 2: Adversarial QA | pre-ICM | 60,784 | 9 | 109 s |
| Review 2: Narrative Critic | pre-ICM | 62,098 | 9 | 123 s |
| Review 2: Feasibility Lead | pre-ICM | 65,839 | 11 | 147 s |
| **Average (12 runs)** | | **60,086** | | **110 s** |

### Documentation research: look up official docs on the web, report with sources
| Run | Phase | Tokens | Tool calls | Duration |
|---|---|---|---|---|
| Claude Pro usage-limits lookup | pre-ICM | 46,966 | 10 | 49 s |

### Feature design: read the GDD and inputs, write a design proposal
| Run | Phase | Tokens | Tool calls | Duration |
|---|---|---|---|---|
| Gerard: capstone Refinery concept | pre-ICM | 59,822 | 5 | 130 s |
| Gerard: native species effects | pre-ICM | 83,525 | 6 | 195 s |
| **Average (2 runs)** | | **71,674** | | **163 s** |

### Balance analysis: model progression math, write a report
| Run | Phase | Tokens | Tool calls | Duration |
|---|---|---|---|---|
| Terry: Royal Crystal boost + starting hives | pre-ICM | 54,527 | 6 | 157 s |
| Terry: Refinery parameters | pre-ICM | 135,513 | 13 | 655 s |
| Terry: Refinery rebalance (4 designer decisions) | pre-ICM | 174,042 | 25 | 2,585 s |
| Terry: native species balance | pre-ICM | 138,229 | 13 | 448 s |
| Terry: species check + progression levers | pre-ICM | 130,520 | 16 | 357 s |
| **Average (5 runs)** | | **126,566** | | **840 s** |

### Content generation: write or check player-facing text (`_tools/generate.py`)
Measures: **total processed**, and from 2026-11-01 evening also **final context** (— for earlier rows, whose transcripts were not kept). Turns are the CLI's `num_turns`, not tool calls.
| Run | Phase | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|---|
| William: onboarding script, round 1 (Sonnet) | post-ICM | 144,063 | — | 9 | 183 s |
| Clara: onboarding script, round 1 (Sonnet) | post-ICM | 83,580 | — | 4 | 137 s |
| William: onboarding script v2, round 1 (Sonnet) | post-ICM | 90,439 | — | 6 | 161 s |
| Clara: onboarding script v2, round 1, five checks + evidence (Sonnet) | post-ICM | 130,197 | — | 5 | 221 s |
| William: onboarding script, designer notes ("honey money"), Edit only (Sonnet) | post-ICM | 107,825 | — | 7 | 35 s |
| Clara: onboarding script, re-check after notes (Sonnet) | post-ICM | 87,053 | — | 4 | 163 s |
| Clara: onboarding regression, round 1, FAIL with 3 findings (Sonnet) | post-ICM | 86,167 | — | 4 | 143 s |
| William: onboarding regression, round 2, Edit only (Sonnet) | post-ICM | 169,906 | — | 10 | 49 s |
| Clara: onboarding regression, round 2, PASS (Sonnet) | post-ICM | 169,886 | — | 6 | 93 s |
| William: biome-intros, round 1 (Sonnet) | post-ICM | 178,497 | — | 10 | 145 s |
| Critic: biome-intros, round 1 (Sonnet) | post-ICM | 122,505 | — | 5 | 189 s |
| William: bee-journal-magic, round 1 (Sonnet) | post-ICM | 90,388 | — | 6 | 118 s |
| Critic: bee-journal-magic, round 1 (Sonnet) | post-ICM | 122,567 | — | 5 | 203 s |
| William: bee-journal-magic, round 2 (Sonnet) | post-ICM | 67,494 | — | 5 | 17 s |
| Critic: bee-journal-magic, round 2 (Sonnet) | post-ICM | 71,092 | — | 4 | 33 s |
| William: bee-journal-real, round 1 (Sonnet) | post-ICM | 720,124 | — | 34 | 654 s |
| Critic: bee-journal-real, round 1 (Sonnet) | post-ICM | 158,551 | — | 12 | 237 s |
| Critic: critic check onboarding-bad, round 1 (Sonnet) | post-ICM | 153,734 | — | 6 | 193 s |
| Ruth: bee-journal-real, round 1 (Haiku) | post-ICM | 339,442 | — | 18 | 122 s |
| Critic: bee-journal-real, round 1 (Sonnet) | post-ICM | 163,058 | — | 15 | 258 s |
| Critic: critic check onboarding-bad, round 1 (Sonnet) | post-ICM | 72,423 | — | 4 | 157 s |
| William: bee-journal-real, round 1 (Sonnet) | post-ICM | 333,097 | — | 13 | 215 s |
| Critic: bee-journal-real, round 1 (Sonnet) | post-ICM | 206,029 | — | 12 | 312 s |
| Ruth: bee-journal-real, round 2 (Sonnet) | post-ICM | 193,098 | — | 11 | 109 s |
| William: bee-journal-real, round 2 (Sonnet) | post-ICM | 372,765 | — | 16 | 144 s |
| Critic: bee-journal-real, round 2 (Sonnet) | post-ICM | 64,572 | — | 7 | 84 s |

Notes on the rows above:
- **Rows before `biome-intros`** were logged by hand; from `biome-intros` on, `generate.py` and `critic_check.py` append them.
- **William's 720,124-token `bee-journal-real` call** is research, not writing: 34 turns of WebSearch and WebFetch. It is why research moved to Ruth; leave it out of William's writing average.
- **Ruth's Haiku brief** (339,442 tokens) overclaimed and ignored the template; she is back on Sonnet (see [team.md](team.md), Model reviews).
- **Critic checks** (`_tools/critic_check.py` on `_tools/fixtures/onboarding-bad.md`, 3 known errors): the first (153,734) missed the false bloom fact; the second (72,423) missed the "cheapest" upgrade. Each caught 2 of 3; Clara's Lore check was then extended to game facts in tables and notes.
- **Before 2026-11-01** (rows down to the regression run), Clara read the whole blackboard herself and later rounds copied the full draft; afterwards she gets only her slice, and later rounds a diff.

### Doc audits: check the day's changes against the docs (`_tools/doc_audit.py`)
Measures: **total processed** and **final context** (see Measures above). One row per run of Doris.
| Run | Phase | Total processed | Final context | Turns | Duration |
|---|---|---|---|---|---|
| Doris: doc audit since 902ca88 (both working days, 58 files), 1 finding (Sonnet) | post-ICM | 493,700 | 102,299 | 10 | 284 s |

### Probes: fixed costs
| Run | Phase | Tokens | Turns | What it measured |
|---|---|---|---|---|
| William, one empty turn ("reply OK", no tools) | post-ICM | 12,242 | 1 | boot cost of any `claude -p` call: system prompt, tools, AGENTS.md, the agent definition |
| Clara, one empty turn, prompt on stdin | post-ICM | 13,370 | 1 | that stdin prompts work; boot cost with a longer definition |

A full design review (Round 1 + Round 2, 12 agent runs) used about 586k subagent tokens the first time and 634k the second. The orchestrator's synthesis is not included.


### Subagent runs (Agent tool, logged by the SubagentStop hook)
Logged automatically when a subagent launched with the Agent tool finishes. *Final context* is the size of the conversation at the subagent's last call (the Agent tool's own figure, and the measure of the pre-ICM rows above); *total processed* is the sum over all its calls, the measure `generate.py` logs.
| Run | Phase | Final context | Total processed | Tool calls | Duration | Model |
|---|---|---|---|---|---|---|
| Martin (hiring-manager): Martin hires the content critic | post-ICM | 39,232 | 234,632 | 18 | 63 s | claude-haiku-5-5 |
| Martin (hiring-manager): Martin hires the research assistant | post-ICM | 47,200 | 345,056 | 26 | 93 s | claude-haiku-5-5 |
| claude-code-guide: Check SubagentStop hook input fields | post-ICM | 29,603 | 73,389 | 5 | 39 s | claude-haiku-5-5 |
| Martin (hiring-manager): Martin hires the doc auditor | post-ICM | 47,180 | 272,581 | 22 | 63 s | claude-haiku-5-5 |
| Patricia (programmer): Patricia writes Prototype 0 scripts | post-ICM | 58,600 | 656,482 | 24 | 396 s | claude-sonnet-5-5 |
| Bob (builder): Bob builds Prototype 0 scenes | post-ICM | 36,067 | 175,542 | 11 | 94 s | claude-sonnet-5-5 |
| Patricia (programmer): Patricia writes Prototype 0 scripts | post-ICM | 59,815 | 716,297 | 24 | 858 s | claude-sonnet-5-5 |
| Quinn (qa-build-engineer): Quinn tests and builds Prototype 0 | post-ICM | 74,194 | 1,158,136 | 27 | 529 s | claude-sonnet-5-5 |

## Daily Budget

All agents draw from one shared daily pool (no per-agent caps). The developer is on the Claude Pro plan, which has a rolling 5-hour limit and a weekly limit shared across Claude and Claude Code, including subagents. Anthropic does not publish a token count for these limits, so the absolute budget is calibrated:
1. Run a known task (e.g., one design-review round, about 250k tokens) and note the weekly usage percentage in `/usage` before and after.
2. Tokens per 1% of the weekly limit = tokens used ÷ percentage change.
3. **Daily budget** = 14.3% of the weekly limit (1/7) × tokens per 1%.

**Usage by day (subagent tokens; the main session is not included).** Mostly *total processed* tokens, while the ~2.0M/day budget was calibrated with *final context* figures, so the comparison overstates usage; read it as an upper bound.

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
