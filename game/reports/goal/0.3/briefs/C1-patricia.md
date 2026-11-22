Goal agent run `0.3`, spec `game/specs/0.3-course-build.md`, goal C1. Work in the main folder on branch `main`; do not commit, switch branch or edit outside your folder. Follow `game/CONTEXT.md` (Process 2-5, 8). Read only the spec text below, not the whole spec.

Build your part (scripts/) of this change. Bob works on the scenes in parallel; the handoff is your contract. Run `python -I _tools/contract_check.py` before you finish.

Your contract lines:
- Item 1: the welcome overlay script; `main.gd` holds the world idle until `play_pressed`; `show_welcome` read from config.

Spec text:
1. **Welcome screen.** On every launch an overlay (CanvasLayer in `main.tscn`, not a separate scene) shows over the live farm, dimmed: the title "Chill Bee Game" and one **Play** button, nothing else (no how-to text, no icons). Until Play the world is idle: no hive fill, bees hold, no input reaches the farm. Play removes the overlay and shows the farm UI. Config `show_welcome` (bool, default true); every test run sets it false unless the test is about the welcome screen. The title is not translated; "Play" goes through `tr()` (key `welcome_play`, en "Play", fr "Jouer").

Reply in at most 150 words: files changed, node names used, open questions.