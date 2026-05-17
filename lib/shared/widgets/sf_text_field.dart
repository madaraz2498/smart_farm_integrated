import 'package:flutter/material.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            // These will automatically use the InputDecorationTheme from our dark/light theme files
          ),
        ),
      ],
    );
  }
}
