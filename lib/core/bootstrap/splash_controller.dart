import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/role_based_navigation_service.dart';
import '../providers/app_providers.dart';
import '../ui/startup_loading_guard.dart';

/// Session-aware navigation after splash (max ~2 s).
class SplashController {
  SplashController._();

  static const Duration maxSplashDuration = Duration(seconds: 2);

  static Future<void> completeSplashNavigation({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    if (!context.mounted) return;

    if (StartupUiFlags.bootstrapGateCompleted) {
      if (context.mounted) {
        context.go(RoleBasedNavigationService.loginEntry());
      }
      return;
    }

    try {
      final session = await ref
          .read(localSessionProvider.future)
          .timeout(const Duration(seconds: 3));

      if (!context.mounted) return;

      if (session.isLoggedIn) {
        context.go(
          RoleBasedNavigationService.homeFor(
            role: session.role,
            accountType: session.accountType,
            mustChangePassword: session.mustChangePassword,
          ),
        );
      } else {
        context.go(RoleBasedNavigationService.loginEntry());
      }
    } catch (_) {
      if (context.mounted) {
        context.go(RoleBasedNavigationService.loginEntry());
      }
    }
  }
}
