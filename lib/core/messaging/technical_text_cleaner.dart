/// Nettoie tout texte avant affichage utilisateur — aucun détail technique.
class TechnicalTextCleaner {
  TechnicalTextCleaner._();

  static final _technicalPatterns = [
    RegExp(r'firebase\w*', caseSensitive: false),
    RegExp(r'sqlite\w*', caseSensitive: false),
    RegExp(r'timeout\w*', caseSensitive: false),
    RegExp(r'permission[- ]denied', caseSensitive: false),
    RegExp(r'cloud_firestore', caseSensitive: false),
    RegExp(r'stack\s*trace', caseSensitive: false),
    RegExp(r'\bcollection\b', caseSensitive: false),
    RegExp(r'\bdocument\b', caseSensitive: false),
    RegExp(r'\bquery\b', caseSensitive: false),
    RegExp(r'\bdatabase\b', caseSensitive: false),
    RegExp(r'sync\s*queue', caseSensitive: false),
    RegExp(r'offline\s*queue', caseSensitive: false),
    RegExp(r'\brules\b', caseSensitive: false),
    RegExp(r'\bservice\b', caseSensitive: false),
    RegExp(r'\brepository\b', caseSensitive: false),
    RegExp(r'\bprovider\b', caseSensitive: false),
    RegExp(r'\bcontroller\b', caseSensitive: false),
    RegExp(r'error\s*code', caseSensitive: false),
    RegExp(r'exception', caseSensitive: false),
    RegExp(r'\.dart\b', caseSensitive: false),
    RegExp(r'package:', caseSensitive: false),
    RegExp(r'#\d+\s', caseSensitive: false),
  ];

  static bool looksTechnical(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    return _technicalPatterns.any((p) => p.hasMatch(lower));
  }

  static String clean(String? text, {String fallback = ''}) {
    if (text == null || text.trim().isEmpty) return fallback;
    if (looksTechnical(text)) return fallback;
    return text.trim();
  }
}
