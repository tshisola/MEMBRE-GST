import 'package:printing/printing.dart';

import '../../../features/members/data/local_member_repository.dart';
import '../../smart/data_quality_engine.dart';
import '../../smart/pointage_visibility_checker.dart';
import '../../smart/report/post_service_report_engine.dart';
import '../../smart/sync_intelligence_engine.dart';
import '../models/advanced_models.dart';
import 'advanced_pdf_template.dart';

enum SmartReportType {
  dailyAttendance,
  weeklyAttendance,
  sundayMedia,
  lateMembers,
  absentMembers,
  dataQuality,
  syncHealth,
  mediaIntelligence,
  memberPerformance,
}

/// Export PDF intelligent — rapports professionnels MEDIA LUBUMBASHI.
class SmartPdfReportService {
  SmartPdfReportService({
    AdvancedPdfTemplate? template,
    LocalMemberRepository? members,
    PostServiceReportEngine? postReport,
    DataQualityEngine? quality,
    SyncIntelligenceEngine? sync,
    PointageVisibilityChecker? pointage,
  })  : _template = template ?? AdvancedPdfTemplate(),
        _members = members ?? LocalMemberRepository(),
        _postReport = postReport ?? PostServiceReportEngine(),
        _quality = quality ?? DataQualityEngine(),
        _sync = sync ?? SyncIntelligenceEngine(),
        _pointage = pointage ?? PointageVisibilityChecker();

  final AdvancedPdfTemplate _template;
  final LocalMemberRepository _members;
  final PostServiceReportEngine _postReport;
  final DataQualityEngine _quality;
  final SyncIntelligenceEngine _sync;
  final PointageVisibilityChecker _pointage;

  Future<void> shareReport(
    SmartReportType type, {
    String? responsible,
  }) async {
    final doc = await buildReport(type, responsible: responsible);
    final name = _fileName(type);
    await Printing.sharePdf(bytes: await doc.save(), filename: name);
  }

  Future<dynamic> buildReport(
    SmartReportType type, {
    String? responsible,
  }) async {
    switch (type) {
      case SmartReportType.dailyAttendance:
      case SmartReportType.weeklyAttendance:
      case SmartReportType.sundayMedia:
      case SmartReportType.lateMembers:
      case SmartReportType.absentMembers:
        return _attendanceReport(type, responsible);
      case SmartReportType.dataQuality:
        return _qualityReport(responsible);
      case SmartReportType.syncHealth:
        return _syncReport(responsible);
      case SmartReportType.mediaIntelligence:
        return _intelligenceReport(responsible);
      case SmartReportType.memberPerformance:
        return _performanceReport(responsible);
    }
  }

  Future<dynamic> _attendanceReport(SmartReportType type, String? responsible) async {
    final report = await _postReport.generate();
    final headers = ['Indicateur', 'Valeur'];
    final rows = [
      ['Présents', '${report.presentCount}'],
      ['Absents', '${report.absentCount}'],
      ['Retardataires', '${report.lateCount}'],
      ['À l\'heure', '${report.onTimeCount}'],
      ['Postes couverts', '${report.coveredPosts}'],
      ['Postes non couverts', '${report.uncoveredPosts}'],
    ];
    return _template.buildSmartReport(
      reportTitle: _title(type),
      subtitle: 'Rapport de présence MEDIA LUBUMBASHI',
      headers: headers,
      rows: rows,
      stats: {
        'Présents': report.presentCount,
        'Absents': report.absentCount,
        'Retards': report.lateCount,
      },
      responsible: responsible,
    );
  }

  Future<dynamic> _qualityReport(String? responsible) async {
    final q = await _quality.analyze();
    return _template.buildSmartReport(
      reportTitle: 'Qualité des données',
      subtitle: 'Score : ${q.score} %',
      headers: ['Problème', 'Détail'],
      rows: q.issues
          .take(20)
          .map((i) => [i.title, i.message])
          .toList(),
      stats: {'Score qualité': q.score, 'Problèmes': q.issues.length},
      responsible: responsible,
    );
  }

  Future<dynamic> _syncReport(String? responsible) async {
    final s = await _sync.analyze();
    return _template.buildSmartReport(
      reportTitle: 'Synchronisation',
      subtitle: 'Score : ${s.score} %',
      headers: ['Élément', 'Valeur'],
      rows: [
        ['En attente', '${s.pendingCount}'],
        ['Échecs', '${s.failedCount}'],
        ['Local seulement', '${s.localOnlyCount}'],
      ],
      stats: {
        'Score sync': s.score,
        'En attente': s.pendingCount,
        'Échecs': s.failedCount,
      },
      responsible: responsible,
    );
  }

  Future<dynamic> _intelligenceReport(String? responsible) async {
    final p = await _pointage.check();
    final q = await _quality.analyze();
    return _template.buildSmartReport(
      reportTitle: 'Intelligence Média',
      subtitle: 'Analyse globale',
      headers: ['Domaine', 'Statut'],
      rows: [
        ['Pointage visible', '${p.visibleCount}'],
        ['Pointage invisible', '${p.invisibleMembers.length}'],
        ['Qualité données', '${q.score} %'],
      ],
      stats: {
        'Visibles': p.visibleCount,
        'Invisibles': p.invisibleMembers.length,
        'Qualité': q.score,
      },
      responsible: responsible,
    );
  }

  Future<dynamic> _performanceReport(String? responsible) async {
    final active = await _members.listActive();
    final headers = ['Membre', 'Code', 'Département'];
    final rows = active
        .take(30)
        .map((m) => [m.displayName, m.memberCode, m.departmentName ?? '—'])
        .toList();
    return _template.buildSmartReport(
      reportTitle: 'Performance des membres',
      subtitle: '${active.length} membres actifs',
      headers: headers,
      rows: rows,
      stats: {'Actifs': active.length},
      responsible: responsible,
    );
  }

  String _title(SmartReportType type) {
    switch (type) {
      case SmartReportType.dailyAttendance:
        return 'Présence du jour';
      case SmartReportType.weeklyAttendance:
        return 'Présence hebdomadaire';
      case SmartReportType.sundayMedia:
        return 'Rapport Média du dimanche';
      case SmartReportType.lateMembers:
        return 'Retardataires';
      case SmartReportType.absentMembers:
        return 'Absents';
      default:
        return 'Rapport MEDIA';
    }
  }

  String _fileName(SmartReportType type) {
    final d = DateTime.now();
    return 'media_${type.name}_${d.year}${d.month}${d.day}.pdf';
  }
}
