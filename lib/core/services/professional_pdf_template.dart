import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'lubumbashi_branding_service.dart';
import 'pdf_font_service.dart';
import 'text_sanitizer_service.dart';
import 'watermark_logo_service.dart';

/// Modèle PDF professionnel style Excel — MEDIA LUBUMBASHI.
class ProfessionalPdfTemplate {
  ProfessionalPdfTemplate({
    WatermarkLogoService? watermark,
  }) : _watermark = watermark ?? WatermarkLogoService();

  final WatermarkLogoService _watermark;

  Future<pw.MultiPage> buildDocument({
    required String listTitle,
    required String departmentName,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? date,
    String? responsible,
    String? signatureLabel,
  }) async {
    final theme = await PdfFontService.theme();
    final pageTheme = await _watermark.pageThemeWithWatermark();
    final header = await _watermark.buildHeader();
    final safeTitle = PdfSafeText.clean(listTitle);
    final safeDept = PdfSafeText.clean(departmentName);
    final dateLabel = date ?? DateTime.now();

    return pw.MultiPage(
      pageTheme: pageTheme,
      theme: theme,
      header: (_) => header,
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            PdfSafeText.clean(LubumbashiBrandingService.pdfFooter),
            style: pw.TextStyle(fontSize: 8),
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
          PdfSafeText.clean(LubumbashiBrandingService.churchName),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          safeDept.toUpperCase(),
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          safeTitle,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date : ${_formatDate(dateLabel)} · Total : ${rows.length}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (responsible != null && responsible.isNotEmpty)
          pw.Text(
            'Responsable : ${PdfSafeText.clean(responsible)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.SizedBox(height: 12),
        ExcelStylePdfTable.build(
          headers: headers.map(PdfSafeText.clean).toList(),
          rows: rows
              .map(
                (r) => r.map(PdfSafeText.clean).toList(),
              )
              .toList(),
        ),
        if (signatureLabel != null) ...[
          pw.SizedBox(height: 24),
          pw.Text('Signature : ${PdfSafeText.clean(signatureLabel)}'),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Tableau PDF style Excel — en-têtes colorés, lignes alternées.
class ExcelStylePdfTable {
  ExcelStylePdfTable._();

  static pw.Widget build({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: i == 0
              ? const pw.FixedColumnWidth(28)
              : const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0067B1)),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: rows[i]
                .map(
                  (c) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(c, style: const pw.TextStyle(fontSize: 8)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

typedef MediaListPdfTemplate = ProfessionalPdfTemplate;
typedef DepartmentListPdfTemplate = ProfessionalPdfTemplate;
