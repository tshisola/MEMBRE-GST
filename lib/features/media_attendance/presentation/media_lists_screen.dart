import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../../../core/messaging/user_friendly_error_mapper.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../core/services/department_list_automation_service.dart';
import '../../../core/services/manual_list_manager.dart';
import '../../../core/services/media_csv_export_service.dart';
import '../../../core/services/media_lists_local_repository.dart';
import '../../../core/services/media_pdf_export_service.dart';
import '../../advanced/presentation/pdf_preview_screen.dart';
import '../../../core/services/media_permission_service.dart';
import '../../../core/services/media_realtime_service.dart';
import '../../../core/services/smart_media_list_engine.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/media_components.dart';
import '../../../shared/components/premium_states.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/professional_list_viewer.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/department_model.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/models/role_models.dart';

/// Listes du dimanche — offline-first, erreurs sanitizées, UI pro.
class MediaListsScreen extends ConsumerStatefulWidget {
  const MediaListsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MediaListsScreen> createState() => _MediaListsScreenState();
}

class _MediaListsScreenState extends ConsumerState<MediaListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _realtime = MediaRealtimeService();
  final _localRepo = MediaListsLocalRepository();
  final _pdfExport = MediaPdfExportService();
  final _csvExport = const MediaCsvExportService();
  final _listEngine = SmartMediaListEngine();
  final _automation = DepartmentListAutomationService();
  final _manualManager = ManualListManager();
  final _mediaPerms = MediaPermissionService();

  bool _isGenerating = false;
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;
  bool _loadingLocal = true;
  bool _usingLocalFallback = false;
  MediaSundayList? _selectedList;
  List<MediaSundayList> _localAutoLists = [];
  List<MediaSundayList> _localManualLists = [];

  static final _demoMembers = [
    const Member(
      id: '1',
      name: 'Jean Mukendi',
      phone: '+243 990 000 001',
      departmentId: Member.mediaDepartmentId,
      role: 'media_lead',
    ),
    const Member(
      id: '2',
      name: 'Marie Kabongo',
      phone: '+243 990 000 002',
      departmentId: Member.mediaDepartmentId,
      role: 'camera',
    ),
    const Member(
      id: '3',
      name: 'Paul Tshilombo',
      phone: '+243 990 000 003',
      departmentId: Member.mediaDepartmentId,
      role: 'son',
    ),
    const Member(
      id: '4',
      name: 'Grace Mwamba',
      phone: '+243 990 000 004',
      departmentId: Member.mediaDepartmentId,
      role: 'assistant',
    ),
  ];

  static final _demoRoles = {
    '1': MediaRole.chefMedia,
    '2': MediaRole.camera,
    '3': MediaRole.son,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _refreshLocalLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocalLists() async {
    setState(() => _loadingLocal = true);
    try {
      final all = await _localRepo.loadLists();
      if (mounted) {
        setState(() {
          _localAutoLists =
              all.where((l) => !l.isManual).toList(growable: false);
          _localManualLists =
              all.where((l) => l.isManual).toList(growable: false);
          _loadingLocal = false;
        });
      }
    } catch (e) {
      AppErrorPresenter.recordOnly(e, source: 'media_lists_local');
      if (mounted) setState(() => _loadingLocal = false);
    }
  }

  Future<UserRole?> _actorFromSession() async {
    final role = await ref.read(currentUserRoleProvider.future);
    return role;
  }

  MediaSundayList _demoAutoList() {
    return _listEngine.generateSundayList(
      sundayDate: _nextSunday(),
      members: _demoMembers,
      roleByMemberId: _demoRoles,
      listId: const Uuid().v4(),
    );
  }

  DateTime _nextSunday() {
    var cursor = DateTime.now();
    while (cursor.weekday != DateTime.sunday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return DateTime(cursor.year, cursor.month, cursor.day);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppTheme.cardSecondary,
      ),
    );
  }

  Future<void> _generateAutoList() async {
    final actor = await _actorFromSession();
    if (actor != null && !_mediaPerms.canGenerateAuto(actor)) {
      _showMessage('Vous n\'êtes pas autorisé à effectuer cette action.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      MediaSundayList? list;
      if (actor != null) {
        list = await _automation.runScheduledGeneration(
          actor: actor,
          force: true,
        );
      }
      list ??= _demoAutoList();
      await _localRepo.saveList(
        list,
        extra: {'isAutoGenerated': true, 'departmentId': 'media'},
      );
      await _refreshLocalLists();
      _showMessage('Liste automatique enregistrée.');
    } catch (e) {
      AppErrorPresenter.recordOnly(e, source: 'media_lists_generate');
      _showMessage(AppErrorPresenter.forSnackBar(e, source: 'media_lists_generate'));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _createManualList() async {
    final actor = await _actorFromSession();
    if (actor != null && !_mediaPerms.canCreateManual(actor)) {
      _showMessage('Vous n\'êtes pas autorisé à effectuer cette action.');
      return;
    }

    final serviceDate = await showDatePicker(
      context: context,
      initialDate: _nextSunday(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (serviceDate == null || !mounted) return;

    final entries = _demoMembers.asMap().entries.map((e) {
      final role = _demoRoles[e.value.id] ?? MediaRole.assistant;
      return MediaListEntry(
        memberId: e.value.id,
        memberName: e.value.name,
        mediaRole: role.label,
        sortOrder: e.key,
      );
    }).toList();

    setState(() => _isGenerating = true);
    try {
      if (actor != null) {
        await _manualManager.create(
          actor: actor,
          serviceDate: serviceDate,
          entries: entries,
        );
      } else {
        final list = MediaSundayList(
          id: const Uuid().v4(),
          serviceDate: serviceDate,
          entries: entries,
          isAutoGenerated: false,
          isManual: true,
          createdAt: DateTime.now(),
        );
        await _localRepo.saveList(list, extra: {'departmentId': 'media'});
      }
      await _refreshLocalLists();
      _showMessage('Liste manuelle créée.');
    } catch (e) {
      AppErrorPresenter.recordOnly(e, source: 'media_lists_manual');
      _showMessage(AppErrorPresenter.forSnackBar(e, source: 'media_lists_manual'));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPdf(MediaSundayList list) async {
    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _pdfExport.exportSundayList(list: list);
      if (!mounted) return;
      await openPdfPreview(
        context,
        bytes: bytes,
        title: 'Liste Média ${DateFormat('dd/MM/yyyy').format(list.serviceDate)}',
      );
    } catch (e) {
      AppErrorPresenter.recordOnly(e, source: 'media_lists_pdf');
      _showMessage(AppErrorPresenter.forSnackBar(e, source: 'media_lists_pdf'));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportCsv(MediaSundayList list) async {
    setState(() => _isExportingCsv = true);
    try {
      final bytes = _csvExport.exportSundayListBytes(list);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/media_lubumbashi_liste_${list.id}.csv',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Liste Média ${AppConstants.appName}',
      );
    } catch (e) {
      AppErrorPresenter.recordOnly(e, source: 'media_lists_csv');
      _showMessage(AppErrorPresenter.forSnackBar(e, source: 'media_lists_csv'));
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Widget _buildListCard(MediaSundayList list) {
    final dateLabel =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(list.serviceDate);
    final type = list.isManual ? MediaListType.manual : MediaListType.auto;
    final isSelected = _selectedList?.id == list.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.brandOrange : Colors.white12,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedList = list),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ListTypeBadge(type: type),
                  const Spacer(),
                  Text(
                    '${list.entries.length} membres',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.brandWhite,
                ),
              ),
              const SizedBox(height: 8),
              ...list.entries.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${e.sortOrder + 1}.',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.memberName} — ${e.mediaRole}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.brandWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (list.entries.length > 3)
                Text(
                  '+ ${list.entries.length - 3} autres…',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppTheme.brandOrange.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            const Text(
              'Accès non autorisé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.brandWhite,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contactez l\'administrateur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListsContent({required bool manualOnly}) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    return roleAsync.when(
      loading: () => const LoadingState(message: 'Chargement…'),
      error: (_, __) => _buildListsBody(manualOnly: manualOnly, canView: true),
      data: (role) {
        if (role != null && !_mediaPerms.canViewLists(role)) {
          return _accessDeniedView();
        }
        return _buildListsBody(manualOnly: manualOnly, canView: true);
      },
    );
  }

  Widget _buildListsBody({required bool manualOnly, required bool canView}) {
    if (_loadingLocal) {
      return const LoadingState(message: 'Chargement des listes…');
    }

    final localLists = manualOnly ? _localManualLists : _localAutoLists;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final useFirestoreStream =
        FirebaseInitializer.isInitialized && firebaseUser != null;

    if (!useFirestoreStream) {
      if (localLists.isEmpty) {
        return EmptyState(
          title: manualOnly ? 'Aucune liste manuelle' : 'Aucune liste disponible',
          message: FirebaseInitializer.isInitialized
              ? 'Données locales affichées. Synchronisation en arrière-plan.'
              : 'Générez une liste pour commencer.',
          icon: Icons.list_alt,
          actionLabel: manualOnly ? 'Créer manuelle' : 'Générer auto',
          onAction: manualOnly ? _createManualList : _generateAutoList,
        );
      }
      return Column(
        children: [
          if (_usingLocalFallback || firebaseUser == null)
            _localBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: localLists.map(_buildListCard).toList(),
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<MediaSundayList>>(
      stream: _realtime.listsStream(manualOnly: manualOnly),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            localLists.isEmpty) {
          return const LoadingState(message: 'Synchronisation…');
        }

        if (snapshot.hasError) {
          AppErrorPresenter.recordOnly(
            snapshot.error!,
            source: 'media_lists_firestore',
          );
          setState(() => _usingLocalFallback = true);
          if (localLists.isNotEmpty) {
            return Column(
              children: [
                _localBanner(
                  message: UserFriendlyErrorMapper.map(snapshot.error),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: localLists.map(_buildListCard).toList(),
                  ),
                ),
              ],
            );
          }
          return EmptyState(
            title: 'Aucune liste disponible',
            message: UserFriendlyErrorMapper.map(snapshot.error),
            icon: Icons.list_alt,
            actionLabel: manualOnly ? 'Créer manuelle' : 'Générer auto',
            onAction: manualOnly ? _createManualList : _generateAutoList,
          );
        }

        final remote = snapshot.data ?? [];
        final merged = remote.isNotEmpty ? remote : localLists;

        if (merged.isEmpty) {
          return EmptyState(
            title: manualOnly ? 'Aucune liste manuelle' : 'Aucune liste disponible',
            message: 'Créez ou générez une liste du dimanche.',
            icon: Icons.list_alt,
            actionLabel: manualOnly ? 'Créer manuelle' : 'Générer auto',
            onAction: manualOnly ? _createManualList : _generateAutoList,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: merged.map(_buildListCard).toList(),
        );
      },
    );
  }

  Widget _localBanner({String? message}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.brandBlue.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: AppTheme.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? UserFacingMessages.offlineHint,
              style: const TextStyle(fontSize: 12, color: AppTheme.brandBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedListDetail() {
    final list = _selectedList;
    if (list == null) return const SizedBox.shrink();

    final dateLabel =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(list.serviceDate);

    return ProfessionalListViewer<MediaListEntry>(
      title: list.isManual ? 'Liste manuelle' : 'Liste automatique',
      departmentName: 'Département Média',
      dateLabel: dateLabel,
      syncLabel: _usingLocalFallback ? 'Données locales' : null,
      items: list.entries,
      nameOf: (e) => e.memberName,
      subtitleOf: (e) => e.mediaRole,
      searchHint: 'Rechercher un membre…',
      onPdf: () => _exportPdf(list),
      onCsv: () => _exportCsv(list),
      pdfLoading: _isExportingPdf,
      csvLoading: _isExportingCsv,
      canDeleteItem: (e) {
        final role = ref.read(currentUserRoleProvider).valueOrNull;
        const checker = MemberDeletionPermissionChecker();
        return e.memberId.isNotEmpty && checker.canDelete(role);
      },
      onDeleteItem: (e) => context.push('/members/${e.memberId}/delete'),
      onItemTap: (e) {
        if (e.memberId.isNotEmpty) {
          context.push('/members/${e.memberId}');
        }
      },
      emptyTitle: 'Liste vide',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;
    final route = widget.initialTab == 1
        ? '/media/lists/manual'
        : '/media/lists';

    return PopScopeBackGuard(
      fallbackRoute: '/media',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: AppDrawer(currentRoute: route),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: AppBackButton(fallbackRoute: '/media'),
        title: const Text('Listes Média'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.brandOrange,
          labelColor: AppTheme.brandOrange,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Dimanche (auto)', icon: Icon(Icons.auto_awesome, size: 18)),
            Tab(text: 'Manuelles', icon: Icon(Icons.edit_note, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          ScreenHeader(
            title: 'Listes du dimanche',
            subtitle: '${AppConstants.appName} · Auto & manuelles',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
            actions: [
              AdvancedButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf,
                variant: AdvancedButtonVariant.export,
                isExpanded: false,
                isLoading: _isExportingPdf,
                onPressed: _selectedList == null || _isExportingPdf
                    ? null
                    : () => _exportPdf(_selectedList!),
              ),
              AdvancedButton(
                label: 'CSV',
                icon: Icons.table_chart_outlined,
                variant: AdvancedButtonVariant.export,
                isExpanded: false,
                isLoading: _isExportingCsv,
                onPressed: _selectedList == null || _isExportingCsv
                    ? null
                    : () => _exportCsv(_selectedList!),
              ),
            ],
          ),
          Expanded(
            child: _selectedList != null
                ? _buildSelectedListDetail()
                : TabBarView(
              controller: _tabController,
              children: [
                _buildListsContent(manualOnly: false),
                _buildListsContent(manualOnly: true),
              ],
            ),
          ),
          if (_selectedList != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedList = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour aux listes'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: _tabController.index == 0
                  ? AdvancedButton(
                      label: 'Générer liste automatique',
                      icon: Icons.auto_awesome,
                      variant: AdvancedButtonVariant.sync,
                      isLoading: _isGenerating,
                      onPressed: _isGenerating ? null : _generateAutoList,
                    )
                  : AdvancedButton(
                      label: 'Créer liste manuelle',
                      icon: Icons.add,
                      onPressed: _createManualList,
                    ),
            ),
        ],
      ),
    ),
    );
  }
}
