/// Modèles pour fonctionnalités avancées MEDIA LUBUMBASHI.
library;

enum AppNotificationCategory {
  general,
  critical,
  attendance,
  list,
  account,
  sync,
  report,
}

enum AppNotificationSeverity { info, warning, critical }

enum ApprovalStatus { pending, approved, rejected, cancelled }

enum ApprovalActionType {
  deleteMember,
  changeRole,
  activateGoogle,
  deleteList,
  changeQrCode,
  restoreMember,
  publishReport,
}

enum SmartActionOutcome { success, failure, cancelled }

enum AuditRiskLevel { low, medium, high, critical }

enum PerformanceLevel { excellent, good, fair, poor }

extension PerformanceLevelUi on PerformanceLevel {
  String get label {
    switch (this) {
      case PerformanceLevel.excellent:
        return 'Excellent';
      case PerformanceLevel.good:
        return 'Bon';
      case PerformanceLevel.fair:
        return 'Correct';
      case PerformanceLevel.poor:
        return 'À améliorer';
    }
  }
}

enum CalendarEventType { service, list, team, reminder }

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.isRead,
    required this.createdAt,
    this.targetRole,
    this.targetUserId,
    this.memberId,
    this.route,
  });

  final String id;
  final String title;
  final String message;
  final AppNotificationCategory category;
  final AppNotificationSeverity severity;
  final bool isRead;
  final DateTime createdAt;
  final String? targetRole;
  final String? targetUserId;
  final String? memberId;
  final String? route;
}

class ApprovalRequestItem {
  const ApprovalRequestItem({
    required this.id,
    required this.actionType,
    required this.targetLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.targetId,
    this.requestedBy,
    this.requestedByName,
    this.reason,
    this.decisionReason,
    this.decidedBy,
    this.riskLevel = AuditRiskLevel.medium,
  });

  final String id;
  final ApprovalActionType actionType;
  final String? targetId;
  final String targetLabel;
  final ApprovalStatus status;
  final String? requestedBy;
  final String? requestedByName;
  final String? reason;
  final String? decisionReason;
  final String? decidedBy;
  final AuditRiskLevel riskLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get actionLabel {
    switch (actionType) {
      case ApprovalActionType.deleteMember:
        return 'Suppression membre';
      case ApprovalActionType.changeRole:
        return 'Changement de rôle';
      case ApprovalActionType.activateGoogle:
        return 'Activation compte Google';
      case ApprovalActionType.deleteList:
        return 'Suppression liste';
      case ApprovalActionType.changeQrCode:
        return 'Modification QR Code';
      case ApprovalActionType.restoreMember:
        return 'Restauration membre';
      case ApprovalActionType.publishReport:
        return 'Publication rapport';
    }
  }
}

class SmartActionHistoryEntry {
  const SmartActionHistoryEntry({
    required this.id,
    required this.actionKey,
    required this.label,
    required this.success,
    required this.createdAt,
    this.message,
    this.actorId,
    this.actorName,
  });

  final String id;
  final String actionKey;
  final String label;
  final bool success;
  final String? message;
  final String? actorId;
  final String? actorName;
  final DateTime createdAt;
}

class AppHealthSnapshot {
  const AppHealthSnapshot({
    required this.healthScore,
    required this.syncScore,
    required this.dataQualityScore,
    required this.pointageScore,
    required this.listScore,
    required this.activeMembers,
    required this.visibleAtPointage,
    required this.invisibleAtPointage,
    required this.incompleteLists,
    required this.pendingSync,
    required this.criticalAlerts,
    required this.recommendations,
    required this.generatedAt,
    this.deletedMembers = 0,
    this.totalListsGenerated = 0,
    this.todayPresent = 0,
    this.todayLate = 0,
    this.todayAbsent = 0,
    this.qrMissingCount = 0,
    this.inactiveAccounts = 0,
  });

  final int healthScore;
  final int syncScore;
  final int dataQualityScore;
  final int pointageScore;
  final int listScore;
  final int activeMembers;
  final int visibleAtPointage;
  final int invisibleAtPointage;
  final int incompleteLists;
  final int pendingSync;
  final int criticalAlerts;
  final List<String> recommendations;
  final DateTime generatedAt;
  final int deletedMembers;
  final int totalListsGenerated;
  final int todayPresent;
  final int todayLate;
  final int todayAbsent;
  final int qrMissingCount;
  final int inactiveAccounts;
}

class DuplicateMatch {
  const DuplicateMatch({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.matchType,
    required this.matchValue,
    required this.confidence,
    this.suggestedAction,
    this.secondaryMemberId,
    this.secondaryMemberName,
    this.primaryMemberId,
    this.similarityScore,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String matchType;
  final String matchValue;
  final int confidence;
  final String? suggestedAction;
  final String? secondaryMemberId;
  final String? secondaryMemberName;
  final String? primaryMemberId;
  final int? similarityScore;
}

class PerformanceSnapshot {
  const PerformanceSnapshot({
    required this.score,
    required this.startupMs,
    required this.avgQueryMs,
    required this.recommendations,
    required this.level,
  });

  final int score;
  final int startupMs;
  final int avgQueryMs;
  final List<String> recommendations;
  final PerformanceLevel level;
}

class CalendarEventItem {
  const CalendarEventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.subtitle,
    this.isReady = true,
  });

  final String id;
  final String title;
  final DateTime date;
  final CalendarEventType type;
  final String? subtitle;
  final bool isReady;
}

class LiveActivitySnapshot {
  const LiveActivitySnapshot({
    required this.expectedCount,
    required this.arrivedCount,
    required this.lateCount,
    required this.absentCount,
    required this.coveredPosts,
    required this.uncoveredPosts,
    required this.prepPercent,
    required this.alerts,
  });

  final int expectedCount;
  final int arrivedCount;
  final int lateCount;
  final int absentCount;
  final int coveredPosts;
  final int uncoveredPosts;
  final int prepPercent;
  final List<String> alerts;
}

class ReplacementSuggestion {
  const ReplacementSuggestion({
    required this.postLabel,
    required this.absentMemberName,
    required this.suggestedMemberId,
    required this.suggestedMemberName,
    required this.confidence,
  });

  final String postLabel;
  final String absentMemberName;
  final String suggestedMemberId;
  final String suggestedMemberName;
  final int confidence;
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.targetId,
    this.module,
    this.riskLevel = AuditRiskLevel.low,
    this.metadata,
  });

  final String id;
  final String action;
  final String? actorId;
  final String? actorName;
  final String? targetId;
  final String? module;
  final AuditRiskLevel riskLevel;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
}

extension AppNotificationCategoryX on AppNotificationCategory {
  String get label {
    switch (this) {
      case AppNotificationCategory.general:
        return 'Général';
      case AppNotificationCategory.critical:
        return 'Critique';
      case AppNotificationCategory.attendance:
        return 'Présence';
      case AppNotificationCategory.list:
        return 'Listes';
      case AppNotificationCategory.account:
        return 'Comptes';
      case AppNotificationCategory.sync:
        return 'Synchronisation';
      case AppNotificationCategory.report:
        return 'Rapports';
    }
  }
}

extension ApprovalStatusX on ApprovalStatus {
  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'En attente';
      case ApprovalStatus.approved:
        return 'Approuvé';
      case ApprovalStatus.rejected:
        return 'Refusé';
      case ApprovalStatus.cancelled:
        return 'Annulé';
    }
  }
}
