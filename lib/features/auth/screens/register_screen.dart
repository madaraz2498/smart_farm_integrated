import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true, _obscureConfirm = true;
  String? _nameErr, _emailErr, _passErr, _confirmErr;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameErr = _emailErr = _passErr = _confirmErr = null;
      if (_nameCtrl.text.trim().length < 2) { _nameErr = 'Name must be at least 2 characters.'; ok = false; }
      if (!_emailCtrl.text.contains('@'))   { _emailErr = 'Enter a valid email.'; ok = false; }
      if (_passCtrl.text.length < 6)        { _passErr = 'Password must be at least 6 characters.'; ok = false; }
      if (_confirmCtrl.text != _passCtrl.text) { _confirmErr = 'Passwords do not match.'; ok = false; }
    });
    return ok;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
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
                Center(child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 38),
                )),
                const SizedBox(height: 20),
                const Center(child: Text('Create Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                const SizedBox(height: 6),
                const Center(child: Text('Join Smart Farm AI today',
                    style: TextStyle(fontSize: 14, color: AppColors.textSubtle))),
                const SizedBox(height: 24),

                Consumer<AuthProvider>(builder: (_, auth, __) {
                  if (auth.errorMsg == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.errorMsg!,
                          style: const TextStyle(fontSize: 13, color: AppColors.error))),
                    ]),
                  );
                }),

                SfTextField(controller: _nameCtrl, hint: 'Enter your full name', label: 'Full Name',
                    errorText: _nameErr, onChanged: (_) => setState(() => _nameErr = null)),
                const SizedBox(height: 14),
                SfTextField(controller: _emailCtrl, hint: 'Enter your email', label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailErr, onChanged: (_) => setState(() => _emailErr = null)),
                const SizedBox(height: 14),
                SfTextField(controller: _passCtrl, hint: 'Min 6 characters', label: 'Password',
                    obscureText: _obscurePass, errorText: _passErr,
                    onChanged: (_) => setState(() => _passErr = null),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppColors.textSubtle),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    )),
                const SizedBox(height: 14),
                SfTextField(controller: _confirmCtrl, hint: 'Re-enter password', label: 'Confirm Password',
                    obscureText: _obscureConfirm, textInputAction: TextInputAction.done,
                    errorText: _confirmErr, onChanged: (_) => setState(() => _confirmErr = null),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppColors.textSubtle),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    )),
                const SizedBox(height: 20),

                Consumer<AuthProvider>(builder: (_, auth, __) =>
                    SfPrimaryButton(label: 'Create Account', onPressed: _submit, isLoading: auth.isLoading)),
                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ',
                      style: TextStyle(fontSize: 14, color: AppColors.textSubtle)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Sign in',
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
