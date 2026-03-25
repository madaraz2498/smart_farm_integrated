import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-width primary button with loading state.
class SfPrimaryButton extends StatelessWidget {
  const SfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
    this.height,
  });

  final String     label;
  final VoidCallback? onPressed;
  final bool       isLoading;
  final IconData?  icon;
  final Color?     color;
  final double?    width;
  final double?    height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: (color ?? AppColors.primary).withValues(alpha: 0.6),
          padding: EdgeInsets.symmetric(vertical: height != null ? 0 : 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : icon != null
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ])
                : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Full-width outlined button.
class SfOutlineButton extends StatelessWidget {
  const SfOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    this.width,
    this.height,
  });

  final String     label;
  final VoidCallback? onPressed;
  final Color?     color;
  final IconData?  icon;
  final double?    width;
  final double?    height;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side:    BorderSide(color: c),
          padding: EdgeInsets.symmetric(vertical: height != null ? 0 : 14),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          backgroundColor: c.withValues(alpha: 0.05),
        ),
        child: icon != null
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ])
            : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
