import '../../performance/background_sync_after_action.dart';
import '../models/advanced_models.dart';
import 'auto_fix_action_service.dart';
import 'quick_action_audit_logger.dart';

/// Exécute les actions rapides intelligentes avec audit et sync automatique.
class QuickActionService {
  QuickActionService({AutoFixActionService? autoFix})
      : _autoFix = autoFix ?? AutoFixActionService();

  final AutoFixActionService _autoFix;
  final _audit = QuickActionAuditLogger.instance;

  Future<SmartActionHistoryEntry> run(
    String key, {
    String? actorId,
    String? actorName,
    String? responsible,
  }) async {
    SmartActionHistoryEntry entry;
    switch (key) {
      case 'fix_invisible_pointage':
        entry = await _autoFix.fixInvisiblePointage(
          actorId: actorId,
          actorName: actorName,
        );
      case 'generate_sunday_lists':
        entry = await _autoFix.generateSundayLists(
          actorId: actorId,
          actorName: actorName,
        );
      case 'verify_qr_codes':
        entry = await _autoFix.verifyQrCodes(
          actorId: actorId,
          actorName: actorName,
        );
      case 'fix_incomplete_lists':
        entry = await _autoFix.fixIncompleteLists(
          actorId: actorId,
          actorName: actorName,
        );
      case 'retry_sync':
        entry = await _autoFix.retrySync(
          actorId: actorId,
          actorName: actorName,
        );
      case 'verify_deleted_members':
        entry = await _autoFix.verifyDeletedMembers(
          actorId: actorId,
          actorName: actorName,
        );
      case 'prepare_exports':
        entry = await _autoFix.prepareExports(
          actorId: actorId,
          actorName: actorName,
          responsible: responsible,
        );
      case 'merge_duplicates':
        entry = await _audit.record(
          actionKey: 'merge_duplicates',
          label: 'Fusionner doublons',
          success: true,
          message: 'Ouvrez Fusion doublons pour valider chaque fusion.',
          actorId: actorId,
          actorName: actorName,
        );
      case 'verify_media_requests':
        entry = await _audit.record(
          actionKey: 'verify_media_requests',
          label: 'Vérifier demandes Google',
          success: true,
          message: 'Consultez les demandes Média en attente.',
          actorId: actorId,
          actorName: actorName,
        );
      case 'preview_last_pdf':
        entry = await _audit.record(
          actionKey: 'preview_last_pdf',
          label: 'Prévisualiser dernier PDF',
          success: true,
          message: 'Aperçu du dernier document généré.',
          actorId: actorId,
          actorName: actorName,
        );
      case 'open_diagnostic':
        entry = await _audit.record(
          actionKey: 'open_diagnostic',
          label: 'Ouvrir Diagnostic Admin',
          success: true,
          message: 'Diagnostic ouvert.',
          actorId: actorId,
          actorName: actorName,
        );
      case 'export_report':
        entry = await _autoFix.exportIntelligentReport(
          actorId: actorId,
          actorName: actorName,
          responsible: responsible,
        );
      default:
        entry = await _audit.record(
          actionKey: key,
          label: key,
          success: false,
          message: 'Action indisponible.',
          actorId: actorId,
          actorName: actorName,
        );
    }
    await BackgroundSyncAfterAction.run(trigger: key);
    return entry;
  }
}
