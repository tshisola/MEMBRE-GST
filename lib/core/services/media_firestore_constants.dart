/// Firestore collection names for IFCM media department (Lubumbashi).
abstract final class MediaFirestoreCollections {
  static const String attendance = 'media_attendance';
  static const String lists = 'media_lists';
  static const String roles = 'media_roles';
  static const String members = 'media_members';
}

abstract final class MediaLocalTables {
  static const String attendance = 'media_attendance_local';
  static const String lists = 'media_lists_local';
  static const String members = 'media_members_local';
  static const String roles = 'media_roles_local';
  static const String syncQueue = 'media_sync_queue';
}
