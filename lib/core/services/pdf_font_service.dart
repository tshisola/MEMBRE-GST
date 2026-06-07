import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Polices PDF Unicode — accents français, pas de rectangles □.
class PdfFontService {
  PdfFontService._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.Font> regular() async {
    if (_regular != null) return _regular!;
    try {
      _regular = await PdfGoogleFonts.notoSansRegular();
    } catch (_) {
      _regular = pw.Font.helvetica();
    }
    return _regular!;
  }

  static Future<pw.Font> bold() async {
    if (_bold != null) return _bold!;
    try {
      _bold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      _bold = pw.Font.helveticaBold();
    }
    return _bold!;
  }

  static Future<pw.ThemeData> theme() async {
    return pw.ThemeData.withFont(
      base: await regular(),
      bold: await bold(),
    );
  }

  static Future<pw.TextStyle> style({
    double fontSize = 10,
    bool bold = false,
    PdfColor? color,
  }) async {
    return pw.TextStyle(
      font: bold ? await PdfFontService.bold() : await regular(),
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
  }
}

typedef PdfFontLoader = PdfFontService;
