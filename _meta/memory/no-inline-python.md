---
name: no-inline-python
description: "Never run inline code (python -c, heredoc scripts piped to an interpreter); the read block makes every such command prompt the designer"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 3260c91b-5129-4d17-a59d-2e69cfb5a86a
  modified: 2026-11-08T07:19:10.044Z
---

The designer turned on `permissions.blockReadsOutsideWorkingDirectories` (2026-11-07) after the Design Votes drafts were written outside the repo. Under that block, any command the shell parser can't analyze, such as `python -c "..."` or a heredoc piped to python, asks the designer every time. The designer finds these prompts annoying ("this is the rule that keeps getting triggered").

**Why:** the block stays on, because it keeps work inside the repo ([[repo-only]], [[drafts-folder]]). The prompts come from how commands are written, not from the rule.

**How to apply:** run repo scripts by path (`python -I _tools/<script>.py ...`). For a one-off check, use plain tools (grep, Read) or an existing repo script. The scratchpad is outside the repo, so a script there may prompt too. Never use `python -c`, inline heredoc interpreters, or `node -e`. Enforced since 2026-11-08 by the `_tools/guard_shell.py` PreToolUse hook.
