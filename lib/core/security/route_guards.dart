import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../auth/auth_role_redirector.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell_screens.dart';

/// Réservé à l'Admin Général (diagnostic, conflits sensibles).
class AdminGeneralRouteGuard extends ConsumerWidget {
  const AdminGeneralRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(localSessionProvider);

    return sessionAsync.when(
      loading: () => const _RouteGuardPlaceholder(),
      error: (_, __) => _denied(context),
      data: (session) {
        if (session.role != AppConstants.roleAdminGeneral &&
            session.role != AppConstants.roleAdminGeneralOwner &&
            !session.isAdminGeneralOwner) {
          return _denied(context);
        }
        return child;
      },
    );
  }

  Widget _denied(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/dashboard');
    });
    return const _RouteGuardPlaceholder();
  }
}

/// Blocks admin routes for member accounts.
class AdminRouteGuard extends ConsumerWidget {
  const AdminRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(localSessionProvider);

    return sessionAsync.when(
      loading: () => const _RouteGuardPlaceholder(),
      error: (_, __) => _denied(context),
      data: (session) {
        if (session.accountType == AppConstants.accountTypeMember) {
          return _denied(context);
        }
        if (session.role == AppConstants.roleMember) {
          return _denied(context);
        }
        return child;
      },
    );
  }

  Widget _denied(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/auth/access-denied');
    });
    return const _RouteGuardPlaceholder();
  }
}

/// Ensures only member accounts access member space.
class MemberRouteGuard extends ConsumerWidget {
  const MemberRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(localSessionProvider);

    return sessionAsync.when(
      loading: () => const _RouteGuardPlaceholder(),
      error: (_, __) => _redirect(context),
      data: (session) {
        if (session.accountType != AppConstants.accountTypeMember &&
            session.role != AppConstants.roleMember &&
            session.role != AppConstants.roleMediaMember) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AuthRoleRedirector.redirectForRole(
                session.role ?? AppConstants.roleAdmin,
              ).route!);
            }
          });
          return const _RouteGuardPlaceholder();
        }
        if (session.mustChangePassword) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/auth/change-password');
          });
          return const _RouteGuardPlaceholder();
        }
        return child;
      },
    );
  }

  Widget _redirect(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/login');
    });
    return const _RouteGuardPlaceholder();
  }
}

/// Placeholder léger — pas de ModalBarrier ni AbsorbPointer global.
class _RouteGuardPlaceholder extends StatelessWidget {
  const _RouteGuardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.premiumBlack,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.goldAccent,
          ),
        ),
      ),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 64, color: AppTheme.danger),
              const SizedBox(height: 16),
              const Text(
                'Accès refusé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'avez pas l\'autorisation d\'accéder à cette section.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Retour connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDisabledScreen extends StatelessWidget {
  const AccountDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 64, color: AppTheme.warning),
              const SizedBox(height: 16),
              const Text(
                'Compte désactivé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Compte désactivé, contactez votre responsable.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Retour connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
