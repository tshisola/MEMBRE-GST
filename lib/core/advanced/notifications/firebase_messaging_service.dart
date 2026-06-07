import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase/firebase_initializer.dart';
import '../../logging/app_logger.dart';
import '../../navigation/notification_deep_link_router.dart';
import '../models/advanced_models.dart';

/// Intégration Firebase Cloud Messaging + notifications locales.
class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isAvailable => _initialized && FirebaseInitializer.isInitialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (!kIsWeb) {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await _local.initialize(
          const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: (response) {
            NotificationDeepLinkRouter.instance.handle(response.payload);
          },
        );
      }

      if (FirebaseInitializer.isInitialized) {
        final messaging = FirebaseMessaging.instance;
        if (kIsWeb) {
          await messaging.requestPermission(alert: true, badge: true, sound: true);
        } else {
          await messaging.requestPermission(alert: true, badge: true, sound: true);
        }
        _fcmToken = await messaging.getToken(
          vapidKey: kIsWeb ? null : null,
        );
        messaging.onTokenRefresh.listen((t) => _fcmToken = t);
        FirebaseMessaging.onMessage.listen((message) {
          final n = message.notification;
          if (n != null && !kIsWeb) {
            final route = message.data['route'] as String?;
            unawaited(
              showLocal(
                title: n.title ?? 'MEDIA LUBUMBASHI',
                body: n.body ?? '',
                payload: route,
              ),
            );
          }
        });
        AppLogger.sync('Notifications push initialisées');
      }      _initialized = true;
    } catch (e) {
      AppLogger.error('FCM', 'init', e);
      _initialized = true;
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    AppNotificationSeverity severity = AppNotificationSeverity.info,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    final isCritical = severity == AppNotificationSeverity.critical;
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isCritical ? 'media_critical' : 'media_general',
          isCritical ? 'Alertes critiques' : 'Notifications MEDIA',
          importance:
              isCritical ? Importance.high : Importance.defaultImportance,
          priority: isCritical ? Priority.high : Priority.defaultPriority,
        ),
      ),
      payload: payload,
    );
  }
}
