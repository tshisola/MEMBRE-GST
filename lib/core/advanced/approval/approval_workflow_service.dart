import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../models/advanced_models.dart';

/// Workflow de validation pour actions sensibles.
class ApprovalWorkflowService {
  ApprovalWorkflowService._();
  static final ApprovalWorkflowService instance = ApprovalWorkflowService._();

  final _uuid = const Uuid();

  Future<ApprovalRequestItem> submit({
    required ApprovalActionType actionType,
    required String targetLabel,
    String? targetId,
    String? requestedBy,
    String? requestedByName,
    String? reason,
    AuditRiskLevel riskLevel = AuditRiskLevel.medium,
  }) async {
    final now = DateTime.now();
    final item = ApprovalRequestItem(
      id: _uuid.v4(),
      actionType: actionType,
      targetId: targetId,
      targetLabel: targetLabel,
      status: ApprovalStatus.pending,
      requestedBy: requestedBy,
      requestedByName: requestedByName,
      reason: reason,
      riskLevel: riskLevel,
      createdAt: now,
      updatedAt: now,
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert(AppConstants.tableApprovalRequests, {
      'id': item.id,
      'action_type': actionType.name,
      'target_id': targetId,
      'target_label': targetLabel,
      'requested_by': requestedBy,
      'requested_by_name': requestedByName,
      'status': item.status.name,
      'reason': reason,
      'risk_level': riskLevel.name,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return item;
  }

  Future<List<ApprovalRequestItem>> listPending({int limit = 50}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableApprovalRequests,
      where: 'status = ?',
      whereArgs: [ApprovalStatus.pending.name],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<ApprovalRequestItem>> listAll({int limit = 100}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableApprovalRequests,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> approve({
    required String id,
    required String decidedBy,
    String? decisionReason,
  }) =>
      _decide(id, ApprovalStatus.approved, decidedBy, decisionReason);

  Future<void> reject({
    required String id,
    required String decidedBy,
    required String decisionReason,
  }) =>
      _decide(id, ApprovalStatus.rejected, decidedBy, decisionReason);

  Future<void> _decide(
    String id,
    ApprovalStatus status,
    String decidedBy,
    String? decisionReason,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableApprovalRequests,
      {
        'status': status.name,
        'decided_by': decidedBy,
        'decision_reason': decisionReason,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ApprovalRequestItem _fromRow(Map<String, Object?> row) {
    return ApprovalRequestItem(
      id: row['id'] as String,
      actionType: ApprovalActionType.values.firstWhere(
        (a) => a.name == row['action_type'],
        orElse: () => ApprovalActionType.deleteMember,
      ),
      targetId: row['target_id'] as String?,
      targetLabel: row['target_label'] as String,
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      requestedBy: row['requested_by'] as String?,
      requestedByName: row['requested_by_name'] as String?,
      reason: row['reason'] as String?,
      decisionReason: row['decision_reason'] as String?,
      decidedBy: row['decided_by'] as String?,
      riskLevel: AuditRiskLevel.values.firstWhere(
        (r) => r.name == row['risk_level'],
        orElse: () => AuditRiskLevel.medium,
      ),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Valide si une action sensible nécessite approbation.
class SensitiveActionValidator {
  static bool requiresApproval(ApprovalActionType type) {
    switch (type) {
      case ApprovalActionType.deleteMember:
      case ApprovalActionType.changeRole:
      case ApprovalActionType.deleteList:
      case ApprovalActionType.changeQrCode:
      case ApprovalActionType.restoreMember:
      case ApprovalActionType.publishReport:
        return true;
      case ApprovalActionType.activateGoogle:
        return false;
    }
  }

  static AuditRiskLevel riskFor(ApprovalActionType type) {
    switch (type) {
      case ApprovalActionType.deleteMember:
      case ApprovalActionType.deleteList:
        return AuditRiskLevel.high;
      case ApprovalActionType.changeRole:
      case ApprovalActionType.changeQrCode:
      case ApprovalActionType.restoreMember:
        return AuditRiskLevel.medium;
      case ApprovalActionType.publishReport:
      case ApprovalActionType.activateGoogle:
        return AuditRiskLevel.low;
    }
  }
}
