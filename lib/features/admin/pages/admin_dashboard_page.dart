import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/admin_provider.dart';
import '../reports/providers/report_provider.dart';
import '../widgets/admin_charts.dart';
import '../widgets/admin_stats_grid.dart';
import '../../../shared/theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
      context.read<AdminReportProvider>().fetchAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportProv = context.watch<AdminReportProvider>();
    final pagePadding = Responsive.responsivePadding(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<AdminProvider>().refreshAll(),
                context.read<AdminReportProvider>().fetchAllReports(force: true),
              ]);
            },
            color: AppColors.primary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = Responsive.isMobile(context);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Header
                Row(children: [
                  const Icon(Icons.dashboard_outlined,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(l10n.admin_dashboard, style: AppTextStyles.pageTitle),
                ]),
                const SizedBox(height: 4),
                Text(l10n.admin_dashboard_subtitle,
                    style: AppTextStyles.pageSubtitle),
                const SizedBox(height: 24),

                // 1. Stats Grid
                const AdminStatsGrid(),
                const SizedBox(height: 24),

                // 2. Charts Section
                if (reportProv.isLoading && reportProv.stats == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Preparing your dashboard...',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // If refreshing in background, show a thin indicator
                  if (reportProv.isLoading && reportProv.stats != null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(
                          minHeight: 2, color: AppColors.primary),
                    ),

                  if (isMobile)
                    Column(
                      children: [
                        UserGrowthChart(data: reportProv.growthList),
                        const SizedBox(height: 24),
                        ServiceDistributionChart(data: reportProv.usageList),
                        const SizedBox(height: 24),
                        WeeklyActivityChart(data: reportProv.activityList),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: UserGrowthChart(data: reportProv.growthList),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: ServiceDistributionChart(
                              data: reportProv.usageList),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: WeeklyActivityChart(data: reportProv.activityList),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 24),
                // 3. Recent Activity
                const RecentActivityList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// _ChartCard is no longer needed as the widgets handle their own cards now
