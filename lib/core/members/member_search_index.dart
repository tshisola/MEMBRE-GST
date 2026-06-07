import 'pointage_member_view.dart';

/// Index de recherche pointage — fonctionne hors ligne sur SQLite.
class MemberSearchIndex {
  MemberSearchIndex(this.members);

  final List<PointageMemberView> members;

  List<PointageMemberView> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return List<PointageMemberView>.from(members);
    return members.where((m) => m.matchesQuery(q)).toList();
  }

  PointageMemberView? findExactCodeOrQr(String codeOrQr) {
    final normalized = codeOrQr.trim();
    if (normalized.isEmpty) return null;
    for (final m in members) {
      if (m.memberCode == normalized) return m;
      if (m.qrData == normalized) return m;
      if (m.id == normalized) return m;
    }
    return null;
  }
}

/// Alias recherche type Excel.
typedef ExcelLikePointageSearch = MemberSearchIndex;
