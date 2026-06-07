import '../../app/constants.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firestore_service.dart';

class DuplicateCheckResult {
  const DuplicateCheckResult({
    required this.hasDuplicate,
    this.existingMember,
    this.reason,
    this.source,
  });

  final bool hasDuplicate;
  final IfcmMemberRecord? existingMember;
  final String? reason;
  final String? source;
}

/// Detects duplicate members before creation (SQLite + Firestore when online).
class MemberDuplicateDetector {
  MemberDuplicateDetector({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<DuplicateCheckResult> check({
    String? phone,
    String? memberCode,
    String? fullName,
    String? localId,
    bool checkCloud = true,
  }) async {
    final local = await _checkLocal(
      phone: phone,
      memberCode: memberCode,
      fullName: fullName,
      localId: localId,
    );
    if (local.hasDuplicate) return local;

    if (checkCloud && FirebaseInitializer.isInitialized && phone != null &&
        phone.trim().isNotEmpty) {
      final cloud = await _checkCloudPhone(phone.trim());
      if (cloud.hasDuplicate) return cloud;
    }

    return const DuplicateCheckResult(hasDuplicate: false);
  }

  Future<DuplicateCheckResult> _checkLocal({
    String? phone,
    String? memberCode,
    String? fullName,
    String? localId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (phone != null && phone.trim().isNotEmpty) {
      final rows = await db.query(
        AppConstants.tableMembers,
        where: 'phone = ? AND is_deleted = 0',
        whereArgs: [phone.trim()],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return DuplicateCheckResult(
          hasDuplicate: true,
          existingMember: IfcmMemberRecord.fromSqlite(rows.first),
          reason: 'Un membre avec ce téléphone existe déjà.',
          source: 'local',
        );
      }
    }

    if (memberCode != null && memberCode.isNotEmpty) {
      final rows = await db.query(
        AppConstants.tableMembers,
        where: 'member_code = ?',
        whereArgs: [memberCode],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return DuplicateCheckResult(
          hasDuplicate: true,
          existingMember: IfcmMemberRecord.fromSqlite(rows.first),
          reason: 'Ce code membre existe déjà.',
          source: 'local',
        );
      }
    }

    if (fullName != null &&
        phone != null &&
        fullName.trim().isNotEmpty &&
        phone.trim().isNotEmpty) {
      final rows = await db.query(
        AppConstants.tableMembers,
        where: "LOWER(full_name) = ? AND phone = ? AND is_deleted = 0",
        whereArgs: [fullName.trim().toLowerCase(), phone.trim()],
        limit: 1,
      );
      if (rows.isEmpty) {
        final alt = await db.query(
          AppConstants.tableMembers,
          where:
              "LOWER(first_name || ' ' || last_name) = ? AND phone = ? AND is_deleted = 0",
          whereArgs: [fullName.trim().toLowerCase(), phone.trim()],
          limit: 1,
        );
        if (alt.isNotEmpty) {
          return DuplicateCheckResult(
            hasDuplicate: true,
            existingMember: IfcmMemberRecord.fromSqlite(alt.first),
            reason: 'Nom complet + téléphone déjà enregistrés.',
            source: 'local',
          );
        }
      } else {
        return DuplicateCheckResult(
          hasDuplicate: true,
          existingMember: IfcmMemberRecord.fromSqlite(rows.first),
          reason: 'Nom complet + téléphone déjà enregistrés.',
          source: 'local',
        );
      }
    }

    if (localId != null && localId.isNotEmpty) {
      final rows = await db.query(
        AppConstants.tableMembers,
        where: 'local_id = ? OR id = ?',
        whereArgs: [localId, localId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return DuplicateCheckResult(
          hasDuplicate: true,
          existingMember: IfcmMemberRecord.fromSqlite(rows.first),
          reason: 'Identifiant local déjà utilisé.',
          source: 'local',
        );
      }
    }

    return const DuplicateCheckResult(hasDuplicate: false);
  }

  Future<DuplicateCheckResult> _checkCloudPhone(String phone) async {
    try {
      final rows = await _firestore.queryCollection(
        AppConstants.collectionMembers,
        queryBuilder: (ref) => ref
            .where('city', isEqualTo: AppConstants.city)
            .where('phone', isEqualTo: phone)
            .where('isDeleted', isEqualTo: false)
            .limit(1),
      );
      if (rows.isEmpty) {
        return const DuplicateCheckResult(hasDuplicate: false);
      }
      final row = rows.first;
      final member = IfcmMemberRecord.fromFirestore(
        row['id'] as String? ?? row['localId'] as String? ?? '',
        row,
      );
      return DuplicateCheckResult(
        hasDuplicate: true,
        existingMember: member,
        reason: 'Ce téléphone existe déjà sur Firebase (autre Admin).',
        source: 'firebase',
      );
    } catch (_) {
      return const DuplicateCheckResult(hasDuplicate: false);
    }
  }

  /// Compte les groupes téléphone en double (diagnostic / automation).
  Future<int> scanDuplicatePhoneGroups() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT phone, COUNT(*) as c FROM ${AppConstants.tableMembers} '
        "WHERE phone IS NOT NULL AND TRIM(phone) != '' "
        'AND (is_deleted = 0 OR is_deleted IS NULL) '
        'GROUP BY phone HAVING c > 1',
      );
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}
