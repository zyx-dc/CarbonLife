"""Compose clay-tree renders: add a soft contact shadow, export 512 and 256 PNGs,
and build a 108px preview page."""
from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(ROOT, "docs", "tasks", "tree-concept", "3d", "kenney")
OUT = os.path.join(ROOT, "docs", "tasks", "tree-concept", "3d", "final")
os.makedirs(OUT, exist_ok=True)

VARIANTS = ["mixed", "travel", "recycle", "energy", "food"]
STAGES = range(6)


def compose(path: str) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if not bbox:
        return im
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    cx = (bbox[0] + bbox[2]) // 2
    by = bbox[3] - 8
    w = (bbox[2] - bbox[0]) * 0.60
    h = max(14, w * 0.11)
    d.ellipse((cx - w / 2, by - h / 2, cx + w / 2, by + h / 2), fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(11))
    canvas = Image.new("RGBA", im.size, (0, 0, 0, 0))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(im)
    return canvas


def main() -> None:
    for v in VARIANTS:
        for s in STAGES:
            src = os.path.join(RAW, f"tree_{v}_{s}.png")
            if not os.path.exists(src):
                continue
            im = compose(src)
            im.save(os.path.join(OUT, f"tree_{v}_{s}.png"))
            im.resize((256, 256), Image.LANCZOS).save(os.path.join(OUT, f"tree_{v}_{s}_256.png"))
    print("composed ->", OUT)


if __name__ == "__main__":
    main()
