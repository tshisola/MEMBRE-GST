import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/messaging/app_error_presenter.dart';
import 'package:ifcm_membership/core/messaging/secure_error_mapper.dart';
import 'package:ifcm_membership/core/messaging/technical_text_cleaner.dart';
import 'package:ifcm_membership/core/messaging/user_friendly_message_service.dart';

void main() {
  group('TechnicalTextCleaner', () {
    test('detects firebase and sqlite patterns', () {
      expect(
        TechnicalTextCleaner.looksTechnical('FirebaseException: permission-denied'),
        isTrue,
      );
      expect(
        TechnicalTextCleaner.looksTechnical('SQLiteException: database locked'),
        isTrue,
      );
      expect(
        TechnicalTextCleaner.looksTechnical('cloud_firestore/query failed'),
        isTrue,
      );
    });

    test('allows professional french messages', () {
      expect(
        TechnicalTextCleaner.looksTechnical('Données enregistrées avec succès.'),
        isFalse,
      );
      expect(
        TechnicalTextCleaner.looksTechnical('Veuillez réessayer dans un instant.'),
        isFalse,
      );
    });

    test('cleans technical text to fallback', () {
      final cleaned = TechnicalTextCleaner.clean(
        'TimeoutException after 30s',
        fallback: 'Veuillez réessayer dans un instant.',
      );
      expect(cleaned, 'Veuillez réessayer dans un instant.');
    });
  });

  group('SecureErrorMapper', () {
    test('maps permission denied professionally', () {
      final msg = SecureErrorMapper.map(
        Exception('FirebaseException: permission-denied'),
      );
      expect(msg.toLowerCase(), isNot(contains('firebase')));
      expect(msg.toLowerCase(), isNot(contains('permission-denied')));
    });
  });

  group('AppErrorPresenter', () {
    test('never returns raw exception text', () {
      final msg = AppErrorPresenter.forUser(
        StateError('Bad state: sync queue overflow in repository.dart'),
        source: 'test',
      );
      expect(TechnicalTextCleaner.looksTechnical(msg), isFalse);
    });
  });

  group('UserFriendlyMessageService', () {
    test('professional success and unauthorized messages', () {
      expect(UserFriendlyMessageService.success(), 'Opération réussie.');
      expect(
        UserFriendlyMessageService.unauthorized(),
        'Vous n\'êtes pas autorisé à effectuer cette action.',
      );
    });
  });
}
