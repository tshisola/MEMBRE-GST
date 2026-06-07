import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../shared/models/member_account_model.dart';
import '../database/database_helper.dart';
import '../security/sensitive_action_logger.dart';
import '../sync/offline_action_queue.dart';
import '../sync/background_sync_trigger.dart';

/// Manual department lists (non-Media) with alphabetical sorting.
class ManualDepartmentListService {
  ManualDepartmentListService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<DepartmentManualList> createList({
    required String departmentId,
    required String departmentName,
    required String listTitle,
    required List<DepartmentManualListEntry> entries,
    required String createdBy,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final sorted = _sortEntries(entries);

    await db.insert(AppConstants.tableDepartmentManualLists, {
      'id': id,
      'department_id': departmentId,
      'department_name': departmentName,
      'list_title': listTitle,
      'payload_json': _encodeEntries(sorted),
      'created_by': createdBy,
      'city': AppConstants.city,
      'created_at': now,
      'updated_at': now,
    });

    for (final entry in sorted) {
      await db.insert(AppConstants.tableDepartmentManualListEntries, {
        'id': _uuid.v4(),
        'list_id': id,
        'member_id': entry.memberId,
        'member_name': entry.memberName,
        'notes': entry.notes,
        'sort_order': entry.sortOrder,
        'city': AppConstants.city,
        'created_at': now,
      });
    }

    await SensitiveActionLogger.log(
      action: 'create_department_list',
      actorId: createdBy,
      targetId: id,
      metadata: {'department': departmentName, 'title': listTitle},
    );

    final list = DepartmentManualList(
      id: id,
      departmentId: departmentId,
      departmentName: departmentName,
      listTitle: listTitle,
      entries: sorted,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await OfflineActionQueue().enqueue(
      actionType: 'department_list_upsert',
      payload: list.toMap(),
    );

    await BackgroundSyncTrigger().afterLocalWrite(
      entityType: 'department_list',
      entityId: id,
      actionType: AppConstants.syncActionCreateDepartmentList,
      payload: list.toMap(),
    );

    return list;
  }

  Future<List<DepartmentManualList>> listForDepartment(String departmentId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableDepartmentManualLists,
      where: 'department_id = ?',
      whereArgs: [departmentId],
      orderBy: 'list_title COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<DepartmentManualList>> listAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableDepartmentManualLists,
      orderBy: 'department_name COLLATE NOCASE ASC, list_title COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<DepartmentManualList?> getById(String listId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableDepartmentManualLists,
      where: 'id = ?',
      whereArgs: [listId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<DepartmentManualList> addMember({
    required String listId,
    required DepartmentManualListEntry entry,
    required String actorId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final list = await getById(listId);
    if (list == null) throw StateError('Liste introuvable');

    if (list.entries.any((e) => e.memberId == entry.memberId)) {
      throw StateError('Ce membre est déjà dans la liste.');
    }

    final updated = [...list.entries, entry];
    final sorted = _sortEntries(updated);
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableDepartmentManualLists,
      {'payload_json': _encodeEntries(sorted), 'updated_at': now},
      where: 'id = ?',
      whereArgs: [listId],
    );

    await db.insert(AppConstants.tableDepartmentManualListEntries, {
      'id': _uuid.v4(),
      'list_id': listId,
      'member_id': entry.memberId,
      'member_name': entry.memberName,
      'notes': entry.notes,
      'sort_order': entry.sortOrder,
      'city': AppConstants.city,
      'created_at': now,
    });

    return DepartmentManualList(
      id: list.id,
      departmentId: list.departmentId,
      departmentName: list.departmentName,
      listTitle: list.listTitle,
      entries: sorted,
      createdBy: list.createdBy,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<DepartmentManualList> removeMember({
    required String listId,
    required String memberId,
    required String actorId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final list = await getById(listId);
    if (list == null) throw StateError('Liste introuvable');

    final sorted = _sortEntries(
      list.entries.where((e) => e.memberId != memberId).toList(),
    );
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableDepartmentManualLists,
      {'payload_json': _encodeEntries(sorted), 'updated_at': now},
      where: 'id = ?',
      whereArgs: [listId],
    );

    await db.delete(
      AppConstants.tableDepartmentManualListEntries,
      where: 'list_id = ? AND member_id = ?',
      whereArgs: [listId, memberId],
    );

    return DepartmentManualList(
      id: list.id,
      departmentId: list.departmentId,
      departmentName: list.departmentName,
      listTitle: list.listTitle,
      entries: sorted,
      createdBy: list.createdBy,
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteList(String listId, String actorId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      AppConstants.tableDepartmentManualListEntries,
      where: 'list_id = ?',
      whereArgs: [listId],
    );
    await db.delete(
      AppConstants.tableDepartmentManualLists,
      where: 'id = ?',
      whereArgs: [listId],
    );
    await SensitiveActionLogger.log(
      action: 'delete_department_list',
      actorId: actorId,
      targetId: listId,
    );
    await BackgroundSyncTrigger().afterLocalWrite(
      entityType: 'department_list',
      entityId: listId,
      actionType: AppConstants.syncActionDeleteDepartmentList,
    );
  }

  List<DepartmentManualListEntry> _sortEntries(
    List<DepartmentManualListEntry> entries,
  ) {
    final copy = [...entries];
    copy.sort(
      (a, b) => a.memberName.toLowerCase().compareTo(b.memberName.toLowerCase()),
    );
    return [
      for (var i = 0; i < copy.length; i++)
        DepartmentManualListEntry(
          memberId: copy[i].memberId,
          memberName: copy[i].memberName,
          notes: copy[i].notes,
          sortOrder: i,
        ),
    ];
  }

  DepartmentManualList _fromRow(Map<String, Object?> row) {
    final payload = row['payload_json'] as String?;
    final entries = payload != null && payload.isNotEmpty
        ? _decodeEntries(payload)
        : <DepartmentManualListEntry>[];
    return DepartmentManualList(
      id: row['id'] as String,
      departmentId: row['department_id'] as String? ?? '',
      departmentName: row['department_name'] as String? ?? '',
      listTitle: row['list_title'] as String? ?? '',
      entries: entries,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    );
  }

  String _encodeEntries(List<DepartmentManualListEntry> entries) {
    return jsonEncode(entries.map((e) => e.toMap()).toList());
  }

  List<DepartmentManualListEntry> _decodeEntries(String raw) {
    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed
        .map((e) => DepartmentManualListEntry.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }
}

/// Repository wrapper for department lists.
class DepartmentListRepository {
  DepartmentListRepository({ManualDepartmentListService? service})
      : _service = service ?? ManualDepartmentListService();

  final ManualDepartmentListService _service;

  Future<List<DepartmentManualList>> getByDepartment(String id) =>
      _service.listForDepartment(id);

  Future<List<DepartmentManualList>> getAll() => _service.listAll();

  Future<DepartmentManualList?> getById(String id) => _service.getById(id);

  Future<DepartmentManualList> create({
    required String departmentId,
    required String departmentName,
    required String listTitle,
    required List<DepartmentManualListEntry> entries,
    required String createdBy,
  }) =>
      _service.createList(
        departmentId: departmentId,
        departmentName: departmentName,
        listTitle: listTitle,
        entries: entries,
        createdBy: createdBy,
      );
}

/// Controller for department list UI state.
class DepartmentListController {
  DepartmentListController({DepartmentListRepository? repository})
      : _repository = repository ?? DepartmentListRepository();

  final DepartmentListRepository _repository;

  Future<List<DepartmentManualList>> loadForDepartment(String departmentId) =>
      _repository.getByDepartment(departmentId);

  Future<List<DepartmentManualList>> loadAll() => _repository.getAll();
}
