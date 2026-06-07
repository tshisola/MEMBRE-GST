import '../../../app/constants.dart';
import '../database/database_helper.dart';
import '../members/member_duplicate_detector.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import 'models/smart_models.dart';

/// Analyse la qualité des données membres.
class DataQualityEngine {
  DataQualityEngine({
    LocalMemberRepository? repo,
    DuplicateDetector? duplicates,
    MissingDataDetector? missing,
  })  : _repo = repo ?? LocalMemberRepository(),
        _duplicates = duplicates ?? DuplicateDetector(),
        _missing = missing ?? MissingDataDetector();

  final LocalMemberRepository _repo;
  final DuplicateDetector _duplicates;
  final MissingDataDetector _missing;

  Future<DataQualityReport> analyze() async {
    final active = await _repo.listActive();
    final issues = <SmartIssue>[];

    final dupPhones = await _duplicates.countDuplicatePhones();
    final dupNames = await _duplicates.countDuplicateNames();
    final missingQr = _missing.countMissingQr(active);
    final missingPhone = _missing.countMissingPhone(active);
    final missingDept = _missing.countMissingDepartment(active);
    final missingCommune = _missing.countMissingCommune(active);
    final missingRole = _missing.countMissingRole(active);

    if (dupPhones > 0) {
      issues.add(SmartIssue(
        id: 'dup_phone',
        title: '$dupPhones doublon(s) de téléphone',
        message: 'Vérifiez les numéros en double.',
        category: SmartIssueCategory.duplicate,
        severity: SmartIssueSeverity.warning,
        detailRoute: '/smart/data-quality',
      ));
    }
    if (dupNames > 0) {
      issues.add(SmartIssue(
        id: 'dup_name',
        title: '$dupNames doublon(s) de nom possible(s)',
        message: 'Des noms similaires ont été détectés.',
        category: SmartIssueCategory.duplicate,
        severity: SmartIssueSeverity.info,
        detailRoute: '/smart/data-quality',
      ));
    }

    issues.addAll(_missing.toIssues(active));

    final penalty = dupPhones * 8 +
        dupNames * 4 +
        missingQr * 3 +
        missingPhone * 4 +
        missingDept * 3 +
        missingCommune * 2 +
        missingRole * 2;
    final score = (100 - penalty).clamp(0, 100);

    return DataQualityReport(
      score: score,
      issues: issues,
      duplicatePhoneCount: dupPhones,
      missingQrCount: missingQr,
      missingPhoneCount: missingPhone,
      missingDepartmentCount: missingDept,
    );
  }
}

/// Détecte les doublons.
class DuplicateDetector {
  DuplicateDetector({MemberDuplicateDetector? detector})
      : _detector = detector ?? MemberDuplicateDetector();

  final MemberDuplicateDetector _detector;

  Future<int> countDuplicatePhones() => _detector.scanDuplicatePhoneGroups();

  Future<int> countDuplicateNames() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT LOWER(COALESCE(full_name, first_name || \' \' || last_name)) as n, '
        'COUNT(*) as c FROM ${AppConstants.tableMembers} '
        'WHERE is_deleted = 0 GROUP BY n HAVING c > 1',
      );
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countDuplicateQr() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT qr_data, COUNT(*) as c FROM ${AppConstants.tableMembers} '
        "WHERE qr_data IS NOT NULL AND TRIM(qr_data) != '' "
        'AND is_deleted = 0 GROUP BY qr_data HAVING c > 1',
      );
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}

/// Détecte les champs manquants.
class MissingDataDetector {
  int countMissingQr(List<IfcmMemberRecord> members) =>
      members.where((m) => m.qrData.isEmpty).length;

  int countMissingPhone(List<IfcmMemberRecord> members) =>
      members.where((m) => m.phone == null || m.phone!.trim().isEmpty).length;

  int countMissingDepartment(List<IfcmMemberRecord> members) =>
      members
          .where(
            (m) =>
                (m.departmentId == null || m.departmentId!.isEmpty) &&
                (m.departmentName == null || m.departmentName!.isEmpty),
          )
          .length;

  int countMissingCommune(List<IfcmMemberRecord> members) =>
      members.where((m) => m.commune.trim().isEmpty).length;

  int countMissingRole(List<IfcmMemberRecord> members) =>
      members.where((m) => m.role.trim().isEmpty || m.role == 'member').length;

  List<SmartIssue> toIssues(List<IfcmMemberRecord> members) {
    final issues = <SmartIssue>[];
    final qr = countMissingQr(members);
    if (qr > 0) {
      issues.add(SmartIssue(
        id: 'quality_qr',
        title: '$qr membre(s) sans QR Code',
        message: 'Complétez les QR Code pour le pointage.',
        category: SmartIssueCategory.qrCode,
        severity: SmartIssueSeverity.warning,
      ));
    }
    final phone = countMissingPhone(members);
    if (phone > 0) {
      issues.add(SmartIssue(
        id: 'quality_phone',
        title: '$phone membre(s) sans téléphone',
        message: 'Ajoutez les numéros de contact.',
        category: SmartIssueCategory.dataQuality,
        severity: SmartIssueSeverity.info,
      ));
    }
    return issues;
  }
}

/// Réparations qualité données.
class DataRepairService {
  DataRepairService({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<SmartActionResult> repairMissingDepartments() async {
    final active = await _repo.listActive();
    var fixed = 0;
    for (final m in active) {
      if (m.departmentId != null && m.departmentId!.isNotEmpty) continue;
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          AppConstants.tableMembers,
          {
            'department_id': AppConstants.mediaDepartmentId,
            'department_name': 'Département Média',
            'sync_status': AppConstants.syncStatusPending,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [m.id],
        );
        fixed++;
      } catch (_) {}
    }
    return (
      success: true,
      message: '$fixed département(s) attribué(s).',
      fixedCount: fixed,
    );
  }
}

typedef DataQualityDashboard = DataQualityEngine;
