import 'dart:io' as io;
import 'package:balance_sheet/constants.dart';
import 'package:path_provider/path_provider.dart';
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
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, "transaction.db");
    var taskDb = await openDatabase(
      path,
      version: Constants.DB_VERSION,
      onCreate: (Database db, int version) async {
        await db.execute("""
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            date INTEGER NOT NULL,
            category TEXT NOT NULL
          )"""
        );
      },
      // onUpgrade: (Database db, int oldVersion, int newVersion) async {
      //   if (newVersion > oldVersion) {
      //     print('executed');
      //     await db.execute("ALTER TABLE transactions ADD COLUMN category TEXT");
      //   }
      // }
    );
    return taskDb;
  }
}
