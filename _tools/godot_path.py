"""Where the Godot console binary is, for every script that runs Godot.

Order: the GODOT environment variable, then the copy unpacked in the repo folder
(`Godot_v4.2.1-stable_win64.exe/`, gitignored: the laptop), then the desktop's copy.
Run it alone to print the path in use; with arguments it runs Godot with them and returns
its exit code (Bob's renders: `python -I _tools/godot_path.py --path game --script ...`),
so agents and permission rules never name a machine's path.
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCAL = os.path.join(REPO, "Godot_v4.2.1-stable_win64.exe", "Godot_v4.2.1-stable_win64_console.exe")
DESKTOP = r"C:\Users\mtrem\Desktop\Godot_v4.2.1-stable_win64_console.exe"
GODOT = os.environ.get("GODOT") or (LOCAL if os.path.isfile(LOCAL) else DESKTOP)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        sys.exit(subprocess.call([GODOT, *sys.argv[1:]]))
    print(GODOT, "(found)" if os.path.isfile(GODOT) else "(MISSING)")
