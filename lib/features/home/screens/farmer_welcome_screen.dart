// lib/features/home/screens/farmer_welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';

class FarmerWelcomeScreen extends StatelessWidget {
  const FarmerWelcomeScreen({super.key});

  static const _features = [
    (svg: 'assets/images/icons/plant_icon.svg',  title: 'Plant Disease Detection',   desc: 'Detect diseases early using AI image analysis.',            page: FarmerPage.plantDisease),
    (svg: 'assets/images/icons/animal_icon.svg', title: 'Animal Weight Estimation',  desc: 'Estimate animal weight without physical scales.',            page: FarmerPage.animalWeight),
    (svg: 'assets/images/icons/crop_icon.svg',   title: 'Crop Recommendation',       desc: 'Get crop suggestions based on soil and climate.',            page: FarmerPage.cropRecommendation),
    (svg: 'assets/images/icons/soil_icon.svg',   title: 'Soil Type Analysis',         desc: 'Analyze soil fertility using your data.',                   page: FarmerPage.soilAnalysis),
    (svg: 'assets/images/icons/fruit_icon.svg',  title: 'Fruit Quality Analysis',    desc: 'Classify fruit quality and detect defects.',                 page: FarmerPage.fruitQuality),
    (svg: 'assets/images/icons/chat_icon.svg',   title: 'Smart Farm Chatbot',        desc: 'Ask questions and get instant farming advice.',              page: FarmerPage.chatbot),
  ];

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().displayName;
    final nav  = context.read<NavigationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, $name 👋', style: AppTextStyles.pageTitle),
        const SizedBox(height: 6),
        const Text('Use AI to improve your farming decisions', style: AppTextStyles.pageSubtitle),
        const SizedBox(height: AppSizes.pagePadding),

        LayoutBuilder(builder: (_, constraints) {
          final cols = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 500 ? 2 : 1;
          const gap  = AppSizes.itemPadding;
          final w    = (constraints.maxWidth - gap * (cols - 1)) / cols;

          if (cols == 1) {
            return Column(children: _features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: _FeatureCard(svg: f.svg, title: f.title, desc: f.desc,
                  onTap: () => nav.goToFarmerPage(f.page)),
            )).toList());
          }

          return Wrap(spacing: gap, runSpacing: gap,
            children: _features.map((f) => SizedBox(width: w, height: 192,
              child: _FeatureCard(svg: f.svg, title: f.title, desc: f.desc,
                  fixedHeight: true, onTap: () => nav.goToFarmerPage(f.page)),
            )).toList());
        }),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.svg, required this.title, required this.desc,
      required this.onTap, this.fixedHeight = false});
  final String svg, title, desc;
  final VoidCallback onTap;
  final bool fixedHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min, children: [
          Container(width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
              child: Center(child: SvgPicture.asset(svg, width: 24, height: 24))),
          const SizedBox(height: AppSizes.itemPadding),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(desc, style: AppTextStyles.pageSubtitle.copyWith(fontSize: 13),
              maxLines: fixedHeight ? 2 : null,
              overflow: fixedHeight ? TextOverflow.ellipsis : null),
        ]),
      ),
    );
  }
}
