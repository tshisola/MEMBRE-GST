import 'technical_text_cleaner.dart';
import 'user_facing_messages.dart';
import 'user_friendly_error_mapper.dart';

/// Mappe toute erreur vers un message professionnel (jamais technique).
class SecureErrorMapper {
  SecureErrorMapper._();

  static String map(Object? error, {String? fallback}) {
    if (error == null) {
      return fallback ?? UserFacingMessages.genericIssue;
    }
    final raw = error.toString();
    if (TechnicalTextCleaner.looksTechnical(raw)) {
      return UserFriendlyErrorMapper.map(error, fallback: fallback);
    }
    final mapped = UserFriendlyErrorMapper.map(error, fallback: null);
    if (mapped != UserFacingMessages.genericIssue) return mapped;
    if (TechnicalTextCleaner.looksTechnical(raw)) {
      return fallback ?? UserFacingMessages.genericIssue;
    }
    return TechnicalTextCleaner.clean(raw, fallback: fallback ?? UserFacingMessages.genericIssue);
  }

  static bool isPermissionDenied(Object? error) =>
      UserFriendlyErrorMapper.isPermissionDenied(error);

  static bool isNetworkIssue(Object? error) =>
      UserFriendlyErrorMapper.isNetworkIssue(error);
}
