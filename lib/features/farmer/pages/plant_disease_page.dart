import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/plant_models.dart';
import '../providers/plant_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.choose_image,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _isPicking = true);
    try {
      final img = await _picker.pickImage(
          source: source, imageQuality: 85);
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
              _UploadCard(
                pickedImage: _picked,
                isLoading: prov.isLoading,
                onPick: _pick,
                onAnalyze: () {
                  if (_picked != null) prov.analyze(_picked!);
                },
                chooseLabel: l10n.choose_image,
                analyzeLabel: l10n.analyze_plant,
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                _PlantResultCard(result: prov.result!, l10n: l10n),
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

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.pickedImage,
    required this.isLoading,
    required this.onPick,
    required this.onAnalyze,
    required this.chooseLabel,
    required this.analyzeLabel,
  });

  final XFile? pickedImage;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onAnalyze;
  final String chooseLabel;
  final String analyzeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)],
            ),
            child: const Icon(Icons.eco_outlined, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(pickedImage!.path),
                        width: 170,
                        height: 95,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: AppColors.textDisabled, size: 44),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SfOutlineButton(label: chooseLabel, onPressed: isLoading ? null : onPick)),
              const SizedBox(width: 8),
              Expanded(
                child: SfPrimaryButton(
                  label: analyzeLabel,
                  onPressed: pickedImage != null && !isLoading ? onAnalyze : null,
                  isLoading: isLoading,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _PlantResultCard extends StatelessWidget {
  const _PlantResultCard({required this.result, required this.l10n});
  final PlantDiseaseResponse result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cropName = (result.cropType?.isNotEmpty ?? false)
        ? result.cropType!
        : _extractCrop(result.prediction);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const CircleAvatar(radius: 4, backgroundColor: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.analysis_result, style: AppTextStyles.cardTitle),
          ],
        ),
        const SizedBox(height: 14),
        _statusBox(
          icon: Icons.eco_outlined,
          label: 'Crop',
          value: cropName,
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _statusBox(
          icon: Icons.error_outline,
          label: 'Status',
          value: result.prediction,
          color: result.isHealthy ? AppColors.primary : AppColors.error,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Confidence', style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
                Text('${(result.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: result.confidence.clamp(0, 1),
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        _detailsBox(icon: Icons.chat_bubble_outline, label: l10n.description, value: result.description ?? '--'),
        const SizedBox(height: 10),
        _detailsBox(icon: Icons.health_and_safety_outlined, label: l10n.treatment, value: result.treatment ?? '--'),
      ]),
    );
  }

  Widget _statusBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ]),
    );
  }

  Widget _detailsBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.textSubtle),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textSubtle, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  String _extractCrop(String prediction) {
    final parts = prediction.split(RegExp(r'[\s\-\(]+'));
    if (parts.isEmpty) return prediction;
    return parts.first;
  }
}
