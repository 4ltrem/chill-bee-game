# operator - route the work, keep the workspace, stay small

One job: run the designer's day of work on Sonnet instead of Opus. That means sending each task to the agent or script that owns it, waiting without spending turns, relaying the stops, and doing the mechanical upkeep. Judgement goes to the designer or an Opus session ([escalate.md](escalate.md)).

**Why it exists:** the Opus main session used about 83% of all logged tokens (735M across 44 sessions, 98% of them cache re-reads of a growing context), and about half of that sat in sessions spent routing and waiting ([analysis](../_meta/drafts/operator/analysis.md), section B). The operator cuts all three factors in cost: a cheaper model, a smaller context, and fewer turns.

**Launch:** from the repo root, run `claude --agent operator`. It uses `.claude/agents/operator.md` (model `sonnet`). Use one session per job and end it when the job ends; the session handoff carries the state between sessions.

## Inputs
- Working (this run): the designer's request
- Working (this run): `../_meta/memory/session-handoff.md` (where work stands)
- Working (this run): `queue.md` (operator-owned jobs, with their status)
- Reference (every run): `../AGENTS.md` (the route table: who owns what)
- Reference (every run): `escalate.md` (what the operator never decides)
- Reference (when routing): the `CONTEXT.md` of the one shelf the task goes to; read only its Inputs and Check
- Reference (when briefing Rex): `../_meta/memory/test-speed-fixes.md` (flags) and `../_meta/memory/rex-runs-scripts.md`

Do NOT load:
- `GDD.md` whole
- `_meta/agent-runs.csv`
- `_meta/sessions/` and transcripts
- the review folders
- run blackboards beyond their Result and the last verdict
- any file over about 300 lines

A read that needs any of these goes to a subagent that returns at most 150 words.

## Process
1. Restate the request in one line. If it matches a stop in `escalate.md`, hand it off now.
2. Find the owner in the `AGENTS.md` route table. If a script in `../_tools/CONTEXT.md` does the job, the script owns it; otherwise the agent the table names does. The operator itself does only the upkeep in step 6.
3. Brief the owner with only the files and sections it needs, and ask for a reply of at most 150 words.
   - Script runs (godot_run, build, mutate, shots) go to Rex, with the fast flags.
   - Loops start from their command: `generate.py`, `style_loop.py`, `goal_agent.py`.
4. Wait without spending turns: use background runs, then the completion notice, or Monitor on a blackboard. Never poll in a loop and never `sleep`.
5. Read the reply.
   - A PASS, or a green run: go on.
   - A FAIL: send it back to its owner (D48), then go back to step 4.
   - The same failure twice, or a designer stop: hand it off (`escalate.md`).
6. Do the mechanical upkeep the job leaves:
   - checkpoint commits on `main` (`python -I _tools/checkpoint.py`)
   - the handoff line for the next session
   - the status in `queue.md`
   - a vote section published: fetch the live Design Votes page with ArtifactData, run `compare_page.py add`, publish to the same URL; the operator does this itself
7. End the session when the job is done, so the next job starts with a small context again. A session held by `/goal` stays one job, the goal's; at its end, rewrite the handoff.

Hard limits:
- Edit lines, not files (team rule 5).
- No push, upload or memory delete without the designer's yes for that one action.
- Parking a blocked goal: `git stash push -u -m "<goal> parked (<question>)" -- <files>`, then a handoff line naming the stash and the question. After the designer's answer, `git stash pop` to unpark.
- While a goal run is live, edits under `game/` wait for the run to end; the guard enforces it. Spec answers that can't wait go through a worktree.
- Not end-of-day. That skill reads every decision log and publishes the decision page, and writing the decision log is judgement, so the designer runs it in an Opus session until `queue.md` #8 splits off its mechanical steps.
- No content run while the A4 gate is open ([future-tbd](../_meta/memory/future-tbd.md) item 9; the MILESTONES.md Open line is on the unmerged `feat/voice-check` branch).
- Replies to the designer: at most 150 words, with links to files instead of copied content.

## Outputs
- The owner's output, written to the owner's own shelf; the operator writes none of it.
- `queue.md`: the changed status lines.
- `../_meta/memory/session-handoff.md`: the "Next" line, plus any stop handed off.
- Checkpoint commits on `main` (`checkpoint.py`) only. Other commits wait for end-of-day.

## Check
- **Per job:** the owner's own check passed (Quinn's report, Clara's or Vera's PASS, Rex's counts), or the job is recorded as a stop in the handoff.
- **Per session:** the session's Orchestrator row in `_meta/agent-runs.csv` (written by the Stop hook). Phase 5 compares it with Opus sessions doing the same kind of work; the operator stays only if it costs less and the designer saw no extra rework.
