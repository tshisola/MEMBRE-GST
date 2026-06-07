import 'models/smart_models.dart';

/// Recommandations intelligentes basées sur l'analyse.
class SmartRecommendationService {
  List<SmartRecommendation> buildFrom(
    List<SmartIssue> issues,
    DataQualityReport quality,
    SyncHealthReport sync,
  ) {
    final recs = <SmartRecommendation>[];

    if (issues.any((i) => i.category == SmartIssueCategory.pointage)) {
      recs.add(const SmartRecommendation(
        id: 'rec_pointage',
        title: 'Vérifier le pointage',
        description:
            'Des membres actifs ne sont pas visibles au pointage. Lancez une correction automatique.',
        actionLabel: 'Problèmes pointage',
        route: '/smart/pointage-problems',
        priority: 10,
      ));
    }

    if (quality.score < 80) {
      recs.add(SmartRecommendation(
        id: 'rec_quality',
        title: 'Améliorer la qualité des données',
        description:
            'Score actuel : ${quality.score}%. Complétez les informations manquantes.',
        actionLabel: 'Qualité des données',
        route: '/smart/data-quality',
        priority: 8,
      ));
    }

    if (sync.score < 85) {
      recs.add(const SmartRecommendation(
        id: 'rec_sync',
        title: 'Synchroniser les données',
        description:
            'Des éléments attendent la synchronisation. Elle reprendra automatiquement.',
        actionLabel: 'Centre sync',
        route: '/admin/sync',
        priority: 9,
      ));
    }

    recs.add(const SmartRecommendation(
      id: 'rec_team',
      title: 'Planifier l\'équipe du dimanche',
      description: 'Générez une proposition d\'équipe équilibrée avec rotation.',
      actionLabel: 'Planification',
      route: '/smart/team-planning',
      priority: 5,
    ));

    recs.add(const SmartRecommendation(
      id: 'rec_checklist',
      title: 'Checklist avant service',
      description: 'Préparez le matériel et l\'équipe avant l\'activité.',
      actionLabel: 'Checklist',
      route: '/smart/checklist',
      priority: 4,
    ));

    recs.sort((a, b) => b.priority.compareTo(a.priority));
    return recs;
  }
}
