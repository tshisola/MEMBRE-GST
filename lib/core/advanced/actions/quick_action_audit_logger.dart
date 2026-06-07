import '../models/advanced_models.dart';
import 'auto_fix_action_service.dart';

/// Journalisation des actions rapides — délègue à l'historique existant.
class QuickActionAuditLogger {
  QuickActionAuditLogger._();
  static final QuickActionAuditLogger instance = QuickActionAuditLogger._();

  Future<SmartActionHistoryEntry> record({
    required String actionKey,
    required String label,
    required bool success,
    String? message,
    String? actorId,
    String? actorName,
  }) {
    return SmartActionHistoryService.instance.record(
      actionKey: actionKey,
      label: label,
      success: success,
      message: message,
      actorId: actorId,
      actorName: actorName,
    );
  }
}
