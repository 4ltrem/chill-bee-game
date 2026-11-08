---
name: drafts-folder
description: "Unfinished work for a later session (vote plans, render status, write-up rows) goes in _meta/drafts/<version>/ in the repo, never the temp folder"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 81c6a13d-f79a-4428-bc66-986f58e5b2ff
  modified: 2026-11-07T22:17:46.269Z
---

Drafts of work handed to a later session go in `_meta/drafts/<version>/` (e.g. `_meta/drafts/0.1.4/`): vote plans, render status, README rows, page drivers. They don't go in the system temp or scratchpad folder. The session handoff points to them (designer, 2026-11-07: "make sure to include this drafts are in _meta/drafts/0.1.4/ for the votes").

**Why:** the designer stopped two of my steps that wrote throwaway files to the temp folder (a spot-check image and a Design Votes driver). Work the next session must pick up has to live in the repo, where both machines and sessions can see it.

**How to apply:** when work stops partway and a later session will continue it, write the draft into `_meta/drafts/<version>/`, add a short status file listing what is done and what is left, and link the folder from [[session-handoff]]. Related: [[ab-comparison-page]].
