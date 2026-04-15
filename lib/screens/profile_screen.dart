import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/screens/lock_screen.dart';
import 'package:balance_sheet/screens/pin_lock.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:get/get.dart';

/// Matches [pubspec.yaml] version (update when bumping release).
const String _kAppVersion = '1.3.0';

/// Profile tab — identity-style header plus security controls (replaces flat settings list).
class ProfileView extends StatelessWidget {
  final SecurityController _securityController = Get.find();
  final AppController _appController = Get.find();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
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
                        Text(
                          'Profile',
                          style: textTheme.displayMedium!.copyWith(
                            color: p.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _ProfileHeroCard(),
                        const SizedBox(height: 28),
                        Text(
                          'THEME',
                          style: textTheme.labelMedium!.copyWith(
                            letterSpacing: 1.4,
                            color: p.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final ThemeMode current = _appController.themeMode.value;
                          return Column(
                            children: [
                              _ThemeModeOptionRow(
                                selected: current == ThemeMode.light,
                                label: 'Light',
                                icon: Icons.light_mode_outlined,
                                onTap: () => _appController.setThemeMode(ThemeMode.light),
                              ),
                              const SizedBox(height: 8),
                              _ThemeModeOptionRow(
                                selected: current == ThemeMode.dark,
                                label: 'Dark',
                                icon: Icons.dark_mode_outlined,
                                onTap: () => _appController.setThemeMode(ThemeMode.dark),
                              ),
                              const SizedBox(height: 8),
                              _ThemeModeOptionRow(
                                selected: current == ThemeMode.system,
                                label: 'System default',
                                icon: Icons.brightness_auto_outlined,
                                onTap: () => _appController.setThemeMode(ThemeMode.system),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                        Text(
                          'APPEARANCE',
                          style: textTheme.labelMedium!.copyWith(
                            letterSpacing: 1.4,
                            color: p.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final String current = _appController.fontId.value;
                          return Column(
                            children: AppFontIds.choices.map((AppFontOption o) {
                              final bool selected = current == o.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _appController.setAppFont(o.id),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: p.surface,
                                        border: Border.all(
                                          color: selected
                                              ? p.mint.withValues(alpha: 0.45)
                                              : p.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? Icons.radio_button_checked_rounded
                                                : Icons.radio_button_off_rounded,
                                            color: selected
                                                ? p.mint
                                                : p.textSecondary,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              o.label,
                                              style: textTheme.titleMedium!.copyWith(
                                                color: p.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 20),
                        Text(
                          'SECURITY',
                          style: textTheme.labelMedium!.copyWith(
                            letterSpacing: 1.4,
                            color: p.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() => _SecuritySwitchRow(
                              title: !_securityController.pinIsSet.value
                                  ? 'Access PIN'
                                  : 'Change access PIN',
                              subtitle: !_securityController.pinIsSet.value
                                  ? 'Protect the app with a 4-digit PIN'
                                  : 'PIN is enabled for this device',
                              icon: Icons.lock_rounded,
                              switchValue: _securityController.pinIsSet.value,
                              switchDisabled: false,
                              onSwitch: (v) => _goToPinView(v),
                              onRowTap: () => Get.to(() => Pin()),
                            )),
                        const SizedBox(height: 10),
                        Obx(() => _SecuritySwitchRow(
                              title: _securityController.fingerprintInUse.value
                                  ? 'Fingerprint unlock'
                                  : 'Use fingerprint',
                              subtitle: !_securityController.pinIsSet.value
                                  ? 'Set a PIN first to use fingerprint'
                                  : 'Unlock with Face ID / fingerprint when available',
                              icon: Icons.fingerprint_rounded,
                              switchValue: _securityController.fingerprintInUse.value,
                              switchDisabled: !_securityController.pinIsSet.value,
                              onSwitch: (v) => _securityController.activateFingerPrint(v),
                            )),
                        const SizedBox(height: 20),
                        Text(
                          'DATA',
                          style: textTheme.labelMedium!.copyWith(
                            letterSpacing: 1.4,
                            color: p.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BackupActionRow(
                          label: 'Export backup',
                          subtitle:
                              'Choose where to save a JSON file (e.g. Files or Downloads). PIN is stored as hash + salt only — keep the file private.',
                          icon: Icons.save_alt_rounded,
                          onTap: () => _exportBackup(context),
                        ),
                        const SizedBox(height: 8),
                        _BackupActionRow(
                          label: 'Import backup',
                          subtitle: 'Replace everything on this device from a Balanced backup file',
                          icon: Icons.file_download_outlined,
                          onTap: () => _importBackup(context),
                        ),
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
                        style: textTheme.bodySmall!.copyWith(
                          color: p.textSecondary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Data stays on this device',
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium!.copyWith(
                          color: p.textSecondary.withValues(alpha: 0.55),
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

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final String? path = await BackupService.exportBackup();
      if (!context.mounted) return;
      if (path == null) return;
      Get.snackbar(
        'Backup saved',
        p.basename(path),
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (!context.mounted) return;
      Get.snackbar(
        'Backup',
        'Could not export: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final String? path = result.files.single.path;
    if (path == null) {
      Get.snackbar(
        'Import',
        'Could not read the selected file.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppPalette p = AppPalette.of(ctx);
        final TextTheme tt = Theme.of(ctx).textTheme;
        return AlertDialog(
          backgroundColor: p.surface,
          title: Text(
            'Replace all data?',
            style: tt.titleLarge?.copyWith(color: p.textPrimary),
          ),
          content: Text(
            'Importing overwrites transactions, contacts, theme, and lock settings on this device. This cannot be undone.',
            style: tt.bodyMedium?.copyWith(color: p.textSecondary, height: 1.35),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Import', style: TextStyle(color: p.mint)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final String raw = await File(path).readAsString();
      await BackupService.importFromJsonString(raw);
      await BackupService.refreshControllersAfterImport();
      if (!context.mounted) return;
      Get.snackbar(
        'Restored',
        'Backup imported successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    } on BackupException catch (e) {
      Get.snackbar(
        'Import failed',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Import failed',
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
    }
  }
}

class _BackupActionRow extends StatelessWidget {
  const _BackupActionRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: p.surface,
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: p.mint.withValues(alpha: 0.12),
                  border: Border.all(
                    color: p.mint.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: p.mint, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium!.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall!.copyWith(
                        height: 1.3,
                        color: p.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  static const double _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: p.mint.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: p.mint.withValues(alpha: 0.18),
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
              gradient: p.profileHeroGradient,
            ),
            child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: p.mint.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.mint.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface.withValues(alpha: 0.92),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 40,
                    color: p.mint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Balanced',
                style: textTheme.headlineSmall!.copyWith(
                  color: p.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Income & expenses on your phone',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!.copyWith(
                  height: 1.35,
                  color: p.textSecondary.withValues(alpha: 0.95),
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: switchDisabled ? null : onRowTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: p.surface,
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: p.mint.withValues(alpha: 0.12),
                  border: Border.all(
                    color: p.mint.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  color: switchDisabled
                      ? p.textSecondary
                      : p.mint,
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
                      style: textTheme.titleMedium!.copyWith(
                        color: switchDisabled
                            ? p.textSecondary
                            : p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall!.copyWith(
                        height: 1.3,
                        color: p.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: switchValue,
                onChanged: switchDisabled ? null : onSwitch,
                activeThumbColor: Colors.black87,
                activeTrackColor: p.mint.withValues(alpha: 0.55),
                inactiveThumbColor: p.textSecondary,
                inactiveTrackColor: p.surfaceElevated,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeOptionRow extends StatelessWidget {
  const _ThemeModeOptionRow({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: p.surface,
            border: Border.all(
              color: selected ? p.mint.withValues(alpha: 0.45) : p.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? p.mint : p.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 22, color: selected ? p.mint : p.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleMedium!.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
