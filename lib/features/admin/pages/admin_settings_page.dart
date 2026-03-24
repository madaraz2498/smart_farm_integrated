// lib/features/admin/pages/admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late final TextEditingController _nameCtrl, _emailCtrl;
  bool _maintenance = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl  = TextEditingController(text: user?.name  ?? 'Admin');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _logout() {
    context.read<NavigationProvider>().reset();
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: AppTextStyles.pageTitle),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: AppColors.cardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin Profile', style: AppTextStyles.cardTitle),
              const SizedBox(height: 16),
              SfTextField(controller: _nameCtrl, hint: 'Display Name', label: 'Display Name'),
              const SizedBox(height: 14),
              SfTextField(controller: _emailCtrl, hint: 'Email', label: 'Email',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              SfPrimaryButton(label: 'Save Profile', onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Profile saved.'), backgroundColor: AppColors.primary));
              }),
            ])),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: AppColors.cardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Danger Zone', style: AppTextStyles.cardTitle),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Maintenance Mode', style: AppTextStyles.label),
                  Text('Disable user access temporarily', style: AppTextStyles.caption),
                ]),
                Switch(value: _maintenance,
                    onChanged: (v) => setState(() => _maintenance = v),
                    activeColor: AppColors.error),
              ]),
              const SizedBox(height: 12),
              SfOutlineButton(label: 'Sign Out', color: AppColors.error, onPressed: _logout),
            ])),
        ]),
      )),
    );
  }
}
