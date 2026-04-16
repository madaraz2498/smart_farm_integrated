import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  String? _codeError, _passError, _confirmError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    bool ok = true;
    setState(() {
      _codeError = _passError = _confirmError = null;
      if (_codeCtrl.text.trim().isEmpty) {
        _codeError = l10n.field_required;
        ok = false;
      }
      if (_passCtrl.text.trim().isEmpty) {
        _passError = l10n.password_required;
        ok = false;
      } else if (_passCtrl.text.length < 6) {
        _passError = l10n.password_too_short;
        ok = false;
      }
      if (_confirmPassCtrl.text.trim().isEmpty) {
        _confirmError = l10n.field_required;
        ok = false;
      } else if (_confirmPassCtrl.text != _passCtrl.text) {
        _confirmError = l10n.passwords_dont_match;
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;

    final success = await context.read<AuthProvider>().resetPassword(
          email: widget.email,
          code: _codeCtrl.text.trim(),
          newPassword: _passCtrl.text.trim(),
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.success_msg)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final hPadding = Responsive.responsiveValue(context, 16.0, 24.0, 32.0);
    final vPadding = Responsive.responsiveValue(context, 32.0, 40.0, 56.0);
    final cardPadding = Responsive.responsiveValue(context, 20.0, 24.0, 32.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 24),

                  Text(l10n.reset_password_title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(l10n.reset_password_subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSubtle)),
                  const SizedBox(height: 32),

                  SfTextField(
                    controller: TextEditingController(text: widget.email),
                    label: l10n.email,
                    readOnly: true,
                    enabled: false,
                    hint: '',
                  ),
                  const SizedBox(height: 16),
                  SfTextField(
                    controller: _codeCtrl,
                    hint: l10n.enter_code,
                    label: l10n.verification_code,
                    errorText: _codeError,
                    onChanged: (_) => setState(() => _codeError = null),
                  ),
                  const SizedBox(height: 16),
                  SfTextField(
                    controller: _passCtrl,
                    hint: l10n.enter_password,
                    label: l10n.new_password,
                    obscureText: _obscure,
                    errorText: _passError,
                    onChanged: (_) => setState(() => _passError = null),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textSubtle),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SfTextField(
                    controller: _confirmPassCtrl,
                    hint: l10n.re_enter_password,
                    label: l10n.confirm_new_password,
                    obscureText: _obscure,
                    errorText: _confirmError,
                    onChanged: (_) => setState(() => _confirmError = null),
                  ),
                  const SizedBox(height: 24),
                  SfPrimaryButton(
                    label: l10n.reset_password,
                    onPressed: () => _submit(l10n),
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(l10n.back_to_sign_in),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
