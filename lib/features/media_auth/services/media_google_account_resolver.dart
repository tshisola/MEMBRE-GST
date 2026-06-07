import '../../../app/constants.dart';
import '../data/activation_idempotency_service.dart';
import '../data/activation_request_repository.dart';

class MediaAccountResolution {
  const MediaAccountResolution({
    required this.route,
    this.request,
    this.userMessage,
    this.memberId,
    this.firebaseUid,
  });

  final String route;
  final dynamic request;
  final String? userMessage;
  final String? memberId;
  final String? firebaseUid;
}

/// Résout le statut après Google Sign-In.
class MediaGoogleAccountResolver {
  MediaGoogleAccountResolver({
    ActivationRequestRepository? requests,
    ActivationIdempotencyService? idempotency,
  })  : _requests = requests ?? ActivationRequestRepository(),
        _idempotency = idempotency ?? ActivationIdempotencyService();

  final ActivationRequestRepository _requests;
  final ActivationIdempotencyService _idempotency;

  Future<MediaAccountResolution> resolve({
    required String firebaseUid,
    required String? email,
    String? displayName,
    String? photoUrl,
    String? providerId,
  }) async {
    if (email == null || email.isEmpty) {
      return const MediaAccountResolution(
        route: '/auth/google-email-missing',
        userMessage: 'E-mail Google requis.',
      );
    }

    final check = await _idempotency.checkBeforeActivation(
      firebaseUid: firebaseUid,
      email: email,
    );
    if (check.alreadyActive) {
      return MediaAccountResolution(
        route: '/media/member/dashboard',
        memberId: check.memberId,
        firebaseUid: firebaseUid,
        userMessage: 'Compte activé',
      );
    }

    var request = await _requests.findByFirebaseUid(firebaseUid);
    request ??= await _requests.findByEmail(email);

    if (request == null) {
      request = await _requests.createPendingRequest(
        firebaseUid: firebaseUid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return MediaAccountResolution(
        route: '/auth/pending-activation',
        request: request,
        firebaseUid: firebaseUid,
      );
    }

    switch (request.status) {
      case AppConstants.activationStatusActive:
        if (request.activationCompleted) {
          return MediaAccountResolution(
            route: '/media/member/dashboard',
            request: request,
            memberId: request.memberId,
            firebaseUid: firebaseUid,
          );
        }
        return MediaAccountResolution(
          route: '/auth/pending-activation',
          request: request,
          firebaseUid: firebaseUid,
        );
      case AppConstants.activationStatusRejected:
        return MediaAccountResolution(
          route: '/auth/activation-rejected',
          request: request,
          firebaseUid: firebaseUid,
        );
      case AppConstants.activationStatusSuspended:
      case AppConstants.activationStatusDisabled:
        return MediaAccountResolution(
          route: '/auth/account-disabled',
          request: request,
          firebaseUid: firebaseUid,
        );
      default:
        return MediaAccountResolution(
          route: '/auth/pending-activation',
          request: request,
          firebaseUid: firebaseUid,
        );
    }
  }
}
