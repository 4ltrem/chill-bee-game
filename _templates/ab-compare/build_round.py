"""Build a vote page for one A/B round: shots grouped in rows by option, yes / maybe / no + note per shot (db "votes").

    python -I build_round.py SHOTS_DIR round.json spec.json previous_page.html out.html

round.json: [{"file", "option", "label", "change", "zoom_size", "min_cell_px"|null}, ...]
spec.json:  {"title", "eyebrow", "h1", "brief", "prefix" (vote id prefix, e.g. "r4-"), "rows": {"A": "row title", ...},
             "history": "<html of earlier-round summary>"}
Earlier rounds from previous_page.html (from its "Round 2" section on) are kept collapsed, without their scripts.
"""
import base64, html, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from build_votes import SCRIPT  # same vote script: cards with data-id + data-meta, db collection "votes"


def b64(p):
    return "data:image/png;base64," + base64.b64encode(open(p, "rb").read()).decode()


def main(shots_dir, round_json, spec_json, prev_page, out):
    shots = json.load(open(round_json, encoding="utf-8"))
    spec = json.load(open(spec_json, encoding="utf-8"))
    head = open(os.path.join(HERE, "head.html"), encoding="utf-8").read().splitlines()
    head = [l for l in head[1:] if not l.startswith('<span class="eyebrow">') and l not in ('<div class="wrap">', '<section class="brief">')]
    css_end = head.index("</style>")
    extra = """
.row{display:grid;gap:10px}.row h2{font-size:20px}
.rgrid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}
@media (max-width:760px){.rgrid{grid-template-columns:minmax(0,1fr)}}
.card figure img{cursor:zoom-in}
.votes{display:grid;grid-template-columns:repeat(3,1fr);gap:6px}
.votes button{font:inherit;font-weight:700;font-size:13px;padding:8px 4px;border-radius:999px;border:1.5px solid var(--line);background:var(--bg);color:var(--ink);cursor:pointer;min-height:40px}
.votes button:focus-visible{outline:2px solid var(--honey);outline-offset:2px}
.votes button[aria-pressed=true][data-v=yes]{background:var(--ok);border-color:var(--ok);color:#fff}
.votes button[aria-pressed=true][data-v=maybe]{background:var(--honey);border-color:var(--honey);color:#2b1d06}
.votes button[aria-pressed=true][data-v=no]{background:var(--low);border-color:var(--low);color:#fff}
.card textarea{font:inherit;font-size:13px;width:100%;box-sizing:border-box;border:1px solid var(--line);border-radius:8px;padding:6px;background:var(--bg);color:var(--ink);resize:vertical;min-height:34px}
.status{font-size:13px;color:var(--muted)}
.lb{position:fixed;inset:0;background:rgba(0,0,0,.85);display:none;place-items:center;z-index:9;padding:16px}
.lb.open{display:grid}.lb img{max-height:94vh;max-width:100%;border-radius:8px}
"""
    page = "\n".join(head[:css_end] + [extra] + head[css_end:]).replace("<title>Zoom Framing Options</title>", f"<title>{html.escape(spec['title'])}</title>")
    p = [page, '<div class="wrap">', '<section class="brief" style="max-width:none">', f'<span class="eyebrow">{spec["eyebrow"]}</span>',
         f"<h1>{html.escape(spec['h1'])}</h1>", f"<p>{spec['brief']}</p>", '<p class="status" id="status">Loading saved votes…</p></section>']
    for opt, title in spec["rows"].items():
        row = [s for s in shots if s["option"] == opt]
        if not row:
            continue
        p.append(f'<section class="row"><h2>{title}</h2><div class="rgrid">')
        for s in row:
            sid = spec["prefix"] + os.path.splitext(s["file"])[0]
            px = s.get("min_cell_px")
            meta = {k: s.get(k) for k in ("file", "option", "label", "change", "zoom_size", "min_cell_px")}
            stat = ""
            if px is not None:
                cls = "ok" if px >= 44 else "low"
                stat = (f'<div class="stat"><span class="num">{px:.1f}</span><span class="unit">px smallest cell</span>'
                        f'<span class="pill {cls}">{"meets" if px >= 44 else "below"} 44</span></div>')
            p.append(f'<article class="card" data-id="{sid}" data-meta="{html.escape(json.dumps(meta), quote=True)}">'
                     f'<header><h2>{html.escape(s["label"])}</h2></header>'
                     f'<figure><img src="{b64(os.path.join(shots_dir, s["file"]))}" alt="{html.escape(s["label"])}"></figure>{stat}'
                     f'<p class="small">{html.escape(s.get("change") or "")}</p>'
                     f'<div class="votes" role="group" aria-label="Vote for {html.escape(s["label"])}">'
                     + "".join(f'<button type="button" data-v="{v}" aria-pressed="false">{v}</button>' for v in ("yes", "maybe", "no"))
                     + f'</div><textarea aria-label="Note for {html.escape(s["label"])}" placeholder="Note (optional)" rows="1"></textarea></article>')
        p.append("</div></section>")
    hist = spec.get("history", "")
    prev = open(prev_page, encoding="utf-8").read()
    i = prev.find('<section class="brief" style="max-width:none"><span class="eyebrow">Round 2')
    if i >= 0:
        body = prev[i:]
        body = body[:body.find("</details>")] if "</details>" in body else body
        body = re.sub(r"(</div>\s*){2}$", "", body.rstrip())
        body = re.sub(r"<script>.*?</script>", "", body, flags=re.S)
        hist += body
    if hist:
        p.append(f'<details><summary>Earlier rounds</summary><div class="wrap">{hist}</div></details>')
    p += ["</div>", '<div class="lb" id="lb" role="dialog" aria-label="Full-size shot"><img alt=""></div>', SCRIPT]
    open(out, "w", encoding="utf-8").write("\n".join(p) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:6])
