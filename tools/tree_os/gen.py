"""CarbonLife tree set from Temaki (CC0) silhouettes.

Temaki icons are 15x15 single-path silhouettes with fill="currentColor".
We scale them into a 200x200 box, add a one-pixel-ish deep offset for depth,
and derive six stages: seed, sprout, sapling, bloom, fruit, evergreen.

Output: 5 variants x 6 stages = 30 SVGs.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/tasks/tree-concept/open-source"
OUT = ROOT / "docs/tasks/tree-concept/open-source/generated"

# variant -> (temaki file, main, deep)
VARIANTS = {
    "mixed":   ("temaki-broadleaved.svg", "#4E9F63", "#3A7F4D"),
    "travel":  ("temaki-palm.svg",        "#2FA894", "#227F70"),
    "recycle": ("temaki-leafless.svg",    "#4C8FA8", "#376E84"),
    "energy":  ("temaki-needleleaved.svg","#D9A63C", "#A87C26"),
    "food":    ("temaki-broadleaved.svg", "#C97A5E", "#A05B43"),
}

STAGE_SCALE = {0: 0.00, 1: 0.34, 2: 0.55, 3: 0.72, 4: 0.88, 5: 1.00}
TRUNK = "#6B4B33"
SOIL = "#4A3A2A"
SEED = "#A97C50"
CREAM = "#F4E9C8"
FRUIT = "#8F3B2A"


def read_icon(name: str):
    raw = (SRC / name).read_text(encoding="utf-8")
    vb = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', raw)
    d = re.search(r'<path[^>]*\sd="([^"]+)"', raw)
    if not vb or not d:
        raise ValueError("unexpected svg: " + name)
    return float(vb.group(1)), float(vb.group(2)), d.group(1)


def shade(hex_color: str, factor: float) -> str:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    r, g, b = (max(0, min(255, int(round(v * factor)))) for v in (r, g, b))
    return "#%02X%02X%02X" % (r, g, b)


def seed_svg(main: str, deep: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <ellipse cx="100" cy="178" rx="38" ry="7" fill="{deep}" opacity="0.15"/>
  <path d="M64 177 C64 160 80 150 100 150 C120 150 136 160 136 177 Z" fill="{SOIL}" opacity="0.55"/>
  <ellipse cx="100" cy="150" rx="12" ry="16" fill="{SEED}" transform="rotate(-8 100 150)"/>
  <path d="M94 146 Q100 141 106 147" stroke="#7E5A36" stroke-width="1.6" fill="none" opacity="0.7" stroke-linecap="round"/>
  <path d="M100 138 Q97 130 101 124" stroke="{main}" stroke-width="4" fill="none" stroke-linecap="round"/>
  <path d="M101 128 Q108 122 116 122 Q112 131 103 132 Z" fill="{deep}"/>
  <path d="M99 132 Q91 126 83 128 Q88 136 97 136 Z" fill="{main}"/>
</svg>'''


def sprout_svg(main: str, deep: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <ellipse cx="100" cy="178" rx="36" ry="7" fill="{deep}" opacity="0.15"/>
  <path d="M100 176 Q96 156 100 132" stroke="{TRUNK}" stroke-width="7" fill="none" stroke-linecap="round"/>
  <path d="M100 150 Q80 146 64 132 Q84 120 100 138 Z" fill="{main}"/>
  <path d="M100 142 Q120 136 136 120 Q118 108 101 128 Z" fill="{deep}"/>
  <path d="M100 130 Q96 114 100 102 Q106 116 103 130 Z" fill="{main}"/>
</svg>'''


def tree_svg(variant: str, stage: int) -> str:
    name, main, deep = VARIANTS[variant]
    if stage == 0:
        return seed_svg(main, deep)
    if stage == 1:
        return sprout_svg(main, deep)

    vw, vh, d = read_icon(name)
    f = STAGE_SCALE[stage]
    k = (170.0 * f) / vw
    tx = 100.0 - (vw * k) / 2.0
    ty = 178.0 - vh * k

    if stage == 5:
        main = shade(main, 0.92)
        deep = shade(deep, 0.90)

    h = vh * k
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">',
        f'  <ellipse cx="100" cy="178" rx="{44 * f:.0f}" ry="7" fill="{deep}" opacity="0.15"/>',
        f'  <g transform="translate({tx:.2f} {ty:.2f}) scale({k:.3f})">',
        f'    <path d="{d}" fill="{deep}" transform="translate(0.20 0.26)"/>',
        f'    <path d="{d}" fill="{main}"/>',
        '  </g>',
    ]

    if stage == 3:
        w = vw * k
        pts = [(100 - 0.20 * w, ty + 0.22 * h),
               (100 - 0.08 * w, ty + 0.28 * h),
               (100 + 0.05 * w, ty + 0.20 * h),
               (100 + 0.18 * w, ty + 0.26 * h),
               (100, ty + 0.13 * h)]
        for x, y in pts:
            parts.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="3.4" fill="{CREAM}"/>')

    w = vw * k
    if stage == 4:
        if variant == "recycle":
            # 枯枝回芽：结果期先长绿芽，不结红果
            pts = [(100 - 0.20 * w, ty + 0.34 * h),
                   (100 + 0.20 * w, ty + 0.34 * h),
                   (100, ty + 0.50 * h),
                   (100 - 0.04 * w, ty + 0.20 * h)]
            for x, y in pts:
                parts.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="4.6" fill="#6FBF73"/>')
        else:
            pts = [(100 - 0.15 * w, ty + 0.46 * h),
                   (100, ty + 0.54 * h),
                   (100 + 0.15 * w, ty + 0.46 * h)]
            for x, y in pts:
                parts.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="6.4" fill="{FRUIT}"/>')

    if stage == 5 and variant == "recycle":
        # 常青：枝头补叶，让"循环再生"闭环
        leaves = [(100 - 0.22 * w, ty + 0.30 * h, -28),
                  (100 + 0.22 * w, ty + 0.30 * h, 28),
                  (100 - 0.12 * w, ty + 0.16 * h, -14),
                  (100 + 0.12 * w, ty + 0.16 * h, 14),
                  (100, ty + 0.09 * h, 0),
                  (100, ty + 0.46 * h, 0)]
        for x, y, a in leaves:
            parts.append(f'  <ellipse cx="{x:.1f}" cy="{y:.1f}" rx="6.2" ry="3.2" '
                         f'fill="#6FBF73" transform="rotate({a} {x:.1f} {y:.1f})"/>')

    parts.append('</svg>')
    return "\n".join(parts)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for variant in VARIANTS:
        for stage in range(6):
            (OUT / f"tree_{variant}_{stage}.svg").write_text(tree_svg(variant, stage), encoding="utf-8")
            n += 1
    print(f"generated {n} -> {OUT}")


if __name__ == "__main__":
    main()
