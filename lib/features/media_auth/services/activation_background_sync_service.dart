import '../data/activation_request_repository.dart';

/// Sync activation en arrière-plan après action Admin.
class ActivationBackgroundSyncService {
  ActivationBackgroundSyncService({
    ActivationRequestRepository? requests,
  }) : _requests = requests ?? ActivationRequestRepository();

  final ActivationRequestRepository _requests;

  Future<void> syncActivation(String firebaseUid) async {
    await _requests.findByFirebaseUid(firebaseUid);
  }
}
