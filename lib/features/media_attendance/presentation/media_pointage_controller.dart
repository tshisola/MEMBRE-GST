import '../../../core/members/pointage_member_view.dart';
import '../../../shared/models/attendance_model.dart';

/// Filtres statut pointage.
enum PointageStatusFilter {
  all,
  present,
  late,
  absent,
  excused,
  marked,
  unmarked,
}

/// Filtres liste Média.
enum PointageMediaListFilter {
  all,
  cameraCentre,
  abonnement,
  interieurCombine,
  rejouisseur,
  cameraBaladeuse,
  photographe,
}

/// Labels listes Média (spec utilisateur).
class PointageMediaLists {
  PointageMediaLists._();

  static const cameraCentre = 'Caméra Centre';
  static const abonnement = 'Abonnement';
  static const interieurCombine = 'Intérieur de la Combine';
  static const rejouisseur = 'Réjouisseur';
  static const cameraBaladeuse = 'Caméra Baladeuse';
  static const photographe = 'Photographe';

  static String label(PointageMediaListFilter filter) {
    switch (filter) {
      case PointageMediaListFilter.all:
        return 'Tous';
      case PointageMediaListFilter.cameraCentre:
        return cameraCentre;
      case PointageMediaListFilter.abonnement:
        return abonnement;
      case PointageMediaListFilter.interieurCombine:
        return interieurCombine;
      case PointageMediaListFilter.rejouisseur:
        return rejouisseur;
      case PointageMediaListFilter.cameraBaladeuse:
        return cameraBaladeuse;
      case PointageMediaListFilter.photographe:
        return photographe;
    }
  }

  static bool memberMatchesList(PointageMemberView member, PointageMediaListFilter filter) {
    if (filter == PointageMediaListFilter.all) return true;
    final role = member.role.toLowerCase();
    final name = member.name.toLowerCase();
    switch (filter) {
      case PointageMediaListFilter.cameraCentre:
        return role.contains('camera') || role.contains('caméra') || name.contains('caméra');
      case PointageMediaListFilter.abonnement:
        return role.contains('abonnement') || name.contains('abonnement');
      case PointageMediaListFilter.interieurCombine:
        return role.contains('combine') || name.contains('combine');
      case PointageMediaListFilter.rejouisseur:
        return role.contains('réjou') || role.contains('rejou');
      case PointageMediaListFilter.cameraBaladeuse:
        return role.contains('baladeuse') || name.contains('baladeuse');
      case PointageMediaListFilter.photographe:
        return role.contains('photo') || name.contains('photo');
      case PointageMediaListFilter.all:
        return true;
    }
  }
}

/// Contrôleur logique pointage Média.
class MediaPointageController {
  MediaPointageController({
    this.statusFilter = PointageStatusFilter.all,
    this.mediaListFilter = PointageMediaListFilter.all,
  });

  PointageStatusFilter statusFilter;
  PointageMediaListFilter mediaListFilter;
  String searchQuery = '';

  List<PointageMemberView> applyFilters({
    required List<PointageMemberView> members,
    required Map<String, MediaAttendanceStatus> attendance,
    required String searchQuery,
  }) {
    this.searchQuery = searchQuery;
    var result = List<PointageMemberView>.from(members);

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((m) => m.matchesQuery(q)).toList();
    }

    result = result
        .where((m) => PointageMediaLists.memberMatchesList(m, mediaListFilter))
        .toList();

    switch (statusFilter) {
      case PointageStatusFilter.all:
        break;
      case PointageStatusFilter.present:
        result = result
            .where((m) => attendance[m.id] == MediaAttendanceStatus.present)
            .toList();
      case PointageStatusFilter.late:
        result = result
            .where((m) => attendance[m.id] == MediaAttendanceStatus.late)
            .toList();
      case PointageStatusFilter.absent:
        result = result
            .where((m) =>
                attendance[m.id] == null ||
                attendance[m.id] == MediaAttendanceStatus.absent)
            .toList();
      case PointageStatusFilter.excused:
        result = result
            .where((m) => attendance[m.id] == MediaAttendanceStatus.excused)
            .toList();
      case PointageStatusFilter.marked:
        result = result.where((m) => attendance.containsKey(m.id)).toList();
      case PointageStatusFilter.unmarked:
        result = result.where((m) => !attendance.containsKey(m.id)).toList();
    }

    return result;
  }

  PointageCounters computeCounters({
    required List<PointageMemberView> members,
    required Map<String, MediaAttendanceStatus> attendance,
  }) {
    var present = 0;
    var absent = 0;
    var late = 0;
    var excused = 0;
    var marked = 0;
    for (final m in members) {
      final status = attendance[m.id];
      if (status != null) {
        marked++;
        switch (status) {
          case MediaAttendanceStatus.present:
            present++;
          case MediaAttendanceStatus.late:
            late++;
          case MediaAttendanceStatus.absent:
            absent++;
          case MediaAttendanceStatus.excused:
            excused++;
        }
      }
    }
    return PointageCounters(
      total: members.length,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
      marked: marked,
      unmarked: members.length - marked,
    );
  }

  bool canPointMember({
    required bool operatorCanTakeAttendance,
    String? operatorMemberId,
    required String targetMemberId,
  }) {
    if (!operatorCanTakeAttendance) return false;
    if (operatorMemberId != null && operatorMemberId == targetMemberId) {
      return false;
    }
    return true;
  }
}

class PointageCounters {
  const PointageCounters({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    this.excused = 0,
    required this.marked,
    required this.unmarked,
  });

  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int marked;
  final int unmarked;
}

/// Alias contrôleur recherche.
typedef PointageSearchController = MediaPointageController;
