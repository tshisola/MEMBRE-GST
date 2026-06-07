import 'dart:convert';

import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../security/sensitive_action_logger.dart';
import '../models/advanced_models.dart';
import '../pdf/advanced_pdf_template.dart';
import 'package:printing/printing.dart';

/// Journal d'audit professionnel avec filtres avancés.
class ProfessionalAuditLogService {
  ProfessionalAuditLogService._();
  static final ProfessionalAuditLogService instance =
      ProfessionalAuditLogService._();

  Future<List<AuditLogEntry>> list({
    DateTime? from,
    DateTime? to,
    String? actorId,
    String? actionContains,
    String? module,
    AuditRiskLevel? minRisk,
    int limit = 200,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableAuditLogs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows
        .map((r) {
          final action = r['action'] as String? ?? '';
          return AuditLogEntry(
            id: r['id'] as String,
            action: action,
            actorId: r['actor_id'] as String?,
            actorName: r['actor_name'] as String?,
            targetId: r['target_id'] as String?,
            module: _moduleFor(action),
            riskLevel: _riskFor(action),
            metadata: _parseMeta(r['metadata_json'] as String?),
            createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
          );
        })
        .where((e) {
          if (from != null && e.createdAt.isBefore(from)) return false;
          if (to != null && e.createdAt.isAfter(to)) return false;
          if (actorId != null && e.actorId != actorId) return false;
          if (actionContains != null &&
              !e.action.toLowerCase().contains(actionContains.toLowerCase())) {
            return false;
          }
          if (module != null && e.module != module) return false;
          if (minRisk != null && e.riskLevel.index < minRisk.index) {
            return false;
          }
          return true;
        })
        .toList();
  }

  Future<void> logAction({
    required String action,
    String? actorId,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) =>
      SensitiveActionLogger.log(
        action: action,
        actorId: actorId,
        targetId: targetId,
        metadata: metadata,
      );

  String? _moduleFor(String action) {
    if (action.contains('member')) return 'Membres';
    if (action.contains('pointage') || action.contains('attendance')) {
      return 'Pointage';
    }
    if (action.contains('sync')) return 'Synchronisation';
    if (action.contains('list')) return 'Listes';
    if (action.contains('smart')) return 'Intelligence';
    if (action.contains('account')) return 'Comptes';
    return 'Général';
  }

  AuditRiskLevel _riskFor(String action) {
    if (action.contains('delete') || action.contains('permanent')) {
      return AuditRiskLevel.high;
    }
    if (action.contains('restore') || action.contains('role')) {
      return AuditRiskLevel.medium;
    }
    return AuditRiskLevel.low;
  }

  Map<String, dynamic>? _parseMeta(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Export PDF du journal d'audit.
class AuditExportPdfService {
  Future<void> share(List<AuditLogEntry> entries) async {
    final template = AdvancedPdfTemplate();
    final doc = await template.buildSmartReport(
      reportTitle: 'Journal d\'audit',
      subtitle: '${entries.length} entrée(s)',
      headers: ['Date', 'Action', 'Module', 'Risque'],
      rows: entries
          .take(100)
          .map(
            (e) => [
              e.createdAt.toIso8601String().substring(0, 16),
              e.action,
              e.module ?? '—',
              e.riskLevel.name,
            ],
          )
          .toList(),
      stats: {'Entrées': entries.length},
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'audit_media_lubumbashi.pdf',
    );
  }
}
