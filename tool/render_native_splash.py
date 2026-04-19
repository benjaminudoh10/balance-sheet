#!/usr/bin/env python3
"""Generate flutter_native_splash source PNGs using the same assets as the launcher icon.

- Book: Material Icons `menu_book_rounded` (U+F8B4) from Flutter's MaterialIcons-Regular.otf
- Copy: matches lib/screens/splash.dart — row of icon + \"Balanced\", then \"...know where your money goes\"
- Typography: Roboto from Flutter SDK (close to in-app Material / Google Fonts)

Requires: pip3 install pillow
Uses: FLUTTER_ROOT (default ~/flutter)

  python3 tool/render_native_splash.py
  dart run flutter_native_splash:create

Keep colors in sync with lib/theme/app_palette.dart.
"""
from __future__ import annotations

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Install Pillow: pip3 install pillow", file=sys.stderr)
    sys.exit(1)

# --- AppPalette (light / dark) — sync with lib/theme/app_palette.dart ---
PALETTE = {
    "light": {
        "bg": (0xF5, 0xF3, 0xFA, 0xFF),
        "mint": (0x0D, 0x8F, 0x72, 0xFF),
        "text_primary": (0x1A, 0x14, 0x28, 0xFF),
        "text_secondary": (0x5E, 0x56, 0x72, 0xFF),
    },
    "dark": {
        "bg": (0x0D, 0x11, 0x17, 0xFF),
        "mint": (0x3E, 0xE6, 0xB5, 0xFF),
        "text_primary": (0xF0, 0xF6, 0xFC, 0xFF),
        "text_secondary": (0x8B, 0x94, 0x9E, 0xFF),
    },
}

_CODEPOINT_BOOK = 0xF8B4
_TITLE = "Balanced"
_TAGLINE = "...know where your money goes"


def _fonts(flutter_root: str) -> tuple[str, str, str]:
    art = os.path.join(flutter_root, "bin", "cache", "artifacts", "material_fonts")
    material = os.path.join(art, "MaterialIcons-Regular.otf")
    roboto_med = os.path.join(art, "Roboto-Medium.ttf")
    roboto_reg = os.path.join(art, "Roboto-Regular.ttf")
    if not os.path.isfile(material):
        sys.exit(f"Missing font: {material}")
    if not os.path.isfile(roboto_med):
        sys.exit(f"Missing font: {roboto_med}")
    if not os.path.isfile(roboto_reg):
        sys.exit(f"Missing font: {roboto_reg}")
    return material, roboto_med, roboto_reg


def _text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def render_android12(path: str, *, light: bool, material: str, w: int, h: int) -> None:
    """Centered book glyph only (transparent). Used as Android 12 splash middle image."""
    c = PALETTE["light" if light else "dark"]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Scale icon to ~42% of canvas height (similar visual weight to previous asset)
    target_h = int(h * 0.42)
    fs = target_h
    for _ in range(40):
        font = ImageFont.truetype(material, fs)
        tw, th = _text_size(draw, chr(_CODEPOINT_BOOK), font)
        if th <= target_h and tw <= int(w * 0.72):
            break
        fs -= 2
    else:
        font = ImageFont.truetype(material, max(24, fs))
    ch = chr(_CODEPOINT_BOOK)
    tw, th = _text_size(draw, ch, font)
    x = (w - tw) // 2
    y = (h - th) // 2
    draw.text((x, y), ch, font=font, fill=c["mint"])
    img.save(path)


def render_full(path: str, *, light: bool, material: str, roboto_med: str, roboto_reg: str) -> None:
    """Wide banner: icon + title row, tagline below — matches in-app horizontal lockup; iOS / legacy Android."""
    c = PALETTE["light" if light else "dark"]
    canvas_w, canvas_h = 1600, 480
    img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    icon_target_h = 200
    fs_icon = icon_target_h
    font_icon = ImageFont.truetype(material, fs_icon)
    ch = chr(_CODEPOINT_BOOK)
    for _ in range(60):
        tw, th = _text_size(draw, ch, font_icon)
        if th <= icon_target_h:
            break
        fs_icon -= 2
        font_icon = ImageFont.truetype(material, fs_icon)
    tw, th = _text_size(draw, ch, font_icon)

    title_size = 52
    sub_size = 24
    font_title = ImageFont.truetype(roboto_med, title_size)
    font_sub = ImageFont.truetype(roboto_reg, sub_size)

    title_w, title_h = _text_size(draw, _TITLE, font_title)
    sub_w, sub_h = _text_size(draw, _TAGLINE, font_sub)
    text_gap = 12
    text_block_h = title_h + text_gap + sub_h

    icon_x = 220
    # Vertically center icon with the stacked title + tagline
    block_top = (canvas_h - max(th, text_block_h)) // 2
    icon_y = block_top + (max(th, text_block_h) - th) // 2
    draw.text((icon_x, icon_y), ch, font=font_icon, fill=c["mint"])

    text_left = icon_x + tw + 40
    title_y = block_top + (max(th, text_block_h) - text_block_h) // 2
    draw.text((text_left, title_y), _TITLE, font=font_title, fill=c["text_primary"])
    draw.text((text_left, title_y + title_h + text_gap), _TAGLINE, font=font_sub, fill=c["text_secondary"])

    img.save(path)


def render_branding(path: str, *, light: bool, material: str, roboto_med: str, roboto_reg: str) -> None:
    """Bottom branding strip: icon + title on one line, tagline below (Android 12 footer)."""
    c = PALETTE["light" if light else "dark"]
    w, h = 800, 320
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    icon_pt = 52
    title_pt = 40
    sub_pt = 20
    font_icon = ImageFont.truetype(material, icon_pt)
    font_title = ImageFont.truetype(roboto_med, title_pt)
    font_sub = ImageFont.truetype(roboto_reg, sub_pt)

    ch = chr(_CODEPOINT_BOOK)
    iw, ih = _text_size(draw, ch, font_icon)
    gap = 15
    tw, th = _text_size(draw, _TITLE, font_title)
    sw, sh = _text_size(draw, _TAGLINE, font_sub)

    row_w = iw + gap + tw
    block_h = max(ih, th) + 12 + sh
    row_y = (h - block_h) // 2
    # Center the lockup; if tagline is wider than the title row, center using max width
    lockup_w = max(row_w, sw)
    start_x = (w - lockup_w) // 2

    draw.text((start_x, row_y), ch, font=font_icon, fill=c["mint"])
    title_x = start_x + iw + gap
    title_y = row_y + (ih - th) // 2
    draw.text((title_x, title_y), _TITLE, font=font_title, fill=c["text_primary"])
    sub_y = row_y + max(ih, th) + 12
    sub_x = title_x
    draw.text((sub_x, sub_y), _TAGLINE, font=font_sub, fill=c["text_secondary"])

    img.save(path)


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "lib", "assets", "splash")
    os.makedirs(out, exist_ok=True)

    flutter_root = os.environ.get("FLUTTER_ROOT", os.path.expanduser("~/flutter"))
    material, roboto_med, roboto_reg = _fonts(flutter_root)

    # Android 12 center art (icon only) — same pixel size as previous generated assets
    a12_w, a12_h = 1376, 768
    render_android12(
        os.path.join(out, "splash_android12_light.png"),
        light=True,
        material=material,
        w=a12_w,
        h=a12_h,
    )
    render_android12(
        os.path.join(out, "splash_android12_dark.png"),
        light=False,
        material=material,
        w=a12_w,
        h=a12_h,
    )

    for light in (True, False):
        suffix = "light" if light else "dark"
        render_full(
            os.path.join(out, f"splash_full_{suffix}.png"),
            light=light,
            material=material,
            roboto_med=roboto_med,
            roboto_reg=roboto_reg,
        )
        render_branding(
            os.path.join(out, f"splash_branding_{suffix}.png"),
            light=light,
            material=material,
            roboto_med=roboto_med,
            roboto_reg=roboto_reg,
        )

    print(f"Wrote PNGs under {out}/")


if __name__ == "__main__":
    main()
