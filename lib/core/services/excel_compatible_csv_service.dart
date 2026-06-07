import 'dart:convert';

import 'package:csv/csv.dart';

import 'lubumbashi_branding_service.dart';
import 'text_sanitizer_service.dart';

/// CSV compatible Excel — UTF-8 BOM, accents propres.
class ExcelCompatibleCsvService {
  const ExcelCompatibleCsvService();

  static const utf8Bom = [0xEF, 0xBB, 0xBF];

  List<int> encode(String csvContent) {
    final sanitized = CsvTextSanitizer.clean(csvContent);
    return [...utf8Bom, ...utf8.encode(sanitized)];
  }

  String build({
    required String title,
    required String departmentName,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? date,
    String? responsible,
  }) {
    final data = <List<dynamic>>[
      [LubumbashiBrandingService.churchName],
      ['MEDIA LUBUMBASHI'],
      [CsvTextSanitizer.clean(departmentName)],
      [CsvTextSanitizer.clean(title)],
      ['Date', (date ?? DateTime.now()).toIso8601String()],
      if (responsible != null) ['Responsable', CsvTextSanitizer.clean(responsible)],
      ['Total', rows.length],
      [],
      headers.map(CsvTextSanitizer.clean).toList(),
      ...rows.map(
        (r) => r.map(CsvTextSanitizer.clean).toList(),
      ),
    ];
    return const ListToCsvConverter(fieldDelimiter: ';').convert(data);
  }

  List<int> buildBytes({
    required String title,
    required String departmentName,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? date,
    String? responsible,
  }) {
    return encode(
      build(
        title: title,
        departmentName: departmentName,
        headers: headers,
        rows: rows,
        date: date,
        responsible: responsible,
      ),
    );
  }
}

typedef CsvExportService = ExcelCompatibleCsvService;
