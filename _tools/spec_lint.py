#!/usr/bin/env python3
"""Lint a game spec before agents build from it: the spec-consistency rule, as a script.

    python -I _tools/spec_lint.py game/specs/<spec>.md [--item N]   # FAIL lines exit 1; REVIEW pairs are printed
    python -I _tools/spec_lint.py --staged                          # the specs staged for commit (pre-commit gate)

Two kinds of finding, read with goal_agent.parse_spec so the lint sees the spec the way the goal agent does:
  FAIL    a Quinn contract line names several items. parse_spec gives such a line a `T.n` id tied to all of them,
          so it waits on every one and a fix can't be traced to one change. Keep one item per line.
  WARN    a Quinn line names no item and ties on keywords between items (also a `T.n` id). Name its item.
  REVIEW  two items' sentences meet on the same view (farm view, first zoom, second stop) and share a subject
          word, and one of them restricts it (never, only, not, hidden...) while the other asserts something there.
          That's the 2026-11-08 shape: item 11 said the farm view never cranks, then item 13's test line asked for
          a crank in the farm view, and it could never pass. A person reads each pair; it doesn't fail.
`--item N` keeps only the REVIEW pairs touching item N: run it right after writing a play-test item.
Standard library only.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))  # -I leaves the script's folder off sys.path
import goal_agent as ga  # noqa: E402

VIEWS = {"farm view": r"farm view|farm-view|zoomed out|on the farm",
         "first zoom": r"first zoom|zoom 1\b",
         "second stop": r"second stop|zoom 2\b|centrifuge zoom"}
RESTRICT = re.compile(r"\b(never|only|not|no|cannot|can't|shouldn't|doesn't|don't|hidden|hide|without|unless)\b", re.I)
GENERIC = {"camera", "screen", "button", "player", "tap", "tapped", "show", "shows", "game", "phase", "stage",
           "farm", "zoom", "first", "second", "stop", "still", "again", "also", "then", "there", "here", "where",
           "while", "after", "before", "until", "once", "both", "every", "designer", "confirmed", "kept", "play"}
GENERIC |= {w for w in ("never", "only", "not", "cannot", "hidden", "hide", "without", "unless", "should", "shouldn")}


def stem(w):
    for suf in ("ing", "ed", "es", "s"):
        if w.endswith(suf) and len(w) - len(suf) >= 4:
            return w[: -len(suf)]
    return w


def subjects(text):
    """Stemmed content words and node names, minus the view phrases and generic words."""
    t = text
    for pat in VIEWS.values():
        t = re.sub(pat, " ", t, flags=re.I)
    out = {stem(w) for w in ga.words(t) if w not in GENERIC and len(w) >= 4}
    return out | {n.lower() for n in ga.backticked(text) if ga.is_node(n)}


def views(text):
    return {v for v, pat in VIEWS.items() if re.search(pat, text, re.I)}


def sentences(text):
    text = re.sub(r"\s+", " ", text)
    return [s.strip() for s in re.split(r"(?<=[.;:])\s+(?=[A-Z`(])", text) if s.strip()]


def item_sentences(spec_path):
    """[(item, where, sentence)] from the Changes and every contract line."""
    text = Path(spec_path).read_text(encoding="utf-8")
    changes, _ = ga.parse_changes(ga.section(text, "Changes"))
    out = [(n, "Changes", s) for n, _, body in changes for s in sentences(body)]
    numbers = {n for n, _, _ in changes}
    for owner, lines in ga.parse_contract(ga.section(text, "Contract")).items():
        context = None
        for kind, line in lines:
            named = [n for n in ga.item_numbers(line) if n in numbers]
            if kind == "head":
                context = named or None
            for n in (named or context or []):
                out += [(n, f"Contract/{owner}", s) for s in sentences(line)]
    return out


def clauses(sentence):
    return [c.strip() for c in re.split(r"[,;:()]|\s-\s|\.\s|\*\*", sentence) if c.strip()]


def review(spec_path, only=None):
    """Pairs (restricting, asserting, view, shared words) across different items, one per item pair and view.
    The restriction is tight: its word, the view and the subject sit in one clause ("the farm view never cranks").
    The assertion is the whole sentence: it names that view and that subject, with no restricting word."""
    sents = item_sentences(spec_path)
    rules = [(s, c) for s in sents for c in clauses(s[2]) if RESTRICT.search(c) and views(c) and subjects(c)]
    pairs, seen = [], set()
    for a, clause in rules:
        for b in sents:
            if a[0] == b[0] or RESTRICT.search(b[2]):
                continue
            if only is not None and only not in (a[0], b[0]):
                continue
            common_views = views(clause) & views(b[2])
            shared = subjects(clause) & subjects(b[2])
            key = (a[0], b[0], tuple(sorted(common_views)))
            if common_views and shared and key not in seen:
                seen.add(key)
                pairs.append(((a[0], a[1], clause), b, sorted(common_views), sorted(shared)))
    return pairs


def check_lines(spec_path):
    """(fails, warns) on Quinn's contract lines."""
    spec = ga.parse_spec(spec_path)
    fails, warns = [], []
    for g in spec["goals"].values():
        if g["kind"] != "test" or re.search(r"\bmutations?\b", g["text"], re.I):
            continue
        named = ga.item_numbers(g["text"])
        if len(named) > 1:
            fails.append(f"{g['id']} names items {', '.join(map(str, named))}: keep one item per line: {g['text'][:90]}")
        elif not named and len(g["items"]) > 1:
            warns.append(f"{g['id']} ties on keywords between items {g['items']}: name its item: {g['text'][:90]}")
    return fails, warns


def lint(spec_path, only=None, out=print):
    """Print the findings; return the number of FAILs."""
    fails, warns = check_lines(spec_path)
    name = Path(spec_path).name
    for f in fails:
        out(f"FAIL   {name}: {f}")
    for w in warns:
        out(f"WARN   {name}: {w}")
    for a, b, vs, shared in review(spec_path, only):
        out(f"REVIEW {name}: item {a[0]} restricts, item {b[0]} asserts, on {', '.join(vs)} ({', '.join(shared)})")
        out(f"         {a[0]} [{a[1]}] {a[2][:160]}")
        out(f"         {b[0]} [{b[1]}] {b[2][:160]}")
    if not (fails or warns):
        out(f"spec_lint {name}: no FAIL or WARN" + ("" if not review(spec_path, only) else "; read the REVIEW pairs"))
    return len(fails)


def staged():
    res = subprocess.run(["git", "diff", "--cached", "--name-only", "--diff-filter=AM", "--", "game/specs/*.md"],
                         capture_output=True, text=True)
    return [p for p in res.stdout.split() if p.endswith(".md") and "handoff" not in p]


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("spec", nargs="?")
    ap.add_argument("--item", type=int, help="only REVIEW pairs touching this item")
    ap.add_argument("--staged", action="store_true", help="lint the specs staged for commit; REVIEW pairs not shown")
    a = ap.parse_args(argv)
    if a.staged:
        quiet = lambda line: None if line.startswith(("REVIEW", "  ", "spec_lint")) else print(line)
        return 1 if sum(lint(p, out=quiet) for p in staged()) else 0
    if not a.spec:
        ap.error("give a spec path, or --staged")
    return 1 if lint(a.spec, a.item) else 0


if __name__ == "__main__":
    sys.exit(main())
