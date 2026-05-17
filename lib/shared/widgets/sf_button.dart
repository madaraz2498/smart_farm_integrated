import 'package:flutter/material.dart';

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

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = color ?? colorScheme.primary;
    final fg = colorScheme.onPrimary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
            : icon != null
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(label,
                        style: textTheme.labelLarge?.copyWith(color: fg)),
                  ])
                : Text(label, style: textTheme.labelLarge?.copyWith(color: fg)),
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

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = color ?? colorScheme.primary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: c.withValues(alpha: 0.05),
        ),
        child: icon != null
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label, style: textTheme.labelLarge?.copyWith(color: c)),
              ])
            : Text(label, style: textTheme.labelLarge?.copyWith(color: c)),
      ),
    );
  }
}
