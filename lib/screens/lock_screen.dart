import 'package:balance_sheet/constants/midnight_theme.dart';
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
        backgroundColor: MidnightTheme.background,
        appBar: AppBar(
          backgroundColor: MidnightTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: MidnightTheme.textPrimary),
          title: Text(
            appBarTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MidnightTheme.textPrimary,
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
                painter: MidnightGridPainter(heightFraction: 1.0),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MidnightTheme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: MidnightTheme.textSecondary.withValues(alpha: 0.92),
                      ),
                    ),
                    if (!turningOffPin && _securityController.fingerprintInUse.value) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Or use fingerprint when prompted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: MidnightTheme.mint.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
