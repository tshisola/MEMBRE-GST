/// Parse les payloads notification → route application.
class NotificationPayloadParser {
  NotificationPayloadParser._();

  static ParsedDeepLink? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('/')) {
      return ParsedDeepLink(path: trimmed);
    }

    if (trimmed.startsWith('member:')) {
      final id = trimmed.substring(7);
      return ParsedDeepLink(path: '/members/$id');
    }

    switch (trimmed) {
      case 'media_activation':
        return const ParsedDeepLink(path: '/admin/media-activation-requests');
      case 'pointage_problems':
        return const ParsedDeepLink(path: '/smart/pointage-problems');
      case 'pdf_report':
        return const ParsedDeepLink(path: '/advanced/report');
      case 'member_dashboard':
        return const ParsedDeepLink(path: '/member/dashboard');
      case 'media_lists':
        return const ParsedDeepLink(path: '/media/lists');
      case 'attendance_history':
        return const ParsedDeepLink(path: '/media/history');
      case 'duplicate_merge':
        return const ParsedDeepLink(path: '/advanced/duplicate-merge');
      default:
        return null;
    }
  }

  static String routeForMemberDetail(String memberId) => '/members/$memberId';

  static String routeForPdfPreview(String cacheKey) =>
      '/advanced/pdf-preview?key=$cacheKey';
}

class ParsedDeepLink {
  const ParsedDeepLink({required this.path});
  final String path;
}

typedef NotificationPayloadParserService = NotificationPayloadParser;
