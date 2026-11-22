---
name: status
description: Show where Chill Bee Game's workspace stands - branch and sync, uncommitted work, last commits, goal runs, the newest test run, open STOPs, the next decision ID, usage and what runs now. Use when the designer asks "status", "where are we", "what's running", or runs /status.
---

# Status

Run `python -I _tools/status.py` and show its output as is, in a code block. It is facts only and read-only.

Then add at most three lines of your own: which open STOP or `waiting-designer` run is the next thing for the designer, from the handoff (`_meta/memory/session-handoff.md`). Do not start any of it.

When the handoff is being rewritten at the end of a session, paste `python -I _tools/status.py --markdown` into it as its facts block instead of writing those facts by hand.
