import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../security/role_permission_matrix.dart';
import '../web/web_role_compatibility_service.dart';

/// Synchronisation permissions côté client — repli sans Cloud Functions.
class SystemSyncClientService {
  SystemSyncClientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<SystemSyncClientResult> syncAllPermissions() async {
    if (!FirebaseInitializer.isInitialized) {
      return const SystemSyncClientResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }

    var updated = 0;
    var skipped = 0;
    var permissionsFixed = 0;
    var webAccessGranted = 0;
    final now = DateTime.now().toIso8601String();

    final snap = await _firestore.collection(AppConstants.collectionUsers).get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      if (role.isEmpty) {
        skipped++;
        continue;
      }

      List<String> existing = const [];
      final perms = data['permissions'];
      if (perms is List) {
        existing = perms.map((e) => e.toString()).toList();
      }

      final template = RolePermissionMatrix.permissionsForRole(role);
      final merged = _mergePermissions(existing, template);
      final withWeb = WebRoleCompatibilityService.ensureWebPermissions(
        role: role,
        permissions: merged,
      );

      final hadWeb = existing.contains(WebRoleCompatibilityService.canAccessWeb);
      final permsChanged = withWeb.length != existing.length ||
          template.any((p) => !existing.contains(p));

      if (!permsChanged && hadWeb) {
        skipped++;
        continue;
      }

      if (permsChanged) permissionsFixed++;
      if (!hadWeb && withWeb.contains(WebRoleCompatibilityService.canAccessWeb)) {
        webAccessGranted++;
      }

      await doc.reference.set(
        {
          'permissions': withWeb,
          'roles': data['roles'] ?? [role],
          'updatedAt': now,
          'lastSystemSyncAt': now,
        },
        SetOptions(merge: true),
      );
      updated++;
    }

    await _firestore.collection('systemSyncState').doc('latest').set(
      {
        'lastSyncAt': now,
        'usersUpdated': updated,
        'permissionsFixed': permissionsFixed,
        'webAccessGranted': webAccessGranted,
        'source': 'client_fallback',
        'city': AppConstants.city,
      },
      SetOptions(merge: true),
    );

    return SystemSyncClientResult(
      success: true,
      updated: updated,
      skipped: skipped,
      permissionsFixed: permissionsFixed,
      webAccessGranted: webAccessGranted,
      message: 'Synchronisation terminée avec succès.',
    );
  }

  List<String> _mergePermissions(List<String> existing, List<String> template) {
    return {...existing, ...template}.toList();
  }
}

class SystemSyncClientResult {
  const SystemSyncClientResult({
    required this.success,
    this.updated = 0,
    this.skipped = 0,
    this.permissionsFixed = 0,
    this.webAccessGranted = 0,
    this.message,
  });

  final bool success;
  final int updated;
  final int skipped;
  final int permissionsFixed;
  final int webAccessGranted;
  final String? message;
}
