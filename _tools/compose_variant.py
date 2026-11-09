"""Compose a colorbox variant from existing variant scenes. No agent.

Most vote rounds after the first recombine parts the designer already saw: take variant A, add a part of
variant B, drop a part, swap a material, nudge a part. This script does those steps on the .tscn text, so
the round costs a command instead of a Milo run (designer, 2026-11-09). New shapes still go to Milo.

Steps run in the order given. NODE paths are relative to the root, as Godot writes `parent=` ("Lid/Gears/Gear1");
"*" and "?" match (fnmatch, "*" also crosses "/"). Each step must match at least one node, or nothing is written.

  --graft SRC.tscn:NODE[@PARENT]  copy NODE and its children from SRC (with the resources they use) under the
                                  same parent path, or under PARENT; a node already at that path is replaced
  --drop NODE                     remove NODE and its children
  --material NODE=NAME            set material_override on each matching MeshInstance3D to materials/NAME.tres
  --move NODE=DX,DY,DZ            add to the node's local position (its transform's origin)

Unused sub_resources and ext_resources are removed and load_steps recounted. OUT must be
game/scenes/variants/<prop>-r<N>/<prop>-r<N>-<x>.tscn, in a round folder (the vote-round rule), and must not
exist yet. --dry-run prints the node paths and load_steps instead of writing.

  python -I _tools/compose_variant.py game/scenes/variants/truck-flames-r3/truck-flames-r3-l4.tscn \
      --base game/scenes/variants/truck-flames-r2/truck-flames-r2-d.tscn --drop "Flames/StackFlame*"
"""
import argparse
import fnmatch
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
OUT_RE = re.compile(r"^game/scenes/variants/([a-z0-9-]+-r\d+)/\1-[a-z0-9-]+\.tscn$")
REF_RE = re.compile(r'(ExtResource|SubResource)\("([^"]+)"\)')


class Scene:
    def __init__(self, text, name):
        self.name = name
        self.header = None
        self.ext = []    # [id, header line, body]
        self.sub = []    # [id, header line, body]
        self.nodes = []  # [path, header line, body]
        for block in re.split(r"\n(?=\[)", text.strip()):
            head, _, body = block.partition("\n")
            body = body.strip("\n")
            kind = head[1:].split(" ", 1)[0]
            if kind == "gd_scene":
                self.header = head
            elif kind == "ext_resource":
                self.ext.append([attr(head, "id"), head, body])
            elif kind == "sub_resource":
                self.sub.append([attr(head, "id"), head, body])
            elif kind == "node":
                parent = attr(head, "parent")
                nm = attr(head, "name")
                path = "." if parent is None else (nm if parent == "." else f"{parent}/{nm}")
                self.nodes.append([path, head, body])
            else:
                sys.exit(f"{name}: unknown section [{kind}]")
        if self.header is None or not self.nodes or self.nodes[0][0] != ".":
            sys.exit(f"{name}: not a scene with a root node")

    def match(self, pattern, what):
        hits = [n for n in self.nodes if n[0] != "." and fnmatch.fnmatchcase(n[0], pattern)]
        if not hits:
            sys.exit(f"{what}: no node matches '{pattern}' in {self.name}; nothing written")
        return hits

    def subtree(self, path):
        return [n for n in self.nodes if n[0] == path or n[0].startswith(path + "/")]

    def text(self):
        used = set()
        for _, head, body in self.nodes:
            used |= refs(head + "\n" + body)
        subs = {s[0]: s for s in self.sub}
        stack = [r for r in used if r[0] == "SubResource"]
        while stack:  # sub_resources may use other resources
            sid = stack.pop()[1]
            if sid in subs:
                for r in refs(subs[sid][1] + "\n" + subs[sid][2]):
                    if r not in used:
                        used.add(r)
                        if r[0] == "SubResource":
                            stack.append(r)
        self.ext = [e for e in self.ext if ("ExtResource", e[0]) in used]
        self.sub = [s for s in self.sub if ("SubResource", s[0]) in used]
        steps = len(self.ext) + len(self.sub) + 1
        header = re.sub(r"load_steps=\d+ ?", "", self.header)
        header = header.replace("[gd_scene ", f"[gd_scene load_steps={steps} ") if steps > 1 else header
        parts = [header]
        if self.ext:
            parts.append("\n".join(h for _, h, _ in self.ext))
        parts += [join(h, b) for _, h, b in self.sub] + [join(h, b) for _, h, b in self.nodes]
        return "\n\n".join(parts) + "\n"


def attr(head, key):
    m = re.search(rf'\b{key}="([^"]*)"', head)
    return m.group(1) if m else None


def refs(text):
    return set(REF_RE.findall(text))


def join(head, body):
    return head + ("\n" + body if body else "")


def rename(text, mapping):
    return REF_RE.sub(lambda m: f'{m.group(1)}("{mapping.get((m.group(1), m.group(2)), m.group(2))}")', text)


def unique(want, taken):
    new, k = want, 2
    while new in taken:
        new, k = f"{want}_{k}", k + 1
    return new


def graft(base, spec):
    src_spec, _, parent_override = spec.partition("@")
    src_file, sep, pattern = src_spec.rpartition(":")
    if not sep:
        sys.exit(f"--graft '{spec}': use SRC.tscn:NODE[@PARENT]")
    src_path = (ROOT / src_file) if not Path(src_file).is_absolute() else Path(src_file)
    src = Scene(src_path.read_text(encoding="utf-8"), src_file)
    tops = [n[0] for n in src.match(pattern, "--graft")]
    tops = [t for t in tops if not any(t.startswith(o + "/") for o in tops)]  # children come with their parent
    for top in tops:
        nodes = src.subtree(top)
        old_parent = top.rpartition("/")[0] or "."
        new_parent = parent_override or old_parent
        new_top = (top.rpartition("/")[2] if new_parent == "." else f"{new_parent}/{top.rpartition('/')[2]}")
        if new_parent != "." and new_parent not in [n[0] for n in base.nodes]:
            sys.exit(f"--graft '{spec}': parent '{new_parent}' is not in the base; nothing written")
        # resources the copied nodes use, with ids remapped where the base already uses the id for something else
        mapping = {}
        ext_by_path = {attr(h, "path"): i for i, h, _ in base.ext}
        need = set()
        for _, h, b in nodes:
            need |= refs(h + "\n" + b)
        src_subs = {s[0]: s for s in src.sub}
        stack = [r for r in need if r[0] == "SubResource"]
        while stack:
            sid = stack.pop()[1]
            for r in refs(src_subs[sid][1] + "\n" + src_subs[sid][2]):
                if r not in need:
                    need.add(r)
                    if r[0] == "SubResource":
                        stack.append(r)
        src_ext = {e[0]: e for e in src.ext}
        for kind, rid in sorted(need):
            if kind == "ExtResource":
                e = src_ext[rid]
                p = attr(e[1], "path")
                if p in ext_by_path:
                    mapping[(kind, rid)] = ext_by_path[p]
                else:
                    nid = unique(rid, {x[0] for x in base.ext})
                    mapping[(kind, rid)] = nid
                    base.ext.append([nid, e[1].replace(f'id="{rid}"', f'id="{nid}"'), ""])
                    ext_by_path[p] = nid
        base_subs = {s[0]: s for s in base.sub}
        for kind, rid in sorted(need):
            if kind == "SubResource":
                s = src_subs[rid]
                same = rid in base_subs and rename(join(s[1], s[2]), mapping) == join(*base_subs[rid][1:])
                mapping[(kind, rid)] = rid if same else unique(rid, set(base_subs) | {m for m in mapping.values()})
        for kind, rid in sorted(need):
            if kind == "SubResource" and mapping[(kind, rid)] not in base_subs:
                s = src_subs[rid]
                nid = mapping[(kind, rid)]
                head = rename(s[1], mapping).replace(f'id="{rid}"', f'id="{nid}"')
                base.sub.append([nid, head, rename(s[2], mapping)])
                base_subs[nid] = base.sub[-1]
        # replace whatever sits at the new path, then insert after the parent's last descendant
        base.nodes = [n for n in base.nodes if not (n[0] == new_top or n[0].startswith(new_top + "/"))]
        copied = []
        for path, head, body in nodes:
            rel = path[len(top):]
            npath = new_top + rel
            parent = npath.rpartition("/")[0] or "."
            head = re.sub(r'parent="[^"]*"', f'parent="{parent}"', rename(head, mapping))
            copied.append([npath, head, rename(body, mapping)])
        idx = max((i for i, n in enumerate(base.nodes)
                   if new_parent == "." or n[0] == new_parent or n[0].startswith(new_parent + "/")), default=0)
        base.nodes[idx + 1:idx + 1] = copied


def drop(base, pattern):
    gone = [n[0] for n in base.match(pattern, "--drop")]
    base.nodes = [n for n in base.nodes if not any(n[0] == g or n[0].startswith(g + "/") for g in gone)]


def material(base, spec):
    pattern, _, name = spec.rpartition("=")
    if not (GAME / "materials" / f"{name}.tres").is_file():
        sys.exit(f"--material: game/materials/{name}.tres does not exist; nothing written")
    res = f"res://materials/{name}.tres"
    hits = [n for n in base.match(pattern, "--material") if attr(n[1], "type") == "MeshInstance3D"]
    if not hits:
        sys.exit(f"--material: '{pattern}' matches no MeshInstance3D; nothing written")
    rid = next((i for i, h, _ in base.ext if attr(h, "path") == res), None)
    if rid is None:
        rid = unique(f"m_{name}", {e[0] for e in base.ext})
        base.ext.append([rid, f'[ext_resource type="Material" path="{res}" id="{rid}"]', ""])
    for n in hits:
        lines = [l for l in n[2].splitlines() if not l.startswith("material_override =")]
        n[2] = "\n".join(lines + [f'material_override = ExtResource("{rid}")'])


def move(base, spec):
    pattern, _, delta = spec.rpartition("=")
    try:
        d = [float(x) for x in delta.split(",")]
        assert len(d) == 3
    except (ValueError, AssertionError):
        sys.exit(f"--move '{spec}': use NODE=DX,DY,DZ")
    for n in base.match(pattern, "--move"):
        m = re.search(r"^transform = Transform3D\(([^)]*)\)$", n[2], re.M)
        v = [float(x) for x in m.group(1).split(",")] if m else [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
        for k in range(3):
            v[9 + k] = round(v[9 + k] + d[k], 6)
        line = "transform = Transform3D(" + ", ".join(f"{x:g}" for x in v) + ")"
        n[2] = n[2].replace(m.group(0), line) if m else "\n".join([line] + ([n[2]] if n[2] else []))


class Step(argparse.Action):
    def __call__(self, parser, ns, value, option=None):
        ns.steps = (getattr(ns, "steps", None) or []) + [(self.dest, value)]


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("out")
    ap.add_argument("--base", required=True)
    for op in ("graft", "drop", "material", "move"):
        ap.add_argument(f"--{op}", dest=op, action=Step, default=None)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    out = a.out.replace("\\", "/")
    if not OUT_RE.match(out):
        sys.exit(f"'{out}': write to game/scenes/variants/<prop>-r<N>/<prop>-r<N>-<x>.tscn (a new round folder)")
    if (ROOT / out).exists():
        sys.exit(f"{out} exists: each round is a new file, never an overwrite")
    base = Scene((ROOT / a.base).read_text(encoding="utf-8"), a.base)
    for op, value in getattr(a, "steps", None) or []:
        {"graft": graft, "drop": drop, "material": material, "move": move}[op](base, value)
    text = base.text()
    if a.dry_run:
        print(re.search(r"load_steps=\d+", text).group(0) if "load_steps" in text else "load_steps=1")
        print("\n".join(n[0] for n in base.nodes))
        return
    (ROOT / out).parent.mkdir(parents=True, exist_ok=True)
    (ROOT / out).write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {out}: {len(base.nodes)} nodes, {len(base.sub)} sub_resources, {len(base.ext)} ext_resources")


if __name__ == "__main__":
    main()
