#!/usr/bin/env python3
"""Print the game's code map: what each script offers and which scene nodes exist, so an agent reads one slice
instead of grepping every script for `signal |^func |^var` (0.3.1 run: Patricia's C4 call, 1.8M tokens, 58 turns,
most of them that grep; Bob read main.tscn 13 times in C6).

    python -I _tools/code_map.py [--root game] [--for NAME[,NAME...]] [--scripts-only | --nodes-only]

Scripts (game/scripts/*.gd): class_name and base, the header comment's first line, signals, public functions
with their signatures, @export values, the config values read (`config.x` / `cfg.x`), the nodes looked up by
name (`find_child("X")`, `%X`) and the tr() keys used.
Nodes (every top-level-free .tscn under game/scenes): name, type, parent path and script. A node name used twice
in one scene is listed under "Duplicate names", since `find_child` returns whichever comes first (0.3.1 C4 fix 2:
two `HintLabel` nodes).
--for keeps only the scripts that name, declare or look up any of the given words (a node, signal, function,
config value or class), and the nodes whose name or path contains one; the goal agent passes a goal's node names.
Standard library only; read-only. Exit code 0.
"""
import argparse
import os
import re
import sys

CLASS = re.compile(r'^class_name\s+(\w+)', re.M)
EXTENDS = re.compile(r'^extends\s+(\S+)', re.M)
SIGNAL = re.compile(r'^signal\s+(\w+)(\([^)]*\))?', re.M)
FUNC = re.compile(r'^(static\s+)?func\s+([a-zA-Z]\w*)\s*(\([^)]*\))\s*(->\s*[\w\[\]]+)?', re.M)
EXPORT = re.compile(r'^@export(?:_\w+(?:\([^)]*\))?)?\s+var\s+(\w+)\s*(:\s*[\w\[\]]+)?(?:\s*=\s*([^#\n]+))?', re.M)
CONFIG = re.compile(r'\b(?:config|_config|cfg|_cfg)\.([a-z_]\w*)\b')
CONFIG_FUNCS = {"get", "set", "duplicate", "resource_path", "has", "connect"}
FIND_CHILD = re.compile(r'find_child\(\s*"([^"]+)"')
UNIQUE = re.compile(r'(?<![\w"])%([A-Za-z_]\w*)')   # read with string literals blanked, so "%d" is not a lookup
STRING = re.compile(r'"(?:[^"\\]|\\.)*"')
CREATED = re.compile(r'\.name\s*=\s*"([A-Za-z_]\w*)"')   # nodes a script builds at run time (shop_ui.gd's ShopButton)
TR = re.compile(r'\btr\(\s*"([^"]+)"')
NODE = re.compile(r'^\[node\s+(.*)\]\s*$')
ATTR = re.compile(r'(\w+)=("(?:[^"\\]|\\.)*"|\S+)')
EXT = re.compile(r'^\[ext_resource\s+(.*)\]\s*$')


def header_line(text):
    """The first line of the script's leading comment block, without the '# '."""
    for line in text.splitlines():
        if line.startswith("#"):
            return line.lstrip("# ").strip()
        if line.strip():
            break
    return ""


def script_entry(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    code = "\n".join(l.split("#", 1)[0] if not l.lstrip().startswith("#") else "" for l in text.splitlines())
    cls = CLASS.search(text)
    ext = EXTENDS.search(text)
    return {
        "file": os.path.basename(path),
        "class": cls.group(1) if cls else "",
        "extends": ext.group(1) if ext else "",
        "about": header_line(text),
        "signals": [m.group(1) + (m.group(2) or "") for m in SIGNAL.finditer(text)],
        "funcs": [("static " if m.group(1) else "") + m.group(2) + re.sub(r"\s+", " ", m.group(3))
                  + (" " + m.group(4) if m.group(4) else "") for m in FUNC.finditer(text)],
        "exports": [m.group(1) + (" = " + m.group(3).strip() if m.group(3) else "") for m in EXPORT.finditer(text)],
        "config": sorted({k for k in CONFIG.findall(code) if k not in CONFIG_FUNCS}),
        "lookups": sorted(set(FIND_CHILD.findall(text)) | set(UNIQUE.findall(STRING.sub('""', code)))),
        "created": sorted(set(CREATED.findall(text))),
        "tr": sorted(set(TR.findall(text))),
    }


def scene_nodes(path, root):
    """[(name, type, parent path, script file)] in file order."""
    scripts, nodes = {}, []
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()
    for line in lines:
        m = EXT.match(line)
        if m:
            a = dict(ATTR.findall(m.group(1)))
            if a.get("type", "").strip('"') == "Script":
                scripts[a.get("id", "").strip('"')] = os.path.basename(a.get("path", "").strip('"'))
            continue
        m = NODE.match(line)
        if m:
            a = {k: v.strip('"') for k, v in ATTR.findall(m.group(1))}
            nodes.append([a.get("name", "?"), a.get("type", "instance" if "instance" in a else "?"),
                          a.get("parent", ""), ""])
            continue
        if nodes and line.startswith("script = ExtResource("):
            nodes[-1][3] = scripts.get(re.sub(r'^script = ExtResource\(\s*"?([^")]+?)"?\s*\)\s*$', r"\1", line), "")
    return nodes


def matches(entry, words):
    hay = " ".join([entry["file"], entry["class"], " ".join(entry["signals"]), " ".join(entry["funcs"]),
                    " ".join(entry["exports"]), " ".join(entry["config"]), " ".join(entry["lookups"]),
                    " ".join(entry["created"])])
    return any(re.search(r"\b" + re.escape(w) + r"\b", hay) for w in words)


def render_scripts(entries):
    out = ["## Scripts", ""]
    for e in entries:
        title = f"### `{e['file']}`" + (f" — `{e['class']}`" if e["class"] else "") + (f" ({e['extends']})" if e["extends"] else "")
        out += [title, ""]
        if e["about"]:
            out.append(e["about"])
        for label, key in (("Signals", "signals"), ("Functions", "funcs"), ("Exports", "exports"),
                           ("Config read", "config"), ("Nodes looked up", "lookups"),
                           ("Nodes created at run time", "created"), ("tr() keys", "tr")):
            if e[key]:
                out.append(f"- {label}: " + ", ".join(f"`{x}`" for x in e[key]))
        out.append("")
    return out


def render_nodes(scenes, words, looked_up):
    """`looked_up`: every name any script finds by name; only those are flagged when duplicated."""
    out = ["## Scene nodes", ""]
    for rel, nodes in scenes:
        shown = [n for n in nodes if not words or any(w.lower() in (n[2] + "/" + n[0]).lower() for w in words)]
        if not shown:
            continue
        out += [f"### `{rel}` ({len(nodes)} nodes)", "", "| Node | Type | Parent | Script |", "|---|---|---|---|"]
        out += [f"| `{n}` | {t} | `{p or '(root)'}` | {s} |" for n, t, p, s in shown]
        counts = {}
        for n in nodes:
            counts[n[0]] = counts.get(n[0], 0) + 1
        dups = sorted(k for k, v in counts.items() if v > 1 and k in looked_up)
        if dups:
            out += ["", "Duplicate names (`find_child` returns the first): " + ", ".join(
                f"`{d}` under " + " and ".join(f"`{n[2] or '(root)'}`" for n in nodes if n[0] == d) for d in dups)]
        out.append("")
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default="game")
    ap.add_argument("--for", dest="words", default="", help="comma-separated names to slice on")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--scripts-only", action="store_true")
    g.add_argument("--nodes-only", action="store_true")
    args = ap.parse_args(argv)
    words = [w.strip() for w in args.words.split(",") if w.strip()]
    sys.stdout.reconfigure(encoding="utf-8")
    print(render_for(args.root, words, scripts=not args.nodes_only, nodes=not args.scripts_only))
    return 0


def render_for(root, words, scripts=True, nodes=True):
    """The map as Markdown, sliced to `words` when given (goal_agent puts this in a step's briefs)."""
    sdir = os.path.join(root, "scripts")
    all_entries = [script_entry(os.path.join(sdir, f)) for f in sorted(os.listdir(sdir)) if f.endswith(".gd")]
    entries = [e for e in all_entries if matches(e, words)] if words else all_entries
    scenes = []
    for dirpath, dirs, files in os.walk(os.path.join(root, "scenes")):
        dirs[:] = [d for d in dirs if d != "variants"]   # Milo's compare variants: not part of the game
        for f in sorted(files):
            if f.endswith(".tscn"):
                p = os.path.join(dirpath, f)
                scenes.append((os.path.relpath(p, root).replace(os.sep, "/"), scene_nodes(p, root)))
    scenes.sort()

    out = ["# Code map" + (f" for {', '.join(words)}" if words else ""), "",
           "Generated by `python -I _tools/code_map.py`; do not edit.", ""]
    if scripts:
        out += render_scripts(entries)
    if nodes:
        out += render_nodes(scenes, words, {n for e in all_entries for n in e["lookups"]})
    return "\n".join(out)


if __name__ == "__main__":
    sys.exit(main())
