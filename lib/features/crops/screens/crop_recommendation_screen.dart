import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crop_models.dart';
import '../providers/crop_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});
  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _tempCtrl     = TextEditingController();
  final _humCtrl      = TextEditingController();
  final _rainCtrl     = TextEditingController();
  final _phCtrl       = TextEditingController();
  final _nCtrl        = TextEditingController();
  final _pCtrl        = TextEditingController();
  final _kCtrl        = TextEditingController();
  String _soilType    = 'Sandy';
  String? _validErr;

  static const _soilTypes = ['Sandy', 'Loamy', 'Clay', 'Silt', 'Peaty', 'Saline'];

  @override
  void dispose() {
    for (final c in [_tempCtrl, _humCtrl, _rainCtrl, _phCtrl, _nCtrl, _pCtrl, _kCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    if (_tempCtrl.text.isEmpty || _humCtrl.text.isEmpty || _rainCtrl.text.isEmpty) {
      setState(() => _validErr = 'Temperature, Humidity, and Rainfall are required.');
      return false;
    }
    setState(() => _validErr = null);
    return true;
  }

  void _submit(CropProvider prov) {
    if (!_validate()) return;
    prov.recommend(CropRecommendationRequest(
      temperature: double.tryParse(_tempCtrl.text) ?? 0,
      humidity:    double.tryParse(_humCtrl.text)  ?? 0,
      rainfall:    double.tryParse(_rainCtrl.text) ?? 0,
      soilType:    _soilType,
      ph:          double.tryParse(_phCtrl.text),
      nitrogen:    double.tryParse(_nCtrl.text),
      phosphorus:  double.tryParse(_pCtrl.text),
      potassium:   double.tryParse(_kCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CropProvider(),
      child: Consumer<CropProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Crop Recommendation', style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              const Text('Enter environmental data to get the best crop suggestion.',
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),

              // ── Form card ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  border:       Border.all(color: AppColors.cardBorder),
                  boxShadow:   [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
                        child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 20)),
                    const SizedBox(width: 12),
                    const Text('Environmental Parameters', style: AppTextStyles.cardTitle),
                  ]),
                  const SizedBox(height: 20),

                  // Required fields
                  SfTextField(controller: _tempCtrl, hint: '25',
                      label: 'Temperature (°C)', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  SfTextField(controller: _humCtrl, hint: '65',
                      label: 'Humidity (%)', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  SfTextField(controller: _rainCtrl, hint: '120',
                      label: 'Rainfall (mm)', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),

                  // Soil type dropdown
                  const Text('Soil Type', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color:        AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                      border:       Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:      _soilType,
                        isExpanded: true,
                        style:      const TextStyle(fontSize: 14, color: AppColors.textDark),
                        items: _soilTypes.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _soilType = v); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional NPK / pH
                  const Text('Optional Parameters', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: SfTextField(controller: _phCtrl, hint: '6.5', label: 'pH',
                        keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: SfTextField(controller: _nCtrl,  hint: '20',  label: 'Nitrogen (N)',
                        keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: SfTextField(controller: _pCtrl, hint: '30', label: 'Phosphorus (P)',
                        keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: SfTextField(controller: _kCtrl, hint: '25', label: 'Potassium (K)',
                        keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 20),

                  if (_validErr != null) ...[
                    SfErrorBanner(_validErr!), const SizedBox(height: 16),
                  ],

                  SfPrimaryButton(
                    label:     'Get Recommendation',
                    isLoading: prov.isLoading,
                    onPressed: () => _submit(prov),
                  ),
                ]),
              ),

              // ── Result ─────────────────────────────────────────────────────
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: 'Recommendation Result', children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:        AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                      border:       Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Recommended Crop',
                          style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(prov.result!.recommendedCrop,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                  ),
                  SfInfoRow(label: 'Expected Yield', value: prov.result!.yieldDisplay,
                      valueColor: AppColors.primary),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                      border:       Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(prov.result!.explanation,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSubtle, height: 1.5)),
                  ),
                ]),
              ],
              if (prov.status == ScanStatus.error && prov.error != null) ...[
                const SizedBox(height: 20), SfErrorBanner(prov.error!),
              ],
            ]),
          )),
        );
      }),
    );
  }
}
