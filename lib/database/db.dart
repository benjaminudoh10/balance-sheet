import 'package:balance_sheet/constants/db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static final AppDb _instance = new AppDb.internal();

  factory AppDb() => _instance;
  static Database _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
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
            FOREIGN KEY(contactId) REFERENCES ${DBConstants.CONTACT}(id)
          )"""
        );
        await db.execute("""
          CREATE TABLE ${DBConstants.CONTACT}(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )"""
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (newVersion > oldVersion) {
          await db.execute("""
            CREATE TABLE ${DBConstants.ORGANIZATION}(
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL
            )"""
          );
          await db.execute("""
            INSERT INTO ${DBConstants.ORGANIZATION} (id, name) VALUES (1, 'Personal')"""
          );
          await db.execute("""
            ALTER TABLE ${DBConstants.TRANSACTION} ADD organizationId INTEGER NOT NULL DEFAULT 1"""
          );
        }
      }
    );
    return taskDb;
  }
}
