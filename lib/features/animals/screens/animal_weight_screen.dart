import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class AnimalWeightScreen extends StatefulWidget {
  const AnimalWeightScreen({super.key});
  @override
  State<AnimalWeightScreen> createState() => _AnimalWeightScreenState();
}

class _AnimalWeightScreenState extends State<AnimalWeightScreen> {
  XFile? _picked;
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _picked = img);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnimalProvider(),
      child: Consumer<AnimalProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Animal Weight Estimation', style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              const Text('Upload an animal image to estimate weight using computer vision.',
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: 'Animal Image',
                icon:  Icons.pets_rounded,
                analyzeLabel: 'Estimate Weight',
                isLoading:    prov.isLoading,
                pickedImage:  _picked,
                onPickImage:  _pick,
                onAnalyze: () { if (_picked != null) prov.estimate(_picked!); },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: 'Estimation Result', children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Estimated Weight', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(prov.result!.weightDisplay,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                  ),
                  SfInfoRow(label: 'Animal Type', value: prov.result!.animalType),
                  SfConfidenceBar(confidence: prov.result!.confidence),
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
