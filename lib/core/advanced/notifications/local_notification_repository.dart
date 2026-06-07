import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../models/advanced_models.dart';

/// Stockage local des notifications (offline-first).
class LocalNotificationRepository {
  LocalNotificationRepository._();
  static final LocalNotificationRepository instance =
      LocalNotificationRepository._();

  final _uuid = const Uuid();

  Future<void> insert(AppNotificationItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(AppConstants.tableAppNotifications, {
      'id': item.id,
      'title': item.title,
      'message': item.message,
      'category': item.category.name,
      'severity': item.severity.name,
      'target_role': item.targetRole,
      'target_user_id': item.targetUserId,
      'member_id': item.memberId,
      'route': item.route,
      'is_read': item.isRead ? 1 : 0,
      'created_at': item.createdAt.toIso8601String(),
    });
  }

  Future<List<AppNotificationItem>> list({
    String? targetRole,
    String? targetUserId,
    String? memberId,
    AppNotificationCategory? category,
    bool unreadOnly = false,
    int limit = 100,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <Object?>[];

    if (targetRole != null) {
      where.add('(target_role IS NULL OR target_role = ?)');
      args.add(targetRole);
    }
    if (targetUserId != null) {
      where.add('(target_user_id IS NULL OR target_user_id = ?)');
      args.add(targetUserId);
    }
    if (memberId != null) {
      where.add('(member_id IS NULL OR member_id = ?)');
      args.add(memberId);
    }
    if (category != null) {
      where.add('category = ?');
      args.add(category.name);
    }
    if (unreadOnly) {
      where.add('is_read = 0');
    }

    final rows = await db.query(
      AppConstants.tableAppNotifications,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> unreadCount({
    String? targetRole,
    String? targetUserId,
    String? memberId,
  }) async {
    final items = await list(
      targetRole: targetRole,
      targetUserId: targetUserId,
      memberId: memberId,
      unreadOnly: true,
      limit: 500,
    );
    return items.length;
  }

  Future<void> markRead(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableAppNotifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllRead({String? targetRole, String? targetUserId}) async {
    final items = await list(
      targetRole: targetRole,
      targetUserId: targetUserId,
      unreadOnly: true,
      limit: 500,
    );
    for (final n in items) {
      await markRead(n.id);
    }
  }

  AppNotificationItem _fromRow(Map<String, Object?> row) {
    return AppNotificationItem(
      id: row['id'] as String,
      title: row['title'] as String,
      message: row['message'] as String,
      category: AppNotificationCategory.values.firstWhere(
        (c) => c.name == row['category'],
        orElse: () => AppNotificationCategory.general,
      ),
      severity: AppNotificationSeverity.values.firstWhere(
        (s) => s.name == row['severity'],
        orElse: () => AppNotificationSeverity.info,
      ),
      isRead: (row['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      targetRole: row['target_role'] as String?,
      targetUserId: row['target_user_id'] as String?,
      memberId: row['member_id'] as String?,
      route: row['route'] as String?,
    );
  }

  Future<AppNotificationItem> create({
    required String title,
    required String message,
    AppNotificationCategory category = AppNotificationCategory.general,
    AppNotificationSeverity severity = AppNotificationSeverity.info,
    String? targetRole,
    String? targetUserId,
    String? memberId,
    String? route,
  }) async {
    final item = AppNotificationItem(
      id: _uuid.v4(),
      title: title,
      message: message,
      category: category,
      severity: severity,
      isRead: false,
      createdAt: DateTime.now(),
      targetRole: targetRole,
      targetUserId: targetUserId,
      memberId: memberId,
      route: route,
    );
    await insert(item);
    return item;
  }
}
