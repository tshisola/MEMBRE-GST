import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../core/services/media_csv_export_service.dart';
import '../../../core/services/media_pdf_export_service.dart';
import '../../advanced/presentation/pdf_preview_screen.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/professional_list_viewer.dart';
import '../../../shared/components/premium_states.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/attendance_model.dart';

class MediaHistoryScreen extends StatefulWidget {
  const MediaHistoryScreen({super.key});

  @override
  State<MediaHistoryScreen> createState() => _MediaHistoryScreenState();
}

class _MediaHistoryScreenState extends State<MediaHistoryScreen> {
  int _filterIndex = 0;
  bool _isLoading = false;
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  final _pdfExport = MediaPdfExportService();
  final _csvExport = const MediaCsvExportService();

  static const _filterLabels = ['Tout', 'Présents', 'Absents', 'Retards'];

  static final List<({String name, DateTime date, MediaAttendanceStatus status})> _records = [
    (name: 'Jean Mukendi', date: DateTime(2026, 5, 25), status: MediaAttendanceStatus.present),
    (name: 'Marie Kabongo', date: DateTime(2026, 5, 25), status: MediaAttendanceStatus.present),
    (name: 'Paul Tshilombo', date: DateTime(2026, 5, 25), status: MediaAttendanceStatus.late),
    (name: 'Grace Mwamba', date: DateTime(2026, 5, 18), status: MediaAttendanceStatus.absent),
    (name: 'Jean Mukendi', date: DateTime(2026, 5, 18), status: MediaAttendanceStatus.present),
  ];

  List<({String name, DateTime date, MediaAttendanceStatus status})> get _filtered {
    return switch (_filterIndex) {
      1 => _records.where((r) => r.status == MediaAttendanceStatus.present).toList(),
      2 => _records.where((r) => r.status == MediaAttendanceStatus.absent).toList(),
      3 => _records.where((r) => r.status == MediaAttendanceStatus.late).toList(),
      _ => _records,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLoading = false);
  }

  List<MediaAttendanceRecord> get _asRecords {
    return _records.map((r) {
      return MediaAttendanceRecord(
        id: '${r.name}-${r.date.millisecondsSinceEpoch}',
        memberId: r.name.toLowerCase().replaceAll(' ', '_'),
        date: r.date,
        status: r.status,
        sessionType: MediaSessionType.sundayService,
      );
    }).toList();
  }

  Map<String, String> get _memberNames {
    return {for (final r in _records) r.name.toLowerCase().replaceAll(' ', '_'): r.name};
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _pdfExport.exportAttendanceReport(
        title: 'Historique pointage',
        records: _asRecords,
        memberNames: _memberNames,
      );
      if (!mounted) return;
      await openPdfPreview(
        context,
        bytes: bytes,
        title: 'Historique pointage',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorPresenter.forSnackBar(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExportingCsv = true);
    try {
      final bytes = _csvExport.exportAttendanceBytes(
        records: _asRecords,
        memberNames: _memberNames,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ifcm_lubumbashi_historique.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Historique Média IFCM ${AppConstants.city}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorPresenter.forSnackBar(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Color _statusColor(MediaAttendanceStatus status) {
    return switch (status) {
      MediaAttendanceStatus.present => AppTheme.success,
      MediaAttendanceStatus.absent => AppTheme.danger,
      MediaAttendanceStatus.late => AppTheme.goldAccent,
      MediaAttendanceStatus.excused => AppTheme.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;

    return PopScopeBackGuard(
      fallbackRoute: '/media',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/media/history'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/media'),
        title: const Text('Historique'),
      ),
      body: Column(
        children: [
          ProfessionalListHeader(
            title: 'Historique de pointage',
            departmentName: 'Département Média',
            totalCount: _filtered.length,
            syncLabel: isConnected ? 'Synchronisé' : 'Données locales',
          ),
          ListExportToolbar(
            onPdf: _isExportingPdf ? null : _exportPdf,
            onCsv: _isExportingCsv ? null : _exportCsv,
            onRefresh: _loadHistory,
            pdfLoading: _isExportingPdf,
            csvLoading: _isExportingCsv,
            refreshLoading: _isLoading,
          ),
          ListFilterChips(
            labels: _filterLabels,
            selectedIndex: _filterIndex,
            onSelected: (i) => setState(() => _filterIndex = i),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : _filtered.isEmpty
                    ? const EmptyState(
                        title: 'Aucun enregistrement',
                        message: 'Aucun pointage ne correspond aux filtres sélectionnés.',
                        icon: Icons.history,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final record = _filtered[index];
                          final color = _statusColor(record.status);
                          return AdvancedListTableRow(
                            index: index + 1,
                            name: record.name,
                            subtitle:
                                '${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(record.date)} · ${record.status.label}',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                record.status.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
    );
  }
}
