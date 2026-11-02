#!/usr/bin/env python3
"""Check that the docs agree with the code and config they describe. Exit 1 on any mismatch.

    python -I _tools/consistency.py

Runs in the test suite and in the git pre-commit hook (.githooks/pre-commit), so a commit where a
doc contradicts its source of truth is refused. It checks facts a script can verify; the end-of-day
doc audit covers meaning. Sources of truth: agent frontmatter (.claude/agents/*.md), the scripts'
defaults (_tools/generate.py) and Ruth's budget (her definition). Checked:
  - generated sections are up to date (_tools/sync_docs.py)
  - every agent definition has a roster row in _meta/team.md with the same model, and a route in
    AGENTS.md; every roster row links to a definition that exists
  - models named in Model reviews rows and in Mermaid diagram nodes match the agent's frontmatter
  - the token cap, round limit and Ruth's search/fetch budget quoted in docs match the code
  - a stated agent count ("the nine agents") matches the number of agent definitions
  - no Per-Task Estimates row says "Not yet run" for an agent whose runs are already logged
History is not checked: dated logs, blackboards, decision logs, proposals and review folders
record what was true when written. Standard library only.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import sync_docs  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
MODELS = r"(Haiku|Sonnet|Opus)"


def docs(root):
    """Markdown that describes the present: not history (logs, runs, sessions, proposals, reviews)."""
    found = [root / n for n in ("README.md", "CREW.md", "AGENTS.md", "CONTEXT.md", "_meta/team.md")]
    found += sorted(root.glob("*/CONTEXT.md")) + sorted(root.glob("proposals/*/CONTEXT.md"))
    found += sorted((root / ".claude" / "agents").glob("*.md")) + sorted((root / ".claude" / "skills").glob("*/SKILL.md"))
    found += sorted((root / "_templates").glob("*.md"))
    return [p for p in dict.fromkeys(found) if p.is_file()]


def agents(root):
    return {p.stem: sync_docs.agent(p.stem, root) for p in sorted((root / ".claude" / "agents").glob("*.md"))}


def lines(path):
    return path.read_text(encoding="utf-8").splitlines()


def check_roster(root, ags):
    problems = []
    team = root / "_meta" / "team.md"
    roster = {}
    for n, line in enumerate(lines(team), 1):
        m = re.match(r"\| (\w+) \| [^|]+ \| [^|]+ \| " + MODELS + r" \| .*\]\(\.\./\.claude/agents/([\w-]+)\.md\) \|$", line)
        if m:
            roster[m.group(3)] = (m.group(1), m.group(2), n)
    for slug, a in ags.items():
        if slug not in roster:
            problems.append(f"_meta/team.md: no roster row links .claude/agents/{slug}.md ({a['name']})")
            continue
        name, model, n = roster[slug]
        if model != a["model"]:
            problems.append(f"_meta/team.md:{n}: {name} listed as {model}, but {slug}.md has model: {a['model'].lower()}")
    for slug, (name, _, n) in roster.items():
        if slug not in ags:
            problems.append(f"_meta/team.md:{n}: {name}'s row links a missing definition .claude/agents/{slug}.md")
    agents_md = (root / "AGENTS.md").read_text(encoding="utf-8")
    for slug, a in ags.items():
        if f".claude/agents/{slug}.md" not in agents_md:
            problems.append(f"AGENTS.md: no route mentions .claude/agents/{slug}.md ({a['name']})")
    return problems


def check_model_mentions(root, ags):
    """Model reviews rows ('| Ruth (Sonnet...') and Mermaid nodes ('Ruth<br/>...<br/>Sonnet')."""
    by_name = {a["name"]: a for a in ags.values()}
    problems = []
    for path in docs(root):
        rel = path.relative_to(root).as_posix()
        for n, line in enumerate(lines(path), 1):
            row = re.match(r"\| ([A-Z]\w+(?:, [A-Z]\w+)*) \(" + MODELS, line)
            if row:
                for name in row.group(1).split(", "):
                    a = by_name.get(name)
                    if a and a["model"] != row.group(2):
                        problems.append(f"{rel}:{n}: {name} shown as {row.group(2)}, but the agent runs on {a['model']}")
            for name, model in re.findall(r"\[([A-Z]\w+)<br/>[^\]]*?<br/>" + MODELS + r"\]", line):
                a = by_name.get(name)
                if a and a["model"] != model:
                    problems.append(f"{rel}:{n}: diagram shows {name} on {model}, but the agent runs on {a['model']}")
    return problems


def check_numbers(root):
    """Defaults and budgets quoted in docs against the code that sets them."""
    gen = (root / "_tools" / "generate.py").read_text(encoding="utf-8")
    cap = int(re.search(r'"--max-tokens", type=int, default=([\d_]+)', gen).group(1).replace("_", ""))
    rounds = int(re.search(r'"--max-rounds", type=int, default=(\d+)', gen).group(1))
    ruth = (root / ".claude" / "agents" / "research-assistant.md").read_text(encoding="utf-8")
    searches, fetches = map(int, re.search(r"at most (\d+) WebSearch and (\d+) WebFetch", ruth).groups())
    problems = []
    for path in docs(root):
        rel = path.relative_to(root).as_posix()
        for n, line in enumerate(lines(path), 1):
            if re.search(r"token cap|--max-tokens", line):
                for num in re.findall(r"(\d{1,3}(?:,\d{3})+) by default|default (\d{1,3}(?:,\d{3})+)", line):
                    value = int((num[0] or num[1]).replace(",", ""))
                    if value != cap:
                        problems.append(f"{rel}:{n}: token cap quoted as {value:,}, but generate.py defaults to {cap:,}")
            for num in re.findall(r"round[^.]*?\((\d+) by default\)|(\d+) rounds by default", line):
                value = int(num[0] or num[1])
                if value != rounds:
                    problems.append(f"{rel}:{n}: round limit quoted as {value}, but generate.py defaults to {rounds}")
            for num in re.findall(r"(\d+) (?:WebSearch|searches)\b", line):
                if int(num) != searches:
                    problems.append(f"{rel}:{n}: Ruth's search budget quoted as {num}, but her definition says {searches}")
            for num in re.findall(r"(\d+) (?:WebFetch|fetches)\b", line):
                if int(num) != fetches:
                    problems.append(f"{rel}:{n}: Ruth's fetch budget quoted as {num}, but her definition says {fetches}")
    return problems


WORDS = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen".split()


def check_agent_count(root, ags):
    """'the nine agents' in a doc must match the number of agent definitions."""
    problems = []
    for path in docs(root):
        rel = path.relative_to(root).as_posix()
        for n, line in enumerate(lines(path), 1):
            for word in re.findall(r"\bthe (\d+|" + "|".join(WORDS) + r") agents\b", line, re.I):
                value = int(word) if word.isdigit() else WORDS.index(word.lower())
                if value != len(ags):
                    problems.append(f"{rel}:{n}: says the {word} agents, but .claude/agents/ holds {len(ags)}")
    return problems


def check_estimates(root):
    """A Per-Task Estimates row saying 'Not yet run' while the log already holds that agent's runs."""
    log = root / "_meta" / "agent-runs.md"
    if not log.is_file():
        return []
    text = lines(log)
    problems = []
    for n, line in enumerate(text, 1):
        m = re.match(r"\| ([A-Z]\w+), the [^|]+ \| Not yet run", line)
        if not m:
            continue
        name = m.group(1)
        runs = [k for k, l in enumerate(text, 1) if re.match(rf"\| {name}(:| \()", l)]
        if runs:
            problems.append(f"_meta/agent-runs.md:{n}: {name}'s estimate says 'Not yet run', but line {runs[0]} logs a run")
    return problems


def check(root=None):
    root = root or ROOT
    ags = agents(root)
    return (sync_docs.sync(check=True, root=root) + check_roster(root, ags)
            + check_model_mentions(root, ags) + check_numbers(root) + check_agent_count(root, ags)
            + check_estimates(root))


def main():
    problems = check()
    for p in problems:
        print(p)
    if problems:
        sys.exit(f"{len(problems)} doc/code mismatch(es); fix the docs (or run python -I _tools/sync_docs.py)")
    print("docs agree with code and config")


if __name__ == "__main__":
    main()
