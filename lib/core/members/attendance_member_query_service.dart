import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import 'firebase_member_merger.dart';
import 'pointage_member_view.dart';

/// Charge les membres pour le pointage — SQLite local-first, fusion Firebase ensuite.
class AttendanceMemberQueryService {
  AttendanceMemberQueryService({
    LocalMemberRepository? repo,
    FirebaseMemberMerger? merger,
  })  : _repo = repo ?? LocalMemberRepository(),
        _merger = merger ?? FirebaseMemberMerger();

  final LocalMemberRepository _repo;
  final FirebaseMemberMerger _merger;

  /// Membres actifs pour pointage Média — inclut pending/local/synced.
  Future<List<PointageMemberView>> loadForMediaPointage({
    bool mergeFirebase = true,
  }) async {
    if (mergeFirebase) {
      await _merger.mergeIfAvailable();
    }
    return _loadFromSqlite();
  }

  Future<List<PointageMemberView>> _loadFromSqlite() async {
    final records = await _repo.listActive();
    final eligible = records.where(_isEligibleForMediaPointage).toList();
    final source = eligible.isEmpty && records.isNotEmpty ? records : eligible;
    source.sort((a, b) => a.displayName.compareTo(b.displayName));
    return source.map(PointageMemberView.fromRecord).toList();
  }

  /// Recherche locale pour scanner QR / recherche pointage.
  Future<PointageMemberView?> findByQrOrCode(String qrOrCode) async {
    final record = await _repo.findByQrData(qrOrCode.trim());
    if (record == null || !_isEligibleForMediaPointage(record)) return null;
    return PointageMemberView.fromRecord(record);
  }

  bool _isEligibleForMediaPointage(IfcmMemberRecord m) {
    if (!m.isActive || m.isDeleted) return false;
    if (_matchesMediaDepartment(m) || _hasNoDepartment(m)) return true;
    if (m.syncStatus == AppConstants.syncStatusPending ||
        m.syncStatus == AppConstants.syncStatusLocal) {
      return true;
    }
    return false;
  }

  bool _matchesMediaDepartment(IfcmMemberRecord m) {
    final deptId = m.departmentId?.toLowerCase() ?? '';
    final deptName = m.departmentName?.toLowerCase() ?? '';
    return deptId == AppConstants.mediaDepartmentId ||
        deptName.contains('media') ||
        deptName.contains('média');
  }

  bool _hasNoDepartment(IfcmMemberRecord m) {
    return (m.departmentId == null || m.departmentId!.isEmpty) &&
        (m.departmentName == null || m.departmentName!.isEmpty);
  }
}

/// Alias explicite pour le chargement pointage.
typedef PointageMemberLoader = AttendanceMemberQueryService;

/// Alias repository pointage.
typedef AttendanceMemberRepository = AttendanceMemberQueryService;

/// Alias loader local-first.
typedef LocalFirstMemberLoader = AttendanceMemberQueryService;
