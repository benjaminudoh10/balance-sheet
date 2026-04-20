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

  /// [GetStorage] flags: one-time slidable row peek (see `slidable_peek_hint.dart`).
  static const SLIDABLE_PEEK_TRANSACTIONS = 'slidable_peek_transactions';
  static const SLIDABLE_PEEK_BUDGET = 'slidable_peek_budget';
  static const SLIDABLE_PEEK_CONTACTS = 'slidable_peek_contacts';
  /// Stock holdings list on the plan / invest screen.
  static const SLIDABLE_PEEK_INVESTMENTS = 'slidable_peek_investments';
  /// “Other investments” tab list (separate from [SLIDABLE_PEEK_INVESTMENTS] so each tab can peek once).
  static const SLIDABLE_PEEK_INVESTMENTS_OTHER = 'slidable_peek_investments_other';

  /// Home screen: one-time balance ↔ net worth [PageView] coach animation (see `main_screen.dart`).
  static const HOME_BALANCE_PAGER_COACH_DONE = 'home_balance_pager_coach_done';

  /// Summary cards: show amounts on home balance + net worth strip (`main_screen.dart`).
  static const SHOW_HOME_SUMMARY_AMOUNTS_KEY = 'show_home_summary_amounts';
  /// Summary cards: show amounts on portfolio + other investments summaries (`plan_stocks_screen.dart`).
  static const SHOW_INVESTMENT_SUMMARY_AMOUNTS_KEY = 'show_investment_summary_amounts';
}
