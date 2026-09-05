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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await db.execute("""
          CREATE TABLE IF NOT EXISTS ${DBConstants.TRANSACTION}(
            id INTEGER PRIMARY KEY,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            date INTEGER NOT NULL,
            category TEXT NOT NULL,
            contactId INTEGER,
            entryCurrency TEXT NOT NULL DEFAULT 'lcy',
            entryAmount INTEGER NOT NULL DEFAULT 0,
            deletedAt INTEGER,
            FOREIGN KEY(contactId) REFERENCES ${DBConstants.CONTACT}(id)
          )""");
        await db.execute("""
          CREATE TABLE IF NOT EXISTS ${DBConstants.CONTACT}(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )""");
        await db.execute(_sqlCreateBudgetMonths);
        await db.execute(_sqlCreateBudgetLines);
        await db.execute(_sqlCreateInvestmentHoldings);
        await db.execute(_sqlCreateInvestmentLots);
        await db.execute(_sqlCreateInvestmentPrices);
        await db.execute(_sqlCreateInvestmentOtherAssets);
        await db.execute(_sqlCreateOtherAssetLineItems);
        await db.execute(_sqlCreateTags);
        await db.execute(_sqlCreateTransactionTags);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE ${DBConstants.TRANSACTION} ADD COLUMN deletedAt INTEGER");
        }
        if (oldVersion < 3) {
          await db.execute(_sqlCreateTags);
          await db.execute(_sqlCreateTransactionTags);
        }
        if (oldVersion < 4) {
          await db.execute(
              "ALTER TABLE ${DBConstants.BUDGET_LINE} ADD COLUMN tag_id INTEGER REFERENCES ${DBConstants.TAG}(id) ON DELETE SET NULL");
        }
        if (oldVersion < 5) {
          await db.execute(_sqlCreateOtherAssetLineItems);
          final List<Map<String, Object?>> existing = await db.query(
            DBConstants.INVESTMENT_OTHER_ASSET,
          );
          final int now = DateTime.now().millisecondsSinceEpoch;
          for (final Map<String, Object?> row in existing) {
            final int id = row['id'] as int;
            final int lcy = row['value_lcy_minor'] as int? ?? 0;
            final String ec = '${row['entry_currency'] ?? 'lcy'}'.toLowerCase();
            final int entry = row['entry_minor'] as int? ?? lcy;
            if (lcy == 0 && entry == 0) continue;
            await db
                .insert(DBConstants.OTHER_ASSET_LINE_ITEM, <String, Object?>{
              'asset_id': id,
              'description': 'Opening balance',
              'amount_minor': lcy,
              'entry_currency': ec == 'fcy' ? 'fcy' : 'lcy',
              'entry_amount_minor': entry,
              'occurred_at_ms': row['updated_at_ms'] as int? ?? now,
              'created_at_ms': now,
            });
          }
        }
      },
    );
    return taskDb;
  }
}

const String _sqlCreateTags = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.TAG}(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''';

const String _sqlCreateTransactionTags = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.TRANSACTION_TAG}(
  transaction_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (transaction_id, tag_id),
  FOREIGN KEY(transaction_id) REFERENCES ${DBConstants.TRANSACTION}(id) ON DELETE CASCADE,
  FOREIGN KEY(tag_id) REFERENCES ${DBConstants.TAG}(id) ON DELETE CASCADE
)
''';

const String _sqlCreateBudgetMonths = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.BUDGET_MONTH}(
  id INTEGER PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  UNIQUE(year, month)
)
''';

const String _sqlCreateBudgetLines = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.BUDGET_LINE}(
  id INTEGER PRIMARY KEY,
  budget_month_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  planned_amount INTEGER NOT NULL,
  contact_id INTEGER,
  tag_id INTEGER,
  category TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  entryCurrency TEXT NOT NULL DEFAULT 'lcy',
  entryAmount INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(budget_month_id) REFERENCES ${DBConstants.BUDGET_MONTH}(id) ON DELETE CASCADE,
  FOREIGN KEY(contact_id) REFERENCES ${DBConstants.CONTACT}(id) ON DELETE SET NULL,
  FOREIGN KEY(tag_id) REFERENCES ${DBConstants.TAG}(id) ON DELETE SET NULL
)
''';

const String _sqlCreateInvestmentHoldings = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.INVESTMENT_HOLDING}(
  id INTEGER PRIMARY KEY,
  ticker TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at_ms INTEGER NOT NULL
)
''';

const String _sqlCreateInvestmentLots = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.INVESTMENT_LOT}(
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
CREATE TABLE IF NOT EXISTS ${DBConstants.INVESTMENT_PRICE}(
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
CREATE TABLE IF NOT EXISTS ${DBConstants.INVESTMENT_OTHER_ASSET}(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT NOT NULL,
  value_lcy_minor INTEGER NOT NULL DEFAULT 0,
  entry_currency TEXT NOT NULL DEFAULT 'lcy',
  entry_minor INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  updated_at_ms INTEGER NOT NULL
)
''';

const String _sqlCreateOtherAssetLineItems = '''
CREATE TABLE IF NOT EXISTS ${DBConstants.OTHER_ASSET_LINE_ITEM}(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  amount_minor INTEGER NOT NULL,
  entry_currency TEXT NOT NULL DEFAULT 'lcy',
  entry_amount_minor INTEGER NOT NULL DEFAULT 0,
  occurred_at_ms INTEGER NOT NULL,
  created_at_ms INTEGER NOT NULL,
  FOREIGN KEY(asset_id) REFERENCES ${DBConstants.INVESTMENT_OTHER_ASSET}(id) ON DELETE CASCADE
)
''';
