#!/usr/bin/env python3
"""Status line: show plan usage and save each new reading for the run log.

Claude Code runs this after each response with the session's status JSON on stdin. On a Pro plan it
holds `rate_limits.five_hour.used_percentage` and `rate_limits.seven_day.used_percentage` (the
figures /usage shows). Each change is appended to _meta/usage/readings.jsonl (local, gitignored):
only the time, session id and the two percentages, never any conversation content. runlog.py reads
them to put usage before and after on every run. A status line must never fail, so errors only
fall back to a plain line.

Test by hand:  echo '{"rate_limits": {"five_hour": {"used_percentage": 12}}}' | python -I _tools/statusline.py
Standard library only.
"""
import datetime
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "_tools"))  # -I leaves the script's folder off sys.path


def pct(data, window):
    v = ((data.get("rate_limits") or {}).get(window) or {}).get("used_percentage")
    return v if isinstance(v, (int, float)) else None


def save(reading, path):
    """Append the reading unless it repeats the last one."""
    path.parent.mkdir(parents=True, exist_ok=True)
    last = None
    if path.is_file():
        tail = path.read_text(encoding="utf-8").splitlines()[-1:]
        try:
            last = json.loads(tail[0]) if tail else None
        except ValueError:
            last = None
    same = last and all(last.get(k) == reading[k] for k in ("five_hour", "seven_day", "session"))
    if not same:
        with path.open("a", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps(reading) + "\n")


def live(root=None, at=None):
    """The headless agents and script steps running now (_meta/usage/live.json, see live.py), grouped by what
    their loop is on: '▶ goal 0.1.4 · C5 · Patricia 4m · Bob 2m · unit 2m (45 passed)'. A dead process and an
    entry over 12 h old are left out."""
    try:
        import live as lv
    except ImportError:
        return ""
    groups = {}
    for r in lv.running(root or ROOT, at):
        note = r.get("note", "") if r.get("kind") == "step" else ""
        note = f" ({note.split(' · ')[0][:28]})" if note else ""
        groups.setdefault(r.get("tag") or "run", []).append(f"{r.get('agent', '?')} {r['mins']}m{note}")
    return " | ".join(f"▶ {tag} · " + " · ".join(names) for tag, names in groups.items())


def line(data, root=None):
    five, week = pct(data, "five_hour"), pct(data, "seven_day")
    model = ((data.get("model") or {}).get("display_name")) or ""
    running = live(root)
    if five is None and week is None:
        return " · ".join(x for x in (model, "usage: no reading yet", running) if x)
    show = lambda v: "?" if v is None else f"{v:g}%"
    return " · ".join(x for x in (model, f"5h {show(five)}", f"week {show(week)}", running) if x)


def main(raw, root=None):
    data = json.loads(raw or "{}")
    five, week = pct(data, "five_hour"), pct(data, "seven_day")
    if (five is not None or week is not None) and data.get("session_id"):   # no session: a hand test, not saved
        stamp = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
        reading = {"ts": stamp, "session": data.get("session_id", ""), "five_hour": five, "seven_day": week}
        resets = ((data.get("rate_limits") or {}).get("seven_day") or {}).get("resets_at")
        if isinstance(resets, (int, float)):   # epoch seconds; budget_guard.py paces the week by it
            resets = datetime.datetime.fromtimestamp(resets, datetime.timezone.utc).isoformat()
        if isinstance(resets, str) and resets:
            reading["week_resets"] = resets
        save(reading, (root or ROOT) / "_meta" / "usage" / "readings.jsonl")
    return line(data, root)


if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # Windows pipes default to cp1252
        print(main(sys.stdin.read()))
    except Exception:
        print("usage: status line error")
    sys.exit(0)
