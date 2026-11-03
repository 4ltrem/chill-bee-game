#!/usr/bin/env python3
"""Generate one piece of game content with William, check it with the critic, revise until it passes.

    python -I _tools/generate.py SLUG --type TYPE --request "TEXT" [--max-rounds 3] [--max-tokens N]
    python -I _tools/generate.py SLUG --revise [--request "DESIGNER NOTES"] [--max-rounds 3] [--max-tokens N]

Each round: William writes or revises content/SLUG.md from the GDD, and the critic checks it. A
PASS stops the loop with `status: draft` (awaiting the designer); a FAIL after the last round saves
the draft with `status: needs-review`. Agents run through the Claude Code CLI (`claude -p --agent
...`, prompt on stdin), so no API key is needed. Standard library only.

The blackboard (content/_runs/SLUG/blackboard.md) is the run's shared record: the request, the full
draft in round 1, a diff against the previous round after that, and every verdict. The script is
its controller: it hands each agent only the slice it needs in the prompt (William: the open FAIL
rows; the critic: the draft or the diff, plus its previous verdict) and appends what they return.
No agent opens the blackboard, so nothing on it is re-read turn after turn.

Research: for --type journal (unless --no-research), Ruth first writes a brief to
research/SLUG.md (on --revise, verifying the draft's existing claims) and William cites only from
briefs. In later rounds, FAIL rows asking for a better source go to Ruth first, as a new brief
research/SLUG-2.md, -3, ...

--revise starts a new run (blackboard-2.md, -3, ...) on the existing draft instead of a blank one.
With designer notes, William first edits the draft for them; without, the critic checks the
draft as it stands, and William is called only if it fails. William edits flagged lines only.

--max-tokens (default 500,000) is checked after each FAIL: once the run has used that many, no new
round starts and the draft is saved as needs-review. Every agent call is appended to the Content
generation table in _meta/agent-runs.md, with both token measures: total processed (the CLI's
usage, summed over the call's turns) and final context (the conversation's size at its last turn,
read from the call's transcript). Each call's transcript is moved out of ~/.claude/projects/ into
_meta/sessions/runs/<date>-<slug>-<run>/ (gitignored), so runs keep a full record without piling up
there. If an agent call fails, the blackboard is marked `result: failed` and a fresh run may
replace it. Tests: python -I _tools/test_generate.py
"""
import argparse
import datetime
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
from log_subagent import measure  # noqa: E402
import runlog  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
WRITER, CRITIC, RESEARCHER = "writer", "content-critic", "research-assistant"
NAMES = {WRITER: "William", CRITIC: "Critic", RESEARCHER: "Ruth"}
TYPES = ("story", "onboarding", "journal", "ui-text")
LOG_TABLE = "Content generation"
RUNS = Path("_meta") / "sessions" / "runs"
ASKS_FOR_SOURCE = re.compile(r"\bsource|\bcite|citation|\bURL", re.I)


class AgentError(Exception):
    pass


def run_agent(agent, prompt):
    """Run one agent headless with the prompt on stdin; return (reply text, usage summary)."""
    claude = shutil.which("claude")
    if not claude:
        raise AgentError("claude CLI not found on PATH")
    cmd = [claude, "-p", "--agent", agent, "--output-format", "json",
           "--permission-mode", "acceptEdits", "--allowedTools", "WebFetch,WebSearch"]
    started = now_iso()
    proc = subprocess.run(cmd, cwd=ROOT, input=prompt, capture_output=True, text=True, encoding="utf-8",
                          env={**os.environ, "CHILLBEE_HEADLESS": "1"})  # log_session.py skips these
    ended = now_iso()
    try:
        out = json.loads(proc.stdout)
    except ValueError:
        raise AgentError(f"{agent} failed (exit {proc.returncode}): {proc.stderr or proc.stdout}")
    if out.get("is_error"):
        raise AgentError(f"{agent} reported an error: {out.get('result')}")
    u = out.get("usage", {})
    tokens = sum(u.get(k, 0) for k in ("input_tokens", "output_tokens",
                                       "cache_creation_input_tokens", "cache_read_input_tokens"))
    return out.get("result", ""), {"tokens": tokens, "turns": out.get("num_turns", 0),
                                   "seconds": round(out.get("duration_ms", 0) / 1000),
                                   "session_id": out.get("session_id"), "start": started, "end": ended,
                                   "model": out.get("modelUsage") and " ".join(out["modelUsage"]) or ""}


def projects_dir():
    """Claude Code's transcript folder for this workspace, or None."""
    base = Path.home() / ".claude" / "projects"
    name = re.sub(r"[:\\/]", "-", str(ROOT)).lower()
    found = [d for d in base.iterdir() if d.is_dir() and d.name.lower() == name] if base.is_dir() else []
    return found[0] if found else None


def keep_transcript(usage, dest, name):
    """Move a call's transcript into dest/name.jsonl and record its final context in usage."""
    sid, src_dir = usage.pop("session_id", None), projects_dir()
    src = src_dir / f"{sid}.jsonl" if sid and src_dir else None
    if not src or not src.is_file():
        return
    dest.mkdir(parents=True, exist_ok=True)
    target = dest / f"{name}.jsonl"
    shutil.move(str(src), str(target))
    if (src_dir / sid).is_dir():  # tool results the call saved beside its transcript
        shutil.move(str(src_dir / sid), str(dest / name))
    usage["final"] = measure(target)["final"]


def append(path, text):
    with path.open("a", encoding="utf-8", newline="\n") as f:
        f.write(text)


def critic_block(reply, n):
    """The `### Critic, round n` block in the critic's reply, without code fences, or None."""
    m = re.search(rf"^### Critic, round {n}\b.*", reply, re.M | re.S)
    if not m:
        return None
    block = "\n".join(line for line in m.group(0).splitlines() if not line.strip().startswith("```"))
    return block.strip() if verdict_of(block) else None


def verdict_of(text):
    m = re.search(r"VERDICT:\s*\**\s*(PASS|FAIL)", text)
    return m.group(1) if m else None


def verdict(board, n):
    """The critic's VERDICT for round n on the blackboard, or None if it has no block."""
    text = board.read_text(encoding="utf-8")
    block = re.search(rf"^### Critic, round {n}\b(.*?)(?=^#{{2,3}} |\Z)", text, re.M | re.S)
    return verdict_of(block.group(1)) if block else None


def fail_rows(block):
    """The blocking findings rows of a critic block (table rows that are not minor notes)."""
    rows = [line for line in block.splitlines() if re.match(r"\|\s*\d+\s*\|", line)]
    return [r for r in rows if "(minor)" not in r]


def set_front(path, **fields):
    """Set frontmatter fields in a markdown file, adding any that are missing."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        text = "---\n---\n" + text
    end = text.find("\n---", 3)
    front, body = text[3:end], text[end:]
    for key, value in fields.items():
        line = f"{key}: {value}"
        front, n = re.subn(rf"^{key}:.*$", line, front, flags=re.M)
        if not n:
            front = front.rstrip("\n") + "\n" + line + "\n"
    path.write_text("---" + front.rstrip("\n") + body, encoding="utf-8", newline="\n")


def get_front(path, key):
    m = re.search(rf"^{key}:\s*(\S.*)$", path.read_text(encoding="utf-8").split("\n---", 1)[0], re.M)
    return m.group(1).strip() if m else ""


def model_of(agent):
    definition = ROOT / ".claude" / "agents" / f"{agent}.md"
    model = get_front(definition, "model") if definition.is_file() else ""
    return model.capitalize() or "?"


def briefs(slug):
    """Existing research briefs for a slug: research/SLUG.md, then -2, -3, ..."""
    folder = ROOT / "research"
    found = [folder / f"{slug}.md"] + sorted(folder.glob(f"{slug}-[0-9]*.md"),
                                             key=lambda p: int(p.stem.rsplit("-", 1)[1]))
    return [p for p in found if p.is_file()]


def next_brief(slug):
    folder, n = ROOT / "research", 2
    if not (folder / f"{slug}.md").exists():
        return folder / f"{slug}.md"
    while (folder / f"{slug}-{n}.md").exists():
        n += 1
    return folder / f"{slug}-{n}.md"


def research(slug, n, task, usage, run_folder):
    """Ask Ruth for a brief; return its path."""
    brief = next_brief(slug)
    rel = brief.relative_to(ROOT).as_posix()
    print(f"round {n}: Ruth researching...", flush=True)
    _, u = run_agent(RESEARCHER, f"Research request. Write your brief to `{rel}` (one brief, within its "
                                 f"budget; put what does not fit under Not supported).\n\n{task}")
    keep_transcript(u, run_folder, f"ruth-round-{n}")
    usage.append((RESEARCHER, n, u))
    if not brief.is_file():
        raise AgentError(f"Ruth did not write {rel}")
    return brief


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def log_runs(slug, usage, table=LOG_TABLE):
    """Add one row per agent call to the run log, _meta/agent-runs.csv (default table: Content generation)."""
    for agent, n, u in usage:
        start, end = runlog.parse_ts(u.get("start")), runlog.parse_ts(u.get("end"))
        f0, w0 = runlog.usage_at(start, ROOT)
        f1, w1 = runlog.usage_at(end, ROOT, after=True)
        runlog.upsert({"start": u.get("start"), "end": u.get("end"), "table": table,
                       "run": f"{slug}, round {n}", "agent": NAMES[agent], "phase": "post-ICM",
                       "model": u.get("model") or model_of(agent), "final_context": u.get("final"),
                       "total_processed": u["tokens"], "turns": u["turns"], "duration_s": u["seconds"],
                       "five_hour_before": f0, "five_hour_after": f1, "seven_day_before": w0,
                       "seven_day_after": w1}, ROOT)


def fmt(n):
    return f"{n:,}" if n else "—"


def finish(board, slug, usage, result, summary, run_folder=None):
    """Write the Result section, mark the blackboard, log the calls and rebuild the indexes."""
    rows = "\n".join(f"| {NAMES[agent]}, round {n} | {u['tokens']:,} | {fmt(u.get('final'))} | {u['turns']} | "
                     f"{u['seconds']} s |" for agent, n, u in usage)
    total = sum(u["tokens"] for *_, u in usage)
    kept = (f"\n\nTranscripts: `{run_folder.relative_to(ROOT).as_posix()}/`"
            if run_folder and run_folder.is_dir() else "")
    append(board, f"\n## Result\n\n{summary}{kept}\n\n| Call | Total processed | Final context | Turns | Duration |\n"
                  f"|---|---|---|---|---|\n{rows}\n| **Total** | **{total:,}** | | | |\n")
    text = board.read_text(encoding="utf-8")
    board.write_text(text.replace("result: running", f"result: {result}", 1), encoding="utf-8", newline="\n")
    log_runs(slug, usage)
    folders = ["content"] + (["research"] if (ROOT / "research").is_dir() else [])
    subprocess.run([sys.executable, "-I", str(ROOT / "_tools" / "index.py"), *folders], cwd=ROOT)
    return total


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("slug", help="output name, e.g. onboarding-script")
    ap.add_argument("--type", choices=TYPES, help="required for a new draft; read from the draft with --revise")
    ap.add_argument("--request", help="the designer's story point, lesson or goal; with --revise, revision notes")
    ap.add_argument("--revise", action="store_true", help="start a new run on the existing draft")
    ap.add_argument("--no-research", action="store_true", help="journal runs only: skip Ruth (fictional species)")
    ap.add_argument("--max-rounds", type=int, default=3)
    ap.add_argument("--max-tokens", type=int, default=500_000, help="no new round starts past this total")
    a = ap.parse_args(argv)
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", a.slug):
        sys.exit("slug must be kebab-case, e.g. onboarding-script")

    draft = ROOT / "content" / f"{a.slug}.md"
    run_dir = ROOT / "content" / "_runs" / a.slug
    rel_draft = draft.relative_to(ROOT).as_posix()
    if a.revise:
        if not draft.is_file():
            sys.exit(f"--revise needs an existing {rel_draft}")
        a.type = a.type or get_front(draft, "type")
        if a.type not in TYPES:
            sys.exit(f"{rel_draft} has no valid type:; pass --type")
        n = 2
        while (run_dir / f"blackboard-{n}.md").exists():
            n += 1
        board = run_dir / f"blackboard-{n}.md"
        previous = get_front(draft, "run") or "none recorded"
        request = (f"Revision of `{rel_draft}` (previous run: `{previous}`, status was "
                   f"`{get_front(draft, 'status')}`).\n\nDesigner notes: {a.request or 'none; re-check against the current rules.'}")
    else:
        if not (a.type and a.request):
            sys.exit("a new draft needs --type and --request (or use --revise)")
        if draft.exists():
            sys.exit(f"{rel_draft} already exists; use --revise to revise it")
        board = run_dir / "blackboard.md"
        if board.exists():
            if get_front(board, "result") != "failed":
                sys.exit(f"{board.relative_to(ROOT).as_posix()} already exists; use --revise")
            n = 1
            while (run_dir / f"blackboard-failed-{n}.md").exists():
                n += 1
            board.rename(run_dir / f"blackboard-failed-{n}.md")  # keep the failed run as history
        request = a.request
    use_research = a.type == "journal" and not a.no_research
    rel_board = board.relative_to(ROOT).as_posix()
    run_folder = ROOT / RUNS / f"{datetime.date.today()}-{a.slug}-{board.stem.replace('blackboard', 'run')}"
    run_dir.mkdir(parents=True, exist_ok=True)
    board.write_text(
        f"---\nslug: {a.slug}\ntype: {a.type}\nstarted: {datetime.date.today()}\n"
        f"max_rounds: {a.max_rounds}\nmax_tokens: {a.max_tokens}\nresult: running\n---\n"
        f"# Blackboard: {a.slug}\n\nThe shared record of this run. The script writes every section and "
        f"hands each agent only the slice it needs; no agent reads this file.\n\n"
        f"## Request\n{request}\n", encoding="utf-8", newline="\n")

    usage, result, edited, v, n, block = [], "needs-review", False, None, 0, ""
    try:
        if use_research and not briefs(a.slug):
            task = (f"Verify the real-world claims in `{rel_draft}` (its Real-world facts section and any "
                    f"real-world statement in the text): for each, find a source whose quote supports it, "
                    f"narrowed as needed." if a.revise else
                    f"Find real-world facts for this content request: {a.request}")
            append(board, f"\n## Research\n\nBrief: `{research(a.slug, 1, task, usage, run_folder).relative_to(ROOT).as_posix()}`\n")

        for n in range(1, a.max_rounds + 1):
            rows = fail_rows(block) if n > 1 else []
            if n > 1 and use_research:
                asks = [r for r in rows if "Facts" in r and ASKS_FOR_SOURCE.search(r)]
                if asks:
                    brief = research(a.slug, n, "Clara's FAIL rows below ask for better sources. For each, "
                                                "find a source whose quote supports the claim it quotes, or "
                                                "the narrower claim a source does support:\n" + "\n".join(asks), usage, run_folder)
                    append(board, f"\n## Research, round {n}\n\nBrief: `{brief.relative_to(ROOT).as_posix()}`\n")
            if n > 1:
                task = (f"Revise `{rel_draft}` to fix every FAIL row below (from the critic's round {n - 1} "
                        f"verdict). Use Edit on the flagged lines only; do not rewrite the file.\n\n"
                        + "\n".join(rows))
            elif a.revise and a.request:
                task = (f"Revise `{rel_draft}` for these designer notes. Use Edit on the lines they concern "
                        f"only; do not rewrite the file.\n\nDesigner notes: {a.request}")
            elif a.revise:
                task = None  # the critic checks the draft as it stands first
            else:
                task = f"Write `{rel_draft}` for this request (type: {a.type}): {a.request}"
            if task:
                cite = ""
                if use_research:
                    paths = ", ".join(f"`{p.relative_to(ROOT).as_posix()}`" for p in briefs(a.slug))
                    cite = f"\n\nCite real-world facts only from these research briefs: {paths}."
                print(f"round {n}: William writing...", flush=True)
                _, u = run_agent(WRITER, f"Content loop, round {n}. {task}{cite}\n\nSet `type: {a.type}` and "
                                         f"`status: draft` in the frontmatter.")
                keep_transcript(u, run_folder, f"william-round-{n}")
                usage.append((WRITER, n, u))
                edited = True
                if not draft.is_file():
                    raise AgentError(f"William did not write {rel_draft}")

            text = draft.read_text(encoding="utf-8").strip()
            if n == 1:
                section = f"### Draft ({'William' if task else 'unchanged from the previous run'}), round 1"
                append(board, f"\n## Round 1\n\n{section}\n\n~~~~markdown\n{text}\n~~~~\n")
                shown = (f"Request:\n{request}\n\nThe full draft of `{rel_draft}`:\n\n~~~~markdown\n{text}\n~~~~")
            else:
                diff = "\n".join(difflib.unified_diff(previous_text.splitlines(), text.splitlines(),
                                                     f"round {n - 1}", f"round {n}", n=1, lineterm=""))
                append(board, f"\n## Round {n}\n\n### Changes (William), round {n}\n\n~~~~diff\n"
                              f"{diff or '(no changes)'}\n~~~~\n")
                shown = (f"Your round {n - 1} verdict:\n\n{block}\n\nWilliam's changes since then, as a diff "
                         f"of `{rel_draft}` (read the file only for context around them):\n\n~~~~diff\n"
                         f"{diff or '(no changes)'}\n~~~~")
            previous_text = text

            print(f"round {n}: critic checking...", flush=True)
            prompt = f"Content loop, round {n}.\n\n{shown}\n\nReply with only your `### Critic, round {n}` block."
            reply, u = run_agent(CRITIC, prompt)
            keep_transcript(u, run_folder, f"critic-round-{n}")
            block = critic_block(reply, n)
            if block is None:  # one retry if the block is missing or has no VERDICT line
                reply, u2 = run_agent(CRITIC, prompt + " Your last reply had no such block with a VERDICT line.")
                keep_transcript(u2, run_folder, f"critic-round-{n}-retry")
                u = {k: u[k] + u2[k] for k in ("tokens", "turns", "seconds")} | {"final": u2.get("final")}
                block = critic_block(reply, n)
            usage.append((CRITIC, n, u))
            if block is None:
                raise AgentError(f"the critic returned no verdict for round {n}")
            append(board, f"\n{block}\n")
            v = verdict_of(block)
            print(f"round {n}: {v}", flush=True)
            if v == "PASS":
                # an unedited draft that still passes keeps its status (e.g. approved)
                result = "draft" if edited else get_front(draft, "status") or "draft"
                break
            spent = sum(x["tokens"] for *_, x in usage)
            if n < a.max_rounds and spent >= a.max_tokens:
                print(f"token cap reached ({spent:,} >= {a.max_tokens:,}); stopping", flush=True)
                break
    except (AgentError, KeyboardInterrupt) as e:
        reason = str(e) or "interrupted"
        finish(board, a.slug, usage, "failed", f"Failed in round {n}: {reason}. The draft was not "
               f"updated by the script; a fresh run may replace this blackboard.", run_folder)
        sys.exit(f"run failed: {reason}. Blackboard: {rel_board}")

    set_front(draft, author="william", type=a.type, status=result, run=rel_board)
    spent = sum(u["tokens"] for *_, u in usage)
    if v == "PASS":
        summary = f"PASS after {n} round(s)"
    elif n < a.max_rounds:
        summary = f"Still FAIL after {n} round(s); stopped at the token cap ({spent:,} of {a.max_tokens:,})"
    else:
        summary = f"Still FAIL after {n} round(s)"
    total = finish(board, a.slug, usage, result, f"{summary}: `{rel_draft}` saved with `status: {result}`.",
                   run_folder)
    print(f"{rel_draft}: status {result} after {n} round(s), {total:,} tokens. Blackboard: {rel_board}")


if __name__ == "__main__":
    main()
