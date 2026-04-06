import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/plant_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class PlantDiseasePage extends StatefulWidget {
  const PlantDiseasePage({super.key});
  @override
  State<PlantDiseasePage> createState() => _PlantDiseasePageState();
}

class _PlantDiseasePageState extends State<PlantDiseasePage> {
  XFile? _picked;
  final _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pick() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (img != null) setState(() => _picked = img);
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<PlantProvider>(builder: (context, prov, _) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() => _picked = null);
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
              Text(l10n.nav_plant_disease, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.plant_disease_desc, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: l10n.plant_image,
                icon: Icons.eco_outlined,
                analyzeLabel: l10n.analyze_plant,
                isLoading: prov.isLoading,
                pickedImage: _picked,
                onPickImage: _pick,
                onAnalyze: () {
                  if (_picked != null) prov.analyze(_picked!);
                },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: l10n.analysis_result, children: [
                  SfInfoRow(
                    label: l10n.prediction,
                    value: prov.result!.prediction,
                    valueColor: prov.result!.isHealthy
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                  SfInfoRow(
                      label: l10n.description,
                      value: prov.result!.description ?? ''),
                  SfInfoRow(
                      label: l10n.treatment,
                      value: prov.result!.treatment ?? ''),
                  SfConfidenceBar(confidence: prov.result!.confidence),
                ]),
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
