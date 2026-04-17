class DBConstants {
  static const DB_NAME = "transactions.db";
  static const TRANSACTION = "transactions";
  static const CONTACT = "contacts";
  static const BUDGET_MONTH = "budget_months";
  static const BUDGET_LINE = "budget_lines";
  static const INVESTMENT_HOLDING = "investment_holdings";
  static const INVESTMENT_LOT = "investment_lot_entries";
  static const INVESTMENT_PRICE = "investment_price_points";
  /// Legacy table removed in v10; kept for migration reference only.
  static const INVESTMENT_CASH = "investment_cash";
  static const INVESTMENT_OTHER_ASSET = "investment_other_assets";
  static const int DB_VERSION = 10;
}
