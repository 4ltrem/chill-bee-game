---
session: 48828af3-0854-4eed-ae60-5bc5642a3a42
dates: 2026-11-08 to 2026-11-08
transcript: session.jsonl (this folder, gitignored)
description: Assignment 4 check: CREW.md section committed to main, Clara's known-error check re-run on main
---
# Decisions: session 48828af3 (2026-11-08 to 2026-11-08)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D188 · 2026-11-08 · Records & deliverables · Assignment 4: "Does it sound like the game?" added to `CREW.md`, committed to `main`
- Decided: asked "is everything in place for this assignment?", the designer said "yes" to adding the section; committed to `main` from a temporary worktree (`origin/main` at `e4bfa51`) after the designer logged in for the push.
- Files: `CREW.md`, `_meta/memory/commit-to-main.md`

### D189 · 2026-11-08 · Critic quality · Re-run Clara's known-error check on `main`
- Decided: "ok run it": on `main` Clara caught all three planted errors (66,952 tokens); the fixture verdict, run log and `CREW.md` Limits line updated (`origin/main` at `00d0c83`). `milestone/0.1.4` does not have these two commits yet.
- Files: `_tools/fixtures/onboarding-bad.last-verdict.md`, `_meta/agent-runs.md`, `CREW.md`

## Still open

- See the newest log, `_meta/sessions/2026-11-09-4be1c5ef/decisions.md`.
