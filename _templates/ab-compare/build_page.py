"""Build an A/B comparison page in the Zoom Framing Options layout.

    python -I build_page.py spec.json out.html

spec.json: {title, eyebrow, h1, brief, min_px, options:[{letter,title,shot,extra_shots:[[label,path]],px,on:[...],cut:[...],change}],
            ref:{shot,title,text}, ask}
Images are inlined as base64 PNG.
"""
import base64, html, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def img(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def esc(s):
    return html.escape(s, quote=True)


def main(spec_path, out_path):
    spec = json.load(open(spec_path, encoding="utf-8"))
    head = open(os.path.join(HERE, "head.html"), encoding="utf-8").read().splitlines()
    head = [l for l in head[1:] if not l.startswith('<span class="eyebrow">')]   # drop the publish wrapper line
    css_end = head.index("</style>")
    head = head[:css_end] + [".grid.two{grid-template-columns:repeat(2,minmax(0,1fr))}@media (max-width:560px){.grid.two{grid-template-columns:minmax(0,1fr)}}",
                             ".shots{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.shots figcaption{font-size:12px;color:var(--muted)}"] + head[css_end:]
    out = "\n".join(head).replace("<title>Zoom Framing Options</title>", f"<title>{esc(spec['title'])}</title>")
    out = out.replace('<section class="brief">', "", 1).rstrip()
    if out.endswith('<div class="wrap">'):
        pass
    min_px = spec.get("min_px", 44)
    parts = [out, '<section class="brief">', f'<span class="eyebrow">{spec["eyebrow"]}</span>', f"<h1>{esc(spec['h1'])}</h1>",
             f"<p>{spec['brief']}</p>", "</section>", '<div class="grid two">']
    for o in spec["options"]:
        px = o.get("px")
        parts.append(f'<article class="card" id="opt-{o["letter"].lower()}">')
        parts.append(f'<header><span class="letter">{o["letter"]}</span><h2>{esc(o["title"])}</h2></header>')
        parts.append(f'<figure><img src="{img(o["shot"])}" alt="{esc(o["title"])} at 720 by 1280"></figure>')
        if px is not None:
            ok = px >= min_px
            cls = "ok" if ok else "low"
            parts.append(f'<div class="stat"><span class="num">{px:.1f}</span><span class="unit">px smallest cell</span>'
                         f'<span class="pill {cls}">{"meets" if ok else "below"} {min_px} px</span></div>')
            parts.append(f'<div class="meter" role="img" aria-label="{px:.1f} px against the {min_px} px minimum">'
                         f'<div class="fill {cls}" style="width:{min(px / 50 * 100, 100):.1f}%"></div><div class="mark" style="left:{min_px / 50 * 100:.1f}%"></div></div>')
        if o.get("on"):
            parts.append("<h3>On screen</h3><ul>" + "".join(f"<li>{esc(x)}</li>" for x in o["on"]) + "</ul>")
        if o.get("cut"):
            parts.append('<h3>Cut off</h3><ul class="cut">' + "".join(f"<li>{esc(x)}</li>" for x in o["cut"]) + "</ul>")
        if o.get("change"):
            parts.append(f'<p class="small">{o["change"]}</p>')
        if o.get("extra_shots"):
            parts.append("<details><summary>More shots</summary><div class=\"shots\">" + "".join(
                f'<figure><img src="{img(p)}" alt="{esc(l)}"><figcaption>{esc(l)}</figcaption></figure>' for l, p in o["extra_shots"]) + "</div></details>")
        parts.append("</article>")
    parts.append("</div>")
    r = spec["ref"]
    parts += ['<section class="ref">']
    if r.get("shots"):
        parts.append('<div class="shots" style="grid-template-columns:minmax(0,1fr)">' + "".join(f'<img src="{img(p)}" alt="{esc(l)}">' for l, p in r["shots"]) + "</div>")
    parts += [f'<div class="brief"><span class="eyebrow">Reference</span><h2>{esc(r["title"])}</h2>', f"<p>{r['text']}</p>",
              f'<div class="ask"><strong>To choose:</strong> {spec["ask"]}</div></div>', "</section>", "</div>"]
    open(out_path, "w", encoding="utf-8").write("\n".join(parts) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
