---
name: end-of-day
description: Close the designer's working day on Chill Bee Game - export this session's transcript, log the day's decisions, rebuild and republish the decision timeline page, run the checks, and commit. Use when the designer says "end of work day", "done for the day", "wrap up", "end of day", or runs /end-of-day. Do not run it on your own initiative mid-session.
---

# End of work day

The designer keeps a record of every working session for analysis and a future episodic memory. This routine is the same on every machine; everything it needs is in the repository.

Run the steps in order. Stop and report if a step fails; never commit over a failing check.

## 0. Check this machine is set up

**Doc gate.** `git config --get core.hooksPath` must print `.githooks`. If not, run `git config core.hooksPath .githooks`: it enables `.githooks/pre-commit`, which refuses any commit whose docs contradict the code (`_tools/consistency.py`) or whose links break.

**Memories.**

Project memories live in `_meta/memory/` and travel with git. Each machine points Claude Code there with one line in its own `.claude/settings.local.json` (gitignored, because the path is absolute): `"autoMemoryDirectory": "<absolute path to this repo>/_meta/memory"` (forward slashes). If the file or the line is missing, add it, merging with anything already there, and tell the designer it takes effect from the next session. If this machine still has memories in its old folder (`~/.claude/projects/<workspace>/memory/`), copy any that `_meta/memory/` lacks into it and add them to `_meta/memory/MEMORY.md` before going on.

## 1. Export the session

```
python -I _tools/export_session.py --all
```

It copies every transcript that is not yet exported, or has changed since its export, and their subagents' transcripts. That includes sessions closed with `/clear` (each `/clear` starts a new session id) and sessions run in a second terminal. The day's decision log (step 2) covers every session it exported today, not only this one. Each goes into `_meta/sessions/<date>-<first 8 of session id>/`, with a `manifest.json`. Note the folder it prints. Transcripts, subagent folders, manifests and `_meta/sessions/runs/` are gitignored: they hold the account email and everything read. `generate.py` already moved its own agents' transcripts into `_meta/sessions/runs/`.

## 2. Log the day's decisions

In that folder, create `decisions.md` from `_templates/decisions.md` if it does not exist yet; otherwise update it (the routine may run twice in one session).

- Add every decision made in this session that is not logged yet: process, architecture, model, rule and tooling decisions, and anything the designer explicitly decided or deferred. Decisions about a single draft or proposal belong in that file's `decided:` / `decision:` frontmatter, not here, but a deferral or a rule change that came with them does belong here.
- Number them after the highest `D<n>` in any `_meta/sessions/*/decisions.md` (IDs are global across sessions and machines).
- Use the strict format the template shows: `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>`, then `- Label: text` bullets (`Decided` first, then `Why`, `Rejected`, `Files`, or another label). Reuse an existing topic name when one fits: Workspace & agents, Pipeline design, Critic quality, Cost & structure, Bee Journal rules, Research & blackboard, Models, Records & deliverables.
- Rewrite `## Still open` as the full current list: carry over unresolved items from the newest previous log, drop resolved ones, add new ones. The page shows only the newest session's list.
- Write for the designer reading it later: plain sentences, what was decided and why, real file paths.

## 3. Rebuild and republish the decision page

```
python -I _tools/decision_page.py
```

It rebuilds `_meta/sessions/decision-comb.html` from every session's log. Publish that file with the Artifact tool to the existing page, keeping its link:

- url: https://claude.ai/code/artifact/d62b3ba8-566a-4d33-8b73-d8e7c8b71f57
- In a session that has not published or read it yet, first call the Artifact tool with `action: "read"` on that url, then publish `_meta/sessions/decision-comb.html` with the same `url`. No `icon`.

## 4. Audit the docs against the day's changes

Docs must stay true without the designer checking them. Three layers do that; this step runs the third.

1. `python -I _tools/sync_docs.py` rewrites the generated sections (facts copied from code and config).
2. Stage everything (`git add -A`), then run **Doris** (`.claude/agents/doc-auditor.md`): `python -I _tools/doc_audit.py`. It gives her the staged diff since the last commit, minus history, runs her headless (so it works even in a session that has not loaded her agent type), keeps her transcript and audit in `_meta/sessions/runs/<date>-doc-audit/`, logs her call, and prints `DOC AUDIT: CLEAN` or a table of statements the day made untrue. If the day already has commits, add `--since <the first commit of the day's parent>` so the audit covers the whole day.
3. Fix every finding whose fix is a plain correction to match the source of truth. If a finding needs a decision (the doc may be right and the code wrong), do not guess: list it for the designer under `## Still open` in the decision log and in the report.
4. Fixed findings go in the report.

## 5. Run the checks

```
python -I _tools/consistency.py
python -I _tools/test_generate.py
python -I _tools/index.py content research proposals/design proposals/balance
python -I _tools/links.py
```

All must pass. `consistency.py` checks that docs agree with code and config (the pre-commit hook runs it too); `test_generate.py` includes tests that every real `decisions.md` parses and that the real docs are consistent.

## 6. Commit

- `git status`, and confirm nothing gitignored is staged: `git check-ignore` any `_meta/sessions/` path you are unsure of. Never stage `session.jsonl`, `subagents/`, `manifest.json` or `_meta/sessions/runs/`.
- Stage the day's work, including `_meta/memory/` and the session's `decisions.md`, and commit on the current branch with a message that summarises the day in a short subject line and a body listing the main changes and the decision IDs added. End the message with any attribution lines the session's instructions give.
- **Milestone branches** (`game/CONTEXT.md`, Process 4): during a milestone the day is committed on its `milestone/<version>` branch, on top of the step checkpoints. Merge it into `main` (`git switch main && git merge --no-ff milestone/<version>`) only when Quinn's report for the milestone passes and the designer has played it; otherwise leave the branch open and say so in the report.
- Do not push unless the designer asks.

## 7. Report

Tell the designer, briefly: the export folder, the decision IDs added, what Doris found and what was fixed, the page link, the commit hash, and anything still open that needs them at the start of the next working day.
