from pathlib import Path
from PIL import Image

TASK = Path(__file__).resolve().parent
R = TASK / "output" / "rendered"
imgs = [R / f"slide{i:02d}.png" for i in range(1, 16)]
cols, rows, tw, pad = 5, 3, 460, 12
th = int(tw * 720 / 1280)
sheet = Image.new("RGB", (cols * tw + (cols + 1) * pad, rows * th + (rows + 1) * pad), "#0A0A0A")
for i, p in enumerate(imgs):
    im = Image.open(p).convert("RGB").resize((tw, th))
    c, r = i % cols, i // cols
    sheet.paste(im, (pad + c * (tw + pad), pad + r * (th + pad)))
out = TASK / "output" / "contact_sheet.png"
sheet.save(out)
print("SAVED", out, sheet.size)
