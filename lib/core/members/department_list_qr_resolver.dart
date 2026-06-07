import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../../shared/models/member_account_model.dart';
import '../database/database_helper.dart';

/// QR / member code lookup for department list PDF & CSV exports.
class MemberExportQrInfo {
  const MemberExportQrInfo({
    required this.memberCode,
    required this.qrData,
  });

  final String memberCode;
  final String qrData;
}

class DepartmentListQrResolver {
  DepartmentListQrResolver({LocalMemberRepository? members})
      : _members = members ?? LocalMemberRepository();

  final LocalMemberRepository _members;

  Future<Map<String, MemberExportQrInfo>> resolveForList(
    DepartmentManualList list,
  ) async {
    final result = <String, MemberExportQrInfo>{};
    for (final entry in list.entries) {
      final info = await _resolveEntry(entry);
      if (info != null) {
        result[entry.memberId] = info;
      }
    }
    return result;
  }

  Future<MemberExportQrInfo?> _resolveEntry(
    DepartmentManualListEntry entry,
  ) async {
    final byId = await _members.getById(entry.memberId);
    if (byId != null && byId.qrData.isNotEmpty) {
      return MemberExportQrInfo(
        memberCode: byId.memberCode,
        qrData: byId.qrData,
      );
    }

    final db = await DatabaseHelper.instance.database;
    final name = entry.memberName.trim().toLowerCase();
    if (name.isEmpty) return null;

    final rows = await db.query(
      AppConstants.tableMembers,
      where: "LOWER(full_name) = ? OR LOWER(first_name || ' ' || last_name) = ?",
      whereArgs: [name, name],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final member = IfcmMemberRecord.fromSqlite(rows.first);
    if (member.qrData.isEmpty) return null;

    return MemberExportQrInfo(
      memberCode: member.memberCode,
      qrData: member.qrData,
    );
  }
}
