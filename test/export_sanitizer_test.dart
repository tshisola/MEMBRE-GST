import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/core/services/excel_compatible_csv_service.dart';
import 'package:ifcm_membership/core/services/text_sanitizer_service.dart';

void main() {
  group('TextSanitizerService', () {
    test('cleans smart quotes and keeps french accents', () {
      const input = 'Réjouisseur — Caméra « Centre »';
      final out = PdfSafeText.clean(input);
      expect(out, contains('Réjouisseur'));
      expect(out, contains('Caméra'));
      expect(out, isNot(contains('\uFFFD')));
    });

    test('csv sanitizer removes line breaks', () {
      expect(CsvTextSanitizer.clean('Ligne\nDeux'), 'Ligne Deux');
    });
  });

  group('ExcelCompatibleCsvService', () {
    test('adds utf8 bom', () {
      const svc = ExcelCompatibleCsvService();
      final bytes = svc.encode('a;b\n1;2');
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });

    test('uses semicolon delimiter for excel', () {
      const svc = ExcelCompatibleCsvService();
      final csv = svc.build(
        title: 'Liste test',
        departmentName: 'Média',
        headers: const ['N°', 'Nom'],
        rows: const [
          ['1', 'Jean Mukendi'],
        ],
      );
      expect(csv.contains(';'), isTrue);
      expect(csv.contains('Média'), isTrue);
    });
  });
}
