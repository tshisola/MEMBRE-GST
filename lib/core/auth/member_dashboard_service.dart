import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import '../../shared/models/member_account_model.dart';
import '../advanced/notifications/local_notification_repository.dart';
import '../database/database_helper.dart';
import '../security/privacy_guard.dart';
import '../services/media_lists_local_repository.dart';

/// Données affichées sur le dashboard membre — sans métadonnées admin.
class MemberDashboardData {
  const MemberDashboardData({
    required this.displayName,
    required this.memberCode,
    required this.department,
    required this.pasteur,
    required this.disciple,
    required this.weekAttendancePercent,
    required this.isHabilite,
    required this.attendanceHistory,
    required this.messages,
    required this.notifications,
    this.role = 'Membre',
    this.qrAvailable = false,
    this.mediaAssignment,
    this.weekSessionCount = 0,
    this.weekPresentCount = 0,
  });

  final String displayName;
  final String memberCode;
  final String department;
  final String pasteur;
  final String disciple;
  final double weekAttendancePercent;
  final bool isHabilite;
  final List<MemberAttendanceEntry> attendanceHistory;
  final List<MemberMessageEntry> messages;
  final List<MemberNotificationEntry> notifications;
  final String role;
  final bool qrAvailable;
  final String? mediaAssignment;
  final int weekSessionCount;
  final int weekPresentCount;

  static MemberDashboardData empty() => const MemberDashboardData(
        displayName: 'Membre IFCM',
        memberCode: '—',
        department: '—',
        pasteur: 'Non assigné',
        disciple: 'Non assigné',
        weekAttendancePercent: 0,
        isHabilite: false,
        attendanceHistory: [],
        messages: [],
        notifications: [],
      );
}

class MemberAttendanceEntry {
  const MemberAttendanceEntry({
    required this.date,
    required this.status,
    required this.sessionType,
  });

  final String date;
  final String status;
  final String sessionType;
}

class MemberMessageEntry {
  const MemberMessageEntry({
    required this.title,
    required this.body,
    required this.date,
  });

  final String title;
  final String body;
  final String date;
}

class MemberNotificationEntry {
  const MemberNotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String date;
  final bool isRead;
}

/// Charge le profil membre depuis SQLite (offline-first).
class MemberDashboardService {
  Future<MemberDashboardData> loadForSession({
    required String accountId,
    required String? memberId,
    required String? departmentId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final accountRows = await db.query(
      AppConstants.tableMemberAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (accountRows.isEmpty) return MemberDashboardData.empty();

    final account = CreatorVisibilityGuard.sanitizeAccount(
      MemberAccount.fromMap(accountRows.first),
    );

    var displayName = account.loginIdentifier;
    var pasteur = 'Non assigné';
    var disciple = 'Non assigné';
    var memberCode = account.loginIdentifier;
    var deptLabel = '—';
    var role = 'Membre';
    var qrAvailable = false;
    String? mediaAssignment;

    final resolvedMemberId = memberId ?? account.memberId;

    if (resolvedMemberId != null && resolvedMemberId.isNotEmpty) {
      final memberRows = await db.query(
        AppConstants.tableMembers,
        where: 'id = ?',
        whereArgs: [resolvedMemberId],
        limit: 1,
      );
      if (memberRows.isNotEmpty) {
        final row = memberRows.first;
        final first = row['first_name'] as String? ?? '';
        final last = row['last_name'] as String? ?? '';
        final full = '$first $last'.trim();
        if (full.isNotEmpty) displayName = full;

        final pastorName = row['pastor_name'] as String? ?? '';
        if (pastorName.trim().isNotEmpty) pasteur = pastorName.trim();

        final discipleName = row['disciple_name'] as String? ?? '';
        if (discipleName.trim().isNotEmpty) disciple = discipleName.trim();

        final code = row['member_code'] as String? ?? '';
        if (code.trim().isNotEmpty) memberCode = code.trim();

        final deptName = row['department_name'] as String? ?? '';
        final deptId = row['department_id'] as String? ?? '';
        deptLabel = deptName.trim().isNotEmpty
            ? deptName.trim()
            : _formatDepartment(deptId);

        final memberRole = row['role'] as String? ?? '';
        if (memberRole.trim().isNotEmpty) role = _formatRole(memberRole);

        final qrData = row['qr_data'] as String? ?? '';
        qrAvailable = qrData.trim().isNotEmpty;

        mediaAssignment = await _loadMediaAssignment(resolvedMemberId);
      }
    }

    if (deptLabel == '—') {
      final dept = account.departmentId ?? departmentId ?? '—';
      deptLabel = _formatDepartment(dept);
    }

    final weekStats = await _weekAttendanceStats(db, resolvedMemberId);
    final weekPercent = weekStats.percent;

    final history = await _loadAttendanceHistory(db, resolvedMemberId);

    final notifications = await _loadNotifications(resolvedMemberId ?? '');

    final isHabilite = account.isActive && weekPercent >= 50;

    return MemberDashboardData(
      displayName: displayName,
      memberCode: memberCode,
      department: deptLabel,
      pasteur: pasteur,
      disciple: disciple,
      weekAttendancePercent: weekPercent,
      isHabilite: isHabilite,
      attendanceHistory: history,
      messages: const [
        MemberMessageEntry(
          title: 'Bienvenue sur ${AppConstants.appName}',
          body: 'Consultez votre présence et vos messages ici.',
          date: 'Récent',
        ),
      ],
      notifications: notifications,
      role: role,
      qrAvailable: qrAvailable,
      mediaAssignment: mediaAssignment,
      weekSessionCount: weekStats.sessions,
      weekPresentCount: weekStats.present,
    );
  }

  Future<String?> _loadMediaAssignment(String memberId) async {
    try {
      final lists = await MediaListsLocalRepository().loadLists();
      for (final list in lists) {
        for (final entry in list.entries) {
          if (entry.memberId != memberId) continue;
          if (entry.mediaRole.trim().isEmpty) continue;
          final date = list.serviceDate.toIso8601String().substring(0, 10);
          return '${entry.mediaRole} · $date';
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatRole(String raw) {
    if (raw.isEmpty) return 'Membre';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<List<MemberNotificationEntry>> _loadNotifications(String memberId) async {
    if (memberId.isEmpty) return [];
    final items = await LocalNotificationRepository.instance.list(
      memberId: memberId,
      limit: 20,
    );
    if (items.isEmpty) return [];
    return items
        .map(
          (n) => MemberNotificationEntry(
            id: n.id,
            title: n.title,
            message: n.message,
            date: n.createdAt.toString().substring(0, 10),
            isRead: n.isRead,
          ),
        )
        .toList();
  }

  String _formatDepartment(String id) {
    if (id.isEmpty || id == '—') return '—';
    return id[0].toUpperCase() + id.substring(1);
  }

  Future<({double percent, int sessions, int present})> _weekAttendanceStats(
    Database db,
    String? memberId,
  ) async {
    if (memberId == null || memberId.isEmpty) {
      return (percent: 0.0, sessions: 0, present: 0);
    }

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().substring(0, 10);

    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'member_id = ? AND session_date >= ?',
      whereArgs: [memberId, weekStartStr],
    );

    if (rows.isEmpty) return (percent: 0.0, sessions: 0, present: 0);

    final present = rows.where((r) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      return status.contains('present') || status.contains('présent');
    }).length;

    final percent = (present / rows.length * 100).clamp(0, 100).toDouble();
    return (percent: percent, sessions: rows.length, present: present);
  }

  Future<List<MemberAttendanceEntry>> _loadAttendanceHistory(
    Database db,
    String? memberId,
  ) async {
    if (memberId == null || memberId.isEmpty) return [];

    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'session_date DESC',
      limit: 10,
    );

    return rows
        .map(
          (r) => MemberAttendanceEntry(
            date: r['session_date'] as String? ?? '—',
            status: r['status'] as String? ?? '—',
            sessionType: r['session_type'] as String? ?? 'Session',
          ),
        )
        .toList();
  }
}
