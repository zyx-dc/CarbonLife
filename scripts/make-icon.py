# -*- coding: utf-8 -*-
"""生成 CarbonLife 应用图标与启动图标。

设计：深林绿底 + 青柠色碳小树（一茎双叶，象征「碳小树」成长）。
- app_icon.png  ：1024x1024 满幅不透明。系统会套自己的圆角遮罩，
                  所以不能预先切圆角，否则图标会显得缩小、四角露底。
- startIcon.png ：256x256 透明底，深林绿标，铺在 #F1F8E9 启动背景上。

用法：python scripts/make-icon.py
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOREST = (15, 61, 46)      # #0F3D2E
FOREST_HI = (23, 80, 59)   # #17503B 中心微亮
FOREST_LO = (12, 51, 38)   # #0C3326 边缘压暗
LIME = (182, 255, 46)      # #B6FF2E

SS = 2048  # 超采样画布


def leaf_polygon(length, width, n=240):
    """一片叶子：两条对称曲线在中轴收拢成尖头。"""
    top, bot = [], []
    for i in range(n + 1):
        t = i / n
        x = t * length
        w = width * (math.sin(math.pi * t) ** 0.72)
        spine = -0.10 * length * math.sin(math.pi * t)  # 轻微上弯
        top.append((x, spine - w / 2))
        bot.append((x, spine + w / 2))
    return top + bot[::-1]


def place(points, origin, angle_deg, scale=1.0):
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    ox, oy = origin
    out = []
    for x, y in points:
        x *= scale
        y *= scale
        # 数学坐标（y 向上）转屏幕坐标（y 向下）
        rx = x * ca - y * sa
        ry = x * sa + y * ca
        out.append((ox + rx, oy - ry))
    return out


def build_mark(size, color, stroke, vein=None, vein_w=0):
    """在透明画布上画碳小树，返回裁到内容并居中的图层。

    vein 不为 None 时，沿叶片中轴画一条细线（用背景色"切"开叶片），
    大尺寸下更精神；小尺寸下要保证不会糊成脏点。
    """
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    cx = size // 2
    stem_bottom, stem_top = int(size * 0.760), int(size * 0.548)

    # 茎：圆头竖线，顶端收在右叶内部，避免露出圆头
    d.line([(cx, stem_bottom), (cx, stem_top)], fill=color + (255,), width=stroke)
    r = stroke // 2
    for y in (stem_bottom, stem_top):
        d.ellipse([cx - r, y - r, cx + r, y + r], fill=color + (255,))

    leaves = [
        (int(size * 0.630), 150, size * 0.290, size * 0.150),
        (int(size * 0.520), 34, size * 0.310, size * 0.158),
    ]
    for oy, ang, L, W in leaves:
        poly = place(leaf_polygon(L, W), (cx, oy), ang)
        d.polygon(poly, fill=color + (255,))
        if vein is not None and vein_w > 0:
            spine = []
            n = 60
            for i in range(n + 1):
                t = i / n
                x = t * L
                y = -0.10 * L * math.sin(math.pi * t)
                a = math.radians(ang)
                spine.append((cx + x * math.cos(a) - y * math.sin(a),
                              oy - (x * math.sin(a) + y * math.cos(a))))
            d.line(spine, fill=vein + (255,), width=vein_w, joint='curve')

    bbox = layer.getbbox()
    if bbox is None:
        return layer
    content = layer.crop(bbox)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(content, ((size - content.width) // 2, (size - content.height) // 2), content)
    return out


def radial_bg(size, hi, lo):
    """中心微亮的径向渐变，避免大面积死板纯色。"""
    img = Image.new('RGB', (size, size), lo)
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    maxd = math.hypot(cx, cy)
    steps = 260
    for i in range(steps, 0, -1):
        t = i / steps
        rr = maxd * t
        k = 1 - t  # 0 边缘 -> 1 中心
        col = tuple(int(lo[j] + (hi[j] - lo[j]) * (k ** 1.6)) for j in range(3))
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
    return img


def main():
    # ---- 应用图标：满幅、不透明 ----
    bg = radial_bg(SS, FOREST_HI, FOREST_LO)
    mark = build_mark(SS, LIME, int(SS * 0.030), vein=FOREST, vein_w=int(SS * 0.0075))
    # 标记缩到画布的 56%，落在系统遮罩安全区内
    target = int(SS * 0.62)
    bbox = mark.getbbox()
    content = mark.crop(bbox)
    scale = target / max(content.width, content.height)
    content = content.resize((int(content.width * scale), int(content.height * scale)),
                             Image.LANCZOS)
    canvas = bg.convert('RGBA')
    canvas.alpha_composite(content, ((SS - content.width) // 2, (SS - content.height) // 2))
    app_icon = canvas.resize((1024, 1024), Image.LANCZOS)

    # ---- 启动图标：透明底、深林绿标 ----
    start = build_mark(SS, FOREST, int(SS * 0.032), vein=(241, 248, 233),
                       vein_w=int(SS * 0.0075))
    b2 = start.getbbox()
    c2 = start.crop(b2)
    s2 = int(SS * 0.82) / max(c2.width, c2.height)
    c2 = c2.resize((int(c2.width * s2), int(c2.height * s2)), Image.LANCZOS)
    start_canvas = Image.new('RGBA', (SS, SS), (0, 0, 0, 0))
    start_canvas.alpha_composite(c2, ((SS - c2.width) // 2, (SS - c2.height) // 2))
    start_icon = start_canvas.resize((256, 256), Image.LANCZOS)

    targets = [
        ('AppScope/resources/base/media/app_icon.png', app_icon),
        ('entry/src/main/resources/base/media/app_icon.png', app_icon),
        ('entry/src/main/resources/base/media/startIcon.png', start_icon),
    ]
    for rel, im in targets:
        p = os.path.join(ROOT, rel)
        im.save(p)
        print('wrote %-58s %s %s' % (rel, im.size, im.mode))

    # 缩小预览：确认 48px 下不会糊成一团
    preview = os.path.join(ROOT, '.tmp-docdiff', 'icon-preview.png')
    os.makedirs(os.path.dirname(preview), exist_ok=True)
    sheet = Image.new('RGBA', (1024, 240), (255, 255, 255, 255))
    x = 16
    for px in (240, 128, 96, 72, 48):
        t = app_icon.resize((px, px), Image.LANCZOS)
        sheet.alpha_composite(t, (x, (240 - px) // 2))
        x += px + 24
    sheet.save(preview)
    print('preview ->', preview)


if __name__ == '__main__':
    main()
