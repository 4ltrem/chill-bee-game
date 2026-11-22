#!/usr/bin/env python3
"""What runs right now: the headless agents and the scripts' own steps, for the status line, watch.py and the pane.

Three local files under _meta/usage/ (gitignored, never committed):
- live.json: {key: entry} for each thing running now. An entry has `agent` (a name: Patricia, unit, mutate,
  git commit), `kind` (agent or step), `tag` (what its loop is on: "goal 0.2 · C14"), `start`, `pid`, and an
  optional `note` (progress: "45 passed, 1 failed · t_shop_rows"). statusline.py shows it.
- live.log: one JSON line per event (start, end, note, tool call), for watch.py to follow. Rotated at 2 MB.
- live/<key>.jsonl: an agent's full stream-json output while it runs (generate.run_agent), kept until the next run.

A loop sets the tag with set_tag(); a script it starts inherits it through the CHILLBEE_LIVE_TAG environment
variable, so godot_run.py's suites show under the goal step that ran them. Nothing here may fail a run: every
write swallows its errors. Standard library only.
"""
import contextlib
import datetime
import json
import os
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIR = ROOT / "_meta" / "usage"
FILE = DIR / "live.json"
LOG = DIR / "live.log"
STREAMS = DIR / "live"
LOG_MAX = 2_000_000
ENV_TAG = "CHILLBEE_LIVE_TAG"

_lock = threading.Lock()
_tag = [os.environ.get(ENV_TAG, "")]


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def set_tag(tag):
    """What the running loop is on; agents and steps started after this carry it, and so do child scripts."""
    _tag[0] = tag
    os.environ[ENV_TAG] = tag


def tag():
    return _tag[0]


def update(key, entry=None, path=None):
    """Add (entry), merge into (entry with only some fields, existing key) or remove (None) one running item."""
    path = path or FILE
    with _lock:
        try:
            cur = json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}
        except (OSError, ValueError):
            cur = {}
        if entry is None:
            cur.pop(key, None)
        else:
            cur[key] = entry
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            tmp = path.with_suffix(".tmp")
            tmp.write_text(json.dumps(cur), encoding="utf-8")
            os.replace(tmp, path)
        except OSError:
            pass


def event(kind, name, text="", path=None, **extra):
    """Append one line to live.log: {ts, kind, name, tag, text}. kind: start, end, note, tool."""
    path = path or LOG
    rec = {"ts": now_iso(), "kind": kind, "name": name, "tag": extra.pop("tag", _tag[0]), "text": text, **extra}
    with _lock:
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.is_file() and path.stat().st_size > LOG_MAX:
                os.replace(path, path.with_suffix(".log.1"))
            with path.open("a", encoding="utf-8", newline="\n") as f:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        except OSError:
            pass


def new_key(name):
    return f"{os.getpid()}-{threading.get_ident()}-{name}-{time.monotonic_ns() % 10**9}"


def start(name, kind="step", key=None, text="", root=None):
    """Mark one item running; returns its key for note() and end()."""
    key = key or new_key(name)
    base = Path(root) / "_meta" / "usage" if root else None
    prune(base / "live.json" if base else None)
    update(key, {"agent": name, "kind": kind, "tag": _tag[0], "start": now_iso(), "pid": os.getpid()},
           base / "live.json" if base else None)
    event("start", name, text, base / "live.log" if base else None, item=kind)
    return key


def note(key, text, every=2.0, _last={}):
    """Set an item's progress note (at most once per `every` seconds; the last call wins at end())."""
    t = time.monotonic()
    if t - _last.get(key, 0) < every:
        return
    _last[key] = t
    with _lock:
        try:
            cur = json.loads(FILE.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return
    if key in cur:
        cur[key]["note"] = text
        update(key, cur[key])


def end(key, name, text="", ok=True, seconds=None):
    update(key)
    event("end", name, text, ok=ok, seconds=seconds)


@contextlib.contextmanager
def step(name, text="", kind="step"):
    """`with live.step("unit") as s:` shows `unit` while the block runs; s.note("45 passed") sets its progress,
    s.result = "PASS" (or s.ok = False) goes into the end event."""
    class S:
        ok, result = True, ""

        def note(self, t):
            note(self.key, t)
    s = S()
    s.key = start(name, kind, text=text)
    began = time.monotonic()
    try:
        yield s
    except BaseException:
        s.ok = False
        raise
    finally:
        end(s.key, name, s.result, ok=s.ok, seconds=round(time.monotonic() - began))


def alive(pid):
    """Is this process still running? Unknown counts as alive (the age limit still applies)."""
    if not isinstance(pid, int) or pid <= 0:
        return True
    if os.name == "nt":
        try:
            import ctypes
            k = ctypes.windll.kernel32
            h = k.OpenProcess(0x1000, False, pid)   # PROCESS_QUERY_LIMITED_INFORMATION
            if not h:
                return False
            code = ctypes.c_ulong()
            ok = k.GetExitCodeProcess(h, ctypes.byref(code))
            k.CloseHandle(h)
            return not ok or code.value == 259   # STILL_ACTIVE
        except Exception:
            return True
    try:
        os.kill(pid, 0)   # signal 0 only checks on POSIX (on Windows os.kill terminates: never reached there)
        return True
    except ProcessLookupError:
        return False
    except OSError:
        return True


def running(root=None, at=None, max_hours=12):
    """The live items, oldest first, each with `mins`; dead processes and items over max_hours (3 h without a
    pid) are left out."""
    try:
        cur = json.loads(((Path(root) / "_meta" / "usage") if root else DIR).joinpath("live.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return []
    at = at or datetime.datetime.now(datetime.timezone.utc)
    out = []
    for key, r in sorted(cur.items(), key=lambda kv: kv[1].get("start", "")):
        try:
            mins = int((at - datetime.datetime.fromisoformat(r["start"].replace("Z", "+00:00"))).total_seconds() // 60)
        except (KeyError, ValueError, AttributeError, TypeError):
            continue
        limit = max_hours * 60 if r.get("pid") else 180   # no pid to check (older entries): 3 h, as before
        if 0 <= mins < limit and alive(r.get("pid")):
            out.append({**r, "key": key, "mins": mins})
    return out


def prune(path=None):
    """Drop entries whose process has ended (a killed run), so the pane, which can't check a pid, stays true."""
    path = path or FILE
    try:
        cur = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return
    for key, r in cur.items():
        if not alive(r.get("pid")):
            update(key, None, path)


def display(agent):
    """An agent file's roster name ("programmer" -> "Patricia", from its description "Patricia, the Programmer")."""
    try:
        text = (ROOT / ".claude" / "agents" / f"{agent}.md").read_text(encoding="utf-8")
        for line in text.splitlines()[:12]:
            if line.startswith("description:"):
                first = line.split(":", 1)[1].strip().strip("\"'").split(",")[0].strip()
                return first if first and " " not in first else agent
    except OSError:
        pass
    return agent


def prune_streams(days=3):
    """Drop agent stream files older than `days` (the kept transcripts hold the full record)."""
    cut = time.time() - days * 86400
    try:
        for p in STREAMS.glob("*.jsonl"):
            if p.stat().st_mtime < cut:
                p.unlink()
    except OSError:
        pass


def tool_line(msg):
    """One short line for a stream-json assistant message's tool calls: 'Edit game/scripts/main.gd'."""
    parts = []
    for c in ((msg.get("message") or {}).get("content") or []):
        if not isinstance(c, dict) or c.get("type") != "tool_use":
            continue
        i = c.get("input") or {}
        path = i.get("file_path") or i.get("path")
        arg = (str(path).replace("\\", "/") if path else
               i.get("pattern") or i.get("command") or i.get("url") or i.get("description") or i.get("query") or "")
        arg = str(arg).replace(str(ROOT).replace("\\", "/") + "/", "").replace(str(ROOT) + "\\", "")
        arg = " ".join(arg.split())
        parts.append(f"{c.get('name', '?')} {arg[:90]}".strip())
    return " · ".join(parts)
