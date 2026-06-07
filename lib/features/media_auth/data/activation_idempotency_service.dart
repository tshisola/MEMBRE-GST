import '../../../app/constants.dart';
import '../../../core/database/database_helper.dart';
import 'activation_request_repository.dart';

/// Empêche doublons activation / demandes.
class ActivationIdempotencyService {
  ActivationIdempotencyService({
    ActivationRequestRepository? requests,
  }) : _requests = requests ?? ActivationRequestRepository();

  final ActivationRequestRepository _requests;

  Future<ActivationCheckResult> checkBeforeActivation({
    required String firebaseUid,
    required String email,
  }) async {
    final request = await _requests.findByFirebaseUid(firebaseUid);
    if (request != null &&
        request.isActive &&
        request.activationCompleted) {
      return ActivationCheckResult.alreadyActive(
        request: request,
        memberId: request.memberId,
      );
    }

    final db = await DatabaseHelper.instance.database;
    final mediaRows = await db.query(
      AppConstants.tableMediaMembers,
      where: 'firebase_uid = ? AND status = ?',
      whereArgs: [firebaseUid, AppConstants.activationStatusActive],
      limit: 1,
    );
    if (mediaRows.isNotEmpty) {
      return ActivationCheckResult.alreadyActive(
        memberId: mediaRows.first['member_id'] as String?,
      );
    }

    final accountRows = await db.query(
      AppConstants.tableMemberAccounts,
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (accountRows.isNotEmpty) {
      return ActivationCheckResult.alreadyActive(
        memberId: accountRows.first['member_id'] as String?,
      );
    }

    return ActivationCheckResult.canProceed(request: request);
  }
}

class ActivationCheckResult {
  const ActivationCheckResult._({
    required this.canActivate,
    this.alreadyActive = false,
    this.request,
    this.memberId,
  });

  final bool canActivate;
  final bool alreadyActive;
  final dynamic request;
  final String? memberId;

  factory ActivationCheckResult.canProceed({dynamic request}) =>
      ActivationCheckResult._(canActivate: true, request: request);

  factory ActivationCheckResult.alreadyActive({
    dynamic request,
    String? memberId,
  }) =>
      ActivationCheckResult._(
        canActivate: false,
        alreadyActive: true,
        request: request,
        memberId: memberId,
      );
}
