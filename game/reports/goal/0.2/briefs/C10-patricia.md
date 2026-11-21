Goal agent run `0.2`, spec `game/specs/0.2-first-automation.md`, goal C10. Work in the main folder on branch `milestone/0.2`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.
Config keys of this goal (Process 3: in `scripts/game_config.gd` and `default_config.tres`, marked PLACEHOLDER, live in the Dev panel): fork_return_seconds.
Node handoff: `game/specs/0.2-node-handoff.md` (read it first).

Your contract lines:
- Item 10: `honeycomb.gd` emits `drag_ended` on any release and when it goes inactive mid-drag; `uncap_fork.gd` gets a return move to the Harvest icon's spot, started when the zoom ends with the fork shown.
- The config keys above, in the Dev panel.

Spec text:
10. **The fork goes back into the Harvest icon** (same play-test: "fork stays in after harvesting is done/when mouse is done clicking, after harvesting the hive it should go back into the icon"; `UI_DESIGN.md` rule 4, Harvest is the fork icon). The fork prop never stays on screen without a drag: it hides when the press ends, wherever the release lands, and when the frame or zoom ends during a drag. When the zoom ends, a fork still on screen moves to the Harvest icon's spot and shrinks into it over `fork_return_seconds` (config, 0.35, live in Dev), then hides.

Reply in at most 150 words: files changed, node names used, open questions.