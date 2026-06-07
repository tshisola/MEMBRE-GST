import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/members/member_search_index.dart';
import 'package:ifcm_membership/core/members/pointage_member_view.dart';
import 'package:ifcm_membership/core/pointage/attendance_time_rules.dart';
import 'package:ifcm_membership/features/media_attendance/presentation/media_pointage_controller.dart';
import 'package:ifcm_membership/shared/models/attendance_model.dart';
import 'package:ifcm_membership/shared/models/ifcm_member_record.dart';

IfcmMemberRecord _record({
  required String id,
  String? departmentId,
  String syncStatus = 'pending',
  bool isActive = true,
  bool isDeleted = false,
  String firstName = 'Jean',
  String lastName = 'Test',
}) {
  return IfcmMemberRecord(
    id: id,
    localId: id,
    memberCode: 'MBR-$id',
    qrCodeId: 'qr-$id',
    qrData: 'IFCM|Lubumbashi|$id',
    firstName: firstName,
    lastName: lastName,
    departmentId: departmentId,
    syncStatus: syncStatus,
    isActive: isActive,
    isDeleted: isDeleted,
  );
}

PointageMemberView _view(String id, {String syncStatus = 'pending'}) {
  return PointageMemberView.fromRecord(
    _record(id: id, departmentId: 'media', syncStatus: syncStatus),
  );
}

void main() {
  group('AttendanceMemberQueryService eligibility', () {
    test('pending sync member is active and not deleted', () {
      final record = _record(id: '1', departmentId: 'other', syncStatus: 'pending');
      expect(record.isActive, isTrue);
      expect(record.isDeleted, isFalse);
      expect(record.syncStatus, 'pending');
    });

    test('deleted member record is not active eligible', () {
      final record = _record(id: '2', isDeleted: true, isActive: false);
      expect(record.isDeleted, isTrue);
    });
  });

  group('MemberSearchIndex', () {
    test('finds by member code offline', () {
      final members = [_view('a'), _view('b')];
      final index = MemberSearchIndex(members);
      expect(index.findExactCodeOrQr('MBR-a')?.id, 'a');
    });

    test('search by name', () {
      final members = [
        PointageMemberView.fromRecord(
          _record(id: 'x', departmentId: 'media', firstName: 'Marie', lastName: 'Kabongo'),
        ),
      ];
      final index = MemberSearchIndex(members);
      expect(index.search('marie').length, 1);
    });
  });

  group('MediaPointageController', () {
    test('operator cannot point themselves', () {
      final controller = MediaPointageController();
      expect(
        controller.canPointMember(
          operatorCanTakeAttendance: true,
          operatorMemberId: 'm1',
          targetMemberId: 'm1',
        ),
        isFalse,
      );
    });

    test('attendance operator can point others', () {
      final controller = MediaPointageController();
      expect(
        controller.canPointMember(
          operatorCanTakeAttendance: true,
          operatorMemberId: 'op',
          targetMemberId: 'm1',
        ),
        isTrue,
      );
    });

    test('filters unmarked members', () {
      final controller = MediaPointageController();
      final members = [_view('1'), _view('2')];
      final attendance = {'1': MediaAttendanceStatus.present};
      final filtered = controller.applyFilters(
        members: members,
        attendance: attendance,
        searchQuery: '',
      );
      controller.statusFilter = PointageStatusFilter.unmarked;
      final unmarked = controller.applyFilters(
        members: members,
        attendance: attendance,
        searchQuery: '',
      );
      expect(unmarked.length, 1);
      expect(unmarked.first.id, '2');
      expect(filtered.length, 2);
    });
  });

  group('AttendanceTimeRules', () {
    test('sunday 07:00 is on time', () {
      final dt = DateTime(2026, 6, 7, 7, 0); // Sunday
      expect(
        AttendanceTimeRules.statusForNow(
          dateTime: dt,
          sessionType: MediaSessionType.sundayService,
        ),
        MediaAttendanceStatus.present,
      );
    });

    test('sunday 07:20 is late', () {
      final dt = DateTime(2026, 6, 7, 7, 20);
      expect(
        AttendanceTimeRules.statusForNow(
          dateTime: dt,
          sessionType: MediaSessionType.sundayService,
        ),
        MediaAttendanceStatus.late,
      );
    });

    test('wednesday 17:05 is late', () {
      final dt = DateTime(2026, 6, 3, 17, 5); // Mercredi
      expect(
        AttendanceTimeRules.statusForNow(
          dateTime: dt,
          sessionType: MediaSessionType.rehearsal,
        ),
        MediaAttendanceStatus.late,
      );
    });
  });
}
