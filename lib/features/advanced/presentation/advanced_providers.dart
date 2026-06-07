import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/advanced/pdf/advanced_pdf_export_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/advanced/actions/auto_fix_action_service.dart';
import '../../../core/advanced/actions/quick_action_service.dart';
import '../../../core/advanced/approval/approval_workflow_service.dart';
import '../../../core/advanced/audit/professional_audit_log_service.dart';
import '../../../core/advanced/calendar/media_smart_calendar.dart';
import '../../../core/advanced/command/intelligent_admin_command_center.dart';
import '../../../core/advanced/duplicates/smart_duplicate_detection_engine.dart';
import '../../../core/advanced/live/live_media_activity_engine.dart';
import '../../../core/advanced/models/advanced_models.dart';
import '../../../core/advanced/notifications/local_notification_repository.dart';
import '../../../core/advanced/notifications/push_notification_service.dart';
import '../../../core/advanced/pdf/smart_pdf_report_service.dart';
import '../../../core/advanced/performance/performance_monitor.dart';
import '../../../core/advanced/replacement/smart_replacement_engine.dart';

final commandCenterProvider = FutureProvider<AppHealthSnapshot>((ref) async {
  return IntelligentAdminCommandCenter().load();
});

final notificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  if (session.isMemberAccount && session.memberId != null) {
    return LocalNotificationRepository.instance.list(
      memberId: session.memberId,
      limit: 100,
    );
  }
  return LocalNotificationRepository.instance.list(
    targetRole: session.role,
    targetUserId: session.userId,
    limit: 100,
  );
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  if (session.isMemberAccount && session.memberId != null) {
    return PushNotificationService.instance.unreadCount(
      memberId: session.memberId,
    );
  }
  return PushNotificationService.instance.unreadCount(
    role: session.role,
    userId: session.userId,
  );
});

final approvalRequestsProvider = FutureProvider<List<ApprovalRequestItem>>((ref) async {
  return ApprovalWorkflowService.instance.listAll();
});

final auditTimelineProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  return ProfessionalAuditLogService.instance.list();
});

final duplicatesProvider = FutureProvider<List<DuplicateMatch>>((ref) async {
  return SmartDuplicateDetectionEngine().scanAll();
});

final performanceProvider = FutureProvider<PerformanceSnapshot>((ref) async {
  return PerformanceMonitor.instance.analyze();
});

final calendarEventsProvider =
    FutureProvider.family<List<CalendarEventItem>, DateTime>((ref, month) async {
  return MediaSmartCalendar().loadMonth(month);
});

final liveActivityProvider = FutureProvider<LiveActivitySnapshot>((ref) async {
  return LiveMediaActivityDashboard().load();
});

final replacementSuggestionsProvider =
    FutureProvider<List<ReplacementSuggestion>>((ref) async {
  return SmartReplacementEngine().suggestForSunday();
});

final smartActionHistoryProvider =
    FutureProvider<List<SmartActionHistoryEntry>>((ref) async {
  return SmartActionHistoryService.instance.listRecent();
});

final smartPdfReportServiceProvider = Provider((ref) => SmartPdfReportService());
final advancedPdfExportServiceProvider = Provider((ref) => AdvancedPdfExportService());
final autoFixActionServiceProvider = Provider((ref) => AutoFixActionService());
final quickActionServiceProvider = Provider(
  (ref) => QuickActionService(autoFix: ref.read(autoFixActionServiceProvider)),
);
