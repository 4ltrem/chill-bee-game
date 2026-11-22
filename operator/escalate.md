# escalate - what the operator never decides

The operator routes and does mechanical upkeep. It stops and hands off everything below, with a one-paragraph summary and the file paths, so the next reader doesn't have to read the whole thread.

## To the designer (a person decides)

| Stop | Why | How |
|---|---|---|
| A creative A/B choice, or any numerical visual change | the designer decides by looking ([AGENTS.md](../AGENTS.md); the Design Votes page) | `python -I _tools/compare_page.py add`, publish the page to the same URL ([operator/CONTEXT.md](CONTEXT.md) step 6), then stop |
| Accepting a proposal, or any change to `GDD.md` | the one rule ([AGENTS.md](../AGENTS.md)) | point to the proposal; never apply it |
| Approving content | [content/CONTEXT.md](../content/CONTEXT.md) | point to the draft |
| A `git push`, an itch upload, a course submission | an earlier yes covers only that push (D45) | ask each time |
| Deleting or moving files outside the repo, or deleting a memory | hard to undo | ask each time |
| A plan-usage override past the budget guard | the designer's call (D148, D167) | report the numbers and ask |
| A goal or spec item that is ambiguous | ask, don't guess (D113, D185) | quote the line and ask |

## To an Opus session (judgement)

| Stop | Examples |
|---|---|
| A design trade-off or a feature proposal | anything Gerard or Terry would write, or a choice between two designs |
| Synthesis for the designer | a play-test read-out, a graded write-up, a cost analysis with a recommendation |
| Changing a loop or a script's logic | `generate.py`, `goal_agent.py`, `style_loop.py`; read [_meta/learnings.md](../_meta/learnings.md) first |
| The same failure twice | a second FAIL with the same cause, or a fix that didn't hold (D159, D172) |
| Anything the operator is unsure fits its contract | default to escalate |

Override: a designer instruction in the session ("keep going", a `/goal`) overrides the same-failure-twice stop for that job. Route the next round to the owner with the verified cause. The "To the designer" stops are never overridden.

Handoff note: add a line under "Next" in the session handoff naming the stop and the files, then end the session. An Opus session started on that line reads only those files.
