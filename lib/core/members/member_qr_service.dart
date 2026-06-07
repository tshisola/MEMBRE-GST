import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';

/// Generates unique IFCM-LUB-YYYY-000001 member codes.
class UniqueMemberCodeGenerator {
  UniqueMemberCodeGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<String> generate() async {
    final db = await DatabaseHelper.instance.database;
    final year = DateTime.now().year;
    final prefix = '${AppConstants.memberCodePrefix}-$year-';

    final rows = await db.rawQuery(
      'SELECT member_code FROM ${AppConstants.tableMembers} '
      "WHERE member_code LIKE ? ORDER BY member_code DESC LIMIT 1",
      ['$prefix%'],
    );

    var seq = 1;
    if (rows.isNotEmpty) {
      final last = rows.first['member_code'] as String?;
      if (last != null && last.contains('-')) {
        final parts = last.split('-');
        if (parts.length >= 4) {
          seq = (int.tryParse(parts.last) ?? 0) + 1;
        }
      }
    }

    for (var attempt = 0; attempt < 100; attempt++) {
      final code = '$prefix${seq.toString().padLeft(6, '0')}';
      final exists = await db.query(
        AppConstants.tableMembers,
        where: 'member_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (exists.isEmpty) return code;
      seq++;
    }

    return '$prefix${_uuid.v4().substring(0, 6).toUpperCase()}';
  }
}

/// Generates stable unique QR identifiers per member.
class UniqueQrCodeGenerator {
  UniqueQrCodeGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  String generateQrCodeId() => 'QR-${_uuid.v4()}';

  String buildQrData({
    required String memberCode,
    required String localId,
    String? cloudId,
    String? uuidSuffix,
  }) {
    final uid = uuidSuffix ?? localId.substring(0, 8);
    final effectiveCloudId = cloudId ?? localId;
    return 'IFCM|${AppConstants.city}|$memberCode|$localId|$effectiveCloudId|$uid';
  }

  String updateQrDataWithCloudId(String qrData, String cloudId) {
    final parts = qrData.split('|');
    if (parts.length >= 5) {
      parts[4] = cloudId;
      return parts.join('|');
    }
    return buildQrData(
      memberCode: parts.length > 2 ? parts[2] : '',
      localId: parts.length > 3 ? parts[3] : '',
      cloudId: cloudId,
    );
  }
}

/// Ensures QR codes and member codes are never duplicated.
class QrDuplicateChecker {
  Future<bool> isMemberCodeTaken(String code) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMembers,
      where: 'member_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> isQrCodeIdTaken(String qrCodeId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMemberQrCodes,
      where: 'qr_code_id = ?',
      whereArgs: [qrCodeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> isQrDataTaken(String qrData) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMemberQrCodes,
      where: 'qr_data = ?',
      whereArgs: [qrData],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}

class MemberQrService {
  MemberQrService({
    UniqueMemberCodeGenerator? codeGen,
    UniqueQrCodeGenerator? qrGen,
    QrDuplicateChecker? checker,
    Uuid? uuid,
  })  : _codeGen = codeGen ?? UniqueMemberCodeGenerator(),
        _qrGen = qrGen ?? UniqueQrCodeGenerator(),
        _checker = checker ?? QrDuplicateChecker(),
        _uuid = uuid ?? const Uuid();

  final UniqueMemberCodeGenerator _codeGen;
  final UniqueQrCodeGenerator _qrGen;
  final QrDuplicateChecker _checker;
  final Uuid _uuid;

  Future<({String memberCode, String qrCodeId, String qrData})> generate({
    required String localId,
    String? cloudId,
  }) async {
    final memberCode = await _codeGen.generate();
    var qrCodeId = _qrGen.generateQrCodeId();
    while (await _checker.isQrCodeIdTaken(qrCodeId)) {
      qrCodeId = _qrGen.generateQrCodeId();
    }

    var qrData = _qrGen.buildQrData(
      memberCode: memberCode,
      localId: localId,
      cloudId: cloudId,
    );
    while (await _checker.isQrDataTaken(qrData)) {
      qrData = _qrGen.buildQrData(
        memberCode: memberCode,
        localId: '${localId}_${_uuid.v4().substring(0, 4)}',
        cloudId: cloudId,
      );
    }

    return (memberCode: memberCode, qrCodeId: qrCodeId, qrData: qrData);
  }

  Future<void> saveQrRecord({
    required String memberId,
    required String memberCode,
    required String qrCodeId,
    required String qrData,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(AppConstants.tableMemberQrCodes, {
      'id': _uuid.v4(),
      'member_id': memberId,
      'member_code': memberCode,
      'qr_code_id': qrCodeId,
      'qr_data': qrData,
      'created_at': now,
      'is_active': 1,
      'city': AppConstants.city,
    });
  }
}
