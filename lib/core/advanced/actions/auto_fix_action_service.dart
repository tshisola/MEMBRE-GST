import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../security/sensitive_action_logger.dart';
import '../../smart/data_quality_engine.dart';
import '../../smart/pointage_visibility_checker.dart';
import '../../smart/planning/smart_media_team_planner.dart';
import '../../smart/planning/sunday_list_persistence_service.dart';
import '../../smart/smart_auto_fix_service.dart';
import '../../sync/member_sync_manager.dart';
import '../models/advanced_models.dart';
import '../notifications/push_notification_service.dart';
import '../pdf/smart_pdf_report_service.dart';
import '../../sync/manual_sync_refresh_service.dart';

/// Actions rapides intelligentes avec confirmation et audit.
class AutoFixActionService {
  AutoFixActionService({
    PointageAutoRepairService? pointage,
    DataRepairService? data,
    SmartAutoFixService? autoFix,
    SmartMediaTeamPlanner? planner,
    SmartPdfReportService? pdf,
    SmartActionHistoryService? history,
  })  : _pointage = pointage ?? PointageAutoRepairService(),
        _data = data ?? DataRepairService(),
        _autoFix = autoFix ?? SmartAutoFixService(),
        _planner = planner ?? SmartMediaTeamPlanner(),
        _pdf = pdf ?? SmartPdfReportService(),
        _history = history ?? SmartActionHistoryService.instance;

  final PointageAutoRepairService _pointage;
  final DataRepairService _data;
  final SmartAutoFixService _autoFix;
  final SmartMediaTeamPlanner _planner;
  final SmartPdfReportService _pdf;
  final SmartActionHistoryService _history;

  Future<SmartActionHistoryEntry> fixInvisiblePointage({
    String? actorId,
    String? actorName,
  }) async {
    final result = await _pointage.repairAll();
    return _history.record(
      actionKey: 'fix_invisible_pointage',
      label: 'Corriger membres invisibles au pointage',
      success: result.success,
      message: result.message,
      actorId: actorId,
      actorName: actorName,
    );
  }

  Future<SmartActionHistoryEntry> generateSundayLists({
    String? actorId,
    String? actorName,
  }) async {
    try {
      final plan = await _planner.generate();
      await SundayListPersistenceService().persistPlan(plan);
      await PushNotificationService.instance.rules.onSundayListGenerated();
      return _history.record(
        actionKey: 'generate_sunday_lists',
        label: 'Générer listes Média du dimanche',
        success: true,
        message: 'Équipe du dimanche proposée.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (e) {
      return _history.record(
        actionKey: 'generate_sunday_lists',
        label: 'Générer listes Média du dimanche',
        success: false,
        message: 'Action impossible pour le moment.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> retrySync({
    String? actorId,
    String? actorName,
  }) async {
    try {
      await MemberSyncManager().syncNow();
      return _history.record(
        actionKey: 'retry_sync',
        label: 'Relancer synchronisation',
        success: true,
        message: 'Synchronisation relancée.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'retry_sync',
        label: 'Relancer synchronisation',
        success: false,
        message: 'Synchronisation en cours — réessayez plus tard.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> fixMissingData({
    String? actorId,
    String? actorName,
  }) async {
    final result = await _data.repairMissingDepartments();
    return _history.record(
      actionKey: 'fix_missing_data',
      label: 'Corriger données manquantes',
      success: result.fixedCount > 0,
      message: '${result.fixedCount} correction(s) appliquée(s).',
      actorId: actorId,
      actorName: actorName,
    );
  }

  Future<SmartActionHistoryEntry> cleanDuplicates({
    String? actorId,
    String? actorName,
  }) async {
    final result = await _autoFix.fixAll();
    return _history.record(
      actionKey: 'clean_duplicates',
      label: 'Nettoyer doublons',
      success: result.fixedCount > 0,
      message: result.message,
      actorId: actorId,
      actorName: actorName,
    );
  }

  Future<SmartActionHistoryEntry> exportIntelligentReport({
    String? actorId,
    String? actorName,
    String? responsible,
  }) async {
    try {
      await _pdf.shareReport(
        SmartReportType.mediaIntelligence,
        responsible: responsible,
      );
      await PushNotificationService.instance.rules.onReportAvailable();
      return _history.record(
        actionKey: 'export_report',
        label: 'Exporter rapport intelligent',
        success: true,
        message: 'Rapport exporté.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'export_report',
        label: 'Exporter rapport intelligent',
        success: false,
        message: 'Export impossible pour le moment.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> verifyQrCodes({
    String? actorId,
    String? actorName,
  }) async {
    try {
      await PointageCacheRefresher().refresh();
      final quality = await DataQualityEngine().analyze();
      final missing = quality.missingQrCount;
      return _history.record(
        actionKey: 'verify_qr_codes',
        label: 'Vérifier les QR Codes',
        success: true,
        message: missing == 0
            ? 'Tous les QR Codes sont en ordre.'
            : '$missing QR Code(s) à compléter.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'verify_qr_codes',
        label: 'Vérifier les QR Codes',
        success: false,
        message: 'Vérification en cours — réessayez dans un instant.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> fixIncompleteLists({
    String? actorId,
    String? actorName,
  }) async {
    try {
      final plan = await _planner.generate();
      await SundayListPersistenceService().persistPlan(plan);
      return _history.record(
        actionKey: 'fix_incomplete_lists',
        label: 'Corriger listes incomplètes',
        success: true,
        message: 'Listes Média mises à jour.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'fix_incomplete_lists',
        label: 'Corriger listes incomplètes',
        success: false,
        message: 'Mise à jour impossible pour le moment.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> verifyAttendance({
    String? actorId,
    String? actorName,
  }) async {
    try {
      await PointageCacheRefresher().refresh();
      return _history.record(
        actionKey: 'verify_attendance',
        label: 'Vérifier les présences',
        success: true,
        message: 'Présences vérifiées et mises à jour.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'verify_attendance',
        label: 'Vérifier les présences',
        success: false,
        message: 'Vérification en cours — réessayez dans un instant.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> verifyInactiveAccounts({
    String? actorId,
    String? actorName,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMemberAccounts} '
        'WHERE is_active = 0',
      );
      final count = rows.first['c'] as int? ?? 0;
      return _history.record(
        actionKey: 'verify_inactive_accounts',
        label: 'Vérifier comptes non activés',
        success: true,
        message: count == 0
            ? 'Tous les comptes sont activés.'
            : '$count compte(s) en attente d\'activation.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'verify_inactive_accounts',
        label: 'Vérifier comptes non activés',
        success: false,
        message: 'Vérification en cours — réessayez dans un instant.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> verifyDeletedMembers({
    String? actorId,
    String? actorName,
  }) async {
    final result = await _pointage.repairAll();
    return _history.record(
      actionKey: 'verify_deleted_members',
      label: 'Vérifier membres supprimés',
      success: result.success,
      message: result.message,
      actorId: actorId,
      actorName: actorName,
    );
  }

  Future<SmartActionHistoryEntry> prepareExports({
    String? actorId,
    String? actorName,
    String? responsible,
  }) async {
    try {
      await _pdf.buildReport(
        SmartReportType.dataQuality,
        responsible: responsible,
      );
      return _history.record(
        actionKey: 'prepare_exports',
        label: 'Préparer exports PDF/CSV',
        success: true,
        message: 'Rapports prêts à exporter.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'prepare_exports',
        label: 'Préparer exports PDF/CSV',
        success: false,
        message: 'Préparation en cours — réessayez dans un instant.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<SmartActionHistoryEntry> retryAutoUpdate({
    String? actorId,
    String? actorName,
  }) async {
    try {
      await ManualSyncRefreshService().refresh();
      await MemberSyncManager().syncNow();
      return _history.record(
        actionKey: 'retry_auto_update',
        label: 'Relancer mise à jour automatique',
        success: true,
        message: 'Mise à jour automatique relancée.',
        actorId: actorId,
        actorName: actorName,
      );
    } catch (_) {
      return _history.record(
        actionKey: 'retry_auto_update',
        label: 'Relancer mise à jour automatique',
        success: false,
        message: 'Mise à jour en cours — vos données seront synchronisées.',
        actorId: actorId,
        actorName: actorName,
      );
    }
  }

  Future<void> auditAction(String action, {String? actorId, String? targetId}) {
    return SensitiveActionLogger.log(
      action: action,
      actorId: actorId,
      targetId: targetId,
    );
  }
}

class SmartQuickActionsPanel {
  SmartQuickActionsPanel({AutoFixActionService? service})
      : _service = service ?? AutoFixActionService();

  final AutoFixActionService _service;

  static const actions = [
    ('fix_invisible_pointage', 'Corriger membres invisibles au pointage', true),
    ('merge_duplicates', 'Fusionner doublons', true),
    ('generate_sunday_lists', 'Générer listes Média du dimanche', false),
    ('preview_last_pdf', 'Prévisualiser dernier PDF', false),
    ('verify_qr_codes', 'Vérifier QR Codes', false),
    ('fix_incomplete_lists', 'Vérifier listes incomplètes', false),
    ('retry_sync', 'Relancer synchronisation', false),
    ('verify_media_requests', 'Vérifier demandes Google', false),
    ('verify_deleted_members', 'Vérifier membres supprimés', false),
    ('prepare_exports', 'Préparer rapport intelligent', false),
    ('open_diagnostic', 'Ouvrir Diagnostic Admin', false),
  ];

  AutoFixActionService get service => _service;
}

typedef SmartActionPanel = SmartQuickActionsPanel;
typedef SmartActionExecutor = AutoFixActionService;

/// Historique des actions rapides.
class SmartActionHistoryService {
  SmartActionHistoryService._();
  static final SmartActionHistoryService instance = SmartActionHistoryService._();

  final _uuid = const Uuid();

  Future<SmartActionHistoryEntry> record({
    required String actionKey,
    required String label,
    required bool success,
    String? message,
    String? actorId,
    String? actorName,
  }) async {
    final entry = SmartActionHistoryEntry(
      id: _uuid.v4(),
      actionKey: actionKey,
      label: label,
      success: success,
      message: message,
      actorId: actorId,
      actorName: actorName,
      createdAt: DateTime.now(),
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert(AppConstants.tableSmartActionHistory, {
      'id': entry.id,
      'action_key': entry.actionKey,
      'label': entry.label,
      'success': success ? 1 : 0,
      'message': message,
      'actor_id': actorId,
      'actor_name': actorName,
      'created_at': entry.createdAt.toIso8601String(),
    });
    await SensitiveActionLogger.log(
      action: 'smart_action_$actionKey',
      actorId: actorId,
      metadata: {'success': success, 'label': label},
    );
    return entry;
  }

  Future<List<SmartActionHistoryEntry>> listRecent({int limit = 50}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableSmartActionHistory,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (r) => SmartActionHistoryEntry(
            id: r['id'] as String,
            actionKey: r['action_key'] as String,
            label: r['label'] as String,
            success: (r['success'] as int? ?? 0) == 1,
            message: r['message'] as String?,
            actorId: r['actor_id'] as String?,
            actorName: r['actor_name'] as String?,
            createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }
}
