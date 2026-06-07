import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/sync/sync_on_login_service.dart';
import '../../../shared/models/media_activation_request.dart';
import '../services/google_media_member_auth_service.dart';

final googleMediaAuthServiceProvider = Provider(
  (ref) => GoogleMediaMemberAuthService(),
);

final mediaMemberAuthControllerProvider =
    Provider.autoDispose<MediaMemberAuthController>(
  (ref) => MediaMemberAuthController(ref: ref),
);

class MediaMemberAuthController {
  MediaMemberAuthController({required this.ref});

  final Ref ref;

  Future<GoogleSignInResult> signInWithGoogle() async {
    final service = ref.read(googleMediaAuthServiceProvider);
    final result = await service.signInWithGoogle();
    if (!result.success || result.route == null) return result;

    if (result.route == '/media/member/dashboard') {
      final req = result.request as MediaActivationRequest?;
      await _saveMediaSession(
        firebaseUid: result.firebaseUid!,
        email: req?.email ?? '',
        displayName: req?.displayName,
        photoUrl: req?.photoUrl,
        memberId: req?.memberId,
        role: AppConstants.roleMediaMember,
        activationStatus: AppConstants.activationStatusActive,
      );
    } else if (result.firebaseUid != null) {
      final req = result.request as MediaActivationRequest?;
      await _savePendingSession(
        firebaseUid: result.firebaseUid!,
        email: req?.email ?? '',
        displayName: req?.displayName,
        photoUrl: req?.photoUrl,
      );
    }

    return result;
  }

  Future<void> _saveMediaSession({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? memberId,
    required String role,
    required String activationStatus,
  }) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final session = LocalSession(prefs);
    await session.saveGoogleMediaSession(
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      memberId: memberId,
      activationStatus: activationStatus,
    );
    ref.invalidate(localSessionProvider);
    unawaited(
      SyncOnLoginService(autoSync: ref.read(autoSyncManagerProvider))
          .afterLogin(session),
    );
  }

  Future<void> _savePendingSession({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    await _saveMediaSession(
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: AppConstants.roleMediaMember,
      activationStatus: AppConstants.activationStatusPending,
    );
  }
}
