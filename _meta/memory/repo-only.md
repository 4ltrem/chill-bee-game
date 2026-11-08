---
name: repo-only
description: "Read and run only files inside the repo; anything outside (~/.claude transcripts, tool-results copies) needs an explanation first"
metadata:
  node_type: memory
  type: feedback
  originSessionId: f02d3df8-5279-44dd-9dfd-b1dea783ef12
  modified: 2026-11-08T07:19:12.961Z
---

Only read and run things from inside the MAIGD repo. Don't read outside it (for example `~/.claude/projects/` transcripts or the Artifact tool's saved copies in `tool-results/`) unless I first explain why it's needed.

**Why:** the designer, 2026-11-07, said "don't need to read outside this repo unless you can explain to me why" and "yes only run stuff from the repo". They rejected a transcript listing, then a page build that used the Artifact read's out-of-repo copy as its base.

**How to apply:** "analyze the last sessions" means `_meta/sessions/`, the handoff, drafts and git, not transcripts. For Design Votes, build from `game/reports/ui-compare/design-votes.html` after checking that the live page's header matches it ([[ab-comparison-page]]).

**In Bash:** use only paths relative to the repo. No `cd` prefix (the cwd is already the repo), and no `C:\Users\...` paths, which the permission check counts as outside the repo even when they point inside it. Edit files with Edit, not Python write scripts ([[edit-lines-only]]). Chain only commands on the allow list, or send parallel calls. The `cd` prefix and absolute repo paths are refused by `_tools/guard_shell.py` since 2026-11-08.
