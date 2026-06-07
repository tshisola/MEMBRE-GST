import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/widgets/app_logo.dart';
import 'providers/media_activation_providers.dart';

/// Attente activation Admin — mise à jour temps réel sans détails techniques.
class PendingActivationScreen extends ConsumerWidget {
  const PendingActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localSessionProvider).valueOrNull;
    final uid = session?.firebaseUid ?? session?.userId;

    final statusAsync = uid == null
        ? const AsyncValue.data(null)
        : ref.watch(memberActivationStatusProvider(uid));

    if (uid != null) {
      ref.listen(memberActivationStatusProvider(uid), (prev, next) {
        final req = next.valueOrNull;
        if (req != null &&
            req.status == AppConstants.activationStatusActive &&
            req.activationCompleted) {
          unawaited(() async {
            final prefs = await ref.read(sharedPreferencesProvider.future);
            await LocalSession(prefs).saveGoogleMediaSession(
              firebaseUid: uid,
              email: req.email,
              displayName: req.displayName,
              photoUrl: req.photoUrl,
              role: AppConstants.roleMediaMember,
              memberId: req.memberId,
              activationStatus: AppConstants.activationStatusActive,
            );
            ref.invalidate(localSessionProvider);
            if (context.mounted) context.go('/media/member/dashboard');
          }());
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const AppLogo(size: 80, showTitle: true),
              const SizedBox(height: 24),
              const Text(
                UserFacingMessages.preparingTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                statusAsync.isLoading
                    ? UserFacingMessages.pleaseWait
                    : 'Votre demande est en cours de validation. Vous serez notifié dès activation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.95),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppTheme.goldAccent),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(logoutServiceProvider).logout(ref);
                  if (context.mounted) context.go('/login/member');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Retour connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
