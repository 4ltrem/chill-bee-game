Goal agent run `0.3`, fix round 1 for goal C1 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: scripts/

You alone work this round. If the cause is in Bob (scenes/)'s folder, change nothing and say which file and line: the next round goes to them. Change only what a failing row names; every other value, pose and position stays as it is (0.1.4: a lid fix asked to change the end also moved the open pose). If neither the failure message nor the code shows the cause, do not guess a fix: change nothing for it and write `diag needed` with the values that would show the cause; the next round asks Quinn to print them. Never change a visual number (a size, scale, offset, font size or margin) to make a check pass: those are the designer's, voted on the Design Votes page (item 12). If only such a change would fix a row, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. tests:
FAIL    unit      3 passed, 4 failed  (godot exit 1, 10 noise lines dropped)  game/reports/_runs/20261122-132434/unit.log
    FAIL  t_dev_panel_when_on  a dev_panel.gd node exists with chill_bee/dev_mode true  (224 ms)
    FAIL  t_journal_tr_follows_locale  locale fr: tr(welcome_play) is the CSV fr text: expected Jouer got welcome_play | locale en: tr(welcome_play) is the CSV en text: expected Play got welcome_play | locale fr: tr(welcome_play) is the CSV fr 
    FAIL  t_journal_panel_text_matches_csv_twice  en run 1: the Journal button is on screen | en run 1: a real tap on Journal opens the panel | en run 1: the panel body is the CSV text: expected Canada is home to 41 bumble bee species � fuzzy, 
    FAIL  t_journal_csv_equals_script_output  journal_csv.py output equals the committed journal.csv byte for byte (1238 vs 1262 bytes)  (244 ms)
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    ERROR: Failed to load script "res://scripts/main.gd" with error "Parse error".
FAIL    start     3 errors  (godot exit 1 (1 is normal here), 4 noise lines dropped)  game/reports/_runs/20261122-132434/start.log
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    ERROR: Failed to load script "res://scripts/main.gd" with error "Parse error".

Spec text:
1. **Welcome screen.** On every launch an overlay (CanvasLayer in `main.tscn`, not a separate scene) shows over the live farm, dimmed: the title "Chill Bee Game" and one **Play** button, nothing else (no how-to text, no icons). Until Play the world is idle: no hive fill, bees hold, no input reaches the farm. Play removes the overlay and shows the farm UI. Config `show_welcome` (bool, default true); every test run sets it false unless the test is about the welcome screen. The title is not translated; "Play" goes through `tr()` (key `welcome_play`, en "Play", fr "Jouer").

Reply in at most 150 words.