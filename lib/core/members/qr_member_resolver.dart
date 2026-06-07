import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firebase_member_service.dart';
import '../firebase/firestore_service.dart';
import '../logging/technical_error_repository.dart';
import 'attendance_member_query_service.dart';
import 'pointage_member_view.dart';

/// Recherche QR locale (SQLite).
class LocalQrLookup {
  LocalQrLookup({LocalMemberRepository? repo, AttendanceMemberQueryService? query})
      : _query = query ?? AttendanceMemberQueryService();

  final AttendanceMemberQueryService _query;

  Future<PointageMemberView?> find(String qrOrCode) =>
      _query.findByQrOrCode(qrOrCode);
}

/// Recherche QR Firebase puis cache locale.
class FirebaseQrLookup {
  FirebaseQrLookup({
    FirestoreService? firestore,
    LocalMemberRepository? localRepo,
    FirebaseMemberRepository? memberRepo,
  })  : _firestore = firestore ?? FirestoreService(),
        _local = localRepo ?? LocalMemberRepository(),
        _memberRepo = memberRepo ?? FirebaseMemberRepository();

  final FirestoreService _firestore;
  final LocalMemberRepository _local;
  final FirebaseMemberRepository _memberRepo;

  Future<PointageMemberView?> find(String qrOrCode) async {
    if (!FirebaseInitializer.isInitialized) return null;
    try {
      final rows = await _firestore.queryCollection(
        AppConstants.collectionMemberQrCodes,
        queryBuilder: (ref) => ref.where('qrData', isEqualTo: qrOrCode.trim()),
      );
      if (rows.isEmpty) {
        final byCode = await _firestore.queryCollection(
          AppConstants.collectionMemberQrCodes,
          queryBuilder: (ref) =>
              ref.where('memberCode', isEqualTo: qrOrCode.trim()),
        );
        if (byCode.isEmpty) return null;
        final memberId = byCode.first['memberId'] as String?;
        if (memberId == null) return null;
        return _loadAndCacheMember(memberId);
      }
      final memberId = rows.first['memberId'] as String?;
      if (memberId == null) return null;
      return _loadAndCacheMember(memberId);
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'firebase_qr_lookup',
        error: e,
        stack: st,
      );
      return null;
    }
  }

  Future<PointageMemberView?> _loadAndCacheMember(String memberId) async {
    final remoteList = await _memberRepo.fetchAll();
    IfcmMemberRecord? remote;
    for (final r in remoteList) {
      if (r.localId == memberId || r.id == memberId) {
        remote = r;
        break;
      }
    }
    if (remote == null || !remote.isActive || remote.isDeleted) return null;
    await _local.upsert(
      remote.copyWith(syncStatus: AppConstants.syncStatusSynced),
    );
    return PointageMemberView.fromRecord(remote);
  }
}

/// Résout un QR : SQLite d'abord, Firebase ensuite.
class QrMemberResolver {
  QrMemberResolver({
    LocalQrLookup? local,
    FirebaseQrLookup? remote,
  })  : _local = local ?? LocalQrLookup(),
        _remote = remote ?? FirebaseQrLookup();

  final LocalQrLookup _local;
  final FirebaseQrLookup _remote;

  Future<QrMemberResolveResult> resolve(String qrOrCode) async {
    final normalized = qrOrCode.trim();
    if (normalized.isEmpty) {
      return const QrMemberResolveResult.notFound();
    }

    final local = await _local.find(normalized);
    if (local != null) {
      if (!local.isActive) {
        return const QrMemberResolveResult.blocked(
          reason: 'Ce membre est désactivé.',
        );
      }
      return QrMemberResolveResult.found(local, source: 'local');
    }

    final remote = await _remote.find(normalized);
    if (remote != null) {
      if (!remote.isActive) {
        return const QrMemberResolveResult.blocked(
          reason: 'Ce membre est désactivé.',
        );
      }
      return QrMemberResolveResult.found(remote, source: 'firebase');
    }

    return const QrMemberResolveResult.notFound();
  }
}

class QrMemberResolveResult {
  const QrMemberResolveResult._({
    required this.found,
    this.member,
    this.source,
    this.blockedReason,
  });

  const QrMemberResolveResult.found(PointageMemberView member, {String? source})
      : this._(found: true, member: member, source: source);

  const QrMemberResolveResult.notFound()
      : this._(found: false);

  const QrMemberResolveResult.blocked({required String reason})
      : this._(found: false, blockedReason: reason);

  final bool found;
  final PointageMemberView? member;
  final String? source;
  final String? blockedReason;

  bool get isBlocked => blockedReason != null;
}

typedef PointageQrScannerService = QrMemberResolver;
