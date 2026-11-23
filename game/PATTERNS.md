# Game programming patterns - Chill Bee Game's code reference

One job: the patterns from Robert Nystrom's *Game Programming Patterns* (free web edition, <https://gameprogrammingpatterns.com>, © Robert Nystrom, no reuse licence stated, so this page paraphrases and links, never copies) that fit a small Godot idle game, each with its Godot form, where it already lives in `scripts/`, and when to reach for it. Agents read only the sections their brief or definition names. The spec and the GDD still decide *what* to build; this page only shapes *how*.

Rule of thumb from the book's opening chapter ([Architecture, Performance, and Games](https://gameprogrammingpatterns.com/architecture-performance-and-games.html)): decoupling earns its cost only where change is likely. Don't add a pattern for a feature the spec doesn't ask for; reach for one when the second copy of a problem shows up.

## Use these

### Observer: signals ([chapter](https://gameprogrammingpatterns.com/observer.html))
*Godot form:* `signal` + `.connect()`. *Ours:* already the main wiring (about 37 signals, 67 connects; `economy.gd`, `centrifuge.gd`, `hive.gd`, `honeycomb.gd`).
- Gameplay emits; UI and audio listen. A gameplay script never reaches into a UI node to update it.
- Every `connect` has an owner that disconnects or frees with it; a listener freed while still connected is the book's "lapsed listener" bug.
- Signals fire synchronously: a listener that changes the emitter's state mid-emit is a re-entrancy bug. If it must, defer it (`call_deferred` or Event Queue below).

### State: the interaction state machines ([chapter](https://gameprogrammingpatterns.com/state.html))
*Ours:* `centrifuge.gd` `enum State { EMPTY, LOADING, FULL, CRANKING, DONE, BOTTLING }`, `main.gd` `enum Zoom`.
- Each state change goes through one `_set_state(new)` that runs the old state's exit and the new state's enter. Input handlers check the state first and do nothing outside the states that accept them.
- This is the code side of Quinn's interaction checklist: "the crank kept counting after Back" (0.1.3) is a missing exit step. A new thing the player starts and leaves (crank, scrape, lid, pour, hold) gets an enum and a `_set_state`, not a set of bools.
- A state table in the spec maps one-to-one to the enum; name them the same.

### Type Object: config and data resources ([chapter](https://gameprogrammingpatterns.com/type-object.html))
*Godot form:* a `Resource` with `@export` fields. *Ours:* `game_config.gd` / `default_config.tres`; `upgrade_level.gd`.
- A new *kind* of thing that differs only in numbers and names (an upgrade, a bee species, a flower, a biome's yields) is one Resource instance, not a new script or subclass. Adding a species should be a data edit plus Journal text.
- Matches the workspace rule: every tunable lives in the config, is read when used, and shows in the Dev panel.

### Command: recorded input ([chapter](https://gameprogrammingpatterns.com/command.html))
*Ours:* `input_recorder.gd` records `InputEvent`s with game time; `tests/replay.gd` plays them back with the `GameRng` seed.
- Replays stay exact only while every random draw goes through `GameRng` and every timer uses game time. New gameplay randomness never calls the global `randf()`.
- If undo or a player action log is ever specced, model player actions as command objects then; not before.

### Update Method and Game Loop: `_process` and offline time ([Update Method](https://gameprogrammingpatterns.com/update-method.html), [Game Loop](https://gameprogrammingpatterns.com/game-loop.html))
*Ours:* 13 scripts have `_process`.
- Everything that advances with time scales by `delta` (and so by `Engine.time_scale`, which the test runner's `--time-scale 6` relies on). No per-frame counters.
- A `_process` that only watches for a change is a candidate for a signal (Observer) or a Dirty Flag; idle `_process` work costs battery on mobile. Turn it off with `set_process(false)` when the node has nothing to do.
- Idle-game catch-up (offline earnings, a skipped wait) is the book's fixed-step idea: advance the economy by a computed elapsed time in one closed-form step or fixed chunks, never by replaying frames. Any offline-progress spec should name which.

### Dirty Flag: derived display values ([chapter](https://gameprogrammingpatterns.com/dirty-flag.html))
- For values derived from several others and shown in UI (rates, upgrade costs, labels): set a dirty flag when an input changes (a signal), recompute once when read or once per frame. Cuts the per-frame recomputing in UI `_process` methods such as `farm_ui.gd`.
- Never use it to cache a config value: the config is read when used so Dev mode edits apply at once. Dirty-flag only derived values, and mark them dirty on the config's change too.

### Object Pool: short-lived flying props ([chapter](https://gameprogrammingpatterns.com/object-pool.html))
*Ours:* `cell_flight.gd` and `jar_flight.gd` `instantiate()` and `queue_free()` each flight; `floating_icon.gd` likewise.
- Not needed yet. Reach for it only when Quinn's profile shows frame spikes on a test device during bursts (Auto-Sell, many jars at once). Then: a fixed-size pool per prop, hidden and reset on return, size in the config.

### Flyweight: shared meshes and materials ([chapter](https://gameprogrammingpatterns.com/flyweight.html))
*Godot form:* shared `.tres` materials and meshes, `MultiMeshInstance3D`. *Ours:* `materials/` (one material per palette use), `bees.gd`.
- Bob's rule already: repeated bees, flowers and cells share one mesh and material; per-instance differences go in MultiMesh instance data or a shader parameter, not a duplicated material. A `duplicate()` of a material in a loop is a draw-call leak.

### Singleton and Service Locator: autoloads ([Singleton](https://gameprogrammingpatterns.com/singleton.html), [Service Locator](https://gameprogrammingpatterns.com/service-locator.html))
*Ours:* `Economy` is the only autoload; `GameRng` and `GameConfig.live()` are static access points.
- The book's warning: global access hides coupling and makes tests order-dependent. Keep autoloads few. A new global needs a reason in the spec.
- Tests can replace what the locator hands out (a fixed `GameRng` seed, a test config) rather than poking gameplay internals; a static access point offers a way to reset or swap it for tests.

### Component: nodes ([chapter](https://gameprogrammingpatterns.com/component.html))
*Godot form:* child nodes and one-job scripts. *Ours:* `uncap_fork.gd`, `lid_motion.gd`, `jar_fill.gd`.
- A big script (`main.gd` 720 lines, `centrifuge.gd` 642) gains a feature by gaining a child component, not more branches. A refactor step that moves code into a component is a 0.Xa "no behaviour change" step (`CONTEXT.md` Process 4), with node names in the spec's contract.

### Event Queue: deferred messages ([chapter](https://gameprogrammingpatterns.com/event-queue.html))
- For sounds and toasts that may fire many times in one frame (a sell burst): queue and merge them, play once. For a listener that must not act inside the emitter's call: `call_deferred`. No general event bus unless a spec asks.

## Not for us now
[Double Buffer](https://gameprogrammingpatterns.com/double-buffer.html) (the engine does it), [Bytecode](https://gameprogrammingpatterns.com/bytecode.html) (no modding or scripting language), [Subclass Sandbox](https://gameprogrammingpatterns.com/subclass-sandbox.html) (Type Object covers our variety), [Prototype](https://gameprogrammingpatterns.com/prototype.html) (`PackedScene` already is one), [Data Locality](https://gameprogrammingpatterns.com/data-locality.html) and [Spatial Partition](https://gameprogrammingpatterns.com/spatial-partition.html) (too few objects; revisit only on a profiler finding).

## Who reads what
| Agent | Sections |
|---|---|
| Patricia | all of "Use these" that her task touches; always State, Observer, Type Object |
| Bob | Flyweight, Component |
| Quinn | State (to find the exits to test), Command (replays), Update Method (time scale), Object Pool (when profiling) |
| Gerard | Type Object (a new kind of thing should be data), Update Method (offline catch-up) |
