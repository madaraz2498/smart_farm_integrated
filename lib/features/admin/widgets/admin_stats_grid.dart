import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../providers/admin_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AdminStatsGrid extends StatefulWidget {
  const AdminStatsGrid({super.key});
  @override
  State<AdminStatsGrid> createState() => _AdminStatsGridState();
}

class _AdminStatsGridState extends State<AdminStatsGrid> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AdminProvider>(builder: (context, prov, _) {
      if (prov.statsLoading) {
        return const SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)));
      }

      final s = prov.stats;
      
      return LayoutBuilder(builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isExtraWide = screenWidth > 1200;
        final isWide = screenWidth > 700;
        final isCompact = screenWidth < 400;
        
        // Responsive grid configuration
        final crossAxisCount = isExtraWide ? 6 : isWide ? 4 : 2;
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
        }        // Lower ratio = Taller cards. Adjusted to fix 11px overflow.

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              title: l10n.total_analyses,
              value: s?.formattedAnalyses ?? '–',
              badge: s?.analysesGrowth ?? '+0%',
              subtitle: l10n.this_month,
              svgPath: AppAssets.totalAnalyses,
            ),
            _StatCard(
              title: l10n.total_users,
              value: s?.formattedUsers ?? '–',
              badge: s?.usersGrowth ?? '+0%',
              subtitle: l10n.registered,
              svgPath: AppAssets.activeUsers,
            ),
            _StatCard(
              title: l10n.ai_services,
              value: s?.aiServicesDisplay ?? '6 / 6',
              badge: l10n.active,
              subtitle: l10n.active,
              svgPath: AppAssets.aiServices,
            ),
            _StatCard(
              title: l10n.most_used,
              value: s?.mostUsedService ?? l10n.plant_disease,
              badge: l10n.top,
              subtitle: l10n.service,
              svgPath: AppAssets.avgResponse,
            ),
          ],
        );
      });
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title,
      required this.value,
      required this.badge,
      required this.subtitle,
      required this.svgPath});
  final String title, value, badge, subtitle, svgPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Use responsive sizing based on available space
        final isCompact = constraints.maxHeight < 80;
        final iconSize = isCompact ? 18.0 : 22.0;
        final titleFontSize = isCompact ? 9.0 : 10.0;
        final valueFontSize = isCompact ? 13.0 : 15.0;
        final subtitleFontSize = isCompact ? 8.0 : 9.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and badge - use fixed height to prevent overflow
            SizedBox(
              height: iconSize + 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(svgPath, width: iconSize, height: iconSize),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(3)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badge,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 7,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Use minimal flexible spacing
            const SizedBox(height: 2),
            // Title - use Flexible with FittedBox to prevent overflow
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: titleFontSize + 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title, 
                    style: AppTextStyles.caption.copyWith(fontSize: titleFontSize),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Value - use Flexible with constrained height
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: valueFontSize + 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Subtitle - use Flexible with constrained height
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: subtitleFontSize + 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle, 
                    style: AppTextStyles.caption.copyWith(fontSize: subtitleFontSize),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.recent_activity, style: AppTextStyles.cardTitle),
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
                    style: AppTextStyles.caption,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (_, i) {
                final activity = activities[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle),
                        child: Icon(
                            activity.type == NotificationType.system
                                ? Icons.settings_outlined
                                : Icons.person_outline,
                            color: AppColors.primary,
                            size: 20)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(activity.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          Text(activity.body,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ])),
                    Text(_timeAgo(activity.createdAt, l10n),
                        style: AppTextStyles.caption.copyWith(fontSize: 11)),
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
