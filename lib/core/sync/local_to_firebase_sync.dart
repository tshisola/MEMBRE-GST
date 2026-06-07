import 'package:firebase_auth/firebase_auth.dart';

import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../firebase/firebase_member_service.dart';
import '../logging/technical_error_repository.dart';
import '../members/member_qr_service.dart';
import '../messaging/user_friendly_error_mapper.dart';
import 'conflict_resolver.dart';
import 'sync_logger.dart';

/// Pushes local members to Firestore.
class LocalToFirebaseSync {
  LocalToFirebaseSync({
    LocalMemberRepository? localRepo,
    FirebaseMemberRepository? firebaseRepo,
    UniqueQrCodeGenerator? qrGen,
  })  : _local = localRepo ?? LocalMemberRepository(),
        _firebase = firebaseRepo ?? FirebaseMemberRepository(),
        _qrGen = qrGen ?? UniqueQrCodeGenerator();

  final LocalMemberRepository _local;
  final FirebaseMemberRepository _firebase;
  final UniqueQrCodeGenerator _qrGen;

  Future<bool> pushMember(String localId) async {
    if (!_firebase.isAvailable) return false;

    if (FirebaseAuth.instance.currentUser == null) {
      await _local.updateSyncStatus(
        localId,
        syncStatus: AppConstants.syncStatusPending,
      );
      SyncLogger.info('MemberSync: session Firebase absente — en attente');
      return false;
    }

    final member = await _local.getById(localId);
    if (member == null) return false;

    await _local.updateSyncStatus(
      localId,
      syncStatus: AppConstants.syncStatusSyncing,
    );

    try {
      final cloudId = await _firebase.upsertMember(member);
      final updatedQr = _qrGen.updateQrDataWithCloudId(member.qrData, cloudId);
      await _local.updateSyncStatus(
        localId,
        syncStatus: AppConstants.syncStatusSynced,
        cloudId: cloudId,
        qrData: updatedQr,
        syncedAt: DateTime.now(),
      );
      SyncLogger.info('Membre synchronisé: ${member.memberCode}');
      return true;
    } catch (e, st) {
      final keepPending = UserFriendlyErrorMapper.isPermissionDenied(e) ||
          UserFriendlyErrorMapper.isNetworkIssue(e);
      await _local.updateSyncStatus(
        localId,
        syncStatus: keepPending
            ? AppConstants.syncStatusPending
            : AppConstants.syncStatusError,
      );
      TechnicalErrorRepository.record(
        source: 'member_push_firebase',
        error: e,
        stack: st,
      );
      SyncLogger.error('Échec sync membre ${member.memberCode}', e);
      return false;
    }
  }

  Future<int> pushAllPending() async {
    final pending = await _local.listActive(
      syncStatus: AppConstants.syncStatusPending,
    );
    final errors = await _local.listActive(
      syncStatus: AppConstants.syncStatusError,
    );
    var count = 0;
    for (final m in [...pending, ...errors]) {
      if (await pushMember(m.id)) count++;
    }
    return count;
  }
}
