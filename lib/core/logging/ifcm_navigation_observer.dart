import 'package:flutter/material.dart';

import 'app_logger.dart';
import 'error_reporter_local.dart';

/// Tracks route changes for diagnostics.
class IfcmNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name ?? route.settings.toString();
    AppLogger.navigation('→ $name');
    ErrorReporterLocal.setLastRoute(name);
  }
}
