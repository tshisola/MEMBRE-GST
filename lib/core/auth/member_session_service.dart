import '../storage/local_session.dart';
import '../security/privacy_guard.dart';

/// Member session helpers — no creator metadata exposed.
class MemberSessionService {
  MemberSessionService(this.session);

  final LocalSession session;

  bool get isMember => session.isMemberAccount;
  bool get mustChangePassword => session.mustChangePassword;
  String? get memberId => session.memberId;

  /// Sanitized profile for member UI — never includes creator.
  Map<String, dynamic> memberProfileView() {
    return CreatorVisibilityGuard.sanitizeForMember({
      'memberId': session.memberId,
      'department': session.department,
      'role': session.role,
    });
  }
}

/// Blocks member from self check-in and admin visibility.
class MemberPrivacyGuard {
  MemberPrivacyGuard._();

  static bool canSelfCheckIn(LocalSession session, String targetMemberId) {
    return PrivacyGuard.memberCanSelfCheckIn(
      accountType: session.accountType,
      sessionMemberId: session.memberId,
      targetMemberId: targetMemberId,
    );
  }

  static bool shouldHideAdminUi(LocalSession session) =>
      session.isMemberAccount;
}

/// Secure auth guard for route-level checks.
class SecureAuthGuard {
  SecureAuthGuard._();

  static bool requiresPasswordChange(LocalSession session) =>
      session.isMemberAccount && session.mustChangePassword;

  static bool canAccessAdmin(LocalSession session) =>
      MemberScopeGuard.canAccessAdminSpace(
        session.accountType,
        session.role,
      );
}
