import '../../shared/models/attendance_model.dart';
import '../../shared/models/department_model.dart';
import 'excel_compatible_csv_service.dart';
import 'lubumbashi_branding_service.dart';
import 'text_sanitizer_service.dart';

/// CSV export with Lubumbashi header branding for media department.
class MediaCsvExportService {
  const MediaCsvExportService();

  static const _excel = ExcelCompatibleCsvService();

  String exportAttendance({
    required List<MediaAttendanceRecord> records,
    required Map<String, String> memberNames,
    DateTime? generatedAt,
  }) {
    return _excel.build(
      title: 'Rapport de présence',
      departmentName: LubumbashiBrandingService.mediaDepartmentLabel,
      date: generatedAt ?? DateTime.now(),
      headers: const [
        'N°',
        'Nom complet',
        'Date',
        'Statut',
        'Session',
        'Notes',
        'Ville',
      ],
      rows: records.asMap().entries.map((e) {
        final r = e.value;
        return [
          '${e.key + 1}',
          memberNames[r.memberId] ?? r.memberId,
          r.date.toIso8601String(),
          r.status.label,
          r.sessionType.label,
          r.notes ?? '',
          LubumbashiBrandingService.city,
        ];
      }).toList(),
    );
  }

  String exportSundayList(MediaSundayList list) {
    return _excel.build(
      title: 'Liste du dimanche',
      departmentName: LubumbashiBrandingService.mediaDepartmentLabel,
      date: list.serviceDate,
      headers: const [
        'N°',
        'Nom complet',
        'Rôle Média',
        'Notes',
        'Ville',
      ],
      rows: list.entries.map((e) {
        return [
          '${e.sortOrder + 1}',
          e.memberName,
          e.mediaRole,
          e.notes ?? '',
          list.city,
        ];
      }).toList(),
    );
  }

  List<int> exportAttendanceBytes({
    required List<MediaAttendanceRecord> records,
    required Map<String, String> memberNames,
  }) {
    return _excel.encode(exportAttendance(
      records: records,
      memberNames: memberNames,
    ));
  }

  List<int> exportSundayListBytes(MediaSundayList list) {
    return _excel.encode(exportSundayList(list));
  }
}

typedef CsvTextSanitizerService = TextSanitizerService;
