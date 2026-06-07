import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/web/web_responsive_layout_service.dart';

void main() {
  group('WebResponsiveLayoutService', () {
    test('mobile breakpoint', () {
      expect(
        WebResponsiveLayoutService.tierOf(480),
        WebLayoutTier.mobile,
      );
    });

    test('tablet breakpoint', () {
      expect(
        WebResponsiveLayoutService.tierOf(800),
        WebLayoutTier.tablet,
      );
    });

    test('desktop breakpoint', () {
      expect(
        WebResponsiveLayoutService.tierOf(1200),
        WebLayoutTier.desktop,
      );
    });

    test('isWeb on VM test is false', () {
      expect(WebResponsiveLayoutService.isWeb, isFalse);
    });
  });
}
