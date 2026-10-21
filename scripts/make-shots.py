# -*- coding: utf-8 -*-
"""Turn raw emulator screenshots into the deliverable image assets.

Why this exists: the screenshots are the asset that goes stale fastest. The 2026-10
review found the Word design doc still using 2026-09-21 UI screenshots, and the PPT
assets frozen at 2026-10-09 while eight UI commits had landed since. Re-capture after
changing the UI, then run this script so both deliverables get the same treatment.

Convention (taken from the existing ppt_tasks/carbonlife-defense/assets/*.jpg):
  raw emulator screenshot 1280x2832
    -> drop the status bar (top 137 px)
    -> scale to 1200 px wide
    => 1200x2527, ratio 0.475

Usage:
  python scripts/make-shots.py --src <dir with raw screenshots>
  # writes docs/shots/*.jpg  (used by the design doc, via the `shot:` src prefix)
  # and copies the PPT subset into ppt_tasks/carbonlife-defense/assets/

See docs/tasks/02-PPT-答辩演示-任务概述.md section 6.2 for how to capture the raw
screenshots (emulator + devecocli ui + hdc).
"""
import argparse
import os
import shutil
import sys

try:
    from PIL import Image, ImageStat
except ImportError:
    sys.exit("Pillow is required: python -m pip install Pillow")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(REPO, "docs", "shots")
ASSETS = os.path.join(REPO, "ppt_tasks", "carbonlife-defense", "assets")

STATUS_BAR_PX = 137   # status bar height in device pixels (1280-wide capture)
TARGET_WIDTH = 1200
JPEG_QUALITY = 88

# figure -> (raw screenshot stem, extra bottom crop, optional explicit crop box)
# box = (left, top, right, bottom) in device pixels and overrides the default
# "drop the status bar" crop; used for the card crops (sapling / family).
FIGURES = {
    "fig01-splash":     ("splash", 0, None),
    "fig02-home":       ("home", 0, None),
    "fig03-record":     ("record", 0, None),
    "fig04-recycle":    ("record-recycle", 0, None),
    "fig05-ai-entry":   ("record", 0, None),
    "fig06-dash-day":   ("dash-day", 0, None),
    "fig07-dash-week":  ("dash-week", 0, None),
    "fig08-dash-month": ("dash-month", 0, None),
    "fig09-rewards":    ("rewards", 0, None),
    "fig10-redeem":     ("rewards-records", 0, None),
    "fig11-family":     ("home-family", 0, None),
    "fig12-knowledge":  ("knowledge", 0, None),
    # the sapling card only: cropped out of the home page
    "fig13-sapling":    ("home", 0, (30, 1150, 1250, 1600)),
    # the report sheet only: drop the dimmed home page around the modal
    "fig14-report":     ("report", 0, (60, 392, 1220, 2320)),
    # the 本地数据管理 panel only (must be captured with the panel on screen)
    "fig15-data-manage": ("data-manager-panel", 0, (0, 1450, 1280, 2700)),
}

# Pages that must come from a light-theme capture. The dark theme follows the system
# color mode, and one capture silently came back dark, so this is verified, not assumed.
LIGHT_ONLY = {"fig01-splash"}   # the splash is a green gradient by design

# ppt asset name -> processed figure
PPT_MAP = {
    "home": "fig02-home",
    "record": "fig03-record",
    "ai": "fig04-recycle",       # slide 7 illustrates the entry card, on the 回收 list
    "dashboard": "fig07-dash-week",
    "rewards": "fig09-rewards",
    "knowledge": "fig12-knowledge",
    "family": "fig11-family",
    "report": "fig14-report",    # slide 10 shows the carbon report sheet
}


def find(src_dir, stem):
    for ext in (".png", ".jpg", ".jpeg"):
        for cand in (stem + ext, stem + "-final" + ext):
            p = os.path.join(src_dir, cand)
            if os.path.exists(p):
                return p
    return None


def theme_of(im):
    """Brightness of the page body (skips whatever top/bottom chrome the crop kept)."""
    h = im.height
    probe = im.convert("L").crop((0, h // 6, im.width, h - h // 6))
    return "LIGHT" if ImageStat.Stat(probe).mean[0] > 110 else "DARK"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="directory holding the raw screenshots")
    ap.add_argument("--allow-dark", action="store_true",
                    help="do not fail when a page that should be light came back dark")
    args = ap.parse_args()

    os.makedirs(SHOTS, exist_ok=True)
    made, missing, mismatched = {}, [], []

    for fig, (stem, bottom_crop, box) in FIGURES.items():
        src = find(args.src, stem)
        if not src:
            missing.append(f"{fig} (looked for {stem}.png/.jpg in {args.src})")
            continue
        im = Image.open(src).convert("RGB")

        if box:
            # explicit card crop, e.g. the sapling card out of the home page
            left, top, right, bottom = box
            im = im.crop((left, top, min(right, im.width), min(bottom, im.height)))
        elif stem == "splash":
            # the splash has no status bar to drop
            if bottom_crop:
                im = im.crop((0, 0, im.width, im.height - bottom_crop))
        else:
            im = im.crop((0, STATUS_BAR_PX, im.width, im.height - (bottom_crop or 0)))

        theme = theme_of(im)
        if fig not in LIGHT_ONLY and theme != "LIGHT":
            mismatched.append(f"{fig} <- {os.path.basename(src)} is {theme}")

        if im.width != TARGET_WIDTH:
            im = im.resize((TARGET_WIDTH, round(im.height * TARGET_WIDTH / im.width)), Image.LANCZOS)
        out = os.path.join(SHOTS, fig + ".jpg")
        im.save(out, "JPEG", quality=JPEG_QUALITY, optimize=True)
        made[fig] = out
        print(f"  {fig:<20} <- {os.path.basename(src):<24} {im.size[0]}x{im.size[1]:<5} "
              f"{os.path.getsize(out)//1024:>4} KB  theme={theme}")

    # de-bordered variant of the report sheet (the design doc uses this one)
    if "fig14-report" in made:
        rep = Image.open(made["fig14-report"]).convert("RGB")
        clean = os.path.join(SHOTS, "fig14-report-clean.jpg")
        rep.crop((14, 0, rep.width - 14, rep.height - 8)).save(
            clean, "JPEG", quality=JPEG_QUALITY, optimize=True)
        print(f"  {'fig14-report-clean':<20} <- fig14-report (trimmed 14px sides / 8px bottom)")

    if missing:
        print("\nMISSING source screenshots:")
        for m in missing:
            print("  -", m)
    if mismatched:
        print("\nTHEME MISMATCH (a light page came from a dark capture):")
        for m in mismatched:
            print("  -", m)

    if missing or (mismatched and not args.allow_dark):
        print("\nNothing copied to the PPT assets. Fix the sources first.")
        return 1

    print("\n  -> ppt_tasks/carbonlife-defense/assets/")
    for asset, fig in PPT_MAP.items():
        if fig not in made:
            continue
        dst = os.path.join(ASSETS, asset + ".jpg")
        shutil.copyfile(made[fig], dst)
        print(f"     {asset + '.jpg':<16} <- {fig}.jpg")
    return 0

if __name__ == "__main__":
    sys.exit(main())
