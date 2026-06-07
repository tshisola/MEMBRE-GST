import '../../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import 'models/smart_models.dart';
import 'pointage_visibility_checker.dart';
import 'data_quality_engine.dart';
import 'sync_intelligence_engine.dart';
import '../sync/offline_sync_queue.dart';

/// Détecte automatiquement les problèmes dans l'application.
class SmartIssueDetector {
  SmartIssueDetector({
    LocalMemberRepository? memberRepo,
    PointageVisibilityChecker? pointageChecker,
    DataQualityEngine? dataQuality,
    SyncIntelligenceEngine? syncEngine,
    OfflineSyncQueue? syncQueue,
  })  : _members = memberRepo ?? LocalMemberRepository(),
        _pointage = pointageChecker ?? PointageVisibilityChecker(),
        _dataQuality = dataQuality ?? DataQualityEngine(),
        _sync = syncEngine ?? SyncIntelligenceEngine(),
        _queue = syncQueue ?? OfflineSyncQueue();

  final LocalMemberRepository _members;
  final PointageVisibilityChecker _pointage;
  final DataQualityEngine _dataQuality;
  final SyncIntelligenceEngine _sync;
  final OfflineSyncQueue _queue;

  Future<List<SmartIssue>> detectAll() async {
    final issues = <SmartIssue>[];

    final active = await _members.listActive();
    final deleted = await _members.listDeleted();
    final pointageReport = await _pointage.check();
    final quality = await _dataQuality.analyze();
    final syncHealth = await _sync.analyze();
    final pending = await _queue.countByStatus(AppConstants.queueStatusPending);

    for (final inv in pointageReport.invisibleMembers) {
      issues.add(SmartIssue(
        id: 'pointage_invisible_${inv.memberId}',
        title: 'Membre absent du pointage',
        message: '${inv.name} : ${inv.reason}',
        category: SmartIssueCategory.pointage,
        severity: SmartIssueSeverity.warning,
        memberId: inv.memberId,
        memberName: inv.name,
        autoFixable: inv.repairable,
        suggestedAction: SmartIssueAction.autoFix,
        detailRoute: '/smart/pointage-problems',
      ));
    }

    if (pointageReport.invisibleMembers.isNotEmpty) {
      issues.add(SmartIssue(
        id: 'pointage_invisible_summary',
        title:
            '${pointageReport.invisibleMembers.length} membre(s) n\'apparaissent pas au pointage',
        message: 'Des membres actifs ne sont pas visibles côté pointage.',
        category: SmartIssueCategory.pointage,
        severity: SmartIssueSeverity.critical,
        autoFixable: true,
        suggestedAction: SmartIssueAction.autoFix,
        detailRoute: '/smart/pointage-problems',
      ));
    }

    final noQr = active.where((m) => m.qrData.isEmpty).length;
    if (noQr > 0) {
      issues.add(SmartIssue(
        id: 'missing_qr',
        title: '$noQr membre(s) sans QR Code',
        message: 'Générez ou synchronisez les QR Code manquants.',
        category: SmartIssueCategory.qrCode,
        severity: SmartIssueSeverity.warning,
        detailRoute: '/smart/data-quality',
      ));
    }

    final noDept = active
        .where(
          (m) =>
              (m.departmentId == null || m.departmentId!.isEmpty) &&
              (m.departmentName == null || m.departmentName!.isEmpty),
        )
        .length;
    if (noDept > 0) {
      issues.add(SmartIssue(
        id: 'missing_dept',
        title: '$noDept membre(s) sans département',
        message: 'Attribuez un département pour une meilleure organisation.',
        category: SmartIssueCategory.department,
        severity: SmartIssueSeverity.info,
        detailRoute: '/smart/data-quality',
      ));
    }

    if (pending > 0) {
      issues.add(SmartIssue(
        id: 'sync_pending',
        title: 'Synchronisation en attente',
        message: '$pending action(s) en file d\'attente.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.warning,
        suggestedAction: SmartIssueAction.refreshSync,
        detailRoute: '/admin/sync',
      ));
    }

    if (syncHealth.localOnlyCount > 0) {
      issues.add(SmartIssue(
        id: 'local_only',
        title: '${syncHealth.localOnlyCount} membre(s) locaux uniquement',
        message: 'Ces membres existent en local mais pas encore en ligne.',
        category: SmartIssueCategory.sync,
        severity: SmartIssueSeverity.info,
        suggestedAction: SmartIssueAction.refreshSync,
      ));
    }

    issues.addAll(quality.issues);
    issues.addAll(syncHealth.issues);

    if (deleted.isNotEmpty) {
      final ghostActive = active.where((m) => m.isDeleted).length;
      if (ghostActive > 0) {
        issues.add(SmartIssue(
          id: 'deleted_visible',
          title: 'Membres supprimés encore actifs',
          message: '$ghostActive anomalie(s) détectée(s).',
          category: SmartIssueCategory.dataQuality,
          severity: SmartIssueSeverity.critical,
          autoFixable: true,
        ));
      }
    }

    return issues;
  }
}

/// Alias détecteur manquant pointage.
typedef MissingPointageMemberDetector = PointageVisibilityChecker;
