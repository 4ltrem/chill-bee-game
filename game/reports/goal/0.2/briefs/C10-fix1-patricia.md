Goal agent run `0.2`, fix round 1 for goal C10 of `game/specs/0.2-first-automation.md`, branch `milestone/0.2`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). tests:
FAIL    unit      194 passed, 1 failed  (exit 1, 292 noise lines dropped)  game/reports/_runs/20261121-001743/unit.log
    FAIL  t_fork_head_colour_by_level  Heated 3: at the first pulse's peak the head reaches crank orange (best dE 81.4 at 0.25 s, want <= 12) | Heated 3: at the second pulse's peak the head reaches crank orange again (best dE 81.4 at 1.26 s) | 

Spec text:
10. **The fork goes back into the Harvest icon** (same play-test: "fork stays in after harvesting is done/when mouse is done clicking, after harvesting the hive it should go back into the icon"; `UI_DESIGN.md` rule 4, Harvest is the fork icon). The fork prop never stays on screen without a drag: it hides when the press ends, wherever the release lands, and when the frame or zoom ends during a drag. When the zoom ends, a fork still on screen moves to the Harvest icon's spot and shrinks into it over `fork_return_seconds` (config, 0.35, live in Dev), then hides.

Reply in at most 150 words.