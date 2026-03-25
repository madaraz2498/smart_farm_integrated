import 'package:flutter/material.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../widgets/admin_stats_grid.dart';
import '../../../shared/theme/app_theme.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(children: [
            const Icon(Icons.dashboard_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(l10n.admin_dashboard, style: AppTextStyles.pageTitle),
          ]),
          const SizedBox(height: 4),
          Text(l10n.admin_dashboard_subtitle, style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 24),
          
          const AdminStatsGrid(),
          const SizedBox(height: 24),
          const RecentActivityList(),
        ],
      ),
    );
  }
}
