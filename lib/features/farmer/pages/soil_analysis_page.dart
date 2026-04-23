import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/soil_models.dart';
import '../providers/soil_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class SoilAnalysisPage extends StatefulWidget {
  const SoilAnalysisPage({super.key});
  @override
  State<SoilAnalysisPage> createState() => _SoilAnalysisPageState();
}

class _SoilAnalysisPageState extends State<SoilAnalysisPage> {
  final _phCtrl = TextEditingController();
  final _moistCtrl = TextEditingController();
  final _nCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  String? _validErr;

  @override
  void dispose() {
    for (final c in [_phCtrl, _moistCtrl, _nCtrl, _pCtrl, _kCtrl]) c.dispose();
    super.dispose();
  }

  void _submit(SoilProvider prov, AppLocalizations l10n) {
    if (_phCtrl.text.isEmpty) {
      setState(() => _validErr = l10n.field_required);
      return;
    }
    setState(() => _validErr = null);
    prov.analyze(SoilAnalysisRequest(
      ph: double.tryParse(_phCtrl.text) ?? 7.0,
      moisture: double.tryParse(_moistCtrl.text),
      nitrogen: double.tryParse(_nCtrl.text),
      phosphorus: double.tryParse(_pCtrl.text),
      potassium: double.tryParse(_kCtrl.text),
    ), lang: Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SoilProvider>(builder: (context, prov, _) {
      final hPadding = Responsive.responsivePadding(context);
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            for (final c in [_phCtrl, _moistCtrl, _nCtrl, _pCtrl, _kCtrl]) {
              c.clear();
            }
            setState(() => _validErr = null);
            prov.reset();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 32),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(l10n.nav_soil_analysis, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.soil_analyze_button, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),

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
                            child: const Icon(Icons.layers_outlined,
                                color: AppColors.primary, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.soil_npk_levels,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      SfTextField(
                          controller: _phCtrl,
                          hint: '6.5',
                          label: l10n.soil_ph,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 14),
                      SfTextField(
                          controller: _moistCtrl,
                          hint: '48',
                          label: l10n.soil_moisture,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: SfTextField(
                                controller: _nCtrl,
                                hint: '20',
                                label: l10n.soil_nitrogen,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: SfTextField(
                                controller: _pCtrl,
                                hint: '30',
                                label: l10n.soil_phosphorus,
                                keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 14),
                      SfTextField(
                          controller: _kCtrl,
                          hint: '25',
                          label: l10n.soil_potassium,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      if (_validErr != null) ...[
                        SfErrorBanner(_validErr!),
                        const SizedBox(height: 16)
                      ],
                      SfPrimaryButton(
                          label: l10n.soil_analyze_button,
                          isLoading: prov.isLoading,
                          onPressed: () => _submit(prov, l10n)),
                    ]),
              ),
              // ... rest of the build ...

              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _ResultTile(
                          label: l10n.soil_type,
                          value: _localizedSoilType(prov.result!.soilType, l10n),
                          color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _ResultTile(
                          label: l10n.soil_fertility,
                          value: _localizedFertility(prov.result!.fertilityLevel, l10n),
                          color: _fertilityColor(prov.result!.fertilityLevel))),
                ]),
                if (prov.result!.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SfResultCard(title: l10n.soil_recommendations, children: [
                    ...prov.result!.recommendations.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(r,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textDark))),
                              ]),
                        )),
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
          ),
      );
    });
  }
}

Color _fertilityColor(String f) {
  final val = f.trim().toLowerCase();
  switch (val) {
    case 'high':
    case 'عالية':
      return AppColors.primary;
    case 'medium':
    case 'moderate':
    case 'متوسطة':
      return AppColors.warning;
    default:
      return AppColors.error;
  }
}

String _localizedSoilType(String value, AppLocalizations l10n) {
  final v = value.trim().toLowerCase();
  switch (v) {
    case 'sandy':
    case 'رملية':
      return l10n.soil_sandy;
    case 'loamy':
    case 'طميية':
      return l10n.soil_loamy;
    case 'clay':
    case 'طينية':
      return l10n.soil_clay;
    case 'silty':
    case 'غرينية':
      return l10n.soil_silty;
    default:
      return value;
  }
}

String _localizedFertility(String value, AppLocalizations l10n) {
  final v = value.trim().toLowerCase();
  if (v == 'high' || v == 'عالية') return l10n.soil_fertility_high;
  if (v == 'medium' || v == 'moderate' || v == 'متوسطة') return l10n.soil_fertility_medium;
  if (v == 'low' || v == 'منخفضة') return l10n.soil_fertility_low;
  return value;
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMid),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color))),
        ),
      ]),
    );
  }
}
