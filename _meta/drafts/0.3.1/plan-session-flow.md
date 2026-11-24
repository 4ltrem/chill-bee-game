---
author: orchestrator
type: plan
status: draft
description: Retire Oscar as the main session; the Opus main session controls its own flow (Session flow rules in AGENTS.md, a /next skill, a context guard hook that warns at 50%)
---
# Plan: session flow on Opus, Oscar retired

## 1. Goal and done

**Story.** As the designer, I want my Opus main session to keep its own flow (one job at a time, the next job picked from where work stands, a nudge to hand off before the context gets heavy) so that I stop switching between an operator session and an Opus one.

**Why (evidence, 2026-11-23).** Oscar stopped at the first real task in every 11/21 session that ran him: `cf1cdb1b` ("Opus session only: these change loop scripts"), `e8567c58` (the merge was synthesis), `f5b02912` (a designer stop, then about 8 stop-hook turns). `operator/escalate.md` hands loop changes, synthesis and trade-offs to Opus, which is most of the designer's work, and each hand-off meant a new session. The cost the operator was built against (`operator/CONTEXT.md` "Why it exists": 98% of Opus tokens were cache re-reads of a growing context) comes from session length, which the context guard addresses directly. Designer's quiz answers 2026-11-23: "Opus main + flow rules", "Warn at 50%".

**Acceptance criteria**
1. A hook warns the main session once when its context passes 50% of the window: finish the current step, rewrite the handoff (`_meta/memory/session-handoff.md`), and tell the designer to `/clear`. It warns again once past 75%. It never fires in a subagent or a headless `claude -p` run, and it never blocks or breaks a session (always exit 0).
2. The hook is wired in `.claude/settings.json` for `PostToolUse` and `UserPromptSubmit`.
3. `/next` (`.claude/skills/next/SKILL.md`) runs `python -I _tools/status.py`, reads the handoff's **NEXT** list, and offers the top two or three jobs in AskUserQuestion, each with its owner (from the `AGENTS.md` route table) and the stop it ends at. It starts nothing until the designer picks.
4. `AGENTS.md` has a short **Session flow** section holding Oscar's good rules: one job per session, wait on notices not turns, scripts to Rex and admin to a cheap subagent, replies of at most 150 words, the handoff is rewritten when a job ends, and the context warning is obeyed.
5. Oscar is retired: no `.claude/agents/operator.md`, no Oscar roster row (a line under the roster records the retirement and why), no operator route in `AGENTS.md`. The `operator/` files say "Retired 2026-11-23" at the top and stay as history, and queue.md's open jobs move to the handoff's **Still open** list. The "orchestrator or the operator" wording elsewhere becomes "the main session".
6. `python -I _tools/consistency.py`, `python -I _tools/links.py` and `python -I _tools/test_generate.py` pass.

## 2. Read first

| File | Lines | Why |
|---|---|---|
| `_tools/log_session.py` | 1-82 | The hook to copy: reads stdin JSON (`transcript_path`, `agent_id`), skips `CHILLBEE_HEADLESS`, has a `--transcript` hand-test flag, never breaks the session (try/except, exit 0) |
| `_tools/runlog.py` | 36, 101-128 | `calls(transcript)` gives (timestamp, usage) per API call; context in use = the last call's `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` |
| `.claude/settings.json` | whole (65 lines) | Where hooks are wired; copy the `Stop` entry's shape |
| `_tools/test_generate.py` | 940-967, 568-590 | Test patterns for hooks (`budget_guard`, the status line) with temp folders |
| `.claude/skills/status/SKILL.md` | whole | The shortest skill to copy for `/next` |
| `_tools/status.py` | 1-12, 89-96 | What `/next` shows; `stops()` already reads the handoff |
| `_meta/memory/session-handoff.md` | **NEXT** section | The list `/next` reads (numbered items; hand-written) |
| `AGENTS.md` | 32, 50, 54 | The operator rows to replace; the Session flow section goes after "The one rule" |
| `operator/CONTEXT.md` | 27-63 | The rules worth keeping (Process steps 3-7, Hard limits); everything else is retired |
| `_meta/team.md` | 26, 47, 49, 81 | Oscar's roster row, Rex's "orchestrator or the operator", Oscar's role paragraph, Oscar's model-review row |
| `_tools/consistency.py` | 8-15, 47-60 | Checks every agent definition has a roster row with the same model and an `AGENTS.md` route, and every roster row links to an existing definition |
| `.claude/agents/script-runner.md` | 21 | "dispatched by a main session (the orchestrator or the operator)" |
| `_tools/guard_shell.py` | 26-29, 141, 236 | Docstrings naming the operator as writer of `quinn-probes.allow`; the behaviour stays |
| `README.md` | 73 | The `operator/` row |
| `operator/queue.md` | whole | Open jobs #1-4 and #11 to move |
| `_meta/learnings.md` | 1-12 | Entry format; the next entry is L55 at the top |

Hook output (verify before Task A, see Pitfalls): `PostToolUse` and `UserPromptSubmit` hooks add text to the model's context by printing JSON `{"hookSpecificOutput": {"hookEventName": "<event>", "additionalContext": "<text>"}}` to stdout with exit 0.

## 3. Tasks

| # | Task | Files (owned) | Copy from | Pitfalls | Proving command |
|---|---|---|---|---|---|
| A | New hook `context_guard.py`: read stdin JSON (or `--transcript PATH` for a hand test); skip when `agent_id` is set or `CHILLBEE_HEADLESS` is in the environment; context = the last call's three input counts from `runlog.calls()`; `--window` (default 200000) and `--at 50,75`; warn once per threshold per session, remembering what was warned in `_meta/usage/context-guard.json` keyed by `session_id` (gitignored folder); print the `additionalContext` JSON with `hookEventName` from the input; the text: "Context is at N% of the window. Finish the current step, rewrite `_meta/memory/session-handoff.md` to the current state, and tell the designer to run /clear." Expose `context_used(transcript)` and `decide(used, window, warned, at)` for tests. Standard library only. | `_tools/context_guard.py` (new) | `_tools/log_session.py` 1-82 (shape, guards, exit 0); `runlog.calls` | Never exit non-zero (a hook must never break the session); no inline Python; the guard_shell hook refuses writes outside the repo, so the state file stays under `_meta/usage/` | `python -I _tools/context_guard.py --transcript <any main transcript> --window 200000` prints a warning or nothing, exit 0 |
| B | Test `test_context_guard_warns_once_per_threshold`: `decide()` at 40% → none; 55% → 50; 55% again with 50 warned → none; 80% with 50 warned → 75; a fake transcript of two assistant lines gives `context_used` from the last one; `main()` with `agent_id` in stdin prints nothing. Plus `test_settings_wire_the_context_guard`: `.claude/settings.json` has `context_guard.py` under both `PostToolUse` and `UserPromptSubmit`. | `_tools/test_generate.py` (append two tests) | lines 940-967 | Import by module name as the other tests do; temp folders only | `python -I _tools/test_generate.py` (both new tests fail until A and C land) |
| C | Wire the hook: add `PostToolUse` (matcher `*`) and `UserPromptSubmit` entries running `python -I "$CLAUDE_PROJECT_DIR/_tools/context_guard.py" --window <W>`, timeout 10. | `.claude/settings.json` | the `Stop` entry | `<W>` is the window the lead confirmed (Pitfalls); keep the JSON valid | `python -I _tools/test_generate.py` (the settings test) |
| D | New skill `/next`: frontmatter name `next`, description with triggers ("next", "what's next", "what should we do"); body: run `python -I _tools/status.py`, show it in a code block; read only the handoff's **NEXT** and **Still open** sections; offer the top two or three jobs in AskUserQuestion, each labelled with its owner from the `AGENTS.md` route table and the stop it ends at; start nothing until picked; a picked job is this session's one job. | `.claude/skills/next/SKILL.md` (new) | `.claude/skills/status/SKILL.md` | Do not read the whole handoff into replies; no decisions on the designer's behalf | manual: `/next` in a fresh session (Proof) |
| E | `AGENTS.md`: replace row 54 (operator route) with a `/next` row ("asked what's next, or a session starts" → the `next` skill → the designer's pick); row 50 "(the orchestrator or the operator)" → "(the main session)"; row 32 (`operator/`) → "the retired operator's contract and stops (history; retired 2026-11-23, see L55)"; add a **Session flow** section (at most 8 bullets) after "The one rule" with criterion 4's rules. | `AGENTS.md` | `operator/CONTEXT.md` 27-63 | Edit lines only; `consistency.py` needs a route for every agent definition, so this task and F land in the same checkpoint | `python -I _tools/consistency.py` |
| F | Retire Oscar's definition and roster row: delete `.claude/agents/operator.md`; in `_meta/team.md` delete the Oscar roster row (26) and model-review row (81), replace the role paragraph (49) with one line "Oscar, the Operator (retired 2026-11-23): the main session keeps its own flow (AGENTS.md, Session flow; L55)", and line 47 "the orchestrator or the operator" → "the main session"; `script-runner.md` line 21 likewise. Owner: Martin (agent definitions and the roster are his). | `.claude/agents/operator.md` (delete), `_meta/team.md`, `.claude/agents/script-runner.md` | - | A stated agent count must still match (`consistency.py` check 15) | `python -I _tools/consistency.py` |
| G | `operator/CONTEXT.md`, `escalate.md`, `queue.md`: one line under each title "Retired 2026-11-23: the Opus main session keeps its own flow (AGENTS.md, Session flow; `_meta/learnings.md` L55). Kept as history." `README.md` row 73 likewise. | `operator/CONTEXT.md`, `operator/escalate.md`, `operator/queue.md`, `README.md` | - | Links must still resolve | `python -I _tools/links.py` |
| H | `guard_shell.py` docstrings 26-29, 141, 236: "the operator" → "the main session". No logic change. | `_tools/guard_shell.py` | - | The pre-commit gate compiles every `_tools/*.py` | `python -I _tools/test_generate.py` |
| L | Lead only: `_meta/learnings.md` L55 (What broke: Oscar stopped at the first task in 3 of 3 sessions; How noticed: the designer kept switching to Opus; Cause: escalate.md hands most work to Opus, and each hand-off is a new session; How fixed: retired, flow rules and the context guard on the Opus main session; Prevention: `test_context_guard_warns_once_per_threshold`, the Session flow section). Move queue.md's open jobs (#1-4, #11) into the handoff's **Still open** (the lead checks each is still true first: #1's branches were deleted on 11/21, D248). | `_meta/learnings.md`, `_meta/memory/session-handoff.md` | L54's format | - | `python -I _tools/links.py` |

Parallel: A, B and C in checkpoint 1 (B is written against the interface above, so it need not wait). D, E, F, G and H in checkpoint 2, all at once. L is the lead's, after checkpoint 2.

## 4. Checkpoints

| Checkpoint | Tasks | Check (expected) |
|---|---|---|
| C1 Context guard | A, B, C | `python -I _tools/test_generate.py` all pass, both new tests included; the hand test prints valid JSON or nothing, exit 0 |
| C2 Flow and retirement | D, E, F, G, H, then L | `python -I _tools/consistency.py` "docs agree with code and config"; `python -I _tools/links.py` 0 broken; `python -I _tools/test_generate.py` all pass |

## 5. How to run it

- The lead (the Opus main session) reads this whole plan, then writes no code; it runs the checks, commits and fills in **Progress**.
- Before C1, the lead confirms two facts and writes them into Progress: (a) the hook output schema in section 2, from the Claude Code docs (ask the `claude-code-guide` agent); (b) the context window of the main session's model (`/context` shows it), used as `--window`.
- At each checkpoint, launch every task of the checkpoint as a subagent in one message: A, B, C, D, E, G, H to general-purpose subagents (model sonnet; C, G, H may go to haiku); F to Martin (`hiring-manager`). Each brief names the task's row, its files only, the rule "change only the needed lines", a reply of at most 150 words with the files changed and the proving command's result, and "do not run git".
- The lead checks the actual files (diff), not the replies; mismatches go back to the owner or are fixed by the lead.
- Commits: on `main`, through the pre-commit gate, never `--no-verify`, staging the task files by path. One commit per checkpoint, message "Session flow C<n>: …".
- Anything unplanned is written into this plan before anyone builds it. Something that breaks gets an L-number after L55.
- If the context passes half after a checkpoint, write the next checkpoint into Progress and stop for a fresh session (the new hook will say so too).

## 6. Proof

| Criterion | Test | Breaking edit (one line) | Expected |
|---|---|---|---|
| 1 | `test_context_guard_warns_once_per_threshold` | in `decide()`, change the threshold test so it compares against `at * 2` | test fails (55% gives none) |
| 1 (subagents) | same test, `agent_id` case | delete the `agent_id` early return | test fails (prints a warning) |
| 2 | `test_settings_wire_the_context_guard` | remove the `UserPromptSubmit` entry's `context_guard.py` command | test fails |
| 4, 5 | `python -I _tools/consistency.py` | re-add Oscar's roster row to `_meta/team.md` | consistency fails (row links to a missing definition) |
| 5 | `python -I _tools/links.py` | none needed beyond C2's check | 0 broken |

Apply each breaking edit, confirm the failure, then revert it with the exact inverse Edit (never `git checkout` or a reset); rerun the check green.

Whole build: `python -I _tools/test_generate.py`, `python -I _tools/consistency.py`, `python -I _tools/links.py`, and the pre-commit gate on each commit.

Real entry points:
1. Start a fresh session in the repo and type `/next`: it shows the status block and an AskUserQuestion with two or three jobs from NEXT, and starts nothing.
2. In a session, confirm the hook runs without error on a tool call (no hook error line), and run the hand test on a transcript known to be past half the window: it prints the warning once; a second run prints nothing.
3. Normal use: an ordinary prompt and a Bash call in a small session show no warning.

## 7. Progress

- 2026-11-23, pre-C1 facts. (a) Hook output schema confirmed (code.claude.com/docs/en/hooks.md): `{"hookSpecificOutput": {"hookEventName": "<event>", "additionalContext": "<text>"}}` on stdout, exit 0, for both events; stdin carries `session_id`, `transcript_path`, and `agent_id` inside subagents; matcher `*` matches every tool. (b) Window: the designer picked 1M (docs: Opus 4.7+ run 1M by default), so `--window 1000000`.
- C1 done (A, B, C). Lead fixes: docstring names both events; stdin `transcript_path` is `~`-expanded. The proof found a test gap: the `agent_id` case ran at a 1M window, so 60 tokens never warned and deleting the skip still passed. The test now runs `main` with `--window 100`, checks that a main-session prompt warns once with its `hookEventName`, and checks that a subagent gets nothing. All three C1 proofs fail when broken and pass when reverted. Hand test: an old transcript at `--window 100000` warns once, then prints nothing, exit 0. `test_generate.py` 100 OK.
