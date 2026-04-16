import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/crop_models.dart';
import '../providers/crop_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class CropRecommendationPage extends StatefulWidget {
  const CropRecommendationPage({super.key});
  @override
  State<CropRecommendationPage> createState() => _CropRecommendationPageState();
}

class _CropRecommendationPageState extends State<CropRecommendationPage> {
  final _cityCtrl = TextEditingController();
  String? _soilType;
  String? _validErr;

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    if (_cityCtrl.text.trim().isEmpty) {
      setState(() => _validErr = l10n.field_required);
      return false;
    }
    setState(() => _validErr = null);
    return true;
  }

  void _submit(CropProvider prov, AppLocalizations l10n) {
    if (!_validate(l10n)) return;
    prov.recommend(CropRecommendationRequest(
      cityName: _cityCtrl.text.trim(),
      soilType: _soilType ?? 'Sandy',
    ), lang: Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _soilType ??= 'Sandy';

    final soilTypes = [
      {'value': 'Sandy', 'label': l10n.soil_sandy},
      {'value': 'Loamy', 'label': l10n.soil_loamy},
      {'value': 'Clay', 'label': l10n.soil_clay},
      {'value': 'Silty', 'label': l10n.soil_silty},
    ];

    return Consumer<CropProvider>(builder: (context, prov, _) {
      return RefreshIndicator(
        onRefresh: () async {
          _cityCtrl.clear();
          setState(() {
            _soilType = 'Sandy';
            _validErr = null;
          });
          prov.reset();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.nav_crop_recommendation,
                  style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.soil_get_recommendation,
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),

              // ── Form card ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                                color: AppColors.primarySurface,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMid)),
                            child: const Icon(Icons.eco_outlined,
                                color: AppColors.primary, size: 20)),
                        const SizedBox(width: 12),
                        Text(l10n.crop_input_parameters,
                            style: AppTextStyles.cardTitle),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SfTextField(
                              controller: _cityCtrl,
                              hint: l10n.crop_city_hint,
                              label: l10n.crop_city_name,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.crop_soil_type, style: AppTextStyles.label),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _soilType,
                                      isExpanded: true,
                                      items: soilTypes
                                          .map((type) => DropdownMenuItem(
                                                value: type['value'],
                                                child: Text(type['label']!),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => _soilType = v),
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
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: l10n.crop_recommendation_result, children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 520;
                      final cards = [
                        _CropPickCard(
                          title: l10n.crop_primary_crop,
                          crop: prov.result!.primaryCrop ?? prov.result!.recommendedCrop,
                          color: const Color(0xFFF59E0B),
                        ),
                        _CropPickCard(
                          title: l10n.crop_secondary_crop,
                          crop: prov.result!.secondaryCrop ?? '--',
                          color: const Color(0xFF10B981),
                        ),
                        _CropPickCard(
                          title: l10n.crop_third_option,
                          crop: prov.result!.thirdOption ?? '--',
                          color: const Color(0xFF3B82F6),
                        ),
                      ];

                      if (isNarrow) {
                        return Column(
                          children: cards
                              .map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: c,
                                  ))
                              .toList(),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[2]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.crop_expert_advice,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (prov.result!.expertAdvice?.isNotEmpty ?? false)
                              ? prov.result!.expertAdvice!
                              : prov.result!.explanation,
                          style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ]),

                if ((prov.result!.generalStatus?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _normalizeGeneralStatus(prov.result!.generalStatus!, l10n),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (prov.result!.dailyGuide.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SfResultCard(title: l10n.crop_daily_expert_guide, children: [
                    ...prov.result!.dailyGuide.take(6).map(
                          (d) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.date, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                const SizedBox(height: 6),
                                Text('${l10n.crop_weather_label}: ${d.weather}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                Text('${l10n.crop_irrigation_advice_label}: ${d.irrigationAdvice}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                Text('${l10n.crop_fertilizer_advice_label}: ${d.fertilizerAdvice}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                Text('${l10n.crop_disease_alert_label}: ${d.diseaseAlert}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                  ]),
                ],
              ],
              if (prov.status == ScanStatus.error && prov.error != null) ...[
                const SizedBox(height: 20),
                SfErrorBanner(prov.error!),
              ],
            ]),
          )),
        ),
      );
    });
  }
}

class _CropPickCard extends StatelessWidget {
  const _CropPickCard({
    required this.title,
    required this.crop,
    required this.color,
  });

  final String title;
  final String crop;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grass_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(crop, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
  if (normalized == 'safe' || normalized == 'stable') return l10n.crop_status_safe;
  if (normalized == 'warning' || normalized == 'alert') return l10n.crop_status_warning;
  if (normalized.isEmpty) return l10n.crop_status_unknown;
  return cleaned;
}
