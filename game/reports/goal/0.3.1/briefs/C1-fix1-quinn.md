Goal agent run `0.3.1`, fix round 1 for goal C1 of `game/specs/0.3.1-playtest-fixes.md`, branch `main`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit. Do not run the test suite, mutations or shots: the goal agent runs every check after you. You have 15 turns.

Your folder: tests/. Update only a test whose expectation this change of the spec replaces, and quote the spec line in a comment beside it. Any other failure is a finding against the code: leave the test and say which. If neither the failure message nor the code shows why a test fails, do not guess a fix: extend that test's FAIL message with one `diag:` part printing the state that would explain it (the state machine's value, counts on each side, elapsed vs. cap time), change nothing else for it, and say so; the next check prints it. Do not run the tests: the goal agent runs them after you. Test rules (L39): a flow step that several tests take (reach the second stop, open the shop, fill the bucket, wait for CRANKING) goes through one shared helper (unit: `tests/test_helpers_*.gd`; the windowed suites, which extend SceneTree: a static func in `tests/flow.gd`, preloaded, created on first need); reuse it, add it if it is missing, and never copy the steps inline, so a change to that step is fixed in one place. No literal cell index, node count or screen size: read it from the config, the scene, or ProjectSettings (`display/window/size/viewport_width` and `_height`).

tests:
    SCRIPT ERROR: Parse Error: Cannot infer the type of "journal" variable because the value doesn't have a set type.
    SCRIPT ERROR: Compile Error:
    SCRIPT ERROR: Compile Error:
    SCRIPT ERROR: Parse Error: Could not resolve class "JournalUI", because of a parser error.
FAIL    play      -1 passed, 2 failed  (godot exit 1, 0 noise lines dropped)  game/reports/_runs/20261123-142151/play.log
    FAIL  node missing (spec: Node paths for Bob): UpgradeButton
    FAIL  ABORT: a required node is missing; see the lines above
    SCRIPT ERROR: Parse Error: Could not resolve class "JournalUI", because of a parser error.
    SCRIPT ERROR: Parse Error: Cannot infer the type of "journal" variable because the value doesn't have a set type.
    SCRIPT ERROR: Compile Error:
    SCRIPT ERROR: Compile Error:
    SCRIPT ERROR: Parse Error: Could not resolve class "JournalUI", because of a parser error.

Spec text:
1. **One way into the Shop; the Journal gets its own icon.** Supersedes 0.3 item 2's "then **+**, which opens the Shop" and "its 120 px + button (V11)". The Habitat pill loses its **+**: `HabitatPlusButton` is deleted from `main.tscn` and `habitat_pill.gd` no longer looks for it. The pill is the number and the wildflower icon only (`UI_DESIGN.md` rule 9 order), and the `ShopButton` is the only control that opens the Shop. The pill shows on the farm view only: it is hidden in the first zoom and at the second stop (designer, 2026-11-22: "Hide pill at 2nd stop"). Today `TopInfo` stays at the second stop and shrinks to fit (`farm_ui.gd` `fit_top_info`, 0.1.3c), which made the + slide left; the money and bee count keep that behaviour, only the pill hides. The `JournalButton` leaves the Shop (`ShopPanel/ShopBox`) and becomes a farm-view icon (`UI_DESIGN.md` rules 2, 3, 6): a 120 × 120 button (V11) under `FarmUI`, labelled through `tr()` (key `journal_icon`, en "Journal", fr "Carnet"; the bee shape comes with the UI pass), bottom-right directly above the `ShopButton` with a 16 px gap. Being under `FarmUI` it hides in both zooms. It keeps 0.3 item 4's rule: hidden until thriving, and hidden again by the Dev "Reset habitat" that item 5 builds (it does not exist yet). It opens the same `JournalPanel` over the farm; `JournalCloseButton` returns to the farm. It clears the `ShopButton`, the skip icon, the hive count and the Harvest, Spin and Sell anchors. Size and position are placeholders the designer confirms at play-test.

Reply in at most 150 words.