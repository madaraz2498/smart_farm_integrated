import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SfTextField extends StatelessWidget {
  const SfTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.cardBorder,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onChanged: onChanged,
            enabled: enabled,
            readOnly: readOnly,
            style: TextStyle(
                fontSize: 14,
                color: enabled ? AppColors.textDark : AppColors.textDisabled),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: AppColors.textDisabled, fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.error_outline, size: 13, color: AppColors.error),
            const SizedBox(width: 4),
            Text(errorText!,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ]),
        ],
      ],
    );
  }
}
