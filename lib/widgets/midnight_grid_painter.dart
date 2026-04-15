import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:flutter/material.dart';

/// Subtle teal grid for dark screens (home, accounts, etc.).
class MidnightGridPainter extends CustomPainter {
  MidnightGridPainter({this.heightFraction = 1.0});

  /// 1.0 = full height; main screen uses ~0.55 to keep grid in upper area.
  final double heightFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = MidnightTheme.gridLine
      ..strokeWidth = 0.6;
    final double h = size.height * heightFraction.clamp(0.2, 1.0);
    const double step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MidnightGridPainter oldDelegate) =>
      oldDelegate.heightFraction != heightFraction;
}
