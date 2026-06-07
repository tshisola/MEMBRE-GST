import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/pdf_font_service.dart';
import '../../services/text_sanitizer_service.dart';
import '../../services/watermark_logo_service.dart';
import '../../services/lubumbashi_branding_service.dart';
import '../../services/professional_pdf_template.dart';

export '../../services/professional_pdf_template.dart' show ExcelStylePdfTable;
export '../../services/text_sanitizer_service.dart' show PdfSafeText;

/// Alias sanitizer pour rapports intelligents.
typedef PdfTextSanitizer = PdfSafeText;

/// Filigrane logo — délègue au service existant.
typedef PdfLogoWatermarkService = WatermarkLogoService;

/// Modèle PDF avancé avec graphiques et QR de vérification.
class AdvancedPdfTemplate {
  AdvancedPdfTemplate({WatermarkLogoService? watermark})
      : _watermark = watermark ?? WatermarkLogoService();

  final WatermarkLogoService _watermark;

  Future<pw.Document> buildSmartReport({
    required String reportTitle,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    required Map<String, int> stats,
    DateTime? date,
    String? responsible,
    String? verificationCode,
  }) async {
    final doc = pw.Document();
    final theme = await PdfFontService.theme();
    final pageTheme = await _watermark.pageThemeWithWatermark();
    final header = await _watermark.buildHeader();
    final safeTitle = PdfSafeText.clean(reportTitle);
    final code = verificationCode ?? _verificationCode(reportTitle, date);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        theme: theme,
        header: (_) => header,
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              PdfSafeText.clean(LubumbashiBrandingService.pdfFooter),
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            'MEDIA LUBUMBASHI',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            safeTitle,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(PdfSafeText.clean(subtitle), style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Date : ${_fmt(date ?? DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (responsible != null && responsible.isNotEmpty)
            pw.Text(
              'Responsable : ${PdfSafeText.clean(responsible)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 12),
          PdfChartRenderer.buildStatsRow(stats),
          pw.SizedBox(height: 12),
          ExcelStylePdfTable.build(
            headers: headers.map(PdfSafeText.clean).toList(),
            rows: rows.map((r) => r.map(PdfSafeText.clean).toList()).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Signature responsable', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 24),
                  pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Vérification', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 4),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: code,
                    width: 64,
                    height: 64,
                  ),
                  pw.Text(code, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _verificationCode(String title, DateTime? date) {
    final d = date ?? DateTime.now();
    final hash = title.hashCode.abs().toRadixString(16).toUpperCase();
    return 'ML-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}-$hash';
  }
}

/// Graphiques simples pour PDF (barres horizontales).
class PdfChartRenderer {
  PdfChartRenderer._();

  static pw.Widget buildStatsRow(Map<String, int> stats) {
    if (stats.isEmpty) return pw.SizedBox();
    final maxVal = stats.values.fold<int>(0, (a, b) => a > b ? a : b);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: stats.entries.map((e) {
        final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(
                  PdfSafeText.clean(e.key),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.Container(
                      height: 10,
                      width: 120 * ratio.clamp(0.05, 1.0),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF0067B1),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text('${e.value}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
