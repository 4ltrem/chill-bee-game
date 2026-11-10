"""Export Bee Journal entries from content/bee-journal-real.md to game/translations/journal.csv.

Spec 0.2 item 8. Keys JOURNAL_<ID>_TITLE / JOURNAL_<ID>_BODY; columns keys,en,fr.
Text is copied verbatim from the approved file (only the heading's italic Latin name and
the italic wrapper of the closing note are dropped). Run: python -I _tools/journal_csv.py
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "content" / "bee-journal-real.md"
OUT = ROOT / "game" / "translations" / "journal.csv"
# id -> (English heading prefix, French heading prefix)
ENTRIES = {"BUMBLE_BEES": ("### Entry 3 — ", "### Entrée 3 — ")}


def entry(lines: list[str], prefix: str) -> tuple[str, str]:
    start = next(i for i, ln in enumerate(lines) if ln.startswith(prefix))
    title = re.split(r" \*\(", lines[start][len(prefix):])[0].strip()
    paras: list[str] = []
    for ln in lines[start + 1:]:
        if ln.strip() == "---" or ln.startswith("###"):
            break
        if not ln.strip() or ln.startswith("**"):   # blank or the Biomes / Attracted-by metadata
            continue
        if ln.startswith("*") and ln.rstrip().endswith("*"):
            ln = ln.strip()[1:-1]
        paras.append(ln.strip())
    return title, "\n\n".join(paras)


def main() -> None:
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["keys", "en", "fr"])
        for eid, (en_p, fr_p) in ENTRIES.items():
            en_t, en_b = entry(lines, en_p)
            fr_t, fr_b = entry(lines, fr_p)
            w.writerow([f"JOURNAL_{eid}_TITLE", en_t, fr_t])
            w.writerow([f"JOURNAL_{eid}_BODY", en_b, fr_b])
    print("wrote", OUT)


if __name__ == "__main__":
    main()
