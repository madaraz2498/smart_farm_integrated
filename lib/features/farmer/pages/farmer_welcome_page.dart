import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/features/farmer/providers/message_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/providers/location_provider.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';

import 'package:smart_farm/features/farmer/providers/reports_provider.dart';
import 'package:smart_farm/features/farmer/providers/dashboard_provider.dart';

class FarmerWelcomePage extends StatefulWidget {
  const FarmerWelcomePage({super.key});

  @override
  State<FarmerWelcomePage> createState() => _FarmerWelcomePageState();
}

class _FarmerWelcomePageState extends State<FarmerWelcomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<ReportsProvider>().load();
        context.read<DashboardProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = context.watch<AuthProvider>().displayName;
    final nav = context.read<NavigationProvider>();
    final dashboardProv = context.watch<DashboardProvider>();
    final dashboard = dashboardProv.dashboardData;

    String translateService(String service) {
      if (service == 'N/A' || service.isEmpty) {
        return l10n.localeName == 'ar' ? 'غير متاح' : 'N/A';
      }
      final Map<String, String> mapping = {
        'Animal Weight Estimation': l10n.nav_animal_weight,
        'Plant Disease Detection': l10n.nav_plant_disease,
        'Crop Recommendation': l10n.nav_crop_recommendation,
        'Soil Analysis': l10n.nav_soil_analysis,
        'Fruit Quality Analysis': l10n.nav_fruit_quality,
        'Smart Chatbot': l10n.nav_chatbot,
      };
      return mapping[service] ?? service;
    }

    final features = [
      (
        svg: AppAssets.plantIcon,
        icon: null as IconData?,
        title: l10n.nav_plant_disease,
        desc: l10n.plant_disease_card_desc,
        page: FarmerPage.plantDisease
      ),
      (
        svg: AppAssets.animalIcon,
        icon: null as IconData?,
        title: l10n.nav_animal_weight,
        desc: l10n.animal_weight_card_desc,
        page: FarmerPage.animalWeight
      ),
      (
        svg: AppAssets.cropIcon,
        icon: null as IconData?,
        title: l10n.nav_crop_recommendation,
        desc: l10n.crop_recommendation_card_desc,
        page: FarmerPage.cropRecommendation
      ),
      (
        svg: AppAssets.soilIcon,
        icon: null as IconData?,
        title: l10n.nav_soil_analysis,
        desc: l10n.soil_analysis_card_desc,
        page: FarmerPage.soilAnalysis
      ),
      (
        svg: AppAssets.fruitIcon,
        icon: null as IconData?,
        title: l10n.nav_fruit_quality,
        desc: l10n.fruit_quality_card_desc,
        page: FarmerPage.fruitQuality
      ),
      (
        svg: AppAssets.chatIcon,
        icon: null as IconData?,
        title: l10n.nav_chatbot,
        desc: l10n.chatbot_card_desc,
        page: FarmerPage.chatbot
      ),
      (
        svg: null as String?,
        icon: Icons.email_outlined,
        title: l10n.messages,
        desc: l10n.manage_account_preferences,
        page: FarmerPage.messages
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().currentUser?.id;
        if (userId != null) {
          await Future.wait([
            context.read<FarmerMessageProvider>().fetchMessages(userId),
            context.read<ReportsProvider>().load(),
            context.read<DashboardProvider>().load(),
          ]);
        }
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding, 32, AppSizes.pagePadding, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Enhanced Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.welcome_user}, $name 👋',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(l10n.use_ai_subtitle,
                        style: AppTextStyles.pageSubtitle),
                  ],
                ),
              ),
              if (dashboard?.locationName != null ||
                  context.watch<LocationProvider>().city != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        dashboard?.locationName ??
                            context.watch<LocationProvider>().city!,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Stats Section ──────────────────────────────────────────────────
          LayoutBuilder(builder: (context, statsConstraints) {
            if (dashboardProv.isLoading && dashboard == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final statsWidgets = [
              _StatCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF10B981), // Emerald
                label: l10n.total_analyses,
                value: '${dashboard?.totalAnalyses ?? 0}',
              ),
              _StatCard(
                icon: Icons.show_chart_rounded,
                iconColor: const Color(0xFF10B981), // Emerald
                label: l10n.today,
                value: '${dashboard?.todayAnalyses ?? 0}',
              ),
              _StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFFF59E0B), // Amber
                label: l10n.most_used,
                value: translateService(dashboard?.mostUsedService ?? 'N/A'),
              ),
              _StatCard(
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFF3B82F6), // Blue
                label: l10n.weather,
                value: dashboard?.weather ??
                    (l10n.localeName == 'ar'
                        ? 'جاري التحميل...'
                        : 'Loading...'),
              ),
            ];

            final crossAxisCount = statsConstraints.maxWidth < 350 ? 1 : 2;
            final isVerySmall = statsConstraints.maxWidth < 450;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isVerySmall ? 1.0 : 1.4,
              children: statsWidgets,
            );
          }),
          const SizedBox(height: 32),

          LayoutBuilder(builder: (_, constraints) {
            final cols = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 500
                    ? 2
                    : 1;
            const gap = AppSizes.itemPadding;
            final w = (constraints.maxWidth - gap * (cols - 1)) / cols;

            if (cols == 1) {
              return Column(
                  children: features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: gap),
                            child: AspectRatio(
                              aspectRatio:
                                  1.9, // تم تقليل النسبة قليلاً لزيادة الارتفاع ومنع التداخل
                              child: _FeatureCard(
                                  svg: f.svg,
                                  icon: f.icon,
                                  title: f.title ?? '',
                                  desc: f.desc ?? '',
                                  fixedHeight: true,
                                  onTap: () => nav.goToFarmerPage(f.page)),
                            ),
                          ))
                      .toList());
            }

            return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: features
                    .map((f) => SizedBox(
                          width: w,
                          child: AspectRatio(
                            aspectRatio: 1.6,
                            child: _FeatureCard(
                                svg: f.svg,
                                icon: f.icon,
                                title: f.title ?? '',
                                desc: f.desc ?? '',
                                fixedHeight: true,
                                onTap: () => nav.goToFarmerPage(f.page)),
                          ),
                        ))
                    .toList());
          }),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMid),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          // Text section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {this.svg,
      this.icon,
      required this.title,
      required this.desc,
      required this.onTap,
      this.fixedHeight = false});
  final String? svg;
  final String title, desc;
  final IconData? icon;
  final VoidCallback onTap;
  final bool fixedHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
                  child: Center(
                      child: svg != null
                          ? SvgPicture.asset(svg!, width: 24, height: 24)
                          : Icon(icon ?? Icons.help_outline,
                              color: AppColors.primary, size: 24))),
              const SizedBox(height: AppSizes.itemPadding),
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 6),
              Expanded(
                child: Text(desc,
                    style: AppTextStyles.pageSubtitle.copyWith(fontSize: 13),
                    maxLines: fixedHeight ? 2 : null,
                    overflow: fixedHeight ? TextOverflow.ellipsis : null),
              ),
            ]),
      ),
    );
  }
}
