---
session: 024e82ee-6bf4-4dd0-9a6a-b84d6cefbdf2
dates: 2026-11-15 to 2026-11-15
transcript: session.jsonl (this folder, gitignored)
description: Handoff brought up to date on the laptop; M3 cap-stop summary built; M4 waits on a push from the other machine
---
# Decisions: session 024e82ee (2026-11-15 to 2026-11-15)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D220 · 2026-11-15 · Workspace & agents · M4 was built on the other machine: push from there, then pull here; don't rebuild it
- Decided: the designer said M4 work "was on my other machine": Flight Endurance, Centrifuge Gearing, Heated Fork, the truck upgrades (with a Design Votes round for the truck with flames, r1 to r3, from 11-10) and the first Bee Journal entry. None of it is on GitHub. "What I have to do is push from the other machine", then pull here and check that the 0.2 spec, the props, the Journal entry and that machine's 11-09 to 11-14 decision logs arrived.
- Why: the laptop's repo stops at 11-08 plus today's A5 commits; rebuilding M4 here would duplicate work and conflict on the pull.
- Files: `_meta/memory/session-handoff.md`

### D221 · 2026-11-15 · Pipeline design · M3 cap-stop summary built in generate.py (D194)
- Decided: "add the cap-stop summary to generate.py", then "commit it": when a content run stops at the token cap, the blackboard's Result and the console list the last verdict's open FAIL rows, each row's owner (Ruth for a Facts source row on a journal run with research on, otherwise William) and the `--revise` re-run command. 2 new tests; `test_generate.py` 63/63. Commit `a468036`.
- Why: the A3 grader's next step, scheduled for M3 in D194.
- Files: `_tools/generate.py`, `_tools/test_generate.py`

## Still open

- **Pull the other machine's work first:** push M4 (and any milestone branch) from the other machine, then pull here. Expect a conflict on `_meta/memory/session-handoff.md`, and possibly on `_tools/generate.py` if that machine also built the cap-stop summary (keep one).
- **Decision IDs and the decision page:** the live page already has D200 to D218 (11-09 and 11-10) from the other machine, so these logs use D219 to D221. If that machine logged more after 11-10, renumber these three after the pull. The page was not republished from the laptop (it would drop D200 to D218); rebuild and republish it after the pull.
- **Other machine's Still open list:** its newest log (D218) has its own Still open list; merge it with this one after the pull.
- **M4 unknowns, to check after the pull:** is the self-driving truck (the automation step) in, and did 0.2.0 go to itch? A7 is due 11/18.
- **Godot on the laptop:** `build.py` and `godot_run.py` hard-code `C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe`, which only exists on the other machine, so no build or game test runs here. Install Godot 4.2.1 on the laptop and make the path configurable (e.g. an env var), or keep building only on the desktop.
- **GitHub repo visibility for A5:** if `4ltrem/chill-bee-game` is private, the grader needs access.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- **Fast tests as the default (L17):** make `godot_run.py` run sped up by default with plain speed opt-in, so the rule can't be missed again.
- **Goal agent:** confirm whether `--goal` still refuses goals that are already done.
- **Build next (D168):** `live.json`, `_tools/watch.py` and the live side pane (D150, D155), then parallel test runs (D151).
- **M4 content in Godot strings** (D194; may be done on the other machine as the first Journal entry); `/goal` wrapping `goal_agent.py` (D195, backlog item 8).
- **spec_lint warnings:** T.1/T.2 ties; items 11, 12, 15, 20 and 22 all touch Spin in the farm view; reword or confirm.
- **Learning gaps:** L21 (orchestrator runs scripts itself) and L24 (commit to `main` from a worktree) are memory rules only, with no code guard.
- **Guide playtest briefs** (D143): briefs for Patricia (a guide switch) and Gerard; playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- Session d82fcc79 changed after its end-of-day commit; check whether it holds decisions not yet logged.
- `content/biome-intros.md` back to draft after the T6 revise; needs re-approval, with the "five checks" to "six" word change in `STYLE_GUIDE.md`.
- `content/onboarding-script.md`: needs the new harvest flow (D154) and the six guides' lines from `content/guides.md`.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Push: `main` is 1 commit ahead of GitHub (`a468036`); push only when the designer says so (D45).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: add D192's three read-anywhere lines to `.claude/settings.local.json` (its memory folder and the commit gate were set up at this end-of-day).
- Old branches kept after merging (`milestone/m2`, `milestone/0.1.3`, `m2/flower-patch`, `ab/centrifuge-by-crate`, now also `milestone/0.1.4`): delete them, or keep them as history?
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
- The old 10-14 and 10-26 sessions on the laptop were exported only today (`2026-10-14-016cbba0`, `2026-10-26-ccbd920a`); their decisions predate the decision logs and are not added.
