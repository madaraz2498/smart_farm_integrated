import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/farmer/models/scan_status.dart';
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
    return Consumer<FruitProvider>(builder: (context, prov, _) {
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
                  if (_picked != null) {
                    prov.analyze(
                      _picked!,
                      lang: Localizations.localeOf(context).languageCode,
                    );
                  }
                },
              ),
              if (prov.status == ScanStatus.result && prov.result != null) ...[
                const SizedBox(height: 20),
                _FruitResultCard(result: prov.result!, l10n: l10n),
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

class _FruitResultCard extends StatelessWidget {
  const _FruitResultCard({required this.result, required this.l10n});
  final dynamic result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final gradeColor = result.grade == 'A'
        ? AppColors.primary
        : result.grade == 'B'
            ? AppColors.warning
            : AppColors.error;

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
            Text('Analysis Results', style: AppTextStyles.cardTitle),
          ],
        ),
        const SizedBox(height: 14),
        _metricBox(
          icon: Icons.star_border_rounded,
          label: l10n.quality_grade,
          value: _gradeText(result.grade),
          color: gradeColor,
        ),
        const SizedBox(height: 10),
        _metricBox(
          icon: Icons.apple_outlined,
          label: l10n.ripeness,
          value: result.ripeness,
          color: AppColors.primary,
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
                const Text(
                  'Confidence',
                  style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(result.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
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
        if (_shouldShowDefects(result.defects)) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4),
                children: [
                  TextSpan(
                    text: '${l10n.defects}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: result.defects),
                ],
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _metricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
            ]),
          ),
        ],
      ),
    );
  }

  String _gradeText(String grade) {
    final g = grade.trim();
    if (g.toLowerCase().startsWith('grade')) return g;
    return 'Grade $g';
  }

  bool _shouldShowDefects(String defects) {
    final value = defects.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == 'none detected' || value == 'none' || value == 'no defects') {
      return false;
    }
    return true;
  }
}
