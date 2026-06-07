import '../../shared/models/ifcm_member_record.dart';

/// Logged sync conflict between local SQLite and Firestore.
class SyncConflictRecord {
  const SyncConflictRecord({
    required this.id,
    required this.memberId,
    required this.local,
    required this.remote,
    required this.resolved,
    required this.createdAt,
  });

  final String id;
  final String memberId;
  final IfcmMemberRecord? local;
  final IfcmMemberRecord? remote;
  final bool resolved;
  final DateTime createdAt;

  String get memberLabel =>
      local?.displayName ?? remote?.displayName ?? memberId;

  String get memberCode =>
      local?.memberCode ?? remote?.memberCode ?? '—';
}
