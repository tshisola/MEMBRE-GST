import '../../../app/constants.dart';
import '../models/advanced_models.dart';
import 'firebase_messaging_service.dart';
import 'local_notification_repository.dart';
import 'notification_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigation/notification_payload_parser.dart';

/// Règles de notification intelligentes par rôle et événement.
class SmartNotificationRulesEngine {
  SmartNotificationRulesEngine({
    LocalNotificationRepository? repo,
    FirebaseMessagingService? fcm,
  })  : _repo = repo ?? LocalNotificationRepository.instance,
        _fcm = fcm ?? FirebaseMessagingService.instance;

  final LocalNotificationRepository _repo;
  final FirebaseMessagingService _fcm;

  Future<void> onMemberCreated(String memberName, {String? memberId}) => _admin(
        title: 'Nouveau membre',
        message: '$memberName a été enregistré.',
        category: AppNotificationCategory.account,
        route: memberId != null
            ? NotificationPayloadParser.routeForMemberDetail(memberId)
            : null,
      );

  Future<void> onMemberDeleted(String memberName) => _admin(
        title: 'Membre supprimé',
        message: '$memberName a été retiré du registre.',
        category: AppNotificationCategory.critical,
        severity: AppNotificationSeverity.warning,
      );

  Future<void> onSyncError() => _admin(
        title: 'Synchronisation en attente',
        message: 'Des données n\'ont pas encore été synchronisées.',
        category: AppNotificationCategory.sync,
        severity: AppNotificationSeverity.warning,
        route: '/admin/sync',
      );

  Future<void> onInvisiblePointage(int count) => _admin(
        title: 'Membres invisibles au pointage',
        message: '$count membre(s) actif(s) n\'apparaissent pas au pointage.',
        category: AppNotificationCategory.critical,
        severity: AppNotificationSeverity.critical,
        route: '/smart/pointage-problems',
      );

  Future<void> onIncompleteList(String listName) => _admin(
        title: 'Liste incomplète',
        message: 'La liste « $listName » nécessite votre attention.',
        category: AppNotificationCategory.list,
        route: '/media/lists',
      );

  Future<void> onMissingQr(int count) => _admin(
        title: 'QR Code manquant',
        message: '$count membre(s) sans QR Code.',
        category: AppNotificationCategory.critical,
        route: '/members',
      );

  Future<void> onPendingMediaActivation(int count) => _admin(
        title: 'Demandes Média en attente',
        message: '$count demande(s) Google à valider.',
        category: AppNotificationCategory.account,
        route: '/admin/media-activation-requests',
      );

  Future<void> onAccountActivated(String name, {String? memberId}) =>
      _notify(
        title: 'Compte activé',
        message: 'Votre compte est maintenant actif.',
        category: AppNotificationCategory.account,
        targetRole: AppConstants.roleMember,
        memberId: memberId,
        route: '/member/dashboard',
        alsoMember: true,
      );

  Future<void> onSundayListGenerated() => _mediaLead(
        title: 'Liste du dimanche',
        message: 'La liste Média du dimanche a été générée.',
        category: AppNotificationCategory.list,
        route: '/smart/team-planning',
      );

  Future<void> onPostUncovered(String post) => _mediaLead(
        title: 'Poste non couvert',
        message: 'Le poste « $post » n\'a pas encore de responsable.',
        category: AppNotificationCategory.list,
        severity: AppNotificationSeverity.warning,
      );

  Future<void> onChecklistIncomplete(int percent) => _mediaLead(
        title: 'Checklist incomplète',
        message: 'Préparation service : $percent %.',
        category: AppNotificationCategory.general,
        route: '/smart/checklist',
      );

  Future<void> onAttendanceRecorded(String memberId) => _notify(
        title: 'Présence enregistrée',
        message: 'Votre présence a été enregistrée.',
        category: AppNotificationCategory.attendance,
        memberId: memberId,
        route: '/media/history',
        alsoMember: true,
      );

  Future<void> onReportAvailable() => _admin(
        title: 'Rapport disponible',
        message: 'Un rapport intelligent est prêt à consulter.',
        category: AppNotificationCategory.report,
        route: '/advanced/report',
      );

  Future<void> _admin({
    required String title,
    required String message,
    AppNotificationCategory category = AppNotificationCategory.general,
    AppNotificationSeverity severity = AppNotificationSeverity.info,
    String? route,
  }) =>
      _notify(
        title: title,
        message: message,
        category: category,
        severity: severity,
        targetRole: AppConstants.roleAdmin,
        route: route,
      );

  Future<void> _mediaLead({
    required String title,
    required String message,
    AppNotificationCategory category = AppNotificationCategory.general,
    AppNotificationSeverity severity = AppNotificationSeverity.info,
    String? route,
  }) =>
      _notify(
        title: title,
        message: message,
        category: category,
        severity: severity,
        targetRole: AppConstants.roleMediaLead,
        route: route,
      );

  Future<void> _notify({
    required String title,
    required String message,
    AppNotificationCategory category = AppNotificationCategory.general,
    AppNotificationSeverity severity = AppNotificationSeverity.info,
    String? targetRole,
    String? memberId,
    String? route,
    bool alsoMember = false,
  }) async {
    if (!await _allowsCategory(category)) return;

    await _repo.create(
      title: title,
      message: message,
      category: category,
      severity: severity,
      targetRole: alsoMember ? null : targetRole,
      memberId: memberId,
      route: route,
    );
    final payload = route ??
        (memberId != null
            ? NotificationPayloadParser.routeForMemberDetail(memberId)
            : null);
    if (payload != null || severity == AppNotificationSeverity.critical ||
        severity == AppNotificationSeverity.warning) {
      await _fcm.showLocal(
        title: title,
        body: message,
        severity: severity,
        payload: payload,
      );
    }
  }

  Future<bool> _allowsCategory(AppNotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = NotificationPreferencesService(prefs);
    switch (category) {
      case AppNotificationCategory.critical:
      case AppNotificationCategory.sync:
        return settings.criticalAlerts;
      case AppNotificationCategory.attendance:
      case AppNotificationCategory.list:
        return settings.listsAndAttendance;
      case AppNotificationCategory.account:
        return settings.accountsAndActivation;
      case AppNotificationCategory.general:
      case AppNotificationCategory.report:
        return true;
    }
  }
}

/// Façade unifiée notifications push + centre local.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final SmartNotificationRulesEngine _rules = SmartNotificationRulesEngine();
  final LocalNotificationRepository _repo = LocalNotificationRepository.instance;
  final FirebaseMessagingService _fcm = FirebaseMessagingService.instance;

  Future<void> initialize() => _fcm.initialize();

  SmartNotificationRulesEngine get rules => _rules;
  LocalNotificationRepository get repository => _repo;

  Future<int> unreadCount({String? role, String? userId, String? memberId}) =>
      _repo.unreadCount(
        targetRole: role,
        targetUserId: userId,
        memberId: memberId,
      );
}
