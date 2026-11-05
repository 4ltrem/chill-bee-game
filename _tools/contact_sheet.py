#!/usr/bin/env python3
"""Tile a folder of screenshots into one labelled image, so a reviewer reads one image instead of many.

    python _tools/contact_sheet.py FOLDER [--out FILE] [--width 240] [--cols 4] [--match TEXT]

Used for Bob's shot set (game/CONTEXT.md, Process 6): the orchestrator, and later the style critic,
open the sheet once rather than a dozen 720x1280 PNGs. Each tile is scaled to --width pixels wide and
labelled with its file name. Default output: FOLDER/_sheet.png. Needs Pillow from the user site-packages (so run it
without -I); the only tool in _tools/ that is not standard library only.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folder")
    ap.add_argument("--out")
    ap.add_argument("--width", type=int, default=240)
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--match", default="", help="only files whose name contains this text")
    args = ap.parse_args(argv)
    files = sorted(f for f in os.listdir(args.folder)
                   if f.lower().endswith(".png") and not f.startswith("_") and args.match in f)
    if not files:
        print("contact_sheet: no PNG files")
        return 1
    tiles = []
    for f in files:
        im = Image.open(os.path.join(args.folder, f)).convert("RGB")
        h = int(im.height * args.width / im.width)
        tiles.append((f, im.resize((args.width, h))))
    label_h, pad = 18, 6
    tile_h = max(t.height for _, t in tiles) + label_h
    cols = min(args.cols, len(tiles))
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (args.width + pad) + pad, rows * (tile_h + pad) + pad), (250, 247, 236))
    draw = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(tiles):
        x = pad + (i % cols) * (args.width + pad)
        y = pad + (i // cols) * (tile_h + pad)
        draw.text((x, y + 2), name[:40], fill=(43, 29, 6))
        sheet.paste(im, (x, y + label_h))
    out = args.out or os.path.join(args.folder, "_sheet.png")
    sheet.save(out)
    print(f"contact_sheet: {len(tiles)} shots -> {out} ({sheet.width}x{sheet.height})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
