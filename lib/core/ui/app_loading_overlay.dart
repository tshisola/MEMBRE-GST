import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../widgets/app_shell_screens.dart';
import 'global_loading_controller.dart';

/// Overlay global — uniquement sur action explicite, jamais sur LoginChoice.
class AppLoadingOverlay extends ConsumerWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(globalLoadingControllerProvider);
    if (!loading.isVisible) {
      return const SizedBox.shrink();
    }

    final router = GoRouter.maybeOf(context);
    if (router == null) return const SizedBox.shrink();
    final path = router.state.uri.path;
    if (isAuthPublicRoute(path)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Material(
        color: AppTheme.premiumBlack.withValues(alpha: 0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ProfessionalLoader(),
              if (loading.message != null) ...[
                const SizedBox(height: 16),
                Text(
                  loading.message!,
                  style: const TextStyle(color: AppTheme.brandWhite),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
