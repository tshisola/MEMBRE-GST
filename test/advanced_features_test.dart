import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/advanced/approval/approval_workflow_service.dart';
import 'package:ifcm_membership/core/advanced/command/intelligent_admin_command_center.dart';
import 'package:ifcm_membership/core/advanced/models/advanced_models.dart';
import 'package:ifcm_membership/core/advanced/performance/performance_monitor.dart';
import 'package:ifcm_membership/core/messaging/user_friendly_message_service.dart';
import 'package:ifcm_membership/core/advanced/privacy/privacy_ui_guard.dart';

void main() {
  group('AppHealthScoreEngine', () {
    test('computes weighted health score', () {
      final engine = AppHealthScoreEngine();
      final score = engine.compute(
        syncScore: 90,
        dataQualityScore: 85,
        pointageScore: 80,
        listScore: 95,
        prepScore: 70,
      );
      expect(score, greaterThan(70));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('SensitiveActionValidator', () {
    test('delete member requires approval', () {
      expect(
        SensitiveActionValidator.requiresApproval(ApprovalActionType.deleteMember),
        isTrue,
      );
    });
  });

  group('PrivacyUiGuard', () {
    test('cleans technical firebase text', () {
      final cleaned = SensitiveTextCleaner.clean('Firebase permission-denied error');
      expect(cleaned.toLowerCase(), isNot(contains('firebase')));
    });

    test('user friendly messages are professional', () {
      expect(UserFriendlyMessageService.success(), 'Opération réussie.');
      expect(
        UserFriendlyMessageService.unauthorized(),
        'Vous n\'êtes pas autorisé à effectuer cette action.',
      );
    });
  });

  group('PerformanceMonitor', () {
    test('returns snapshot with score', () async {
      final snap = await PerformanceMonitor.instance.analyze();
      expect(snap.score, inInclusiveRange(0, 100));
      expect(snap.recommendations, isNotEmpty);
    });
  });

  group('ApprovalStatus labels', () {
    test('french labels for UI', () {
      expect(ApprovalStatus.pending.label, 'En attente');
      expect(ApprovalStatus.approved.label, 'Approuvé');
    });
  });
}
