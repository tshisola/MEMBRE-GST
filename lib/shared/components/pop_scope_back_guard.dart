import 'package:flutter/material.dart';

import '../../core/navigation/safe_back_navigation_service.dart';

/// Intercepte le bouton retour Android — navigation interne ou confirmation sortie.
class PopScopeBackGuard extends StatelessWidget {
  const PopScopeBackGuard({
    super.key,
    required this.child,
    this.fallbackRoute = '/dashboard',
    this.confirmExitAtRoot = false,
    this.rootRoute = '/dashboard',
  });

  final Widget child;
  final String fallbackRoute;
  final bool confirmExitAtRoot;
  final String rootRoute;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await SafeBackNavigationService.handleWillPop(
          context,
          fallbackRoute: fallbackRoute,
          confirmExitAtRoot: confirmExitAtRoot,
          rootRoute: rootRoute,
        );
      },
      child: child,
    );
  }
}

typedef BackNavigationGuard = PopScopeBackGuard;
