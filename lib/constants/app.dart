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

  /// ISO 4217 codes (3 letters), e.g. NGN / USD — see [CurrencyController].
  static const CURRENCY_LCY_KEY = "currency_lcy";
  static const CURRENCY_FCY_KEY = "currency_fcy";
  /// Major LCY per 1 major FCY (e.g. 1400 when 1 USD = 1400 NGN).
  static const CURRENCY_RATE_KEY = "currency_rate";
}
