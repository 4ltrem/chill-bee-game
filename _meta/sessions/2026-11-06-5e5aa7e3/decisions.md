---
session: 5e5aa7e3-8b7d-4ea5-a386-6a4355bfda24
dates: 2026-11-06 to 2026-11-06
transcript: session.jsonl (this folder, gitignored)
description: decision IDs out of date order on the decision page; renumbered D98-D106, Toronto dates, numbering rule
---
# Decisions: session 5e5aa7e3 (2026-11-06 to 2026-11-06)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D114 · 2026-11-06 · Records & deliverables · Decision IDs follow time; dates are Toronto dates
- What broke: on the decision page, D106 (Vera scores every asset) sat in Thursday's card between D101 and Friday's D107, and D100 (11/6) came before D101 (11/5).
- How noticed: the designer saw D106 out of line with D105 and D107 in the Thursday card.
- Cause: session 29b33c17 ran Thursday 18:40 to Friday 03:20 Toronto. At end of day its decisions were numbered in the order they were written into the log, not the order they were made; the page sorts by date, then ID, so the IDs zig-zagged across the two cards. The dates themselves were right in Toronto time (the Vera request was 02:51 UTC = 21:51 Thursday).
- How fixed: D98-D106 renumbered by each decision's first decision moment in the transcript (old → new: 101→100, 106→101, 104→102, 105→103, 100→104, 102→105, 103→106); Faster QA and Edit lines redated 11/5 (first asked Thursday evening, approved partly after midnight). Citations updated in both sessions' Still open, the cbb6da0e log and the 0.1.4 spec; old commit messages keep the old numbers.
- Prevention: the end-of-day skill now numbers decisions by when they were made and dates them in Toronto (America/Toronto) time, never UTC; `decision_page.py` warns when an ID is lower than one dated before it.
- Rejected: UTC dates. Transcripts store UTC, but a day card is the designer's working day; evening work would land on the next day.
- Files: `_meta/sessions/2026-11-05-29b33c17/decisions.md`, `.claude/skills/end-of-day/SKILL.md`, `_tools/decision_page.py`, `game/specs/0.1.4-ui-placement.md`

## Still open

- **Build M3 in a fresh session after the weekly reset (Sat 11/7 9:00 Toronto):** `_tools/goal_agent.py` scan/gaps/priority_score with tests, then `--plan` on 0.1.4 for the designer, `--dry-run`, then the real run building 0.1.4 on `milestone/0.1.4` in the main folder; upload 0.1.4 to itch; write `GOAL_AGENT.md`. A5 due 11/15, 11:59 ET.
- `build.py`'s web smoke test: the 100 s wait still shows the loading spinner; it matters now, since 0.1.4 goes on itch.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 × 18, so the zoom shows no sky around the diorama; about 14 × 14 would bring the floating look back.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
- Budget guard: reworked on 2026-11-05 (D95); confirm the 80% complaint is resolved.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged. Session 29b33c17 was re-exported today for the same reason.
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" → "six" word change in `STYLE_GUIDE.md`.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- `content/onboarding-script.md`: narrative and onboarding come later; it needs the guide signature-lines revision and the new harvest flow.
- Guide character playtest: Melli, Pip, Lady Aura or Miel (D46).
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- Content follow-ups: a Sunny Meadow flower for the bumble bee visitor (then Journal Entry 3); name Glowbell and Skybloom in `content/biome-intros.md`; the "sweat name" wording.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Push: `main` is ahead of GitHub; push only when the designer says so (D45).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: `git pull`, install or update the `claude` CLI, then the first "end of work day" there sets up its memory folder and the commit gate.
- Learnings file (D92): one record of everything that broke, how it was noticed and how it was fixed; decide where it lives and whether it is kept by hand or built from the decision logs. First worked example: D114 (What broke, How noticed, Cause, How fixed, Prevention).
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `m2/flower-patch`, `ab/centrifuge-by-crate`): delete them, or keep them as history?
