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

# figure -> (raw screenshot basename, extra bottom crop in device px)
# "--" means the splash: no status bar to drop, keep the full frame.
FIGURES = {
    "fig01-splash":     ("splash", 0),
    "fig02-home":       ("home-light", 0),
    "fig03-record":     ("record", 0),
    "fig04-recycle":    ("record-recycle", 0),
    "fig05-ai-entry":   ("record", 0),
    "fig06-dash-day":   ("dash-day", 0),
    "fig07-dash-week":  ("dash-week", 0),
    "fig08-dash-month": ("dash-month", 0),
    "fig09-rewards":    ("rewards", 0),
    "fig10-redeem":     ("rewards-records", 0),
    "fig11-family":     ("home-family", 132),   # also drop the bottom tab bar
    "fig12-knowledge":  ("knowledge", 0),
    "fig13-home-dark":  ("home-dark", 0),
    "fig14-local-data": ("data-manager", 0),
}

# Pages that must come from a light-theme capture. The dark theme follows the system
# color mode, and one capture silently came back dark, so this is verified, not assumed.
LIGHT_ONLY = {"fig01-splash", "fig13-home-dark"}   # these two are expected dark/green

# ppt asset name -> processed figure
PPT_MAP = {
    "home": "fig02-home",
    "record": "fig03-record",
    "ai": "fig04-recycle",       # slide 7 illustrates the entry card, on the 回收 list
    "dashboard": "fig07-dash-week",
    "rewards": "fig09-rewards",
    "knowledge": "fig12-knowledge",
    "family": "fig11-family",
}


def find(src_dir, stem):
    for ext in (".png", ".jpg", ".jpeg"):
        for cand in (stem + ext, stem + "-final" + ext):
            p = os.path.join(src_dir, cand)
            if os.path.exists(p):
                return p
    return None


def theme_of(im):
    probe = im.convert("L").crop((0, 400, im.width, min(2000, im.height)))
    return "LIGHT" if ImageStat.Stat(probe).mean[0] > 110 else "DARK"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="directory holding the raw screenshots")
    ap.add_argument("--allow-dark", action="store_true",
                    help="do not fail when a page that should be light came back dark")
    args = ap.parse_args()

    os.makedirs(SHOTS, exist_ok=True)
    made, missing, mismatched = {}, [], []

    for fig, (stem, bottom_crop) in FIGURES.items():
        src = find(args.src, stem)
        if not src:
            missing.append(f"{fig} (looked for {stem}.png/.jpg in {args.src})")
            continue
        im = Image.open(src).convert("RGB")
        if stem != "splash":
            im = im.crop((0, STATUS_BAR_PX, im.width, im.height - (bottom_crop or 0)))
        elif bottom_crop:
            im = im.crop((0, 0, im.width, im.height - bottom_crop))

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
