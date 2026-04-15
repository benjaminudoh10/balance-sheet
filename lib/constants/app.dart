class AppConstants {
  /// Legacy plaintext PIN — removed when migrating to [USER_PIN_HASH_KEY].
  static const USER_PIN_KEY = "user_pin";
  static const USER_PIN_HASH_KEY = "user_pin_hash";
  static const USER_PIN_SALT_KEY = "user_pin_salt";
  static const USE_FINGERPRINT = "fingerprint";
  static const PIN_CODE_LENGTH = 4;
  static const APP_FONT_KEY = "app_font_family";
  /// Values: `system`, `light`, `dark` — see [AppController.themeMode].
  static const APP_THEME_MODE_KEY = "app_theme_mode";
}
