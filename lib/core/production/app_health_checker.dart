import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_initializer.dart';
import '../sync/offline_sync_queue.dart';

/// État santé application pour diagnostic Admin.
class AppHealthReport {
  const AppHealthReport({
    required this.sqliteOpen,
    required this.firebaseReady,
    required this.pendingLegacyQueue,
    required this.pendingSyncQueue,
    required this.memberCount,
    this.dbPath,
    this.lastError,
  });

  final bool sqliteOpen;
  final bool firebaseReady;
  final int pendingLegacyQueue;
  final int pendingSyncQueue;
  final int memberCount;
  final String? dbPath;
  final String? lastError;
}

class AppHealthChecker {
  AppHealthChecker._();

  static Future<AppHealthReport> check() async {
    var sqliteOpen = false;
    var memberCount = 0;
    String? dbPath;
    String? lastError;

    try {
      final db = await DatabaseHelper.instance.database;
      sqliteOpen = db.isOpen;
      dbPath = db.path;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${AppConstants.tableMembers} WHERE is_deleted = 0 OR is_deleted IS NULL',
        ),
      );
      memberCount = count ?? 0;
    } catch (e) {
      lastError = e.toString();
    }

    var pendingLegacy = 0;
    var pendingSync = 0;
    try {
      final db = await DatabaseHelper.instance.database;
      pendingLegacy = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM ${AppConstants.tableOfflineActionQueue} WHERE status = 'pending'",
            ),
          ) ??
          0;
      pendingSync = (await OfflineSyncQueue().listPending()).length;
    } catch (e) {
      lastError ??= e.toString();
    }

    return AppHealthReport(
      sqliteOpen: sqliteOpen,
      firebaseReady: FirebaseInitializer.isInitialized,
      pendingLegacyQueue: pendingLegacy,
      pendingSyncQueue: pendingSync,
      memberCount: memberCount,
      dbPath: dbPath,
      lastError: lastError,
    );
  }
}
