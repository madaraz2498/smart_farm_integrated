import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _emailError, _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    bool ok = true;
    setState(() {
      _emailError = _passError = null;
      if (_emailCtrl.text.trim().isEmpty) {
        _emailError = l10n.email_required;
        ok = false;
      } else if (!_emailCtrl.text.contains('@')) {
        _emailError = l10n.invalid_email;
        ok = false;
      }
      if (_passCtrl.text.trim().isEmpty) {
        _passError = l10n.password_required;
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Logo
                    Center(
                        child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 38),
                    )),
                    const SizedBox(height: 20),
                    Center(
                        child: Text(l10n.app_name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark))),
                    const SizedBox(height: 6),
                    Center(
                        child: Text(l10n.sign_in_to_account,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSubtle))),
                    const SizedBox(height: 24),

                    // Error banner
                    Consumer<AuthProvider>(builder: (_, auth, __) {
                      if (auth.errorMsg == null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(auth.errorMsg!,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.error))),
                        ]),
                      );
                    }),

                    SfTextField(
                        controller: _emailCtrl,
                        hint: l10n.enter_email,
                        label: l10n.email,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => setState(() => _emailError = null)),
                    const SizedBox(height: 16),
                    SfTextField(
                        controller: _passCtrl,
                        hint: l10n.enter_password,
                        label: l10n.password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
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
                        )),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen())),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: Text(l10n.forgot_password),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Consumer<AuthProvider>(
                        builder: (_, auth, __) => SfPrimaryButton(
                            label: l10n.login,
                            onPressed: () => _submit(l10n),
                            isLoading: auth.isLoading)),
                    const SizedBox(height: 20),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("${l10n.dont_have_account} ",
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSubtle)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: Text(l10n.register,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
