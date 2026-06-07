/// Modèles pour l'intelligence MEDIA LUBUMBASHI.
library;

enum SmartIssueSeverity { info, warning, critical }

enum SmartIssueCategory {
  pointage,
  sync,
  dataQuality,
  qrCode,
  department,
  list,
  duplicate,
  attendance,
  general,
}

enum SmartIssueAction {
  autoFix,
  viewDetails,
  ignore,
  refreshSync,
  openPointage,
  openMember,
}

class SmartIssue {
  const SmartIssue({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.severity = SmartIssueSeverity.warning,
    this.memberId,
    this.memberName,
    this.suggestedAction = SmartIssueAction.viewDetails,
    this.autoFixable = false,
    this.detailRoute,
  });

  final String id;
  final String title;
  final String message;
  final SmartIssueCategory category;
  final SmartIssueSeverity severity;
  final String? memberId;
  final String? memberName;
  final SmartIssueAction suggestedAction;
  final bool autoFixable;
  final String? detailRoute;
}

class SmartRecommendation {
  const SmartRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.actionLabel,
    this.route,
    this.priority = 0,
  });

  final String id;
  final String title;
  final String description;
  final String? actionLabel;
  final String? route;
  final int priority;
}

class SmartAssistantReport {
  const SmartAssistantReport({
    required this.issues,
    required this.recommendations,
    required this.dataQualityScore,
    required this.syncHealthScore,
    required this.servicePrepScore,
    required this.criticalCount,
    required this.generatedAt,
  });

  final List<SmartIssue> issues;
  final List<SmartRecommendation> recommendations;
  final int dataQualityScore;
  final int syncHealthScore;
  final int servicePrepScore;
  final int criticalCount;
  final DateTime generatedAt;

  static SmartAssistantReport empty() => SmartAssistantReport(
        issues: const [],
        recommendations: const [],
        dataQualityScore: 100,
        syncHealthScore: 100,
        servicePrepScore: 0,
        criticalCount: 0,
        generatedAt: DateTime.now(),
      );
}

class DataQualityReport {
  const DataQualityReport({
    required this.score,
    required this.issues,
    required this.duplicatePhoneCount,
    required this.missingQrCount,
    required this.missingPhoneCount,
    required this.missingDepartmentCount,
  });

  final int score;
  final List<SmartIssue> issues;
  final int duplicatePhoneCount;
  final int missingQrCount;
  final int missingPhoneCount;
  final int missingDepartmentCount;
}

enum MemberScoreBadge {
  excellent,
  regular,
  watch,
  inactive,
  newMember;

  String get label {
    switch (this) {
      case MemberScoreBadge.excellent:
        return 'Excellent';
      case MemberScoreBadge.regular:
        return 'Régulier';
      case MemberScoreBadge.watch:
        return 'À surveiller';
      case MemberScoreBadge.inactive:
        return 'Inactif';
      case MemberScoreBadge.newMember:
        return 'Nouveau';
    }
  }
}

class MemberMediaScore {
  const MemberMediaScore({
    required this.memberId,
    required this.score,
    required this.badge,
    required this.factors,
  });

  final String memberId;
  final int score;
  final MemberScoreBadge badge;
  final Map<String, int> factors;
}

class PointageVisibilityReport {
  const PointageVisibilityReport({
    required this.invisibleMembers,
    required this.visibleCount,
    required this.activeCount,
  });

  final List<InvisiblePointageMember> invisibleMembers;
  final int visibleCount;
  final int activeCount;
}

class InvisiblePointageMember {
  const InvisiblePointageMember({
    required this.memberId,
    required this.name,
    required this.reason,
    required this.repairable,
  });

  final String memberId;
  final String name;
  final String reason;
  final bool repairable;
}

class SyncHealthReport {
  const SyncHealthReport({
    required this.score,
    required this.pendingCount,
    required this.failedCount,
    required this.localOnlyCount,
    required this.issues,
  });

  final int score;
  final int pendingCount;
  final int failedCount;
  final int localOnlyCount;
  final List<SmartIssue> issues;
}

class AttendanceRiskMember {
  const AttendanceRiskMember({
    required this.memberId,
    required this.name,
    required this.riskLevel,
    required this.reason,
    required this.riskType,
  });

  final String memberId;
  final String name;
  final int riskLevel;
  final String reason;
  final String riskType;
}

class SundayTeamPost {
  const SundayTeamPost({
    required this.id,
    required this.label,
    this.assignedMemberId,
    this.assignedMemberName,
    this.confidence = 0,
  });

  final String id;
  final String label;
  final String? assignedMemberId;
  final String? assignedMemberName;
  final int confidence;

  SundayTeamPost copyWith({
    String? assignedMemberId,
    String? assignedMemberName,
    int? confidence,
  }) {
    return SundayTeamPost(
      id: id,
      label: label,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      assignedMemberName: assignedMemberName ?? this.assignedMemberName,
      confidence: confidence ?? this.confidence,
    );
  }
}

class SundayTeamPlan {
  const SundayTeamPlan({
    required this.serviceDate,
    required this.posts,
    required this.notes,
  });

  final DateTime serviceDate;
  final List<SundayTeamPost> posts;
  final List<String> notes;
}

class ServiceChecklistItem {
  const ServiceChecklistItem({
    required this.id,
    required this.label,
    this.done = false,
  });

  final String id;
  final String label;
  final bool done;

  ServiceChecklistItem copyWith({bool? done}) =>
      ServiceChecklistItem(id: id, label: label, done: done ?? this.done);
}

class PostServiceReport {
  const PostServiceReport({
    required this.serviceDate,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.onTimeCount,
    required this.coveredPosts,
    required this.uncoveredPosts,
    required this.serviceScore,
    required this.recommendations,
  });

  final DateTime serviceDate;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int onTimeCount;
  final int coveredPosts;
  final int uncoveredPosts;
  final int serviceScore;
  final List<String> recommendations;
}

class DeletionImpactReport {
  const DeletionImpactReport({
    required this.memberId,
    required this.memberName,
    required this.attendanceRecords,
    required this.listAppearances,
    required this.hasQr,
    required this.syncStatus,
    required this.warnings,
    required this.impactLevel,
  });

  final String memberId;
  final String memberName;
  final int attendanceRecords;
  final int listAppearances;
  final bool hasQr;
  final String syncStatus;
  final List<String> warnings;
  final String impactLevel;
}

class SmartDashboardSnapshot {
  const SmartDashboardSnapshot({
    required this.activeMembers,
    required this.pointageVisible,
    required this.pointageInvisible,
    required this.incompleteLists,
    required this.pendingSync,
    required this.missingQr,
    required this.criticalAlerts,
    required this.dataQualityScore,
    required this.syncScore,
    required this.prepScore,
    required this.frequentLate,
    required this.frequentAbsent,
  });

  final int activeMembers;
  final int pointageVisible;
  final int pointageInvisible;
  final int incompleteLists;
  final int pendingSync;
  final int missingQr;
  final int criticalAlerts;
  final int dataQualityScore;
  final int syncScore;
  final int prepScore;
  final int frequentLate;
  final int frequentAbsent;
}

typedef SmartActionResult = ({bool success, String message, int fixedCount});
