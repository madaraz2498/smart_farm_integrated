import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/animal_models.dart';
import '../providers/animal_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
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
    final hPadding = Responsive.responsivePadding(context);
    return Consumer<AnimalProvider>(builder: (context, prov, _) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _picked = null);
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
              Text(l10n.nav_animal_weight, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.animal_weight_desc, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 20),
              _AnimalTipCard(
                text: l10n.localeName == 'ar'
                    ? '📸 للحصول على نتيجة أدق: صوّر الحيوان من الجانب وهو واقف على أرض مستوية.'
                    : '📸 Tip for accurate results: Photograph the animal from the side while standing on flat ground.',
              ),
              const SizedBox(height: 12),
              _AnimalUploadCard(
                pickedImage: _picked,
                isLoading: prov.isLoading,
                chooseLabel: l10n.choose_image,
                analyzeLabel: l10n.estimate_weight,
                onPick: _pick,
                onAnalyze: () {
                  if (_picked != null) {
                    prov.estimate(
                      _picked!,
                      lang: Localizations.localeOf(context).languageCode,
                    );
                  }
                },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                _AnimalResultCard(result: prov.result!, l10n: l10n),
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

class _AnimalTipCard extends StatelessWidget {
  const _AnimalTipCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
    );
  }
}

class _AnimalUploadCard extends StatelessWidget {
  const _AnimalUploadCard({
    required this.pickedImage,
    required this.isLoading,
    required this.chooseLabel,
    required this.analyzeLabel,
    required this.onPick,
    required this.onAnalyze,
  });

  final XFile? pickedImage;
  final bool isLoading;
  final String chooseLabel;
  final String analyzeLabel;
  final VoidCallback onPick;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF4F66F2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF4F66F2).withOpacity(0.35), blurRadius: 12)],
            ),
            child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(pickedImage!.path),
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image_outlined, size: 48, color: AppColors.textDisabled),
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
          ),
        ],
      ),
    );
  }
}

class _AnimalResultCard extends StatelessWidget {
  const _AnimalResultCard({required this.result, required this.l10n});
  final AnimalWeightResponse result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
            const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.estimation_result, style: AppTextStyles.cardTitle),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.estimated_weight, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                Text(result.weightDisplay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMid),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              children: [
                TextSpan(
                  text: '${l10n.animal_type}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: result.animalType,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),
        SfConfidenceBar(confidence: result.confidence),
      ]),
    );
  }
}
