import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/members/qr_member_resolver.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../core/pointage/attendance_time_rules.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/navigation/safe_back_navigation_service.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/search/debounced_search_service.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/premium_states.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/attendance_model.dart';
import '../data/media_attendance_local_repository.dart';
import 'media_attendance_members_provider.dart';
import 'media_pointage_controller.dart';
import 'pointage_qr_scan_screen.dart';
import 'widgets/pointage_widgets.dart';

/// Écran pointage Média — design premium, local-first.
class ProfessionalPointageScreen extends ConsumerStatefulWidget {
  const ProfessionalPointageScreen({super.key});

  @override
  ConsumerState<ProfessionalPointageScreen> createState() =>
      _ProfessionalPointageScreenState();
}

class _ProfessionalPointageScreenState
    extends ConsumerState<ProfessionalPointageScreen> {
  DateTime _selectedDate = DateTime.now();
  MediaSessionType _sessionType = MediaSessionType.sundayService;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _canTakeAttendance = true;
  bool _canDeleteMember = false;
  String? _operatorMemberId;

  final _searchController = TextEditingController();
  final _debouncedSearch = DebouncedSearchService();
  final _controller = MediaPointageController();
  final _attendanceRepo = MediaAttendanceLocalRepository();
  final _qrResolver = QrMemberResolver();

  final Map<String, MediaAttendanceStatus> _attendance = {};
  final Map<String, String> _arrivalTimes = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _checkPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncedSearch.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final canTake = await ref.read(isMediaAttendanceOperatorProvider.future);
    final session = await ref.read(localSessionProvider.future);
    final role = await ref.read(currentUserRoleProvider.future);
    final allowed = canTake ||
        (role?.isAdminGeneral ?? false) ||
        (role?.canTakeAttendance ?? false);
    const deletionChecker = MemberDeletionPermissionChecker();
    if (mounted) {
      setState(() {
        _canTakeAttendance = allowed;
        _operatorMemberId = session.memberId;
        _canDeleteMember = deletionChecker.canDelete(role);
      });
    }
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final saved = await _attendanceRepo.loadForSession(
        date: _selectedDate,
        sessionType: _sessionType,
      );
      final times = await _attendanceRepo.loadArrivalTimes(
        date: _selectedDate,
        sessionType: _sessionType,
      );
      _attendance
        ..clear()
        ..addAll(saved);
      _arrivalTimes
        ..clear()
        ..addAll(times);
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'pointage_load', stack: st);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.brandOrange,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final session = await ref.read(localSessionProvider.future);
      await _attendanceRepo.saveSession(
        date: _selectedDate,
        sessionType: _sessionType,
        attendance: _attendance,
        operatorId: session.userId,
      );
      if (mounted) {
        bumpMediaPointageMembers(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pointage enregistré.')),
        );
      }
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'pointage_save', stack: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement impossible pour le moment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(autoSyncManagerProvider).runBackgroundSync(
            trigger: 'pointage_manual',
            forcePull: true,
          );
      bumpMembersRevision(ref);
      bumpMediaPointageMembers(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirebaseInitializer.isInitialized
                  ? 'Synchronisation en cours.'
                  : 'Synchronisation en attente.',
            ),
          ),
        );
      }
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'pointage_sync', stack: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronisation en attente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _setStatus(String memberId, MediaAttendanceStatus status) {
    setState(() {
      _attendance[memberId] = status;
      _arrivalTimes[memberId] = DateTime.now().toIso8601String();
    });
  }

  Future<void> _onQuickPresent(String memberId) async {
    final autoStatus = AttendanceTimeRules.statusForNow(
      dateTime: DateTime.now(),
      sessionType: _sessionType,
    );
    _setStatus(memberId, autoStatus);
  }

  Future<void> _scanQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PointageQrScanScreen()),
    );
    if (raw == null || !mounted) return;
    await _handleQrResult(raw);
  }

  Future<void> _handleQrResult(String raw) async {
    final result = await _qrResolver.resolve(raw);
    if (!mounted) return;

    if (result.isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.blockedReason!)),
      );
      return;
    }

    if (!result.found || result.member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun membre disponible pour le pointage.')),
      );
      return;
    }

    final member = result.member!;
    if (_attendance.containsKey(member.id) &&
        _attendance[member.id] != MediaAttendanceStatus.absent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} est déjà pointé.')),
      );
      return;
    }

    final session = await ref.read(localSessionProvider.future);
    if (!_controller.canPointMember(
      operatorCanTakeAttendance: _canTakeAttendance,
      operatorMemberId: session.memberId,
      targetMemberId: member.id,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous n\'êtes pas autorisé à pointer ce département.'),
        ),
      );
      return;
    }

    await _onQuickPresent(member.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} pointé.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canTakeAttendance) {
      return PopScopeBackGuard(
        fallbackRoute: '/media',
        child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          leading: const AppBackButton(fallbackRoute: '/media'),
          title: const Text('Pointage Média'),
        ),
        body: const PointageAccessDeniedView(),
      ),
      );
    }

    ref.watch(mediaPointageMembersRevisionProvider);
    final membersAsync = ref.watch(mediaPointageMembersProvider);
    final dateLabel =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate);
    final isConnected = FirebaseInitializer.isInitialized;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await SafeBackNavigationService.handleWillPop(
          context,
          fallbackRoute: '/media',
        );
      },
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/media/attendance'),
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        leading: const AppBackButton(fallbackRoute: '/media'),
        title: const Text('Pointage Média'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, color: AppTheme.brandBlue),
            tooltip: 'Actualiser',
            onPressed: _isSyncing ? null : _syncData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FirebaseConnectionIndicator(
              isConnected: isConnected,
              compact: true,
            ),
          ),
        ],
      ),
      floatingActionButton: PointageQrButton(onPressed: _scanQr),
      body: Column(
        children: [
          ScreenHeader(
            title: 'Pointage Média',
            subtitle: '${AppConstants.city} · $dateLabel',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: PointageSearchBar(
              controller: _searchController,
              onChanged: (v) => _debouncedSearch.search(v, (q) {
                if (mounted) setState(() => _searchQuery = q);
              }),
              onScan: _scanQr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<MediaSessionType>(
                    value: _sessionType,
                    dropdownColor: AppTheme.cardDark,
                    decoration: const InputDecoration(
                      labelText: 'Session',
                      isDense: true,
                    ),
                    items: MediaSessionType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() => _sessionType = v);
                        await _loadAttendance();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PointageFilterChips<PointageStatusFilter>(
              filters: PointageStatusFilter.values,
              selected: _controller.statusFilter,
              labelBuilder: (f) {
                switch (f) {
                  case PointageStatusFilter.all:
                    return 'Tous';
                  case PointageStatusFilter.present:
                    return 'À l\'heure';
                  case PointageStatusFilter.late:
                    return 'Retard';
                  case PointageStatusFilter.absent:
                    return 'Absents';
                  case PointageStatusFilter.excused:
                    return 'Excusés';
                  case PointageStatusFilter.marked:
                    return 'Déjà pointés';
                  case PointageStatusFilter.unmarked:
                    return 'Non pointés';
                }
              },
              onSelected: (f) => setState(() => _controller.statusFilter = f),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PointageFilterChips<PointageMediaListFilter>(
              filters: PointageMediaListFilter.values,
              selected: _controller.mediaListFilter,
              labelBuilder: PointageMediaLists.label,
              onSelected: (f) => setState(() => _controller.mediaListFilter = f),
            ),
          ),
          Expanded(
            child: membersAsync.when(
              loading: () => const LoadingState(message: 'Chargement des membres…'),
              error: (_, __) => const PointageEmptyState(
                title: 'Données locales affichées',
                message: 'Impossible de charger les membres. Réessayez.',
              ),
              data: (members) {
                if (_isLoading) {
                  return const LoadingState(message: 'Chargement du pointage…');
                }

                final counters = _controller.computeCounters(
                  members: members,
                  attendance: _attendance,
                );
                final filtered = _controller.applyFilters(
                  members: members,
                  attendance: _attendance,
                  searchQuery: _searchQuery,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: PointageCounterCard(
                              label: 'Total',
                              value: '${counters.total}',
                              color: AppTheme.brandWhite,
                              icon: Icons.people,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: PointageCounterCard(
                              label: 'Pointés',
                              value: '${counters.marked}',
                              color: AppTheme.brandBlue,
                              icon: Icons.how_to_reg,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: PointageCounterCard(
                              label: 'Non pointés',
                              value: '${counters.unmarked}',
                              color: AppTheme.textMuted,
                              icon: Icons.person_off_outlined,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: PointageCounterCard(
                              label: 'Retards',
                              value: '${counters.late}',
                              color: AppTheme.warningProd,
                              icon: Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isConnected)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'Données locales affichées.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    Expanded(
                      child: filtered.isEmpty
                          ? PointageEmptyState(
                              title: members.isEmpty
                                  ? 'Aucun membre disponible pour le pointage.'
                                  : 'Aucun résultat',
                              message: members.isEmpty
                                  ? 'Créez un membre dans le registre pour commencer.'
                                  : 'Aucun résultat pour « $_searchQuery ».',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final member = filtered[index];
                                final status = _attendance[member.id];
                                return PointageMemberCard(
                                  member: member,
                                  status: status,
                                  arrivalTime: _arrivalTimes[member.id],
                                  canPoint: _controller.canPointMember(
                                    operatorCanTakeAttendance: _canTakeAttendance,
                                    operatorMemberId: _operatorMemberId,
                                    targetMemberId: member.id,
                                  ),
                                  onStatusChanged: (MediaAttendanceStatus s) =>
                                      _setStatus(member.id, s),
                                  onQuickPresent: () => _onQuickPresent(member.id),
                                  showDelete: _canDeleteMember,
                                  onDelete: _canDeleteMember
                                      ? () => context.push(
                                            '/members/${member.id}/delete',
                                          )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(top: BorderSide(color: AppTheme.cardSecondary)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandOrange,
                        foregroundColor: AppTheme.brandWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
