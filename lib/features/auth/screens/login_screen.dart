import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  String? _emailError, _passError;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  bool _validate() {
    bool ok = true;
    setState(() {
      _emailError = _passError = null;
      if (_emailCtrl.text.trim().isEmpty) { _emailError = 'Email is required.'; ok = false; }
      else if (!_emailCtrl.text.contains('@')) { _emailError = 'Enter a valid email.'; ok = false; }
      if (_passCtrl.text.trim().isEmpty) { _passError = 'Password is required.'; ok = false; }
    });
    return ok;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color:        AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: AppColors.cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Logo
                Center(child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color:        AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 38),
                )),
                const SizedBox(height: 20),
                const Center(child: Text('Smart Farm AI',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                const SizedBox(height: 6),
                const Center(child: Text('Sign in to your account',
                    style: TextStyle(fontSize: 14, color: AppColors.textSubtle))),
                const SizedBox(height: 24),

                // Error banner
                Consumer<AuthProvider>(builder: (_, auth, __) {
                  if (auth.errorMsg == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity, margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.errorMsg!,
                          style: const TextStyle(fontSize: 13, color: AppColors.error))),
                    ]),
                  );
                }),

                SfTextField(controller: _emailCtrl, hint: 'Enter your email',
                    label: 'Email', keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _emailError = null)),
                const SizedBox(height: 16),
                SfTextField(controller: _passCtrl, hint: 'Enter your password',
                    label: 'Password', obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    errorText: _passError,
                    onChanged: (_) => setState(() => _passError = null),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppColors.textSubtle),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                const SizedBox(height: 24),

                Consumer<AuthProvider>(builder: (_, auth, __) =>
                    SfPrimaryButton(label: 'Sign In', onPressed: _submit, isLoading: auth.isLoading)),
                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(fontSize: 14, color: AppColors.textSubtle)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Sign up',
                        style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
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
