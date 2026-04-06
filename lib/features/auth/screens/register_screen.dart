import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true, _obscureConfirm = true;
  bool _agreeTerms = false;
  String? _nameErr, _emailErr, _passErr, _confirmErr, _termsErr;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    bool ok = true;
    setState(() {
      _nameErr = _emailErr = _passErr = _confirmErr = _termsErr = null;
      if (_nameCtrl.text.trim().length < 2) {
        _nameErr = l10n.name_too_short;
        ok = false;
      }
      if (!_emailCtrl.text.contains('@')) {
        _emailErr = l10n.invalid_email;
        ok = false;
      }
      if (_passCtrl.text.length < 6) {
        _passErr = l10n.password_too_short;
        ok = false;
      }
      if (_confirmCtrl.text != _passCtrl.text) {
        _confirmErr = l10n.passwords_dont_match;
        ok = false;
      }
      if (!_agreeTerms) {
        _termsErr = 'Please agree to the Terms & Conditions';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                    Center(
                        child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 38),
                    )),
                    const SizedBox(height: 20),
                    Center(
                        child: Text(l10n.create_account,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark))),
                    const SizedBox(height: 6),
                    Center(
                        child: Text(l10n.join_today,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSubtle))),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(builder: (_, auth, __) {
                      if (auth.errorMsg == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3))),
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
                        controller: _nameCtrl,
                        hint: l10n.enter_full_name,
                        label: l10n.full_name,
                        errorText: _nameErr,
                        onChanged: (_) => setState(() => _nameErr = null)),
                    const SizedBox(height: 14),
                    SfTextField(
                        controller: _emailCtrl,
                        hint: l10n.enter_email,
                        label: l10n.email,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailErr,
                        onChanged: (_) => setState(() => _emailErr = null)),
                    const SizedBox(height: 14),
                    SfTextField(
                        controller: _passCtrl,
                        hint: l10n.min_6_chars,
                        label: l10n.password,
                        obscureText: _obscurePass,
                        errorText: _passErr,
                        onChanged: (_) => setState(() => _passErr = null),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSubtle),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        )),
                    const SizedBox(height: 14),
                    SfTextField(
                        controller: _confirmCtrl,
                        hint: l10n.re_enter_password,
                        label: l10n.confirm_password,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        errorText: _confirmErr,
                        onChanged: (_) => setState(() => _confirmErr = null),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSubtle),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (v) =>
                                setState(() => _agreeTerms = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: l10n.agree_terms.split('&').first,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSubtle),
                              children: [
                                TextSpan(
                                  text: '& Conditions',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_termsErr != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 32),
                        child: Text(_termsErr!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 11)),
                      ),
                    const SizedBox(height: 20),
                    Consumer<AuthProvider>(
                        builder: (_, auth, __) => SfPrimaryButton(
                            label: l10n.create_account,
                            onPressed: () => _submit(l10n),
                            isLoading: auth.isLoading)),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("${l10n.already_have_account} ",
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSubtle)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: Text(l10n.sign_in,
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
    );
  }
}
