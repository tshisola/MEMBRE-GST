import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'constants.dart';
import 'router.dart';
import 'theme.dart';
import '../core/bootstrap/background_sync_host.dart';
import '../core/ui/app_loading_overlay.dart';
import '../core/ui/startup_loading_guard.dart';
import '../core/widgets/app_shell_screens.dart';
import '../core/web/web_update_banner.dart';
import '../features/web/presentation/web_responsive_scaffold.dart';

/// Root Material application for IFCM Lubumbashi.
class IfcmApp extends ConsumerWidget {
  const IfcmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} — ${AppConstants.city}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        final path = GoRouter.maybeOf(context)?.state.uri.path ?? '/login';
        final routeChild = child ?? AppShellFallback.forPath(path);

        return WebUpdateBanner(
          child: BackgroundSyncHost(
            routePath: path,
            child: ColoredBox(
              color: AppTheme.premiumBlack,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebResponsiveScaffold(path: path, child: routeChild),
                  const StartupLoadingGuard(),
                  const AppLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
