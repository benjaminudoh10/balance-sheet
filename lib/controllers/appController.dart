import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppController extends GetxController {
  RxInt index = 0.obs;

  /// Persisted key from [AppFontIds] — drives [buildDarkAppTheme] / [buildLightAppTheme].
  final RxString fontId = AppFontIds.defaultId.obs;

  /// User preference: light, dark, or follow OS.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

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
  }

  void setAppFont(String id) {
    if (!AppFontIds.isValid(id)) return;
    fontId.value = id;
    GetStorage().write(AppConstants.APP_FONT_KEY, id);
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    GetStorage().write(AppConstants.APP_THEME_MODE_KEY, _themeModeToStorage(mode));
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

  setIndex(int i) {
    index.value = i;
  }
}
