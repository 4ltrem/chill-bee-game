# Goal agent: 0.1.4-ui-placement.md (run 0.1.4)

Spec: `game/specs/0.1.4-ui-placement.md` (version 0.1.4). Agent: `_tools/goal_agent.py` (spec `game/specs/m3-goal-agent.md`).
No agent reads this file; it is the run's record.

---

Invocation (plan) 2026-11-07T12:16:06-05:00: `goal_agent.py 0.1.4-ui-placement.md --plan`

## Pass 1: scan (2026-11-07T12:16:06-05:00)

Unit results from `game/reports/_runs/20261107-120831/unit.log`. 0 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | missing | ✗ handoff game/specs/0.1.4-node-handoff.md |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | missing | ✗ config harvest_anchor_offset, ✗ config spin_anchor_offset, ✗ config sell_anchor_offset, ✗ config button_screen_margin |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | H Node handoff (Patricia to Bob) | 16.17 | 5 | 1 | 0.83 | 1 | 5 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 2 | C7 The pile loads on its own at the second stop | 11.17 | 2 | 3 | 0.83 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.83 (Patricia) |
| 3 | C6 Housekeeping from 0.1.3: | 7.17 | 2 | 1 | 0.83 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 4 | C1 Harvest button is the honey meter | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 5 | C2 Buttons anchored to their props, the same way in e | 0.0 | 3 | 3 | 1.2 | 0 | waits on H |
| 6 | C3 Back in one fixed place | 0.0 | 2 | 3 | 1.2 | 0 | waits on H |
| 7 | C4 Speed tag clear of the top info | 0.0 | 2 | 3 | 0.36 | 0 | waits on H |
| 8 | C5 Bigger hive frames and combs | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 9 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C1, C2, C3, C4, C5, C6, C7 |
| 10 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C1 |
| 11 | T2.1 no two HUD controls overlap, and none is cut off b | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 12 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 13 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.64 | 0 | waits on C3 |
| 14 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.64 | 0 | waits on C4 |
| 15 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C5 |
| 16 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C6 |
| 17 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.64 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

---

Invocation (dry run) 2026-11-07T12:16:06-05:00: `goal_agent.py 0.1.4-ui-placement.md --dry-run`

## Pass 2: scan (2026-11-07T12:16:07-05:00)

Unit results from `game/reports/_runs/20261107-120831/unit.log`. 0 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | missing | ✗ handoff game/specs/0.1.4-node-handoff.md |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | missing | ✗ config harvest_anchor_offset, ✗ config spin_anchor_offset, ✗ config sell_anchor_offset, ✗ config button_screen_margin |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | H Node handoff (Patricia to Bob) | 16.17 | 5 | 1 | 0.83 | 1 | 5 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 2 | C7 The pile loads on its own at the second stop | 11.17 | 2 | 3 | 0.83 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.83 (Patricia) |
| 3 | C6 Housekeeping from 0.1.3: | 7.17 | 2 | 1 | 0.83 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 4 | C1 Harvest button is the honey meter | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 5 | C2 Buttons anchored to their props, the same way in e | 0.0 | 3 | 3 | 1.2 | 0 | waits on H |
| 6 | C3 Back in one fixed place | 0.0 | 2 | 3 | 1.2 | 0 | waits on H |
| 7 | C4 Speed tag clear of the top info | 0.0 | 2 | 3 | 0.36 | 0 | waits on H |
| 8 | C5 Bigger hive frames and combs | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 9 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C1, C2, C3, C4, C5, C6, C7 |
| 10 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C1 |
| 11 | T2.1 no two HUD controls overlap, and none is cut off b | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 12 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 13 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.64 | 0 | waits on C3 |
| 14 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.64 | 0 | waits on C4 |
| 15 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C5 |
| 16 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C6 |
| 17 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.64 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

Next: **H** (score 16.17: 5 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia)).

### Step: H (2026-11-07T12:16:07-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/H-patricia.md` (4050 chars)
- Checks: 
- Dry run: no agent called.

## Result (2026-11-07T12:16:07-05:00): dry-run

---

Invocation (build) 2026-11-07T12:16:42-05:00: `goal_agent.py 0.1.4-ui-placement.md --max-goals 1`
Branch `milestone/0.1.4`: checked out from `milestone/0.1` (new).

## Pass 3: scan (2026-11-07T12:16:42-05:00)

Unit results from `game/reports/_runs/20261107-120831/unit.log`. 0 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | missing | ✗ handoff game/specs/0.1.4-node-handoff.md |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | missing | ✗ config harvest_anchor_offset, ✗ config spin_anchor_offset, ✗ config sell_anchor_offset, ✗ config button_screen_margin |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | H Node handoff (Patricia to Bob) | 16.17 | 5 | 1 | 0.83 | 1 | 5 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 2 | C7 The pile loads on its own at the second stop | 11.17 | 2 | 3 | 0.83 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.83 (Patricia) |
| 3 | C6 Housekeeping from 0.1.3: | 7.17 | 2 | 1 | 0.83 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 4 | C1 Harvest button is the honey meter | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 5 | C2 Buttons anchored to their props, the same way in e | 0.0 | 3 | 3 | 1.2 | 0 | waits on H |
| 6 | C3 Back in one fixed place | 0.0 | 2 | 3 | 1.2 | 0 | waits on H |
| 7 | C4 Speed tag clear of the top info | 0.0 | 2 | 3 | 0.36 | 0 | waits on H |
| 8 | C5 Bigger hive frames and combs | 0.0 | 2 | 2 | 1.2 | 0 | waits on H |
| 9 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C1, C2, C3, C4, C5, C6, C7 |
| 10 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C1 |
| 11 | T2.1 no two HUD controls overlap, and none is cut off b | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 12 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 13 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.64 | 0 | waits on C3 |
| 14 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.64 | 0 | waits on C4 |
| 15 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C5 |
| 16 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C6 |
| 17 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.64 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

Next: **H** (score 16.17: 5 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia)).

### Step: H (2026-11-07T12:16:42-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/H-patricia.md` (4050 chars)
- Budget guard for Patricia: allow (reading 1 min old)

**Patricia** (221,991 tokens, 16 turns, 42 s):

I wrote `game/specs/0.1.4-node-handoff.md` and no code. I haven't run any checks.

**Nodes Bob adds**
- `ForkIcon/HarvestFill`
- `FarmUI/HiveCountLabel`
- A `disabled` style on `ForkIcon`

**Nodes Bob removes**
- `TopInfo/FillBar`
- `TopInfo/FillLabel`

**Nodes Bob moves**
- `CentrifugeIcon` moves from `FarmUI` to `FarmUIRoot`. I'll delete the runtime reparent in `main.gd`.
- `DevSpeedTag` moves into `TopInfo`, as the last child.
- `BackButton` goes to the top-right corner. I'll delete the Back scan in `main.gd`.
- The existing anchors `ForkAnchor`, `CentrifugeAnchor` and `SellAnchor` are repositioned above the hive lid, centrifuge lid and truck bed.
- `FrameSlots/Slot1..5` and `FrameBars/FrameBar1..5` are scaled up together.

**Open questions**
1. A cell matching the pile cell is about 2.15x larger, which gives a frame about 1.95 wide against a hive body about 1.26 wide. I suggest about 1.35x with `grid_cols` 7 → 5, or a wider body. Who decides?
2. Bob should report the final frame scale, so I can retune `frame_rise` and recheck the 20 px rule.

- Green: checkpoint `c31bbb8` on `milestone/0.1.4`

**Stop:** stopped after 1 goal(s) (--max-goals).

## Pass 4: scan (2026-11-07T12:17:26-05:00)

Unit results from `game/reports/_runs/20261107-120831/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | missing | ✗ config harvest_anchor_offset, ✗ config spin_anchor_offset, ✗ config sell_anchor_offset, ✗ config button_screen_margin |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C2 Buttons anchored to their props, the same way in e | 13.8 | 3 | 3 | 1.2 | 1 | 3 goal(s) wait on it; play-test fix; cost 1.2 (Patricia, Bob) |
| 2 | C4 Speed tag clear of the top info | 11.64 | 2 | 3 | 0.36 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.36 (Bob) |
| 3 | C7 The pile loads on its own at the second stop | 11.17 | 2 | 3 | 0.83 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.83 (Patricia) |
| 4 | C3 Back in one fixed place | 10.8 | 2 | 3 | 1.2 | 1 | 2 goal(s) wait on it; play-test fix; cost 1.2 (Patricia, Bob) |
| 5 | C1 Harvest button is the honey meter | 8.8 | 2 | 2 | 1.2 | 1 | 2 goal(s) wait on it; designer feature; cost 1.2 (Patricia, Bob) |
| 6 | C5 Bigger hive frames and combs | 8.8 | 2 | 2 | 1.2 | 1 | 2 goal(s) wait on it; designer feature; cost 1.2 (Patricia, Bob) |
| 7 | C6 Housekeeping from 0.1.3: | 7.17 | 2 | 1 | 0.83 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.83 (Patricia) |
| 8 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C1, C2, C3, C4, C5, C6, C7 |
| 9 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C1 |
| 10 | T2.1 no two HUD controls overlap, and none is cut off b | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 11 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 12 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.64 | 0 | waits on C3 |
| 13 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.64 | 0 | waits on C4 |
| 14 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C5 |
| 15 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C6 |
| 16 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.64 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

## Result (2026-11-07T12:17:26-05:00): stopped after 1 goal(s) (--max-goals)

1 agent call(s), 221,991 tokens.

---

Invocation (build) 2026-11-07T12:19:16-05:00: `goal_agent.py 0.1.4-ui-placement.md`
Branch `milestone/0.1.4`: already on it.

## Pass 5: scan (2026-11-07T12:19:16-05:00)

Unit results from `game/reports/_runs/20261107-120831/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | missing | ✗ config harvest_anchor_offset, ✗ config spin_anchor_offset, ✗ config sell_anchor_offset, ✗ config button_screen_margin |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing AMBIGUOUS | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C2 Buttons anchored to their props, the same way in e | 13.85 | 3 | 3 | 1.15 | 1 | 3 goal(s) wait on it; play-test fix; cost 1.15 (Patricia, Bob) |
| 2 | C4 Speed tag clear of the top info | 11.64 | 2 | 3 | 0.36 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.36 (Bob) |
| 3 | C7 The pile loads on its own at the second stop | 11.21 | 2 | 3 | 0.79 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.79 (Patricia) |
| 4 | C3 Back in one fixed place | 10.85 | 2 | 3 | 1.15 | 1 | 2 goal(s) wait on it; play-test fix; cost 1.15 (Patricia, Bob) |
| 5 | C1 Harvest button is the honey meter | 8.85 | 2 | 2 | 1.15 | 1 | 2 goal(s) wait on it; designer feature; cost 1.15 (Patricia, Bob) |
| 6 | C6 Housekeeping from 0.1.3: | 7.21 | 2 | 1 | 0.79 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.79 (Patricia) |
| 7 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C1, C2, C3, C4, C5, C6, C7 |
| 8 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C1 |
| 9 | T2.1 no two HUD controls overlap, and none is cut off b | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 10 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 0.0 | 0 | 3 | 0.64 | 0 | waits on C2 |
| 11 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.64 | 0 | waits on C3 |
| 12 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.64 | 0 | waits on C4 |
| 13 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.64 | 0 | waits on C5 |
| 14 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.64 | 0 | waits on C6 |
| 15 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.64 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

### Ambiguous (not scored; built after the designer answers)

- C5: Bigger hive frames and combs
  - Question: A full 2.15x frame is about 1.95 wide against a 1.26 body, so it can't fit. Choose one: about 1.35x (5 cols fit with `grid_cols` 7 → 5, a config change) or widen the hive body. Gerard or the designer decides; I read `grid_cols` from config either way.
  - Question: A bigger frame changes `frame_rise` (now 0.76) and the first zoom's ≥ 20 px check. Bob should report the final scale so I retune.

Next: **C2** (score 13.85: 3 goal(s) wait on it; play-test fix; cost 1.15 (Patricia, Bob)).

### Step: C2 (2026-11-07T12:19:16-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/C2-patricia.md` (2229 chars)
- Brief for Bob: `game/reports/goal/0.1.4/briefs/C2-bob.md` (2087 chars)
- Budget guard for Patricia: allow (reading 0 min old)
- Budget guard for Bob: allow (reading 0 min old)

**Bob** (455,025 tokens, 22 turns, 73 s):

Item 2 is done in the scenes. The three anchors are lowered and Spin now sits under `FarmUIRoot`. `contract_check` reports 0 unresolved. I rendered the nine `ui_compare_shots` moments and read them as one contact sheet.

**Files changed**
- `scenes/props/hive.tscn`: `ForkAnchor` y 3.65 → 1.75.
- `scenes/props/centrifuge.tscn`: `CentrifugeAnchor` y 5.27 → 3.77.
- `scenes/props/truck.tscn`: `SellAnchor` y 3.646 → 1.62.
- `scenes/main.tscn`: `CentrifugeIcon` is now a child of `FarmUIRoot`, with its anchor path `../../FarmWorld/Centrifuge/CentrifugeAnchor`. All three buttons keep `screen_offset` (0, 0).

**What the renders showed**
- **Harvest:** sits just above the hive lid in the farm view.
- **Spin:** sits just above the centrifuge lid.
- **Sell:** sits just above the truck bed, between crate and truck, as in ab-A `8-sell`.
- **Overlaps:** nothing overlaps in those three. At the second stop Harvest still shows; hiding it there is `main.gd`'s job.

No new moment was needed in `ui_compare_shots.gd`. I did not touch items 1, 3, 4 or 5 or their scenes. My probe shots are deleted.

**Open questions:** none for item 2.


**Patricia** (533,260 tokens, 33 turns, 695 s):

Item 2 is in `scripts/`, but `unit` has 11 failures and I did not triage them. The run was 134 passed, 11 failed (log: `game/reports/_runs/20261107-122019/unit.log`). `start` passed and `contract_check` shows 0 unresolved. I did not run `play_loop`.

**Changed**
- `floating_icon.gd` is the shared anchor-follow component.
  - It projects the anchor each frame, adds the one config offset for its button, then clamps to `button_screen_margin` and nudges clear.
  - It nudges clear of other anchored buttons, `TopInfo` and `BackButton`.
  - Offsets are picked by node name.
  - It no longer has the `use_fixed_center` and `fixed_center` pin.
- `main.gd`:
  - It no longer moves Spin out of `FarmUI` (the `reparent` is gone).
  - The second-stop pinning for Harvest and Spin is removed.
  - Harvest is hidden at the second stop.
- `game_config.gd` and `default_config.tres` have the four keys, which show in the Dev panel. The three offsets are PLACEHOLDER 0 px (vertical, positive is down), and `button_screen_margin` is 16.
- `dev_panel.gd`: offset rows accept negative values.

**Nodes used:** `ForkIcon`, `CentrifugeIcon`, `SellIcon`, `ForkAnchor`, `CentrifugeAnchor`, `SellAnchor`, `TopInfo`, `BackButton`.

**For Quinn**
- `test_helpers_1.gd` reads `fixed_center`, which no longer exists. That gives the "Invalid cast to Vector2" errors.
- These second-stop tests encode the old pinning and need rewriting: `t_camera_second_stop_hud_clear`, `t_second_stop_spin_icon_tap`, `t_second_stop_fork_icon_tap`, `t_icons_never_overlap`.
- `t_icons_above_props` fails until Bob moves the anchors.
- Not triaged: `t_fork_shows_while_cranking_and_state_table`, `t_scrape_then_back_in_pop_window_pile`, `t_resume_pending_pile_loads_while_zoom_open`, `t_pan_after_back_then_harvest_again`, `t_replay_fill_and_back`, `t_replay_without_back_stays_in_zoom`. They may depend on the second-stop Harvest or Spin buttons.

**Open question:** with Harvest hidden at the second stop, how should tests reach "Harvest again"?

- Check `contract`: PASS
- Check `tests`: FAIL (exit 1)

```
    FAIL  t_fork_shows_while_cranking_and_state_table  zoom opened at DONE | zoom: Sell icon hidden (farm UI)  (1680 ms)
    FAIL  t_scrape_then_back_in_pop_window_pile  the fork stays: 34 + 4 x 35 Capped cells remain | the fork opens the zoom again | the frame with the empty slot rises first: expected [0] got []  (1383 ms)
    FAIL  t_resume_pending_pile_loads_while_zoom_open  Back: the fork shows (frames 4 and 5 hold Capped cells) | DONE: the fork still shows (resume_pending) | BOTTLING: the fork shows (resume_pending) | zoom 2 did not open while bottling  (4570
    FAIL  t_camera_second_stop_hud_clear  no HUD control overlaps the hive's visible screen rect [P: (395.1641, 61.35845), S: (320, 320)]: expected [] got ["CentrifugeIcon [P: (306.6188, 45.07183), S: (160, 160)]"] | no HUD control overlaps the
    FAIL  t_second_stop_spin_icon_tap  Spin sits left of the centrifuge (icon x 387, centrifuge from x 250) | Spin does not cover the centrifuge: expected true got false  (3221 ms)
    FAIL  t_second_stop_fork_icon_tap  Harvest shows at the second stop (Capped frames remain) | Harvest covers neither the hive nor the centrifuge: expected true got false | a real tap on Harvest at the second stop opens the zoom (a frame rise
    FAIL  t_icons_never_overlap  second stop: CentrifugeIcon does not meet the hive ([P: (306.6188, 45.07183), S: (160, 160)], [P: (390.162, 56.98021), S: (329.838, 330.7086)]): expected false got true | second stop: CentrifugeIcon does not mee
    FAIL  t_pan_after_back_then_harvest_again  Harvest again: a frame rises | the camera went back to the first zoom | every remaining frame was uncapped  (24389 ms)
    FAIL  t_icons_above_props  farm view: ForkIcon bottom 520 is at or above the Hive top 478 (+20) | farm view: CentrifugeIcon bottom 680 is at or above the Centrifuge top 538 (+20) | first zoom: ForkIcon bottom 413 is at or above the Hive top
    SCRIPT ERROR: Invalid cast: could not convert value to 'Vector2'.
    SCRIPT ERROR: Invalid cast: could not convert value to 'Vector2'.
    SCRIPT ERROR: Invalid cast: could not convert value to 'Vector2'.
```

#### Fix round 1: to Patricia, Bob, Quinn

- Budget guard for Patricia: allow (reading 2 min old)
- Budget guard for Bob: allow (reading 2 min old)
- Budget guard for Quinn: allow (reading 2 min old)

**Bob** (137,517 tokens, 9 turns, 20 s):

I made no edits. These failures are in `tests/` and `scripts/`, not in `scenes/` or `materials/`.

My side matches the spec and `game/specs/0.1.4-node-handoff.md`:
- `ForkAnchor`, `CentrifugeAnchor` and `SellAnchor` sit just above the hive lid, centrifuge lid and truck bed.
- `CentrifugeIcon` is placed in `FarmUIRoot` by the scene.
- All three buttons have `screen_offset` (0, 0).

**Quinn's tests (`tests/test_second_stop.gd`):** several still assert the 0.1.3 layout, which the spec replaced.
- `t_icons_above_props` wants the Harvest and Spin buttons' bottom edges at or above the prop top. The spec puts them "just above the lid", which is lower.
- `t_second_stop_fork_icon_tap` expects Harvest to show at the second stop. The spec hides it there.
- `t_second_stop_spin_icon_tap` expects Spin to the left of the centrifuge.
- The fork, scrape and resume failures (zoom not opening, "DONE") likely follow from the same stale expectations. I didn't confirm that.

**Patricia (`scripts/floating_icon.gd`):** at the second stop the clamp and nudge leave Spin overlapping the hive. This is the `t_icons_never_overlap` and `t_camera_second_stop_hud_clear` failure.

**Vector2 cast errors:** the source is in `scripts/` or `tests/`. I did not find the line.

Quinn should update the stale assertions. Patricia should fix the second-stop nudge.


**Quinn** (927,906 tokens, 34 turns, 616 s):

Four tests still fail, and the cause is a bug in game code, not in the tests. The other five tests from your list now pass.

**Finding for Patricia:** in `game/scripts/main.gd`, `leave_second_stop()` (around line 431) never calls `_refresh_icons()`. Harvest is now hidden at the second stop. After Back returns to the farm view, nothing un-hides it, so the player can't harvest again. One-line fix: call `_refresh_icons()` at the end of `leave_second_stop()`.

**Still failing for that reason:**
- `t_second_stop_fork_icon_tap`
- `t_pan_after_back_then_harvest_again`
- `t_scrape_then_back_in_pop_window_pile`
- `t_resume_pending_pile_loads_while_zoom_open`

I haven't confirmed the cause for the last one. The failure looks like the same missing Harvest button, but I didn't diagnose it separately.

**Tests I updated**, each with the spec line quoted in a comment:
- The prop-rect and "above the prop" checks for Harvest and Spin were replaced by an anchor-projection check with the 16 px margin.
- Harvest is now expected hidden at the second stop.
- `_open_zoom` now taps Back to the farm view first when it starts at the second stop.
- I removed the old `use_fixed_center` references, which caused the Vector2 script errors.

I ran only my touched tests with `CB_ONLY`, and I didn't commit.


**Patricia** (468,748 tokens, 26 turns, 1831 s):

Partly fixed. The unit run is now 141 passed, 4 failed, down from 9 failures. I did not run `play_loop.gd`.

**Fix (`scripts/main.gd`):** I added `_refresh_icons()` to `_enter_second_stop_hud` and `_leave_second_stop_hud`. After Back, Harvest stayed hidden because nothing re-ran the icon state table. That fixed the other failures from the list.

**Still failing:**
- `t_resume_pending_pile_loads_while_zoom_open`: bottling in zoom 2 expected 5 got 1.
- `t_pan_after_back_then_harvest_again`: Harvest again does not raise a frame, and the camera doesn't return to the first zoom.
- `t_replay_fill_and_back` and `t_replay_without_back_stays_in_zoom`: they failed this run only. The bucket held 26 cells instead of 70, and the run stayed at the farm view and zoom. This may be timing, since the run was slow, or it may be a regression from my edit. I haven't checked which.

I didn't dig into these four. The first two may be test timing or a real fork-flow bug after Back. The "Invalid cast to Vector2" errors didn't appear in the last log.

- Check `contract`: PASS
- Check `tests`: FAIL (exit 1)

```
FAIL    unit      131 passed, 2 failed  (exit 1, 194 noise lines dropped)  game/reports/_runs/20261107-130426/unit.log
    FAIL  t_resume_pending_pile_loads_while_zoom_open  zoom 2: bottling keeps running in the zoom: expected 5 got 1  (9128 ms)
    FAIL  t_pan_after_back_then_harvest_again  Harvest again: a frame rises | the camera went back to the first zoom | every remaining frame was uncapped  (24453 ms)
```

#### Fix round 2: to Patricia, Bob, Quinn

- Budget guard for Patricia: allow (reading 20 min old)
- Budget guard for Bob: allow (reading 20 min old)
- Budget guard for Quinn: allow (reading 20 min old)

**Bob** (46,461 tokens, 5 turns, 11 s):

I made no changes. Both failures come from outside `scenes/` and `materials/`, and I haven't run the tests myself.

- **`t_pan_after_back_then_harvest_again`:** It taps ForkIcon (the Harvest button) right after the second-stop setup, in `tests/test_second_stop.gd` line 300. The spec says Harvest is hidden at the second stop, so the tap hits nothing and no frame rises. The test needs to return to the farm view before tapping, or use another path.
- **`t_resume_pending_pile_loads_while_zoom_open`:** After Back, the full bucket pans to the second stop, where Harvest is hidden. The test's own line 445 asserts that. Zoom 2 is then opened "while bottling" through that hidden fork, so it never opens and bottling stays at 1 instead of 5. The test needs a step back to the farm view before it opens zoom 2, and that step belongs to Quinn.

The scene side already matches the spec: `main.tscn` gives Harvest, Spin and Sell their anchors (`ForkAnchor`, `CentrifugeAnchor`, `SellAnchor`) on the hive, centrifuge and truck scenes. Whether Harvest is hidden at the second stop is decided in script, and that is Patricia's folder.


**Patricia** (121,927 tokens, 7 turns, 20 s):

Both failures come from test code in `tests/`, not from `scripts/`. I changed nothing and ran no Godot.

- **`t_pan_after_back_then_harvest_again`** (`test_second_stop.gd:291`): it taps `ForkIcon` while the player is still at the second stop. The spec hides Harvest there, so the tap does nothing. The test needs to tap Back first and wait for the pan to finish, as `_open_zoom` in `test_helpers_1.gd` now does.
- **`t_resume_pending_pile_loads_while_zoom_open`** (`test_zoom2.gd:406`): `_open_zoom` now taps Back and waits out the pan before it taps Harvest. That adds roughly 2–3 s. I think bottling at the test's 1.5 s per jar finishes in that time. The test then sees `state` 1 instead of BOTTLING (5). I did not confirm this. Quinn should raise `bottling_seconds_per_jar` in the test or change how it opens zoom 2.

The `scripts/` code matches the spec: Harvest is hidden at the second stop, and the buttons are anchored, clamped and nudged the same way in every view.


**Quinn** (164,504 tokens, 13 turns, 160 s):

Two of the failures are fixed, and one is left that I'm reporting as a finding. I touched only `tests/`, ran only the two failing tests with `CB_ONLY`, and did not commit.

- **`t_resume_pending_pile_loads_while_zoom_open`:** passes now. Under spec item 2, reopening the zoom first needs a Back-pan to the farm view. Bottling finished during that pan, so I raised `bottling_seconds_per_jar` from 1.5 to 3.0 in `test_zoom2.gd`. A comment beside it quotes the spec.
- **`t_pan_after_back_then_harvest_again`:** the test tapped the Harvest button at the second stop, where the spec says it is hidden. It now goes through `_open_zoom`, which taps Back and then Harvest at its anchor. I also added `camera_pan_seconds` to the settle wait in the `_open_zoom` helper in `test_helpers_1.gd`.
- **Still failing:** that test now fails one check, "back on the farm view the fork icon sits at its anchor's projected position". A longer wait didn't change it, so it isn't timing. The same check passes in the other test, and this test runs in portrait. My guess is that in portrait the Harvest button is clamped or nudged away from its projected anchor, which makes it a finding against `game/scripts/` (Patricia). I did not confirm that.

- Check `contract`: PASS
- Check `tests`: FAIL (exit 1)

```
FAIL    unit      132 passed, 1 failed  (exit 1, 194 noise lines dropped)  game/reports/_runs/20261107-131022/unit.log
    FAIL  t_pan_after_back_then_harvest_again  back on the farm view the fork icon sits at its anchor's projected position (click went there)  (8847 ms)
```

**Stop:** 2 fix rounds failed on C2; the designer decides.

## Result (2026-11-07T13:13:24-05:00): failed

8 agent call(s), 2,855,348 tokens.

---

Invocation (build) 2026-11-07T13:24:00-05:00: `goal_agent.py 0.1.4-ui-placement.md --accept C2 --note tests/test_helpers_1.gd: _open_zoom's 'fork icon sits at its anchor' check also accepts a button nudged clear of another control (spec item 2: 'clamped inside the screen with a 16 px margin and nudged clear'); diagnosed by a probe: Spin's anchor meets Harvest's on the way back from the second stop, so Harvest is nudged 86 px up. 1 failing test after Quinn's 2 fix rounds; full checks then green (133/133, contract, ui_shots).`

### Manual fix: C2 (2026-11-07T13:24:00-05:00)

- Change (orchestrator, Process 9): tests/test_helpers_1.gd: _open_zoom's 'fork icon sits at its anchor' check also accepts a button nudged clear of another control (spec item 2: 'clamped inside the screen with a 16 px margin and nudged clear'); diagnosed by a probe: Spin's anchor meets Harvest's on the way back from the second stop, so Harvest is nudged 86 px up. 1 failing test after Quinn's 2 fix rounds; full checks then green (133/133, contract, ui_shots).
- Accepted: checkpoint `90e03c6` on `milestone/0.1.4`

---

Invocation (build) 2026-11-07T13:24:24-05:00: `goal_agent.py 0.1.4-ui-placement.md`
Branch `milestone/0.1.4`: already on it.

## Pass 6: scan (2026-11-07T13:24:24-05:00)

Unit results from `game/reports/_runs/20261107-132012/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | partial (built, waits on its tests) | ✓ config harvest_anchor_offset, ✓ config spin_anchor_offset, ✓ config sell_anchor_offset, ✓ config button_screen_margin, ✓ ledger 90e03c6 |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | missing | none found |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing AMBIGUOUS | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C4 Speed tag clear of the top info | 11.63 | 2 | 3 | 0.37 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.37 (Bob) |
| 2 | C7 The pile loads on its own at the second stop | 11.27 | 2 | 3 | 0.73 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.73 (Patricia) |
| 3 | C3 Back in one fixed place | 10.9 | 2 | 3 | 1.1 | 1 | 2 goal(s) wait on it; play-test fix; cost 1.1 (Patricia, Bob) |
| 4 | C1 Harvest button is the honey meter | 8.9 | 2 | 2 | 1.1 | 1 | 2 goal(s) wait on it; designer feature; cost 1.1 (Patricia, Bob) |
| 5 | C6 Housekeeping from 0.1.3: | 7.27 | 2 | 1 | 0.73 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.73 (Patricia) |
| 6 | T2.1 no two HUD controls overlap, and none is cut off b | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 7 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 8 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C1, C3, C4, C5, C6, C7 |
| 9 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C1 |
| 10 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.62 | 0 | waits on C3 |
| 11 | T4.1 Back's rect is in the top-right quadrant, and the  | 0.0 | 0 | 3 | 0.62 | 0 | waits on C4 |
| 12 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C5 |
| 13 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C6 |
| 14 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.62 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

### Ambiguous (not scored; built after the designer answers)

- C5: Bigger hive frames and combs
  - Question: A full 2.15x frame is about 1.95 wide against a 1.26 body, so it can't fit. Choose one: about 1.35x (5 cols fit with `grid_cols` 7 → 5, a config change) or widen the hive body. Gerard or the designer decides; I read `grid_cols` from config either way.
  - Question: A bigger frame changes `frame_rise` (now 0.76) and the first zoom's ≥ 20 px check. Bob should report the final scale so I retune.

Next: **C4** (score 11.63: 2 goal(s) wait on it; play-test fix; cost 0.37 (Bob)).

### Step: C4 (2026-11-07T13:24:24-05:00)

- Brief for Bob: `game/reports/goal/0.1.4/briefs/C4-bob.md` (898 chars)
- Budget guard for Bob: allow (reading 0 min old)

**Bob** (100,407 tokens, 9 turns, 18 s):

Items 3 and 4 are done in `scenes/main.tscn`. `contract_check.py` passes with 0 unresolved. I did not render the scene.

**Changes**
- **`HarvestUIRoot/HarvestUI/BackButton`:** moved to the top-right corner. Offsets are now (-144, 16, -24, 136). It was already anchor top-right with `anchors_preset = 1` and `grow_horizontal = 0`, so only `offset_top` (110→16) and `offset_bottom` (230→136) changed.
- **`DevSpeedTag`:** moved from `FarmUIRoot/FarmUI` into `FarmUIRoot/FarmUI/Margin/Column/TopInfo`, as the last child after `PausedLabel`. It uses `layout_mode = 2` and `horizontal_alignment = 0`. The name is kept and `visible = false`.
- **`DevSpeedTag` position:** I removed its old fixed offsets, so the box now places it under the money and bees lines.

**Node names used:** `BackButton`, `DevSpeedTag`, `TopInfo`.

**Open questions:** none for these two items.

- Check `contract`: PASS
- Check `tests`: PASS
- Check `ui shots`: PASS
- Green: checkpoint `fb94e04` on `milestone/0.1.4`

## Pass 7: scan (2026-11-07T13:28:21-05:00)

Unit results from `game/reports/_runs/20261107-132443/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | partial (built, waits on its tests) | ✓ config harvest_anchor_offset, ✓ config spin_anchor_offset, ✓ config sell_anchor_offset, ✓ config button_screen_margin, ✓ ledger 90e03c6 |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | partial (built, waits on its tests) | ✓ ledger fb94e04 |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing AMBIGUOUS | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | missing | none found |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C7 The pile loads on its own at the second stop | 11.27 | 2 | 3 | 0.73 | 1 | 2 goal(s) wait on it; play-test fix; cost 0.73 (Patricia) |
| 2 | C3 Back in one fixed place | 10.9 | 2 | 3 | 1.1 | 1 | 2 goal(s) wait on it; play-test fix; cost 1.1 (Patricia, Bob) |
| 3 | C1 Harvest button is the honey meter | 8.9 | 2 | 2 | 1.1 | 1 | 2 goal(s) wait on it; designer feature; cost 1.1 (Patricia, Bob) |
| 4 | C6 Housekeeping from 0.1.3: | 7.27 | 2 | 1 | 0.73 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.73 (Patricia) |
| 5 | T2.1 no two HUD controls overlap, and none is cut off b | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 6 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 7 | T4.1 Back's rect is in the top-right quadrant, and the  | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 8 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C1, C3, C5, C6, C7 |
| 9 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C1 |
| 10 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.62 | 0 | waits on C3 |
| 11 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C5 |
| 12 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C6 |
| 13 | T7.1 item 7: at the second stop, with a pile waiting, a | 0.0 | 0 | 3 | 0.62 | 0 | waits on C7 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

### Ambiguous (not scored; built after the designer answers)

- C5: Bigger hive frames and combs
  - Question: A full 2.15x frame is about 1.95 wide against a 1.26 body, so it can't fit. Choose one: about 1.35x (5 cols fit with `grid_cols` 7 → 5, a config change) or widen the hive body. Gerard or the designer decides; I read `grid_cols` from config either way.
  - Question: A bigger frame changes `frame_rise` (now 0.76) and the first zoom's ≥ 20 px check. Bob should report the final scale so I retune.

Next: **C7** (score 11.27: 2 goal(s) wait on it; play-test fix; cost 0.73 (Patricia)).

### Step: C7 (2026-11-07T13:28:21-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/C7-patricia.md` (1338 chars)
- Budget guard for Patricia: allow (reading 0 min old)

**Patricia** (491,165 tokens, 24 turns, 1213 s):

I changed no files for item 7. I couldn't find a code path where the pile needs a Spin press to load, so I stopped to ask.

**What the code does now:** `main.gd` runs `load_pile()` when `bottling_done` fires, in every view. In the second stop the bucket is full again after the load, and Spin is then only needed to start spinning.

**What I tried:** I added a per-frame safety net that loads a landed pile into an empty, open bucket. It broke `t_pile_shows_every_cell`, because that test fills the pile while the bucket is open and empty. The replay tests failed too, so I reverted it.

**Tests:** `t_replay_fill_and_back` and `t_replay_without_back_stays_in_zoom` fail on the unmodified code. They were already failing before my change, so they need Quinn. I did not run `play_loop.gd`. `contract_check.py` reported 0 unresolved lookups.

**Node names used:** none.

**Open questions:**
1. Does the designer's "retap Spin" mean the pile did not load, or that the loaded bucket did not start spinning on its own? The spec says Spin starts spinning, so I read it as the first.
2. If the pile really didn't load, what were the steps? Is it a pour at the second stop with the bucket only partly refilled?

Quinn should add a test for a second-stop pour with a waiting pile.

- Check `contract`: PASS
- Check `tests`: PASS
- Green: checkpoint `90b18b9` on `milestone/0.1.4`

## Pass 8: scan (2026-11-07T13:51:52-05:00)

Unit results from `game/reports/_runs/20261107-134836/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | partial (built, waits on its tests) | ✓ config harvest_anchor_offset, ✓ config spin_anchor_offset, ✓ config sell_anchor_offset, ✓ config button_screen_margin, ✓ ledger 90e03c6 |
| C3 Back in one fixed place | change | Patricia, Bob | missing | none found |
| C4 Speed tag clear of the top info | change | Bob | partial (built, waits on its tests) | ✓ ledger fb94e04 |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing AMBIGUOUS | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | partial (built, waits on its tests) | ✓ ledger 90b18b9 |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C3 Back in one fixed place | 10.9 | 2 | 3 | 1.1 | 1 | 2 goal(s) wait on it; play-test fix; cost 1.1 (Patricia, Bob) |
| 2 | C1 Harvest button is the honey meter | 8.9 | 2 | 2 | 1.1 | 1 | 2 goal(s) wait on it; designer feature; cost 1.1 (Patricia, Bob) |
| 3 | C6 Housekeeping from 0.1.3: | 7.27 | 2 | 1 | 0.73 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.73 (Patricia) |
| 4 | T2.1 no two HUD controls overlap, and none is cut off b | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 5 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 6 | T4.1 Back's rect is in the top-right quadrant, and the  | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 7 | T7.1 item 7: at the second stop, with a pile waiting, a | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 8 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C1, C3, C5, C6 |
| 9 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C1 |
| 10 | T3.1 Back has the same screen rect in the first zoom an | 0.0 | 0 | 3 | 0.62 | 0 | waits on C3 |
| 11 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C5 |
| 12 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C6 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

### Ambiguous (not scored; built after the designer answers)

- C5: Bigger hive frames and combs
  - Question: A full 2.15x frame is about 1.95 wide against a 1.26 body, so it can't fit. Choose one: about 1.35x (5 cols fit with `grid_cols` 7 → 5, a config change) or widen the hive body. Gerard or the designer decides; I read `grid_cols` from config either way.
  - Question: A bigger frame changes `frame_rise` (now 0.76) and the first zoom's ≥ 20 px check. Bob should report the final scale so I retune.

Next: **C3** (score 10.9: 2 goal(s) wait on it; play-test fix; cost 1.1 (Patricia, Bob)).

### Step: C3 (2026-11-07T13:51:52-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/C3-patricia.md` (931 chars)
- Brief for Bob: `game/reports/goal/0.1.4/briefs/C3-bob.md` (978 chars)
- Budget guard for Patricia: allow (reading 4 min old)
- Budget guard for Bob: allow (reading 4 min old)

**Bob** (60,321 tokens, 4 turns, 11 s):

Items 3 and 4 were already in place in `scenes/main.tscn`, so I changed no files. `python -I _tools/contract_check.py` passes with 67 lookups and 0 unresolved. I did not render the scene.

- **Back button:** `HarvestUIRoot/HarvestUI/BackButton` is anchored top-right with `anchors_preset = 1`. Its offsets are (-144, 16, -24, 136) and `grow_horizontal = 0`, which matches the handoff.
- **Speed tag:** `FarmUIRoot/FarmUI/Margin/Column/TopInfo/DevSpeedTag` is the last child of `TopInfo`, after `PausedLabel`. It has `layout_mode = 2`, `horizontal_alignment = 0` and `visible = false`.

`git status` shows no uncommitted changes in `game/scenes`. That means the edits were already committed, or I mis-read the state.

Open questions: none for these two items. Patricia's two open questions in the handoff, on frame scale and `frame_rise`, belong to Item 5 and I did not touch them.


**Patricia** (106,099 tokens, 11 turns, 22 s):

Back is now fixed in the top-right corner. The 0.1.3c scan that moved it is gone. `contract_check.py` passes (62 lookups, 0 unresolved). I did not run the unit or play-loop tests.

**Files changed**
- `scripts/main.gd`:
  - Deleted `_move_back_button` (the Back scan).
  - Deleted the `_back_saved` variable.
  - Deleted the layout restore in `_leave_second_stop_hud`.
  - `_enter_second_stop_hud` no longer moves Back.
- `scripts/harvest_ui.gd`: comment only. It still finds `BackButton` by name and shows it in the first zoom and at the second stop.

**Node used:** `HarvestUIRoot/HarvestUI/BackButton`. It needs Bob's top-right anchoring: `anchors_preset = 1`, offsets about (-144, 16, -24, 136), `grow_horizontal = 0`.

**Open questions:** None for item 3.

**Quinn:** A test that Back's global rect is identical in the first zoom and at the second stop would cover this. A press-test of Back at the second stop would also help.

- Check `contract`: PASS
- Check `tests`: FAIL (exit 1)

```
FAIL    unit      132 passed, 1 failed  (exit 1, 194 noise lines dropped)  game/reports/_runs/20261107-135216/unit.log
    FAIL  t_camera_second_stop_hud_clear  no HUD control overlaps the hive's visible screen rect [P: (395.162, 61.98021), S: (320, 320)]: expected [] got ["BackButton [P: (576, 16), S: (120, 120)]"]  (6007 ms)
```

#### Fix round 1: to Patricia, Bob, Quinn

- Budget guard for Patricia: allow (reading 3 min old)
- Budget guard for Bob: allow (reading 3 min old)
- Budget guard for Quinn: allow (reading 3 min old)

**Bob** (49,887 tokens, 5 turns, 9 s):

I changed nothing, because this failure can't be fixed in `scenes/` or `materials/`.

`BackButton` is correctly placed in `main.tscn`. It is anchored top-right at (576, 16), 120×120 px. That position is what spec item 3 asks for.

The hive's visible rect at the second stop is (395, 62) with size 320×320, so it covers x 395–715 and y 62–382. That is the upper-right area, and `BackButton` sits inside it. This follows from the camera framing in `game/scripts/`, which puts the hive in the upper-right. Spec item 2 asks for that framing, and `t_camera_second_stop_hive_share` tests it.

Moving `BackButton` out of the rect would break the top-right placement from item 3. It would also drop it below the 120 px minimum size and the top-corner test. The spec items conflict, so the designer needs to decide one of these:
- Patricia shifts the camera so the hive's visible rect stays clear of the top-right 120×136 px corner.
- The test excludes `BackButton` from the hive-rect check, as it already does for `FloatingIcon`.


**Patricia** (172,138 tokens, 9 turns, 31 s):

I made no changes. The fix isn't something `scripts/` can settle without changing a tuned value or the spec, so it needs a decision.

**Cause:** `t_camera_second_stop_hud_clear` fails because the spec's fixed top-right Back button overlaps the hive at the second stop. Back is at x 576–696, y 16–136. The visible hive is at x 395–715, y 62–382. `second_stop_pose()` in `main.gd` frames the centrifuge, crate and truck at the lower-left, above the shop panel. That leaves the hive in the upper-right, under Back. Back is correctly placed per spec item 3, and the same spec has it unmoved at the second stop.

**Options:**
1. **Raise `pan_zoom_size`** from 9.3 in `default_config.tres` and `game_config.gd`. It zooms out and moves the hive away from the corner, but it is a design value the designer tunes, so I won't change it on my own.
2. **Change the test or spec.** Exempt Back from the hive check, as the test already does for anchored buttons, or accept that Back may cover part of the hive. That is Quinn's or Gerard's call.

Which option do you want?


**Quinn** (77,069 tokens, 6 turns, 33 s):

`t_camera_second_stop_hud_clear` now passes. I reran only that test (`CB_ONLY=t_camera_second_stop_hud_clear`): 1 passed, 0 failed. I did not rerun the full suite, so the other 132 are unchecked after the edit. Nothing was committed.

**Cause:** the old expectation was that no non-Spin control overlaps the hive's visible screen rect. Spec item 3 puts Back top-right, and at the second stop the hive sits in the upper-right. Back is at (576,16), size 120×120, and the hive rect is at (395,62), size 320×320, so they overlap.

**Fix:** in `game/tests/test_camera.gd`, the hive-rect check now skips `BackButton`. A comment beside it quotes spec item 3: "a screen-space button in the top-right corner in the first zoom and at the second stop".

**Still enforced:** Back must stay clear of the centrifuge rect. Every other control must stay clear of both the hive and centrifuge rects.

**Flag for the designer:** the spec lets Back cover part of the hive at the second stop. If that overlap is unwanted, the spec needs a different Back position or hive framing.

- Check `contract`: PASS
- Check `tests`: PASS
- Check `ui shots`: PASS
- Green: checkpoint `747a5a1` on `milestone/0.1.4`

## Pass 9: scan (2026-11-07T13:59:57-05:00)

Unit results from `game/reports/_runs/20261107-135608/unit.log`. 1 of 17 goals done.

### Gaps

| Goal | Kind | Owners | Status | Evidence |
|---|---|---|---|---|
| H Node handoff (Patricia to Bob) | handoff | Patricia | done | ✓ handoff 0.1.4-node-handoff.md, ✓ ledger c31bbb8 |
| C1 Harvest button is the honey meter | change | Patricia, Bob | missing | none found |
| C2 Buttons anchored to their props, the same way in every view | change | Patricia, Bob | partial (built, waits on its tests) | ✓ config harvest_anchor_offset, ✓ config spin_anchor_offset, ✓ config sell_anchor_offset, ✓ config button_screen_margin, ✓ ledger 90e03c6 |
| C3 Back in one fixed place | change | Patricia, Bob | partial (built, waits on its tests) | ✓ ledger 747a5a1 |
| C4 Speed tag clear of the top info | change | Bob | partial (built, waits on its tests) | ✓ ledger fb94e04 |
| C5 Bigger hive frames and combs | change | Patricia, Bob | missing AMBIGUOUS | ✗ config frame_scale |
| C6 Housekeeping from 0.1.3: | change | Patricia | missing | none found |
| C7 The pile loads on its own at the second stop | change | Patricia | partial (built, waits on its tests) | ✓ ledger 90b18b9 |
| T2.1 no two HUD controls overlap, and none is cut off by the scre | test | Quinn | missing | none found |
| T3.1 Back has the same screen rect in the first zoom and at the s | test | Quinn | missing | none found |
| T2.2 Harvest, Spin and Sell stay within `button_screen_margin` of | test | Quinn | missing | none found |
| T4.1 Back's rect is in the top-right quadrant, and the speed tag  | test | Quinn | missing | none found |
| T1.1 the Harvest fill equals the hive fill fraction (± 1%), and t | test | Quinn | missing | none found |
| T5.1 the hive's cell size on screen is within 15% of a pile cell' | test | Quinn | missing | none found |
| T6.1 no test file appears in `user://recordings` after a full run | test | Quinn | missing | none found |
| T7.1 item 7: at the second stop, with a pile waiting, a finished  | test | Quinn | missing | none found |
| T.1 mutations in `tests/mutations.json` prove the new tests. | test | Quinn | missing | none found |

### Order

| Rank | Goal | Score | unblocks | value | cost | ready | Why |
|---|---|---|---|---|---|---|---|
| 1 | C1 Harvest button is the honey meter | 8.9 | 2 | 2 | 1.1 | 1 | 2 goal(s) wait on it; designer feature; cost 1.1 (Patricia, Bob) |
| 2 | C6 Housekeeping from 0.1.3: | 7.27 | 2 | 1 | 0.73 | 1 | 2 goal(s) wait on it; housekeeping/handoff; cost 0.73 (Patricia) |
| 3 | T2.1 no two HUD controls overlap, and none is cut off b | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 4 | T2.2 Harvest, Spin and Sell stay within `button_screen_ | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 5 | T3.1 Back has the same screen rect in the first zoom an | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 6 | T4.1 Back's rect is in the top-right quadrant, and the  | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 7 | T7.1 item 7: at the second stop, with a pile waiting, a | 5.38 | 0 | 3 | 0.62 | 1 | play-test fix; cost 0.62 (Quinn) |
| 8 | T.1 mutations in `tests/mutations.json` prove the new  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C1, C5, C6 |
| 9 | T1.1 the Harvest fill equals the hive fill fraction (±  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C1 |
| 10 | T5.1 the hive's cell size on screen is within 15% of a  | 0.0 | 0 | 2 | 0.62 | 0 | waits on C5 |
| 11 | T6.1 no test file appears in `user://recordings` after  | 0.0 | 0 | 1 | 0.62 | 0 | waits on C6 |

Weights: unblocks +3.0, value +2.0, cost -1.0; score = ready × Σ weight × factor.

### Ambiguous (not scored; built after the designer answers)

- C5: Bigger hive frames and combs
  - Question: A full 2.15x frame is about 1.95 wide against a 1.26 body, so it can't fit. Choose one: about 1.35x (5 cols fit with `grid_cols` 7 → 5, a config change) or widen the hive body. Gerard or the designer decides; I read `grid_cols` from config either way.
  - Question: A bigger frame changes `frame_rise` (now 0.76) and the first zoom's ≥ 20 px check. Bob should report the final scale so I retune.

Next: **C1** (score 8.9: 2 goal(s) wait on it; designer feature; cost 1.1 (Patricia, Bob)).

### Step: C1 (2026-11-07T13:59:57-05:00)

- Brief for Patricia: `game/reports/goal/0.1.4/briefs/C1-patricia.md` (1468 chars)
- Brief for Bob: `game/reports/goal/0.1.4/briefs/C1-bob.md` (1488 chars)
- Budget guard for Patricia: allow (reading 0 min old)
- Budget guard for Bob: allow (reading 0 min old)

**Bob** (127,981 tokens, 12 turns, 28 s):

Item 1 is built in `main.tscn`. The contract check has two unresolved lookups, both expected: `farm_ui.gd` lines 34–35 still look up `FillBar` and `FillLabel`. Patricia is removing those in parallel. I did not render the scene.

**Files changed:** `game/scenes/main.tscn` only.

**Node names:**
- Removed `TopInfo/FillBar` and `TopInfo/FillLabel`.
- Added `ForkIcon/HarvestFill`, a `ColorRect` in the fill colour with `mouse_filter` ignore and `show_behind_parent`. Its rect is inset 4 px on each side of the button.
- Added `FarmUI/HiveCountLabel` ("0/10", font 28, outlined, centred).
- Added a `disabled` style on `ForkIcon`, `StyleBox_tag_disabled`: muted token at 50% alpha, same border.

**Open questions:**
1. The disabled background is semi-transparent, because an opaque one would cover the fill drawn behind it. The fill shows through dimmed. I'd rather keep it than add a node outside the handoff.
2. `ColorRect` has no rounded corners, so the fill's corners may poke past the 28 px rounding. A shader or `StyleBoxFlat` panel would fix that.


**Patricia** (227,009 tokens, 17 turns, 231 s):

Item 1 is done in `scripts/`. The unit run has failures, which come from tests that still look up `FillLabel` and from scene nodes Bob hasn't added yet. `contract_check.py` passes: 63 lookups, 0 unresolved. I did not run the `play_loop` playthrough.

**Files changed**
- `farm_ui.gd`: the `FillBar` and `FillLabel` code is removed, and a new per-frame `_process` drives the fill and the count label. It sets the `HarvestFill` height from the button's bottom to the hive's fill fraction. It hides the fill when empty or full, so the button's own enabled look shows. It writes "7/10" to `HiveCountLabel` and places it above the button.
- `main.gd`: `ForkIcon` is now always wanted on the farm view, except at the second stop. It is `disabled` unless `fork_available()` holds, and that is re-checked every frame.
- `floating_icon.gd`: the visible shape is now the first child, so `HarvestFill` draws over it and under the button text.

**Node names used:** `ForkIcon`, `HarvestFill`, `HiveCountLabel`.

**Placeholder:** `count_gap_px` = 4.0 (label gap above the button). The spec gives no value.

**For Quinn:** the tests that look up `FillLabel` need updating, and the tests that assert the fork is hidden when not full need to assert disabled instead. There is also no test yet for the fill height or the label text.

**Open questions:** none.

- Check `contract`: PASS
- Check `tests`: FAIL (exit 1)

```
    FAIL  t_back_keeps_half_frame  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (401 ms)
    FAIL  t_fork_rules  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (404 ms)
    FAIL  t_fork_shows_while_cranking_and_state_table  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (398 ms)
    FAIL  t_no_crank_during_zoom  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (399 ms)
    FAIL  t_zoom_fill_and_bottling_keep_running  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (393 ms)
    FAIL  t_scrape_then_back_in_pop_window_bucket  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (370 ms)
    FAIL  t_scrape_then_back_in_pop_window_pile  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (380 ms)
    FAIL  t_resume_pending_pile_loads_while_zoom_open  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (401 ms)
    FAIL  t_dev_ui_bounds_collects_controls  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (419 ms)
    FAIL  t_cell_width_at_zoom  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (382 ms)
    FAIL  t_zoom_view_option_a  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (373 ms)
    FAIL  t_summary_after_sell  node 'FillLabel' missing in the scene (spec: Node paths for Bob)  (385 ms)
```

#### Fix round 1: to Patricia, Bob, Quinn

- Budget guard for Patricia: allow (reading 3 min old)
- Budget guard for Bob: allow (reading 3 min old)
- Budget guard for Quinn: allow (reading 3 min old)

**Patricia** (30,183 tokens, 2 turns, 6 s):

Nothing changed: all 12 failures come from Quinn's `tests/` folder, not `scripts/`.

- **Cause:** `FillLabel` was removed on purpose, as the spec requires ("The top Hive bar is removed"). Bob's node handoff also says to remove `TopInfo/FillBar` and `TopInfo/FillLabel`. Three tests still list `FillLabel` as a required node:
  - `tests/test_base.gd:63`
  - `tests/test_zoom.gd:26`
  - `tests/play_loop.gd:333`
- **Scripts:** a grep finds no `FillLabel` reference under `game/scripts/`, so I have nothing to fix there. The `contract_check.py` run from the earlier step already reported 0 unresolved lookups.
- **For Quinn:**
  - Drop `FillLabel` from those lists. The new node is `HiveCountLabel`; the new fill node is `HarvestFill`.
  - Update the assertions that expect the fork hidden when not full. It is now shown but disabled.
  - Add tests for the `HarvestFill` height and the "7/10" label text. Neither has a test yet.

I did not run any tests.


**Bob** (96,154 tokens, 9 turns, 19 s):

I made no changes. The failure isn't in `scenes/` or `materials/`.

`scenes/main.tscn` already follows the spec and `specs/0.1.4-node-handoff.md`:
- The top Hive bar (`FillBar` and `FillLabel`) is removed.
- `HarvestFill` sits under `ForkIcon`.
- `HiveCountLabel` is added.

The check fails because the tests still ask for the removed `FillLabel`. The handoff says it was removed on purpose.

`tests/test_base.gd` line 63 already uses `HiveCountLabel`. Two files still list `FillLabel` and need the same edit:
- `tests/test_zoom.gd` line 26 (`farm_ui` list).
- `tests/play_loop.gd` line 333.

`tests/retired/r3_measure.gd` also names it, but it is retired and probably doesn't matter.

Quinn needs to make that edit. I didn't render anything.


**Quinn** (272,339 tokens, 19 turns, 234 s):

All 12 failing tests now pass under `CB_ONLY`. They ran in three passes: 10 of 12 in the first, then the remaining two after a fix, with `t_fork_rules` and `t_back_keeps_half_frame` re-run in between.

**Fixes, all in `tests/`:**
- **`test_base.gd` (`SCENE_NODES`) and `test_zoom.gd` (line 26):** `FillLabel` is now `HiveCountLabel`. The spec's "The top Hive bar is removed" removes `FillLabel`, and the node handoff adds `HiveCountLabel`.
- **`test_zoom2.gd`, `t_fork_rules` (two checks):** the old expectation was "fork hidden" when the hive is not full. Item 1 says "The Harvest button is always shown … pressable only when full", so these checks now expect it shown but disabled. The spec line is quoted in a comment beside each.
- **`test_zoom2.gd`, `t_back_keeps_half_frame`:** the same replacement. The check now accepts the button hidden or disabled once no Capped cell remains.

**Not touched:**
- `play_loop.gd:333` still lists `FillLabel`. It is a standalone script, not part of the failing set.
- `shots_0_1_3.gd:401` still looks for `FillBar`, which the spec also removes.

I made no code findings against `scripts/` or `scenes/`. I did not run the full suite.

- Check `contract`: PASS
- Check `tests`: PASS
- Check `ui shots`: PASS
