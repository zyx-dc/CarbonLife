# -*- coding: utf-8 -*-
"""Post-process the generated design-doc.docx.

html-to-docx cannot express a few things the document needs, so we fix them on the
docx itself (run this right after `node scripts/make-docx.cjs`):

1. Figure layout tables (the side-by-side screenshot pairs) get a visible border and
   a divider because html-to-docx ignores `border="0"` / `style="border:none"` - strip
   every border from any table that contains an image.
2. Content tables get real column widths (html-to-docx renders 3-column tables as
   equal thirds, which squeezes the "说明" column and breaks long identifiers).
3. Content tables repeat their header row when they cross a page.
4. The permission-name column in table 6 is set to 9.5 pt so
   `ohos.permission.DISTRIBUTED_DATASYNC` no longer breaks mid-word.

Usage:
  python scripts/postprocess-docx.py [--docx PATH]
"""
import argparse
import sys
from pathlib import Path

try:
    from docx import Document
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement
    from docx.shared import Cm, Pt
except ImportError:
    sys.exit("python-docx is required: python -m pip install python-docx")

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DOCX = REPO / "docs" / "tasks" / "design-doc" / "CarbonLife-设计文档.docx"

# content-table column widths in cm, keyed by 1-based content-table index (表 N)
COLUMN_WIDTHS = {
    1: (4.2, 11.0),
    2: (2.2, 3.6, 9.4),
    3: (4.2, 11.0),
    4: (4.2, 11.0),
    5: (4.2, 11.0),
    6: (6.5, 3.0, 5.7),
    7: (3.2, 5.2, 6.8),
}

EDGES = ("top", "left", "bottom", "right", "insideH", "insideV")


def has_image(table):
    return "graphic" in table._tbl.xml


def strip_borders(table):
    tbl = table._tbl
    tblPr = tbl.tblPr
    for el in tblPr.findall(qn("w:tblBorders")):
        tblPr.remove(el)
    borders = OxmlElement("w:tblBorders")
    for edge in EDGES:
        e = OxmlElement("w:" + edge)
        e.set(qn("w:val"), "none")
        e.set(qn("w:sz"), "0")
        e.set(qn("w:space"), "0")
        borders.append(e)
    tblPr.append(borders)
    for row in table.rows:
        for cell in row.cells:
            tcPr = cell._tc.get_or_add_tcPr()
            for el in tcPr.findall(qn("w:tcBorders")):
                tcPr.remove(el)


def set_widths(table, widths_cm):
    table.autofit = False
    tbl = table._tbl
    tblPr = tbl.tblPr
    # explicit table width so LibreOffice/Word do not re-distribute the columns
    total_tw = int(sum(widths_cm) / 2.54 * 1440)
    for el in tblPr.findall(qn("w:tblW")):
        tblPr.remove(el)
    tblW = OxmlElement("w:tblW")
    tblW.set(qn("w:w"), str(total_tw))
    tblW.set(qn("w:type"), "dxa")
    tblPr.append(tblW)
    for row in table.rows:
        for idx, w in enumerate(widths_cm):
            if idx < len(row.cells):
                row.cells[idx].width = Cm(w)


def repeat_header(table):
    tr = table.rows[0]._tr
    trPr = tr.get_or_add_trPr()
    if trPr.find(qn("w:tblHeader")) is None:
        h = OxmlElement("w:tblHeader")
        h.set(qn("w:val"), "true")
        trPr.append(h)


def shrink_first_column(table, pt):
    for row in table.rows[1:]:
        cell = row.cells[0]
        for p in cell.paragraphs:
            for run in p.runs:
                run.font.size = Pt(pt)


def merge_page_breaks(doc):
    """html-to-docx turns `<div class="page-break">` into an EMPTY paragraph carrying a
    page break. When the previous page is already exactly full that paragraph lands on a
    page of its own, producing a blank page. Move the break onto the following paragraph
    (page_break_before) and drop the empty one."""
    paras = list(doc.paragraphs)
    removed = 0
    for i, p in enumerate(paras):
        if p.text.strip():
            continue
        if not any(br.get(qn("w:type")) == "page" for br in p._p.findall(".//" + qn("w:br"))):
            continue
        nxt = next((q for q in paras[i + 1:] if q.text.strip()), None)
        if nxt is None:
            continue
        nxt.paragraph_format.page_break_before = True
        p._p.getparent().remove(p._p)
        removed += 1
    return removed


def drop_empty_before_breaks(doc):
    """A layout table (or image) leaves an empty paragraph behind; if it lands on a new
    page just before a chapter break, that page renders blank. Drop empty paragraphs that
    sit immediately before a page-break-before paragraph."""
    paras = list(doc.paragraphs)
    removed = 0
    for i, p in enumerate(paras):
        if not p.paragraph_format.page_break_before:
            continue
        j = i - 1
        while j >= 0 and not paras[j].text.strip():
            if "graphic" in paras[j]._p.xml:
                break
            el = paras[j]._p
            el.getparent().remove(el)
            removed += 1
            j -= 1
    return removed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--docx", default=str(DEFAULT_DOCX))
    args = ap.parse_args()
    path = Path(args.docx)
    if not path.exists():
        sys.exit(f"docx not found: {path}")

    doc = Document(str(path))
    figures = [t for t in doc.tables if has_image(t)]
    content = [t for t in doc.tables if not has_image(t)]

    moved = merge_page_breaks(doc)
    print(f"  page breaks moved onto headings (blank pages avoided): {moved}")
    dropped = drop_empty_before_breaks(doc)
    print(f"  empty paragraphs removed before chapter breaks: {dropped}")

    for t in figures:
        strip_borders(t)
        for cell in t.rows[0].cells:
            tcPr = cell._tc.get_or_add_tcPr()
            for el in tcPr.findall(qn("w:tcMar")):
                tcPr.remove(el)
    print(f"  figure layout tables (borders stripped): {len(figures)}")

    for i, t in enumerate(content, start=1):
        widths = COLUMN_WIDTHS.get(i)
        if widths and len(t.columns) == len(widths):
            set_widths(t, widths)
        repeat_header(t)
        if i == 6:
            shrink_first_column(t, 8.5)
    print(f"  content tables (widths + repeat header): {len(content)}")

    doc.save(str(path))
    print(f"  saved {path} ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
