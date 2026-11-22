Goal agent run `0.3`, fix round 2 for goal C1 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scenes/ and materials/

You alone work this round. If the cause is in Patricia (scripts/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. contract:
CONTRACT: res://scenes/main.tscn: res://scripts/main.gd:121 looks up 'WelcomeOverlay', not in the scene tree
CONTRACT: res://scenes/main.tscn: res://scripts/main.gd:125 looks up 'WelcomeOverlay', not in the scene tree
contract: 80 lookups in 72 top-level scenes, 2 unresolved

Spec text:
1. **Welcome screen.** On every launch an overlay (CanvasLayer in `main.tscn`, not a separate scene) shows over the live farm, dimmed: the title "Chill Bee Game" and one **Play** button, nothing else (no how-to text, no icons). Until Play the world is idle: no hive fill, bees hold, no input reaches the farm. Play removes the overlay and shows the farm UI. Config `show_welcome` (bool, default true); every test run sets it false unless the test is about the welcome screen. The title is not translated; "Play" goes through `tr()` (key `welcome_play`, en "Play", fr "Jouer").

Reply in at most 150 words.