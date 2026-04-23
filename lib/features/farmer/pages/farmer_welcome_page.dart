import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/farmer/providers/message_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/providers/location_provider.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';

import 'package:smart_farm/features/farmer/providers/reports_provider.dart';
import 'package:smart_farm/features/farmer/providers/dashboard_provider.dart';
import '../../../widgets/shared/offline_empty_state.dart';
import '../../../widgets/shared/location_loading_state.dart';

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
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    // LocationProvider._init() already runs on construction and fetches GPS
    // in the background. DashboardProvider auto-loads once coordinates arrive
    // via the ProxyProvider update chain. No location call needed here.

    // Load reports with a small delay so dashboard gets network priority.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await context.read<ReportsProvider>().load();
  }

  String translateService(String service, AppLocalizations l10n) {
    if (service == 'N/A' || service.isEmpty) {
      return l10n.localeName == 'ar' ? ' unavailable' : 'N/A';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = context.watch<AuthProvider>().displayName;
    final nav = context.read<NavigationProvider>();
    final dashboardProv = context.watch<DashboardProvider>();
    final dashboard = dashboardProv.dashboardData;
    final hPadding = Responsive.responsivePadding(context);

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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;
          final authProvider = context.read<AuthProvider>();
          final locationProvider = context.read<LocationProvider>();
          final messageProvider = context.read<FarmerMessageProvider>();
          final reportsProvider = context.read<ReportsProvider>();
          final dashboardProvider = context.read<DashboardProvider>();

          final userId = authProvider.currentUser?.id;
          if (userId == null) return;

          // Refresh GPS first so dashboard gets updated coordinates.
          await locationProvider.refreshLocation();
          if (!mounted) return;

          // Run all secondary refreshes concurrently.
          await Future.wait([
            dashboardProvider.refresh(),
            reportsProvider.load(),
            messageProvider.fetchMessages(userId),
          ]);
        },
        color: AppColors.primary,
        child: _buildContent(hPadding, l10n, name, nav, dashboardProv, dashboard, features),
      ),
    );
  }

  Widget _buildContent(
    double hPadding,
    AppLocalizations l10n,
    String name,
    NavigationProvider nav,
    DashboardProvider dashboardProv,
    dynamic dashboard,
    List<dynamic> features,
  ) {
    final locationProvider = context.watch<LocationProvider>();
    
    // Show location loading state while GPS is still being acquired and
    // the dashboard has no coordinates yet to work with.
    if (locationProvider.isLoading && dashboardProv.isWaitingForLocation) {
      return const LocationLoadingState();
    }
    
    // Show loading state
    if (dashboardProv.isLoading && dashboardProv.dashboardData == null) {
      return const LoadingState(message: 'Loading dashboard...');
    }

    // Show error state
    if (dashboardProv.error != null && dashboardProv.dashboardData == null) {
      return NoDataEmptyState(
        title: 'Dashboard Error',
        description: dashboardProv.error!,
        icon: Icons.error_outline_rounded,
        onAction: () => dashboardProv.refresh(),
        actionText: 'Retry',
      );
    }

    // Show empty state if no data
    if (dashboardProv.dashboardData == null) {
      return const NoDataEmptyState(
        title: 'No Dashboard Data',
        description: 'Unable to load dashboard information. Please check your connection and try again.',
        icon: Icons.dashboard_outlined,
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPadding, 32, hPadding, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                value: translateService(dashboard?.mostUsedService ?? 'N/A', l10n),
              ),
              _WeatherCard(
                title: l10n.weather,
                temp: dashboard?.weatherTemp,
                humidity: dashboard?.weatherHumidity,
                wind: dashboard?.weatherWind,
                description: dashboard?.weatherDescription ??
                    (dashboard?.weather ??
                        (l10n.localeName == 'ar' ? 'جاري التحميل...' : 'Loading...')),
              ),
            ];

            final crossAxisCount = Responsive.isMobile(context) ? 2 : (Responsive.isTablet(context) ? 3 : 4);
            final isVerySmall = Responsive.screenWidth(context) < 450;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isVerySmall ? 1.2 : 0.9, // Much smaller cards
              children: statsWidgets,
            );
          }),
          const SizedBox(height: 32),

          LayoutBuilder(builder: (_, constraints) {
            final cols = Responsive.isDesktop(context)
                ? 3
                : Responsive.isTablet(context)
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
                              aspectRatio: 1.6, // Much smaller cards for mobile
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
                            aspectRatio: 0.8, // Much smaller cards for grid
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
          ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.title,
    required this.temp,
    required this.humidity,
    required this.wind,
    required this.description,
  });

  final String title;
  final String? temp;
  final String? humidity;
  final String? wind;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cleanHumidity = _formatPercent(humidity);
    final cleanWind = _formatWind(wind, l10n);
    final displayTemp = (temp == null || temp!.isEmpty) ? '--°C' : temp!;
    final compact = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4B8B8)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 12),
      child: compact ? _buildCompact(
          l10n, title,
          displayTemp, cleanHumidity, cleanWind, description)
          : _buildWide(l10n, title, displayTemp, cleanHumidity, cleanWind, description),
    );
  }

  Widget _buildWide(
    AppLocalizations l10n,
    String title,
    String displayTemp,
    String cleanHumidity,
    String cleanWind,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSubtle, fontWeight: FontWeight.w600)),
                  Text(displayTemp, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.0)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 14, color: Color(0xFF1D9BF0)),
                    const SizedBox(width: 4),
                    Text(cleanHumidity, style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.air_rounded, size: 14, color: Color(0xFF14B8A6)),
                    const SizedBox(width: 4),
                    Text(cleanWind, style: const TextStyle(fontSize: 12, color: Color(0xFF0891B2))),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              l10n.weather_mild_alert,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
      ],
    );
  }

  Widget _buildCompact(
    AppLocalizations l10n,
    String title,
    String displayTemp,
    String cleanHumidity,
    String cleanWind,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle, fontWeight: FontWeight.w600)),
                  Text(displayTemp, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.0)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFEF4444), size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.water_drop_outlined, size: 14, color: Color(0xFF1D9BF0)),
            const SizedBox(width: 4),
            Text(cleanHumidity, style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
            const Spacer(),
            const Icon(Icons.air_rounded, size: 14, color: Color(0xFF14B8A6)),
            const SizedBox(width: 4),
            Text(cleanWind, style: const TextStyle(fontSize: 12, color: Color(0xFF0891B2))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                l10n.weather_mild_alert,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
      ],
    );
  }

  String _formatPercent(String? value) {
    if (value == null || value.trim().isEmpty) return '--%';
    final v = value.trim();
    return v.contains('%') ? v : '$v%';
  }

  String _formatWind(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return '-- ${l10n.weather_wind_unit}';
    final v = value.trim();
    final hasUnit = v.contains('km') || v.contains('كم');
    if (hasUnit) return v;
    return '$v ${l10n.weather_wind_unit}';
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
