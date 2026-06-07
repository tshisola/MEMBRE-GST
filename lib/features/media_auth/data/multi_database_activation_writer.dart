import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/members/member_qr_service.dart';
import '../../../shared/models/media_activation_request.dart';

/// Écrit le profil activé dans toutes les tables locales nécessaires.
class MultiDatabaseActivationWriter {
  MultiDatabaseActivationWriter({
    Uuid? uuid,
    MemberQrService? qrService,
  })  : _uuid = uuid ?? const Uuid(),
        _qrService = qrService ?? MemberQrService();

  final Uuid _uuid;
  final MemberQrService _qrService;

  Future<ActivationWriteResult> writeActivatedProfile({
    required MediaActivationRequest request,
    String? existingMemberId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    final memberId = existingMemberId ?? _uuid.v4();
    final qr = await _qrService.generate(localId: memberId);
    final memberCode = qr.memberCode;
    await _qrService.saveQrRecord(
      memberId: memberId,
      memberCode: memberCode,
      qrCodeId: qr.qrCodeId,
      qrData: qr.qrData,
    );

    final nameParts = (request.displayName ?? request.email).split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Membre';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Média';

    await db.transaction((txn) async {
      final existingMember = await txn.query(
        AppConstants.tableMembers,
        where: 'id = ?',
        whereArgs: [memberId],
        limit: 1,
      );
      if (existingMember.isEmpty) {
        await txn.insert(AppConstants.tableMembers, {
          'id': memberId,
          'first_name': firstName,
          'last_name': lastName,
          'email': request.email,
          'department_id': AppConstants.mediaDepartmentId,
          'role': AppConstants.roleMediaMember,
          'member_code': memberCode,
          'city': AppConstants.city,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'sync_status': AppConstants.syncStatusPending,
        });
      }

      final existingAccount = await txn.query(
        AppConstants.tableMemberAccounts,
        where: 'member_id = ? OR LOWER(email) = ?',
        whereArgs: [memberId, request.email],
        limit: 1,
      );
      if (existingAccount.isEmpty) {
        await txn.insert(AppConstants.tableMemberAccounts, {
          'id': _uuid.v4(),
          'member_id': memberId,
          'login_identifier': request.email,
          'email': request.email,
          'department_id': AppConstants.mediaDepartmentId,
          'is_active': 1,
          'must_change_password': 0,
          'password_hash': 'google_oauth',
          'password_salt': request.firebaseUid,
          'city': AppConstants.city,
          'created_at': now,
          'updated_at': now,
        });
      }

      await txn.insert(
        AppConstants.tableMediaMembers,
        {
          'id': memberId,
          'firebase_uid': request.firebaseUid,
          'member_id': memberId,
          'email': request.email,
          'display_name': request.displayName,
          'photo_url': request.photoUrl,
          'role': AppConstants.roleMediaMember,
          'department_id': AppConstants.mediaDepartmentId,
          'member_code': memberCode,
          'qr_code_id': qr.qrCodeId,
          'status': AppConstants.activationStatusActive,
          'activation_completed': 1,
          'city': AppConstants.city,
          'created_at': now,
          'updated_at': now,
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(AppConstants.tableAuditLogs, {
        'id': _uuid.v4(),
        'action': 'media_google_activation',
        'actor_id': request.reviewedBy,
        'target_id': memberId,
        'metadata_json': jsonEncode({
          'firebaseUid': request.firebaseUid,
          'email': request.email,
          'public': true,
        }),
        'city': AppConstants.city,
        'created_at': now,
      });

      await txn.insert(AppConstants.tableActivationLogs, {
        'id': _uuid.v4(),
        'request_id': request.id,
        'action': 'activated',
        'actor_id': request.reviewedBy,
        'metadata_json': jsonEncode({'memberId': memberId}),
        'city': AppConstants.city,
        'created_at': now,
      });
    });

    return ActivationWriteResult(
      memberId: memberId,
      memberCode: memberCode,
      qrCodeId: qr.qrCodeId,
      qrData: qr.qrData,
    );
  }
}

class ActivationWriteResult {
  const ActivationWriteResult({
    required this.memberId,
    required this.memberCode,
    required this.qrCodeId,
    required this.qrData,
  });

  final String memberId;
  final String memberCode;
  final String qrCodeId;
  final String qrData;
}
