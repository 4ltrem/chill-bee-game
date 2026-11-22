#!/usr/bin/env python3
"""Watch the headless agents and script steps in a terminal split: one line per start, end, progress note and tool call.

    python -I _tools/watch.py              # what runs now, the last 15 events, then follow (Ctrl+C stops)
    python -I _tools/watch.py --once       # what runs now and the last 15 events, then exit
    python -I _tools/watch.py --last 40 --only Patricia

Reads _meta/usage/live.json and live.log (see live.py). When nothing new comes for 30 s it prints what is still
running and for how long, so a long unit run never looks stalled (L5). Standard library only.
"""
import argparse
import datetime
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I leaves the script's folder off sys.path
import live  # noqa: E402

MARK = {"start": "▶", "end": "■", "note": "…", "tool": "·"}


def local(ts):
    try:
        t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return t.astimezone().strftime("%H:%M:%S")
    except (ValueError, AttributeError):
        return "--:--:--"


def fmt(rec):
    """One event as a line: '18:28:41 · Patricia  Edit game/scripts/main.gd   [goal 0.2 · C14]'."""
    kind = rec.get("kind", "")
    mark = MARK.get(kind, "?")
    if kind == "end":
        mark = "✓" if rec.get("ok", True) else "✗"
    text = rec.get("text") or ""
    if kind == "start":
        text = text or ("agent started" if rec.get("item") == "agent" else "started")
    if kind == "end":
        secs = rec.get("seconds")
        took = f"{secs // 60}m{secs % 60:02d}s" if isinstance(secs, int) else ""
        text = " ".join(x for x in (text or "done", took and f"in {took}") if x)
    tag = f"   [{rec['tag']}]" if rec.get("tag") else ""
    return f"{local(rec.get('ts', ''))} {mark} {rec.get('name', '?'):<14} {text}{tag}"


def now_line(root=None):
    items = live.running(root)
    if not items:
        return "(nothing running)"
    return "running: " + " · ".join(
        f"{r.get('agent', '?')} {r['mins']}m" + (f" ({r['note'][:40]})" if r.get("note") else "") for r in items)


def read_events(path, only=None):
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    out = []
    for l in lines:
        try:
            rec = json.loads(l)
        except ValueError:
            continue
        if not only or rec.get("name") == only:
            out.append(rec)
    return out


def follow(path, only=None, idle=30, poll=0.5):
    pos = path.stat().st_size if path.is_file() else 0
    quiet = time.monotonic()
    while True:
        try:
            size = path.stat().st_size if path.is_file() else 0
        except OSError:
            size = 0
        if size < pos:   # rotated
            pos = 0
        if size > pos:
            with path.open("r", encoding="utf-8") as f:
                f.seek(pos)
                chunk = f.read()
                pos = f.tell()
            for l in chunk.splitlines():
                try:
                    rec = json.loads(l)
                except ValueError:
                    continue
                if not only or rec.get("name") == only:
                    print(fmt(rec), flush=True)
                    quiet = time.monotonic()
        elif time.monotonic() - quiet > idle:
            print(f"{datetime.datetime.now().strftime('%H:%M:%S')}   {now_line()}", flush=True)
            quiet = time.monotonic()
        time.sleep(poll)


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--once", action="store_true", help="print the state and recent events, then exit")
    ap.add_argument("--last", type=int, default=15, help="how many past events to show first")
    ap.add_argument("--only", help="show one name only (Patricia, unit, git commit)")
    a = ap.parse_args(argv)
    print(now_line())
    for rec in read_events(live.LOG, a.only)[-a.last:] if a.last else []:
        print(fmt(rec))
    if a.once:
        return 0
    print("-- following (Ctrl+C stops) --", flush=True)
    try:
        follow(live.LOG, a.only)
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
