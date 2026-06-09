import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../providers/admin_provider.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';

class AdminStatsGrid extends StatefulWidget {
  const AdminStatsGrid({super.key});
  @override
  State<AdminStatsGrid> createState() => _AdminStatsGridState();
}

class _AdminStatsGridState extends State<AdminStatsGrid> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AdminProvider>(builder: (context, prov, _) {
      if (prov.statsLoading) {
        return SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary)));
      }

      final s = prov.stats;

      return LayoutBuilder(builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isExtraWide = screenWidth > 1200;
        final isWide = screenWidth > 700;
        final isCompact = screenWidth < 400;

        // Responsive grid configuration
        final crossAxisCount = isExtraWide
            ? 6
            : isWide
                ? 4
                : 2;
        final spacing = isCompact ? 8.0 : 16.0;

        // Dynamic aspect ratio based on screen size
        double childAspectRatio;
        if (isExtraWide) {
          childAspectRatio = 1.1;
        } else if (isWide) {
          childAspectRatio = 1.0;
        } else if (isCompact) {
          childAspectRatio = 1.4;
        } else {
          childAspectRatio = 1.2;
        } // Lower ratio = Taller cards. Adjusted to fix 11px overflow.

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              title: l10n.total_users,
              value: s?.formattedUsers ?? '–',
              badge: s?.usersGrowth ?? '+0%',
              subtitle: l10n.registered,
              icon: Icons.people_outline,
              iconBgColor: const Color(0xFF6366F1), // Indigo/Blue
            ),
            _StatCard(
              title: l10n.total_analyses,
              value: s?.formattedAnalyses ?? '–',
              badge: s?.analysesGrowth ?? '+0%',
              subtitle: l10n.this_month,
              icon: Icons.show_chart,
              iconBgColor: const Color(0xFF10B981), // Green
            ),
            _StatCard(
              title: l10n.ai_services,
              value: s?.aiServicesDisplay ?? '6 / 6',
              badge: 'All Online',
              subtitle: l10n.active,
              icon: Icons.memory,
              iconBgColor: const Color(0xFF8B5CF6), // Purple
            ),
            _StatCard(
              title: l10n.most_used,
              value: s?.mostUsedService ?? l10n.plant_disease,
              badge: l10n.top,
              subtitle: 'Detection',
              icon: Icons.trending_up,
              iconBgColor: const Color(0xFFF59E0B), // Orange
            ),
          ],
        );
      });
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.badge,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
  });
  final String title, value, badge, subtitle;
  final IconData icon;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 80;
        final iconSize = isCompact ? 16.0 : 18.0;
        final titleFontSize = isCompact ? 9.0 : 10.0;
        final valueFontSize = isCompact ? 14.0 : 16.0;
        final subtitleFontSize = isCompact ? 8.0 : 9.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize + 12,
                  height: iconSize + 12,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }),
    );
  }
}

/// Recent activity list (Real — connected to system notifications).
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  String _timeAgo(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.recent_activity,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Consumer<NotificationProvider>(
          builder: (context, prov, _) {
            final activities = prov.notifications
                .where((n) =>
                    n.type == NotificationType.system ||
                    n.type == NotificationType.user)
                .take(5)
                .toList();

            if (activities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (_, i) {
                final activity = activities[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle),
                        child: Icon(
                            activity.type == NotificationType.system
                                ? Icons.settings_outlined
                                : Icons.person_outline,
                            color: colorScheme.primary,
                            size: 20)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(activity.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface)),
                          Text(activity.body,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ])),
                    Text(_timeAgo(activity.createdAt, l10n),
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ]),
                );
              },
            );
          },
        ),
      ]),
    );
  }
}
