---
session: cb26704c-5cfd-4440-a1b4-3c546673eef4
dates: 2026-11-22 to 2026-11-22
transcript: session.jsonl (this folder, gitignored)
description: 0.3.0 play-test feedback into a new 0.3.1 spec (one Shop button, Journal icon, toast queue, Shop tabs, first-time hint); L52 checks against 0.3.0's misses; v0.3.0 tagged; A7 audit given concrete data, charts and a 29-page PDF
---
# Decisions: session cb26704c (2026-11-22 to 2026-11-22)

Paths are from the repository root. "Designer" is the user. Decisions about a single proposal or draft live in that file's `decided:` / `decision:` frontmatter (the ledger); this log holds the process and architecture decisions that have no file of their own.

Format (parsed by `_tools/decision_page.py`): one `### D<n> · <YYYY-MM-DD> · <Topic> · <Title>` heading per decision, then `- Label: text` bullets (`Decided`, `Why`, `Rejected`, `Files`, or any other label); `## Still open` lists what the designer still has to decide.

## Decisions

### D261 · 2026-11-22 · Pipeline design · Play-test fixes of 0.3.0 go in a 0.3.1 spec, not the 0.3 spec
- Decided: the designer's 0.3.0 feedback ("there's a shop button and a + button, and the + button moves in the zoom spin view, the journal is only accessible through the shop screen. we only need the shop button") goes into a new revision spec, `game/specs/0.3.1-playtest-fixes.md` ("add to 0.3.1 spec"). The orchestrator had started a 0.3 item 7 and reverted it. The Habitat pill loses its +; the Shop button is the only way into the Shop; the Journal becomes its own farm-view icon above the Shop button ("Own bee icon"), hidden until thriving; the pill hides in the first zoom and at the second stop ("Hide pill at 2nd stop").
- Why: 0.3.0 stays the built, play-tested state; fixes are a numbered revision, like 0.2.1 after 0.2.0.
- Rejected: Journal icon plus a Shop button; leaving the Journal in the Shop until the UI pass; keeping the sliding pill; hiding all top info at the second stop.
- Files: `game/specs/0.3.1-playtest-fixes.md` item 1

### D262 · 2026-11-22 · Pipeline design · Shop tabs follow the GDD's upgrade trees; empty tabs say "Coming soon"
- Decided: the canvas Shop sheet (`Shop.dc.html`, "Board as drawn") gets its rows by GDD §3 tree: Bees (Tree A) = Swarm, Flight Endurance; Hive (Tree B) = Heated Fork, Centrifuge Gearing, Spigot Flow, Faster Delivery, Auto-Sell; Habitat (Tree C) = Plant wildflower patch; Research and Refinery show one greyed "Coming soon" line. The designer: "nothing for refinery yet look in the gdd for where to put the upgrades". The dim strip above the sheet closes it like any tap outside.
- Why: the GDD places Gearing, Spigot Flow and the truck upgrades in Tree B; the Refinery is the capstone machine and Research is genetics, tiers and Refinery upgrades.
- Rejected: truck rows in Refinery (map A as first drawn), maps B and C; hiding or locking empty tabs.
- Files: `game/specs/0.3.1-playtest-fixes.md` item 3, `_meta/drafts/0.3/spec-edits-after-run.md` edit 2

### D263 · 2026-11-22 · Pipeline design · Toasts wait for the Shop to close; the patch toast is wired
- Decided: toasts queue while the Shop sheet, the Journal panel or a zoom is up and show on the farm view after, one at a time, for `toast_seconds` (4.0, config) ("Wait for Shop close"). The approved `toast_patch_planted` joins the queue ("Show it, same queue"); the last patch shows only the bumble toast, and the victory waits for it.
- Why: the designer saw a message vanish after buying the last patch: the thriving toast played under the full-height Shop. The patch toast had never shown at all: `patch_slots.gd` emits `toast_requested` and nothing connects it.
- Rejected: drawing toasts above the Shop; toasts that stay until tapped; dropping the patch toast.
- Files: `game/specs/0.3.1-playtest-fixes.md` item 2

### D264 · 2026-11-22 · Pipeline design · L52: four checks against 0.3.0's misses, three built now
- Decided: all four fixes approved: (1) `contract_check.py` fails an emitted signal nothing connects (tests count as listeners; the known patch toast in `KNOWN_UNHEARD`, six checked harmless hooks in `HOOKS`); (2) a fact-check pass on specs' claims about existing behaviour; (3) `spec_lint.py` REVIEW pairs of a full-screen item with a timed one (unless it says it waits or draws on top), and goal_agent's `INTERACTION_CHECKLIST` asks for "seen, not just visible" tests; (4) "I assumed" lines as designer stops, and event shots in `ui_shots.py`. Built in-session: (1), the lint and the checklist line. Deferred: the fact-check pass, assumption stops and event shots.
- Why: 0.3.0 was green and still had four play-test misses (L52): a false spec claim about the top info, a toast under an overlay, an unheard signal, an assumption no one surfaced. The 0.3.0 spec's own wrong claim had been copied into the 0.3.1 draft and was corrected.
- Files: `_tools/contract_check.py`, `_tools/spec_lint.py`, `_tools/goal_agent.py`, `_tools/test_generate.py` (95/95), `_meta/learnings.md` L52, `_meta/drafts/0.3/l52-deferred-checks.md`

### D265 · 2026-11-22 · Cost & structure · With heavy agents held, cheap work goes in-session
- Decided: when the budget guard held a general-purpose agent (week 46% with 21% gone), the designer chose option 2: build the script-only parts in this session and leave the agent work for the reset or an override.
- Why: the fact-check pass isn't needed until the 0.3.1 build, and the week must last until 11/28 14:00, the day before A7 and the final.
- Rejected: an hour's override now; waiting with nothing built.

### D266 · 2026-11-22 · Records & deliverables · 0.3.0 accepted and tagged locally, no push or itch yet
- Decided: the designer: "everything is good for 0.3.0 apart from the feedback I gave"; then "Tag only". `v0.3.0` is an annotated tag on `830416b`, the commit the build came from (moved off `5fdec1b`, a docs-only commit by another session).
- Why: a tag marks the shipped state; the push and the itch upload wait for the designer's word.
- Rejected: tag, push and itch now; tag and push.

### D267 · 2026-11-22 · Records & deliverables · The A7 audit gets its numbers from a script
- Decided: the designer read `_meta/drafts/a7/audit.md` ("looks good but we need more concrete data") and picked all four kinds: a per-version table, charts over time, quality numbers, refreshed figures. `_tools/audit_data.py` computes them from git, `agent-runs.csv`, the learnings and the goal boards (no agents) into `_meta/drafts/a7/data.md`, `data/` and `charts/*.svg`; the audit gained §3.6, the §4.1 goal-run table, §4.5, §6.5, the §7.1 chart, L51-L52. A run counts when it ended. Charts use the dataviz reference palette (validated), with every chart's numbers also in a table.
- Why: figures computed by one command can be re-run before the PDF and checked by a grader.
- Files: `_tools/audit_data.py`, `_meta/drafts/a7/audit.md`, `_meta/drafts/a7/data.md`

### D268 · 2026-11-22 · Records & deliverables · The audit PDF is made by headless Edge
- Decided: `_tools/md_to_pdf.py` converts Markdown with the `Markdown` package and prints with headless Edge (A4, page numbers, one page break per top-level section); the audit is 29 pages (more than 20). No new install: pandoc, wkhtmltopdf and weasyprint are absent; Markdown 3.8.2 and Edge were already there.
- Files: `_tools/md_to_pdf.py`, `_meta/drafts/a7/audit.pdf`

### D269 · 2026-11-22 · Pipeline design · The first-time hint: step bubbles up to the first patch
- Decided: 0.3.1 item 4: after Play, a bubble points at the next thing to do (wait, harvest, uncap, spin, crank, sell, shop, plant), driven by game state so leaving mid-way shows the step that fits; it ends at the first patch or on Skip; Dev "Replay hint"; `show_hint` config; in the Shop only `hint_plant` shows, above the sheet. The text comes from a William + Clara content run (`content/first-time-hint.md`, EN/FR, "vous"); the item isn't built before that text is approved.
- Why: A7's gate is a stranger playing within 2 minutes; the welcome screen deliberately says nothing about how to play (`proposals/design/course-ending.md`).
- Rejected: one card at start; a pulse with no text; stopping at the first sale or the first harvest; placeholder text; no skip; a saved "never again" flag.
- Files: `game/specs/0.3.1-playtest-fixes.md` item 4

## Still open

- **0.3.1 build:** say "build" (and allow heavy agents, `budget_guard.py --allow-for 60`, or wait for the 11/28 reset); build the fact-check pass first if possible (`_meta/drafts/0.3/l52-deferred-checks.md`). Item 4 also needs William's `content/first-time-hint.md` run and your approval.
- **0.3.0 push and itch:** `v0.3.0` is local only; push `main` with the tag and upload the web zip to itch as the A7 link, each on your yes.
- **A7 (due 11/29):** the pipeline run video (you record it); re-run `audit_data.py` and `md_to_pdf.py` before submitting; the audit draft's frontmatter still says "first full draft".
- **Unlogged sessions of 11/22:** 2ae0bbb2, 6c4bacf1, 85235484, b80d1f98 and 5fc31e3f (11/23, the patterns guide `5fdec1b`) were exported but not read for a decision log (budget); their decisions are partly in the 0.3 spec and `proposals/design/course-ending.md` frontmatter. Log them in the next session.
- **L52's deferred checks:** the spec fact-check pass, assumption stops, event shots.
- **`godot_run.py` `start` suite** prints PASS but exits 1: the runner reports "no total line" for it (`game/reports/_runs/20261122-011146/`).
- **L47 prevention:** fix-round briefs to ask for a `diag:` line instead of a guess; `checkpoint.py` labels "(unit green)" from the last full run even when the newest run is red.
- **C14** still shows "partial (built, waits on tests)" in the goal scan though it was accepted on 11/21.
- **`t_icons_never_overlap`** now only asserts 0 icons at the second stop (D240): confirm, or ask Quinn for a stronger check.
- **Operator items still open:** item 7's tail (only `ui_compare_shots.gd` reads `--set` overrides; `run_tests.gd` and the windowed suites don't); item 23's plan count (C14, CFG and T.1 not listed).
- **The side pane** (`claude --plugin-dir _tools/live-pane`) has not been loaded in a real session.
- **Roadmap** (`proposals/design/roadmap.md`): questions 3 (watering) and 5 (Connie timing) open; re-layer to build-from-start r2.
- **0.3 UI pass:** ui-screens decisions 2-4 and the skin; canvas boards 2-3 redrawn for Shop + Tools.
- **First `/dream` pass** (D231): the six preferences (A1), the memory cleanup (A2), the `rex-runs-scripts` wording.
- **Operator, Phase 5 proper:** one real multi-step job through `claude --agent operator`, compared with an Opus session (D233).
- **Mutation 25** (second crank dead) still missed: a test for Quinn.
- **Transcripts of 11/20-11/21** were exported but not re-read for that log; D234-D248 come from the handoff.
- **Fast tests as the default (L17):** whether plain speed becomes opt-in is not decided.
- **GitHub repo visibility for A5/A7:** if `4ltrem/chill-bee-game` is private, the grader needs access.
- **Web build browser check:** the smoke shot is still the loading spinner; the real-time wait fix is approved but not built.
- **Item 19 refill speed:** overflow drains back at up to twice the fill rate (the assistant's choice; the GDD is silent). Say if you want the normal rate only.
- **spec_lint warnings** in `0.1.4-ui-placement.md`: T.1/T.2/T.3 ties; reword or confirm.
- **Guide playtest briefs** (D143): briefs for Patricia (a guide switch) and Gerard; playtest Melli, Pip, Lumi, Lady Aura, Miel and Reine Maeve.
- **Onboarding guide** (D125, D144): `ONBOARDING.md` is a draft at the repo root, untracked on purpose; fill Team Tips and Get Started, or drop it.
- **Google activity analysis** (D156): waiting for your Takeout export.
- Run `style_critic_check.py` with Vera's new scores (D101).
- The farm ground is 18 x 18, so the zoom shows no sky around the diorama; about 14 x 14 would bring the floating look back.
- `content/biome-intros.md` (re-run 3 passed) and `content/onboarding-script.md` need the designer's approval; onboarding needs the new harvest flow (D154) and the six guides' lines.
- Crate tiers and long Deep Frames: build once Terry sets the numbers after the economy is defined.
- Harvest TBDs: centrifuge and truck capacity, truck trip time, Long Fork unlock and cost, automation costs.
- Carried from revision 3: the button focus style that keeps disabled buttons gold, the truck crossing the shop corner, rcedit, `dev_mode` off for store builds, Android.
- First upgrade to recommend in onboarding (Worker Swarm Count vs Flight Endurance).
- Gendered French ("petit apiculteur"); emoji in dialogue bubbles.
- Sunny Meadow intro overlaps onboarding: skip it, or show it only after a reset.
- French honey names (*Miel d'Or Sauvage*, ...) as canon in the GDD.
- Android package name (placeholder `com.chillbeegame.app`).
- Finish the backlog note "sync transcripts f..." (the message was cut off).
- Pasting an image into the CLI chat failed ("no image in clipboard"); no fix was decided.
- On the laptop: add D192's three read-anywhere lines to `.claude/settings.local.json`.
- Patricia's Edit tool writes CRLF into `main.gd`; git normalises it on commit.
