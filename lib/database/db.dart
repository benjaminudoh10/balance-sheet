import 'package:balance_sheet/constants/db.dart';
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
