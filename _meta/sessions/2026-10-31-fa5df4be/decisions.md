---
session: fa5df4be-6365-415d-bd06-9f0be0bb573b
dates: 2026-10-31 to 2026-11-01
transcript: session.jsonl (this folder)
description: Every decision made in the session that built the content crew, with why, what was rejected, and the files changed
---

# Decisions: session fa5df4be (2026-10-31 to 2026-11-01)

Paths are from the repository root. "Designer" is the user; "Claude" is the main session. Each decision has an id for reference (D01...). Decisions about a single proposal or draft also live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D01 · 2026-10-31 · Workspace & agents · Add every roster agent the GDD names
- Decided: definitions for Patricia, Quinn, William, Bob, Andrew and Martin in `.claude/agents/`, with new shelves `content/`, `audio/`, `game/` (each with a `CONTEXT.md`).
- Why: designer asked to include all agents from the GDD. Content and audio use `draft` → `approved` (they never change the GDD), not `proposed` → `applied`.
- Rejected: waiting for each role's "first real task" (the old roster rule).
- Files: `.claude/agents/*.md`, `content/CONTEXT.md`, `audio/CONTEXT.md`, `game/CONTEXT.md`, `_templates/content.md`, `_templates/audio-list.md`, `_meta/team.md`, `AGENTS.md`, `README.md`.

### D02 · 2026-10-31 · Workspace & agents · Create the Godot project in `game/`
- Decided: Godot 4.2.1 standard build, GDScript, Compatibility renderer, portrait 720×1280, placeholder isometric main scene.
- Why: the GDD targets low-end phones (Compatibility avoids Vulkan problems) and one-handed play (portrait).
- Rejected: Mobile renderer; C# (needs the .NET build, experimental on mobile in 4.2).
- Files: `game/project.godot`, `game/scenes/main.tscn`, `game/.gitignore`, `game/export_presets.cfg`.

### D03 · 2026-10-31 · Workspace & agents · Bench Android and iOS builds
- Decided: keep the Android and Windows presets; stop before the Android SDK and keystore. iOS needs a Mac.
- Open: package name `com.chillbeegame.app` is a placeholder; it cannot change after the first store upload.

### D04 · 2026-10-31 · Pipeline design · No overlap: reuse what already does the job
- Note: Provenance = the frontmatter every output already has (author, type, status, Sources line), per file, not per line item.
- Note: Decision ledger = two new frontmatter fields, `decided:` and `decision:`, written only by the designer and never read by agents; `python -I _tools/index.py --decisions ...` lists them. Six applied proposals backfilled as decided 2026-10-26.
- Note: Blackboard = the only new piece: one per run, kept as history.
- Rejected: a separate `_meta/decisions.md` (would duplicate the status line); per-line-item provenance.

### D05 · 2026-10-31 · Pipeline design · Orchestrate with a Python script calling `claude -p`
- Why: no API key; runnable code meets the assignment's "code that runs" bar.
- Rejected: orchestrating from the Claude Code session (nothing to submit as code).
- Files: `_tools/generate.py`.

### D06 · 2026-10-31 · Pipeline design · The critic is a new roster agent, created by Martin
- Decided: Clara, the Content Critic, on Sonnet. Checks: lore, tone and Glossary, child safety and spending, facts and French. 3 rounds max; still failing → `needs-review`.
- Rejected: Claude writing it directly; reusing Connie (compliance only).

### D07 · 2026-10-31 · Pipeline design · Three outputs: onboarding script, Bee Journal entries, biome intros
- Why: all three are real gaps in the GDD.

### D08 · 2026-10-31 · Critic quality · Tighten Clara, not William, after her empty PASS
- What happened: run 1's draft had a false bee fact ("Without bees, the flowers can't bloom") and a wrong GDD section number; Clara passed it with an empty table.
- Causes: facts check only covered cited facts; she trusted the draft's "no real-world facts" label; a PASS needed no evidence; no check covered citations.
- Decided: check every line for real-world claims, ignore the draft's self-assessment, a required "Checked" list on every verdict, a fifth check for GDD citations.
- Why only Clara: fixing William too would hide whether the critic works.

### D09 · 2026-10-31 · Critic quality · William edits flagged lines only; `--revise` mode
- Decided: William gains Edit and never rewrites a file in revision rounds; `generate.py --revise` reopens an existing draft in a new run (`blackboard-2.md`, ...), with or without designer notes.

### D10 · 2026-10-31 · Critic quality · Prove the loop on a known-bad draft (regression fixture)
- Result: Clara failed it with three findings (bloom fact, "cheapest" upgrade, §9 citation); William fixed exactly those lines; PASS in round 2.

### D11 · 2026-10-31 · Critic quality · "Honey money" line scrapped
- Decided: replace with a first-sale line ("Your very first sale!"); no "honey money" / "argent de miel" anywhere. Applied via `--revise` with designer notes; 3 lines changed.

### D12 · 2026-11-01 · Cost & structure · Diff-only blackboard rounds
- Decided: round 1 copies the full draft; later rounds copy only a diff. Round 2 cost fell ~60% on the next real run.

### D13 · 2026-11-01 · Cost & structure · Frontmatter stays; data in frontmatter, prose in body, never both
- Decided: removed body lines that repeated frontmatter (`**Author:**`, `**Status:**`, `**Request:**`) and the unread `rounds:` field; section 3 of content became "Real-world facts" (URLs only). Same cleanup in the proposal and audio templates; `**Trigger:**` and Andrew's `**Request:**` stay (no blackboard behind them).
- Why: index.py, links.py and generate.py read the frontmatter; the ICM tooling depends on it.

### D14 · 2026-11-01 · Cost & structure · Five pipeline modules before the next runs
- Note: GDD-conflict escalation (a wrong GDD fact is a "(minor) Refer to Gerard" row, not a FAIL loop); test suite in the repo (`_tools/test_generate.py`); token cap (`--max-tokens`, default 500,000); automatic run logging to `_meta/agent-runs.md`; crash recovery (`result: failed`, replaceable).
- Note: The real-heading test exposed a logging bug the scratchpad test had hidden.

### D15 · 2026-11-01 · Bee Journal rules · Real species get real facts; fictional species get invented whimsy
- Decided: real species (Sunny Meadow, Alpine Valley): real-world facts only, sourced. Fictional species (Enchanted Grove, Cloud Gardens): invented, magical, plausible facts; labelled fictional; match the GDD effects; no claims about real bees.
- Note: Applied to `GDD.md` (Bee Journal bullet) and the William and Clara definitions.
- Ledger: record it on `content/bee-journal-magic.md` when approved (`decision: approved; fictional species use invented facts (GDD Bee Journal updated 2026-11-01)`); rejected: a commit-message-only record.

### D16 · 2026-11-01 · Bee Journal rules · Split the Journal into real and fictional runs
- Why: the real run is URL-heavy; a FAIL in one should not re-check the other.

### D17 · 2026-11-01 · Research & blackboard · Research moves to a dedicated agent: Ruth
- What happened: William researching alone took 34 turns and 720k tokens and still overclaimed four facts.
- Decided: Martin created Ruth, the Research Assistant (`research/` shelf, briefs with verbatim quotes, 6 searches / 12 fetches per brief). William and Connie lose web tools and cite briefs; Clara keeps WebFetch (verifying a quote is not research).

### D18 · 2026-11-01 · Research & blackboard · The script hands out blackboard slices
- Decided: no agent reads the blackboard. William gets the open FAIL rows in his prompt; Clara gets the draft or the diff plus her last verdict and replies with her verdict, which the script appends (she lost Edit and is read-only). Prompts go in on stdin (Windows' 32,767-character command-line limit).
- Why: a turn costs ~12,000 tokens before any work, and everything read early is re-counted every turn; the turn count is the real multiplier.

### D19 · 2026-11-01 · Research & blackboard · Draft briefs may be cited during a run; approval is gated
- Decided: a content draft cannot be approved until every brief it cites is approved.

### D20 · 2026-11-01 · Research & blackboard · Journal runs research first; source FAILs go to Ruth
- Decided: `--type journal` runs Ruth before William (skip with `--no-research`); FAIL rows asking for a better source go to Ruth before William edits.

### D21 · 2026-11-01 · Models · Try Ruth on Haiku, with a review rule
- Rule: review after 5 briefs; back to Sonnet if 2 or more caused a source FAIL, or 2 of the first 3, or at once if a wrong fact gets past Clara.
- Break-even reasoning: one source-FAIL round (~170k) costs about three briefs' worth of Haiku savings (~60k each).

### D22 · 2026-11-01 · Models · Generalise it: Model reviews for every agent
- Decided: every model choice is a bet on the check after it; a per-agent table of who catches its mistakes, the rework signal, and where it is recorded. Critics have no check after them, so `_tools/critic_check.py` re-runs Clara on known-bad drafts in `_tools/fixtures/`.
- Files: `_meta/team.md` (Model reviews), `_tools/critic_check.py`, `_tools/fixtures/onboarding-bad.md`.

### D23 · 2026-11-01 · Models · Ruth back to Sonnet after one Haiku brief
- What happened: the brief summarised 8 claims as "all supported" while its own notes called two only "predominately" and "plausible"; Clara failed four; it ignored the template (wrong frontmatter, set its own status, no findings table).
- Why early: the rule's threshold (2 of 3) was not reached, but template failures are a second kind of miss and the assignment was due that night.

### D24 · 2026-11-01 · Critic quality · Clara checks game facts everywhere, including tables
- What happened: two critic checks each caught 2 of 3 known errors, missing a different one each time; "cheapest upgrade" (a price claim in a table) was the weak spot.
- Decided: an explicit Lore rule to check every statement about the game's own facts in dialogue, tables, Sources rows and notes. In reserve: two Clara passes per round, or Opus.

### D25 · 2026-11-01 · Records & deliverables · Borrow tomorrow's tokens
- Decided: keep running while still inside the 5-hour usage window, borrowing the next day's tokens.
- Why: the crew assignment was due that night.

### D26 · 2026-11-01 · Records & deliverables · Crew assignment = the content pipeline, written up in `CREW.md`
- Decided: Ruth, William and Clara plus `generate.py` as the crew; Mermaid diagram and ReadMe in `CREW.md`, linked from `README.md`. Report the critic's miss honestly rather than claim a perfect critic.

### D27 · 2026-11-01 · Records & deliverables · Session export and decision record
- Decided: raw JSONL copy (session + subagents) via `_tools/export_session.py` into `_meta/sessions/<date>-<id>/`, gitignored (holds the account email and everything read); this decision log beside it; a private visual timeline page.
- Note: the agents run by `generate.py` use `--no-session-persistence`, so their own turns are not saved; their record is the blackboards and `_meta/agent-runs.md`.

### D28 · 2026-11-01 · Critic quality · The critic check saves Clara's full reply
- Decided: `_tools/critic_check.py` writes every verdict to `_tools/fixtures/<fixture>.last-verdict.md` and prints its path.
- Why: the first check missed the bloom fact but kept no reply, so the cause could not be diagnosed. The second check, with the reply saved, showed she caught each error at least once across runs (2 of 3 per run, a different miss each time).
- Files: `_tools/critic_check.py`

### D29 · 2026-11-01 · Research & blackboard · Close the research gap with a designer-notes revision
- Decided: revise `content/bee-journal-real.md` with notes to trim every fact to its brief quote, with `--max-tokens 700000`.
- Result: Ruth → William → Clara FAIL (5 rows) → Ruth's second brief → William → Clara PASS. The first end-to-end run of the research path with real agents; 1.17M tokens total processed, 706k of them William re-reading both briefs.
- Files: `content/bee-journal-real.md`, `research/bee-journal-real.md`, `research/bee-journal-real-2.md`, `CREW.md`

### D30 · 2026-11-01 · Records & deliverables · A hook logs Agent-tool runs; scripts log their own
- Decided: a `SubagentStop` hook in `.claude/settings.json` runs `_tools/log_subagent.py`, which reads the subagent's own transcript and appends a row to `_meta/agent-runs.md`. `generate.py` and `critic_check.py` keep logging their own calls.
- Why: Martin's runs went unlogged because the Agent tool bypasses the scripts. A project hook on every `claude -p` call would have double-logged the scripts' runs.
- Rejected: a hook for everything; leaving the notes and analysis to a hook (rows can be automatic, interpretation cannot).
- Files: `.claude/settings.json`, `_tools/log_subagent.py`, `_meta/agent-runs.md`

### D31 · 2026-11-01 · Cost & structure · Log two token measures and never compare across them
- Decided: every row says which measure it uses. *Final context* (the conversation's size at the last call; the Agent tool's figure and all pre-ICM rows) and *total processed* (summed over every call; what the CLI reports). Usage by day is read as an upper bound.
- Why: Martin's run hiring Clara was 39,232 final context but 234,632 total processed. The log had been comparing William's total-processed runs with Gerard's final-context runs, and the day looked over budget only because the budget was calibrated in the other measure.
- Files: `_meta/agent-runs.md`

### D32 · 2026-11-01 · Records & deliverables · Keep every generate.py agent's transcript
- Decided: `generate.py` no longer runs agents with `--no-session-persistence`; it moves each call's transcript into `_meta/sessions/runs/<date>-<slug>-<run>/` and reads its final context from it. The blackboard links the folder.
- Why: the agents' own reasoning was lost, and their rows had only one token measure.
- Rejected: copying (transcripts would pile up in `~/.claude/projects/`).
- Files: `_tools/generate.py`, `_tools/critic_check.py`, `_tools/test_generate.py`

### D33 · 2026-11-01 · Records & deliverables · "End of work day" runs one portable routine
- Decided: the `end-of-day` project skill exports the session, logs the day's decisions here, rebuilds and republishes one cumulative decision page (same link on every machine), runs the checks and commits. Decision logs follow one strict format so `_tools/decision_page.py` can rebuild the page from every session's log.
- Why: the designer works on a desktop PC and a laptop; memories and local files do not travel, the repository does.
- Rejected: one timeline page per session.
- Files: `.claude/skills/end-of-day/SKILL.md`, `_tools/decision_page.py`, `_templates/decision-page.html`, `_templates/decisions.md`, `_meta/sessions/decision-comb.html`, `AGENTS.md`

### D34 · 2026-11-01 · Records & deliverables · Transcripts stay local; decision logs are committed
- Decided: `.gitignore` keeps `session.jsonl`, `subagents/`, `manifest.json` and `_meta/sessions/runs/` out of git; `decisions.md` and the decision page are committed.
- Why: a transcript holds far more than the visible conversation (hidden reasoning, every file and page read, file snapshots, the account email) and adds 2-4 MB per session to git history forever. The designer revisited this and chose to keep transcripts local.
- Rejected: committing transcripts as-is; committing them with the email scrubbed.
- Files: `.gitignore`

### D35 · 2026-11-01 · Records & deliverables · Project memories live in the repo
- Decided: memories moved from `~/.claude/projects/<workspace>/memory/` to `_meta/memory/`; each machine's gitignored `.claude/settings.local.json` points `autoMemoryDirectory` there. The end-of-day skill sets it up on a machine that lacks it.
- Why: memories are project facts, nothing private, and both machines should share them.
- Files: `_meta/memory/`, `.claude/settings.local.json` (local), `.gitignore`

### D36 · 2026-11-01 · Records & deliverables · Defer approvals to the next working day
- Decided: approving the research briefs and the four content drafts waits until the next working day; briefs first.
- Files: `_meta/memory/pending-approvals.md`

### D37 · 2026-11-01 · Records & deliverables · Backlog for the workspace's own tooling
- Decided: record, not start, three items: an episodic memory upgrade, a dream skill that consolidates memories (check the built-in `autoDreamEnabled` first), and a way to sync transcripts between machines.
- Files: `_meta/memory/future-tbd.md`

## Still open

- Approve or reject, briefs first: `research/bee-journal-real.md` (the Haiku brief: wrong frontmatter, overclaiming summary; rejecting it is reasonable), `research/bee-journal-real-2.md`, then `content/bee-journal-real.md`, `content/bee-journal-magic.md`, `content/biome-intros.md`, `content/onboarding-script.md`.
- Guide character: Melli, Pip, Lady Aura or Miel (TBD in the GDD).
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- On the laptop: `git pull`, then the first "end of work day" there sets up its memory folder.
