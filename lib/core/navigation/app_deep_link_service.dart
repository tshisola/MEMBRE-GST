import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../storage/local_session.dart';
import 'deep_link_permission_guard.dart';
import 'notification_deep_link_router.dart';
import 'notification_payload_parser.dart';

/// Service central de deep-links — jamais de détail technique côté UI.
class AppDeepLinkService {
  AppDeepLinkService._();
  static final AppDeepLinkService instance = AppDeepLinkService._();

  String? _pendingRoute;

  String? get pendingRoute => _pendingRoute;

  void setPending(String route) => _pendingRoute = route;

  void clearPending() => _pendingRoute = null;

  Future<void> open(
    GoRouter router, {
    required String route,
    LocalSession? session,
  }) async {
    final parsed = NotificationPayloadParser.parse(route);
    if (parsed == null) return;

    if (session == null || !session.isLoggedIn) {
      setPending(parsed.path);
      router.go('/login');
      return;
    }

    if (!DeepLinkPermissionGuard.canAccess(session, parsed.path)) {
      router.go('/auth/access-denied');
      return;
    }

    router.push(parsed.path);
  }

  Future<void> consumePending(GoRouter router, LocalSession session) async {
    final route = _pendingRoute;
    if (route == null) return;
    clearPending();
    await open(router, route: route, session: session);
  }

  Future<void> navigateAfterLogin(
    GoRouter router,
    LocalSession session, {
    required String fallbackRoute,
  }) async {
    if (_pendingRoute != null) {
      await consumePending(router, session);
    } else {
      router.go(fallbackRoute);
    }
  }
}

typedef LocalFirstDeepLinkResolver = AppDeepLinkService;

class DeepLinkGuard {
  DeepLinkGuard._();

  static bool isAdminRoute(String path) {
    return path.startsWith('/admin') ||
        path.startsWith('/advanced') ||
        path.startsWith('/smart') ||
        path.startsWith('/members/create');
  }

  static bool isMemberSafe(String path) {
    if (isAdminRoute(path)) return false;
    return path.startsWith('/member') ||
        path.startsWith('/media/member') ||
        path.startsWith('/media/history');
  }
}

typedef PushNotificationRouter = NotificationDeepLinkRouter;
