# -*- coding: utf-8 -*-
"""Optimize the user-provided family-group screenshot into assets/family.jpg."""
from pathlib import Path
from PIL import Image

SRC = Path(r"C:\Users\39748\Pictures\Screenshot_2026-10-10T182839.png")
ASSETS = Path(__file__).resolve().parent / "assets"
OUT = ASSETS / "family.jpg"

im = Image.open(SRC).convert("RGB")
w, h = im.size
# 去掉：顶部状态栏 + 被截断的“今日任务”行；底部 Tab 栏
top, bottom = 340, 2515
im2 = im.crop((0, top, w, bottom))
nw = 1200
nh = round(im2.height * nw / im2.width)
im2 = im2.resize((nw, nh), Image.LANCZOS)
im2.save(OUT, "JPEG", quality=92)
print("SAVED", OUT, im2.size)
