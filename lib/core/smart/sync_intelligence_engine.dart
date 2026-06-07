import '../../../app/constants.dart';
import '../sync/offline_sync_queue.dart';
import '../../../features/members/data/local_member_repository.dart';
import 'models/smart_models.dart';

/// Analyse la santé de la synchronisation.
class SyncIntelligenceEngine {
  SyncIntelligenceEngine({
    OfflineSyncQueue? queue,
    LocalMemberRepository? members,
  })  : _queue = queue ?? OfflineSyncQueue(),
        _members = members ?? LocalMemberRepository();

  final OfflineSyncQueue _queue;
  final LocalMemberRepository _members;

  Future<SyncHealthReport> analyze() async {
    final pending = await _queue.countByStatus(AppConstants.queueStatusPending);
    final failed = await _queue.countByStatus(AppConstants.queueStatusFailed);
    final localOnly =
        await _members.countBySyncStatus(AppConstants.syncStatusLocal);
    final pendingMembers =
        await _members.countBySyncStatus(AppConstants.syncStatusPending);
    final errorMembers =
        await _members.countBySyncStatus(AppConstants.syncStatusError);

    final issues = <SmartIssue>[];

    if (pending > 0) {
      issues.add(SmartIssue(
        id: 'sync_queue_pending',
        title: '$pending action(s) en attente',
        message: 'La synchronisation reprendra automatiquement.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.warning,
        suggestedAction: SmartIssueAction.refreshSync,
      ));
    }
    if (failed > 0) {
      issues.add(SmartIssue(
        id: 'sync_queue_failed',
        title: '$failed action(s) bloquée(s)',
        message: 'Une intervention peut être nécessaire.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.critical,
        suggestedAction: SmartIssueAction.refreshSync,
        detailRoute: '/admin/sync/pending',
      ));
    }
    if (localOnly > 0) {
      issues.add(SmartIssue(
        id: 'sync_local_only',
        title: '$localOnly membre(s) locaux uniquement',
        message: 'En attente de mise en ligne.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.info,
      ));
    }
    if (errorMembers > 0) {
      issues.add(SmartIssue(
        id: 'sync_member_errors',
        title: '$errorMembers membre(s) en erreur de sync',
        message: 'Consultez la synchronisation pour plus de détails.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.warning,
        detailRoute: '/admin/sync',
      ));
    }

    final penalty =
        pending * 2 + failed * 10 + localOnly * 3 + errorMembers * 5;
    final score = (100 - penalty).clamp(0, 100);

    return SyncHealthReport(
      score: score,
      pendingCount: pending + pendingMembers,
      failedCount: failed,
      localOnlyCount: localOnly,
      issues: issues,
    );
  }
}

typedef SyncProblemDetector = SyncIntelligenceEngine;

/// Réparation automatique sync.
class AutoSyncRepairService {
  AutoSyncRepairService({OfflineSyncQueue? queue})
      : _queue = queue ?? OfflineSyncQueue();

  final OfflineSyncQueue _queue;

  Future<int> retryFailed() async {
    final failed = await _queue.listFailedAboveMax();
    var retried = 0;
    for (final item in failed) {
      try {
        await _queue.markPendingRetry(item.id, 'retry');
        retried++;
      } catch (_) {}
    }
    return retried;
  }
}

typedef SyncHealthScoreCard = SyncHealthReport;
