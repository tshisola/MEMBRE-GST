import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/web/web_responsive_layout_service.dart';

void main() {
  test('Web layout tiers are defined', () {
    expect(WebLayoutTier.values.length, 4);
  });
}
