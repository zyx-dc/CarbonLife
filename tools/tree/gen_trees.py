"""生成碳小树的形态素材：4 形态 × 4 阶段（小树/开花/结果/常青）。

风格对齐现有 sapling_2.svg：200×200、扁平树冠、地面阴影、棕色树干。
颜色保持同一绿色家族，形态差异靠“骨架”（宽窄/层叠/朝向/果实）拉开。
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "entry/src/main/resources/base/media"

TRUNK = "#6B4F35"
SHADOW = "#8C7B5E"
DARK = "#2E8B57"
MID = "#3FA36A"
LIGHT = "#4CB877"
BLOSSOM = "#F2E8C9"
FRUIT = "#E8603C"
GLOW = "#E9C46A"

# 每个形态由若干椭圆组成：(cx, cy, rx, ry, 颜色层级 0/1/2)
CANOPY = {
    # 均衡：三层圆润，左右对称
    "mixed": [
        (100, 100, 30, 27, 0), (80, 112, 19, 17, 1), (120, 112, 19, 17, 2),
    ],
    # 出行：横向压扁、整体右偏，像被风推着
    "travel": [
        (112, 96, 36, 16, 1), (76, 100, 24, 14, 0), (136, 94, 20, 12, 2),
    ],
    # 回收：三层叠起来的塔形树冠，像一点点攒上去的
    "recycle": [
        (100, 118, 26, 10, 1), (100, 102, 23, 11, 0),
        (100, 88, 18, 10, 1), (100, 76, 13, 8, 2),
    ],
    # 饮食：饱满圆冠，果实最大
    "food": [
        (100, 102, 31, 28, 0), (79, 113, 18, 17, 1), (121, 113, 18, 17, 2),
    ],
    # 节能：细高、纵向，带光点
    "energy": [
        (100, 86, 19, 26, 0), (100, 112, 15, 18, 1),
        (88, 96, 10, 14, 2), (112, 96, 10, 14, 2),
    ],
}

ORNAMENT = {
    "mixed": [(84, 92), (116, 94), (100, 112), (74, 106), (126, 106)],
    "travel": [(96, 88), (126, 92), (76, 94), (116, 104), (66, 100)],
    "recycle": [(88, 120), (112, 118), (100, 102), (86, 90), (114, 90)],
    "food": [(84, 94), (116, 92), (100, 110), (78, 112), (122, 112)],
    "energy": [(100, 74), (100, 92), (90, 106), (110, 106), (100, 120)],
}

STAGE_SCALE = {2: 0.86, 3: 0.96, 4: 1.06, 5: 1.18}
STAGE_TRUNK = {2: (166, 114, 7), 3: (166, 110, 7.5), 4: (166, 108, 8.5), 5: (168, 104, 9.5)}
LEAN = {"mixed": 0, "travel": 9, "recycle": 0, "food": 0, "energy": 2}
FILL = {0: DARK, 1: MID, 2: LIGHT}


def canopy_parts(variant: str, stage: int) -> str:
    s = STAGE_SCALE[stage]
    out = []
    for cx, cy, rx, ry, level in CANOPY[variant]:
        x = 100 + (cx - 100) * s
        y = 100 + (cy - 100) * s
        out.append(
            f'  <ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx * s:.1f}" ry="{ry * s:.1f}" '
            f'fill="{FILL[level]}"/>'
        )
    return "\n".join(out)


def ornaments(variant: str, stage: int) -> str:
    pts = ORNAMENT[variant]
    out = []
    if stage == 3:
        for (x, y) in pts:
            out.append(f'  <circle cx="{x}" cy="{y}" r="3.2" fill="{BLOSSOM}" opacity="0.95"/>')
    elif stage >= 4:
        r = 6.2 if variant == "food" else 4.2
        for (x, y) in pts[:4]:
            out.append(f'  <circle cx="{x}" cy="{y}" r="{r}" fill="{FRUIT}"/>')
        if stage == 5:
            out.append(f'  <circle cx="{pts[4][0]}" cy="{pts[4][1]}" r="{r - 1}" fill="{FRUIT}" opacity="0.9"/>')

    if variant == "energy" and stage >= 3:
        for (x, y) in [(100, 68), (84, 84), (116, 84), (100, 96)]:
            out.append(f'  <circle cx="{x}" cy="{y}" r="2.6" fill="{GLOW}" opacity="0.95"/>')

    if variant == "travel":
        out.append(
            f'  <path d="M148 86 q18 2 30 -3" stroke="{MID}" stroke-width="1.8" opacity="0.5" '
            f'fill="none" stroke-linecap="round"/>'
        )
        out.append(
            f'  <path d="M150 99 q20 3 32 -2" stroke="{MID}" stroke-width="1.8" opacity="0.35" '
            f'fill="none" stroke-linecap="round"/>'
        )
    if variant == "recycle" and stage >= 4:
        # 层叠感：树冠下沿加两道短弧，像枝叶压着长
        out.append(
            f'  <path d="M70 126 q30 10 60 0" stroke="{DARK}" stroke-width="2" opacity="0.35" '
            f'fill="none" stroke-linecap="round"/>'
        )
    return "\n".join(out)


def tree_svg(variant: str, stage: int) -> str:
    _, trunk_top, width = STAGE_TRUNK[stage]
    lean = LEAN[variant]
    s = STAGE_SCALE[stage]
    ring = ""
    if stage == 5:
        ring = (f'  <circle cx="100" cy="100" r="{56 * s:.0f}" fill="none" stroke="{MID}" '
                f'stroke-width="1.2" opacity="0.22"/>\n')
    branches = (
        f'  <path d="M{100 + lean} {trunk_top + 12} q-18 -8 -26 -18" stroke="{TRUNK}" '
        f'stroke-width="3.4" fill="none" stroke-linecap="round"/>\n'
        f'  <path d="M{100 + lean} {trunk_top + 18} q18 -8 26 -14" stroke="{TRUNK}" '
        f'stroke-width="3.4" fill="none" stroke-linecap="round"/>\n'
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">\n'
        f'  <ellipse cx="100" cy="172" rx="{50 * s:.0f}" ry="11" fill="{SHADOW}" opacity="0.18"/>\n'
        f'{ring}'
        f'  <path d="M100 168 Q{100 + lean} {trunk_top + 26} {100 + lean} {trunk_top}" '
        f'stroke="{TRUNK}" stroke-width="{width}" fill="none" stroke-linecap="round"/>\n'
        f'{branches}'
        f'{canopy_parts(variant, stage)}\n'
        f'{ornaments(variant, stage)}\n'
        '</svg>\n'
    )


def main() -> None:
    if not OUT.exists():
        raise SystemExit(f"missing media dir: {OUT}")
    count = 0
    for variant in CANOPY:
        for stage in (2, 3, 4, 5):
            path = OUT / f"tree_{variant}_{stage}.svg"
            path.write_text(tree_svg(variant, stage), encoding="utf-8")
            count += 1
    print(f"generated {count} svg -> {OUT}")


if __name__ == "__main__":
    main()
