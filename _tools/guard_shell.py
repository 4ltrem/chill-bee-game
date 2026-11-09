#!/usr/bin/env python3
"""PreToolUse hook: turns five of the designer's standing rules into refusals, so they hold without memory.

    hook on Bash|PowerShell|Write|Edit|Artifact in .claude/settings.json (reads the hook JSON on stdin)

Each refusal names the rule and the right way to do it, so the caller rewrites the call and moves on.
  1. no-inline-python: no `python -c`, `node -e`, or code piped or heredoc'd into an interpreter.
     Run a repo script by path (`python -I _tools/<name>.py`) or use grep/Read.
  2. edit-lines-only (team.md rule 5): no `sed -i`, no `>`/`>>`/`tee`/`Set-Content`/`Out-File` onto an
     existing repo file, and no Write over an existing file (except `_meta/memory/`, whose files are
     replaced whole by design). Use Edit on the lines that change.
  3. repo-only (Bash part): no leading `cd` into the repo and no absolute path that points inside it;
     the cwd is already the repo, and absolute paths trip the permission check.
  4. drafts-folder: no Write/Edit outside the repo (temp, scratchpad) except Claude Code's plan files.
     Work a later session needs goes in `_meta/drafts/<version>/`; throwaway output in `game/reports/_runs/`.
  5. one Design Votes page: a `game/reports/ui-compare/` page is published only to the Design Votes
     artifact, and that artifact is never opened in the browser (give the link instead).
  6. goal-run-owns-game: while `_meta/usage/goal-run.lock` exists (goal_agent writes it for a build run and
     removes it at the end), the main session may not Write or Edit in game/scripts, scenes, materials, tests or
     specs: every change goes through the run and its record (2026-11-08, approved C; the main session fixed a
     line of Quinn's test mid-run and the commit credited the goal agent). Such an edit goes in a worktree
     (`.claude/worktrees/`, whose paths are not under game/), merged after the run. The run's own headless agents
     (CHILLBEE_HEADLESS=1) are not bound. A lock older than 12 hours is stale and ignored.
Fails open: a hook input it can't read allows the call. Standard library only.
"""
import json
import os
import re
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESIGN_VOTES = "https://claude.ai/artifact/17i3YsGsf9zD7NowGxtDSa"
LOCK = "_meta/usage/goal-run.lock"
RUN_OWNS = ("game/scripts/", "game/scenes/", "game/materials/", "game/tests/", "game/specs/")
STALE = 12 * 3600
INTERP = r"(?:python3?|py|node|ruby|perl|bash|sh)(?:\.exe)?"
FLAGS = r"(?:\s+-[A-Za-z]+)*"


def norm(path):
    """Lower-case, forward slashes, Git Bash /c/ drive form turned into c:/."""
    p = path.strip().strip("\"'").replace("\\", "/").lower()
    m = re.match(r"^/([a-z])/(.*)", p)
    return f"{m.group(1)}:/{m.group(2)}" if m else p


def inside(path, repo):
    """Repo-relative path if `path` (absolute or relative to the repo) lies in the repo, else None."""
    p, r = norm(path), norm(repo).rstrip("/")
    if not re.match(r"^([a-z]:)?/", p) and not p.startswith("~"):
        p = r + "/" + p
    p = os.path.normpath(p).replace("\\", "/").lower()
    if p == r:
        return ""
    return p[len(r) + 1:] if p.startswith(r + "/") else None


def existing_file(token, repo):
    rel = inside(token, repo)
    return rel is not None and rel != "" and os.path.isfile(os.path.join(repo, rel))


def shell(cmd, repo):
    if re.search(rf"\b(?:python3?|py|node|ruby|perl)(?:\.exe)?{FLAGS}\s+-[ce]\b", cmd) \
            or re.search(rf"\b{INTERP}{FLAGS}(?:\s+-)?\s*<<", cmd) \
            or re.search(rf"\|\s*{INTERP}{FLAGS}(?:\s+-)?\s*(?:$|[;&|)])", cmd, re.M):
        return ("no-inline-python: inline code makes the designer approve every call. "
                "Run a repo script by path (python -I _tools/<name>.py) or use grep/Read.")
    if re.search(r"\b(?:sed|perl)\b[^|;&\n]*\s-[A-Za-z]*i", cmd):
        return "edit-lines-only: no in-place sed/perl. Use the Edit tool on the lines that change."
    targets = re.findall(r"(?<![0-9&<])>>?\s*([^\s|;&<>()]+)", cmd)
    targets += re.findall(r"\btee\s+(?:-a\s+)?([^\s|;&<>()]+)", cmd)
    for m in re.finditer(r"\b(?:Set-Content|Add-Content|Out-File)\b([^|;\n]*)", cmd, re.I):
        targets += re.findall(r"[^\s,]+", m.group(1))
    for t in targets:
        if not t.startswith(("&", "$", "-")) and existing_file(t, repo):
            return (f"edit-lines-only: this rewrites {t.strip(chr(34) + chr(39))}. "
                    "Use the Edit tool on the lines that change (generated files: their own script).")
    m = re.match(r"\s*(?:cd|Set-Location|pushd)\s+(\"[^\"]*\"|'[^']*'|[^\s;&|]+)", cmd, re.I)
    if m and inside(m.group(1), repo) is not None:
        return "repo-only: drop the cd prefix; the cwd is already the repo. Use repo-relative paths."
    low = cmd.replace("\\", "/").lower()
    r = norm(repo).rstrip("/")
    if r in low or ("/" + r[0] + r[2:]) in low:
        return ("repo-only: use a repo-relative path; absolute paths into the repo count as "
                "outside it for the permission check.")
    return None


def write(tool, path, repo):
    rel = inside(path, repo)
    if rel is None:
        if "/.claude/plans/" in norm(path):
            return None
        return ("drafts-folder: write inside the repo. Work a later session needs goes in "
                "_meta/drafts/<version>/ (linked from the handoff); throwaway output in game/reports/_runs/.")
    if tool == "Write" and rel and os.path.isfile(os.path.join(repo, rel)) and not rel.startswith("_meta/memory/"):
        return f"edit-lines-only: {rel} exists. Change it with Edit on the needed lines; Write is for new files."
    lock = os.path.join(repo, LOCK)
    if rel.startswith(RUN_OWNS) and os.environ.get("CHILLBEE_HEADLESS") != "1" and os.path.isfile(lock) \
            and time.time() - os.path.getmtime(lock) < STALE:
        return (f"goal-run-owns-game: a goal run is live ({LOCK}), so the main folder's {rel} changes only through "
                "it. Make this edit in a worktree (EnterWorktree, under .claude/worktrees/), commit it there, and "
                "merge it after the run; remove the worktree once merged.")
    return None


def artifact(inp):
    action = inp.get("action") or "publish"
    url = (inp.get("url") or "").rstrip("/")
    if action == "open" and url == DESIGN_VOTES:
        return "one Design Votes page: don't open it in the browser; give the designer the link."
    path = norm(inp.get("file_path") or "")
    if action == "publish" and "game/reports/ui-compare/" in path and not inp.get("asset") and url != DESIGN_VOTES:
        return (f"one Design Votes page: add a section with compare_page.py add and publish to {DESIGN_VOTES}; "
                "never a separate artifact.")
    return None


def decide(tool, inp, repo=REPO):
    """The refusal reason for this call, or None to let it through."""
    if tool in ("Bash", "PowerShell"):
        return shell(inp.get("command") or "", repo)
    if tool in ("Write", "Edit"):
        return write(tool, inp.get("file_path") or "", repo)
    if tool == "Artifact":
        return artifact(inp)
    return None


def main():
    try:
        event = json.load(sys.stdin)
        reason = decide(event.get("tool_name", ""), event.get("tool_input") or {})
    except Exception:
        return 0
    if reason:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                                 "permissionDecisionReason": reason}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
