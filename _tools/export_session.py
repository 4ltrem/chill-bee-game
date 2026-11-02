#!/usr/bin/env python3
"""Copy a Claude Code session transcript into the workspace, for analysis and episodic memory.

    python -I _tools/export_session.py [SESSION_ID]

SESSION_ID defaults to the most recently updated session of this workspace. Claude Code keeps
each session as one JSONL file (one JSON object per line: every message, tool call, tool result
and token count) in ~/.claude/projects/<workspace path with separators as dashes>/, and the
transcripts of subagents it launched in <SESSION_ID>/subagents/. Both are copied unchanged to
_meta/sessions/<date>-<first 8 of SESSION_ID>/, with a manifest.json summarising them. Re-running
refreshes the copy. _meta/sessions/ is gitignored: transcripts hold the account email and
everything read during the session. Standard library only.
"""
import collections
import datetime
import json
import re
import shutil
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent


def project_dir():
    base = Path.home() / ".claude" / "projects"
    name = re.sub(r"[:\\/]", "-", str(ROOT)).lower()
    match = [d for d in base.iterdir() if d.is_dir() and d.name.lower() == name] if base.is_dir() else []
    if not match:
        sys.exit(f"no Claude Code project folder for {ROOT} under {base}")
    return match[0]


def summarise(path):
    types, first, last, lines = collections.Counter(), None, None, 0
    with path.open(encoding="utf-8") as f:
        for line in f:
            lines += 1
            try:
                obj = json.loads(line)
            except ValueError:
                continue
            types[obj.get("type", "?")] += 1
            stamp = obj.get("timestamp")
            if stamp:
                first, last = first or stamp, stamp
    return {"file": path.name, "bytes": path.stat().st_size, "lines": lines,
            "first_timestamp": first, "last_timestamp": last, "entries_by_type": dict(types.most_common())}


def main():
    src = project_dir()
    if len(sys.argv) > 1:
        session = src / f"{sys.argv[1]}.jsonl"
        if not session.is_file():
            sys.exit(f"no session {sys.argv[1]} in {src}")
    else:
        sessions = sorted(src.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
        if not sessions:
            sys.exit(f"no sessions in {src}")
        session = sessions[-1]
    sid = session.stem
    started = summarise(session)["first_timestamp"] or datetime.date.today().isoformat()
    dest = ROOT / "_meta" / "sessions" / f"{started[:10]}-{sid[:8]}"
    dest.mkdir(parents=True, exist_ok=True)

    shutil.copy2(session, dest / "session.jsonl")
    manifest = {"session_id": sid, "exported": datetime.datetime.now().isoformat(timespec="seconds"),
                "source": str(session), "session": summarise(dest / "session.jsonl"), "subagents": []}
    subagents = src / sid / "subagents"
    if subagents.is_dir():
        shutil.copytree(subagents, dest / "subagents", dirs_exist_ok=True)
        for t in sorted((dest / "subagents").glob("*.jsonl")):
            meta = t.with_suffix(".meta.json")
            entry = summarise(t)
            if meta.is_file():
                entry["meta"] = json.loads(meta.read_text(encoding="utf-8"))
            manifest["subagents"].append(entry)
    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8", newline="\n")
    s = manifest["session"]
    print(f"exported {sid} -> {dest.relative_to(ROOT).as_posix()}/: {s['lines']:,} entries, "
          f"{s['bytes'] / 1e6:.1f} MB, {len(manifest['subagents'])} subagent transcript(s)")


if __name__ == "__main__":
    main()
