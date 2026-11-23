#!/usr/bin/env python3
"""Compute the A7 audit's numbers and draw its charts, from the repository's own records.

    python -I _tools/audit_data.py            # writes _meta/drafts/a7/data/*.csv, charts/*.svg and data.md

Sources: git history (commits, lines changed, tests and mutations at each version's end commit),
_meta/agent-runs.csv (runs, tokens, plan usage), _meta/learnings.md (dates), the goal boards and build
reports ("mutate: N of M caught"). Play-test findings per version are counted from the specs that fix them
(PLAYTEST below, each with its source). Charts are static SVG for the PDF, in the dataviz reference palette
(validated: blue, orange, aqua pass the CVD and normal-vision checks; aqua is under 3:1 contrast, so every
chart has its numbers in a table in data.md). Standard library only.
"""
import csv
import re
import subprocess
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "_meta" / "drafts" / "a7"

# (label, end ref, what was built). The first row ends at the last commit before 2026-11-03 (design phase).
VERSIONS = [
    ("Design", None, "GDD, two review rounds, proposals"),
    ("0.1.0", "970f28b", "Prototype 0, 0.1 Harvest"),
    ("0.1.1-0.1.2", "92c1119", "play-test fixes, bottling and sale"),
    ("0.1.3", "59e11bd", "farm layouts, camera stops"),
    ("0.1.4", "948a49e", "UI placement (A5, first goal-agent run)"),
    ("0.2.0", "f1ff1d5", "first automation (goal agent)"),
    ("0.2.1", "a6-demo", "0.2.0 play-test fixes (A6)"),
    ("0.3.0", "v0.3.0", "course build items 1-6"),
]
# Findings from the designer's play-test OF each version, counted as the spec items that fix them.
PLAYTEST = {
    "0.1.0": (6, "0.1.1-playtest-fixes.md, items 1-6"),
    "0.1.1-0.1.2": (None, "not itemised (fixed inside 0.1.3)"),
    "0.1.3": (4, "0.1.4-ui-placement.md items 2, 3, 4, 7"),
    "0.1.4": (13, "0.1.4-ui-placement.md items 9-17, 19-22"),
    "0.2.0": (6, "0.2-first-automation.md items 9-14 (0.2.1)"),
    "0.2.1": (1, "0.2-first-automation.md item 15"),
    "0.3.0": (4, "0.3.1-playtest-fixes.md items 1-3 (four findings, L52)"),
}
# Cause groups from the audit's section 6.1, plus L51 and L52.
CAUSES = {
    "Pipeline tooling": "L5 L6 L7 L13 L14 L15 L20 L34 L35 L44 L49 L50 L51",
    "Tests slow, stale or weak": "L4 L16 L17 L19 L39 L40 L41 L42 L47",
    "Environment": "L24 L36 L37 L38 L45 L48",
    "Agents outside brief": "L12 L21 L31 L33 L43",
    "Green checks, wrong result": "L9 L10 L18 L22 L46 L52",
    "Process and human loop": "L1 L2 L8 L23 L30",
    "Design canvas": "L25 L26 L27 L28 L29",
    "Cost blowups": "L3 L11 L32",
}
GAME = ("game/scripts/", "game/scenes/", "game/tests/", "game/materials/", "game/translations/", "game/project.godot")
SURFACE, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100"]   # dataviz categorical slots 1-4, fixed order


def git(*args):
    return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, encoding="utf-8").stdout


def version_bounds():
    """[(label, start_commit_or_None, end_commit, start_dt, end_dt, note)]"""
    first_dev = git("rev-list", "-1", "--before=2026-11-02T23:59:59", "HEAD").strip()
    rows, prev = [], None
    for label, ref, note in VERSIONS:
        end = first_dev if ref is None else git("rev-parse", ref + "^{commit}").strip()
        end_dt = datetime.fromisoformat(git("log", "-1", "--format=%cI", end).strip())
        start_dt = None if prev is None else datetime.fromisoformat(git("log", "-1", "--format=%cI", prev).strip())
        rows.append((label, prev, end, start_dt, end_dt, note))
        prev = end
    return rows


def lines_changed(start, end):
    rng = end if start is None else f"{start}..{end}"
    game = tools = docs = 0
    for line in git("log", "--numstat", "--format=", rng).splitlines():
        parts = line.split("\t")
        if len(parts) != 3 or not parts[0].isdigit():
            continue
        n, path = int(parts[0]) + int(parts[1]), parts[2]
        if path.startswith("game/reports/") or path.endswith((".csv", ".json", ".svg", ".png")):
            continue
        if path.startswith(GAME):
            game += n
        elif path.startswith("_tools/"):
            tools += n
        elif path.endswith(".md"):
            docs += n
    return game, tools, docs


def count_at(ref, pattern, path):
    out = git("grep", "-c", "-E", pattern, ref, "--", path)
    return sum(int(l.rsplit(":", 1)[1]) for l in out.splitlines() if l.rsplit(":", 1)[-1].isdigit())


def runs():
    out = []
    with open(ROOT / "_meta" / "agent-runs.csv", encoding="utf-8", newline="") as fh:
        for r in csv.DictReader(fh):
            if r.get("table") == "table":
                continue
            stamp = r.get("end") or r.get("start")   # a run counts when it ends: one session ran 10-31 to 11-03 (170M)
            r["dt"] = datetime.fromisoformat(stamp.replace("Z", "+00:00")) if stamp else None
            r["tokens"] = int(r["total_processed"]) if (r.get("total_processed") or "").isdigit() else 0
            out.append(r)
    return out


def component(table):
    return {"Orchestrator": "Orchestrator", "Subagent runs": "Agent-tool subagents",
            "Goal agent": "Goal agent"}.get(table, "Other loops")


def mutation_rate():
    caught = total = 0
    for f in list((ROOT / "game" / "reports").glob("goal/*/blackboard.md")) + list((ROOT / "game" / "reports").glob("builds/*/report.md")):
        for m in re.finditer(r"mutate: (\d+) of (\d+) caught", f.read_text(encoding="utf-8", errors="replace")):
            caught, total = caught + int(m.group(1)), total + int(m.group(2))
    return caught, total


def learnings():
    text = (ROOT / "_meta" / "learnings.md").read_text(encoding="utf-8")
    return {m.group(1): date.fromisoformat(m.group(2)) for m in re.finditer(r"^## (L\d+) · (\d{4}-\d\d-\d\d)", text, re.M)}


# ---------- SVG ----------
def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'font-family="Inter, Segoe UI, Arial, sans-serif" role="img" aria-label="{title}">'
            f'<rect width="{w}" height="{h}" fill="{SURFACE}"/>'
            f'<text x="16" y="24" font-size="15" font-weight="600" fill="{INK}">{title}</text>{body}</svg>')


def nice_step(v):
    """A round tick step giving about five intervals up to v (1, 2 or 5 times a power of ten)."""
    raw = max(v, 1) / 5
    mag = 10 ** (len(str(int(raw))) - 1) if raw >= 1 else 1
    for m in (1, 2, 5, 10):
        if raw <= m * mag:
            return m * mag
    return 10 * mag


def nice_max(v):
    step = nice_step(v)
    return step * -(-max(v, 1) // step)


def axes(x0, y0, w, h, ymax, fmt):
    out = ""
    n = round(ymax / nice_step(ymax * 0.999))
    for i in range(n + 1):
        v = ymax * i / n
        y = y0 - h * i / n
        out += f'<line x1="{x0}" x2="{x0 + w}" y1="{y:.1f}" y2="{y:.1f}" stroke="{GRID}" stroke-width="1"/>'
        out += f'<text x="{x0 - 6}" y="{y + 4:.1f}" font-size="11" fill="{INK2}" text-anchor="end">{fmt(v)}</text>'
    return out


def legend(x, y, names):
    out = ""
    for i, n in enumerate(names):
        out += (f'<rect x="{x}" y="{y + i * 18 - 9}" width="10" height="10" rx="2" fill="{SERIES[i]}"/>'
                f'<text x="{x + 16}" y="{y + i * 18}" font-size="12" fill="{INK}">{n}</text>')
    return out


def stacked_bars(title, labels, series, fmt, every=1):
    """series: [(name, [values per label])]; stacked, 2px surface gap between segments."""
    W, H, x0, y0, ph = 760, 340, 64, 280, 230
    pw = 500
    totals = [sum(s[1][i] for s in series) for i in range(len(labels))]
    ymax = nice_max(max(totals) if totals else 1)
    bw = pw / len(labels)
    body = axes(x0, y0, pw, ph, ymax, fmt)
    for i, lab in enumerate(labels):
        y = y0
        for k, (name, vals) in enumerate(series):
            hgt = ph * vals[i] / ymax
            if hgt <= 0:
                continue
            body += (f'<rect x="{x0 + i * bw + 1:.1f}" y="{y - hgt + 1:.1f}" width="{max(bw - 2, 1):.1f}" '
                     f'height="{max(hgt - 2, 0.5):.1f}" fill="{SERIES[k]}"><title>{lab} {name}: {fmt(vals[i])}</title></rect>')
            y -= hgt
        if i % every == 0:
            body += f'<text x="{x0 + i * bw + bw / 2:.1f}" y="{y0 + 16}" font-size="10" fill="{INK2}" text-anchor="middle">{lab}</text>'
    body += legend(x0 + pw + 24, 60, [s[0] for s in series])
    return svg(W, H, body, title)


def line_chart(title, labels, series, fmt, every=1):
    W, H, x0, y0, ph, pw = 760, 340, 64, 280, 230, 500
    ymax = nice_max(max(v for _, vals in series for v in vals if v is not None))
    step = pw / max(len(labels) - 1, 1)
    body = axes(x0, y0, pw, ph, ymax, fmt)
    for k, (name, vals) in enumerate(series):
        pts = [(x0 + i * step, y0 - ph * v / ymax) for i, v in enumerate(vals) if v is not None]
        body += f'<polyline fill="none" stroke="{SERIES[k]}" stroke-width="2" points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in pts)}"/>'
        for (x, y), v in zip(pts, [v for v in vals if v is not None]):
            body += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4" fill="{SERIES[k]}" stroke="{SURFACE}" stroke-width="2"><title>{name}: {fmt(v)}</title></circle>'
        if pts:   # direct label at the line's end
            body += f'<text x="{pts[-1][0] + 8:.1f}" y="{pts[-1][1] + 4:.1f}" font-size="12" fill="{INK}">{name} {fmt([v for v in vals if v is not None][-1])}</text>'
    for i, lab in enumerate(labels):
        if i % every == 0:
            body += f'<text x="{x0 + i * step:.1f}" y="{y0 + 16}" font-size="10" fill="{INK2}" text-anchor="middle">{lab}</text>'
    return svg(W, H, body, title)


def mtok(v):
    return f"{v / 1e6:.0f}M" if v >= 1e6 else (f"{v / 1e3:.0f}k" if v else "0")


def md_table(head, rows):
    out = "| " + " | ".join(head) + " |\n|" + "---|" * len(head) + "\n"
    return out + "".join("| " + " | ".join(str(c) for c in r) + " |\n" for r in rows)


def main():
    (OUT / "data").mkdir(parents=True, exist_ok=True)
    (OUT / "charts").mkdir(parents=True, exist_ok=True)
    rr = runs()
    bounds = version_bounds()
    comps = ["Orchestrator", "Agent-tool subagents", "Goal agent", "Other loops"]

    # 1. per version
    vrows = []
    for label, start, end, s_dt, e_dt, note in bounds:
        rng = end if start is None else f"{start}..{end}"
        commits = int(git("rev-list", "--count", rng).strip() or 0)
        game, tools, docs = lines_changed(start, end)
        tests = count_at(end, r"^func t_", "game/tests")
        muts = count_at(end, r'^\s*"name":', "game/tests/mutations.json")
        win = [r for r in rr if r["dt"] and (s_dt is None or r["dt"] > s_dt) and r["dt"] <= e_dt]
        tok = Counter()
        for r in win:
            tok[component(r["table"])] += r["tokens"]
        calls = sum(1 for r in win if r["table"] != "Orchestrator")
        pt, pt_src = PLAYTEST.get(label, (None, ""))
        days = max(1, (e_dt.date() - (s_dt.date() if s_dt else date(2026, 10, 14))).days + (0 if s_dt else 1))
        vrows.append([label, note, (s_dt or datetime(2026, 10, 14)).date().isoformat(), e_dt.date().isoformat(), days,
                      commits, game, tools, docs, tests, muts, calls, sum(tok.values()), tok["Orchestrator"],
                      "" if pt is None else pt, pt_src])
    head = ["version", "built", "from", "to", "days", "commits", "game lines", "tool lines", "doc lines", "tests",
            "mutations", "agent calls", "tokens", "orchestrator tokens", "play-test findings", "findings source"]
    with open(OUT / "data" / "versions.csv", "w", encoding="utf-8", newline="") as fh:
        csv.writer(fh).writerows([head] + vrows)

    # 2. per day
    days = sorted({r["dt"].date() for r in rr if r["dt"]})
    first, last = days[0], days[-1]
    span = [first + timedelta(d) for d in range((last - first).days + 1)]
    per_day = {d: Counter() for d in span}
    week = {}
    for r in rr:
        if r["dt"]:
            per_day[r["dt"].date()][component(r["table"])] += r["tokens"]
            v = r.get("seven_day_after") or ""
            if v.isdigit():
                week[r["dt"].date()] = max(week.get(r["dt"].date(), 0), int(v))
    commits_day = defaultdict(lambda: [0, 0])   # [touches game code, workspace only], one class per commit
    for block in git("log", "--format=@%cs", "--name-only").split("@")[1:]:
        lines = [l for l in block.splitlines() if l.strip()]
        d = date.fromisoformat(lines[0])
        commits_day[d][0 if any(l.startswith(GAME) for l in lines[1:]) else 1] += 1
    with open(OUT / "data" / "daily.csv", "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["date"] + comps + ["weekly usage % (max reading)", "commits touching game", "commits workspace only"])
        for d in span:
            w.writerow([d.isoformat()] + [per_day[d][c] for c in comps] + [week.get(d, ""), *commits_day[d]])

    # 3. learnings per week by cause
    ldates = learnings()
    cause_of = {l: c for c, ls in CAUSES.items() for l in ls.split()}
    weeks = sorted({d - timedelta(d.weekday()) for d in ldates.values()})
    lw = {wk: Counter() for wk in weeks}
    for l, d in ldates.items():
        lw[d - timedelta(d.weekday())][cause_of.get(l, "Unclassified")] += 1
    caught, total = mutation_rate()

    # 4. goal-agent runs: calls, tokens, agent time, designer stops
    goal = defaultdict(lambda: [0, 0, 0])
    for r in rr:
        m = re.match(r"goal (\d+(?:\.\d+)*)\b", r.get("run") or "")
        if r["table"] == "Goal agent" and m:
            g = goal[m.group(1)]
            g[0] += 1
            g[1] += r["tokens"]
            g[2] += int(r["duration_s"]) if (r.get("duration_s") or "").isdigit() else 0
    grows = []
    for v in sorted(goal, key=lambda s: [int(x) for x in s.split(".")]):
        board = ROOT / "game" / "reports" / "goal" / v / "blackboard.md"
        stops = board.read_text(encoding="utf-8", errors="replace").count("Waiting for the designer") if board.exists() else ""
        c, t, s = goal[v]
        grows.append([v, c, mtok(t), f"{t / c / 1e3:.0f}k" if c else "", f"{s / 60:.0f} min", stops])

    # charts
    lab = [d.strftime("%m-%d") for d in span]
    every = max(1, len(span) // 10)
    (OUT / "charts" / "tokens-per-day.svg").write_text(stacked_bars(
        "Tokens processed per day, by component", lab,
        [(c, [per_day[d][c] for d in span]) for c in comps], mtok, every), encoding="utf-8")
    wk_days = [d for d in span if d in week]
    (OUT / "charts" / "weekly-usage.svg").write_text(line_chart(
        "Weekly plan usage (highest reading per day, %; drops are weekly resets)", [d.strftime("%m-%d") for d in wk_days],
        [("weekly %", [week[d] for d in wk_days])], lambda v: f"{v:.0f}", max(1, len(wk_days) // 10)), encoding="utf-8")
    cd = [first + timedelta(d) for d in range((last - first).days + 1)]
    (OUT / "charts" / "commits-per-day.svg").write_text(stacked_bars(
        "Commits per day: game code vs workspace only", [d.strftime("%m-%d") for d in cd],
        [("touch game code", [commits_day[d][0] for d in cd]), ("workspace only", [commits_day[d][1] for d in cd])],
        lambda v: f"{v:.0f}", every), encoding="utf-8")
    vl = [v[0] for v in vrows[1:]]
    (OUT / "charts" / "tests-per-version.svg").write_text(line_chart(
        "Tests and mutations at each version's end", vl,
        [("tests", [v[9] for v in vrows[1:]]), ("mutations", [v[10] for v in vrows[1:]])], lambda v: f"{v:.0f}"), encoding="utf-8")
    top3 = [c for c, _ in Counter(cause_of[l] for l in ldates if l in cause_of).most_common(3)]
    (OUT / "charts" / "learnings-per-week.svg").write_text(stacked_bars(
        "Learnings (breaks written up) per week, top causes", [f"wk {w.strftime('%m-%d')}" for w in weeks],
        [(c, [lw[w][c] for w in weeks]) for c in top3] +
        [("other causes", [sum(n for c, n in lw[w].items() if c not in top3) for w in weeks])], lambda v: f"{v:.0f}"),
        encoding="utf-8")

    # data.md
    vt = [[v[0], v[1], f"{v[2]} to {v[3]}", v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11], mtok(v[12]), mtok(v[13]),
           v[14] if v[14] != "" else "n/a"] for v in vrows]
    md = ["# A7 audit data (generated by `_tools/audit_data.py`; do not edit by hand)\n",
          f"Generated {date.today().isoformat()}. Runs logged: {len(rr)} ({sum(1 for r in rr if r['dt'])} with timestamps; "
          "the rest, mostly pre-ICM and content runs, count in the totals but not in the per-day or per-version windows). "
          "A run counts on the day and in the version where it ended; a main session is one row, so a long session "
          "lands as one spike (the 10-31 to 11-03 session, 170M, sits on 11-03).\n",
          "## Per version\n", md_table(["version", "built", "dates", "days", "commits", "game lines", "tool lines",
                                       "doc lines", "tests", "mutations", "agent calls", "tokens", "orch. tokens",
                                       "play-test findings"], vt),
          "\nLines are added + deleted, excluding generated reports, CSV, JSON and images. Tests count `func t_` "
          "in `game/tests` at the end commit; mutations count entries in `tests/mutations.json`. Findings sources: "
          + "; ".join(f"{k}: {s}" for k, (_, s) in PLAYTEST.items()) + ".\n",
          "\n## Goal-agent runs\n\n",
          md_table(["run", "agent calls", "tokens", "per call", "agent time", "designer stops"], grows),
          "\nAgent time is the sum of the calls' durations, not wall-clock (scripts and waiting are extra). "
          "Stops count the board's \"Waiting for the designer\" sections.\n",
          f"\n## Mutation testing\n\nAcross every logged `mutate:` line in the goal boards and build reports: "
          f"{caught} of {total} mutations caught" + (f" ({100 * caught / total:.0f}%)" if total else "") +
          ". A surviving mutation sent its test back for a fix round, so the final state is all caught.\n",
          "\n## Learnings per week by cause\n",
          md_table(["week of"] + list(CAUSES) + ["total"],
                   [[w.isoformat()] + [lw[w][c] for c in CAUSES] + [sum(lw[w].values())] for w in weeks]),
          "\n## Charts\n\n" + "\n".join(f"![{n}](charts/{n}.svg)" for n in
                                        ("tokens-per-day", "weekly-usage", "commits-per-day", "tests-per-version",
                                         "learnings-per-week")) + "\n\nDaily numbers behind the charts: `data/daily.csv`.\n"]
    (OUT / "data.md").write_text("\n".join(md), encoding="utf-8")
    print(f"audit_data: {len(vrows)} versions, {len(span)} days, {len(ldates)} learnings, "
          f"mutations {caught}/{total}; wrote {OUT.relative_to(ROOT)}/data.md, data/, charts/")


if __name__ == "__main__":
    main()
