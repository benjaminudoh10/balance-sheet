import 'dart:ui' show ImageFilter;

import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Matches [pubspec.yaml] version (update when bumping release).
const String _kAppVersion = '1.3.0';

/// Profile tab — identity-style header plus security controls (replaces flat settings list).
class ProfileView extends StatelessWidget {
  final SecurityController _securityController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MidnightTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: MidnightTheme.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _ProfileHeroCard(),
                        const SizedBox(height: 28),
                        Text(
                          'SECURITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: MidnightTheme.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() => _SecuritySwitchRow(
                              title: _securityController.currentStoredPin.value == ''
                                  ? 'Access PIN'
                                  : 'Change access PIN',
                              subtitle: _securityController.currentStoredPin.value == ''
                                  ? 'Protect the app with a 4-digit PIN'
                                  : 'PIN is enabled for this device',
                              icon: Icons.lock_rounded,
                              switchValue: _securityController.currentStoredPin.value != '',
                              switchDisabled: false,
                              onSwitch: (v) => _goToPinView(v),
                              onRowTap: () => Get.to(() => Pin()),
                            )),
                        const SizedBox(height: 10),
                        Obx(() => _SecuritySwitchRow(
                              title: _securityController.fingerprintInUse.value
                                  ? 'Fingerprint unlock'
                                  : 'Use fingerprint',
                              subtitle: _securityController.currentStoredPin.value == ''
                                  ? 'Set a PIN first to use fingerprint'
                                  : 'Unlock with Face ID / fingerprint when available',
                              icon: Icons.fingerprint_rounded,
                              switchValue: _securityController.fingerprintInUse.value,
                              switchDisabled: _securityController.currentStoredPin.value == '',
                              onSwitch: (v) => _securityController.activateFingerPrint(v),
                            )),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Balanced $_kAppVersion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: MidnightTheme.textSecondary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Data stays on this device',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: MidnightTheme.textSecondary.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToPinView(bool value) {
    _securityController.reset();
    if (value) {
      Get.to(() => Pin());
    } else {
      _securityController.fromSettings.value = true;
      Get.to(() => LockScreen());
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  static const double _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: MidnightTheme.mint.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: MidnightTheme.mint.withValues(alpha: 0.18),
            blurRadius: 36,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
              gradient: MidnightTheme.profileHeroGradient,
            ),
            child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MidnightTheme.mint.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MidnightTheme.mint.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MidnightTheme.surface.withValues(alpha: 0.92),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 40,
                    color: MidnightTheme.mint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Balanced',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Income & expenses on your phone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: MidnightTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecuritySwitchRow extends StatelessWidget {
  const _SecuritySwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.switchValue,
    required this.switchDisabled,
    required this.onSwitch,
    this.onRowTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool switchValue;
  final bool switchDisabled;
  final void Function(bool) onSwitch;
  final VoidCallback? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: switchDisabled ? null : onRowTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: MidnightTheme.surface,
            border: Border.all(color: MidnightTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: MidnightTheme.mint.withValues(alpha: 0.12),
                  border: Border.all(
                    color: MidnightTheme.mint.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  color: switchDisabled
                      ? MidnightTheme.textSecondary
                      : MidnightTheme.mint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: switchDisabled
                            ? MidnightTheme.textSecondary
                            : MidnightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: MidnightTheme.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: switchValue,
                onChanged: switchDisabled ? null : onSwitch,
                activeThumbColor: Colors.black87,
                activeTrackColor: MidnightTheme.mint.withValues(alpha: 0.55),
                inactiveThumbColor: MidnightTheme.textSecondary,
                inactiveTrackColor: MidnightTheme.surfaceElevated,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
