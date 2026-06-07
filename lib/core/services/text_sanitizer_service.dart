/// Nettoyage texte pour PDF, CSV et listes — évite les rectangles □ dans les exports.
class TextSanitizerService {
  TextSanitizerService._();

  /// Alias spec utilisateur.
  static String sanitize(String? input) => PdfSafeText.clean(input);

  static String forCsv(String? input) => CsvTextSanitizer.clean(input);

  static String forPdf(String? input) => PdfSafeText.clean(input);
}

typedef UnicodeTextCleaner = TextSanitizerService;

class PdfSafeText {
  PdfSafeText._();

  static String clean(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input
        .replaceAll('\uFFFD', '')
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');

    const replacements = {
      '\u2013': '-',
      '\u2014': '-',
      '\u2018': "'",
      '\u2019': "'",
      '\u201C': '"',
      '\u201D': '"',
      '\u2026': '...',
      '\u2022': '-',
    };
    replacements.forEach((k, v) => text = text.replaceAll(k, v));

    // Supprime emojis / pictogrammes non supportés par polices PDF basiques.
    text = text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    return text.trim();
  }
}

class CsvTextSanitizer {
  CsvTextSanitizer._();

  static String clean(String? input) {
    final base = PdfSafeText.clean(input);
    return base.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll(';', ',');
  }
}
