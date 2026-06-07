import '../../shared/models/ifcm_member_record.dart';
import '../../shared/models/role_models.dart';
import '../security/delete_member_guard.dart';

/// Vérification centralisée des permissions de suppression membre.
class MemberDeletionPermissionChecker {
  const MemberDeletionPermissionChecker({DeleteMemberGuard? guard})
      : _guard = guard ?? const DeleteMemberGuard();

  final DeleteMemberGuard _guard;

  bool canDelete(UserRole? user) => _guard.canDelete(user);

  bool canDeactivate(UserRole? user) => _guard.canDeactivate(user);

  bool canRequestDelete(UserRole? user, IfcmMemberRecord member) =>
      _guard.canRequestDelete(user, member);

  bool canRestore(UserRole? user) => _guard.canRestore(user);

  bool canPermanentDelete(UserRole? user) => _guard.canPermanentDelete(user);

  bool canViewTrash(UserRole? user) => _guard.canViewTrash(user);

  bool canApproveRequests(UserRole? user) => _guard.canApproveDeleteRequests(user);

  String denialMessage() => _guard.denialMessage();

  String requestSubmittedMessage() => _guard.requestSubmittedMessage();
}
