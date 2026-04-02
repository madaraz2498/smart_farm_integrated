import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';

class FarmerWelcomeScreen extends StatelessWidget {
  const FarmerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = context.watch<AuthProvider>().displayName;
    final nav = context.read<NavigationProvider>();

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l10n.welcome_user}, $name 👋', style: AppTextStyles.pageTitle),
        const SizedBox(height: 6),
        Text(l10n.app_name, style: AppTextStyles.pageSubtitle),
        const SizedBox(height: AppSizes.pagePadding),
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
