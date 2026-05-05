import 'dart:async' show unawaited;

import 'package:balance_sheet/constants/app.dart';
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
    unawaited(_loadAppVersion());
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

  /// Reloads font and theme from [GetStorage] (e.g. after backup import).
  void syncFromStorage() {
    final GetStorage box = GetStorage();
    final String? stored = box.read<String>(AppConstants.APP_FONT_KEY);
    if (stored != null && AppFontIds.isValid(stored)) {
      fontId.value = stored;
    }
    final String? modeRaw = box.read<String>(AppConstants.APP_THEME_MODE_KEY);
    themeMode.value = _themeModeFromStorage(modeRaw);
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
