# Agent Run Log & Token Estimates

These are the subagent runs from the design-review sessions (2026-10-14 to 2026-10-26). For each run, the harness reported tokens, tool calls and duration. Tokens are what the subagent itself processed, including any cached context. They exclude the orchestrating main session, and they may not map one-to-one onto Claude Pro plan usage (see the calibration step in `GDD.md`, Token Budgets).

## Runs by Task Type

### Document review: read one document, write 3–5 findings
| Run | Tokens | Tool calls | Duration |
|---|---|---|---|
| Review 1: Feasibility Lead | 37,139 | 3 | 40 s |
| Review 1: Player Psychologist | 37,707 | 3 | 44 s |
| Review 1: Business Analyst | 37,973 | 3 | 47 s |
| Review 1: Adversarial QA | 37,999 | 3 | 46 s |
| Review 1: Systems Designer | 38,144 | 3 | 48 s |
| Review 1: Narrative Critic | 41,948 | 5 | 81 s |
| Review 2: Narrative Critic | 40,619 | 3 | 44 s |
| Review 2: Player Psychologist | 42,122 | 3 | 59 s |
| Review 2: Feasibility Lead | 45,427 | 5 | 81 s |
| Review 2: Business Analyst | 45,877 | 5 | 83 s |
| Review 2: Adversarial QA | 46,705 | 4 | 87 s |
| Review 2: Systems Designer | 47,670 | 5 | 102 s |
| **Average (12 runs)** | **41,611** | | **64 s** |

### Cross-examination: read 6–7 documents, append a response
| Run | Tokens | Tool calls | Duration |
|---|---|---|---|
| Review 1: Player Psychologist | 56,853 | 7 | 94 s |
| Review 1: Adversarial QA | 57,907 | 9 | 99 s |
| Review 1: Narrative Critic | 58,453 | 7 | 103 s |
| Review 1: Systems Designer | 59,667 | 7 | 114 s |
| Review 1: Business Analyst | 59,926 | 10 | 113 s |
| Review 1: Feasibility Lead | 62,688 | 10 | 108 s |
| Review 2: Systems Designer | 56,875 | 9 | 93 s |
| Review 2: Player Psychologist | 59,313 | 8 | 104 s |
| Review 2: Business Analyst | 60,634 | 7 | 112 s |
| Review 2: Adversarial QA | 60,784 | 9 | 109 s |
| Review 2: Narrative Critic | 62,098 | 9 | 123 s |
| Review 2: Feasibility Lead | 65,839 | 11 | 147 s |
| **Average (12 runs)** | **60,086** | | **110 s** |

### Documentation research: look up official docs on the web, report with sources
| Run | Tokens | Tool calls | Duration |
|---|---|---|---|
| Claude Pro usage-limits lookup | 46,966 | 10 | 49 s |

### Feature design: read the GDD and inputs, write a design proposal
| Run | Tokens | Tool calls | Duration |
|---|---|---|---|
| Gerard: capstone Refinery concept | 59,822 | 5 | 130 s |
| Gerard: native species effects | 83,525 | 6 | 195 s |
| **Average (2 runs)** | **71,674** | | **163 s** |

### Balance analysis: model progression math, write a report
| Run | Tokens | Tool calls | Duration |
|---|---|---|---|
| Terry: Royal Crystal boost + starting hives | 54,527 | 6 | 157 s |
| Terry: Refinery parameters | 135,513 | 13 | 655 s |
| Terry: Refinery rebalance (4 designer decisions) | 174,042 | 25 | 2,585 s |
| **Average (3 runs)** | **121,361** | | **1,132 s** |

A full design review (Round 1 + Round 2, 12 agent runs) used about 586k subagent tokens the first time and 634k the second. The orchestrator's synthesis is not included.

## Per-Task Estimates for the GDD Agents

| Agent | Basis | Tokens per task | Runtime per task |
|---|---|---|---|
| Gerard, the Gameplay Architect | Measured (average of 2 runs; 59.8k–83.5k) | 71,674 | ~3 min |
| Terry, the Progression Tree Expert | Measured (average of 3 runs; range 54.5k–174k) | 121,361 | ~19 min |
| Connie, the Compliance Officer | Not yet run. Estimated from the document-review average (similar task: read the GDD, write findings) | ~42,000 | ~1 min |
| William, the Writer | Not yet run. Estimated from Gerard's feature-design runs (similar task: write a design document from the GDD) | ~72,000 | ~3 min |
| Bob, the Builder | No similar run | TBD | TBD |
| Patricia, the Programmer | No similar run | TBD | TBD |
| Andrew, the Audiophile | No similar run | TBD | TBD |
| Martin, the Hiring Manager | No similar run (Connie's definition was written by the main session, not by an agent run) | TBD | TBD |
| Quinn, the QA & Build Engineer | No similar run | TBD | TBD |

All runs above used Opus. The GDD (AI Architecture, Suggested model per agent) assigns smaller models to lighter agents, so re-measure those agents' costs once they run on Sonnet or Haiku.

Connie also checks official sources on the web. The documentation-research run (about 47k tokens) suggests a compliance review with web checks may need closer to 90k tokens. Update Connie's row after her first run.
