import 'admin_recovery_orchestrator.dart';

/// Récupération du compte Verdick Yav — délègue à l'orchestrateur.
class AdminOwnerRecoveryService {
  AdminOwnerRecoveryService({AdminRecoveryOrchestrator? orchestrator})
      : _orchestrator = orchestrator ?? AdminRecoveryOrchestrator();

  final AdminRecoveryOrchestrator _orchestrator;

  Future<OwnerRecoveryStatus> evaluate() async {
    final report = await _orchestrator.evaluate();
    if (!report.needsRecovery) {
      return const OwnerRecoveryStatus(needsRecovery: false);
    }
    OwnerRecoveryReason? reason;
    if (!report.existsLocally) {
      reason = OwnerRecoveryReason.noOwner;
    } else if (report.isLockedLocally) {
      reason = OwnerRecoveryReason.ownerLocked;
    } else if (!report.isActiveLocally) {
      reason = OwnerRecoveryReason.ownerInactive;
    }
    return OwnerRecoveryStatus(
      needsRecovery: true,
      reason: reason,
      ownerAccountId: null,
    );
  }

  Future<({String temporaryPassword, String accountId})> restoreOwner({
    required String actorLabel,
  }) async {
    final result = await _orchestrator.restoreVerdickOwner(actorId: actorLabel);
    if (!result.success || result.temporaryPassword == null) {
      throw StateError('recovery_failed');
    }
    return (
      temporaryPassword: result.temporaryPassword!,
      accountId: AdminRecoveryOrchestrator.ownerEmail,
    );
  }
}

enum OwnerRecoveryReason {
  noOwner,
  ownerLocked,
  ownerInactive,
}

class OwnerRecoveryStatus {
  const OwnerRecoveryStatus({
    required this.needsRecovery,
    this.reason,
    this.ownerAccountId,
  });

  final bool needsRecovery;
  final OwnerRecoveryReason? reason;
  final String? ownerAccountId;
}

typedef AdminRecoveryService = AdminOwnerRecoveryService;
