import 'package:balance_sheet/constants/db.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb _instance = AppDb.internal();

  factory AppDb() => _instance;
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  /// Closes the singleton so the next [db] access opens a fresh database file.
  /// Used by tests that reset SQLite state between cases.
  Future<void> closeForTesting() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  AppDb.internal();

  initDb() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, DBConstants.DB_NAME);
    var taskDb = await openDatabase(
      path,
      version: DBConstants.DB_VERSION,
      onCreate: (Database db, int version) async {
        await db.execute("""
          CREATE TABLE ${DBConstants.TRANSACTION}(
            id INTEGER PRIMARY KEY,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            date INTEGER NOT NULL,
            category TEXT NOT NULL,
            contactId INTEGER,
            entryCurrency TEXT NOT NULL DEFAULT 'lcy',
            entryAmount INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(contactId) REFERENCES ${DBConstants.CONTACT}(id)
          )""");
        await db.execute("""
          CREATE TABLE ${DBConstants.CONTACT}(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )""");
        await db.execute(_sqlCreateBudgetMonths);
        await db.execute(_sqlCreateBudgetLines);
        await db.execute(_sqlCreateInvestmentHoldings);
        await db.execute(_sqlCreateInvestmentLots);
        await db.execute(_sqlCreateInvestmentPrices);
        await db.execute(_sqlCreateInvestmentOtherAssets);
      },
    );
    return taskDb;
  }
}

const String _sqlCreateBudgetMonths = '''
CREATE TABLE ${DBConstants.BUDGET_MONTH}(
  id INTEGER PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  UNIQUE(year, month)
)
''';

const String _sqlCreateBudgetLines = '''
CREATE TABLE ${DBConstants.BUDGET_LINE}(
  id INTEGER PRIMARY KEY,
  budget_month_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  planned_amount INTEGER NOT NULL,
  contact_id INTEGER,
  category TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  entryCurrency TEXT NOT NULL DEFAULT 'lcy',
  entryAmount INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(budget_month_id) REFERENCES ${DBConstants.BUDGET_MONTH}(id) ON DELETE CASCADE,
  FOREIGN KEY(contact_id) REFERENCES ${DBConstants.CONTACT}(id) ON DELETE SET NULL
)
''';

const String _sqlCreateInvestmentHoldings = '''
CREATE TABLE ${DBConstants.INVESTMENT_HOLDING}(
  id INTEGER PRIMARY KEY,
  ticker TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at_ms INTEGER NOT NULL
)
''';

const String _sqlCreateInvestmentLots = '''
CREATE TABLE ${DBConstants.INVESTMENT_LOT}(
  id INTEGER PRIMARY KEY,
  holding_id INTEGER NOT NULL,
  occurred_at_ms INTEGER NOT NULL,
  quantity_delta REAL NOT NULL,
  purchase_price_minor_per_share INTEGER NOT NULL DEFAULT 0,
  purchase_entry_currency TEXT NOT NULL DEFAULT 'lcy',
  purchase_price_entry_minor INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  FOREIGN KEY(holding_id) REFERENCES ${DBConstants.INVESTMENT_HOLDING}(id) ON DELETE CASCADE
)
''';

const String _sqlCreateInvestmentPrices = '''
CREATE TABLE ${DBConstants.INVESTMENT_PRICE}(
  id INTEGER PRIMARY KEY,
  holding_id INTEGER NOT NULL,
  as_of_ms INTEGER NOT NULL,
  as_of_day INTEGER NOT NULL DEFAULT 0,
  price_minor_per_share INTEGER NOT NULL,
  entry_currency TEXT NOT NULL DEFAULT 'lcy',
  price_entry_minor INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(holding_id) REFERENCES ${DBConstants.INVESTMENT_HOLDING}(id) ON DELETE CASCADE
)
''';

const String _sqlCreateInvestmentOtherAssets = '''
CREATE TABLE ${DBConstants.INVESTMENT_OTHER_ASSET}(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT NOT NULL,
  value_lcy_minor INTEGER NOT NULL DEFAULT 0,
  entry_currency TEXT NOT NULL DEFAULT 'lcy',
  entry_minor INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  updated_at_ms INTEGER NOT NULL
)
''';
