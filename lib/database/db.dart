import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/investment/investment_days.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb _instance = new AppDb.internal();

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
          )"""
        );
        await db.execute("""
          CREATE TABLE ${DBConstants.CONTACT}(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )"""
        );
        await db.execute(_sqlCreateBudgetMonths);
        await db.execute(_sqlCreateBudgetLines);
        await db.execute(_sqlCreateInvestmentHoldings);
        await db.execute(_sqlCreateInvestmentLots);
        await db.execute(_sqlCreateInvestmentPrices);
        await db.execute(_sqlCreateInvestmentOtherAssets);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE ${DBConstants.TRANSACTION}_new(
              id INTEGER PRIMARY KEY,
              description TEXT NOT NULL,
              type TEXT NOT NULL,
              amount INTEGER NOT NULL,
              date INTEGER NOT NULL,
              category TEXT NOT NULL,
              contactId INTEGER,
              FOREIGN KEY(contactId) REFERENCES ${DBConstants.CONTACT}(id)
            )
          ''');
          await db.execute('''
            INSERT INTO ${DBConstants.TRANSACTION}_new (id, description, type, amount, date, category, contactId)
            SELECT id, description, type, amount, date, category, contactId FROM ${DBConstants.TRANSACTION}
          ''');
          await db.execute('DROP TABLE ${DBConstants.TRANSACTION}');
          await db.execute(
            'ALTER TABLE ${DBConstants.TRANSACTION}_new RENAME TO ${DBConstants.TRANSACTION}',
          );
          await db.execute('DROP TABLE IF EXISTS organizations');
        }
        if (oldVersion < 4) {
          await db.execute(_sqlCreateBudgetMonths);
          await db.execute(_sqlCreateBudgetLines);
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE ${DBConstants.BUDGET_LINE} ADD COLUMN category TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE ${DBConstants.TRANSACTION} ADD COLUMN entryCurrency TEXT NOT NULL DEFAULT 'lcy'",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.TRANSACTION} ADD COLUMN entryAmount INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "UPDATE ${DBConstants.TRANSACTION} SET entryAmount = amount WHERE entryAmount = 0 OR entryAmount IS NULL",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.BUDGET_LINE} ADD COLUMN entryCurrency TEXT NOT NULL DEFAULT 'lcy'",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.BUDGET_LINE} ADD COLUMN entryAmount INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "UPDATE ${DBConstants.BUDGET_LINE} SET entryAmount = planned_amount WHERE entryAmount = 0 OR entryAmount IS NULL",
          );
        }
        if (oldVersion < 7) {
          await db.execute(_sqlCreateInvestmentHoldings);
          await db.execute(_sqlCreateInvestmentLots);
          await db.execute(_sqlCreateInvestmentPrices);
          await db.execute(_sqlCreateInvestmentCash);
          await db.insert(DBConstants.INVESTMENT_CASH, <String, Object?>{
            'id': 1,
            'balance_minor': 0,
            'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
          });
        }
        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE ${DBConstants.INVESTMENT_LOT} ADD COLUMN purchase_price_minor_per_share INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE ${DBConstants.INVESTMENT_PRICE} ADD COLUMN as_of_day INTEGER NOT NULL DEFAULT 0',
          );
          final List<Map<String, Object?>> priceRows = await db.query(DBConstants.INVESTMENT_PRICE);
          final Batch batch = db.batch();
          for (final Map<String, Object?> row in priceRows) {
            final Object? id = row['id'];
            final Object? ms = row['as_of_ms'];
            if (id == null || ms == null) continue;
            final int pid = id is int ? id : (id is num ? id.toInt() : int.tryParse('$id') ?? 0);
            final int mms = ms is int ? ms : (ms is num ? ms.toInt() : int.tryParse('$ms') ?? 0);
            if (pid <= 0) continue;
            final int day = encodeLocalYyyymmddFromMs(mms);
            batch.update(
              DBConstants.INVESTMENT_PRICE,
              <String, Object?>{'as_of_day': day},
              where: 'id = ?',
              whereArgs: <Object>[pid],
            );
          }
          await batch.commit(noResult: true);
        }
        if (oldVersion < 9) {
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_LOT} ADD COLUMN purchase_entry_currency TEXT NOT NULL DEFAULT 'lcy'",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_LOT} ADD COLUMN purchase_price_entry_minor INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "UPDATE ${DBConstants.INVESTMENT_LOT} SET purchase_price_entry_minor = purchase_price_minor_per_share WHERE purchase_price_entry_minor = 0 AND purchase_price_minor_per_share != 0",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_PRICE} ADD COLUMN entry_currency TEXT NOT NULL DEFAULT 'lcy'",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_PRICE} ADD COLUMN price_entry_minor INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "UPDATE ${DBConstants.INVESTMENT_PRICE} SET price_entry_minor = price_minor_per_share WHERE price_entry_minor = 0 AND price_minor_per_share != 0",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_CASH} ADD COLUMN balance_entry_currency TEXT NOT NULL DEFAULT 'lcy'",
          );
          await db.execute(
            "ALTER TABLE ${DBConstants.INVESTMENT_CASH} ADD COLUMN balance_entry_minor INTEGER NOT NULL DEFAULT 0",
          );
          await db.execute(
            "UPDATE ${DBConstants.INVESTMENT_CASH} SET balance_entry_minor = balance_minor WHERE id = 1",
          );
        }
        if (oldVersion < 10) {
          await db.execute(_sqlCreateInvestmentOtherAssets);
          try {
            final List<Map<String, Object?>> cashRows = await db.query(
              DBConstants.INVESTMENT_CASH,
              where: 'id = ?',
              whereArgs: <Object>[1],
              limit: 1,
            );
            if (cashRows.isNotEmpty) {
              final Map<String, Object?> c = cashRows.first;
              int bal(Object? v) {
                if (v == null) return 0;
                if (v is int) return v;
                if (v is num) return v.toInt();
                return int.tryParse('$v') ?? 0;
              }

              final int balanceMinor = bal(c['balance_minor']);
              final String ec = '${c['balance_entry_currency'] ?? 'lcy'}'.toLowerCase();
              int entryMinor = bal(c['balance_entry_minor']);
              if (entryMinor == 0 && balanceMinor != 0) {
                entryMinor = balanceMinor;
              }
              final int updatedMs = bal(c['updated_at_ms']);
              if (balanceMinor != 0 || entryMinor != 0) {
                await db.insert(DBConstants.INVESTMENT_OTHER_ASSET, <String, Object?>{
                  'label': 'Cash',
                  'value_lcy_minor': balanceMinor,
                  'entry_currency': ec == 'fcy' ? 'fcy' : 'lcy',
                  'entry_minor': entryMinor,
                  'sort_order': 0,
                  'updated_at_ms': updatedMs > 0 ? updatedMs : DateTime.now().millisecondsSinceEpoch,
                });
              }
            }
          } catch (_) {
            // ignore if legacy table missing
          }
          await db.execute('DROP TABLE IF EXISTS ${DBConstants.INVESTMENT_CASH}');
        }
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

const String _sqlCreateInvestmentCash = '''
CREATE TABLE ${DBConstants.INVESTMENT_CASH}(
  id INTEGER PRIMARY KEY CHECK (id = 1),
  balance_minor INTEGER NOT NULL DEFAULT 0,
  balance_entry_currency TEXT NOT NULL DEFAULT 'lcy',
  balance_entry_minor INTEGER NOT NULL DEFAULT 0,
  updated_at_ms INTEGER NOT NULL DEFAULT 0
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
