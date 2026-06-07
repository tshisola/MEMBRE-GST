import 'package:cloud_functions/cloud_functions.dart';

import '../../../app/constants.dart';
import '../../../shared/models/media_activation_request.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/logging/technical_error_repository.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../data/activation_idempotency_service.dart';
import '../data/activation_request_repository.dart';
import '../data/multi_database_activation_writer.dart';
import 'activation_background_sync_service.dart';

class AdminActivationResult {
  const AdminActivationResult({
    required this.success,
    required this.message,
    this.alreadyActive = false,
    this.memberId,
  });

  final bool success;
  final String message;
  final bool alreadyActive;
  final String? memberId;
}

/// Activation / refus Admin — Cloud Function + SQLite local.
class AdminMediaActivationController {
  AdminMediaActivationController({
    ActivationRequestRepository? requests,
    ActivationIdempotencyService? idempotency,
    MultiDatabaseActivationWriter? writer,
    ActivationBackgroundSyncService? sync,
  })  : _requests = requests ?? ActivationRequestRepository(),
        _idempotency = idempotency ?? ActivationIdempotencyService(),
        _writer = writer ?? MultiDatabaseActivationWriter(),
        _sync = sync ?? ActivationBackgroundSyncService();

  final ActivationRequestRepository _requests;
  final ActivationIdempotencyService _idempotency;
  final MultiDatabaseActivationWriter _writer;
  final ActivationBackgroundSyncService _sync;

  Future<AdminActivationResult> activate({
    required String requestId,
    required String adminId,
  }) async {
    try {
      final request = await _requests.findByFirebaseUid(requestId);
      if (request == null) {
        return const AdminActivationResult(
          success: false,
          message: 'Demande introuvable.',
        );
      }

      final check = await _idempotency.checkBeforeActivation(
        firebaseUid: request.firebaseUid,
        email: request.email,
      );
      if (check.alreadyActive) {
        return AdminActivationResult(
          success: true,
          alreadyActive: true,
          message: 'Compte déjà activé.',
          memberId: check.memberId ?? request.memberId,
        );
      }

      if (FirebaseInitializer.isInitialized) {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'activateMediaGoogleMemberCallable',
        );
        final response = await callable.call<Map<String, dynamic>>({
          'requestId': request.firebaseUid,
          'adminId': adminId,
        });
        final data = response.data;
        final memberId = data['memberId'] as String?;
        await _syncAfterRemoteSuccess(request, adminId, memberId);
        return AdminActivationResult(
          success: true,
          message: data['message'] as String? ?? 'Compte activé.',
          memberId: memberId,
        );
      }

      return _activateLocalOnly(request!, adminId);
    } catch (e, st) {
      TechnicalErrorRepository.record(source: 'admin_activate', error: e, stack: st);
      return AdminActivationResult(
        success: false,
        message: UserFacingMessages.genericIssue,
      );
    }
  }

  Future<AdminActivationResult> reject({
    required String requestId,
    required String adminId,
    String? reason,
  }) async {
    try {
      if (FirebaseInitializer.isInitialized) {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'rejectMediaGoogleMemberCallable',
        );
        await callable.call({'requestId': requestId, 'adminId': adminId, 'reason': reason});
      }
      final request = await _requests.findByFirebaseUid(requestId);
      if (request != null) {
        await _requests.updateStatus(
          request,
          status: AppConstants.activationStatusRejected,
          rejectionReason: reason,
          reviewedBy: adminId,
        );
      }
      return const AdminActivationResult(success: true, message: 'Demande refusée.');
    } catch (e, st) {
      TechnicalErrorRepository.record(source: 'admin_reject', error: e, stack: st);
      return AdminActivationResult(success: false, message: UserFacingMessages.genericIssue);
    }
  }

  Future<AdminActivationResult> _activateLocalOnly(
    MediaActivationRequest request,
    String adminId,
  ) async {
    final write = await _writer.writeActivatedProfile(request: request);
    await _requests.updateStatus(
      request,
      status: AppConstants.activationStatusActive,
      memberId: write.memberId,
      activationCompleted: true,
      reviewedBy: adminId,
    );
    return AdminActivationResult(
      success: true,
      message: 'Compte activé (mode local).',
      memberId: write.memberId,
    );
  }

  Future<void> _syncAfterRemoteSuccess(
    MediaActivationRequest request,
    String adminId,
    String? memberId,
  ) async {
    await _requests.updateStatus(
      request,
      status: AppConstants.activationStatusActive,
      memberId: memberId,
      activationCompleted: true,
      reviewedBy: adminId,
    );
    if (memberId != null) {
      await _writer.writeActivatedProfile(
        request: request,
        existingMemberId: memberId,
      );
    }
    await _sync.syncActivation(request.firebaseUid);
  }
}
