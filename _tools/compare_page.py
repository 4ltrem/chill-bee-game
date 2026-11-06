"""Build the A/B comparison pages (Zoom Framing Options layout), images inlined as base64 PNG.

    python -I _tools/compare_page.py page  SPEC.json OUT.html
    python -I _tools/compare_page.py round SHOTS_DIR ROUND.json SPEC.json PREVIOUS_PAGE.html OUT.html
    python -I _tools/compare_page.py votes SHOTS_DIR SHOTS.json PREVIOUS_PAGE.html OUT.html
    python -I _tools/compare_page.py variants SHOTS_DIR OUT.html [--title T] [--checks CHECKS.json]
    python -I _tools/compare_page.py add PAGE.html OUT.html --h1 H1 [--stop BLACKBOARD ROW --prefix P --option A=DIR ... --ref DIR --shot NAME] [--variants DIR PREFIX TITLE --checks CHECKS.json] [--versions PREFIX TITLE --version LABEL=PNG[=CAPTION] ...]
    python -I _tools/compare_page.py stop  BLACKBOARD.md --row N --option A=DIR --option B=DIR --ref DIR --shot NAME --out OUT.html

page:  SPEC.json {title, eyebrow, h1, brief, min_px, options:[{letter,title,shot,extra_shots:[[label,path]],px,on:[...],cut:[...],change}],
       ref:{shot|shots,title,text}, ask}
round: ROUND.json [{file, option, label, change, zoom_size, min_cell_px|null}, ...];
       SPEC.json {title, eyebrow, h1, brief, prefix, rows:{"A": "row title"}, history}. Earlier rounds from PREVIOUS_PAGE
       (from its "Round 2" section on) are kept collapsed, without their scripts.
votes: the 3 x 3 grid-zoom vote page; votes live in the artifact db collection "votes", one doc per shot id.
stop:  one designer-stop row of the latest "## Waiting for the designer" table (| # | Rule | Where | Finding | Fix |),
       Fix = "A: ...; B: ..."; each option's NAME PNG comes from its folder, px = that folder's measure.json cell_px_min.
"""
import argparse, base64, html, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def b64(p):
    return "data:image/png;base64," + base64.b64encode(open(p, "rb").read()).decode()






def img(path):
    return b64(path)


def esc(s):
    return html.escape(s, quote=True)


def cmd_page(spec_path, out_path):
    spec = json.load(open(spec_path, encoding="utf-8"))
    head = open(os.path.join(HERE, "compare_page_head.html"), encoding="utf-8").read().splitlines()
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








def cmd_round(shots_dir, round_json, spec_json, prev_page, out):
    shots = json.load(open(round_json, encoding="utf-8"))
    spec = json.load(open(spec_json, encoding="utf-8"))
    head = open(os.path.join(HERE, "compare_page_head.html"), encoding="utf-8").read().splitlines()
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




ZOOMS = {1: "Z1 &middot; rack", 2: "Z2 &middot; hive + centrifuge", 3: "Z3 &middot; hive + centrifuge + crate"}




def cmd_votes(shots_dir, shots_json, prev_page, out):
    shots = json.load(open(shots_json, encoding="utf-8"))
    shots = shots.get("shots", shots) if isinstance(shots, dict) else shots
    head = open(os.path.join(HERE, "compare_page_head.html"), encoding="utf-8").read().splitlines()
    head = [l for l in head[1:] if not l.startswith('<span class="eyebrow">') and l not in ('<div class="wrap">', '<section class="brief">')]
    css_end = head.index("</style>")
    extra = VOTE_CSS
    page = "\n".join(head[:css_end] + [extra] + head[css_end:])
    page = page.replace("<title>Zoom Framing Options</title>", "<title>Grid Zoom Votes</title>")
    by = {(float(s["cell_size"]), int(s["zoom"])): s for s in shots}
    cells = sorted({k[0] for k in by})
    p = [page, '<div class="wrap">', '<section class="brief" style="max-width:none">',
         '<span class="eyebrow">Chill Bee Game &middot; 0.1.3 farm grid &middot; Layout C</span>',
         "<h1>Grid zoom votes</h1>",
         "<p>Layout C on the 5 &times; 5 grid, rendered at three cell sizes (rows) and three zooms (columns), each with a rack risen. "
         "The smallest rack cell is measured on every cell; the rule is 44 px. Mark each shot <strong>yes</strong>, <strong>maybe</strong> or <strong>no</strong> "
         "and add a note if you like. Votes save as you click, and Claude reads them back into <code>game/reports/grid-shots/decisions.json</code>. Click a shot to see it full size.</p>",
         '<pre class="emoji" aria-label="Layout C grid">⬜⬜⬜🌸⬜\n⬜⬜🐝⬜🌸\n🌸⬜🌀🟡⬜\n⬜⬜➕📦📦\n⬜⬜⬜🚚🚚</pre>',
         '<p class="status" id="status">Loading saved votes…</p></section>',
         '<div class="vgrid"><span></span>' + "".join(f'<span class="colh">{ZOOMS[z]}</span>' for z in (1, 2, 3))]
    for c in cells:
        p.append(f'<span class="rowh">cell {c:g}</span>')
        for z in (1, 2, 3):
            s = by.get((c, z))
            if s is None:
                p.append('<span></span>'); continue
            sid = f"c{c:g}-z{z}"
            px = float(s["min_cell_px"])
            ok = px >= 44
            cls = "ok" if ok else "low"
            meta = {k: s[k] for k in ("file", "cell_size", "zoom", "zoom_size", "min_cell_px") if k in s}
            p.append(f'<article class="card" data-id="{sid}" data-meta="{html.escape(json.dumps(meta), quote=True)}">'
                     f'<span class="tag">cell {c:g} &middot; {ZOOMS[z]}</span>'
                     f'<figure><img src="{b64(os.path.join(shots_dir, s["file"]))}" alt="cell {c:g}, {html.unescape(ZOOMS[z])}"></figure>'
                     f'<div class="stat"><span class="num">{px:.1f}</span><span class="unit">px smallest cell</span><span class="pill {cls}">{"meets" if ok else "below"} 44</span></div>'
                     f'<p class="small">zoom size {float(s["zoom_size"]):g} &middot; farm camera {float(s.get("farm_camera_size", 0)):g}</p>'
                     f'<div class="votes" role="group" aria-label="Vote for {sid}">'
                     + "".join(f'<button type="button" data-v="{v}" aria-pressed="false">{v}</button>' for v in ("yes", "maybe", "no"))
                     + f'</div><textarea aria-label="Note for {sid}" placeholder="Note (optional)" rows="1"></textarea></article>')
    p.append("</div>")
    # earlier rounds, collapsed
    prev = open(prev_page, encoding="utf-8").read()
    i = prev.find('<section class="brief" style="max-width:none"><span class="eyebrow">Round 2')
    if i >= 0:
        body = prev[i:]
        body = re.sub(r"\n</div>\s*$", "", body.rstrip())
        p.append('<details><summary>Earlier rounds: grid layouts A/B/C and the centrifuge move</summary><div class="wrap">' + body + "</div></div></details>")
    p.append("</div>")
    p.append('<div class="lb" id="lb" role="dialog" aria-label="Full-size shot"><img alt=""></div>')
    p.append(SCRIPT)
    open(out, "w", encoding="utf-8").write("\n".join(p) + "\n")


VOTE_CSS = """
.vgrid{display:grid;grid-template-columns:auto repeat(3,minmax(0,1fr));gap:12px;align-items:start}
.vgrid .colh{font-weight:700;font-size:13px;color:var(--muted);text-align:center}
.vgrid .rowh{writing-mode:vertical-rl;transform:rotate(180deg);font-family:var(--display);font-weight:800;font-size:15px;align-self:center;color:var(--honey-ink)}
@media (max-width:760px){.vgrid{grid-template-columns:minmax(0,1fr)}.vgrid .colh,.vgrid .rowh{display:none}.card .tag{display:block}}
.card .tag{display:none;font-size:12px;font-weight:700;color:var(--honey-ink)}
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
.emoji{font-size:24px;line-height:1.1;margin:0}
"""


SCRIPT = r"""<script>
(function(){
  const status = document.getElementById('status');
  const cards = [...document.querySelectorAll('.card[data-id]')];
  const state = {};
  function paint(id){
    const c = cards.find(x => x.dataset.id === id); if (!c) return;
    const s = state[id] || {};
    c.querySelectorAll('.votes button').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.v === s.vote)));
    const t = c.querySelector('textarea'); if (document.activeElement !== t) t.value = s.note || '';
  }
  function tally(){
    const n = {yes:0, maybe:0, no:0}; cards.forEach(c => { const s = state[c.dataset.id]; if (s && n[s.vote] !== undefined) n[s.vote]++; });
    return `${n.yes} yes · ${n.maybe} maybe · ${n.no} no · ${cards.length - n.yes - n.maybe - n.no} not voted`;
  }
  // lightbox
  const lb = document.getElementById('lb');
  document.querySelectorAll('.card figure img').forEach(img => img.addEventListener('click', () => { lb.querySelector('img').src = img.src; lb.classList.add('open'); }));
  lb.addEventListener('click', () => lb.classList.remove('open'));
  document.addEventListener('keydown', e => { if (e.key === 'Escape') lb.classList.remove('open'); });

  let db = null;
  const timer = setTimeout(() => { if (!db) status.textContent = 'Votes cannot be saved in this view (open the page on claude.ai, signed in).'; }, 10000);
  async function save(id){
    if (!db) return;
    const c = cards.find(x => x.dataset.id === id);
    const s = state[id] || {};
    try {
      await db.collection('votes').doc(id).set(Object.assign({}, JSON.parse(c.dataset.meta), {vote: s.vote || null, note: s.note || '', updatedAt: new Date().toISOString()}));
      status.textContent = 'Saved · ' + tally();
    } catch (e) { status.textContent = 'Could not save (' + (e && e.code || 'error') + '). Your vote shows here but is not stored.'; }
  }
  cards.forEach(c => {
    const id = c.dataset.id;
    c.querySelectorAll('.votes button').forEach(b => b.addEventListener('click', () => {
      state[id] = Object.assign({}, state[id], {vote: (state[id] && state[id].vote === b.dataset.v) ? null : b.dataset.v});
      paint(id); save(id);
    }));
    const t = c.querySelector('textarea'); let deb;
    t.addEventListener('input', () => { state[id] = Object.assign({}, state[id], {note: t.value}); clearTimeout(deb); deb = setTimeout(() => save(id), 800); });
  });
  (async () => {
    const d = await window.claude?.use?.('db');
    if (!d) { clearTimeout(timer); status.textContent = 'Votes cannot be saved in this view (open the page on claude.ai, signed in).'; return; }
    db = d;
    db.collection('votes').onSnapshot(snap => {
      clearTimeout(timer);
      snap.docs.forEach(doc => { const v = doc.data() || {}; state[doc.id] = {vote: v.vote || null, note: v.note || ''}; paint(doc.id); });
      status.textContent = tally();
    }, e => { clearTimeout(timer); status.textContent = 'Could not load saved votes (' + (e && e.code || 'error') + ').'; });
  })();
})();
</script>"""



def waiting_row(blackboard, n):
    """Cells of row n of the latest '## Waiting for the designer' table: [#, Rule, Where, Finding, Fix]."""
    text = open(blackboard, encoding="utf-8").read()
    i = text.rfind("## Waiting for the designer")
    if i < 0:
        sys.exit("no '## Waiting for the designer' section in " + blackboard)
    for line in text[i:].splitlines()[1:]:
        if line.startswith("## "):
            break
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if line.startswith("|") and len(cells) >= 5 and cells[0] == str(n):
            return cells
    sys.exit(f"row {n} not found in the latest 'Waiting for the designer' table")


def fix_options(fix):
    """'A: x; B: y' -> {'A': 'x', 'B': 'y'}."""
    parts = re.split(r"(?:^|;\s*)([A-Z]):\s*", fix.strip())
    return {parts[k]: parts[k + 1].strip().rstrip(";").strip() for k in range(1, len(parts) - 1, 2)}


def short(text, n=60):
    """An option's card title: its first clause, cut at a word boundary."""
    t = re.split(r"\s\(|;|\. ", text.replace("`", ""))[0].strip()
    return t if len(t) <= n else t[:n].rsplit(" ", 1)[0] + "…"


def cmd_stop(blackboard, row, options, ref, shot, out):
    num, rule, where, finding, fix = waiting_row(blackboard, row)[:5]
    texts = fix_options(fix)
    opts = []
    for spec in options:
        letter, folder = spec.split("=", 1)
        measure = os.path.join(folder, "measure.json")
        px = json.load(open(measure, encoding="utf-8")).get("cell_px_min") if os.path.exists(measure) else None
        opts.append({"letter": letter, "title": short(texts.get(letter, "Option " + letter)),
                     "shot": os.path.join(folder, shot), "px": px, "change": esc(texts.get(letter, ""))})
    spec = {"title": f"Style Rule {rule}", "eyebrow": f"Chill Bee Game &middot; designer stop &middot; row {num}",
            "h1": f"{rule}: {finding}", "brief": f"{esc(where)}. {esc(finding)}", "min_px": 20, "options": opts,
            "ref": {"title": "Current build", "text": "The build as it is now; nothing changes until you pick.",
                    "shots": [[shot, os.path.join(ref, shot)]]},
            "ask": "pick " + " or ".join(o["letter"] for o in opts) + "."}
    tmp = out + ".spec.json"
    json.dump(spec, open(tmp, "w", encoding="utf-8"))
    try:
        cmd_page(tmp, out)
    finally:
        os.remove(tmp)


def cmd_variants(shots_dir, out, title, checks=None):
    """A yes / maybe / no vote page for up to 9 prop variants (model_shots.py). checks: {file: summary}."""
    files = sorted(f for f in os.listdir(shots_dir) if f.endswith(".png"))[:9]
    checks = json.load(open(checks, encoding="utf-8")) if checks else {}
    head = open(os.path.join(HERE, "compare_page_head.html"), encoding="utf-8").read().splitlines()
    head = [l for l in head[1:] if not l.startswith('<span class="eyebrow">') and l not in ('<div class="wrap">', '<section class="brief">')]
    css_end = head.index("</style>")
    page = "\n".join(head[:css_end] + [VOTE_CSS] + head[css_end:])
    page = page.replace("<title>Zoom Framing Options</title>", f"<title>{esc(title)}</title>")
    p = [page, '<div class="wrap">', '<section class="brief" style="max-width:none">',
         '<span class="eyebrow">Chill Bee Game &middot; colorbox variants</span>', f"<h1>{esc(title)}</h1>",
         "<p>Each variant stands on the 5 &times; 5 test grid (cell 2.0) under the farm's light and camera. Mark each "
         "<strong>yes</strong>, <strong>maybe</strong> or <strong>no</strong>; Bob promotes the pick into "
         "<code>game/scenes/props/</code>. Click a shot to see it full size.</p>",
         '<p class="status" id="status">Loading saved votes…</p></section>', '<div class="grid">']
    for f in files:
        sid = f[:-4]
        c = checks.get(f, {})
        ok = c.get("pass", True)
        meta = {"file": f, "style_check": c.get("summary", "")}
        p.append(f'<article class="card" data-id="{esc(sid)}" data-meta="{html.escape(json.dumps(meta), quote=True)}">'
                 f'<header><h2>{esc(sid)}</h2></header><figure><img src="{b64(os.path.join(shots_dir, f))}" alt="{esc(sid)}"></figure>'
                 f'<div class="stat"><span class="pill {"ok" if ok else "low"}">style_check {"PASS" if ok else "FAIL"}</span></div>'
                 f'<p class="small">{esc(c.get("summary", ""))}</p>'
                 f'<div class="votes" role="group" aria-label="Vote for {esc(sid)}">'
                 + "".join(f'<button type="button" data-v="{v}" aria-pressed="false">{v}</button>' for v in ("yes", "maybe", "no"))
                 + f'</div><textarea aria-label="Note for {esc(sid)}" placeholder="Note (optional)" rows="1"></textarea></article>')
    p += ["</div>", "</div>", '<div class="lb" id="lb" role="dialog" aria-label="Full-size shot"><img alt=""></div>', SCRIPT]
    open(out, "w", encoding="utf-8").write("\n".join(p) + "\n")


def vote_card(sid, title, shot, lines=(), pill=None, meta=None):
    """One votable card (yes / maybe / no + note), the same markup the votes SCRIPT binds to."""
    meta = dict(meta or {}, file=os.path.basename(shot))
    pill_html = f'<span class="pill {"ok" if pill[1] else "low"}">{esc(pill[0])}</span>' if pill else ""
    body = "".join(f'<p class="small">{l}</p>' for l in lines)
    return (f'<article class="card" data-id="{esc(sid)}" data-meta="{html.escape(json.dumps(meta), quote=True)}">'
            f'<header><h2>{esc(title)}</h2>{pill_html}</header><figure><img src="{b64(shot)}" alt="{esc(title)}"></figure>{body}'
            f'<div class="votes" role="group" aria-label="Vote for {esc(sid)}">'
            + "".join(f'<button type="button" data-v="{v}" aria-pressed="false">{v}</button>' for v in ("yes", "maybe", "no"))
            + f'</div><textarea aria-label="Note for {esc(sid)}" placeholder="Note (optional)" rows="1"></textarea></article>')


def add_sections(page, sections, h1, brief, title=None):
    """Put new question sections at the top of an existing vote page; everything already there is
    collapsed under "Earlier questions". sections: [{eyebrow, h2, text, cards: [vote_card html]}]."""
    i = page.index('<div class="wrap">') + len('<div class="wrap">')
    k = page.rindex("</div>", 0, page.rindex('<div class="lb"'))
    old = page[i:k].replace(' id="status"', "")
    new = ['\n<section class="brief" style="max-width:none"><span class="eyebrow">Chill Bee Game &middot; comparisons</span>',
           f"<h1>{esc(h1)}</h1><p>{brief}</p>", '<p class="status" id="status">Loading saved votes…</p></section>']
    for sec in sections:
        new.append(f'<section class="row"><span class="eyebrow">{sec["eyebrow"]}</span><h2>{esc(sec["h2"])}</h2>'
                   f'<p class="small">{sec["text"]}</p><div class="rgrid">' + "\n".join(sec["cards"]) + "</div></section>")
    new.append(f'<details><summary>Earlier questions</summary><div class="wrap">{old}</div></details>\n')
    page = page[:i] + "\n".join(new) + page[k:]
    if title:
        page = re.sub(r"<title>[^<]*</title>", f"<title>{esc(title)}</title>", page, count=1)
    return page


def cmd_add(page_path, out, sections, h1, brief, title=None):
    page = open(page_path, encoding="utf-8").read()
    open(out, "w", encoding="utf-8").write(add_sections(page, sections, h1, brief, title))


def stop_section(blackboard, row, options, ref, shot, prefix):
    """The designer-stop question as a votable section: one card per option and the current build."""
    num, rule, where, finding, fix = waiting_row(blackboard, row)[:5]
    texts = fix_options(fix)
    cards = []
    for spec in options:
        letter, folder = spec.split("=", 1)
        cards.append(vote_card(f"{prefix}-{letter.lower()}", f"{letter}: {short(texts.get(letter, 'Option ' + letter))}",
                               os.path.join(folder, shot), [esc(texts.get(letter, ""))], meta={"question": prefix, "option": letter}))
    cards.append(vote_card(f"{prefix}-ref", "Current build (reference)", os.path.join(ref, shot),
                           ["The build as it is now; nothing changes until you pick."], meta={"question": prefix, "option": "ref"}))
    return {"eyebrow": f"Style loop &middot; designer stop &middot; {esc(rule)}", "h2": f"{rule}: {finding}",
            "text": f"<code>{esc(where)}</code>. Vote yes on the option to apply.", "cards": cards}


def variants_section(shots_dir, prefix, title, checks=None):
    files = sorted(f for f in os.listdir(shots_dir) if f.endswith(".png"))[:9]
    checks = json.load(open(checks, encoding="utf-8")) if checks else {}
    cards = []
    for f in files:
        c = checks.get(f, {})
        sid = f[:-4] if f[:-4].startswith(prefix) else f"{prefix}-{f[:-4]}"  # model shots are already <prop>-a
        cards.append(vote_card(sid, f[:-4], os.path.join(shots_dir, f), [esc(c.get("summary", ""))],
                               ("style_check " + ("PASS" if c.get("pass", True) else "FAIL"), c.get("pass", True)),
                               meta={"question": prefix}))
    return {"eyebrow": "Colorbox variants (Milo) &middot; 5 &times; 5 test grid", "h2": title,
            "text": "Each variant on the test grid under the farm's light and camera, checked by <code>style_check.py</code>. "
                    "Bob promotes the pick into <code>game/scenes/props/</code>.", "cards": cards}


def versions_section(prefix, title, versions, text=""):
    """One card per build version, each a contact sheet of the same ui_shots.py moments. versions: [(label, png, caption)]."""
    cards = [vote_card(f"{prefix}-{label}", label, png, [esc(cap)] if cap else [], meta={"question": prefix, "version": label})
             for label, png, cap in versions]
    return {"eyebrow": "Versions side by side &middot; <code>_tools/ui_shots.py</code>", "h2": title,
            "text": text or "Each sheet shows the same moments in one version. Click a sheet to see it full size. "
                            "Vote yes on the version that places things right, and say in the note which moment.", "cards": cards}


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, args in (("page", ("spec", "out")), ("round", ("shots_dir", "round_json", "spec_json", "prev_page", "out")),
                       ("votes", ("shots_dir", "shots_json", "prev_page", "out"))):
        s = sub.add_parser(name)
        for a in args:
            s.add_argument(a)
    s = sub.add_parser("add", help="put new questions at the top of an existing vote page")
    s.add_argument("page")
    s.add_argument("out")
    s.add_argument("--h1", required=True)
    s.add_argument("--brief", default="")
    s.add_argument("--title")
    s.add_argument("--stop", nargs=2, metavar=("BLACKBOARD", "ROW"), action="append", default=[],
                   help="a designer-stop row; with --option, --ref, --shot, --prefix")
    s.add_argument("--option", action="append", default=[], metavar="LETTER=DIR")
    s.add_argument("--ref")
    s.add_argument("--shot")
    s.add_argument("--variants", nargs=3, metavar=("SHOTS_DIR", "PREFIX", "TITLE"), action="append", default=[])
    s.add_argument("--checks", action="append", default=[], help="checks.json per --variants, in order")
    s.add_argument("--prefix", action="append", default=[], help="vote id prefix per --stop, in order")
    s.add_argument("--versions", nargs=2, metavar=("PREFIX", "TITLE"), help="a versions section; with --version")
    s.add_argument("--version", action="append", default=[], metavar="LABEL=PNG[=CAPTION]")
    s.add_argument("--versions-text", default="")
    s = sub.add_parser("variants")
    s.add_argument("shots_dir")
    s.add_argument("out")
    s.add_argument("--title", default="Prop variants")
    s.add_argument("--checks", help="JSON {file: {pass, summary}} from model_shots.py")
    s = sub.add_parser("stop")
    s.add_argument("blackboard")
    s.add_argument("--row", type=int, required=True)
    s.add_argument("--option", action="append", required=True, metavar="LETTER=DIR")
    s.add_argument("--ref", required=True)
    s.add_argument("--shot", required=True)
    s.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "page":
        cmd_page(a.spec, a.out)
    elif a.cmd == "round":
        cmd_round(a.shots_dir, a.round_json, a.spec_json, a.prev_page, a.out)
    elif a.cmd == "votes":
        cmd_votes(a.shots_dir, a.shots_json, a.prev_page, a.out)
    elif a.cmd == "add":
        secs = [stop_section(b, int(r), a.option, a.ref, a.shot, a.prefix[n]) for n, (b, r) in enumerate(a.stop)]
        secs += [variants_section(d, pre, t, a.checks[n] if n < len(a.checks) else None) for n, (d, pre, t) in enumerate(a.variants)]
        if a.versions:
            vs = [(v.split("=", 2) + [""])[:3] for v in a.version]
            secs.insert(0, versions_section(a.versions[0], a.versions[1], vs, a.versions_text))
        cmd_add(a.page, a.out, secs, a.h1, a.brief, a.title)
    elif a.cmd == "variants":
        cmd_variants(a.shots_dir, a.out, a.title, a.checks)
    else:
        cmd_stop(a.blackboard, a.row, a.option, a.ref, a.shot, a.out)


if __name__ == "__main__":
    main(sys.argv[1:])
