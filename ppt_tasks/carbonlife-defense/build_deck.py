# -*- coding: utf-8 -*-
"""CarbonLife 答辩 PPT — Build Mode (pptx-designer public API)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from pptx_designer import Presentation, set_slide_theme
from pptx_designer.renderer.theme import ThemeComposer, validate_resolved_theme
from pptx_designer.tools.shapes import rect, rrect, oval, arrow
from pptx_designer.tools.text import text, multiline, gradient_text
from pptx.util import Inches

from pptx_designer.tools.images import cover_image

TASK = Path(__file__).resolve().parent
CARBON = TASK.parents[1]
OUT = TASK / "output"
OUT.mkdir(parents=True, exist_ok=True)
PPTX = OUT / "CarbonLife-答辩PPT.pptx"

ASSETS = TASK / "assets"

# 截图素材：assets/ 内为当前 UI 的高分截图（1200px 宽，已裁系统状态栏）
IMG = {
    "home": str(ASSETS / "home.jpg"),
    "record": str(ASSETS / "record.jpg"),
    "dashboard": str(ASSETS / "dashboard.jpg"),
    "rewards": str(ASSETS / "rewards.jpg"),
    "knowledge": str(ASSETS / "knowledge.jpg"),
    "splash": str(CARBON / "screen3.jpeg"),
    # 端侧 AI 识图：记录页 AI 卡片（模拟器实机截图，浅色，已裁系统状态栏）
    "ai": str(ASSETS / "ai.jpg"),
    # 家庭碳积分：由实机首页截图裁切优化（去状态栏 / 截断行 / Tab 栏）
    "family": str(ASSETS / "family.jpg"),
}

FONT = "Microsoft YaHei"
TINT = "#EAEFE7"   # 浅色底纹（比 muted role 更浅、对比更好）

DARK = {
    "colors": {
        "primary": "#B6FF2E", "on-primary": "#0A0F07", "secondary": "#7FCB00",
        "accent": "#3DE0C8", "background": "#0A0A0A", "foreground": "#E9F7E0",
        "card": "#141A14", "muted": "#1B241B", "muted-foreground": "#82917B",
        "border": "#2E3A2E", "destructive": "#FF5C5C",
    },
    "roles": {
        "background": "#0A0A0A", "surface": "#141A14", "ink": "#E9F7E0", "muted": "#82917B",
        "accent": "#3DE0C8", "accent-secondary": "#7FCB00", "success": "#B6FF2E",
        "warning": "#FFB300", "danger": "#FF5C5C", "border": "#2E3A2E",
        "data-series-1": "#B6FF2E", "data-series-2": "#3DE0C8",
    },
}
LIGHT = {
    "colors": {
        "primary": "#0F3D2E", "on-primary": "#FFFFFF", "secondary": "#2F6B4F",
        "accent": "#E8A317", "background": "#F5F7F5", "foreground": "#14201A",
        "card": "#FFFFFF", "muted": "#EAEFE7", "muted-foreground": "#6A7562",
        "border": "#DCE4D8", "destructive": "#D64545",
    },
    "roles": {
        "background": "#F5F7F5", "surface": "#FFFFFF", "ink": "#14201A", "muted": "#6A7562",
        "accent": "#E8A317", "accent-secondary": "#2F6B4F", "success": "#3E8E1E",
        "warning": "#E8A317", "danger": "#D64545", "border": "#DCE4D8",
        "data-series-1": "#0F3D2E", "data-series-2": "#2E8B57",
    },
}


def make_theme(spec, style, seed, name):
    t = ThemeComposer().compose(style=style, seed=seed)
    t["name"] = name
    t["colors"] = dict(spec["colors"])
    t["semantic_roles"] = dict(spec["roles"])
    t["typography"] = {"heading": FONT, "body": FONT, "cjk_fallback": FONT, "mono": "Consolas"}
    validate_resolved_theme(t)
    return t


THEME_DARK = make_theme(DARK, "dark-mode-oled", 17, "carbonlife-night-neon")
THEME_LIGHT = make_theme(LIGHT, "minimalism-swiss-style", 11, "carbonlife-day-paper")

W, H = 13.333, 7.5
M = 0.7
CW = W - 2 * M
NOTES: dict[int, str] = {}


def est_w(s, size=12):
    u = sum(0.105 if ord(c) < 128 else 0.20 for c in s)
    return u * (size / 12.0) + 0.34


def new_slide(prs, dark=False):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    if dark:
        set_slide_theme(s, THEME_DARK)
    rect(s, 0, 0, W, H, "background")
    return s


def header(s, eyebrow, title, kicker=""):
    text(s, M, 0.46, CW, 0.3, eyebrow, font_size=11, color="text_muted", bold=True)
    text(s, M, 0.74, CW, 0.62, title, font_size=29, color="primary", bold=True)
    rect(s, M, 1.5, 0.95, 0.055, "primary")
    if kicker:
        text(s, M + 1.15, 1.39, CW - 1.15, 0.3, kicker, font_size=13, color="text_muted")


def footer(s, n):
    text(s, M, 7.05, 7.0, 0.3, "CarbonLife 碳足迹 · 参赛答辩", font_size=10, color="text_muted")
    text(s, W - M - 1.4, 7.05, 1.4, 0.3, f"{n:02d} / 15", font_size=10, color="text_muted", align="right")


def card(s, x, y, w, h, accent=None, fill="card", line="border"):
    rrect(s, x, y, w, h, fill, line=line)
    if accent:
        rect(s, x, y, w, 0.06, accent)


def band(s, x, y, w, h, txt, size=16):
    rrect(s, x, y, w, h, TINT, line="border")
    text(s, x + 0.35, y + (h - 0.45) / 2, w - 0.7, 0.45, txt, font_size=size, color="text_dark", bold=True)


def phone(s, x, y, box_w, box_h, path, ring="border", pad=0.16, panel=True):
    """Place a screenshot: contain-fit inside box (never stretched/cropped)."""
    with Image.open(path) as im:
        iw, ih = im.size
    r = iw / ih
    w = box_w
    h = w / r
    if h > box_h:
        h = box_h
        w = h * r
    cx = x + (box_w - w) / 2
    cy = y + (box_h - h) / 2
    if panel:
        rrect(s, cx - pad, cy - pad, w + 2 * pad, h + 2 * pad, "card", line=ring)
    # 直接嵌入原图：上面的 contain-fit 框与原图同比例，无需裁剪/重编码
    # （cover_image 会把图重新编码为 PNG，导致 PPTX 体积成倍膨胀）
    s.shapes.add_picture(path, Inches(cx), Inches(cy), Inches(w), Inches(h))
    return w, h


def point_rows(s, x, y, w, rows, gap=1.5, size=18):
    for i, (t, d) in enumerate(rows):
        yy = y + i * gap
        oval(s, x, yy + 0.02, 0.5, 0.5, "primary" if i % 2 == 0 else "accent")
        text(s, x, yy + 0.08, 0.5, 0.4, f"{i + 1:02d}", font_size=14, color="on_primary", bold=True, align="center")
        text(s, x + 0.7, yy - 0.02, w - 0.7, 0.4, t, font_size=size, color="primary", bold=True)
        text(s, x + 0.7, yy + 0.42, w - 0.7, 0.4, d, font_size=14, color="text_muted")


def chip(s, x, y, label, size=12):
    w = est_w(label, size)
    rrect(s, x, y, w, 0.42, "card", line="border")
    text(s, x, y + 0.05, w, 0.32, label, font_size=size, color="text_dark", align="center")
    return w


# ════════════════════════════════════════════════════════════════════
prs = Presentation(theme=THEME_LIGHT, strict_theme=True)

# ── P1 封面 (dark) ──────────────────────────────────────────────────
s = new_slide(prs)
rect(s, 0, 0, 0.16, H, "primary")
text(s, 0.95, 1.15, 7.0, 0.3, "CARBONLIFE · 碳足迹", font_size=12, color="accent", bold=True)
gradient_text(s, 0.9, 1.55, 6.6, 1.15, "CarbonLife",
              stops=[("#0F3D2E", 0), ("#2F6B4F", 55), ("#0E8F79", 100)], font_size=58, bold=True)
text(s, 0.95, 2.72, 6.4, 0.5, "碳足迹 · 全民绿色生活", font_size=22, color="primary", bold=True)
text(s, 0.95, 3.35, 6.4, 0.4, "基于 HarmonyOS 的低碳生活记录与激励应用", font_size=15, color="text_muted")
cx = 0.95
for label in ["双碳目标", "HarmonyOS 原生", "端侧 AI", "隐私优先", "家庭共享"]:
    cx += chip(s, cx, 4.15, label) + 0.18
rect(s, 0.95, 5.05, 4.2, 0.02, "border")
text(s, 0.95, 5.25, 6.4, 0.35, "参赛作品 · 答辩演示", font_size=13, color="accent", bold=True)
text(s, 0.95, 5.62, 6.4, 0.35, "记录每一次低碳行动，积少成多守护地球", font_size=12, color="text_muted")
phone(s, 7.3, 1.5, 5.4, 5.4, IMG["home"], ring="border")
footer(s, 1)
NOTES[1] = "各位评委好，我们的作品是 CarbonLife 碳足迹，一款基于 HarmonyOS 的低碳生活记录与激励应用。"

# ── P2 痛点与选题 ───────────────────────────────────────────────────
s = new_slide(prs)
header(s, "BACKGROUND", "为什么做 CarbonLife？", "国家「双碳」目标：2030 碳达峰 · 2060 碳中和")
pains = [("难记录", "低碳行为零散，缺少统一、低门槛的记录入口。"),
         ("没反馈", "减排量不可见，一次绿色行动得不到即时反馈。"),
         ("难坚持", "缺少激励与家人互动，好习惯难以长期坚持。")]
cw = (CW - 2 * 0.3) / 3
for i, (t, d) in enumerate(pains):
    x = M + i * (cw + 0.3)
    card(s, x, 1.95, cw, 2.55, accent=["primary", "accent", "primary"][i])
    text(s, x + 0.3, 2.3, cw - 0.6, 0.5, t, font_size=22, color="primary", bold=True)
    multiline(s, x + 0.3, 3.0, cw - 0.6, 1.3, [d], font_size=15, color="text_muted")
band(s, M, 4.85, CW, 1.05, "另一个现实问题：用户对生活数据的隐私有顾虑。")
text(s, M + 0.35, 5.5, CW - 0.7, 0.3, "这决定了我们坚持「数据默认留在本机，云备份由用户自主开关」。", font_size=13, color="text_muted")
footer(s, 2)
NOTES[2] = "在双碳目标背景下，日常低碳行为普遍「难记录、没反馈、难坚持」，同时用户对生活数据隐私有顾虑。"

# ── P3 我们做了什么 ─────────────────────────────────────────────────
s = new_slide(prs)
header(s, "SOLUTION", "把一次低碳行动，变成一次可量化的减排")
steps = [("01", "记录", "出行 / 节能 / 回收 / 餐饮，共 13 种低碳行为"),
         ("02", "计算", "活动量 × 排放因子 → 减排量(kg CO₂e) → 碳积分"),
         ("03", "激励", "积分兑换 · 徽章 · 植树证书 · 家庭碳积分")]
cw = (CW - 2 * 0.85) / 3
for i, (n, t, d) in enumerate(steps):
    x = M + i * (cw + 0.85)
    card(s, x, 2.15, cw, 3.0, accent="primary" if i == 0 else "accent")
    oval(s, x + 0.32, 2.55, 0.95, 0.95, "primary" if i == 0 else "accent")
    text(s, x + 0.32, 2.72, 0.95, 0.6, n, font_size=26, color="on_primary", bold=True, align="center")
    text(s, x + 0.32, 3.75, cw - 0.64, 0.5, t, font_size=22, color="primary", bold=True)
    multiline(s, x + 0.32, 4.35, cw - 0.64, 0.9, [d], font_size=14, color="text_muted")
    if i < 2:
        arrow(s, x + cw + 0.16, 3.35, 0.52, 0.55, "accent")
text(s, M, 5.6, CW, 0.4, "一次记录 = 一次可见的减排，且可在家庭内共享。", font_size=15, color="text_muted")
footer(s, 3)
NOTES[3] = "我们做了一件事：记录低碳行为，自动算出减排量与碳积分，再用激励和家庭共享让它可持续。"

# ── P4 目标用户 ─────────────────────────────────────────────────────
s = new_slide(prs)
header(s, "AUDIENCE", "谁会用它？")
users = [("家庭用户", "与家人一起记录低碳行为，共享家庭碳积分。"),
         ("学生", "把校园里的低碳实践变成可见的减排与习惯。"),
         ("通勤上班族", "用步行 / 骑行 / 公交替代驾车，积累减排与积分。")]
cw = (CW - 2 * 0.3) / 3
for i, (t, d) in enumerate(users):
    x = M + i * (cw + 0.3)
    card(s, x, 2.1, cw, 2.8, accent=["primary", "accent", "primary"][i])
    oval(s, x + 0.3, 2.5, 0.9, 0.9, TINT, line="border")
    text(s, x + 0.3, 2.72, 0.9, 0.5, ["家", "学", "勤"][i], font_size=20, color="primary", bold=True, align="center")
    text(s, x + 0.3, 3.65, cw - 0.6, 0.5, t, font_size=20, color="primary", bold=True)
    multiline(s, x + 0.3, 4.2, cw - 0.6, 0.7, [d], font_size=14, color="text_muted")
band(s, M, 5.25, CW, 0.95, "家庭碳积分让「一起减排」变得可见、可坚持。")
footer(s, 4)
NOTES[4] = "面向关注环保与健康的家庭用户、学生与通勤上班族，以及希望与家人共同参与的用户。"

# ── P5 功能总览 ─────────────────────────────────────────────────────
s = new_slide(prs)
header(s, "OVERVIEW", "8 大功能，覆盖记录—计算—激励的完整闭环")
feats = [("01", "低碳行为记录", "13 种行为自动折算"), ("02", "端侧 AI 识图", "选图推荐低碳行为"),
         ("03", "数据看板与导出", "趋势图表 + 导入导出"), ("04", "积分与荣誉", "兑换 · 徽章 · 植树 · 任务"),
         ("05", "家庭碳积分", "家庭码聚合多设备"), ("06", "每日提醒", "默认 20:00 提醒记录"),
         ("07", "双碳科普", "碳达峰 / 碳中和专栏"), ("08", "浅色 · 深色主题", "跟随系统实时切换")]
cw = (CW - 3 * 0.28) / 4
ch = 1.5
for i, (n, t, d) in enumerate(feats):
    x = M + (i % 4) * (cw + 0.28)
    y = 1.9 + (i // 4) * (ch + 0.3)
    card(s, x, y, cw, ch, accent="primary" if i % 2 == 0 else "accent")
    text(s, x + 0.25, y + 0.26, cw - 0.5, 0.3, n, font_size=13, color="accent", bold=True)
    text(s, x + 0.25, y + 0.58, cw - 0.5, 0.4, t, font_size=16, color="primary", bold=True)
    text(s, x + 0.25, y + 1.02, cw - 0.5, 0.35, d, font_size=12, color="text_muted")
band(s, M, 5.35, CW, 0.95, "记录 → 计算 → 激励，形成可持续的低碳闭环。")
footer(s, 5)
NOTES[5] = "项目包含低碳行为记录、端侧 AI 识图、数据看板与导入导出、积分与荣誉、家庭碳积分、每日提醒、双碳科普、深浅主题八大功能；数据还支持本地整包备份与可选的云备份。"

# ── P6 亮点1 ────────────────────────────────────────────────────────
s = new_slide(prs)
header(s, "HIGHLIGHT 01", "13 种低碳行为，四大类自动折算")
cats = [("出行", "步行 / 骑行 / 公交 …"), ("节能", "节电 / 节水 …"),
        ("回收", "纸张 / 塑料 / 旧物 …"), ("餐饮", "光盘行动 …")]
cw = (7.0 - 0.28) / 2
for i, (t, d) in enumerate(cats):
    x = M + (i % 2) * (cw + 0.28)
    y = 1.95 + (i // 2) * (1.3 + 0.22)
    card(s, x, y, cw, 1.3, accent="primary" if i % 2 == 0 else "accent")
    text(s, x + 0.25, y + 0.2, cw - 0.5, 0.4, t, font_size=18, color="primary", bold=True)
    text(s, x + 0.25, y + 0.68, cw - 0.5, 0.4, d, font_size=12, color="text_muted")
band(s, M, 5.05, 7.0, 0.95, "减排量 = 活动量 × 排放因子  →  自动结算碳积分")
phone(s, 8.15, 1.95, 4.5, 4.6, IMG["record"])
footer(s, 6)
NOTES[6] = "出行、节能、回收、餐饮四大类共 13 种行为，按「活动量 × 排放因子」自动估算减排量与积分。"

# ── 亮点页 7–10 ─────────────────────────────────────────────────────
def highlight_page(n, eyebrow, title, rows, img, note):
    s = new_slide(prs)
    header(s, eyebrow, title)
    card(s, M, 1.95, 7.0, 4.6, accent="primary")
    point_rows(s, M + 0.4, 2.35, 6.2, rows, gap=1.5)
    phone(s, 8.15, 1.95, 4.5, 4.6, img)
    footer(s, n)
    NOTES[n] = note


highlight_page(7, "HIGHLIGHT 02", "选一张照片，自动推荐低碳行为",
    [("端侧识别", "基于 CoreVisionKit，在本机完成物体检测"),
     ("自动映射", "识别结果推荐对应的低碳行为，省去手填"),
     ("隐私友好", "图片全程在本机处理，不上传云端")],
    IMG["ai"],
    "用户选一张照片，设备侧识别物体并推荐对应低碳行为，图片不出本机。")

highlight_page(8, "HIGHLIGHT 03", "日 / 周 / 月 / 年，把减排趋势看清楚",
    [("多周期趋势", "日 / 周 / 月 / 年切换，汇总口径一致"),
     ("多视图", "折线 / 柱状 / 饼图呈现类别占比"),
     ("导入导出", "CSV / JSON 互导（UTF-8 BOM，Excel 不乱码）")],
    IMG["dashboard"],
    "提供日 / 周 / 月 / 年趋势，折线、柱状、饼图多种呈现；支持 CSV / JSON 导入与导出，导入时逐字段校验归一化。")

highlight_page(9, "HIGHLIGHT 04", "一个家庭码，把家人的减排聚在一起",
    [("家庭码", "生成 / 加入即可建立家庭组"),
     ("自动聚合", "同账号多设备按成员展示减排与积分"),
     ("不经第三方", "数据仅在本人设备间同步")],
    IMG["family"],
    "生成或加入家庭码后，可在同一华为账号的多设备间同步，并按成员展示家庭减排与积分。")

highlight_page(10, "HIGHLIGHT 05", "减排有回馈：积分 · 徽章 · 植树",
    [("积分", "累计并兑换碳普惠权益"),
     ("荣誉", "解锁低碳徽章与植树证书"),
     ("任务", "今日任务完成后自动发放积分")],
    IMG["rewards"],
    "碳积分可兑换权益、解锁徽章与植树证书，今日任务完成后自动发放积分。")

# ── P11 设计与体验 ──────────────────────────────────────────────────
s = new_slide(prs)
header(s, "DESIGN", "让低碳数据「好看、好读」")
card(s, M, 1.95, 7.0, 4.6, accent="primary")
point_rows(s, M + 0.4, 2.35, 6.2,
           [("视觉基调", "暖白纸感底，深林绿为品牌、琥珀金为强调"),
            ("统一的系统", "玻璃质感卡片 + 单一信号色，层次靠字号与留白"),
            ("跟随系统", "主题随系统深浅色切换，运行中实时生效"),
            ("有目的的动效", "读数滚动 / 图表入场，支持「减弱动效」开关")], gap=1.15)
phone(s, 7.75, 1.95, 2.35, 4.6, IMG["home"])
phone(s, 10.35, 1.95, 2.35, 4.6, IMG["knowledge"])
text(s, 7.75, 6.62, 2.35, 0.3, "首页", font_size=11, color="text_muted", align="center")
text(s, 10.35, 6.62, 2.35, 0.3, "双碳科普", font_size=11, color="text_muted", align="center")
footer(s, 11)
NOTES[11] = "整体采用可跟随系统的浅 / 深双主题，颜色与控件统一走设计规范，关键动效尊重「减弱动效」开关。"

# ── P12 技术底座 ────────────────────────────────────────────────────
s = new_slide(prs)
header(s, "TECH", "基于 HarmonyOS 的原生实现")
layers = [("应用层", "ArkUI 声明式 UI · 5 Tab（首页 / 记录 / 看板 / 积分 / 科普）", "primary"),
          ("数据与服务层", "CarbonStore · CarbonFactors · Family / Mall / Reminder / Vision · Backup", "accent"),
          ("系统 Kit 层", "ArkData · CoreVisionKit · BackgroundTasksKit · MediaLibrary / ImageKit · CoreFileKit · AbilityKit", "primary")]
for i, (t, d, a) in enumerate(layers):
    y = 1.95 + i * (1.28 + 0.2)
    rrect(s, M, y, 7.0, 1.28, "card", line="border")
    rect(s, M, y, 0.06, 1.28, a)
    text(s, M + 0.3, y + 0.2, 6.5, 0.4, t, font_size=17, color="primary", bold=True)
    text(s, M + 0.3, y + 0.68, 6.5, 0.45, d, font_size=12, color="text_muted")
card(s, 8.15, 1.95, 4.48, 4.6, accent="accent")
text(s, 8.45, 2.2, 3.9, 0.4, "技术栈", font_size=17, color="primary", bold=True)
multiline(s, 8.45, 2.75, 3.9, 3.5,
          ["· 语言：ArkTS", "· UI：ArkUI（声明式）", "· 模型：Stage 模型",
           "· SDK：compatibleSdkVersion 26.0.0", "· 设备：phone / tablet",
           "· 存储：Preferences 本地持久化", "· 同步：DistributedDataObject",
           "· 备份：AGC 云存储（可开关）"],
          font_size=13, color="text_dark", line_spacing=7)
footer(s, 12)
NOTES[12] = "基于 HarmonyOS / OpenHarmony 原生开发，使用 ArkTS 与 ArkUI 声明式 UI，Stage 模型、SDK 26.0.0；本机存储、端侧 AI、分布式数据、后台提醒，以及可开关的 AGC 云备份。"

# ── P13 隐私与安全 ──────────────────────────────────────────────────
s = new_slide(prs)
header(s, "PRIVACY", "数据留在本机，隐私优先")
priv = [("默认仅存本机", "记录默认保存在本机 Preferences；云备份为独立开关，默认关闭。"),
        ("家庭同步不经第三方", "家庭碳积分仅在本人同账号设备间同步，不经过第三方服务器。"),
        ("识图不出本机", "端侧 AI 识图在本机完成，图片不上传。")]
cw = (CW - 2 * 0.3) / 3
for i, (t, d) in enumerate(priv):
    x = M + i * (cw + 0.3)
    card(s, x, 2.05, cw, 2.9, accent=["primary", "accent", "primary"][i])
    oval(s, x + 0.3, 2.45, 0.85, 0.85, TINT, line="border")
    text(s, x + 0.3, 2.63, 0.85, 0.5, ["本", "家", "AI"][i], font_size=18, color="primary", bold=True, align="center")
    text(s, x + 0.3, 3.6, cw - 0.6, 0.5, t, font_size=17, color="primary", bold=True)
    multiline(s, x + 0.3, 4.15, cw - 0.6, 0.75, [d], font_size=13, color="text_muted")
band(s, M, 5.35, CW, 0.85, "隐私不是附加项，而是产品设计的起点。")
footer(s, 13)
NOTES[13] = "记录默认只存本机（Preferences），云备份是可选的独立开关、默认关闭；家庭数据只在同一账号设备间同步，不经过第三方；识图在本机完成。"

# ── P14 验证与质量 ──────────────────────────────────────────────────
s = new_slide(prs)
header(s, "QA", "每一步都有验收：写审分离 + 设备验证")
card(s, M, 1.95, 5.4, 4.6, accent="primary")
text(s, M + 0.3, 2.2, 4.8, 0.4, "只读的设备验证流程", font_size=17, color="primary", bold=True)
multiline(s, M + 0.3, 2.8, 4.8, 3.4,
          ["· 写代码与审查分离，避免自证", "· 设备验证 Agent 在模拟器上构建、安装、截图",
           "· 逐条核对验收清单并输出证据", "· 依据验收清单与复测记录归档"],
          font_size=14, color="text_dark", line_spacing=9)
card(s, 6.35, 1.95, 6.28, 4.6, accent="accent")
text(s, 6.65, 2.2, 5.7, 0.4, "复测结果", font_size=17, color="primary", bold=True)
rrect(s, 6.65, 2.75, 5.65, 1.5, TINT, line="border")
text(s, 6.85, 2.9, 5.3, 0.35, "✓ 已通过", font_size=14, color="success", bold=True)
multiline(s, 6.85, 3.3, 5.3, 0.9, ["记录增删实时刷新 · 图表刷新 · 家庭聚合（本地侧） · UI 冒烟 20/20（手机 + 平板）"], font_size=13, color="text_dark")
rrect(s, 6.65, 4.5, 5.65, 1.5, TINT, line="border")
text(s, 6.85, 4.65, 5.3, 0.35, "! 待真机复测", font_size=14, color="accent", bold=True)
multiline(s, 6.85, 5.05, 5.3, 0.9, ["分布式权限弹窗 · 跨设备家庭聚合"], font_size=13, color="text_dark")
footer(s, 14)
NOTES[14] = "项目采用「写审分离 + 设备验证」，在模拟器上逐条核对验收清单；记录刷新、图表刷新、家庭聚合（本地侧）与设备端 UI 冒烟 20/20 已通过，分布式权限弹窗与跨设备家庭聚合仍需真机复测。"

# ── P15 展望与致谢 (dark) ───────────────────────────────────────────
s = new_slide(prs)
rect(s, 0, 0, 0.16, H, "primary")
text(s, M, 0.7, 6, 0.4, "ROADMAP", font_size=12, color="accent", bold=True)
text(s, M, 1.05, 7, 0.7, "接下来", font_size=30, color="primary", bold=True)
road = ["· 对接真实城市碳普惠平台 API，替代本地模拟兑换码",
        "· 云备份冲突合并策略与签名构建端到端验证",
        "· 接入系统无障碍设置，真正启用「减弱动效」",
        "· 平板其余页面补齐多列布局"]
multiline(s, M, 2.0, 7.2, 3.4, road, font_size=16, color="text_dark", line_spacing=11)
gradient_text(s, 8.0, 2.2, 4.6, 1.6, "谢谢", stops=[("#0F3D2E", 0), ("#2F6B4F", 60), ("#0E8F79", 100)], font_size=72, bold=True)
text(s, 8.05, 4.0, 4.6, 0.4, "记录每一次低碳行动", font_size=14, color="text_muted")
text(s, 8.05, 4.35, 4.6, 0.4, "积少成多守护地球", font_size=14, color="text_muted")
rect(s, M, 5.65, 11.93, 0.02, "border")
text(s, M, 5.85, 8, 0.4, "CarbonLife 碳足迹 · 基于 HarmonyOS 的低碳生活应用", font_size=13, color="primary", bold=True)
footer(s, 15)
NOTES[15] = "后续计划对接真实碳普惠平台、完成云备份冲突合并与签名构建验证、接入系统无障碍与补齐平板多列布局。谢谢观看。"

for i, slide in enumerate(prs.slides, start=1):
    if i in NOTES:
        slide.notes_slide.notes_text_frame.text = NOTES[i]

cp = prs.core_properties
cp.title = "CarbonLife 碳足迹 · 答辩PPT"
cp.author = ""
cp.last_modified_by = ""
cp.comments = ""

prs.save(str(PPTX))
print("SAVED", PPTX)
print("slides", len(prs.slides._sldIdLst))
