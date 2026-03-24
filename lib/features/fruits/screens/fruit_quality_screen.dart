import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/fruit_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class FruitQualityScreen extends StatefulWidget {
  const FruitQualityScreen({super.key});
  @override
  State<FruitQualityScreen> createState() => _FruitQualityScreenState();
}

class _FruitQualityScreenState extends State<FruitQualityScreen> {
  XFile? _picked;
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _picked = img);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FruitProvider(),
      child: Consumer<FruitProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fruit Quality Analysis', style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              const Text('Upload a fruit image for AI-powered quality grading.',
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: 'Fruit Image', icon: Icons.apple_outlined,
                analyzeLabel: 'Analyze Fruit', isLoading: prov.isLoading,
                pickedImage: _picked, onPickImage: _pick,
                onAnalyze: () { if (_picked != null) prov.analyze(_picked!); },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: 'Analysis Results', children: [
                  SfInfoRow(label: 'Quality Grade', value: 'Grade ${prov.result!.grade}',
                      valueColor: prov.result!.grade == 'A' ? AppColors.primary
                          : prov.result!.grade == 'B' ? AppColors.warning : AppColors.error),
                  SfInfoRow(label: 'Grade Label',   value: prov.result!.gradeLabel),
                  SfInfoRow(label: 'Ripeness',       value: prov.result!.ripeness),
                  SfInfoRow(label: 'Defects',        value: prov.result!.defects),
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
