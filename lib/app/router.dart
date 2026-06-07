import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_deep_link_service.dart';
import '../../core/navigation/notification_deep_link_router.dart';
import '../../core/auth/auth_role_redirector.dart';
import '../../core/auth/role_based_navigation_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/session_redirect_provider.dart';
import '../../core/security/admin_only_diagnostic_guard.dart';
import '../../core/security/route_guards.dart';
import '../../features/auth/presentation/app_recovery_screen.dart';
import '../../features/admin/presentation/create_member_account_screen.dart';
import '../../features/admin/presentation/member_accounts_list_screen.dart';
import '../../core/logging/ifcm_navigation_observer.dart';
import '../../core/ui/startup_loading_guard.dart';
import '../../features/admin/presentation/admin_account_management_screen.dart';
import '../../features/admin/presentation/create_admin_account_screen.dart';
import '../../features/admin/presentation/create_operator_account_screen.dart';
import '../../features/messaging/presentation/conversation_list_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/ai/presentation/ai_chat_screen.dart';
import '../../features/admin/presentation/admin_audit_logs_screen.dart';
import '../../core/auth/admin_recovery_orchestrator.dart';
import '../../features/admin/presentation/admin_owner_recovery_screen.dart';
import '../../features/admin/presentation/password_reset_result_screen.dart';
import '../../features/admin/presentation/role_management_screen.dart';
import '../../features/admin/presentation/app_diagnostic_screen.dart';
import '../../features/admin/presentation/database_repair_screen.dart';
import '../../features/admin_sync/presentation/admin_sync_screen.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../core/widgets/app_shell_screens.dart';
import '../../features/auth/presentation/login_choice_screen.dart';
import '../../features/auth/presentation/mandatory_password_change_screen.dart';
import '../../features/auth/presentation/member_login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/departments/presentation/department_lists_screen.dart';
import '../../features/media_attendance/presentation/media_attendance_screen.dart';
import '../../features/media_attendance/presentation/media_history_screen.dart';
import '../../features/media_attendance/presentation/media_lists_screen.dart';
import '../../features/media_attendance/presentation/media_module_screen.dart';
import '../../features/media_attendance/presentation/media_roles_screen.dart';
import '../../features/member/presentation/member_dashboard_screen.dart';
import '../../features/media_auth/presentation/activation_rejected_screen.dart';
import '../../features/media_auth/presentation/media_activation_requests_screen.dart';
import '../../features/media_auth/presentation/media_member_dashboard_screen.dart';
import '../../features/media_auth/presentation/pending_activation_screen.dart';
import '../../features/members/presentation/create_member_screen.dart';
import '../../features/admin_sync/presentation/pending_sync_actions_screen.dart';
import '../../features/members/presentation/member_conflict_screen.dart';
import '../../features/members/presentation/members_list_screen.dart';
import '../../features/members/presentation/delete_member_screen.dart';
import '../../features/members/presentation/deleted_members_trash_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/smart/presentation/smart_assistant_screen.dart';
import '../../features/smart/presentation/smart_sub_screens.dart';
import '../../features/advanced/presentation/advanced_screens.dart';
import '../../features/advanced/presentation/duplicate_merge_screens.dart';
import '../../features/advanced/presentation/pdf_preview_screen.dart';
import '../../features/web/presentation/web_account_migration_screen.dart';
import '../../features/online_updates/presentation/online_update_center_screen.dart';
import '../../shared/models/member_account_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  final router = GoRouter(
    initialLocation: '/login/member',
    observers: [IfcmNavigationObserver()],
    errorBuilder: (context, state) => AppRecoveryScreen(
      onRetry: () => context.go('/login/member'),
      onContinue: () => context.go('/login/member'),
    ),
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = _isPublicPath(path);
      final session = ref.read(sessionForRedirectProvider);

      if (session == null) {
        if (isPublic) return null;
        return '/login';
      }

      final loggedIn = session.isLoggedIn;

      if (!loggedIn && !isPublic) return '/login';

      if (loggedIn) {
        final guardRedirect = AuthRoleRedirector.guardRoute(
          path: path,
          role: session.role,
          accountType: session.accountType,
          mustChangePassword: session.mustChangePassword,
          activationStatus: session.activationStatus,
        );
        if (guardRedirect != null) return guardRedirect;

        if (path == '/' ||
            path == '/login' ||
            path.startsWith('/login/')) {
          return RoleBasedNavigationService.homeFor(
            role: session.role,
            accountType: session.accountType,
            mustChangePassword: session.mustChangePassword,
          );
        }
      }

      return null;
    },
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          if (StartupUiFlags.bootstrapGateCompleted) {
            return '/login/member';
          }
          return null;
        },
        builder: (context, state) => const SplashRouteScreen(),
      ),
      GoRoute(
        path: '/login',
        redirect: (context, state) {
          if (state.uri.path == '/login') return '/login/member';
          return null;
        },
        routes: [
          GoRoute(
            path: 'choice',
            builder: (context, state) => const LoginChoiceScreen(),
          ),
          GoRoute(
            path: 'admin',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: 'member',
            builder: (context, state) => const MemberLoginScreen(),
          ),
          GoRoute(
            path: 'legacy',
            builder: (context, state) => const LegacyLoginScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/change-password',
        builder: (context, state) => const MandatoryPasswordChangeScreen(),
      ),
      GoRoute(
        path: '/auth/access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: '/auth/owner-recovery',
        builder: (context, state) => const AdminOwnerRecoveryScreen(),
      ),
      GoRoute(
        path: '/auth/password-reset-result',
        builder: (context, state) {
          final result = state.extra as AdminRecoveryResult?;
          return PasswordResetResultScreen(
            result: result ??
                const AdminRecoveryResult(
                  success: false,
                  message: 'Opération terminée.',
                ),
          );
        },
      ),
      GoRoute(
        path: '/auth/pending-activation',
        builder: (context, state) => const PendingActivationScreen(),
      ),
      GoRoute(
        path: '/auth/activation-rejected',
        builder: (context, state) => const ActivationRejectedScreen(),
      ),
      GoRoute(
        path: '/admin/media-activation-requests',
        builder: (context, state) => const AdminRouteGuard(
          child: MediaActivationRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/media/member/dashboard',
        builder: (context, state) => const MemberRouteGuard(
          child: MediaMemberDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => AdminRouteGuard(
          child: Consumer(
            builder: (context, ref, _) {
              final roleAsync = ref.watch(userRoleProvider);
              final nameAsync = ref.watch(userNameProvider);
              return DashboardScreen(
                userRole: roleAsync.value ?? 'admin',
                userName: nameAsync.value ?? 'Responsable',
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/member/dashboard',
        builder: (context, state) => const MemberRouteGuard(
          child: MemberDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/accounts',
        builder: (context, state) => const AdminRouteGuard(
          child: AdminAccountManagementScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create-admin',
            builder: (context, state) => const AdminRouteGuard(
              child: CreateAdminAccountScreen(),
            ),
          ),
          GoRoute(
            path: 'create-operator',
            builder: (context, state) => const AdminRouteGuard(
              child: CreateOperatorAccountScreen(),
            ),
          ),
          GoRoute(
            path: 'roles',
            builder: (context, state) => const AdminRouteGuard(
              child: RoleManagementScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/messaging',
        builder: (context, state) => const AdminRouteGuard(
          child: ConversationListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'chat/:conversationId',
            builder: (context, state) => AdminRouteGuard(
              child: ChatScreen(
                conversationId: state.pathParameters['conversationId']!,
              ),
            ),
          ),
          GoRoute(
            path: 'media-general',
            builder: (context, state) => const AdminRouteGuard(
              child: ChatScreen(conversationId: 'media-general'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AdminRouteGuard(
          child: AppointmentsScreen(),
        ),
      ),
      GoRoute(
        path: '/ai/assistant',
        builder: (context, state) => const AdminRouteGuard(
          child: AiChatScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/audit-logs',
        builder: (context, state) => const AdminRouteGuard(
          child: AdminAuditLogsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/member-accounts',
        builder: (context, state) => const AdminRouteGuard(
          child: MemberAccountsListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AdminRouteGuard(
              child: CreateMemberAccountScreen(),
            ),
          ),
          GoRoute(
            path: 'active',
            builder: (context, state) => const AdminRouteGuard(
              child: MemberAccountsListScreen(activeOnly: true),
            ),
          ),
          GoRoute(
            path: 'inactive',
            builder: (context, state) => const AdminRouteGuard(
              child: MemberAccountsListScreen(activeOnly: false),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/departments/lists',
        builder: (context, state) => const AdminRouteGuard(
          child: DepartmentListsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AdminRouteGuard(
              child: CreateDepartmentListScreen(),
            ),
          ),
          GoRoute(
            path: ':listId',
            builder: (context, state) {
              final listId = state.pathParameters['listId']!;
              final list = state.extra as DepartmentManualList?;
              return AdminRouteGuard(
                child: DepartmentListDetailScreen(
                  listId: listId,
                  initialList: list,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/media',
        builder: (context, state) => AdminRouteGuard(
          child: const MediaModuleScreen(),
        ),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const AdminRouteGuard(
              child: MediaAttendanceScreen(),
            ),
          ),
          GoRoute(
            path: 'roles',
            builder: (context, state) => const AdminRouteGuard(
              child: MediaRolesScreen(),
            ),
          ),
          GoRoute(
            path: 'lists',
            builder: (context, state) => const AdminRouteGuard(
              child: MediaListsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'manual',
                builder: (context, state) => const AdminRouteGuard(
                  child: MediaListsScreen(initialTab: 1),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const AdminRouteGuard(
              child: MediaHistoryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const AdminRouteGuard(
          child: MembersListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AdminRouteGuard(
              child: CreateMemberScreen(),
            ),
          ),
          GoRoute(
            path: 'trash',
            builder: (context, state) => const AdminRouteGuard(
              child: DeletedMembersTrashScreen(),
            ),
          ),
          GoRoute(
            path: 'delete-requests',
            builder: (context, state) => const AdminRouteGuard(
              child: MemberDeleteRequestsScreen(),
            ),
          ),
          GoRoute(
            path: 'deletion-history',
            builder: (context, state) => const AdminRouteGuard(
              child: MemberDeletionHistoryScreen(),
            ),
          ),
          GoRoute(
            path: ':memberId/delete',
            builder: (context, state) {
              final memberId = state.pathParameters['memberId']!;
              return AdminRouteGuard(
                child: DeleteMemberScreen(memberId: memberId),
              );
            },
          ),
          GoRoute(
            path: ':memberId',
            builder: (context, state) {
              final memberId = state.pathParameters['memberId']!;
              return AdminRouteGuard(
                child: MemberDetailScreen(memberId: memberId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/sync',
        builder: (context, state) => const AdminRouteGuard(
          child: AdminSyncScreen(),
        ),
        routes: [
          GoRoute(
            path: 'pending',
            builder: (context, state) => const AdminRouteGuard(
              child: PendingSyncActionsScreen(),
            ),
          ),
          GoRoute(
            path: 'conflicts',
            builder: (context, state) => const AdminRouteGuard(
              child: MemberConflictScreen(),
            ),
          ),
          GoRoute(
            path: 'diagnostic',
            builder: (context, state) => const AdminOnlyDiagnosticGuard(
              child: AppDiagnosticScreen(),
            ),
          ),
          GoRoute(
            path: 'web-migration',
            builder: (context, state) => const AdminOnlyDiagnosticGuard(
              child: WebAccountMigrationScreen(),
            ),
          ),
          GoRoute(
            path: 'online-updates',
            builder: (context, state) => const AdminOnlyDiagnosticGuard(
              child: OnlineUpdateCenterScreen(),
            ),
            routes: [
              GoRoute(
                path: 'texts',
                builder: (context, state) => const AdminOnlyDiagnosticGuard(
                  child: RemoteTextEditorScreen(),
                ),
              ),
              GoRoute(
                path: 'menus',
                builder: (context, state) => const AdminOnlyDiagnosticGuard(
                  child: RemoteMenuEditorScreen(),
                ),
              ),
              GoRoute(
                path: 'attendance-rules',
                builder: (context, state) => const AdminOnlyDiagnosticGuard(
                  child: RemoteRulesEditorScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/database-repair',
        builder: (context, state) => const DatabaseRepairScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/smart',
        builder: (context, state) => const AdminRouteGuard(
          child: SmartAssistantScreen(),
        ),
        routes: [
          GoRoute(
            path: 'assistant',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartAssistantScreen(),
            ),
          ),
          GoRoute(
            path: 'pointage-problems',
            builder: (context, state) => const AdminRouteGuard(
              child: PointageProblemsScreen(),
            ),
          ),
          GoRoute(
            path: 'data-quality',
            builder: (context, state) => const AdminRouteGuard(
              child: DataQualityDashboardScreen(),
            ),
          ),
          GoRoute(
            path: 'team-planning',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartTeamPlanningScreen(),
            ),
          ),
          GoRoute(
            path: 'attendance-alerts',
            builder: (context, state) => const AdminRouteGuard(
              child: AttendanceAlertsScreen(),
            ),
          ),
          GoRoute(
            path: 'checklist',
            builder: (context, state) => const AdminRouteGuard(
              child: ServiceChecklistScreen(),
            ),
          ),
          GoRoute(
            path: 'report',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartReportDashboardScreen(),
            ),
          ),
          GoRoute(
            path: 'admin-dashboard',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartAdminDashboardScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/advanced',
        builder: (context, state) => const AdminRouteGuard(
          child: CommandCenterScreen(),
        ),
        routes: [
          GoRoute(
            path: 'command-center',
            builder: (context, state) => const AdminRouteGuard(
              child: CommandCenterScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const AdminRouteGuard(
              child: NotificationCenterScreen(),
            ),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const AdminRouteGuard(
                  child: NotificationSettingsScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'quick-actions',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartQuickActionsScreen(),
            ),
          ),
          GoRoute(
            path: 'approvals',
            builder: (context, state) => const AdminRouteGuard(
              child: ApprovalRequestsScreen(),
            ),
          ),
          GoRoute(
            path: 'audit',
            builder: (context, state) => const AdminRouteGuard(
              child: AuditTimelineScreen(),
            ),
          ),
          GoRoute(
            path: 'duplicates',
            builder: (context, state) => const AdminRouteGuard(
              child: DuplicateWarningScreen(),
            ),
          ),
          GoRoute(
            path: 'duplicate-merge',
            builder: (context, state) => const AdminRouteGuard(
              child: DuplicateMergeHubScreen(),
            ),
            routes: [
              GoRoute(
                path: 'preview',
                builder: (context, state) {
                  final primary = state.uri.queryParameters['primary'] ?? '';
                  final secondary = state.uri.queryParameters['secondary'] ?? '';
                  return AdminRouteGuard(
                    child: DuplicateMergePreviewScreen(
                      primaryId: primary,
                      secondaryId: secondary,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'pdf-preview',
            builder: (context, state) {
              final key = state.uri.queryParameters['key'] ?? '';
              return AdminRouteGuard(
                child: PdfPreviewScreen(cacheKey: key),
              );
            },
          ),
          GoRoute(
            path: 'performance',
            builder: (context, state) => const AdminRouteGuard(
              child: PerformanceScreen(),
            ),
          ),
          GoRoute(
            path: 'calendar',
            builder: (context, state) => const AdminRouteGuard(
              child: MediaCalendarScreen(),
            ),
          ),
          GoRoute(
            path: 'live',
            builder: (context, state) => const AdminRouteGuard(
              child: LiveActivityScreen(),
            ),
          ),
          GoRoute(
            path: 'replacements',
            builder: (context, state) => const AdminRouteGuard(
              child: ReplacementSuggestionsScreen(),
            ),
          ),
          GoRoute(
            path: 'action-history',
            builder: (context, state) => const AdminRouteGuard(
              child: SmartActionHistoryScreen(),
            ),
          ),
          GoRoute(
            path: 'report',
            builder: (context, state) => const AdminRouteGuard(
              child: AdvancedReportHubScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  NotificationDeepLinkRouter.instance.install((route) {
    final session = ref.read(sessionForRedirectProvider);
    AppDeepLinkService.instance.open(router, route: route, session: session);
  });

  return router;
});

bool _isPublicPath(String path) {
  return path == '/' ||
      path == '/login' ||
      path.startsWith('/login/') ||
      path.startsWith('/auth/') ||
      path == '/database-repair' ||
      path == '/media/member/dashboard';
}

/// Notifies GoRouter when session providers change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(localSessionProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
