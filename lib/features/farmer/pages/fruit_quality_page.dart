import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/fruit_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_image_picker_card.dart';

class FruitQualityPage extends StatefulWidget {
  const FruitQualityPage({super.key});
  @override
  State<FruitQualityPage> createState() => _FruitQualityPageState();
}

class _FruitQualityPageState extends State<FruitQualityPage> {
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
    return Consumer<FruitProvider>(builder: (context, prov, _) {
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
              Text(l10n.nav_fruit_quality, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.fruit_quality_desc, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              SfImagePickerCard(
                title: l10n.fruit_image,
                icon: Icons.apple_outlined,
                analyzeLabel: l10n.analyze_fruit,
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
                      label: l10n.quality_grade,
                      value: 'Grade ${prov.result!.grade}',
                      valueColor: prov.result!.grade == 'A'
                          ? AppColors.primary
                          : prov.result!.grade == 'B'
                              ? AppColors.warning
                              : AppColors.error),
                  SfInfoRow(
                      label: l10n.grade_label, value: prov.result!.gradeLabel),
                  SfInfoRow(label: l10n.ripeness, value: prov.result!.ripeness),
                  SfInfoRow(label: l10n.defects, value: prov.result!.defects),
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
