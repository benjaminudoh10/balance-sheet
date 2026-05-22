import 'dart:async' show unawaited;

import 'package:balance_sheet/backup/auto_backup_service.dart';
import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/controllers/security_controller.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppController extends GetxController {
  RxInt index = 0.obs;

  /// Persisted key from [AppFontIds] — drives [buildDarkAppTheme] / [buildLightAppTheme].
  final RxString fontId = AppFontIds.defaultId.obs;

  /// User preference: light, dark, or follow OS.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// User preference: which color scheme to use.
  final Rx<AppThemeScheme> themeScheme = AppThemeScheme.midnightMint.obs;

  /// Trash settings
  final RxBool useTrash = false.obs;
  final RxInt trashPeriodDays = 30.obs;
  final RxBool lockTrash = false.obs;

  /// Automatic daily backup at midnight
  final RxBool autoBackupEnabled = false.obs;
  final RxInt autoBackupRetentionDays = 7.obs;

  /// Populated asynchronously in [onInit] from [PackageInfo.fromPlatform];
  /// reads `version` from `pubspec.yaml` at build time so UI never drifts
  /// from the shipped APK / IPA. Empty until the platform call resolves.
  final RxString appVersion = ''.obs;

  /// Populated alongside [appVersion]; on Android this is `versionCode`,
  /// on iOS `CFBundleVersion`. Empty until resolved.
  final RxString appBuildNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final GetStorage box = GetStorage();
    final String? stored = box.read<String>(AppConstants.APP_FONT_KEY);
    if (stored != null && AppFontIds.isValid(stored)) {
      fontId.value = stored;
    }
    final String? modeRaw = box.read<String>(AppConstants.APP_THEME_MODE_KEY);
    themeMode.value = _themeModeFromStorage(modeRaw);

    final String? schemeRaw =
        box.read<String>(AppConstants.APP_COLOR_SCHEME_KEY);
    themeScheme.value = AppThemeScheme.fromId(schemeRaw);

    useTrash.value = box.read<bool>(AppConstants.USE_TRASH_KEY) ?? true;
    trashPeriodDays.value =
        box.read<int>(AppConstants.TRASH_PERIOD_DAYS_KEY) ?? 30;
    lockTrash.value = box.read<bool>(AppConstants.LOCK_TRASH_KEY) ?? false;
    autoBackupEnabled.value =
        box.read<bool>(AppConstants.AUTO_BACKUP_ENABLED_KEY) ?? false;
    autoBackupRetentionDays.value =
        box.read<int>(AppConstants.AUTO_BACKUP_RETENTION_DAYS_KEY) ?? 7;

    unawaited(_loadAppVersion());
    unawaited(_cleanupTrash());
  }

  Future<void> _cleanupTrash() async {
    if (!useTrash.value) return;
    final int thresholdMs = DateTime.now()
        .subtract(Duration(days: trashPeriodDays.value))
        .millisecondsSinceEpoch;
    await db.cleanupTrash(thresholdMs);
  }

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      appVersion.value = info.version;
      appBuildNumber.value = info.buildNumber;
    } catch (e, st) {
      debugPrint('AppController: PackageInfo.fromPlatform failed: $e\n$st');
    }
  }

  void setAppFont(String id) {
    if (!AppFontIds.isValid(id)) return;
    fontId.value = id;
    GetStorage().write(AppConstants.APP_FONT_KEY, id);
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    GetStorage()
        .write(AppConstants.APP_THEME_MODE_KEY, _themeModeToStorage(mode));
  }

  void setThemeScheme(AppThemeScheme scheme) {
    themeScheme.value = scheme;
    GetStorage().write(AppConstants.APP_COLOR_SCHEME_KEY, scheme.id);
  }

  Future<void> setUseTrash(bool value) async {
    if (!value && lockTrash.value) {
      // Disabling Trash with lock enabled: Requires authentication (Biometric or PIN)
      final SecurityController sc = Get.find();
      final bool confirmed =
          await sc.authenticateUser('Use biometrics or PIN to disable Trash');
      if (!confirmed) return;
    }
    useTrash.value = value;
    GetStorage().write(AppConstants.USE_TRASH_KEY, value);
  }

  void setTrashPeriodDays(int value) {
    trashPeriodDays.value = value;
    GetStorage().write(AppConstants.TRASH_PERIOD_DAYS_KEY, value);
  }

  Future<void> setLockTrash(bool value) async {
    if (!value) {
      // Disabling Trash Lock: Requires authentication (Biometric or PIN)
      final SecurityController sc = Get.find();
      final bool confirmed = await sc
          .authenticateUser('Use biometrics or PIN to disable Trash lock');
      if (!confirmed) return;
    }
    lockTrash.value = value;
    GetStorage().write(AppConstants.LOCK_TRASH_KEY, value);
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    autoBackupEnabled.value = value;
    GetStorage().write(AppConstants.AUTO_BACKUP_ENABLED_KEY, value);
    if (value) {
      await AutoBackupService.scheduleDaily();
    } else {
      await AutoBackupService.cancelDaily();
    }
  }

  void setAutoBackupRetentionDays(int value) {
    autoBackupRetentionDays.value = value;
    GetStorage().write(AppConstants.AUTO_BACKUP_RETENTION_DAYS_KEY, value);
  }

  /// Reloads font and theme from [GetStorage] (e.g. after backup import).
  void syncFromStorage() {
    final GetStorage box = GetStorage();
    final String? stored = box.read<String>(AppConstants.APP_FONT_KEY);
    if (stored != null && AppFontIds.isValid(stored)) {
      fontId.value = stored;
    }
    final String? modeRaw = box.read<String>(AppConstants.APP_THEME_MODE_KEY);
    themeMode.value = _themeModeFromStorage(modeRaw);

    final String? schemeRaw =
        box.read<String>(AppConstants.APP_COLOR_SCHEME_KEY);
    themeScheme.value = AppThemeScheme.fromId(schemeRaw);

    useTrash.value = box.read<bool>(AppConstants.USE_TRASH_KEY) ?? true;
    trashPeriodDays.value =
        box.read<int>(AppConstants.TRASH_PERIOD_DAYS_KEY) ?? 30;
    lockTrash.value = box.read<bool>(AppConstants.LOCK_TRASH_KEY) ?? false;
    autoBackupEnabled.value =
        box.read<bool>(AppConstants.AUTO_BACKUP_ENABLED_KEY) ?? false;
    autoBackupRetentionDays.value =
        box.read<int>(AppConstants.AUTO_BACKUP_RETENTION_DAYS_KEY) ?? 7;
  }

  static ThemeMode _themeModeFromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void setIndex(int i) {
    if (i == index.value) return;
    AppHaptics.selection();
    index.value = i;
  }
}
