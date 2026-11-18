# Commit history findings (190 commits, all branches, 2026-10-14 to 2026-11-17)

Source: `git log --all` plus `--stat` and `--name-only` counts. Counts are commit counts unless stated.

## 1. Churn and rework

| finding | evidence (hashes, dates) | count |
|---|---|---|
| GDD.md is the most-touched file (design decisions applied one by one, mostly 10-14 and 10-26) | e.g. d59e10f, 82f7d9f, d0bd3fe, 313c587, 9a44fe1, 3079a36, 8ddb97a, 89794bf, a862041, b28be28, 10fcf34 | 43 commits touch it |
| Run log rewritten constantly: agent-runs.md and agent-runs.csv change in almost every working commit | 3195332, 9e9687c, d42874d (log moved to CSV), 2f8ef1e, c66a52e, afec7e1, 616c0c0 | agent-runs.md 42 touches, agent-runs.csv 32 |
| Memory index and session handoff rewritten each session | 2f8ef1e, c66a52e, 868f919, e21bf90, b5c231e, a468036, 2e36631 | MEMORY.md 32, session-handoff.md 31 |
| 0.1.4 lid / hive item 14 took five or more rounds: spec fix line, WIP, re-fix, "recorded fixed with no lid change", vote reversal | 720d42d (hive five frames, 11-08), eb134fe (lid fix line T14.5), e77235a (WIP, 6 unit fails), c2bfdc5 (WIP), d8cefc8 (item 14 done, lid back to voted open pose), 3bb2012 (loop fixes "against repeat failures") | 6 commits; hive.tscn touched 15 times |
| Goal-agent loop was patched after its own runs failed (fixes of the fixer) | 111062a, 91603c2, 35cdf5c, fcde905, eb134fe, 3eb1c7e, b4410cf, 320fdb7, b9f9347, 3bb2012 | 10 goal_agent fix commits within 11-07 to 11-08 |
| Same goal built in more than one commit | C1: b431c26 and a32b0be; C7: 90b18b9 and f6f153a; T.1: 928b711 and 1ee096d; T2.1/T2.2: b65f5e1, 2c464bc | 3 goals with 2 commits, plus T2 pair |
| Generated goal state committed on every goal commit | game/reports/goal/0.1.4/blackboard.md 31 touches; ledger.json 30; gaps.json 30; blackboard.pass.json 22 | 4 files |
| Test and mutation files change with every feature | game/tests/run_tests.gd 30, mutations.json 23, _tools/test_generate.py 24 | 3 files |
| 0.1.2 and 0.1.3 needed repeated passes: tests red then green | 8dc442b, 9514516 (104/110), 92c1119 (110/110); 64a02b0 (WIP tests red), 151d42a (green), b35f92f (WIP 6 red), ad38de7 (green) | 7 commits |
| 0.1.4 spec edited 22 times, 0.1.3 spec 8 times (play-test findings appended repeatedly) | c7261e7, 7d80bd1, 578b761, 036f886, 4861171 | 22 + 8 touches |
| Visual loop for the farm took 3 rounds and ended at max rounds with an open row | ad2d4c5, d802164, d0ebd3e, 3698b62 | 4 commits |
| Decision page redesigned four times in one day | 962bc62, 52f4e84, 6552003, 61d6b45; decision-comb.html changed 21 times | 4 commits |
| Decision IDs renumbered twice to follow time | 5aed8ef (11-05), fd153fa (11-06) | 2 |
| Prototype 0 rework: revision 2 and 3, a regression found | 0c2379b, 16dee73, b8c8d32, dea294f ("lost uncapping pop is a regression"), 13d1c26 | 5 |
| Env-var prefix replaced by CLI flags across scripts | 51b775d, 8011388 on fix/cli-args-not-env-prefix | 2 |
| Reverts | none found; no commit message contains "revert" | 0 |

## 2. Work moved from agents to scripts

| finding | evidence | count |
|---|---|---|
| godot_run, build, mutate, contact_sheet replaced hand-run engine commands, hand-made broken copies and noisy logs (one run dropped 628 engine-noise lines) | cec51db (2026-11-04) | 1 commit, 4 tools |
| mutate.py: named mutations replaced hand-made broken copies; later `--since` and one baseline | cec51db, 7c29298, 3bb2012 | 3 |
| Doc accuracy: sync_docs.py writes the CREW.md agent table; consistency.py plus pre-commit hook refuses mismatches; doc_audit.py runs Doris headless | 7139f12 (2026-11-01), 7fcbedd | 2 |
| Run logging moved to a CSV and a hook script | d42874d, 3bb2012 (log_subagent.py) | 2 |
| Budget guard as a PreToolUse hook instead of the orchestrator watching usage | a1df106, c9a3667 | 2 |
| style_check.py + style_loop.py (script runs checks, Vera judges the rest) | 897daa3, 3698b62, 369da81 | 3 |
| compare_page.py builds the Design Votes page by script | ad2d4c5, 8cf72e1, 040fd0e | 3 |
| ui_shots.py: same screenshot moments across worktrees by script | 040fd0e, 403be4a | 2 |
| goal_agent.py: scan, gaps, priority_score, loop replaced orchestrator routing of build tasks | e5a2a0b, 91603c2, 111062a; 28 commits tagged "goal_agent run" | 28 goal commits |
| Quinn's briefs no longer run tests; goal agent's checks do | b9f9347 | 1 |
| One blackboard format for content, style and goal loops | 037a1a2 | 1 |
| checkpoint.py: WIP commit on milestone branches with last unit counts | 3bb2012 | 1 |
| Test speed: CB_TIME_SCALE, input recorder/replayer, Rex runs scripts | 6fec9b2, 7c29298, 59e11bd, c9a3667 | 4 |
| build.py --serve real-browser web check | 68e774b | 1 |
| voice_check.py runs T5 and T2 by script before Clara; a FAIL skips the Clara call (branch feat/voice-check, not merged) | ff131dc (2026-11-17) | 1 |
| generate.py prints the cap-stop summary (open FAIL rows, owner, rerun command) | a468036 | 1 |
| godot_path.py finds Godot per machine (branch not merged) | 8011388 | 1 |
| Critic check on main: Clara catches all three known errors (66,952 tokens) | 00d0c83 | 1 |

## 3. Remaining mechanical orchestrator work

| finding | evidence | count |
|---|---|---|
| End-of-day commits (export, decisions, page, audit fixes, handoff) | abbe978, 7d04bc6, 877baf2, 37da2f5, f5a0cbd, 57fbe40, 0d34e56, ad1cae9, 7f7a801, fe23e98, 2e36631 | 11 commits (messages match "End of day") |
| "Checkpoint" commits | c9a3667, 7cc4c3f, e21bf90, b5c231e, c2bfdc5, e77235a, b385d39, 948a49e, d8cefc8, b810f31, 044f59b, 68e774b, 6959925 | 14 messages match "checkpoint" |
| Decision-log commits and ID renumbering | 2631d3f, 5aed8ef, fd153fa, 52f4e84, 6552003, 962bc62, 61d6b45 | 7 |
| Handoff, memory and run-log files edited | session-handoff.md 31, MEMORY.md 32, agent-runs.md 42, agent-runs.csv 32, pending-approvals.md 10 | 147 file touches |
| Memory-only commits | 2f8ef1e, c66a52e, 868f919 | 3 |
| Doc syncs and audit fixes | abbe978 ("Doris's three fixes"), fe23e98 ("doc audit fixes"), 0ff43f5, 7139f12, 7fcbedd, 506bb8e | 6 |
| Status-table docs updated: README 20 touches, AGENTS.md 18, team.md 15, game/CONTEXT.md 16, MILESTONES.md 9 | e.g. 44d6344, 4af8e88, 0ff43f5 | 78 file touches |
| Merges done by hand | 6e22681, 82c900d, f426b6c, 88e65cd, ee1da9a, af9776b, 2809a7b | 7 |
| Link fixes | only a "dead-link note" in 0ff43f5; no standalone link-fix commits | 1 mention |

## 4. Designer preferences visible in commit messages

| finding | evidence | count |
|---|---|---|
| "too small": contact sheets keep proportions, take the full row, open full size | 8cf72e1 (2026-11-07) | 1 |
| "back button overlaps instruction text at top": text moves below Back | c7261e7 (2026-11-07) | 1 |
| Approvals of content, guides, specs, docs | 88c0bac (journals, biome intros, Glowbell/Skybloom), 840a021, 4cdcfac (guides), 73c5ac7, eaa8628, ad1cae9 (0.1.4 and M3 specs), aa4e1a3, 37da2f5 (style guide), c9a3667 (STYLE_LOOP), 739b51c (GOAL_AGENT.md as A5 README), ff131dc (seed terms confirmed by the designer) | 11 |
| Rejections | 88c0bac (rejected the Haiku research brief); d8cefc8 (lid back-edge hinge pose voted down, keep open pose) | 2 |
| Picks by vote | 044f59b (spin-r1: C), 42ed176 and ee1da9a (zoom option A), d802164 (rim mark A), 4cdcfac (C5 round 9 pick), 578b761 (Round 8 votes), 040fd0e (Round 7 votes) | 6 |
| Size tolerance ("1.4 deep, fine while jars stay inside") | ad1cae9 body | 1 |
| Play-test findings drive specs | 7cc4c3f, 7d80bd1, 6e22681 ("designer play-tested 0.1.4") | 3 |
| Rules the designer set | 57fc3c4 (one folder), 7c29298 (edit lines only), 7f7a801 (rules as code), 51b775d (no VAR= prefixes) | 4 |
| Decision logs | ad1cae9 (D107-D113), fe23e98 (D170-D199), 2e36631 (D219-D221) | 3 |

## 5. Open threads

| finding | evidence | count |
|---|---|---|
| feat/voice-check has one commit not on main | ff131dc | 1 branch |
| fix/cli-args-not-env-prefix has two commits not on main | 51b775d, 8011388 | 1 branch |
| main is two commits ahead of origin/main (unpushed) | a468036, 2e36631 | 2 commits |
| origin/milestone/0.1.4 is fully merged | merge 6e22681; `main..origin/milestone/0.1.4` is empty | 0 |
| feat/operator (current branch) has no commits beyond main; uncommitted edits to agent-runs, memory files; untracked Godot_v4.2.1-stable_win64.exe/ folder | git status snapshot | 1 |
| A4 grader item (b) built on a branch; other A4 items (cheaper Clara pass with cached facts, more voice rules as hard checks) on the backlog | ff131dc; MEMORY.md future-tbd | partial |
| C5 paused in the second 0.1.4 run | a3b1dbd | 1 |
| Pending approvals (onboarding-script, biome-intros re-approval) | MEMORY.md pending-approvals; not in commits | 2 |
| Godot 4.7.2 upgrade parked until after 11/24 | MEMORY.md future-tbd | 1 |

## Top token-saving candidates

1. **Run-log rows by hook only (agent-runs.md/.csv, 74 touches).** log_subagent.py exists; making rows fully automatic removes the most-edited non-code files.
2. **End-of-day as one script (11 commits).** Export, decision page, link check, commit are mechanical; only the decision log needs judgement.
3. **Generate handoff and MEMORY.md status lines (63 touches)** from git and the run log instead of hand-written prose.
4. **Stop committing generated goal state** (blackboard.md, ledger.json, gaps.json, 30 touches each); commit once per run or gitignore, shrinking diffs agents and Doris read.
5. **Merge feat/voice-check and fix/cli-args-not-env-prefix.** voice_check.py skips Clara calls on T5/T2 failures (a direct token saving); godot_path.py removes per-machine fix-ups.
6. **Apply the 3bb2012 rules earlier (one owner, scope check, keep tests).** Item 14 took six rounds and the loop itself needed ten patches.
7. **Use checkpoint.py by default (14 checkpoint commits, several by hand).** One command, no prose.
8. **Extend sync_docs.py/consistency.py to generate status tables** (README, AGENTS.md, team.md, CONTEXT files, 78 touches), so Doris reads only prose.
