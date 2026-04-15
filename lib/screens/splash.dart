import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MidnightTheme.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MidnightTheme.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MidnightGridPainter(heightFraction: 1.0),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  flex: 9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 36.0,
                            color: MidnightTheme.mint,
                          ),
                          const SizedBox(width: 15.0),
                          Text(
                            'Balanced',
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: MidnightTheme.textPrimary,
                              fontSize: 36.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '...know where your money goes',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: MidnightTheme.textSecondary,
                          fontSize: 18.0,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: SpinKitThreeBounce(
                    color: MidnightTheme.mint,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
