import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _navScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navScheduled) return;
      _navScheduled = true;
      // Isolated widget tests use [Splash] without Get; skip timer so tests don't leak.
      if (!Get.isRegistered<SecurityController>()) return;
      Future.delayed(const Duration(milliseconds: 1000), _goToInitialRoute);
    });
  }

  void _goToInitialRoute() {
    if (!mounted) return;

    final SecurityController security = Get.find<SecurityController>();
    final Widget next = security.pinIsSet.value ? LockScreen() : Home();

    // Use the root [Navigator] from context — [Get.offAll] can run before
    // [GetMaterialApp] wires [Get.key], which caused contextless navigation errors.
    Navigator.of(context).pushAndRemoveUntil<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
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
                            color: p.mint,
                          ),
                          const SizedBox(width: 15.0),
                          Text(
                            'Balanced',
                            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                              color: p.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '...know where your money goes',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: p.textSecondary,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SpinKitThreeBounce(
                    color: p.mint,
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
