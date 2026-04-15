import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/pin_field_card.dart';
import 'package:balance_sheet/widgets/pin_hero_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// PIN entry when unlocking the app, or when confirming removal of the access PIN from Profile.
class LockScreen extends StatefulWidget {
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final SecurityController _securityController = Get.find();

  late final TextEditingController _pinController;
  late final FocusNode _pinFocus;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _pinFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _securityController.unlockWithFingerprint();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      final bool turningOffPin = _securityController.fromSettings.value;

      final String appBarTitle =
          turningOffPin ? 'Turn off PIN' : 'Unlock';
      final String headline = turningOffPin
          ? 'Remove access PIN'
          : 'Welcome back';
      final String subtitle = turningOffPin
          ? 'Enter your current PIN to turn off app lock. You can set a PIN again anytime in Profile.'
          : 'Enter your 4-digit PIN to open Balanced.';

      final IconData heroIcon =
          turningOffPin ? Icons.lock_open_rounded : Icons.lock_rounded;
      final String cardLabel = turningOffPin ? 'Verify PIN' : 'Your PIN';
      final String cardHint = turningOffPin
          ? 'Enter the PIN you use today'
          : 'Four digits';

      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: p.background,
        appBar: AppBar(
          backgroundColor: p.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: p.textPrimary),
          title: Text(
            appBarTitle,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: p.textPrimary,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + keyboardInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: PinHeroIcon(icon: heroIcon)),
                    const SizedBox(height: 22),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: p.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        height: 1.45,
                        color: p.textSecondary.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PinFieldCard(
                      label: cardLabel,
                      hint: cardHint,
                      field: PinInput(
                        fullWidth: true,
                        focusNode: _pinFocus,
                        autofocus: true,
                        onCompleted: (value) =>
                            _securityController.confirmPin(value),
                        onChanged: (_) {},
                        controller: _pinController,
                      ),
                    ),
                    if (_securityController.fingerprintInUse.value) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _securityController.unlockWithFingerprint(),
                                borderRadius: BorderRadius.circular(32),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    size: 48,
                                    color: p.mint,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use fingerprint',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w500,
                                color: p.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
