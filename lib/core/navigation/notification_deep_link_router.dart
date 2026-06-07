import 'notification_payload_parser.dart';

/// Route les notifications vers le bon écran.
class NotificationDeepLinkRouter {
  NotificationDeepLinkRouter._();
  static final NotificationDeepLinkRouter instance = NotificationDeepLinkRouter._();

  void Function(String route)? _handler;

  void install(void Function(String route) handler) => _handler = handler;

  void handle(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    final parsed = NotificationPayloadParser.parse(payload);
    if (parsed == null) return;
    _handler?.call(parsed.path);
  }
}
