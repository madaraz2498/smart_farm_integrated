import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/farmer/models/scan_status.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/animal_models.dart';
import '../providers/animal_provider.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';
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
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.choose_image,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: Theme.of(ctx).colorScheme.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined,
                  color: Theme.of(ctx).colorScheme.primary),
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
      final img = await _picker.pickImage(source: source, imageQuality: 85);
      if (img != null) setState(() => _picked = img);
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hPadding = Responsive.responsivePadding(context);
    return Consumer<AnimalProvider>(builder: (context, prov, _) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _picked = null);
            prov.reset();
          },
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 32),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nav_animal_weight,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(l10n.animal_weight_desc,
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    _AnimalTipCard(
                      text: l10n.localeName == 'ar'
                          ? '📸 للحصول على نتيجة أدق: صوّر الحيوان من الجانب وهو واقف على أرض مستوية.'
                          : '📸 Tip for accurate results: Photograph the animal from the side while standing on flat ground.',
                    ),
                    const SizedBox(height: 12),
                    SfImagePickerCard(
                      title: l10n.nav_animal_weight,
                      icon: Icons.pets_outlined,
                      analyzeLabel: l10n.estimate_weight,
                      isLoading: prov.isLoading,
                      pickedImage: _picked,
                      onPickImage: _pick,
                      accentColor: colorScheme.primary, // Unified Green
                      onAnalyze: () {
                        if (_picked != null) {
                          prov.estimate(
                            _picked!,
                            lang: Localizations.localeOf(context).languageCode,
                          );
                        }
                      },
                    ),
                    if (prov.status == ScanStatus.result &&
                        prov.result != null) ...[
                      const SizedBox(height: 20),
                      _AnimalResultCard(result: prov.result!, l10n: l10n),
                    ],
                    if (prov.status == ScanStatus.error &&
                        prov.error != null) ...[
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: colorScheme.onErrorContainer)),
    );
  }
}

class _AnimalResultCard extends StatelessWidget {
  const _AnimalResultCard({required this.result, required this.l10n});
  final AnimalWeightResponse result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.estimation_result,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.estimated_weight,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant)),
                Text(result.weightDisplay,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary)),
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
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMid),
            border: Border.all(color: colorScheme.outline),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
              children: [
                TextSpan(
                  text: '${l10n.animal_type}: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: result.animalType,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface),
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
