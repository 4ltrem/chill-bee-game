# Decisions findings: designer preferences and orchestrator work

Sources: the 42 `_meta/sessions/*/decisions.md` files (D01-D221 as logged) and the 44 `Orchestrator (main session)` rows of `_meta/agent-runs.csv`. Transcripts were not read. Work-kind labels below are inferred from each session's decision-log description and turn count, not measured; "unclear" marks where that is not enough. Dates are the session folder's (Toronto) date.

Coverage gaps: no decision log exists for D200-D218 (the other machine's 11-09 to 11-14 work, per D220) nor for the 11-17 and 11-18 sessions. Seven session folders hold no decisions (89a1bbb7, 068bd2f8, 9bbb13ca, 1879c4fd, 2b017ff6, 96b6271f, b9867da8); only 89a1bbb7 has an Orchestrator row.

## Preferences

| preference | evidence (D-ids, dates) | recurrences | already a rule? |
|---|---|---|---|
| Scripts and cheap agents, not orchestrator tokens: run, shot, build and test work goes to scripts or Rex; admin goes to a subagent, never a `/model` switch | D67 (11-04, "scripts before tokens"); D108 (11-06, "the capturing shots routine should be done by a script"); D115 (11-07); D178 (11-08, "rex is supposed to run scripts"); D180 (11-08, "delegate any scripts to rex to keep this session slim"); D97 (Rex hired 11-05) | 6 | |
| Fast test runs: time-scale 6 and only the affected tests while iterating | D91 (11-05, deferred); D102 (11-05); D199 (11-08, "why does it take 15 minutes"; note says approved 11/6 but missed again) | 3 | |
| Edit only the needed lines, no whole-file rewrites | D83 (11-05, "the designer asked"); D103 (11-05); D161 (11-08, hook refuses overwriting an existing file) | 3 | |
| Designer decides by looking: every creative or numerical visual choice becomes a section of the one Design Votes page, with real shots, never a new artifact or browser tab | D71, D82 (11-05, "two separate pages opened in the browser"); D118 (11-07, "hard for me as a human to decide without a visual"); D122, D128 (11-07, page fixes); D124 (11-07); D179, D198 (11-08, "also take before and after of the lid"; Spin per-view values chosen on the page); D109 (11-06) | 9 | |
| Creative or ambiguous choices stop and go to the designer, not to an agent's guess | D71 (11-05, style loop stops); D86, D87 (11-05, V3 and V8 stops); D113 (11-06, "ambiguous goals stop for the designer"); D185/D186 (11-08, "ask don't guess"); D142 (11-07) | 5 | |
| A fix is not done until a code change is committed, and a model change is not done on tests alone | D48 (11-03, owners fix their own work); D159 (11-08, "the style loop should've caught this", hive wrong "second or third time"); D172 (11-08, "this shouldn't have happened, a fix should always be committed"); D123 (11-07, unchanged step counted as built) | 4 | |
| Owners fix their own defects; the orchestrator only makes small certain fixes, and edits during a goal run go in a worktree | D48 (11-03); D173 (11-08); D74 (11-05) | 3 | |
| Do not re-ask or misread what the designer already said: check cast votes and the spec first | D104 (11-06, orchestrator's reading of "zoom in even more" withdrawn); D165 (11-08, "check the votes and ask only if unclear"); D160 (11-08, spec contradictions); D50/D61 (11-03/04, build differs from the designer's own words, a scraped-cell effect cut without asking); D154 (11-07) | 5 | |
| Ask before every push; an earlier yes covers only that push | D45 (11-03, Claude pushed 88c0bac on the old D43 approval); D43 (11-01); D38 | 2 (plus D43 origin) | |
| Run only the routine asked for: "time to close this session" is not "end of work day" | D164 (11-08, designer stopped the routine); D85 (11-05) | 2 | |
| Fewer permission prompts: allow-list repo and Godot commands, no inline python, Linux tools, repo-only becomes write-only | D127, D129 (11-07, "Stop asking me to approve bash commands that run in repo"); D135, D146, D147 (11-07/08); D176 (11-08, "prefer linux tools over powershell"); D192 (11-08, "cant we just replace the cantreadoutsidework with cant writeoutsidework"); D161 | 8 | |
| Visibility of headless agents: status line, live pane, board stream | D120 (11-07); D145 (11-07); D150 (11-07); D155 (11-08, "I need everything visible, also the live pane"); D168 (11-08); D177 (11-08, "yes, log the command and turns") | 6 | |
| Override the budget guard and keep working in the window | D148 (11-07, three renewals); D167 (11-08, "there's still 5h usage left so let's do it all"); D171 (11-08, "about eight overrides since D148"); D25 (11-01, borrow tomorrow's tokens); D183 (11-08, "wait until after the reset", the opposite) | 5 (about 9 individual overrides) | |
| Budget guard must not block early or by peak cost | D68 (11-05, "never happen again"); D91/D95 (11-05, 80% block at 22% left); D187 (11-08, "use average token count run not highest", "no don't lower it") | 3 | |
| Docs must not drift: generate or check facts by script, the designer does not want to check by hand | D39, D40, D41 (11-01); D44 (11-01, misfiled Doris run, stale "Not yet run"); D114 (11-06, IDs out of order, designer saw it) | 5 | |
| Critics must catch what the designer later catches | D8 (11-01, Clara's empty PASS); D24 (11-01); D142 (11-07, "Clara should have caught this"); D159 (11-08, style loop miss) | 4 | |
| Placeholders err slow; every tunable in config; Dev mode in every spec | D56 (11-04, "honey is viscous it wouldn't take .4s per jar"); D57 (11-04); D69, D78 (11-05, x10 and x20 speed) | 4 | |
| Tests come from the spec and must prove something | D49 (11-03, real input, shown failing); D58 (11-04, designer saw tests follow the code); D160/D185 (11-08) | 4 | |
| One folder; worktrees only for parallel work | D110 (11-06, "difficult to navigate the workspace with this worktree stuff"); D74 (11-05); D126 (11-07, drafts stay in the repo) | 3 | |
| Defer non-priority work to a later day or milestone | D36 (11-01); D91 (11-05); D125 (11-07, "defer, onboarding not a priority rn"); D87 (11-05); D183 (11-08) | 5 | |
| Cost review leads to tooling, and the designer reads the cost log | D52 (11-03, orchestrator was 162M vs 11M for agents); D60 (11-04); D67 ("yes build the tools now"); D116 (11-07, trim always-loaded context); D170 (11-08, "look into your memory for the best leverage tasks") | 5 | |
| Play-test notes become spec items with failing-first tests, and every spec item also carries the designer's own wording | D111, D121, D131, D132, D134, D149, D152, D157, D165, D190-D197 (11-06 to 11-08) | about 15 | |

## Orchestrator work

Tokens are `total_processed` and `orch_cache_read` from the Orchestrator rows (M = million). Turns come from the CSV `turns` column. Kinds are R (routing), M (mechanical), J (judgement), W (waiting); inferred from the decision-log description, so treat as rough. No decision log means "unclear" for kinds.

| session | date | tokens (total / cache_read) | main kinds of work | notes |
|---|---|---|---|---|
| fa5df4be | 10-31 to 11-03 | 170.2M / 167.9M | J, R, M | 484 turns. Built the content crew: agents (D01-D54), pipeline design, cost logging, session export, CREW.md. Biggest by far, 23% of all orchestrator tokens. |
| 89a1bbb7 | 11-03 | 0.05M / 0.03M | none | greeting only (log) |
| 864dbfb5 | 11-03 | 11.1M / 10.7M | R, W | Prototype 0 rev 3 and calibration (D55-D61); agents ran the build |
| 5d085f00 | 11-04 | 43.7M / 42.5M | J, R, W, M | Milestones, 0.1 and 0.1.1/0.1.2 revisions, cost tools (D62-D69); Quinn's 0.1 run alone was 22.7M (D67) |
| e0d1da16 | 11-05 | 19.5M / 19.1M | J, M | style guide review, A/B votes, grid (D70-D74) |
| d82fcc79 | 11-05 | 27.4M / 27.1M | J, R, W | 0.1.3 grid and camera, harvest automation, M2 approval, Milo hired (D75-D85) |
| 452ddba6 | 11-05 | 35.6M / 35.1M | R, W, J | M2 built and demoed; two designer stops (D86, D87); the style loop ran agents |
| 1f6110f3 | 11-05 | 3.9M / 3.8M | R, M | flower-patch B on a branch, handoff (D88) |
| 4297b6fb | 11-05 | 6.3M / 6.2M | J, M | why tests were slow; mutate.py fix (D89-D91) |
| 472d224a | 11-05 | 0.9M / 0.8M | M | usage check, end of day, learnings backlog (D92, D93) |
| cbb6da0e | 11-05 | 5.0M / 4.9M | M, R | STYLE_LOOP approval, budget guard, Rex (D94-D97) |
| 29b33c17 | 11-05/06 | 69.0M / 68.4M | R, W, J | 0.1.3 steps b and c, play-test fixes, recorder; 668 turns over about 8.7 h (D98-D106) |
| 49ba7bdd | 11-06 | 23.1M / 22.8M | M, J | merges, play-test, one-folder rule, 0.1.4 and M3 specs (D107-D113) |
| 5e5aa7e3 | 11-06 | 2.4M / 2.3M | M | renumbered decision IDs (D114) |
| a87fa624 | 11-07 | 0.6M / 0.5M | J, M | cost tips, trimmed always-loaded context (D115, D116) |
| 81c6a13d | 11-07 | 58.1M / 57.2M | R, W, J | built the goal agent, ran it on 0.1.4; 622 turns (D117, D118, D120-D122) |
| 360de647 | 11-07 | 15.5M / 15.1M | R, J, M | one blackboard format, Clara's checks, guides (D119, D125; the description also lists D131-D144 content work in 3e77b3cf, unclear which belongs here) |
| f282bdb2 | 11-07 | 4.8M / 4.6M | J, W | what to do while the goal run goes (D123) |
| 60faff60 | 11-07 | 1.7M / 1.6M | W, M | 2.6 h wall time for 48 turns, mostly waiting on the goal run (D124, D126) |
| f02d3df8 | 11-07/08 | 8.0M / 7.7M | M, J | Round 8 page bug, permissions (D127-D130) |
| 3e77b3cf | 11-08 | 35.5M / 35.1M | J, R, M | play-test findings, Round 8/9, six guides, Clara's completeness check (D131-D144); 484 turns |
| 3260c91b | 11-08 | 3.7M / 3.6M | M | live view, allow rules (D145-D147) |
| b89522de | 11-08 | 18.1M / 17.9M | R, W, J | second goal run, items 11-15, repeat-failure fixes (D148-D164) |
| 24feb07b | 11-08 | 1.1M / 1.0M | J | analysis plan, not the game (D156); 13.5 h wall time, 38 turns, mostly idle |
| 29d5fe47 | 11-08 | 15.0M / 14.7M | M, J | guard_shell, spec_lint, pick_match (D161-D166) |
| f42a6ca5 | 11-08 | 8.2M / 8.1M | R, W | third goal run, budget guard override (D167-D169) |
| 28475ef9 | 11-08 | 32.6M / 32.2M | R, W, J | goal-agent blockers, lid fix gates, Rex (D170-D178); 418 turns |
| 4d46525c | 11-08 | 0.8M / 0.8M | unclear | no log; 12 calls |
| 472fd463 | 11-08 | 6.4M / 6.2M | J, W | lid before/after vote, hold for reset (D179-D183) |
| c8303ec0 | 11-08 | 7.3M / 7.1M | R, W | `/goal` loop fixes (D184) |
| c3ac07db | 11-08 | 2.4M / 2.3M | J | Quinn's interaction checklist (D185, D186) |
| 4ccf1614 | 11-09 | 55.5M / 55.1M | R, W, J | play-test items 16-21, guard change; 648 turns (D187, D190-D196) |
| 48828af3 | 11-09 | 4.0M / 4.0M | M | A4 write-up commit and Clara re-run (D188, D189) |
| 8e027381 | 11-09 | 2.1M / 2.1M | J | A3 next steps, `/goal` comparison (D194, D195) |
| 4be1c5ef | 11-09 | 18.0M / 17.8M | R, W | `/goal` fix of play-test notes, Spin votes (D197-D199) |
| bc40915c | 11-15 | 2.9M / 2.8M | M | A5 write-up approved and pushed (D219) |
| 024e82ee | 11-16 | 3.6M / 3.5M | M, R | handoff on the laptop, cap-stop summary (D220, D221) |
| 85a47ddc | 11-16 | 2.4M / 2.3M | unclear | folder has no decisions file |
| a9eea6c7 | 11-17 | 0.7M / 0.6M | unclear | no folder |
| edd56bee | 11-17 | 2.2M / 2.1M | unclear | no folder; 1.6 h wall for 62 turns |
| 2159a8f0 | 11-17/18 | 1.3M / 1.2M | unclear | no folder; 1.9 h wall for 40 turns |
| 963460fc | 11-18 | 0.5M / 0.4M | unclear | no folder |
| a36b22c3 | 11-18 | 2.4M / 2.3M | unclear | no folder |
| 3714d3c1 | 11-18 | 1.6M / 1.4M | this analysis session | row is open at time of writing |

Total across the 44 rows: 735.0M total_processed, of which 722.7M (98.3%) is cache read.

### Ten costliest sessions (75% of all tokens, 550.7M)

| rank | session | tokens | what it mostly did |
|---|---|---|---|
| 1 | fa5df4be | 170.2M | designing the content crew and its records and checks (judgement and mechanical doc work) |
| 2 | 29b33c17 | 69.0M | dispatching Bob, Patricia, Quinn and waiting through 0.1.3 steps b and c |
| 3 | 81c6a13d | 58.1M | building and running the goal agent, with long waits |
| 4 | 4ccf1614 | 55.5M | 0.1.4 play-test items 16-21 through `/goal` and fix rounds |
| 5 | 5d085f00 | 43.7M | milestone planning, build revisions, cost tooling |
| 6 | 452ddba6 | 35.6M | M2 style loop run and designer stops |
| 7 | 3e77b3cf | 35.5M | play-test findings, votes, guide content |
| 8 | 28475ef9 | 32.6M | goal-agent fixes, fix-gating rules |
| 9 | d82fcc79 | 27.4M | 0.1.3 grid, camera and automation design, worktree build |
| 10 | 49ba7bdd | 23.1M | merges, specs, one-folder rule |

### Tally across sessions (inferred)

- Routing and Waiting dominate the expensive sessions: 7 of the top 10 involve dispatching agents or scripts and idling while they ran (29b33c17, 81c6a13d, 4ccf1614, 5d085f00, 452ddba6, 28475ef9, d82fcc79). Every turn resends the whole context (D18, D168), so waiting turns cost like work turns.
- Judgement (design trade-offs, synthesis for the designer) is the main content of fa5df4be, 3e77b3cf, e0d1da16 and the small content sessions. This is the kind that most plausibly stays on Opus.
- Mechanical work (commits, logs, memory and handoff upkeep, end-of-day, doc edits) is the main kind in about 12 small sessions (472d224a, 5e5aa7e3, cbb6da0e, 1f6110f3, 3260c91b, 48828af3, bc40915c, 024e82ee and others), but each is small, together roughly 30M tokens (my sum of the rows listed; not verified).
- Could run on a script: waiting loops (the Monitor/board streaming and `goal_agent.py` already do this; D168), shot and contact-sheet runs (D108, D180), decision numbering and the end-of-day export, checkpoint commits (D184 `checkpoint.py`).
- Could run on Haiku: Rex-style script running (D97, D178, D180), mechanical doc and handoff edits, session-log writing for a closed session (D74 already used a subagent for this).
- Could run on a Sonnet operator: dispatching agents to a written spec, reading boards and relaying stops, merging and checkpointing; the judgement items (votes, design trade-offs, explaining choices) would stay with Opus. Whether this saves tokens versus context hand-off cost is unclear from these logs.

## Other signals

- Cache reads: 722.7M of 735.0M tokens (98.3%). The orchestrator used about 162M against about 11M for all agents combined when first measured (D52, 11-03). Fresh session per milestone and trimmed always-loaded context were the responses (D54, D67, D116).
- Long wall-clock, few turns, so mostly idle: 24feb07b (13.5 h, 38 turns), 60faff60 (2.6 h, 48 turns), edd56bee (1.6 h, 62 turns), 2159a8f0 (1.9 h, 40 turns); from CSV start and end times.
- Hitting the plan limit: an agent hit the 5-hour limit mid-task (D68, 11-05); the day ended at 86% (D92, D93); one prototype batch took a fifth of the window (D60, 11-04); weekly pace overrides about 9 times (D148, D167, D171).
- Costly agent runs: Quinn's 0.1 run 22.7M (D67); William alone 720k tokens on one brief (D17); a fix round of 777k tokens and 36 turns (D168); Quinn's last write step 974k tokens and suite runs at 21% of plan (D178); mutate.py took an hour until fixed (D89); QA rounds up to an hour (D102); full runs 15 minutes (D199).
- Repeated rework on the hive and frame model: wrong "second or third time" (D159), rebuilt against the pick (D157, D163, D169), comb size then hitbox then Dev-config override (D165, D190, D191).
- A fix claimed but not shipped: the lid still clipped after a handoff said "fixed (designer confirmed)"; T14.3 passed on the clipping build (D172); fix-round edits reverted (D174); lid vote and landing rework (D175, D179, D182).
- A step that changed nothing counted as built (C7, D123); line IDs positional so a new test line was credited by another test (D170).
- Tests passing while the game was wrong: first build passed but dragging could not uncap (D49); uncapping pop lost to Bob's light, missed by Quinn (D50); focus style (D61); loose bounds test (D153).
- Votes page defects: Round 8 had duplicate card IDs and broken buttons (D128); round 9 overwrote round 8's scenes (D166); decision IDs out of time order (D114).
- Critic misses: Clara's empty PASS (D8), missing a different known error each run (D24, D28), no completeness check (D142); Ruth on Haiku summarised "all supported" over weak claims (D23, reverted to Sonnet after one brief).
- Doc drift found by the designer: CREW.md wrong in eleven places (D39); Doris's run misfiled and her estimate stale (D44); a README said "nine agents" for twelve (D42).
- Process slips: Claude pushed on a stale approval (D45); the end-of-day routine started on "close this session" (D164); a worktree-heavy layout confused the designer (D110); orchestrator fixed Patricia's and Quinn's bugs unrecorded (D48); a closed session's log was never written until a subagent did it (D74); session d82fcc79 and 29b33c17 changed after their end-of-day commit and needed re-export (listed in Still open of D-logs 11-05 and 11-06).
- Open items repeated unchanged across about ten Still-open lists (guide playtest, harvest TBDs, Android package name, "sync transcripts" note, push ask), which inflates the logs; I skipped them for this analysis.
- Missing logs: no decision log for D200-D218 (other machine, D220) or the 11-17/11-18 sessions, so work in those spans is "unclear".
