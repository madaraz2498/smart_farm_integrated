import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/farmer/models/scan_status.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/crop_models.dart';
import '../providers/crop_provider.dart';
import 'package:smart_farm/core/theme/app_colors.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class CropRecommendationPage extends StatefulWidget {
  const CropRecommendationPage({super.key});
  @override
  State<CropRecommendationPage> createState() => _CropRecommendationPageState();
}

class _CropRecommendationPageState extends State<CropRecommendationPage> {
  String? _cityName;
  String? _soilType;
  String? _validErr;

  final List<String> _egyptGovernorates = [
    'Cairo',
    'Giza',
    'Alexandria',
    'Dakahlia',
    'Red Sea',
    'Beheira',
    'Fayoum',
    'Gharbiya',
    'Ismailia',
    'Menofia',
    'Minya',
    'Qalyubia',
    'New Valley',
    'Sharqia',
    'Suez',
    'Aswan',
    'Assiut',
    'Beni Suef',
    'Port Said',
    'Damietta',
    'South Sinai',
    'Kafr El Sheikh',
    'Matrouh',
    'Luxor',
    'Qena',
    'North Sinai',
    'Sohag',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    if (_cityName == null || _cityName!.isEmpty) {
      setState(() => _validErr = l10n.field_required);
      return false;
    }
    setState(() => _validErr = null);
    return true;
  }

  void _submit(CropProvider prov, AppLocalizations l10n) {
    if (!_validate(l10n)) return;
    prov.recommend(
        CropRecommendationRequest(
          cityName: _cityName!,
          soilType: _soilType ?? 'Sandy',
        ),
        lang: Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    _soilType ??= 'Sandy';
    final hPadding = Responsive.responsivePadding(context);

    final soilTypes = [
      {'value': 'Sandy', 'label': l10n.soil_sandy},
      {'value': 'Loamy', 'label': l10n.soil_loamy},
      {'value': 'Clay', 'label': l10n.soil_clay},
      {'value': 'Silty', 'label': l10n.soil_silty},
    ];

    return Consumer<CropProvider>(builder: (context, prov, _) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _cityName = null;
              _soilType = 'Sandy';
              _validErr = null;
            });
            prov.reset();
          },
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 32),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nav_crop_recommendation,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(l10n.soil_get_recommendation,
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),

                    // ── Form card ──────────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: colorScheme.outline),
                        boxShadow: [
                          BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 6)
                        ],
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMid)),
                                  child: Icon(Icons.eco_outlined,
                                      color: colorScheme.primary, size: 20)),
                              const SizedBox(width: 12),
                              Text(l10n.crop_input_parameters,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface)),
                            ]),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.crop_city_name,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface)),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusMid),
                                          border: Border.all(
                                              color: colorScheme.outline),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _cityName,
                                            hint: Text(l10n.crop_city_hint,
                                                style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 14)),
                                            isExpanded: true,
                                            items: _egyptGovernorates
                                                .map((city) => DropdownMenuItem(
                                                      value: city,
                                                      child: Text(city,
                                                          style: TextStyle(
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ))
                                                .toList(),
                                            onChanged: (v) =>
                                                setState(() => _cityName = v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.crop_soil_type,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface)),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusMid),
                                          border: Border.all(
                                              color: colorScheme.outline),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _soilType,
                                            isExpanded: true,
                                            items: soilTypes
                                                .map((type) => DropdownMenuItem(
                                                      value: type['value'],
                                                      child: Text(
                                                          type['label']!,
                                                          style: TextStyle(
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ))
                                                .toList(),
                                            onChanged: (v) =>
                                                setState(() => _soilType = v),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_validErr != null) ...[
                              SfErrorBanner(_validErr!),
                              const SizedBox(height: 16)
                            ],
                            SfPrimaryButton(
                                label: l10n.soil_get_recommendation,
                                isLoading: prov.isLoading,
                                onPressed: () => _submit(prov, l10n)),
                          ]),
                    ),

                    // ── Result ─────────────────────────────────────────────────────
                    if (prov.status == ScanStatus.result &&
                        prov.result != null) ...[
                      const SizedBox(height: 20),
                      SfResultCard(
                          title: '', // Custom title with dot below
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.crop_recommendation_result,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // ── Categories (Web-style Rows) ──────────────────────────
                            if (prov.result!.vegetables.isNotEmpty ||
                                prov.result!.fruits.isNotEmpty ||
                                prov.result!.fieldCrops.isNotEmpty) ...[
                              if (prov.result!.vegetables.isNotEmpty)
                                _CategoryRow(
                                  icon: Icons.eco_rounded,
                                  iconColor: colorScheme.primary,
                                  title: l10n.crop_vegetables,
                                  crops: prov.result!.vegetables,
                                ),
                              if (prov.result!.fruits.isNotEmpty)
                                _CategoryRow(
                                  icon: Icons.apple_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  title: l10n.crop_fruits,
                                  crops: prov.result!.fruits,
                                ),
                              if (prov.result!.fieldCrops.isNotEmpty)
                                _CategoryRow(
                                  icon: Icons.grass_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  title: l10n.crop_field_crops,
                                  crops: prov.result!.fieldCrops,
                                ),
                            ] else ...[
                              // ── 3 Main Recommendations (List Style) ────────────────
                              _RecommendationRow(
                                icon: Icons.looks_one_rounded,
                                color: const Color(0xFFF59E0B),
                                title: l10n.crop_primary_crop,
                                value: prov.result!.primaryCrop ??
                                    prov.result!.recommendedCrop,
                              ),
                              _RecommendationRow(
                                icon: Icons.looks_two_rounded,
                                color: AppColors.primary,
                                title: l10n.crop_secondary_crop,
                                value: prov.result!.secondaryCrop ?? '--',
                              ),
                              _RecommendationRow(
                                icon: Icons.looks_3_rounded,
                                color: const Color(0xFF3B82F6),
                                title: l10n.crop_third_option,
                                value: prov.result!.thirdOption ?? '--',
                              ),
                            ],
                            const SizedBox(height: 16),
                            // ── Expert Advice Section ───────────────────────────────
                            if (prov.result!.expertAdvice != null &&
                                prov.result!.expertAdvice!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMid),
                                  border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.crop_expert_advice.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      prov.result!.expertAdvice!,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                          height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (prov.result!.explanation.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMid),
                                  border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  prov.result!.explanation,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                      height: 1.6),
                                ),
                              ),
                            ],
                          ]),
                      if ((prov.result!.generalStatus?.isNotEmpty ??
                          false)) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusCard),
                            border: Border.all(color: colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 18, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _normalizeGeneralStatus(
                                      prov.result!.generalStatus!, l10n),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (prov.result!.dailyGuide.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SfResultCard(
                            title: l10n.crop_daily_expert_guide,
                            children: [
                              ...prov.result!.dailyGuide.take(6).map(
                                    (d) => Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusMid),
                                        border: Border.all(
                                            color: colorScheme.outline),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(d.date,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      colorScheme.onSurface)),
                                          const SizedBox(height: 6),
                                          Text(
                                              '${l10n.crop_weather_label}: ${d.weather}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      colorScheme.onSurface)),
                                          Text(
                                              '${l10n.crop_irrigation_advice_label}: ${d.irrigationAdvice}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      colorScheme.onSurface)),
                                          Text(
                                              '${l10n.crop_fertilizer_advice_label}: ${d.fertilizerAdvice}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      colorScheme.onSurface)),
                                          Text(
                                              '${l10n.crop_disease_alert_label}: ${d.diseaseAlert}',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      colorScheme.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ),
                            ]),
                      ],
                    ],
                    if (prov.status == ScanStatus.error &&
                        prov.error != null) ...[
                      const SizedBox(height: 20),
                      SfErrorBanner(prov.error!),
                    ],
                  ]),
            )),
          ),
        ),
      );
    });
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMid),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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

String _normalizeGeneralStatus(String text, AppLocalizations l10n) {
  var cleaned = text.trim();
  if (cleaned.toLowerCase().startsWith('general status')) {
    cleaned = cleaned.substring('general status'.length).trim();
  }
  cleaned = cleaned.replaceAll(':', '').trim();
  final normalized = cleaned.toLowerCase();
  if (normalized == 'safe' || normalized == 'stable') {
    return l10n.crop_status_safe;
  }
  if (normalized == 'warning' || normalized == 'alert') {
    return l10n.crop_status_warning;
  }
  if (normalized.isEmpty) return l10n.crop_status_unknown;
  return cleaned;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.crops,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> crops;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: crops.map((crop) {
                // Approximate 3 items per row on mobile
                final itemWidth = (constraints.maxWidth - 20) / 3;
                return SizedBox(
                  width: itemWidth,
                  child: _CropChip(name: crop),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  const _CropChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
