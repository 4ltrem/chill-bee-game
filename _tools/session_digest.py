#!/usr/bin/env python3
"""Print an exported session's decision material: the designer's own messages and AskUserQuestion answers, timestamped.

    python -I _tools/session_digest.py _meta/sessions/<folder> [<folder> ...] [--out]

For logging a session's decisions after the fact (the end-of-day skill, step 2) without reading its whole transcript:
decisions happen in the designer's messages and quiz answers. Timestamps are UTC as in the transcript (date decisions
in Toronto time). --out writes `digest.txt` beside each transcript instead (gitignored, like the transcript: it holds
what the session read). Standard library only.
"""
import json
import sys
from pathlib import Path

ANSWERED = ("questions have been answered", "User has answered")


def lines(transcript):
    """[(utc minute, kind, text)] for the main session's user messages and quiz answers, each user message after the
    end of the assistant text it answers (ASKED), since a reply like "1 yes, b" means nothing alone."""
    out, said = [], ""
    for raw in Path(transcript).open(encoding="utf-8", errors="replace"):
        try:
            e = json.loads(raw)
        except ValueError:
            continue
        if e.get("isSidechain"):
            continue
        if e.get("type") == "assistant":
            for part in e.get("message", {}).get("content") or []:
                if isinstance(part, dict) and part.get("type") == "text" and part["text"].strip():
                    said = part["text"].strip()
            continue
        if e.get("type") != "user":
            continue
        ts = (e.get("timestamp") or "")[:16]
        content = e.get("message", {}).get("content")
        parts = [{"type": "text", "text": content}] if isinstance(content, str) else (content or [])
        for part in parts:
            if part.get("type") == "text":
                t = part["text"].strip()
                if t and not t.startswith("<") and not t.startswith("[Request interrupted") \
                        and not t.startswith("Another Claude session sent"):
                    if said:
                        out.append((ts, "ASKED", "..." + said[-900:].replace("\n", " ")))
                        said = ""
                    out.append((ts, "USER", t[:700]))
            elif part.get("type") == "tool_result":
                c = part.get("content")
                c = c if isinstance(c, str) else " ".join(x.get("text", "") for x in (c or []) if isinstance(x, dict))
                if any(a in c for a in ANSWERED):
                    out.append((ts, "ANSWER", c[:900]))
    return out


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = list(sys.argv[1:] if argv is None else argv)
    write = "--out" in args
    for folder in [Path(a) for a in args if a != "--out"]:
        text = "".join(f"[{ts}] {kind}: {t}\n" for ts, kind, t in lines(folder / "session.jsonl"))
        if write:
            (folder / "digest.txt").write_text(text, encoding="utf-8")
            print(f"{folder.as_posix()}/digest.txt: {len(text):,} chars")
        else:
            print(f"######## {folder.as_posix()}\n{text}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
