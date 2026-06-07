import '../../messaging/technical_text_cleaner.dart';
import '../../messaging/user_friendly_message_service.dart';
import '../../security/privacy_guard.dart';

/// Garde confidentialité UI — masque données sensibles côté membre.
class PrivacyUiGuard {
  PrivacyUiGuard._();

  static Map<String, dynamic> sanitizeMemberView(Map<String, dynamic> data) =>
      CreatorVisibilityGuard.sanitizeForMember(data);

  static bool memberCanSeeAudit(String? role, String? accountType) =>
      MemberScopeGuard.canAccessAdminSpace(accountType, role);

  static String? hideCreator(String? createdBy, String? role) =>
      CreatorVisibilityGuard.canViewCreator(role) ? createdBy : null;
}

/// Nettoie textes sensibles avant affichage.
class SensitiveTextCleaner {
  SensitiveTextCleaner._();

  static String clean(String? input) =>
      TechnicalTextCleaner.clean(
        input,
        fallback: UserFriendlyMessageService.genericError(),
      );
}
