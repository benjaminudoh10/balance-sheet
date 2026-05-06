#!/usr/bin/env python3
"""Render a blue-tinted launcher icon used only by debug builds.

The output is written directly under ``android/app/src/debug/res/`` so that
AGP's per-build-type resource overlay replaces the main mint icon for
``flutter run`` / debug installs only. Release builds are unaffected.

The adaptive-icon XML at ``src/main/res/mipmap-anydpi-v26/launcher_icon.xml``
is shared — it references ``@color/ic_launcher_background`` and
``@drawable/ic_launcher_foreground`` which both resolve to the debug
overrides this script writes.

Requires Pillow:    ``pip3 install pillow``
Uses MaterialIcons from your Flutter SDK (set ``FLUTTER_ROOT``, default
``~/flutter``).

Usage::

    python3 tool/render_debug_launcher_icon.py

Then ``flutter run`` (debug) and the app on the phone shows the blue icon.
Re-run only when the debug colours below change; the generated PNGs are
checked into the repo so day-to-day builds don't depend on Pillow.
"""
from __future__ import annotations

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Install Pillow: pip3 install pillow", file=sys.stderr)
    sys.exit(1)

# Same icon family as the release variant (Icons.menu_book_rounded U+F8B4),
# tinted to a debug-blue so the launcher icon makes the build type
# unmistakable at a glance. The background gets a subtle blue cast so
# circle-cropped launcher styles (which hide the glyph margin) also read
# "different" at small sizes.
_BG = (0xEA, 0xF1, 0xFB, 0xFF)        # faint azure-tinted background
_GLYPH = (0x1F, 0x6F, 0xEB, 0xFF)     # vivid debug-blue glyph

_CODEPOINT = 0xF8B4  # Icons.menu_book_rounded

# Per-density sizes for the legacy / pre-O raster icons (square crop)
# and the adaptive-icon foreground at 108dp x 108dp.
_MIPMAP_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
_FOREGROUND_SIZES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

# Glyph fills ~57% of the canvas so the inset adaptive-icon safe area
# (72dp / 108dp ~= 66%) clears it with a small margin and the legacy
# raster icon doesn't kiss its own edges.
_GLYPH_FILL_FRACTION = 0.566


def _font(flutter_root: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = os.path.join(
        flutter_root,
        "bin",
        "cache",
        "artifacts",
        "material_fonts",
        "MaterialIcons-Regular.otf",
    )
    if not os.path.isfile(font_path):
        print(
            f"Font not found: {font_path}\n"
            "Set FLUTTER_ROOT to your Flutter SDK.",
            file=sys.stderr,
        )
        sys.exit(1)
    return ImageFont.truetype(font_path, size)


def _ensure(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _render_glyph(size: int, flutter_root: str, *, transparent_bg: bool) -> Image.Image:
    bg = (0, 0, 0, 0) if transparent_bg else _BG
    img = Image.new("RGBA", (size, size), bg)
    font = _font(flutter_root, int(size * _GLYPH_FILL_FRACTION))
    ImageDraw.Draw(img).text(
        (size // 2, size // 2),
        chr(_CODEPOINT),
        font=font,
        fill=_GLYPH,
        anchor="mm",
    )
    return img


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    flutter_root = os.environ.get("FLUTTER_ROOT", os.path.expanduser("~/flutter"))
    debug_res = os.path.join(root, "android", "app", "src", "debug", "res")

    # 1. mipmap-*dpi/launcher_icon.png — flattened (used by older Androids
    #    and by some launchers / task-switcher previews).
    for density, size in _MIPMAP_SIZES.items():
        out_dir = os.path.join(debug_res, f"mipmap-{density}")
        _ensure(out_dir)
        _render_glyph(size, flutter_root, transparent_bg=False).save(
            os.path.join(out_dir, "launcher_icon.png")
        )

    # 2. drawable-*dpi/ic_launcher_foreground.png — adaptive-icon
    #    foreground on a transparent canvas; the system composites it
    #    over the background colour set via values/colors.xml below.
    for density, size in _FOREGROUND_SIZES.items():
        out_dir = os.path.join(debug_res, f"drawable-{density}")
        _ensure(out_dir)
        _render_glyph(size, flutter_root, transparent_bg=True).save(
            os.path.join(out_dir, "ic_launcher_foreground.png")
        )

    # 3. values/colors.xml — debug-only override of the adaptive-icon
    #    background colour. The shared adaptive-icon XML at
    #    src/main/res/mipmap-anydpi-v26/launcher_icon.xml resolves
    #    @color/ic_launcher_background to this value when building debug.
    values_dir = os.path.join(debug_res, "values")
    _ensure(values_dir)
    bg_hex = "#{:02X}{:02X}{:02X}".format(_BG[0], _BG[1], _BG[2])
    colors_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        "    <!-- Debug-only override of the adaptive-icon background\n"
        "         colour so the debug install shows a blue-tinted icon\n"
        "         and is visually distinguishable from the release\n"
        '         "Balanced" install on the same device. Generated by\n'
        "         tool/render_debug_launcher_icon.py — do not hand-edit. -->\n"
        f'    <color name="ic_launcher_background">{bg_hex}</color>\n'
        "</resources>\n"
    )
    with open(os.path.join(values_dir, "colors.xml"), "w", encoding="utf-8") as f:
        f.write(colors_xml)

    print(f"Wrote debug launcher icon assets under {debug_res}")


if __name__ == "__main__":
    main()
