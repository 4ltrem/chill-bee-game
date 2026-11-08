# Quinn's interaction checklist (designer chose all four recommended options 2026-11-08; built the same day)

Choices: scope = running interactions (one-tap gets only check 4); exits = in-game + app pause; spec gaps = ask, don't guess; shape = one sequence test, two mutations.

Approved 2026-11-08 as failure-mode fix 3c-c (session b89522de): "Only the obvious path gets tested. The crank kept going after Back because item 12's test only covered starting a crank in the farm view. Fix: a short checklist in Quinn's brief for each interaction: start it, leave mid-way, come back, and do it twice." Spec item 15 (0.1.4) is the bug it would have caught.

## What counts as an interaction

A contract line about something the player **starts and that keeps running or holds state** until it ends: crank, scrape, lid open/close, pour, zoom in/out, a hold. A one-tap action with no running state (a button that just fires once) gets only check 4.

## The four checks (one sequence test per interaction, driven by real input)

1. **Start.** Start it from every place the spec allows, and confirm it does *not* start from the places the spec rules out (item 12: never from the farm view or the first zoom).
2. **Leave mid-way.** While it is running, leave by every exit in the current UI: Back, zoom out, opening another panel or menu, and app pause (focus lost / `NOTIFICATION_APPLICATION_PAUSED`). After leaving, assert: the player's input no longer counts (no turn, no scrape, no progress), nothing the player was driving keeps moving, and progress is kept or reset exactly as the spec says. **Automatic steps are the exception** (designer, 2026-11-08: "things that are automatic that might fail the test such as the jar pour or the pile loading into the centrifuge"). Anything that runs on its own keeps running after the player leaves: automatic loads and pours (the jar pour, the pile loading: item 7, "in every view") and, generalized at the designer's request since later milestones add automation upgrades, anything an owned upgrade does (the motor: item 12). The test waits for it and asserts it finished, never that it stopped.
3. **Come back.** Return the way the spec names (e.g. Spin in the farm view pans back). Assert it resumes or restarts as the spec says, the UI matches that state, and nothing runs twice (one tween, one signal connection, one sound).
4. **Twice.** Do the whole thing start to finish, then again. The second run behaves like the first: same counts, same timings, no stacked signals or doubled rewards.

Every check asserts with a message naming its step (`"leave mid-way via Back: turn counted"`), so a red test says which step broke.

## When the spec says nothing

If the spec doesn't say what leaving mid-way or coming back should do, Quinn writes no guess. He lists it under open questions in his reply ("Item N: what happens to <x> on Back mid-way?"). The orchestrator puts the question to the designer and writes the answer into the spec ([[spec-consistency]]) before the code goes on.

## Mutations

One mutation per sequence test for check 2 (e.g. drop the "stop input on leave" line) and one for check 4 (e.g. connect the signal on every start). Checks 1 and 3 ride on the existing per-test mutation.

## Where it goes

- `_tools/goal_agent.py` `briefs()`, test branch: one short paragraph (Quinn's real prompt).
- `.claude/agents/qa-build-engineer.md`: one bullet, next to the real-input bullet (line 26).
- `game/CONTEXT.md` Process 2: one sentence.
- `_tools/test_goal_agent.py` (or wherever briefs are tested): a test that the test brief carries the checklist.
