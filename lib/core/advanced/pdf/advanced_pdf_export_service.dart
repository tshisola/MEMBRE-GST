import 'dart:typed_data';

import '../../services/media_pdf_export_service.dart';
import 'smart_pdf_report_service.dart';

/// Façade unifiée pour tous les exports PDF — délègue aux services existants.
class AdvancedPdfExportService {
  AdvancedPdfExportService({
    SmartPdfReportService? smart,
    MediaPdfExportService? media,
  })  : _smart = smart ?? SmartPdfReportService(),
        _media = media ?? MediaPdfExportService();

  final SmartPdfReportService _smart;
  final MediaPdfExportService _media;

  Future<void> shareSmartReport(
    SmartReportType type, {
    String? responsible,
  }) =>
      _smart.shareReport(type, responsible: responsible);

  Future<Uint8List> buildSmartReportBytes(
    SmartReportType type, {
    String? responsible,
  }) async {
    final doc = await _smart.buildReport(type, responsible: responsible);
    final saved = await doc.save();
    return Uint8List.fromList(saved);
  }

  Future<void> shareMediaPdf(
    Uint8List bytes, {
    String name = 'ifcm_media',
  }) =>
      _media.sharePdf(bytes, name: name);

  SmartPdfReportService get smart => _smart;
  MediaPdfExportService get media => _media;
}

typedef SmartReportPdfService = SmartPdfReportService;
