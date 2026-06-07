import 'dart:convert';

import '../../shared/models/department_model.dart';
import '../database/database_helper.dart';
import 'lubumbashi_branding_service.dart';
import 'media_firestore_constants.dart';
import 'media_sync_service.dart';

/// Lecture/écriture listes Média — SQLite local d'abord (offline-first).
class MediaListsLocalRepository {
  MediaListsLocalRepository({
    MediaSyncService? syncService,
  }) : _sync = syncService ??
            MediaSyncService(
              databaseProvider: () => DatabaseHelper.instance.database,
            );

  final MediaSyncService _sync;

  Future<void> ensureSchema() => _sync.ensureSchema();

  Future<List<MediaSundayList>> loadLists({bool manualOnly = false}) async {
    await ensureSchema();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      MediaLocalTables.lists,
      where: 'city = ?',
      whereArgs: [LubumbashiBrandingService.city],
      orderBy: 'updated_at DESC',
    );

    final lists = rows.map((row) {
      final payload =
          jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
      return MediaSundayList.fromMap(payload, id: row['id'] as String);
    }).where((list) {
      if (!manualOnly) return true;
      return list.isManual;
    }).toList();

    lists.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return lists;
  }

  Future<void> saveList(MediaSundayList list, {Map<String, dynamic>? extra}) async {
    final payload = {
      ...list.toMap(),
      if (extra != null) ...extra,
      'city': LubumbashiBrandingService.city,
    };
    await _sync.saveLocalRecord(
      table: MediaLocalTables.lists,
      id: list.id,
      payload: payload,
    );
  }
}
