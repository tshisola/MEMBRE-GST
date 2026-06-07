import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/smart/models/smart_models.dart';

/// Composants UI premium pour l'intelligence MEDIA LUBUMBASHI.
class SmartAlertCard extends StatelessWidget {
  const SmartAlertCard({
    super.key,
    required this.issue,
    this.onFix,
    this.onDetails,
    this.onIgnore,
  });

  final SmartIssue issue;
  final VoidCallback? onFix;
  final VoidCallback? onDetails;
  final VoidCallback? onIgnore;

  Color get _accent {
    switch (issue.severity) {
      case SmartIssueSeverity.critical:
        return AppTheme.errorProd;
      case SmartIssueSeverity.warning:
        return AppTheme.brandOrange;
      case SmartIssueSeverity.info:
        return AppTheme.brandBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: _accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.title,
                  style: const TextStyle(
                    color: AppTheme.brandWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(issue.message, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          if (onFix != null || onDetails != null || onIgnore != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (issue.autoFixable && onFix != null)
                  TextButton.icon(
                    onPressed: onFix,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Corriger'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.successProd),
                  ),
                if (onDetails != null)
                  TextButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Voir détails'),
                  ),
                if (onIgnore != null)
                  TextButton(
                    onPressed: onIgnore,
                    child: const Text('Ignorer'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SmartScoreCard extends StatelessWidget {
  const SmartScoreCard({
    super.key,
    required this.label,
    required this.score,
    this.icon = Icons.analytics_outlined,
    this.color,
    this.showPercent = true,
  });

  final String label;
  final int score;
  final IconData icon;
  final Color? color;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _scoreColor(score);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 10),
          Text(
            showPercent ? '$score%' : '$score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.successProd;
    if (s >= 60) return AppTheme.brandOrange;
    return AppTheme.errorProd;
  }
}

class SmartRecommendationCard extends StatelessWidget {
  const SmartRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  final SmartRecommendation recommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardSecondary,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: AppTheme.goldAccent),
        title: Text(recommendation.title),
        subtitle: Text(recommendation.description),
        trailing: recommendation.actionLabel != null
            ? FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(recommendation.actionLabel!, style: const TextStyle(fontSize: 12)),
              )
            : null,
      ),
    );
  }
}

class SmartProgressCard extends StatelessWidget {
  const SmartProgressCard({
    super.key,
    required this.label,
    required this.percent,
  });

  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 10,
              backgroundColor: AppTheme.cardSecondary,
              color: AppTheme.brandOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text('$percent%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class SmartDashboardGrid extends StatelessWidget {
  const SmartDashboardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: children,
    );
  }
}

class MemberScoreCard extends StatelessWidget {
  const MemberScoreCard({super.key, required this.score});

  final MemberMediaScore score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          MemberScoreBadgeChip(score: score),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Média',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${score.score} / 100',
                  style: const TextStyle(color: AppTheme.goldAccent, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MemberScoreBadgeChip extends StatelessWidget {
  const MemberScoreBadgeChip({super.key, required this.score, this.compact = false});

  final MemberMediaScore score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(score.badge);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        score.badge.label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _badgeColor(MemberScoreBadge badge) {
    switch (badge) {
      case MemberScoreBadge.excellent:
        return AppTheme.successProd;
      case MemberScoreBadge.regular:
        return AppTheme.brandBlue;
      case MemberScoreBadge.watch:
        return AppTheme.brandOrange;
      case MemberScoreBadge.inactive:
        return AppTheme.errorProd;
      case MemberScoreBadge.newMember:
        return AppTheme.goldAccent;
    }
  }
}

class DeleteImpactPreviewCard extends StatelessWidget {
  const DeleteImpactPreviewCard({super.key, required this.report});

  final DeletionImpactReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorProd.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impact de la suppression',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandWhite),
          ),
          const SizedBox(height: 8),
          Text('Niveau : ${report.impactLevel}',
              style: const TextStyle(color: AppTheme.brandOrange)),
          const SizedBox(height: 8),
          ...report.warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(w, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntelligentEmptyState extends StatelessWidget {
  const IntelligentEmptyState({
    super.key,
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: AppTheme.successProd.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

typedef SmartActionCard = SmartAlertCard;
typedef AdvancedFilterBar = SizedBox;
typedef ProfessionalBackButton = BackButton;

class RotationSuggestionCard extends StatelessWidget {
  const RotationSuggestionCard({super.key, required this.post});

  final SundayTeamPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.2),
          child: Text('${post.confidence}', style: const TextStyle(fontSize: 11)),
        ),
        title: Text(post.label),
        subtitle: Text(post.assignedMemberName ?? 'Non assigné'),
      ),
    );
  }
}
