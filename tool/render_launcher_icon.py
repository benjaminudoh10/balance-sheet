#!/usr/bin/env python3
"""Rasterize Icons.menu_book_rounded (U+F8B4) for flutter_launcher_icons source assets.

Requires Pillow: pip3 install pillow
Uses MaterialIcons from your Flutter SDK (set FLUTTER_ROOT, default ~/flutter).

  python3 tool/render_launcher_icon.py
  dart run flutter_launcher_icons
"""
from __future__ import annotations

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Install Pillow: pip3 install pillow", file=sys.stderr)
    sys.exit(1)

# AppPalette.light — keep in sync with lib/theme/app_palette.dart
_BG = (0xF5, 0xF3, 0xFA, 0xFF)
_MINT = (0x0D, 0x8F, 0x72, 0xFF)

# Icons.menu_book_rounded (see Flutter material/icons.dart)
_CODEPOINT = 0xF8B4
_FONT_SIZE = 580
_CANVAS = 1024


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    flutter_root = os.environ.get("FLUTTER_ROOT", os.path.expanduser("~/flutter"))
    font_path = os.path.join(
        flutter_root,
        "bin",
        "cache",
        "artifacts",
        "material_fonts",
        "MaterialIcons-Regular.otf",
    )
    if not os.path.isfile(font_path):
        print(f"Font not found: {font_path}\nSet FLUTTER_ROOT to your Flutter SDK.", file=sys.stderr)
        sys.exit(1)

    font = ImageFont.truetype(font_path, _FONT_SIZE)
    glyph = chr(_CODEPOINT)
    cx, cy = _CANVAS // 2, _CANVAS // 2

    logo = Image.new("RGBA", (_CANVAS, _CANVAS), _BG)
    draw = ImageDraw.Draw(logo)
    draw.text((cx, cy), glyph, font=font, fill=_MINT, anchor="mm")
    logo.save(os.path.join(root, "lib/assets/logo.png"))

    fg = Image.new("RGBA", (_CANVAS, _CANVAS), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(fg)
    draw_fg.text((cx, cy), glyph, font=font, fill=_MINT, anchor="mm")
    fg.save(os.path.join(root, "lib/assets/app_icon_foreground.png"))

    print("Wrote lib/assets/logo.png and lib/assets/app_icon_foreground.png")


if __name__ == "__main__":
    main()
