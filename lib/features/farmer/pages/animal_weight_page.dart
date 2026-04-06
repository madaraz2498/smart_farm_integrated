import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/animal_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class AnimalWeightPage extends StatefulWidget {
  const AnimalWeightPage({super.key});
  @override
  State<AnimalWeightPage> createState() => _AnimalWeightPageState();
}

class _AnimalWeightPageState extends State<AnimalWeightPage> {
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
    return Consumer<AnimalProvider>(builder: (context, prov, _) {
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
              Text(l10n.nav_animal_weight, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.animal_weight_desc, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: l10n.animal_image,
                icon: Icons.pets_outlined,
                analyzeLabel: l10n.estimate_weight,
                isLoading: prov.isLoading,
                pickedImage: _picked,
                onPickImage: _pick,
                onAnalyze: () {
                  if (_picked != null) prov.estimate(_picked!);
                },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: l10n.estimation_result, children: [
                  SfInfoRow(
                      label: l10n.animal_type, value: prov.result!.animalType),
                  SfInfoRow(
                      label: l10n.estimated_weight,
                      value: prov.result!.weightDisplay,
                      valueColor: AppColors.primary),
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
