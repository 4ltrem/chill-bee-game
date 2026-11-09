#!/usr/bin/env python3
"""Export Chill Bee Game: set the version, export Windows and Web, zip the web build, smoke-test it.

    python -I _tools/build.py VERSION [--targets windows,web] [--no-zip] [--smoke] [--root game]

One command for what Quinn did by hand in every build run (about a third of his 0.1.0 run's tokens):
  1. writes `config/version="VERSION"` into game/project.godot;
  2. exports each target with its preset (`Windows Desktop` -> builds/windows/ChillBeeGame.exe,
     `Web` -> builds/web/index.html); Godot 4.2.1 sometimes crashes (exit 139) on the first export of a
     session, so a failed export is retried once;
  3. zips builds/web as builds/chill-bee-game-VERSION-web.zip with index.html at the zip root (for itch.io);
  4. with --smoke: serves builds/web with the COOP/COEP headers itch.io's SharedArrayBuffer option gives,
     loads it in headless Edge at 720x1280 and saves a screenshot to game/reports/_runs/smoke-VERSION.png.
     Only the page booting is checked, not input.
`python -I _tools/build.py VERSION --serve 8060` only serves builds/web with those headers, for a real-browser check.
Prints one line per step; exit 0 only when every step passed. Standard library only.
"""
import argparse
import functools
import http.server
import os
import re
import subprocess
import sys
import threading
import time
import zipfile

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
GODOT = os.environ.get("GODOT", r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe")
EDGE = os.environ.get("EDGE", r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
TARGETS = {
    "windows": ("Windows Desktop", "builds/windows/ChillBeeGame.exe"),
    "web": ("Web", "builds/web/index.html"),
    "android": ("Android", "builds/android/chill-bee-game.apk"),
}
VERSION = re.compile(r"^\d+\.\d+\.\d+$")


def set_version(root, version):
    path = os.path.join(root, "project.godot")
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    if re.search(r'^config/version=".*"$', text, re.M):
        text = re.sub(r'^config/version=".*"$', f'config/version="{version}"', text, flags=re.M)
    else:
        text = text.replace("[application]\n", f'[application]\n\nconfig/version="{version}"\n', 1)
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


def export(root, target):
    preset, rel = TARGETS[target]
    out = os.path.join(root, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    before = os.path.getmtime(out) if os.path.exists(out) else 0
    for attempt in (1, 2):
        proc = subprocess.run([GODOT, "--headless", "--path", root, "--export-release", preset, rel],
                              capture_output=True, text=True, errors="replace", timeout=900)
        fresh = os.path.exists(out) and os.path.getmtime(out) > before
        if proc.returncode == 0 and fresh:
            return True, f"{rel} ({os.path.getsize(out):,} bytes, attempt {attempt})"
    tail = (proc.stdout + proc.stderr).strip().splitlines()[-3:]
    return False, f"{rel}: export failed (exit {proc.returncode}): " + " / ".join(tail)


def zip_web(root, version):
    web = os.path.join(root, "builds", "web")
    dest = os.path.join(root, "builds", f"chill-bee-game-{version}-web.zip")
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as zf:
        for dirpath, _, files in os.walk(web):
            for f in files:
                full = os.path.join(dirpath, f)
                zf.write(full, os.path.relpath(full, web))
    with zipfile.ZipFile(dest) as zf:
        names = zf.namelist()
    ok = "index.html" in names
    return ok, f"{os.path.relpath(dest, REPO)} ({os.path.getsize(dest):,} bytes, index.html at root: {ok})"


class IsolatedHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *args):
        pass


def smoke(root, version):
    if not os.path.exists(EDGE):
        return False, f"Edge not found at {EDGE} (set EDGE)"
    web = os.path.join(root, "builds", "web")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(IsolatedHandler, directory=web))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_address[1]}/index.html"
    shot = os.path.join(root, "reports", "_runs", f"smoke-{version}.png")
    os.makedirs(os.path.dirname(shot), exist_ok=True)
    try:
        subprocess.run([EDGE, "--headless=new", "--disable-gpu-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
                        "--window-size=720,1280", "--virtual-time-budget=100000", f"--screenshot={shot}", url],
                       capture_output=True, timeout=240)
    finally:
        server.shutdown()
    ok = os.path.exists(shot) and os.path.getsize(shot) > 10_000
    return ok, f"{os.path.relpath(shot, REPO)} ({os.path.getsize(shot) if os.path.exists(shot) else 0:,} bytes; look at it to confirm the farm drew)"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("version")
    ap.add_argument("--targets", default="windows,web")
    ap.add_argument("--no-zip", action="store_true")
    ap.add_argument("--smoke", action="store_true")
    ap.add_argument("--root", default=os.path.join(REPO, "game"))
    ap.add_argument("--serve", type=int, metavar="PORT", help="only serve builds/web (itch's COOP/COEP headers) until Ctrl+C")
    args = ap.parse_args(argv)
    if args.serve:   # the designer's real-browser check: headless Edge shows only the loading spinner (0.1.3 open item)
        web = os.path.join(os.path.abspath(args.root), "builds", "web")
        server = http.server.ThreadingHTTPServer(("127.0.0.1", args.serve), functools.partial(IsolatedHandler, directory=web))
        print(f"serving {os.path.relpath(web, REPO)} at http://127.0.0.1:{args.serve}/index.html (Ctrl+C to stop)", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        return 0
    if not VERSION.match(args.version):
        ap.error("VERSION must look like 0.1.2")
    root = os.path.abspath(args.root)
    targets = [t.strip() for t in args.targets.split(",") if t.strip()]
    steps = []
    set_version(root, args.version)
    steps.append((True, f"version {args.version} in project.godot"))
    for t in targets:
        if t not in TARGETS:
            ap.error(f"unknown target {t}; choose from {list(TARGETS)}")
        steps.append(export(root, t))
    if "web" in targets and not args.no_zip and steps[-1][0]:
        steps.append(zip_web(root, args.version))
    if args.smoke and "web" in targets:
        steps.append(smoke(root, args.version))
    for ok, msg in steps:
        print(("OK    " if ok else "FAIL  ") + msg)
    return 0 if all(ok for ok, _ in steps) else 1


if __name__ == "__main__":
    sys.exit(main())
