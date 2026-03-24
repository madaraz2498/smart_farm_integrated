import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/soil_models.dart';
import '../providers/soil_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});
  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  final _phCtrl   = TextEditingController();
  final _moistCtrl = TextEditingController();
  final _nCtrl    = TextEditingController();
  final _pCtrl    = TextEditingController();
  final _kCtrl    = TextEditingController();
  String? _validErr;

  @override
  void dispose() {
    for (final c in [_phCtrl, _moistCtrl, _nCtrl, _pCtrl, _kCtrl]) c.dispose();
    super.dispose();
  }

  void _submit(SoilProvider prov) {
    if (_phCtrl.text.isEmpty) {
      setState(() => _validErr = 'Soil pH is required.');
      return;
    }
    setState(() => _validErr = null);
    prov.analyze(SoilAnalysisRequest(
      ph:         double.tryParse(_phCtrl.text)   ?? 7.0,
      moisture:   double.tryParse(_moistCtrl.text),
      nitrogen:   double.tryParse(_nCtrl.text),
      phosphorus: double.tryParse(_pCtrl.text),
      potassium:  double.tryParse(_kCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilProvider(),
      child: Consumer<SoilProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Soil Type Analysis', style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              const Text('Enter soil properties to identify type and fertility level.',
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),

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
                        child: const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20)),
                    const SizedBox(width: 12),
                    const Text('Soil Properties', style: AppTextStyles.cardTitle),
                  ]),
                  const SizedBox(height: 20),
                  SfTextField(controller: _phCtrl, hint: '6.5',
                      label: 'Soil pH *', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  SfTextField(controller: _moistCtrl, hint: '48',
                      label: 'Moisture Level (%)', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: SfTextField(controller: _nCtrl, hint: '20',
                        label: 'Nitrogen (N)', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: SfTextField(controller: _pCtrl, hint: '30',
                        label: 'Phosphorus (P)', keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 14),
                  SfTextField(controller: _kCtrl, hint: '25',
                      label: 'Potassium (K)', keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  if (_validErr != null) ...[SfErrorBanner(_validErr!), const SizedBox(height: 16)],
                  SfPrimaryButton(
                      label: 'Analyze Soil Properties',
                      isLoading: prov.isLoading,
                      onPressed: () => _submit(prov)),
                ]),
              ),

              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _ResultTile(
                      label: 'Soil Type', value: prov.result!.soilType, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _ResultTile(
                      label: 'Fertility',
                      value: prov.result!.fertilityLevel,
                      color: _fertilityColor(prov.result!.fertilityLevel))),
                ]),
                if (prov.result!.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SfResultCard(title: 'Recommendations', children: [
                    ...prov.result!.recommendations.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13, color: AppColors.textMid))),
                      ]),
                    )),
                  ]),
                ],
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

  Color _fertilityColor(String f) {
    switch (f.toLowerCase()) {
      case 'high':     return AppColors.primary;
      case 'moderate': return AppColors.warning;
      default:         return AppColors.error;
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border:       Border.all(color: AppColors.cardBorder),
        boxShadow:   [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMid),
            border:       Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(child: Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
        ),
      ]),
    );
  }
}
