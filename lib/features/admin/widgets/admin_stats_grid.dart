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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

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
      return LayoutBuilder(builder: (_, c) {
        final mobile = c.maxWidth < 600;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          _StatCard(
            title: l10n.total_analyses,
            value: s?.formattedAnalyses ?? '–',
            badge: s?.analysesGrowth ?? '+0%',
            subtitle: l10n.this_month,
            isMobile: mobile,
            svgPath: AppAssets.totalAnalyses,
          ),
          _StatCard(
            title: l10n.total_users,
            value: s?.formattedUsers ?? '–',
            badge: s?.usersGrowth ?? '+0%',
            subtitle: l10n.registered,
            isMobile: mobile,
            svgPath: AppAssets.activeUsers,
          ),
          _StatCard(
            title: l10n.ai_services,
            value: s?.aiServicesDisplay ?? '6 / 6',
            badge: l10n.active,
            subtitle: l10n.active,
            isMobile: mobile,
            svgPath: AppAssets.aiServices,
          ),
          _StatCard(
            title: l10n.most_used,
            value: s?.mostUsedService ?? l10n.plant_disease,
            badge: l10n.top,
            subtitle: l10n.service,
            isMobile: mobile,
            svgPath: AppAssets.avgResponse,
          ),
        ]);
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
      required this.isMobile,
      required this.svgPath});
  final String title, value, badge, subtitle, svgPath;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final w = isMobile
        ? (MediaQuery.of(context).size.width - 64) / 2
        : (MediaQuery.of(context).size.width / 4) - 32;

    return Container(
      width: w,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SvgPicture.asset(svgPath, width: 40, height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8)),
            child: Text(badge,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(title, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
            overflow: TextOverflow.ellipsis),
        Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ]),
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
