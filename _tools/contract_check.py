#!/usr/bin/env python3
"""Check the script-scene contract: every node a script looks up exists in the scenes that use it.

    python -I _tools/contract_check.py [--root game] [-v]

Patricia's scripts find their nodes by name (`find_child("X")`, `get_node("a/b")`, `$a/b`, `%X`), and
Bob's scenes must contain them. A mismatch used to surface only in Quinn's run; this finds it in
seconds, without Godot. For each top-level scene (one no other scene instances), the scene tree is
expanded through its instanced sub-scenes. Then, for every script attached anywhere in that tree:
  - a `find_child` or `%Unique` name must exist somewhere in the expanded tree;
  - a relative `get_node` / `$` path must resolve from the node the script is attached to.
Every `NodePath("...")` property in a scene (e.g. a floating icon's `anchor_path`) must resolve too.

Skipped: absolute paths (`/root/...`), lookups built at run time, and any line carrying the comment
`# contract: optional` (for lookups the script guards, such as nodes it creates itself).
Exit code 0 when every lookup resolves, 1 otherwise. Standard library only.
"""
import argparse
import os
import re
import sys

HEADER = re.compile(r'^\[(\w+)(.*)\]\s*$')
ATTR = re.compile(r'(\w+)=("(?:[^"\\]|\\.)*"|\[[^\]]*\]|\S+)')
PROP_NODEPATH = re.compile(r'^(\w+)\s*=\s*NodePath\("([^"]*)"\)')
SCRIPT_PROP = re.compile(r'^script\s*=\s*ExtResource\(\s*"?([^")]+?)"?\s*\)')

# (kind, regex, read from): string-argument lookups read the raw line; `%Name` and `$path` read the
# line with string literals blanked, so "%d" in a format string is not a lookup.
LOOKUPS = [
    ("name", re.compile(r'find_child\(\s*"([^"]+)"'), "raw"),
    ("name", re.compile(r'(?<![\w"])%([A-Za-z_]\w*)'), "code"),
    ("path", re.compile(r'get_node(?:_or_null)?\(\s*"([^"]+)"'), "raw"),
    ("path", re.compile(r'(?<![\w"])\$("[^"]+"|[A-Za-z_][\w/]*)'), "raw$"),
]
STRING = re.compile(r'"(?:[^"\\]|\\.)*"' + r"|'(?:[^'\\]|\\.)*'")
SCENE_LITERAL = re.compile(r'"(res://[^"]+\.tscn)"')


class Node:
    def __init__(self, name, parent_path):
        self.name = name
        self.path = name if parent_path is None else (name if parent_path == "" else parent_path + "/" + name)
        self.script = None        # res:// path
        self.instance = None      # res:// path of a PackedScene
        self.nodepaths = []       # (property, NodePath string)


def res_to_file(res, root):
    return os.path.join(root, res[len("res://"):]) if res.startswith("res://") else None


def parse_tscn(file):
    """Return (ext_resources {id: path}, [Node]) with paths relative to the scene root ("" = root)."""
    ext, nodes, current = {}, [], None
    with open(file, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            m = HEADER.match(line)
            if m:
                kind, attrs = m.group(1), dict((k, v.strip('"')) for k, v in ATTR.findall(m.group(2)))
                current = None
                if kind == "ext_resource":
                    ext[attrs.get("id")] = attrs.get("path")
                elif kind == "node":
                    parent = attrs.get("parent")
                    if parent is None:
                        node = Node(attrs["name"], None)
                        node.path = ""
                    else:
                        node = Node(attrs["name"], "" if parent == "." else parent)
                    inst = attrs.get("instance", "")
                    mi = re.search(r'ExtResource\(\s*"?([^")]+?)"?\s*\)', inst)
                    if mi:
                        node.instance = ext.get(mi.group(1))
                    nodes.append(node)
                    current = node
                continue
            if current is None:
                continue
            ms = SCRIPT_PROP.match(line)
            if ms:
                current.script = ext.get(ms.group(1))
                continue
            mp = PROP_NODEPATH.match(line)
            if mp and mp.group(2):
                current.nodepaths.append((mp.group(1), mp.group(2)))
    return ext, nodes


def expand(scene_res, root, prefix="", seen=()):
    """Expand a scene into a flat list of (full_path, Node) through instanced sub-scenes."""
    file = res_to_file(scene_res, root)
    if not file or not os.path.exists(file) or scene_res in seen:
        return []
    _, nodes = parse_tscn(file)
    out = []
    for node in nodes:
        full = prefix if node.path == "" else (prefix + "/" + node.path if prefix else node.path)
        out.append((full, node))
        if node.instance:
            for sub_full, sub in expand(node.instance, root, full, seen + (scene_res,)):
                if sub_full == full:      # the sub-scene's root is this same node
                    if sub.script and not node.script:
                        node.script = sub.script
                    node.nodepaths = node.nodepaths or sub.nodepaths
                    continue
                out.append((sub_full, sub))
    return out


def resolve(base, rel):
    parts = [p for p in base.split("/") if p] if base else []
    for piece in rel.split("/"):
        if piece in ("", "."):
            continue
        if piece == "..":
            if not parts:
                return None
            parts.pop()
        else:
            parts.append(piece)
    return "/".join(parts)


def script_lookups(file):
    out = []
    with open(file, encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            if "# contract: optional" in line:
                continue
            raw = line.split("#", 1)[0] if not line.lstrip().startswith("#") else ""
            blank = STRING.sub('""', raw)
            for kind, rx, src in LOOKUPS:
                text = blank if src == "code" else raw
                if src == "raw$":   # `$"a/b"` keeps its quotes; a bare `$a` must not sit inside a string
                    text = STRING.sub(lambda m: m.group(0) if raw[max(0, m.start() - 1):m.start()] == "$" else '""', raw)
                for m in rx.finditer(text):
                    target = m.group(1).strip('"')
                    if kind == "path" and (target.startswith("/") or ":" in target):
                        continue
                    out.append((n, kind, target))
    return out


def scene_literals(file):
    with open(file, encoding="utf-8") as fh:
        return SCENE_LITERAL.findall(fh.read())


def scenes_in(root):
    for dirpath, _, files in os.walk(root):
        if os.sep + "." in os.sep + os.path.relpath(dirpath, root):  # relative: a worktree under .claude/ still counts
            continue
        for f in files:
            if f.endswith(".tscn"):
                rel = os.path.relpath(os.path.join(dirpath, f), root).replace(os.sep, "/")
                yield "res://" + rel


def check(root, verbose=False):
    scenes = sorted(scenes_in(root))
    instanced = set()
    for s in scenes:
        _, nodes = parse_tscn(res_to_file(s, root))
        instanced.update(n.instance for n in nodes if n.instance)
    tops = [s for s in scenes if s not in instanced]
    problems, checked = [], 0
    cache = {}
    for top in tops:
        tree = expand(top, root)
        paths = {p for p, _ in tree}
        names = {p.rsplit("/", 1)[-1] for p in paths if p} | {n.name for _, n in tree}
        for full, node in tree:
            for prop, np in node.nodepaths:
                checked += 1
                target = resolve(full, np)
                if target is None or target not in paths:
                    problems.append(f"{top}: node '{full or node.name}' property {prop} = NodePath(\"{np}\") resolves to nothing")
            if not node.script:
                continue
            sfile = res_to_file(node.script, root)
            if not sfile or not os.path.exists(sfile):
                problems.append(f"{top}: node '{full or node.name}' attaches missing script {node.script}")
                continue
            if sfile not in cache:
                extra = set()
                for lit in scene_literals(sfile):   # scenes the script instances at run time
                    sub_tree = expand(lit, root)
                    extra |= {p.rsplit("/", 1)[-1] for p, _ in sub_tree if p} | {n.name for _, n in sub_tree}
                cache[sfile] = (script_lookups(sfile), extra)
            lookups, extra = cache[sfile]
            for line, kind, target in lookups:
                checked += 1
                where = f"{node.script}:{line}"
                if kind == "name":
                    if target not in names and target not in extra:
                        problems.append(f"{top}: {where} looks up '{target}', not in the scene tree")
                else:
                    got = resolve(full, target)
                    if got is None or got not in paths:
                        problems.append(f"{top}: {where} get_node(\"{target}\") from '{full or node.name}' resolves to nothing")
        if verbose:
            print(f"{top}: {len(tree)} nodes")
    return problems, checked, tops


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game"))
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args(argv)
    if not os.path.isdir(args.root):
        print(f"contract: no Godot project at {args.root}")
        return 0
    problems, checked, tops = check(args.root, args.verbose)
    for p in problems:
        print("CONTRACT: " + p)
    print(f"contract: {checked} lookups in {len(tops)} top-level scenes, {len(problems)} unresolved")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
