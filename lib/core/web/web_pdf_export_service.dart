import 'dart:async';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/constants.dart';

/// Export PDF côté Web — téléchargement navigateur.
class WebPdfExportService {
  WebPdfExportService._();
  static final WebPdfExportService instance = WebPdfExportService._();

  Future<Uint8List> buildTablePdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final doc = pw.Document();
    final safeTitle = PdfTextSanitizer.clean(title);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '${AppConstants.appName}\n${AppConstants.organizationLegalLine}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(safeTitle, style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers.map(PdfTextSanitizer.clean).toList(),
            data: rows
                .map((r) => r.map(PdfTextSanitizer.clean).toList())
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> downloadPdf({
    required String filename,
    required Uint8List bytes,
  }) async {
    if (!kIsWeb) return;
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

class WebPdfPreviewService {
  WebPdfPreviewService._();
  static final WebPdfPreviewService instance = WebPdfPreviewService._();

  Future<void> preview(Uint8List bytes, {String name = 'document.pdf'}) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

class WebCsvExportService {
  WebCsvExportService._();
  static final WebCsvExportService instance = WebCsvExportService._();

  String buildCsv({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return const ListToCsvConverter().convert([headers, ...rows]);
  }
}

class PdfFontService {
  PdfFontService._();
  static Future<pw.Font> loadDefault() async {
    return pw.Font.helvetica();
  }
}

class PdfTextSanitizer {
  PdfTextSanitizer._();
  static String clean(String input) {
    return input
        .replaceAll('\uFFFD', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .trim();
  }
}

typedef WebProfessionalListViewer = WebPdfExportService;
typedef WebAdvancedDataTable = WebPdfExportService;
typedef WebExcelLikeSearch = WebCsvExportService;
typedef WebPdfPreview = WebPdfPreviewService;
typedef WebCsvExport = WebCsvExportService;
typedef WebListActionToolbar = WebActionButtonStub;

class WebActionButtonStub {}
