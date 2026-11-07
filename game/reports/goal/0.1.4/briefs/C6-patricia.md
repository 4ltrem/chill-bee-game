Goal agent run `0.1.4`, spec `game/specs/0.1.4-ui-placement.md`, goal C6. Work in the main folder on branch `milestone/0.1.4`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Node handoff: `game/specs/0.1.4-node-handoff.md` (read it first).

Your contract lines:
- Item 6: the recorder path under the tests.

Spec text:
6. **Housekeeping from 0.1.3:**
   - Tests and shot scripts never write into the player's `user://recordings` (about 278 test files landed there on 11/6). Under the tests, the recorder writes to a temp folder or is off.
   - The 10 X1_TESTS stay the designer's to play (D102); nothing here changes the timing tests.

Reply in at most 150 words: files changed, node names used, open questions.