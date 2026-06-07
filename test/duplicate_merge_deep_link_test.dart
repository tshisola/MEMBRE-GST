import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/core/advanced/duplicates/duplicate_similarity_engine.dart';
import 'package:ifcm_membership/core/advanced/pdf/pdf_preview_cache.dart';
import 'package:ifcm_membership/core/navigation/deep_link_permission_guard.dart';
import 'package:ifcm_membership/core/navigation/notification_payload_parser.dart';
import 'package:ifcm_membership/core/security/duplicate_merge_permission_guard.dart';
import 'package:ifcm_membership/core/storage/local_session.dart';
import 'package:ifcm_membership/shared/models/ifcm_member_record.dart';

Future<LocalSession> _session({
  required String role,
  required String accountType,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final session = LocalSession(prefs);
  await session.saveSession(
    userId: 'user-1',
    email: 'test@ifcm.local',
    role: role,
    accountType: accountType,
  );
  return session;
}

void main() {
  group('DuplicateSimilarityEngine', () {
    test('detects high similarity for same phone and name', () {
      final engine = DuplicateSimilarityEngine();
      final a = IfcmMemberRecord(
        id: 'a',
        localId: 'local-a',
        memberCode: 'M001',
        qrCodeId: 'qr-id-a',
        qrData: 'qr-a',
        firstName: 'Jean',
        lastName: 'Dupont',
        phone: '+243900000001',
      );
      final b = IfcmMemberRecord(
        id: 'b',
        localId: 'local-b',
        memberCode: 'M002',
        qrCodeId: 'qr-id-b',
        qrData: 'qr-b',
        firstName: 'Jean',
        lastName: 'Dupont',
        phone: '+243900000001',
      );
      final result = engine.compare(a, b);
      expect(result.similarityScore, greaterThanOrEqualTo(50));
      expect(result.primaryMemberId, isNotEmpty);
      expect(result.secondaryMemberId, isNotEmpty);
    });
  });

  group('NotificationPayloadParser', () {
    test('parses member detail route', () {
      final parsed = NotificationPayloadParser.parse('member:abc123');
      expect(parsed?.path, '/members/abc123');
    });

    test('parses media activation route', () {
      final parsed = NotificationPayloadParser.parse('media_activation');
      expect(parsed?.path, '/admin/media-activation-requests');
    });

    test('parses duplicate merge route', () {
      final parsed = NotificationPayloadParser.parse('duplicate_merge');
      expect(parsed?.path, '/advanced/duplicate-merge');
    });
  });

  group('DeepLinkPermissionGuard', () {
    test('blocks member from admin routes', () async {
      final session = await _session(
        role: AppConstants.roleMember,
        accountType: AppConstants.accountTypeMember,
      );
      expect(
        DeepLinkPermissionGuard.canAccess(session, '/advanced/duplicate-merge'),
        isFalse,
      );
      expect(
        DeepLinkPermissionGuard.canAccess(session, '/member/dashboard'),
        isTrue,
      );
    });
  });

  group('DuplicateMergePermissionGuard', () {
    test('admin general can always merge', () async {
      final session = await _session(
        role: AppConstants.roleAdminGeneral,
        accountType: AppConstants.accountTypeAdmin,
      );
      expect(DuplicateMergePermissionGuard.canMerge(session), isTrue);
    });

    test('simple member cannot merge', () async {
      final session = await _session(
        role: AppConstants.roleMember,
        accountType: AppConstants.accountTypeMember,
      );
      expect(DuplicateMergePermissionGuard.canMerge(session), isFalse);
    });
  });

  group('PdfPreviewCache', () {
    test('stores and retrieves preview bytes', () {
      final cache = PdfPreviewCache.instance;
      cache.put('test_key', Uint8List.fromList([1, 2, 3]), title: 'Test PDF');
      final doc = cache.documentFor('test_key');
      expect(doc?.title, 'Test PDF');
      expect(doc?.bytes, [1, 2, 3]);
      cache.clear('test_key');
    });
  });
}
