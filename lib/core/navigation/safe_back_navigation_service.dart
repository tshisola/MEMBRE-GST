import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/components/exit_confirmation_dialog.dart';

/// Navigation retour sécurisée — évite de quitter l'app brutalement.
class SafeBackNavigationService {
  SafeBackNavigationService._();

  static void goBack(
    BuildContext context, {
    String fallbackRoute = '/dashboard',
  }) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  static Future<bool> handleWillPop(
    BuildContext context, {
    String fallbackRoute = '/dashboard',
    bool confirmExitAtRoot = false,
    String rootRoute = '/dashboard',
  }) async {
    if (context.canPop()) {
      context.pop();
      return false;
    }
    final current = GoRouter.of(context).state.uri.path;
    if (confirmExitAtRoot && current == rootRoute) {
      final exit = await ExitConfirmationDialog.show(context);
      if (exit && context.mounted) {
        await SystemNavigator.pop();
      }
      return false;
    }
    context.go(fallbackRoute);
    return false;
  }
}

typedef SafeBackNavigation = SafeBackNavigationService;
