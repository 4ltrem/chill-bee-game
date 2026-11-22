Goal agent run `0.3`, fix round 2 for goal C1 of `game/specs/0.3-course-build.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. You alone work this round: Patricia put the fault in tests/. Check each failing test against the spec text: if it expects what the spec does not say (a wrong expectation, or state left over from an earlier run in the same scene), fix the test and quote the spec line beside it; if the game breaks the spec, change nothing and say which file and line: the next round goes to the code owners. Where the spec does not say what the game should do, change nothing for it and write one line ending `(designer)`: the question, with options A: and B:. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
FAIL    unit      4 passed, 3 failed  (godot exit 1, 10 noise lines dropped)  game/reports/_runs/20261122-132507/unit.log
    FAIL  t_dev_panel_when_on  a dev_panel.gd node exists with chill_bee/dev_mode true  (228 ms)
    FAIL  t_journal_tr_follows_locale  locale fr: tr(welcome_play) is the CSV fr text: expected Jouer got welcome_play | locale en: tr(welcome_play) is the CSV en text: expected Play got welcome_play | locale fr: tr(welcome_play) is the CSV fr 
    FAIL  t_journal_panel_text_matches_csv_twice  en run 1: the Journal button is on screen | en run 1: a real tap on Journal opens the panel | en run 1: the panel body is the CSV text: expected Canada is home to 41 bumble bee species � fuzzy, 
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    ERROR: Failed to load script "res://scripts/main.gd" with error "Parse error".
FAIL    start     3 errors  (godot exit 1 (1 is normal here), 4 noise lines dropped)  game/reports/_runs/20261122-132507/start.log
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    SCRIPT ERROR: Parse Error: Could not find type "WelcomeOverlay" in the current scope.
    ERROR: Failed to load script "res://scripts/main.gd" with error "Parse error".

Patricia (last round):
I fixed one cause, and the other two failure groups look like stale Godot caches that I couldn't clear from here. I ran nothing, per your instructions.

- **`t_journal_csv_equals_script_output`:** `_tools/journal_csv.py` didn't write the `welcome_play,Play,Jouer` row that `game/translations/journal.csv` already has. I added that row to the script, so its output should now match the file byte for byte.
- **`WelcomeOverlay` parse error:** `scripts/welcome_overlay.gd` and `main.gd` look correct. The `WelcomeOverlay` node is already in `main.tscn`. The error is almost certainly Godot's global class cache missing the new `class_name`. Run `godot_run.py unit start --refresh` to rebuild it.
- **`t_journal_tr_follows_locale`:** `tr(welcome_play)` returns the raw key. I suspect the CSV hasn't been re-imported, so the new row isn't in the translations. The `--refresh` run should re-import it. If it still fails after that, the cause is the import setup, and that needs `diag needed`.
- **`t_dev_panel_when_on` and `t_journal_panel_text_matches_csv_twice`:** these fail because `main.gd` doesn't load. I expect them to pass after the refresh.

I changed nothing under `scripts/`.

Spec text:
1. **Welcome screen.** On every launch an overlay (CanvasLayer in `main.tscn`, not a separate scene) shows over the live farm, dimmed: the title "Chill Bee Game" and one **Play** button, nothing else (no how-to text, no icons). Until Play the world is idle: no hive fill, bees hold, no input reaches the farm. Play removes the overlay and shows the farm UI. Config `show_welcome` (bool, default true); every test run sets it false unless the test is about the welcome screen. The title is not translated; "Play" goes through `tr()` (key `welcome_play`, en "Play", fr "Jouer").

Reply in at most 150 words.