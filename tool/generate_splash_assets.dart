// Generates PNGs for flutter_native_splash (branding strip + full mark+wordmark).
// Run from project root: dart run tool/generate_splash_assets.dart
// Then: dart run flutter_native_splash:create

import 'dart:io';

import 'package:image/image.dart';

/// AppPalette.light / .dark text colors (ARGB)
void main() {
  final String root = Directory.current.path;
  final String dir = '$root/lib/assets/splash';

  _writeBranding('$dir/splash_branding_light.png', light: true);
  _writeBranding('$dir/splash_branding_dark.png', light: false);

  _writeFull(
    '$dir/splash_full_light.png',
    light: true,
    markFile: File('$dir/splash_android12_light.png'),
  );
  _writeFull(
    '$dir/splash_full_dark.png',
    light: false,
    markFile: File('$dir/splash_android12_dark.png'),
  );

  stdout.writeln('Wrote splash_branding_*.png and splash_full_*.png under lib/assets/splash/');
}

void _writeBranding(String path, {required bool light}) {
  final Image img = Image(width: 800, height: 320, numChannels: 4);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  final Color titleC = light
      ? ColorRgba8(0x1A, 0x14, 0x28, 0xFF)
      : ColorRgba8(0xF0, 0xF6, 0xFC, 0xFF);
  final Color subC = light
      ? ColorRgba8(0x5E, 0x56, 0x72, 0xFF)
      : ColorRgba8(0x8B, 0x94, 0x9E, 0xFF);

  drawString(img, 'Balanced', font: arial48, y: 88, color: titleC);
  drawString(
    img,
    'know where your money goes',
    font: arial24,
    y: 168,
    color: subC,
  );

  File(path).writeAsBytesSync(encodePng(img));
}

void _writeFull(String path, {required bool light, required File markFile}) {
  final Image? decoded = decodePng(markFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode ${markFile.path}');
    exit(1);
  }

  const int canvasH = 480;
  const int iconTargetH = 200;
  final int iconW = (decoded.width * iconTargetH / decoded.height).round();
  final Image icon = copyResize(decoded, width: iconW, height: iconTargetH);

  const int canvasW = 1600;
  final Image img = Image(width: canvasW, height: canvasH, numChannels: 4);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  final int iconX = 220;
  final int iconY = (canvasH - iconTargetH) ~/ 2;
  compositeImage(img, icon, dstX: iconX, dstY: iconY);

  final Color titleC = light
      ? ColorRgba8(0x1A, 0x14, 0x28, 0xFF)
      : ColorRgba8(0xF0, 0xF6, 0xFC, 0xFF);
  final Color subC = light
      ? ColorRgba8(0x5E, 0x56, 0x72, 0xFF)
      : ColorRgba8(0x8B, 0x94, 0x9E, 0xFF);

  final int textLeft = iconX + iconW + 40;
  drawString(
    img,
    'Balanced',
    font: arial48,
    x: textLeft,
    y: 150,
    color: titleC,
  );
  drawString(
    img,
    'know where your money goes',
    font: arial24,
    x: textLeft,
    y: 230,
    color: subC,
  );

  File(path).writeAsBytesSync(encodePng(img));
}
