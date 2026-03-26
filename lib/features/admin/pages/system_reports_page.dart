import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/admin_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';

class SystemReportsPage extends StatefulWidget {
  const SystemReportsPage({super.key});
  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {
  String? _dateRange;

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
    _dateRange ??= l10n.last_30_days;

    return Consumer<AdminProvider>(
      builder: (context, prov, _) {
        if (prov.statsLoading && prov.stats == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final stats = prov.stats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(l10n.nav_reports, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.system_reports_subtitle,
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 24),

              // Filters Card
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.filter_list_rounded,
                      title: l10n.report_filters,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.date_range, style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dateRange,
                          isExpanded: true,
                          items: [
                            l10n.last_7_days,
                            l10n.last_30_days,
                            l10n.last_90_days,
                            l10n.last_year,
                            l10n.custom_range,
                          ]
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _dateRange = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 900 ? 2.2 : 1.4,
                children: [
                  _StatCard(
                    svgPath: AppAssets.totalAnalyses,
                    label: l10n.total_analyses,
                    value: stats?.formattedAnalyses ?? '0',
                    trend: stats?.analysesGrowth ?? '+0%',
                    iconColor: const Color(0xFF10B981),
                  ),
                  _StatCard(
                    svgPath: AppAssets.activeUsers,
                    label: l10n.active_users,
                    value: stats?.formattedUsers ?? '0',
                    trend: stats?.usersGrowth ?? '+0%',
                    iconColor: const Color(0xFF3B82F6),
                  ),
                  _StatCard(
                    svgPath: AppAssets.aiServices,
                    label: l10n.ai_services,
                    value: stats?.aiServicesDisplay ?? '6 Active',
                    trend: '99.8% uptime',
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                  _StatCard(
                    svgPath: AppAssets.avgResponse,
                    label: l10n.avg_response,
                    value: '156ms',
                    trend: '-8% from last',
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Charts Row
              LayoutBuilder(builder: (_, c) {
                final stack = c.maxWidth < 600;
                final children = [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                            icon: Icons.bar_chart_rounded,
                            title: l10n.usage_by_service,
                            iconColor: const Color(0xFF10B981)),
                        Text(l10n.total_analyses_per_service,
                            style: AppTextStyles.caption),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMid),
                            ),
                            child: const Center(
                                child: Text('Bar Chart Placeholder',
                                    style: AppTextStyles.caption)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!stack)
                    const SizedBox(width: 24)
                  else
                    const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                            icon: Icons.show_chart_rounded,
                            title: l10n.user_growth,
                            iconColor: const Color(0xFF3B82F6)),
                        Text(l10n.new_user_registrations,
                            style: AppTextStyles.caption),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMid),
                            ),
                            child: const Center(
                                child: Text('Line Chart Placeholder',
                                    style: AppTextStyles.caption)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];

                return stack
                    ? Column(children: children)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children
                            .map((e) =>
                                e is _SectionCard ? Expanded(child: e) : e)
                            .toList());
              }),
              const SizedBox(height: 24),

              // Daily Activity Chart
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        icon: Icons.timeline_rounded,
                        title: l10n.daily_activity,
                        iconColor: const Color(0xFFF59E0B)),
                    Text(l10n.platform_activity_past_week,
                        style: AppTextStyles.caption),
                    const SizedBox(height: 20),
                    AspectRatio(
                      aspectRatio: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMid),
                        ),
                        child: const Center(
                            child: Text('Full Width Activity Chart Placeholder',
                                style: AppTextStyles.caption)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Generated Reports List Footer
              _SectionCard(
                child: LayoutBuilder(builder: (_, c) {
                  final stack = c.maxWidth < 500;
                  final children = [
                    Expanded(
                      flex: stack ? 0 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.description_outlined,
                            title: l10n.generated_reports,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                          Text(
                            l10n.download_historical_reports,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (stack)
                      const SizedBox(height: 16)
                    else
                      const SizedBox(width: 16),
                    SfPrimaryButton(
                      label: l10n.generate_new_report,
                      onPressed: () {},
                      width: stack ? double.infinity : 180,
                      height: 40,
                      icon: Icons.add_circle_outline_rounded,
                    ),
                  ];

                  return stack
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children
                              .map((e) => e is Expanded ? e.child : e)
                              .toList())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: children);
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
          ],
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon, required this.title, this.iconColor});
  final IconData icon;
  final String title;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.svgPath,
      required this.label,
      required this.value,
      required this.trend,
      required this.iconColor});
  final String svgPath;
  final String label, value, trend;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMid),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                svgPath,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(trend,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}
