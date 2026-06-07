/// Lubumbashi branding — replaces legacy Kinshasa references.
library;

import '../../app/constants.dart';

class LubumbashiBrandingService {
  LubumbashiBrandingService._();

  static const String city = 'Lubumbashi';
  static const String legacyCity = 'Kinshasa';
  static const String churchName = 'IMPACT FOR CHRIST MINISTRIES';
  static const String mediaDepartmentLabel = 'Département Média — Lubumbashi';
  static const String reportHeader =
      'MEDIA LUBUMBASHI — Département Média — Lubumbashi';
  static const String pdfFooter =
      'Document généré pour MEDIA LUBUMBASHI — Impact For Christ Ministries Lubumbashi';
  static const String csvHeaderPrefix = 'Media_Lubumbashi';
  static const String logoAssetPath = 'assets/images/logo.png';

  /// Replaces Kinshasa (any case) with Lubumbashi in [input].
  static String applyBranding(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp('kinshasa', caseSensitive: false), city)
        .replaceAll(RegExp('kinshasa-gombe', caseSensitive: false), city)
        .replaceAll(RegExp('kinshasa gombe', caseSensitive: false), city);
  }

  /// Builds a localized report title for media exports.
  static String reportTitle({
    required String subject,
    DateTime? date,
  }) {
    final datePart = date != null
        ? ' — ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : '';
    return applyBranding('$reportHeader — $subject$datePart');
  }

  static Map<String, String> brandingMetadata() {
    return {
      'city': city,
      'church': churchName,
      'department': mediaDepartmentLabel,
      'locale': 'fr_CD',
    };
  }
}
