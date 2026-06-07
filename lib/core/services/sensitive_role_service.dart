import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/role_models.dart';
import 'lubumbashi_branding_service.dart';
import 'media_attendance_permission_service.dart';
import 'media_firestore_constants.dart';

/// Manages sensitive media role assignments (Lubumbashi).
class SensitiveRoleService {
  SensitiveRoleService({
    FirebaseFirestore? firestore,
    MediaAttendancePermissionService? permissionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _permissions =
            permissionService ?? const MediaAttendancePermissionService();

  final FirebaseFirestore _firestore;
  final MediaAttendancePermissionService _permissions;

  CollectionReference<Map<String, dynamic>> get _rolesRef =>
      _firestore.collection(MediaFirestoreCollections.roles);

  Future<void> assignRole({
    required UserRole actor,
    required String memberId,
    required MediaRole mediaRole,
  }) async {
    if (!_permissions.canManageMediaRoles(actor)) {
      throw StateError('Permission refusée: attribution rôle média.');
    }

    final assignment = MediaRoleAssignment(
      memberId: memberId,
      mediaRole: mediaRole,
      assignedAt: DateTime.now(),
      assignedBy: actor.uid,
      city: LubumbashiBrandingService.city,
    );

    await _rolesRef.doc(memberId).set({
      ...assignment.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> revokeRole({
    required UserRole actor,
    required String memberId,
  }) async {
    if (!_permissions.canManageMediaRoles(actor)) {
      throw StateError('Permission refusée: révocation rôle média.');
    }
    await _rolesRef.doc(memberId).delete();
  }

  Future<MediaRoleAssignment?> getAssignment(String memberId) async {
    final doc = await _rolesRef.doc(memberId).get();
    if (!doc.exists) return null;
    return MediaRoleAssignment.fromMap(doc.data()!);
  }

  Future<List<MediaRoleAssignment>> listAssignments() async {
    final snap = await _rolesRef
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .get();
    return snap.docs.map((d) => MediaRoleAssignment.fromMap(d.data())).toList();
  }

  Stream<Map<String, MediaRole>> watchRoleMap() {
    return _rolesRef
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .snapshots()
        .map((snap) {
      final map = <String, MediaRole>{};
      for (final doc in snap.docs) {
        final assignment = MediaRoleAssignment.fromMap(doc.data());
        map[assignment.memberId] = assignment.mediaRole;
      }
      return map;
    });
  }

  bool canAssignRole(UserRole? actor, MediaRole targetRole) {
    if (actor == null) return false;
    if (!_permissions.canManageMediaRoles(actor)) return false;
    if (targetRole == MediaRole.chefMedia && !actor.isAdminGeneral) {
      return actor.mediaRole == MediaRole.chefMedia;
    }
    return true;
  }
}
