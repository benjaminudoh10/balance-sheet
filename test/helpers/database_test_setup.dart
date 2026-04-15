import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once in [setUpAll] before any code touches [AppDb].
void initializeSqfliteFfiForTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Deletes the app DB file and clears the singleton so the next open is clean.
Future<void> resetAppDatabaseFile() async {
  await AppDb().closeForTesting();
  final String path = p.join(await getDatabasesPath(), DBConstants.DB_NAME);
  await databaseFactory.deleteDatabase(path);
}
