"""Build the 3 x 3 grid-zoom vote page (cell size x zoom) with yes / maybe / no per shot, stored in the artifact db.

    python -I build_votes.py SHOTS_DIR shots.json previous_page.html out.html

The votes live in the db collection "votes", one doc per shot id ("c1.5-z1"): {vote, note, file, cell_size, zoom,
zoom_size, min_cell_px, updatedAt}. Claude reads them with ArtifactData and writes the decision JSON into the repo.
"""
import base64, html, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ZOOMS = {1: "Z1 &middot; rack", 2: "Z2 &middot; hive + centrifuge", 3: "Z3 &middot; hive + centrifuge + crate"}


def b64(p):
    return "data:image/png;base64," + base64.b64encode(open(p, "rb").read()).decode()


def main(shots_dir, shots_json, prev_page, out):
    shots = json.load(open(shots_json, encoding="utf-8"))
    shots = shots.get("shots", shots) if isinstance(shots, dict) else shots
    head = open(os.path.join(HERE, "head.html"), encoding="utf-8").read().splitlines()
    head = [l for l in head[1:] if not l.startswith('<span class="eyebrow">') and l not in ('<div class="wrap">', '<section class="brief">')]
    css_end = head.index("</style>")
    extra = """
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

if __name__ == "__main__":
    main(*sys.argv[1:5])
