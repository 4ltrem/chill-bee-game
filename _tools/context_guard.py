#!/usr/bin/env python3
"""PostToolUse and UserPromptSubmit hook: warn the main session when its context window fills up.

Claude Code runs this after each tool call and each prompt, with the hook input as JSON on stdin (session_id,
transcript_path, hook_event_name). The context in use is the last API call in the transcript:
input + cache write + cache read tokens. When it crosses a threshold (default 50% and 75% of the
window) that was not warned yet, the hook prints additionalContext telling the session to finish its
step, rewrite _meta/memory/session-handoff.md and ask the designer to /clear. Each threshold is
warned once per session; what was warned is kept in _meta/usage/context-guard.json by session id.
Only the highest newly crossed threshold is reported, and every crossed one is marked warned.

Subagents (agent_id in the input) and headless `claude -p` runs (CHILLBEE_HEADLESS=1) are skipped.
A hook must never break the session, so any failure prints a warning to stderr and exits 0.

Test by hand:  python -I _tools/context_guard.py --transcript PATH --window 1000000
Standard library only.
"""
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import runlog  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
WINDOW = 1000000
AT = (50, 75)
MESSAGE = ("Context is at {pct}% of the window. Finish the current step, rewrite "
           "`_meta/memory/session-handoff.md` to the current state, and tell the designer to run /clear.")


def context_used(transcript):
    """Tokens in the context at the transcript's last API call (0 if there is none)."""
    calls = runlog.calls(transcript)
    if not calls:
        return 0
    usage = calls[-1][1]
    return sum(usage.get(k, 0) or 0 for k in
               ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))


def decide(used, window, warned, at):
    """The highest threshold (%) crossed and not warned yet, or None."""
    pct = used * 100 / window
    new = [t for t in at if pct >= t and t not in warned]
    return max(new) if new else None


def main(argv, stdin_text=None, root=None):
    root = Path(root) if root else ROOT
    args = list(argv)

    def flag(name, default):
        return args[args.index(name) + 1] if name in args else default

    window = int(flag("--window", WINDOW))
    at = tuple(int(x) for x in str(flag("--at", ",".join(map(str, AT)))).split(","))
    path = flag("--transcript", None)
    event = "PostToolUse"
    if path:
        key = Path(path).stem
    else:
        data = json.loads(stdin_text if stdin_text is not None else sys.stdin.read() or "{}")
        if data.get("agent_id") or os.environ.get("CHILLBEE_HEADLESS"):
            return 0
        path, key = os.path.expanduser(data.get("transcript_path") or ""), data.get("session_id")
        event = data.get("hook_event_name") or event
    if not path or not key:
        return 0
    used = context_used(path)
    store = root / "_meta" / "usage" / "context-guard.json"
    try:
        state = json.loads(store.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        state = {}
    warned = state.get(key, [])
    hit = decide(used, window, warned, at)
    if hit is None:
        return 0
    pct = int(used * 100 / window)
    state[key] = sorted(set(warned) | {t for t in at if used * 100 / window >= t})
    store.parent.mkdir(parents=True, exist_ok=True)
    store.write_text(json.dumps(state, indent=1), encoding="utf-8")
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event,
                                             "additionalContext": MESSAGE.format(pct=pct)}}))
    return 0


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as e:  # a hook must never break the session
        print(f"context_guard: {e}", file=sys.stderr)
    sys.exit(0)
