import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
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
  });

  final String     title, analyzeLabel;
  final IconData   icon;
  final bool       isLoading;
  final XFile?     pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border:       Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(children: [
        // Icon chip
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 16),

        // Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMid),
          child: pickedImage != null
              ? Image.file(File(pickedImage!.path),
                  width: double.infinity, height: 190, fit: BoxFit.cover)
              : Container(width: double.infinity, height: 190, color: AppColors.background,
                  child: const Icon(Icons.image_outlined, color: AppColors.textDisabled, size: 52)),
        ),
        const SizedBox(height: 20),

        // Buttons
        Row(children: [
          Expanded(
            child: SfOutlineButton(label: l10n.choose_image, onPressed: isLoading ? null : onPickImage),
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

/// Result card template used by AI screens.
class SfResultCard extends StatelessWidget {
  const SfResultCard({super.key, required this.title, required this.children});
  final String      title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border:       Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}

/// Info row inside a result card (Label: Value).
class SfInfoRow extends StatelessWidget {
  const SfInfoRow({super.key, required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
        border:       Border.all(color: AppColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: TextStyle(color: valueColor ?? AppColors.textDark)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
        border:       Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: LinearProgressIndicator(
            value:           confidence,
            minHeight:       8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor:      AlwaysStoppedAnimation(color ?? AppColors.primary),
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
        color:        const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppSizes.radiusMid),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.error))),
      ]),
    );
  }
}
