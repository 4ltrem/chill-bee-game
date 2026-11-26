#!/usr/bin/env python3
"""Price agent runs in US dollars from their transcripts (A7 cost analysis).

    python -I _tools/run_cost.py PATH [PATH ...] [--by file|dir] [--csv OUT.csv]

Each PATH is a transcript (.jsonl) or a folder of them (searched recursively), e.g. a run folder in
_meta/sessions/runs/ or a main-session transcript. Every assistant message's `usage` is counted once
(transcripts repeat it per content block; the last copy of each message id wins) and priced at the
model's API list price per token type. The plan is a subscription, so this is what the same tokens
would cost on the API, not what was paid.

Prices: claude-api skill model table, cached 2026-11-03, $ per million tokens (input, output, cache read).
Cache writes: 1.25x input for 5-minute entries, 2x input for 1-hour entries, read from
`usage.cache_creation` (all 1-hour when the split is missing, the upper bound). A model not in the table
is priced at Opus 5.5 and listed under `unpriced`. Standard library only.
"""
import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

PRICES = {  # model prefix: (input, output, cache read) in $ per 1M tokens
    "claude-opus-5-5": (4.00, 20.00, 0.20),
    "claude-opus-5": (5.00, 25.00, 0.50),
    "claude-sonnet-5-5": (2.00, 10.00, 0.10),
    "claude-sonnet-5": (2.00, 10.00, 0.20),
    "claude-sonnet-4-6": (3.00, 15.00, 0.30),
    "claude-haiku-5-5": (0.10, 0.50, 0.01),
    "claude-haiku-4-5": (1.00, 5.00, 0.10),
}
WRITE_5M, WRITE_1H = 1.25, 2.0
FIELDS = ("input", "write_5m", "write_1h", "cache_read", "output")


def price_for(model):
    for prefix in sorted(PRICES, key=len, reverse=True):
        if model.startswith(prefix):
            return PRICES[prefix], True
    return PRICES["claude-opus-5-5"], False


def messages(path):
    """{message id: (model, usage)} for one transcript; the last copy of each id wins."""
    seen = {}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            msg = rec.get("message") if isinstance(rec, dict) else None
            if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
                continue
            model = msg.get("model") or ""
            if model.startswith("<"):   # synthetic messages carry no real usage
                continue
            seen[msg.get("id") or rec.get("uuid") or len(seen)] = (model, msg["usage"])
    return seen


def tally(path):
    tokens = defaultdict(lambda: dict.fromkeys(FIELDS, 0))
    for model, u in messages(path).values():
        t = tokens[model]
        t["input"] += u.get("input_tokens") or 0
        t["output"] += u.get("output_tokens") or 0
        t["cache_read"] += u.get("cache_read_input_tokens") or 0
        split = u.get("cache_creation") or {}
        w5, w1 = split.get("ephemeral_5m_input_tokens"), split.get("ephemeral_1h_input_tokens")
        if w5 is None and w1 is None:
            w5, w1 = 0, u.get("cache_creation_input_tokens") or 0
        t["write_5m"] += w5 or 0
        t["write_1h"] += w1 or 0
    return tokens


def dollars(model, t):
    (inp, out, read), known = price_for(model)
    cost = (t["input"] * inp + t["write_5m"] * inp * WRITE_5M + t["write_1h"] * inp * WRITE_1H
            + t["cache_read"] * read + t["output"] * out) / 1e6
    return cost, known


def files_of(path):
    p = Path(path)
    return sorted(p.rglob("*.jsonl")) if p.is_dir() else [p]


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="+")
    ap.add_argument("--by", choices=("file", "dir"), default="dir")
    ap.add_argument("--csv")
    a = ap.parse_args(argv)
    rows, unpriced = [], set()
    for root in a.paths:
        groups = defaultdict(list)
        for f in files_of(root):
            name = f.relative_to(root).as_posix() if Path(root).is_dir() else f.name
            groups[name if a.by == "file" else Path(root).name].append(f)
        for label, files in groups.items():
            per_model = defaultdict(lambda: dict.fromkeys(FIELDS, 0))
            for f in files:
                for model, t in tally(f).items():
                    for k in FIELDS:
                        per_model[model][k] += t[k]
            for model, t in sorted(per_model.items()):
                cost, known = dollars(model, t)
                if not known:
                    unpriced.add(model)
                rows.append({"run": label, "model": model, **t, "total_tokens": sum(t.values()),
                             "usd": round(cost, 4)})
    if not rows:
        sys.exit("run_cost: no assistant messages with usage found")
    w = max(len(r["run"]) for r in rows)
    print(f"{'run':<{w}}  {'model':<18} {'tokens':>12} {'cache read':>12} {'output':>9} {'usd':>9}")
    for r in rows:
        print(f"{r['run']:<{w}}  {r['model']:<18} {r['total_tokens']:>12,} {r['cache_read']:>12,} "
              f"{r['output']:>9,} {r['usd']:>9.2f}")
    print(f"TOTAL {sum(r['total_tokens'] for r in rows):,} tokens, ${sum(r['usd'] for r in rows):.2f}")
    if unpriced:
        print("unpriced (charged at Opus 5.5):", ", ".join(sorted(unpriced)))
    if a.csv:
        with open(a.csv, "w", newline="", encoding="utf-8") as f:
            cw = csv.DictWriter(f, fieldnames=list(rows[0]))
            cw.writeheader()
            cw.writerows(rows)


if __name__ == "__main__":
    main(sys.argv[1:])
