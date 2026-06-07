import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/members/member_created_broadcaster.dart';
import '../../../core/members/member_duplicate_detector.dart';
import '../../../core/members/member_qr_service.dart';
import '../../../core/security/sensitive_action_logger.dart';
import '../../../core/sync/member_sync_manager.dart';
import '../../../core/sync/offline_sync_queue.dart';
import '../../../core/sync/background_sync_trigger.dart';
import '../../../core/sync/offline_action_queue.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../data/local_member_repository.dart';

class CreateMemberInput {
  const CreateMemberInput({
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.commune = 'Lubumbashi',
    this.departmentId,
    this.departmentName,
    this.pastorId,
    this.pastorName,
    this.discipleId,
    this.discipleName,
    this.leaderId,
    this.leaderName,
    this.createdBy,
    this.createdByRole,
    this.forceDuplicate = false,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String commune;
  final String? departmentId;
  final String? departmentName;
  final String? pastorId;
  final String? pastorName;
  final String? discipleId;
  final String? discipleName;
  final String? leaderId;
  final String? leaderName;
  final String? createdBy;
  final String? createdByRole;
  final bool forceDuplicate;
}

class CreateMemberResult {
  const CreateMemberResult({
    required this.member,
    required this.syncStatus,
    this.wasDuplicateOverride = false,
  });

  final IfcmMemberRecord member;
  final String syncStatus;
  final bool wasDuplicateOverride;
}

/// Offline-first member creation use case.
class CreateMemberUseCase {
  CreateMemberUseCase({
    Uuid? uuid,
    LocalMemberRepository? localRepo,
    MemberDuplicateDetector? duplicateDetector,
    MemberQrService? qrService,
    OfflineActionQueue? queue,
    OfflineSyncQueue? syncQueue,
    MemberSyncManager? syncManager,
  })  : _uuid = uuid ?? const Uuid(),
        _local = localRepo ?? LocalMemberRepository(),
        _duplicate = duplicateDetector ?? MemberDuplicateDetector(),
        _qr = qrService ?? MemberQrService(),
        _queue = queue ?? OfflineActionQueue(),
        _syncQueue = syncQueue ?? OfflineSyncQueue(),
        _sync = syncManager ?? MemberSyncManager();

  final Uuid _uuid;
  final LocalMemberRepository _local;
  final MemberDuplicateDetector _duplicate;
  final MemberQrService _qr;
  final OfflineActionQueue _queue;
  final OfflineSyncQueue _syncQueue;
  final MemberSyncManager _sync;

  Future<DuplicateCheckResult> checkDuplicate(CreateMemberInput input) {
    return _duplicate.check(
      phone: input.phone,
      fullName: '${input.firstName} ${input.lastName}',
    );
  }

  Future<CreateMemberResult> execute(CreateMemberInput input) async {
    final dup = await checkDuplicate(input);
    if (dup.hasDuplicate && !input.forceDuplicate) {
      throw DuplicateMemberException(dup);
    }

    if (dup.hasDuplicate && input.forceDuplicate) {
      await SensitiveActionLogger.log(
        action: 'member_duplicate_override',
        actorId: input.createdBy,
        targetId: dup.existingMember?.id,
        metadata: {'reason': dup.reason},
      );
    }

    final localId = _uuid.v4();
    final qrPack = await _qr.generate(localId: localId);
    final now = DateTime.now();

    var member = IfcmMemberRecord(
      id: localId,
      localId: localId,
      memberCode: qrPack.memberCode,
      qrCodeId: qrPack.qrCodeId,
      qrData: qrPack.qrData,
      firstName: input.firstName.trim(),
      lastName: input.lastName.trim(),
      phone: input.phone?.trim(),
      email: input.email?.trim(),
      address: input.address?.trim(),
      commune: input.commune,
      departmentId: input.departmentId,
      departmentName: input.departmentName,
      pastorId: input.pastorId,
      pastorName: input.pastorName,
      discipleId: input.discipleId,
      discipleName: input.discipleName,
      leaderId: input.leaderId,
      leaderName: input.leaderName,
      createdBy: input.createdBy,
      createdByRole: input.createdByRole,
      syncStatus: AppConstants.syncStatusPending,
      createdAt: now,
      updatedAt: now,
    );

    await _local.insert(member);
    await _qr.saveQrRecord(
      memberId: localId,
      memberCode: qrPack.memberCode,
      qrCodeId: qrPack.qrCodeId,
      qrData: qrPack.qrData,
    );

    await _queue.enqueue(
      actionType: 'member_upsert',
      payload: {
        'localId': localId,
        ...member.toFirestore(),
      },
    );

    await _syncQueue.enqueue(
      entityType: 'member',
      entityId: localId,
      actionType: AppConstants.syncActionCreateMember,
      payload: member.toFirestore(),
    );

    var syncStatus = AppConstants.syncStatusPending;
    if (FirebaseInitializer.isInitialized) {
      final ok = await _sync.pushMember(localId);
      if (ok) {
        syncStatus = AppConstants.syncStatusSynced;
        await _queue.completeMemberUpsert(localId);
        await _syncQueue.completeForEntity(entityType: 'member', entityId: localId);
        final refreshed = await _local.getById(localId);
        if (refreshed != null) member = refreshed;
      }
    }

    await SensitiveActionLogger.log(
      action: 'create_member',
      actorId: input.createdBy,
      targetId: localId,
      metadata: {'memberCode': member.memberCode},
    );

    unawaited(
      BackgroundSyncTrigger().afterLocalWrite(
        entityType: 'member',
        entityId: localId,
        actionType: AppConstants.syncActionCreateMember,
        payload: member.toFirestore(),
      ),
    );

    unawaited(MemberCreatedBroadcaster.instance.notifyCreated(localId));

    return CreateMemberResult(
      member: member,
      syncStatus: syncStatus,
      wasDuplicateOverride: dup.hasDuplicate && input.forceDuplicate,
    );
  }
}

class DuplicateMemberException implements Exception {
  DuplicateMemberException(this.result);
  final DuplicateCheckResult result;
}
