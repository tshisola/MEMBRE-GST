import '../audit/professional_audit_log_service.dart';

/// Journalise les fusions doublons dans l'audit professionnel.
class DuplicateMergeAuditService {
  DuplicateMergeAuditService({ProfessionalAuditLogService? audit})
      : _audit = audit ?? ProfessionalAuditLogService.instance;

  final ProfessionalAuditLogService _audit;

  Future<void> recordMerge({
    required String actorId,
    String? actorName,
    required String primaryId,
    required String secondaryId,
    required String primaryName,
    required String secondaryName,
  }) =>
      _audit.logAction(
        action: 'duplicate_merge',
        actorId: actorId,
        targetId: primaryId,
        metadata: {
          'actor_name': actorName,
          'secondary_id': secondaryId,
          'secondary_name': secondaryName,
          'primary_name': primaryName,
        },
      );
}
