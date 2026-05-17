import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive.dart';
import '../providers/auth_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = l10n.email_required);
      return;
    }
    if (!email.contains('@')) {
      setState(() => _emailError = l10n.invalid_email);
      return;
    }

    final success = await context.read<AuthProvider>().forgotPassword(email);
    if (success) {
      setState(() => _codeSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final hPadding = Responsive.responsiveValue(context, 16.0, 24.0, 32.0);
    final vPadding = Responsive.responsiveValue(context, 32.0, 40.0, 56.0);
    final cardPadding = Responsive.responsiveValue(context, 20.0, 24.0, 32.0);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 24),

                    if (!_codeSent) ...[
                      Text(l10n.forgot_password_title,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(l10n.forgot_password_subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 32),
                      SfTextField(
                        controller: _emailCtrl,
                        hint: 'example@email.com',
                        label: l10n.email,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => setState(() => _emailError = null),
                      ),
                      const SizedBox(height: 24),
                      SfPrimaryButton(
                        label: l10n.send_reset_code,
                        onPressed: () => _submit(l10n),
                        isLoading: auth.isLoading,
                      ),
                    ] else ...[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mail_outline_rounded,
                            color: colorScheme.primary, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(l10n.code_sent,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(l10n.check_email_for_code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 32),
                      SfPrimaryButton(
                        label: l10n.enter_code,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResetPasswordScreen(
                                email: _emailCtrl.text.trim(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(l10n.back_to_sign_in),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
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
