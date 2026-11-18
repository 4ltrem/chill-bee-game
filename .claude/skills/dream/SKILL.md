---
name: dream
description: Consolidate Chill Bee Game's project memory - read the recent decision logs, commits and memories, then propose memories to add, merge, correct or prune, and apply only what the designer approves. Use when the designer says "dream", "consolidate memory", "clean up memory", or runs /dream, or when the end-of-day skill offers it. Refuses to run on a machine that is not in sync with origin.
---

# Dream: consolidate memory

Memory lives in `_meta/memory/` and travels between the designer's two machines through git. A pass on a stale copy would undo or duplicate the other machine's memories, so step 0 is a hard gate. Only the designer approves memory changes; this skill proposes, then applies the approved rows with Edit.

Claude Code has no built-in consolidation to switch on: its docs list no `autoDreamEnabled` (checked 2026-11-18, `_meta/drafts/operator/analysis.md`).

## 0. Sync gate (refuse on fail)

```
git fetch origin
git status -sb
```

Stop and tell the designer, changing nothing, if any of these is true:
- the branch is behind its upstream, or main is behind `origin/main`;
- `_meta/memory/` has uncommitted changes this session did not make;
- the session handoff ([`_meta/memory/session-handoff.md`](../../../_meta/memory/session-handoff.md)) says the other machine has unpushed work.

## 1. Choose the window

Use the work since the last pass, read from the newest `_meta/drafts/dream/*.md` date. Without one, use everything. The window covers:
- the decision logs in `_meta/sessions/*/decisions.md`
- `git log --all` messages
- every file in `_meta/memory/`

## 2. Read (cheap readers, in parallel)

Brief three Sonnet subagents, each writing one file to `_meta/drafts/dream/<date>/`. The Phase 1 prompts are the model; `_meta/drafts/operator/*-findings.md` are their output.
- **decisions:** designer preferences (corrections, always/never, rejections, repeats), each with its D-numbers and a count of how often it recurs.
- **commits:** preferences in commit messages, plus work done by hand again and again.
- **memory:** memories that are stale, duplicated, contradicting each other or too long, each checked against the repo, plus the index lines that no longer match their files.

Each reader writes only its one file and replies in at most 150 words.

## 3. Propose

Write `_meta/drafts/dream/<date>.md` with two tables:
- **Add:** each new preference and its evidence.
- **Change:** the file, the action (merge / correct / prune) and the reason.

Before writing them:
- Check every claim that names a file, flag or count against the repo; a reader can be wrong.
- Drop any rule that is already in memory, in `_meta/team.md` or enforced by a hook.

## 4. Designer approves

Show the two tables and ask which rows to apply. Apply nothing without that answer.

## 5. Apply

Use Edit on the needed lines only. A new memory is a new file, and a pruned file needs the designer's yes for each delete. Update the matching `MEMORY.md` index line in the same pass. Then run:

```
python -I _tools/links.py
```

It must report 0 broken links. A dead `[[link]]` inside a memory is allowed (it marks a memory still to write).

## 6. Leave it for end-of-day

Don't commit. The `end-of-day` skill commits memory with the day's other changes.
