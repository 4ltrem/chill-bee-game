# content - story outlines and Bee Journal text (William, checked by Clara, sourced by Ruth)

One job: turn a story point, lesson or goal into player-facing text that sounds like Chill Bee Game and contradicts nothing in the GDD.

## Inputs
- Working (this run): the designer's request (story point, lesson, goal, or Journal species)
- Working (journal runs): `../research/<slug>.md` and any `-2`, `-3` briefs, Ruth's sourced findings
- Reference (every run): `../GDD.md` (Story Premise & Onboarding, Aesthetic & Tone, Child Safety, Glossary, plus the sections the request touches)
- Reference (every run): `../_templates/content.md`
- Reference (when cited): `../proposals/design/_index.md`, then only the applied proposals it names

Do NOT load: the review folders, `_meta/agent-runs.md`, balance reports, any blackboard (the script hands each agent its slice).

## Process
Run the loop with `python -I _tools/generate.py <slug> --type <type> --request "<text>"`.
0. **Ruth** (journal runs only, unless `--no-research`, e.g. for fictional species): writes `research/<slug>.md`, real-world facts each with a verbatim quote and URL.
1. **William** writes (round 1) or revises (later rounds) `<slug>.md` from `../_templates/content.md`: English, then Canadian French. He does no web research: real-world facts come only from the briefs, a fact no brief supports stays out, and TBD choices are offered as options under Decisions needed. In later rounds his prompt holds only Clara's FAIL rows, and he edits only the flagged lines.
2. The script copies the draft onto the blackboard under `## Round N`: the full draft in round 1, only a diff against the previous round after that.
3. **Clara** is given the request and the full draft (round 1), or her previous verdict and the diff (later rounds). She checks lore, tone and Glossary, child safety and spending, facts and French, and cited sources, confirming each cited quote with WebFetch, and replies with `### Critic, round N`: `VERDICT: PASS` or `FAIL`, a Checked list and a findings table citing the GDD. The script appends it to the blackboard.
4. PASS ends the loop. FAIL sends William back; FAIL rows that ask for a better source go to Ruth first, as a new brief (`-2`, `-3`, ...). After the last round (3 by default) the draft is kept as `needs-review` with Clara's open findings on the blackboard.

If a brief or check shows the GDD itself is wrong about the real world, William leaves the claim out of the text and lists it under "GDD issues"; Clara records it as "(minor) Refer to Gerard (GDD fact)" rather than failing, so the loop does not spend rounds on what only the designer can fix. Each run stops early once it has used `--max-tokens` (default 500,000); a run whose agent call fails is marked `result: failed` and may be replaced by a fresh run. Every agent call is logged to `_meta/agent-runs.md` automatically. `python -I _tools/test_generate.py` tests the script with fake agents (no tokens).

To revise an existing draft (you rejected it, or Clara's rules changed), run `python -I _tools/generate.py <slug> --revise [--request "<your notes>"]`. It opens a new blackboard (`blackboard-2.md`, `-3`, ...) that names the previous run. A journal draft with no brief yet gets one first: Ruth verifies the claims it already makes. With notes, William edits for them first; without, Clara re-checks the draft as it stands and William is called only if it fails. A draft that passes unedited keeps its status; an edited one returns to `draft`.

## The blackboard
`_runs/<slug>/blackboard.md` is the shared record of one run: the request, research briefs used, the full draft in round 1, a diff for each later round, every verdict, and a token table. The script is its controller: it writes every section and hands each agent only the slice it needs in the prompt, so no agent reads the file and nothing on it is re-read turn after turn. It is kept afterwards as the record of what the critic caught.

## Outputs
- `<slug>.md` -> this folder, `status: draft` (critic passed) or `needs-review` (critic still failing); its frontmatter is its provenance (`author`, `type`, `run:` the latest blackboard). Data lives in the frontmatter and prose in the body, never both: the body opens with only the title and the Sources line
- `_runs/<slug>/blackboard.md` -> kept

## Check
The designer reads the draft and sets `status: approved` or `rejected`, and records the ledger fields `decided: YYYY-MM-DD` and `decision: <one-line why>`. Agents never read those fields. A draft citing a research brief cannot be approved until that brief is approved (William may cite draft briefs during a run; Clara verifies every quote either way). Journal facts also need conservation-partner review before launch; anything touching donations or kid mode goes to Connie first.
