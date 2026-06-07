import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/smart/automation/automation_trigger_service.dart';
import 'package:ifcm_membership/core/smart/models/smart_models.dart';
import 'package:ifcm_membership/core/smart/planning/smart_media_team_planner.dart';
import 'package:ifcm_membership/core/smart/score/member_media_score_engine.dart';
import 'package:ifcm_membership/shared/models/ifcm_member_record.dart';

IfcmMemberRecord _member({
  required String id,
  bool isActive = true,
  bool isDeleted = false,
  String syncStatus = 'synced',
  String? departmentId = 'media',
  String role = 'member',
  String? phone = '+243900000000',
  String qrData = 'IFCM|Lubumbashi|qr',
}) {
  return IfcmMemberRecord(
    id: id,
    localId: id,
    memberCode: 'MBR-$id',
    qrCodeId: 'qr-$id',
    qrData: qrData,
    firstName: 'Jean',
    lastName: 'Dupont',
    departmentId: departmentId,
    departmentName: departmentId == 'media' ? 'Département Média' : null,
    syncStatus: syncStatus,
    isActive: isActive,
    isDeleted: isDeleted,
    role: role,
    phone: phone,
    commune: 'Lubumbashi',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  );
}

void main() {
  group('MemberMediaScoreEngine', () {
    test('calculates score for active synced media member', () {
      final engine = MemberMediaScoreEngine();
      final score = engine.scoreMember(_member(id: '1'));
      expect(score.score, greaterThan(50));
      expect(score.memberId, '1');
      expect(score.badge, isNot(MemberScoreBadge.inactive));
    });

    test('inactive deleted member gets inactive badge', () {
      final engine = MemberMediaScoreEngine();
      final score = engine.scoreMember(
        _member(id: '2', isActive: false, isDeleted: true),
      );
      expect(score.badge, MemberScoreBadge.inactive);
      expect(score.score, lessThan(70));
    });
  });

  group('SmartIssue model', () {
    test('formats user-friendly title without technical ids', () {
      const issue = SmartIssue(
        id: 'pointage_invisible_1',
        category: SmartIssueCategory.pointage,
        severity: SmartIssueSeverity.warning,
        title: '3 membres n\'apparaissent pas au pointage.',
        message: 'Vérifiez les départements et l\'état actif.',
        autoFixable: true,
      );
      expect(issue.title, isNot(contains('Firebase')));
      expect(issue.title, isNot(contains('SQLite')));
      expect(issue.autoFixable, isTrue);
    });
  });

  group('AutomationTriggerService', () {
    test('allows first run and throttles rapid member_created', () {
      final service = AutomationTriggerService();
      expect(service.shouldRun('member_created', null), isTrue);
      final recent = DateTime.now();
      expect(service.shouldRun('member_created', recent), isFalse);
    });
  });

  group('Sunday team posts', () {
    test('defines six media posts', () {
      expect(SmartMediaTeamPlanner.sundayPosts.length, 6);
      expect(
        SmartMediaTeamPlanner.sundayPosts.map((p) => p.$2),
        contains('Caméra Centre'),
      );
    });
  });

  group('MemberScoreBadge labels', () {
    test('badges have French labels for UI', () {
      expect(MemberScoreBadge.excellent.label, 'Excellent');
      expect(MemberScoreBadge.newMember.label, 'Nouveau');
    });
  });
}
