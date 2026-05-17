import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/farmer/models/scan_status.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/plant_models.dart';
import '../providers/plant_provider.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';
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
    return Consumer<PlantProvider>(builder: (context, prov, _) {
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
                    Text(l10n.nav_plant_disease,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(l10n.plant_disease_desc,
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    SfImagePickerCard(
                      title: l10n.nav_plant_disease,
                      icon: Icons.eco_outlined,
                      analyzeLabel: l10n.analyze_plant,
                      isLoading: prov.isLoading,
                      pickedImage: _picked,
                      onPickImage: _pick,
                      accentColor: colorScheme.primary, // Green for plant
                      onAnalyze: () {
                        if (_picked != null) {
                          prov.analyze(
                            _picked!,
                            lang: Localizations.localeOf(context).languageCode,
                          );
                        }
                      },
                    ),
                    if (prov.status == ScanStatus.result &&
                        prov.result != null) ...[
                      const SizedBox(height: 20),
                      _PlantResultCard(result: prov.result!, l10n: l10n),
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

class _PlantResultCard extends StatelessWidget {
  const _PlantResultCard({required this.result, required this.l10n});
  final PlantDiseaseResponse result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cropName = (result.cropType?.isNotEmpty ?? false)
        ? result.cropType!
        : _extractCrop(result.prediction);
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
            CircleAvatar(radius: 4, backgroundColor: colorScheme.error),
            const SizedBox(width: 8),
            Text(l10n.analysis_result,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 14),
        _statusBox(
          icon: Icons.eco_outlined,
          label: 'Crop',
          value: cropName,
          color: colorScheme.primary,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 10),
        _statusBox(
          icon: Icons.error_outline,
          label: 'Status',
          value: result.condition,
          color: result.isHealthy ? colorScheme.primary : colorScheme.error,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confidence',
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
                Text('${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: result.confidence.clamp(0, 1),
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        _detailsBox(
            icon: Icons.chat_bubble_outline,
            label: l10n.description,
            value: result.description ?? '--',
            colorScheme: colorScheme),
        const SizedBox(height: 10),
        _detailsBox(
            icon: Icons.health_and_safety_outlined,
            label: l10n.treatment,
            value: result.treatment ?? '--',
            colorScheme: colorScheme),
      ]),
    );
  }

  Widget _statusBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant)),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ]),
    );
  }

  Widget _detailsBox({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface)),
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
