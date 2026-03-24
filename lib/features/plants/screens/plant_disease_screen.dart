import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class PlantDiseaseScreen extends StatefulWidget {
  const PlantDiseaseScreen({super.key});
  @override
  State<PlantDiseaseScreen> createState() => _PlantDiseaseScreenState();
}

class _PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  XFile? _picked;
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _picked = img);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlantProvider(),
      child: Consumer<PlantProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Plant Disease Detection', style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              const Text('Upload a leaf image for AI-powered disease diagnosis.',
                  style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: 'Plant Image',
                icon:  Icons.eco_outlined,
                analyzeLabel: 'Analyze Plant',
                isLoading:    prov.isLoading,
                pickedImage:  _picked,
                onPickImage:  _pick,
                onAnalyze: () {
                  if (_picked != null) prov.analyze(_picked!);
                },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                SfResultCard(title: 'Analysis Result', children: [
                  SfInfoRow(
                    label: 'Prediction',
                    value: prov.result!.prediction,
                    valueColor: prov.result!.isHealthy ? AppColors.primary : AppColors.error,
                  ),
                  if (prov.result!.description != null)
                    SfInfoRow(label: 'Description', value: prov.result!.description!),
                  if (prov.result!.treatment != null)
                    SfInfoRow(label: 'Treatment', value: prov.result!.treatment!),
                  SfConfidenceBar(
                    confidence: prov.result!.confidence,
                    color: prov.result!.isHealthy ? AppColors.primary : AppColors.error,
                  ),
                ]),
              ],
              if (prov.status == ScanStatus.error && prov.error != null) ...[
                const SizedBox(height: 20),
                SfErrorBanner(prov.error!),
              ],
            ]),
          )),
        );
      }),
    );
  }
}
