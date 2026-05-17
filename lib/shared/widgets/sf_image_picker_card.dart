import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/core/theme/app_colors.dart';
import 'package:smart_farm/core/theme/app_dimensions.dart';
import 'sf_button.dart';

/// Reusable card used by Plant, Animal, and Fruit screens for image upload.
class SfImagePickerCard extends StatelessWidget {
  const SfImagePickerCard({
    super.key,
    required this.title,
    required this.icon,
    required this.analyzeLabel,
    required this.isLoading,
    this.pickedImage,
    required this.onPickImage,
    required this.onAnalyze,
    this.accentColor,
  });

  final String title, analyzeLabel;
  final IconData icon;
  final bool isLoading;
  final XFile? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onAnalyze;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveAccentColor = accentColor ?? colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.03), blurRadius: 12)
        ],
      ),
      child: Column(children: [
        // Icon chip with glow
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: effectiveAccentColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: effectiveAccentColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 32),

        // Upload Area (Dashed)
        GestureDetector(
          onTap: isLoading ? null : onPickImage,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: colorScheme.outline.withValues(alpha: 0.4),
              radius: 12,
            ),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pickedImage != null
                    ? Image.file(File(pickedImage!.path),
                        width: double.infinity, height: 180, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              size: 48),
                          const SizedBox(height: 12),
                          Text(
                            l10n.choose_image,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PNG, JPG, WEBP',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Buttons
        Row(children: [
          Expanded(
            child: SfOutlineButton(
                label: l10n.choose_image,
                icon: Icons.file_upload_outlined,
                onPressed: isLoading ? null : onPickImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SfPrimaryButton(
              label: analyzeLabel,
              onPressed: pickedImage != null && !isLoading ? onAnalyze : null,
              isLoading: isLoading,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius)));

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Result card template used by AI screens.
class SfResultCard extends StatelessWidget {
  const SfResultCard({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}

/// Info row inside a result card (Label: Value).
class SfInfoRow extends StatelessWidget {
  const SfInfoRow(
      {super.key, required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMid),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w400)),
            TextSpan(
                text: value,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

/// Confidence bar inside a result card.
class SfConfidenceBar extends StatelessWidget {
  const SfConfidenceBar({super.key, required this.confidence, this.color});
  final double confidence;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMid),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style:
                textTheme.titleSmall?.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation(color ?? colorScheme.primary),
          ),
        ),
      ]),
    );
  }
}

/// Standard error banner.
class SfErrorBanner extends StatelessWidget {
  const SfErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMid),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 14, color: AppColors.error))),
      ]),
    );
  }
}
