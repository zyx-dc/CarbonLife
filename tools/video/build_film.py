"""
CarbonLife · 发布会风格演示片渲染器（无旁白 / 无音乐 / 静音）

设计依据（对苹果产品片的实测数据，不是二手总结）：
- 背景：视频用纯黑 #000000（#1d1d1f 是网页值，不用于视频）
- 构图：主体居中（苹果 76% 的帧主体落在画面中心 6% 内），四周留白
- 字体：行高 = 字号 + 4px；字距随字号变化（大字收紧、小字放开）
- 转场：硬切。靠切点两侧手机位置尺寸一致来"藏"切点，不做滑动/模糊
- 节奏：双峰——少量长停留承载大部分屏幕时间，其余是短切
- 一镜一意 + 揭示前留白：数字页前插 1.2 秒黑场

用法：
  python build_film.py --stills   # 只出静帧（检查排版）
  python build_film.py --sample   # 29 秒样片
  python build_film.py            # 全片
"""
import os
import subprocess
import sys
from dataclasses import dataclass
from typing import List, Optional, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ---------------------------------------------------------------- 常量

W, H = 1920, 1080
SS = 1.5                    # 静帧超采样倍率
FW, FH = int(W * SS), int(H * SS)

BG = (0, 0, 0)
INK = (245, 245, 247)
SUB = (138, 143, 135)
LIME = (182, 255, 46)       # 品牌青柠 #B6FF2E，全片唯一的"响"

FONT_PATH = r"C:\Windows\Fonts\NotoSansSC-VF.ttf"
FALLBACK_FONT = r"C:\Windows\Fonts\msyhbd.ttc"

PHONE_H = 860
PHONE_TOP = 78
CAPTION_Y = 1005

ASSETS = os.path.join(os.environ.get("TEMP", "."), "demo_assets")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")

FPS = 30


# ---------------------------------------------------------------- 字体

def load_font(size_px: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    for path in (FONT_PATH, FALLBACK_FONT):
        if not os.path.exists(path):
            continue
        try:
            f = ImageFont.truetype(path, size_px)
            if path == FONT_PATH:
                try:
                    f.set_variation_by_axes([weight])
                except Exception:
                    pass
            return f
        except Exception:
            continue
    raise RuntimeError("no usable font")


def tracking_px(size_px: int) -> float:
    """字距随字号变化：大标题收紧、小字放开（苹果的 ramp）。"""
    if size_px >= 72:
        return size_px * -0.015
    if size_px >= 34:
        return 0.0
    if size_px >= 20:
        return size_px * 0.012
    return size_px * -0.010


def line_height(size_px: int) -> int:
    """行高 = 字号 + 4px。"""
    return size_px + 4


def draw_tracked(draw, xy, text, font, fill, track, align="center"):
    widths = [font.getlength(ch) for ch in text]
    total = sum(widths) + track * max(0, len(text) - 1)
    ascent, descent = font.getmetrics()
    x = xy[0] - total / 2 if align == "center" else xy[0]
    for ch, w in zip(text, widths):
        draw.text((x, xy[1]), ch, font=font, fill=fill)
        x += w + track
    return total, ascent + descent


@dataclass
class Run:
    """一段同字号同色的文字；scale/dy 用于下标（CO₂ 的 2），不依赖字体里有 ₂。"""
    text: str
    color: tuple
    scale: float = 1.0
    dy: float = 0.0
    weight: int = 400


def measure_runs(runs: List[Run], size: int, track: float) -> float:
    total = 0.0
    for r in runs:
        f = load_font(max(1, int(size * SS * r.scale)), r.weight)
        total += sum(f.getlength(ch) for ch in r.text) + track * SS * max(0, len(r.text) - 1)
    return total


def draw_runs(canvas: Image.Image, center_x: float, center_y: float,
              runs: List[Run], size: int, track: float) -> None:
    draw = ImageDraw.Draw(canvas)
    x = center_x * SS - measure_runs(runs, size, track) / 2
    for r in runs:
        px = max(1, int(size * SS * r.scale))
        f = load_font(px, r.weight)
        ascent, descent = f.getmetrics()
        y = center_y * SS - (ascent + descent) / 2 + r.dy * size * SS
        for ch in r.text:
            draw.text((x, y), ch, font=f, fill=r.color)
            x += f.getlength(ch) + track * SS


# ---------------------------------------------------------------- 画面

def new_canvas() -> Image.Image:
    return Image.new("RGB", (FW, FH), BG)


def paste_phone(canvas: Image.Image, shot_path: str) -> None:
    """设备截图按圆角 + 极淡品牌外发光放到底板上，居中。"""
    shot = Image.open(shot_path).convert("RGB")
    sw = int(shot.width * (PHONE_H * SS) / shot.height)
    sh = int(PHONE_H * SS)
    shot = shot.resize((sw, sh), Image.LANCZOS)

    radius = int(38 * SS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius, fill=255)

    x = (FW - sw) // 2
    y = int(PHONE_TOP * SS)

    # 外发光：让设备"浮"在黑场里（苹果的 rim light 意象），不抢主体
    pad = int(46 * SS)
    glow = Image.new("RGB", (sw + pad * 2, sh + pad * 2), BG)
    sil = Image.new("RGB", (sw + pad * 2, sh + pad * 2), BG)
    ImageDraw.Draw(sil).rounded_rectangle(
        [pad, pad, pad + sw, pad + sh], radius=radius + pad // 3, fill=(28, 44, 10))
    sil = sil.filter(ImageFilter.GaussianBlur(pad * 0.65))
    canvas.paste(Image.blend(glow, sil, 0.45), (x - pad, y - pad))

    canvas.paste(shot, (x, y), mask)

    ring = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    ImageDraw.Draw(ring).rounded_rectangle(
        [0, 0, sw - 1, sh - 1], radius=radius,
        outline=(255, 255, 255, 26), width=max(1, int(1.2 * SS)))
    canvas.paste(ring, (x, y), ring)


def caption_layer(text: str) -> Image.Image:
    """说明文字单独出一层（RGBA），便于做成淡入而不带动画面。"""
    layer = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    size = 26
    f = load_font(int(size * SS), 400)
    ascent, descent = f.getmetrics()
    draw_tracked(ImageDraw.Draw(layer),
                 (FW / 2, CAPTION_Y * SS - (ascent + descent) / 2),
                 text, f, SUB + (255,), tracking_px(size) * SS)
    return layer


def brand_card(sub_runs: List[Run]) -> Image.Image:
    canvas = new_canvas()
    draw = ImageDraw.Draw(canvas)
    f1 = load_font(int(104 * SS), 700)
    a1, d1 = f1.getmetrics()
    lh1, lh2, gap = line_height(104), line_height(30), 30

    y = (FH - (lh1 + gap + lh2) * SS) / 2
    draw_tracked(draw, (FW / 2, y + (lh1 * SS - (a1 + d1)) / 2), "CarbonLife",
                 f1, INK, tracking_px(104) * SS)
    y2 = (y + (lh1 + gap) * SS + (lh2 * SS) / 2) / SS
    draw_runs(canvas, W / 2, y2, sub_runs, 30, tracking_px(30))
    return canvas


def number_card() -> Image.Image:
    canvas = new_canvas()
    f = load_font(int(300 * SS), 700)
    a, d = f.getmetrics()
    num_h = (a + d) / SS
    lh_sub = line_height(28)
    top = (H - (num_h + 40 + lh_sub)) / 2
    draw_tracked(ImageDraw.Draw(canvas), (FW / 2, top * SS), "0.51",
                 f, LIME, tracking_px(300) * SS)
    draw_runs(canvas, W / 2, top + num_h + 40 + lh_sub / 2,
              [Run("kg CO", SUB), Run("2", SUB, 0.62, 0.16), Run("e", SUB),
               Run(" · 今日减排", SUB)], 28, tracking_px(28))
    return canvas


# ---------------------------------------------------------------- 分镜

@dataclass
class Beat:
    name: str
    seconds: float
    still: str
    pan: float = 0.015
    caption: Optional[str] = None
    fade_in: float = 0.0
    fade_out: float = 0.0


def build() -> List[Beat]:
    os.makedirs(OUT, exist_ok=True)
    beats: List[Beat] = []

    def add(name: str, canvas: Image.Image, seconds: float, pan: float,
            caption: Optional[str] = None, fade_in: float = 0.0,
            fade_out: float = 0.0) -> None:
        still = os.path.join(OUT, name + ".png")
        canvas.save(still)
        if caption:
            caption_layer(caption).save(os.path.join(OUT, name + ".cap.png"))
        beats.append(Beat(name, seconds, still, pan, caption, fade_in, fade_out))

    add("b01_brand", brand_card([Run("碳足迹", LIME), Run(" · 全民绿色生活", SUB)]),
        4.5, 0.0, fade_in=0.6)

    add("b02_home", phone_shot("01-home.png"), 8.5, 0.015, "记录每一次低碳行动")
    add("b03_record", phone_shot("03-record-3km.png"), 7.5, 0.015,
        "13 种行为 · 活动量 × 排放因子")

    add("b04_black", new_canvas(), 1.2, 0.0)              # 揭示前留白

    add("b05_number", number_card(), 7.3, 0.01)
    add("b06_home_after", phone_shot("04-home-after.png"), 7.0, 0.015,
        "减排、积分、成长值同时更新")

    # 长停留：本片最重要的资产
    add("b07_report", phone_shot("05-report.png"), 9.0, 0.012,
        "碳账单 · 累计 3.91 kg · 421 积分")

    # 三连硬切：手机位置尺寸完全一致，切点几乎不可见
    add("b08_dash_day", phone_shot("06-dash-day.png"), 6.5, 0.012, "看板 · 今日")
    add("b09_dash_week", phone_shot("07-dash-week.png"), 6.5, 0.012, "看板 · 本周")
    add("b10_dash_month", phone_shot("08-dash-month.png"), 6.5, 0.012, "看板 · 本月")

    add("b11_rewards", phone_shot("09-rewards.png"), 5.5, 0.015,
        "积分 · 徽章 · 植树证书")
    add("b12_knowledge", phone_shot("10-knowledge.png"), 5.0, 0.015,
        "6 篇双碳科普 · 5 题自测")

    add("b13_end", brand_card([Run("记录每一次低碳行动", INK)]),
        6.0, 0.0, fade_in=0.6, fade_out=1.2)
    return beats


def phone_shot(asset_name: str) -> Image.Image:
    c = new_canvas()
    paste_phone(c, os.path.join(ASSETS, asset_name))
    return c


# ---------------------------------------------------------------- 编码

def render_beat(beat: Beat) -> str:
    out = os.path.join(OUT, beat.name + ".mp4")
    frames = max(1, int(round(beat.seconds * FPS)))

    if beat.pan > 0:
        zoom = f"1+{beat.pan}*on/{frames}"
        base = (f"zoompan=z='{zoom}':d=1"
                f":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS}")
    else:
        base = f"scale={W}:{H}:flags=lanczos,fps={FPS}"

    if beat.fade_in > 0:
        base += f",fade=t=in:st=0:d={beat.fade_in}"
    if beat.fade_out > 0:
        base += f",fade=t=out:st={max(0.0, beat.seconds - beat.fade_out):.3f}:d={beat.fade_out}"

    cap = os.path.join(OUT, beat.name + ".cap.png")
    cmd = ["ffmpeg", "-y", "-v", "error",
           "-framerate", str(FPS), "-loop", "1", "-i", beat.still]

    if beat.caption and os.path.exists(cap):
        # 说明文字独立成层：只淡入，不随画面推近移动
        cmd += ["-framerate", str(FPS), "-loop", "1", "-i", cap]
        fc = (f"[0:v]{base}[bg];"
              f"[1:v]scale={W}:{H}:flags=lanczos,format=rgba,"
              f"fade=t=in:st=0:d=0.45:alpha=1[cap];"
              f"[bg][cap]overlay=0:0,format=yuv420p")
        cmd += ["-filter_complex", fc]
    else:
        cmd += ["-vf", base, "-pix_fmt", "yuv420p"]

    cmd += ["-frames:v", str(frames),
            "-c:v", "libx264", "-preset", "slow", "-crf", "20",
            "-r", str(FPS), out]
    subprocess.run(cmd, check=True)
    return out


def concat(parts: List[str], out_path: str) -> None:
    lst = os.path.join(OUT, "concat.txt")
    with open(lst, "w", encoding="utf-8") as fh:
        for p in parts:
            fh.write("file '{}'\n".format(p.replace("\\", "/")))
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0",
                    "-i", lst, "-c", "copy", "-movflags", "+faststart", out_path],
                   check=True)


def main() -> None:
    args = set(sys.argv[1:])
    beats = build()
    print("stills:", len(beats), "->", OUT)
    if "--stills" in args:
        return
    if "--sample" in args:
        beats = beats[:5]

    parts = []
    for i, b in enumerate(beats, 1):
        print(f"  [{i}/{len(beats)}] {b.name} {b.seconds}s")
        parts.append(render_beat(b))

    out_name = "sample.mp4" if "--sample" in args else "CarbonLife-演示视频-真机.mp4"
    out_path = os.path.join(OUT, out_name)
    concat(parts, out_path)
    print(f"done: {out_path}  ({os.path.getsize(out_path) / 1048576:.1f} MB)")


if __name__ == "__main__":
    main()
