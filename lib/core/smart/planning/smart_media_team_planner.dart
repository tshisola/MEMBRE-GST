import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../models/smart_models.dart';
import '../score/member_media_score_engine.dart';

/// Postes du dimanche pour planification intelligente.
class SmartMediaTeamPlanner {
  SmartMediaTeamPlanner({
    LocalMemberRepository? repo,
    RoleRotationEngine? rotation,
    MemberMediaScoreEngine? scorer,
  })  : _repo = repo ?? LocalMemberRepository(),
        _rotation = rotation ?? RoleRotationEngine(),
        _scorer = scorer ?? MemberMediaScoreEngine();

  final LocalMemberRepository _repo;
  final RoleRotationEngine _rotation;
  final MemberMediaScoreEngine _scorer;

  static const sundayPosts = [
    ('camera_centre', 'Caméra Centre'),
    ('abonnement', 'Abonnement'),
    ('interieur_combine', 'Intérieur de la Combine'),
    ('rejouisseur', 'Réjouisseur'),
    ('camera_baladeuse', 'Caméra Baladeuse'),
    ('photographe', 'Photographe'),
  ];

  Future<SundayTeamPlan> generate({DateTime? serviceDate}) async {
    final date = serviceDate ?? _nextSunday();
    final members = await _repo.listActive();
    final mediaMembers = members.where(_isMediaMember).toList();
    final scores = mediaMembers.map(_scorer.scoreMember).toList();
    scores.sort((a, b) => b.score.compareTo(a.score));

    final used = <String>{};
    final posts = <SundayTeamPost>[];
    final notes = <String>[];

    for (var i = 0; i < sundayPosts.length; i++) {
      final post = sundayPosts[i];
      final candidate = _rotation.pickMember(
        postId: post.$1,
        candidates: mediaMembers,
        usedIds: used,
        weekIndex: _weekIndex(date),
        slotIndex: i,
      );
      if (candidate != null) {
        used.add(candidate.id);
        final sc = _scorer.scoreMember(candidate).score;
        posts.add(SundayTeamPost(
          id: post.$1,
          label: post.$2,
          assignedMemberId: candidate.id,
          assignedMemberName: candidate.displayName,
          confidence: sc,
        ));
      } else {
        posts.add(SundayTeamPost(id: post.$1, label: post.$2));
        notes.add('Poste « ${post.$2} » non couvert — ajoutez un membre.');
      }
    }

    if (used.length < sundayPosts.length) {
      notes.add('Complétez l\'équipe manuellement si nécessaire.');
    }

    await _rotation.recordAssignments(date, posts);
    return SundayTeamPlan(serviceDate: date, posts: posts, notes: notes);
  }

  bool _isMediaMember(IfcmMemberRecord m) {
    final dept = m.departmentId?.toLowerCase() ?? '';
    final name = m.departmentName?.toLowerCase() ?? '';
    return dept == AppConstants.mediaDepartmentId ||
        name.contains('media') ||
        name.contains('média');
  }

  DateTime _nextSunday() {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day);
    while (d.weekday != DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  int _weekIndex(DateTime date) =>
      date.difference(DateTime(2024, 1, 7)).inDays ~/ 7;
}

typedef TeamRotationEngine = RoleRotationEngine;
typedef AvailabilityEngine = RoleRotationEngine;
typedef SkillMatchingEngine = MemberMediaScoreEngine;
typedef SundayTeamSuggestionService = SmartMediaTeamPlanner;

/// Rotation équitable des postes.
class RoleRotationEngine {
  static const _historyKey = 'media_post_rotation_history';

  IfcmMemberRecord? pickMember({
    required String postId,
    required List<IfcmMemberRecord> candidates,
    required Set<String> usedIds,
    required int weekIndex,
    required int slotIndex,
  }) {
    final pool = candidates.where((c) => !usedIds.contains(c.id)).toList();
    if (pool.isEmpty) return null;
    pool.sort((a, b) => a.displayName.compareTo(b.displayName));
    final index = (weekIndex + slotIndex + postId.hashCode) % pool.length;
    return pool[index];
  }

  Future<void> recordAssignments(
    DateTime date,
    List<SundayTeamPost> posts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    final history = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    history[date.toIso8601String()] = {
      for (final p in posts)
        if (p.assignedMemberId != null) p.id: p.assignedMemberId,
    };
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  Future<Map<String, int>> usageCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return {};
    final history = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final counts = <String, int>{};
    for (final entry in history.values) {
      if (entry is! Map) continue;
      for (final memberId in entry.values) {
        if (memberId is String) {
          counts[memberId] = (counts[memberId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}

typedef MediaPostHistoryService = RoleRotationEngine;
typedef FairAssignmentService = RoleRotationEngine;
typedef RotationSuggestionCard = SundayTeamPost;
