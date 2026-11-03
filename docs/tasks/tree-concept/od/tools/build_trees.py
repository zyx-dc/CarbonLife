"""CarbonLife tree set generator.

Design target: 108 px. Everything is sized so the silhouette and the
dominant colour survive at 108/200 = 0.54 scale.

Output: trees/tree_{variant}_{stage}.svg  (30 files)
"""

import os

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "trees")

TRUNK = "#6B4B33"
SOIL = "#6B4B33"
SEED = "#A97C50"
FRUIT = "#8F3B2A"
HALO = "#B6FF2E"

VARIANTS = {
    "mixed":   dict(main="#4E9F63", deep="#3A7F4D", light="#63B878", halo=(100, 92, 74, 66)),
    "travel":  dict(main="#2FA894", deep="#227F70", light="#5CC4AE", halo=(100, 92, 76, 62)),
    "recycle": dict(main="#4C8FA8", deep="#376E84", light="#7FB0C6", halo=(100, 100, 74, 60)),
    "energy":  dict(main="#D9A63C", deep="#A87C26", light="#E8C46A", halo=(100, 88, 46, 64)),
    "food":    dict(main="#C97A5E", deep="#A05B43", light="#E39A7E", halo=(100, 96, 70, 64)),
}

STAGE_SCALE = {2: 0.62, 3: 0.86, 4: 0.90, 5: 1.00}
STAGE_NAME = {0: "seed", 1: "sprout", 2: "sapling", 3: "bloom", 4: "fruit", 5: "evergreen"}


def f(v):
    s = "%.1f" % v
    return s[:-2] if s.endswith(".0") else s


class Ctx:
    """Scales mature crown geometry toward the trunk base."""

    def __init__(self, s):
        self.s = s

    def pt(self, x, y):
        return (100 + (x - 100) * self.s, 152 + (y - 152) * self.s)

    def r(self, v):
        return v * self.s


def P(d, fill, opacity=None):
    o = ' opacity="%s"' % opacity if opacity is not None else ""
    return '<path d="%s" fill="%s"%s/>' % (d, fill, o)


def E(c, cx, cy, rx, ry, fill, opacity=None):
    x, y = c.pt(cx, cy)
    a, b = c.r(rx), c.r(ry)
    o = ' opacity="%s"' % opacity if opacity is not None else ""
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s/>' % (
        f(x), f(y), f(a), f(b), fill, o)


def CIR(c, cx, cy, r, fill, opacity=None):
    x, y = c.pt(cx, cy)
    rr = c.r(r)
    o = ' opacity="%s"' % opacity if opacity is not None else ""
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>' % (f(x), f(y), f(rr), fill, o)


def esub(c, cx, cy, rx, ry):
    x, y = c.pt(cx, cy)
    a, b = c.r(rx), c.r(ry)
    return ("M %s %s A %s %s 0 1 0 %s %s A %s %s 0 1 0 %s %s Z"
            % (f(x - a), f(y), f(a), f(b), f(x + a), f(y), f(a), f(b), f(x - a), f(y)))


def blob(c, items, dy=0.0):
    return " ".join(esub(c, cx, cy + dy, rx, ry) for (cx, cy, rx, ry) in items)


def rrect(c, x0, y0, x1, y1, r):
    ax, ay = c.pt(x0, y0)
    bx, by = c.pt(x1, y1)
    rr = c.r(r)
    return ("M %s %s H %s Q %s %s %s %s V %s Q %s %s %s %s H %s Q %s %s %s %s V %s "
            "Q %s %s %s %s Z"
            % (f(ax + rr), f(ay), f(bx - rr), f(bx), f(ay), f(bx), f(ay + rr),
               f(by - rr), f(bx), f(by), f(bx - rr), f(by), f(ax + rr),
               f(ax), f(by), f(ax), f(by - rr), f(ay + rr), f(ax), f(ay), f(ax + rr), f(ay)))


def slabs(c, items, dy=0.0):
    return " ".join(rrect(c, x0, y0 + dy, x1, y1 + dy, r) for (x0, y0, x1, y1, r) in items)


def scale_cmds(cmds, c, dy=0.0):
    out = []
    for cmd in cmds:
        op = cmd[0]
        if op == "Z":
            out.append("Z")
        elif op == "M":
            x, y = c.pt(cmd[1], cmd[2] + dy)
            out.append("M %s %s" % (f(x), f(y)))
        elif op == "C":
            x1, y1 = c.pt(cmd[1], cmd[2] + dy)
            x2, y2 = c.pt(cmd[3], cmd[4] + dy)
            x, y = c.pt(cmd[5], cmd[6] + dy)
            out.append("C %s %s %s %s %s %s" % (f(x1), f(y1), f(x2), f(y2), f(x), f(y)))
    return " ".join(out)


def leaf(bx, by, tx, ty, w, fill):
    """Symmetric almond leaf from base to tip. No rotation needed."""
    mx, my = (bx + tx) / 2.0, (by + ty) / 2.0
    dx, dy = tx - bx, ty - by
    ln = (dx * dx + dy * dy) ** 0.5
    px, py = -dy / ln, dx / ln
    c1x, c1y = mx + px * w, my + py * w
    c2x, c2y = mx - px * w, my - py * w
    return ('<path d="M %s %s Q %s %s %s %s Q %s %s %s %s Z" fill="%s"/>'
            % (f(bx), f(by), f(c1x), f(c1y), f(tx), f(ty),
               f(c2x), f(c2y), f(bx), f(by), fill))


# ---------------------------------------------------------------- crowns

MIXED_LOBES = [(100, 74, 54, 54), (54, 116, 36, 36), (146, 116, 36, 36)]
MIXED_FLOWERS = [(78, 30), (100, 22), (122, 30)]
MIXED_FRUIT = [(66, 112), (100, 124), (134, 112)]

TRAVEL_TAIL = [
    ("M", 110, 54),
    ("C", 130, 46, 150, 40, 164, 40),
    ("C", 174, 40, 180, 45, 178, 53),
    ("C", 176, 61, 166, 65, 154, 69),
    ("C", 140, 74, 126, 82, 116, 90),
    ("C", 111, 78, 109, 66, 110, 54),
    ("Z",),
]
TRAVEL_FLOWERS = [(72, 74), (96, 68), (120, 74)]
TRAVEL_FRUIT = [(60, 86), (100, 92), (136, 80)]

RECYCLE_TIERS = [(30, 100, 170, 134, 10), (48, 68, 152, 104, 10), (66, 38, 134, 74, 10)]
RECYCLE_FLOWERS = [(84, 44), (100, 38), (116, 44)]
RECYCLE_FRUIT = [(72, 96), (100, 84), (128, 62)]

ENERGY = [
    ("M", 100, 22),
    ("C", 106, 44, 118, 58, 126, 74),
    ("C", 134, 90, 136, 106, 132, 120),
    ("C", 127, 138, 114, 150, 100, 150),
    ("C", 86, 150, 73, 138, 68, 120),
    ("C", 64, 106, 66, 90, 74, 74),
    ("C", 82, 58, 94, 44, 100, 22),
    ("Z",),
]
ENERGY_LIGHT = [
    ("M", 100, 58),
    ("C", 104, 72, 112, 82, 116, 94),
    ("C", 120, 106, 118, 118, 112, 126),
    ("C", 106, 133, 94, 133, 88, 126),
    ("C", 82, 118, 80, 106, 84, 94),
    ("C", 88, 82, 96, 72, 100, 58),
    ("Z",),
]
ENERGY_FLOWERS = [(94, 20), (100, 14), (106, 20)]
ENERGY_FRUIT = [(92, 86), (108, 100), (100, 68)]

FOOD_BODY = [(100, 72, 62, 62), (100, 114, 54, 22)]
FOOD_FLOWERS = [(84, 20), (100, 14), (116, 20)]
FOOD_FRUIT = [(70, 98), (100, 110), (130, 98)]


def crown(variant, c, col):
    """Returns (deep, main, light) elements for one variant at scale c."""
    if variant == "mixed":
        return (P(blob(c, MIXED_LOBES, 8), col["deep"]),
                P(blob(c, MIXED_LOBES), col["main"]),
                E(c, 96, 50, 38, 18, col["light"]))
    if variant == "travel":
        return (P(esub(c, 84, 100, 50, 24) + " " + esub(c, 138, 96, 32, 15), col["deep"]),
                P(esub(c, 80, 92, 50, 24) + " " + esub(c, 136, 88, 32, 15), col["main"]),
                E(c, 62, 84, 26, 14, col["light"]))
    if variant == "recycle":
        return (P(slabs(c, RECYCLE_TIERS, 7), col["deep"]),
                P(slabs(c, RECYCLE_TIERS), col["main"]),
                E(c, 86, 63, 16, 8, col["light"]))
    if variant == "energy":
        return (P(scale_cmds(ENERGY, c, -10), col["deep"]),
                P(scale_cmds(ENERGY, c, -12), col["main"]),
                P(scale_cmds(ENERGY_LIGHT, c, -12), col["light"]))
    if variant == "food":
        return (P(blob(c, FOOD_BODY, 8), col["deep"]),
                P(blob(c, FOOD_BODY), col["main"]),
                E(c, 82, 54, 30, 20, col["light"]))
    raise ValueError(variant)


ANCHORS = {
    "mixed": (MIXED_FLOWERS, MIXED_FRUIT, 9),
    "travel": (TRAVEL_FLOWERS, TRAVEL_FRUIT, 8),
    "recycle": (RECYCLE_FLOWERS, RECYCLE_FRUIT, 8),
    "energy": (ENERGY_FLOWERS, ENERGY_FRUIT, 6),
    "food": (FOOD_FLOWERS, FOOD_FRUIT, 15),
}


def trunk(top, lean=0.0, s=1.0):
    wb = 16 + 6 * s
    wt = 11 + 4 * s
    xbl, xbr = 100 - wb / 2, 100 + wb / 2
    xtl, xtr = 100 + lean - wt / 2, 100 + lean + wt / 2
    d = ("M %s 178 C %s 160 %s %s %s %s L %s %s C %s %s %s 160 %s 178 Z"
         % (f(xbl), f(xbl + 2), f(xtl - 1), f(min(160, top + 18)), f(xtl), f(top),
            f(xtr), f(top), f(xtr + 1), f(min(160, top + 18)), f(xbr - 2), f(xbr)))
    return '<path d="%s" fill="%s"/>' % (d, TRUNK)


def ground(rx, col):
    return E(Ctx(1.0), 100, 178, rx, 8.5, col["main"], 0.15)


def build(variant, stage):
    col = VARIANTS[variant]
    els = []

    if stage == 5:
        # 常青靠体量与更满的冠表达，不再画光环：缩到 108px 时它会变成一道残月
        pass

    if stage == 0:
        els.append(ground(46, col))
        els.append(P("M 52 176 C 52 156 72 146 100 146 C 128 146 148 156 148 176 Z", SOIL))
        els.append('<ellipse cx="100" cy="134" rx="13" ry="18" fill="%s"/>' % SEED)
        els.append('<path d="M 100 120 L 100 106" stroke="%s" stroke-width="5" '
                   'stroke-linecap="round"/>' % TRUNK)
        els.append(leaf(100, 118, 78, 96, 11, col["light"]))
        els.append(leaf(100, 112, 122, 92, 11, col["main"]))
        return els

    if stage == 1:
        els.append(ground(40, col))
        els.append(P("M 96 178 L 96 128 Q 96 120 100 120 Q 104 120 104 128 L 104 178 Z", TRUNK))
        els.append(leaf(100, 150, 54, 114, 18, col["main"]))
        els.append(leaf(100, 138, 148, 118, 17, col["light"]))
        els.append(leaf(100, 128, 92, 82, 16, col["deep"]))
        return els

    s = STAGE_SCALE[stage]
    c = Ctx(s)
    els.append(ground(34 + 20 * s, col))
    if variant == "travel":
        els.append(trunk(152 - 40 * s, lean=16.0, s=s))
    else:
        els.append(trunk(152 - 22 * s, s=s))

    deep, main, light = crown(variant, c, col)
    els.extend([deep, main, light])

    flowers, fruit, fr = ANCHORS[variant]

    if stage == 3:
        for (x, y) in flowers:
            els.append(CIR(c, x, y, 8, "#F4E9C8"))
            els.append(CIR(c, x, y, 3.4, col["deep"]))
    elif stage == 4:
        for (x, y) in fruit:
            els.append(CIR(c, x, y, fr, FRUIT))

    if variant == "travel":
        for (y, x0) in ((96, 172), (120, 180)):
            els.append('<path d="M %s %s L %s %s" stroke="%s" stroke-width="5" '
                       'stroke-linecap="round" opacity="0.26"/>'
                       % (f(x0), f(y), f(x0 + 12), f(y), col["light"]))
    return els


def render(variant, stage):
    body = build(variant, stage)
    label = "%s tree, %s stage" % (variant, STAGE_NAME[stage])
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" '
            'width="200" height="200" role="img" aria-label="%s">\n  %s\n</svg>\n'
            % (label, "\n  ".join(body)))


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for variant in VARIANTS:
        for stage in range(6):
            name = "tree_%s_%d.svg" % (variant, stage)
            with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as fh:
                fh.write(render(variant, stage))
            n += 1
    print("wrote %d files to %s" % (n, OUT))


if __name__ == "__main__":
    main()
