/// Déclencheurs d'automatisation avec anti-spam.
class AutomationTriggerService {
  static const _minInterval = Duration(minutes: 1);

  bool shouldRun(String trigger, DateTime? lastRun) {
    if (lastRun == null) return true;
    if (trigger == 'dashboard_open') {
      return DateTime.now().difference(lastRun) > const Duration(minutes: 5);
    }
    if (trigger == 'app_start' || trigger == 'after_sync') return true;
    return DateTime.now().difference(lastRun) > _minInterval;
  }
}
