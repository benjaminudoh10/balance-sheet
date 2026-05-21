import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/constants/app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AutoBackupService {
  static const String taskName = "com.benjaminudoh10.balanced.autoBackup";
  static const String backupsFolder = "backups";
  static const String _autoBackupId = "balanced_auto_backup_periodic";

  /// The logic that runs in the background.
  static Future<bool> performBackup() async {
    try {
      // Initialize GetStorage for the background isolate
      await GetStorage.init();

      // Generate the backup payload
      final String json = await BackupService.exportJsonString();

      // Get the storage directory
      // On Android, we use getExternalStorageDirectory so it's visible in File Manager
      // On iOS, we use getApplicationDocumentsDirectory (made visible in Info.plist)
      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) return false;

      final Directory backupDir = Directory("${baseDir.path}/$backupsFolder");

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Save the file
      final String timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final File file = File("${backupDir.path}/auto_backup_$timestamp.json");

      await file.writeAsString(json);
      debugPrint('Auto-backup saved to: ${file.path}');

      // Cleanup old backups
      final int retentionDays =
          GetStorage().read<int>(AppConstants.AUTO_BACKUP_RETENTION_DAYS_KEY) ??
              7;
      await _cleanupOldBackups(backupDir, retentionDays);

      return true;
    } catch (e, st) {
      debugPrint('AutoBackupService error: $e\n$st');
      return false;
    }
  }

  static Future<void> _cleanupOldBackups(
      Directory backupDir, int retentionDays) async {
    try {
      final List<FileSystemEntity> files = await backupDir.list().toList();
      final DateTime now = DateTime.now();

      for (var file in files) {
        if (file is File &&
            file.path.endsWith(".json") &&
            file.path.contains("auto_backup_")) {
          final DateTime lastModified = await file.lastModified();
          // Keep backups for specified days
          if (now.difference(lastModified).inDays >= retentionDays) {
            await file.delete();
            debugPrint('Deleted old auto-backup: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Schedules the task to run daily at midnight.
  static Future<void> scheduleDaily() async {
    final DateTime now = DateTime.now();
    final DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final Duration initialDelay = nextMidnight.difference(now);

    debugPrint(
        'Scheduling daily backup. Initial delay: ${initialDelay.inMinutes} minutes');

    await Workmanager().registerPeriodicTask(
      _autoBackupId,
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Cancels the daily backup task.
  static Future<void> cancelDaily() async {
    await Workmanager().cancelByUniqueName(_autoBackupId);
    debugPrint('Cancelled daily backup task.');
  }
}
