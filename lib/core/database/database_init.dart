import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import 'sqlite_pragma_helper.dart';

/// Creates and migrates local SQLite tables for IFCM Lubumbashi.
class DatabaseInit {
  DatabaseInit._();

  static Future<void> onCreate(Database db, int version) async {
    await SqlitePragmaHelper.enableForeignKeys(db);
    await _createCoreTables(db);
    await _createAuthTables(db);
    await _migrateToV3(db);
    await _migrateToV4(db);
    await _migrateToV5(db);
    await _migrateToV6(db);
    await _migrateToV7(db);
    await _migrateToV8(db);
    await _migrateToV9(db);
    await _migrateToV10(db);
    await _createIndexes(db);
  }

  /// Migrations légères après ouverture (hors chemin critique UI).
  static Future<void> runPostOpenMigrations(Database db) async {
    await _migrateToV5(db);
    await _migrateToV6(db);
    await _migrateToV7(db);
    await _migrateToV8(db);
    await _migrateToV9(db);
    await _migrateToV10(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await SqlitePragmaHelper.enableForeignKeys(db);
    if (oldVersion < 2) {
      await _createAuthTables(db);
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
    if (oldVersion < 7) {
      await _migrateToV7(db);
    }
    if (oldVersion < 8) {
      await _migrateToV8(db);
    }
    if (oldVersion < 9) {
      await _migrateToV9(db);
    }
    if (oldVersion < 10) {
      await _migrateToV10(db);
    }
  }

  static Future<void> _migrateToV6(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMediaGoogleActivationRequests} (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        display_name TEXT,
        photo_url TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.activationStatusPending}',
        department_name TEXT NOT NULL DEFAULT '${AppConstants.departmentNameMedia}',
        requested_role TEXT NOT NULL DEFAULT '${AppConstants.requestedRoleMediaMember}',
        provider TEXT NOT NULL DEFAULT '${AppConstants.authProviderGoogle}',
        activation_completed INTEGER NOT NULL DEFAULT 0,
        rejection_reason TEXT,
        reviewed_by TEXT,
        reviewed_at TEXT,
        member_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMediaMembers} (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT NOT NULL UNIQUE,
        member_id TEXT NOT NULL,
        email TEXT,
        display_name TEXT,
        photo_url TEXT,
        role TEXT NOT NULL DEFAULT '${AppConstants.roleMediaMember}',
        department_id TEXT NOT NULL DEFAULT '${AppConstants.mediaDepartmentId}',
        member_code TEXT,
        qr_code_id TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.activationStatusActive}',
        activation_completed INTEGER NOT NULL DEFAULT 1,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableActivationLogs} (
        id TEXT PRIMARY KEY,
        request_id TEXT NOT NULL,
        action TEXT NOT NULL,
        actor_id TEXT,
        metadata_json TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_activation_status ON ${AppConstants.tableMediaGoogleActivationRequests}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_activation_email ON ${AppConstants.tableMediaGoogleActivationRequests}(email)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_media_members_uid ON ${AppConstants.tableMediaMembers}(firebase_uid)',
    );
  }

  static Future<void> _migrateToV7(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableAdminStaffAccounts} (
        id TEXT PRIMARY KEY,
        login_identifier TEXT NOT NULL UNIQUE,
        email TEXT,
        display_name TEXT NOT NULL,
        role TEXT NOT NULL,
        permissions_json TEXT,
        is_owner INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_locked INTEGER NOT NULL DEFAULT 0,
        must_change_password INTEGER NOT NULL DEFAULT 1,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        firebase_uid TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_admin_staff_login ON ${AppConstants.tableAdminStaffAccounts}(login_identifier)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_admin_staff_role ON ${AppConstants.tableAdminStaffAccounts}(role)',
    );
  }

  static Future<void> _migrateToV8(Database db) async {
    final memberColumns = [
      'deleted_at TEXT',
      'deleted_by TEXT',
      'deleted_reason TEXT',
    ];
    for (final col in memberColumns) {
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.tableMembers} ADD COLUMN $col',
        );
      } catch (_) {}
    }

    final auditColumns = [
      'actor_name TEXT',
      'target_type TEXT',
      'synced_at TEXT',
    ];
    for (final col in auditColumns) {
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.tableAuditLogs} ADD COLUMN $col',
        );
      } catch (_) {}
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableDeletedMembers} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        member_code TEXT,
        full_name TEXT,
        phone TEXT,
        department_id TEXT,
        department_name TEXT,
        deleted_by TEXT,
        deleted_by_role TEXT,
        deleted_reason TEXT,
        deleted_at TEXT NOT NULL,
        restore_available INTEGER NOT NULL DEFAULT 1,
        synced_at TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberDeleteRequests} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        requested_by TEXT NOT NULL,
        requested_by_role TEXT,
        reason TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        approved_by TEXT,
        approved_at TEXT,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberRestoreLogs} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        restored_by TEXT NOT NULL,
        restored_at TEXT NOT NULL,
        reason TEXT,
        synced_at TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}'
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_deleted_members_member ON ${AppConstants.tableDeletedMembers}(member_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_delete_requests_status ON ${AppConstants.tableMemberDeleteRequests}(status)',
    );
  }

  static Future<void> _migrateToV5(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMigrationHistory} (
        id TEXT PRIMARY KEY,
        migration_name TEXT NOT NULL,
        version INTEGER NOT NULL,
        status TEXT NOT NULL,
        executed_at TEXT NOT NULL,
        error_message TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_migration_history_name ON ${AppConstants.tableMigrationHistory}(migration_name)',
    );
  }

  static Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableOfflineSyncQueue} (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        payload_json TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.queueStatusPending}',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_offline_sync_status ON ${AppConstants.tableOfflineSyncQueue}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_offline_sync_entity ON ${AppConstants.tableOfflineSyncQueue}(entity_type, entity_id)',
    );
  }

  static Future<void> _migrateToV3(Database db) async {
    final columns = [
      'local_id TEXT',
      'member_code TEXT',
      'qr_code_id TEXT',
      'qr_data TEXT',
      'full_name TEXT',
      'address TEXT',
      "commune TEXT DEFAULT '${AppConstants.city}'",
      'department_name TEXT',
      'pastor_id TEXT',
      'pastor_name TEXT',
      'disciple_id TEXT',
      'disciple_name TEXT',
      'leader_id TEXT',
      'leader_name TEXT',
      'created_by TEXT',
      'created_by_role TEXT',
      'cloud_id TEXT',
      "sync_status TEXT DEFAULT '${AppConstants.syncStatusLocal}'",
      'is_deleted INTEGER NOT NULL DEFAULT 0',
    ];
    for (final col in columns) {
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.tableMembers} ADD COLUMN $col',
        );
      } catch (_) {}
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberQrCodes} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        member_code TEXT NOT NULL UNIQUE,
        qr_code_id TEXT NOT NULL UNIQUE,
        qr_data TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        FOREIGN KEY (member_id) REFERENCES ${AppConstants.tableMembers}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableSyncConflicts} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        local_json TEXT,
        remote_json TEXT,
        resolved INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}'
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_members_member_code ON ${AppConstants.tableMembers}(member_code)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_members_sync_status ON ${AppConstants.tableMembers}(sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_member_qr_member ON ${AppConstants.tableMemberQrCodes}(member_id)',
    );
  }

  static Future<void> _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMembers} (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        department_id TEXT,
        role TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMediaAttendance} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        session_date TEXT NOT NULL,
        session_type TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        operator_id TEXT,
        department_id TEXT NOT NULL DEFAULT '${AppConstants.mediaDepartmentId}',
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        FOREIGN KEY (member_id) REFERENCES ${AppConstants.tableMembers}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMediaLists} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        list_type TEXT NOT NULL,
        event_date TEXT,
        payload_json TEXT,
        department_id TEXT NOT NULL DEFAULT '${AppConstants.mediaDepartmentId}',
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMediaRoles} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        role_name TEXT NOT NULL,
        permissions_json TEXT,
        department_id TEXT NOT NULL DEFAULT '${AppConstants.mediaDepartmentId}',
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        is_attendance_operator INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        FOREIGN KEY (member_id) REFERENCES ${AppConstants.tableMembers}(id)
      )
    ''');
  }

  static Future<void> _createAuthTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberAccounts} (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        login_identifier TEXT NOT NULL UNIQUE,
        email TEXT,
        phone TEXT,
        department_id TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        must_change_password INTEGER NOT NULL DEFAULT 1,
        created_by TEXT,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberLoginCredentials} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        credential_type TEXT NOT NULL,
        credential_value TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${AppConstants.tableMemberAccounts}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberPasswordResetLogs} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        action TEXT NOT NULL,
        actor_id TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${AppConstants.tableMemberAccounts}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableMemberAccountSecurity} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL UNIQUE,
        must_change_password INTEGER NOT NULL DEFAULT 1,
        failed_attempts INTEGER NOT NULL DEFAULT 0,
        locked_until TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES ${AppConstants.tableMemberAccounts}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableDepartmentManualLists} (
        id TEXT PRIMARY KEY,
        department_id TEXT NOT NULL,
        department_name TEXT NOT NULL,
        list_title TEXT NOT NULL,
        payload_json TEXT,
        created_by TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableDepartmentManualListEntries} (
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        member_name TEXT NOT NULL,
        notes TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        FOREIGN KEY (list_id) REFERENCES ${AppConstants.tableDepartmentManualLists}(id),
        UNIQUE(list_id, member_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableAuditLogs} (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        actor_id TEXT,
        target_id TEXT,
        metadata_json TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableOfflineActionQueue} (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        payload_json TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _migrateToV9(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableAppNotifications} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        severity TEXT NOT NULL DEFAULT 'info',
        target_role TEXT,
        target_user_id TEXT,
        member_id TEXT,
        route TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableApprovalRequests} (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        target_id TEXT,
        target_label TEXT NOT NULL,
        requested_by TEXT,
        requested_by_name TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        reason TEXT,
        decision_reason TEXT,
        decided_by TEXT,
        risk_level TEXT NOT NULL DEFAULT 'medium',
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableSmartActionHistory} (
        id TEXT PRIMARY KEY,
        action_key TEXT NOT NULL,
        label TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 1,
        message TEXT,
        actor_id TEXT,
        actor_name TEXT,
        city TEXT NOT NULL DEFAULT '${AppConstants.city}',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_app_notifications_read ON ${AppConstants.tableAppNotifications}(is_read)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON ${AppConstants.tableApprovalRequests}(status)',
    );
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_members_department ON ${AppConstants.tableMembers}(department_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_attendance_date ON ${AppConstants.tableMediaAttendance}(session_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_roles_member ON ${AppConstants.tableMediaRoles}(member_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_member_accounts_login ON ${AppConstants.tableMemberAccounts}(login_identifier)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dept_lists_department ON ${AppConstants.tableDepartmentManualLists}(department_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON ${AppConstants.tableAuditLogs}(action)',
    );
  }

  static Future<void> _migrateToV10(Database db) async {
    final cols = [
      'is_merged INTEGER NOT NULL DEFAULT 0',
      'merged_into TEXT',
      'merged_at TEXT',
    ];
    for (final col in cols) {
      try {
        await db.execute(
          'ALTER TABLE ${AppConstants.tableMembers} ADD COLUMN $col',
        );
      } catch (_) {}
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_members_merged ON ${AppConstants.tableMembers}(is_merged)',
    );
  }
}
