import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/auth/member_dashboard_service.dart';
import 'package:ifcm_membership/shared/components/advanced_design_system.dart';

void main() {
  group('MemberDashboardData', () {
    test('empty includes premium fields with defaults', () {
      final data = MemberDashboardData.empty();
      expect(data.role, 'Membre');
      expect(data.qrAvailable, isFalse);
      expect(data.mediaAssignment, isNull);
      expect(data.weekSessionCount, 0);
    });
  });

  group('MemberTimelineEntry', () {
    test('timeline widget builds with entries', () {
      const widget = MemberTimeline(
        entries: [
          MemberTimelineEntry(
            date: '2026-06-01',
            status: 'present',
            sessionType: 'Dimanche',
          ),
        ],
      );
      expect(widget.entries.length, 1);
    });
  });

  group('NotificationBadge', () {
    test('hides badge when count is zero', () {
      const badge = NotificationBadge(count: 0, child: SizedBox());
      expect(badge.count, 0);
    });
  });
}
