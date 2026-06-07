import 'dart:io';

import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants.dart';
import '../../shared/models/member_account_model.dart';
import '../members/department_list_qr_resolver.dart';
import 'excel_compatible_csv_service.dart';
import 'lubumbashi_branding_service.dart';
import 'pdf_font_service.dart';
import 'text_sanitizer_service.dart';
import 'watermark_logo_service.dart';

/// PDF export for manual department lists (with member QR codes when available).
class DepartmentListPdfExportService {
  DepartmentListPdfExportService({
    DepartmentListQrResolver? qrResolver,
    WatermarkLogoService? watermark,
  })  : _qrResolver = qrResolver ?? DepartmentListQrResolver(),
        _watermark = watermark ?? WatermarkLogoService();

  final DepartmentListQrResolver _qrResolver;
  final WatermarkLogoService _watermark;

  Future<void> exportAndShare(DepartmentManualList list) async {
    final qrMap = await _qrResolver.resolveForList(list);
    final theme = await PdfFontService.theme();
    final pageTheme = await _watermark.pageThemeWithWatermark();
    final headerWidget = await _watermark.buildHeader();
    final doc = pw.Document(theme: theme);
    final sorted = [...list.entries]
      ..sort((a, b) => a.memberName.compareTo(b.memberName));

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (_) => headerWidget,
        footer: (context) => pw.Text(
          PdfSafeText.clean(LubumbashiBrandingService.pdfFooter),
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (context) => [
          pw.Text(
            'MEDIA LUBUMBASHI',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            PdfSafeText.clean(AppConstants.appFullName),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'DÉPARTEMENT ${PdfSafeText.clean(list.departmentName).toUpperCase()}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'LISTE : ${PdfSafeText.clean(list.listTitle).toUpperCase()}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${LubumbashiBrandingService.city} — Total : ${sorted.length}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FixedColumnWidth(42),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _headerCell('#'),
                  _headerCell('Nom'),
                  _headerCell('Code membre'),
                  _headerCell('QR'),
                  _headerCell('Notes'),
                ],
              ),
              for (var i = 0; i < sorted.length; i++)
                pw.TableRow(
                  children: [
                    _bodyCell('${i + 1}'),
                    _bodyCell(sorted[i].memberName),
                    _bodyCell(
                      qrMap[sorted[i].memberId]?.memberCode ?? '—',
                    ),
                    _qrCell(qrMap[sorted[i].memberId]?.qrData),
                    _bodyCell(sorted[i].notes ?? ''),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${list.listTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          PdfSafeText.clean(text),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _bodyCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          PdfSafeText.clean(text),
          style: const pw.TextStyle(fontSize: 8),
        ),
      );

  pw.Widget _qrCell(String? qrData) {
    if (qrData == null || qrData.isEmpty) {
      return _bodyCell('—');
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.BarcodeWidget(
        barcode: Barcode.qrCode(),
        data: qrData,
        width: 36,
        height: 36,
      ),
    );
  }
}

/// CSV export for manual department lists (includes QR data when available).
class DepartmentListCsvExportService {
  DepartmentListCsvExportService({DepartmentListQrResolver? qrResolver})
      : _qrResolver = qrResolver ?? DepartmentListQrResolver();

  final DepartmentListQrResolver _qrResolver;

  Future<void> exportAndShare(DepartmentManualList list) async {
    final qrMap = await _qrResolver.resolveForList(list);
    final sorted = [...list.entries]
      ..sort((a, b) => a.memberName.compareTo(b.memberName));

    const excel = ExcelCompatibleCsvService();
    final csv = excel.build(
      title: list.listTitle,
      departmentName: list.departmentName,
      headers: const ['N°', 'Nom complet', 'Code membre', 'QR Data', 'Notes'],
      rows: [
        for (var i = 0; i < sorted.length; i++)
          [
            '${i + 1}',
            sorted[i].memberName,
            qrMap[sorted[i].memberId]?.memberCode ?? '',
            qrMap[sorted[i].memberId]?.qrData ?? '',
            sorted[i].notes ?? '',
          ],
      ],
    );
    final bytes = excel.encode(csv);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${list.listTitle.replaceAll(' ', '_')}.csv',
    );
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: list.listTitle);
  }
}
