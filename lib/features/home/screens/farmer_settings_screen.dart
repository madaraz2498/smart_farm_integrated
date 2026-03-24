// lib/features/home/screens/farmer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';

class FarmerSettingsScreen extends StatefulWidget {
  const FarmerSettingsScreen({super.key});
  @override
  State<FarmerSettingsScreen> createState() => _FarmerSettingsScreenState();
}

class _FarmerSettingsScreenState extends State<FarmerSettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool   _pushNotif   = true;
  bool   _emailAlerts = true;
  String _language    = 'English';

  static const _langs = ['English', 'Arabic'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl  = TextEditingController(text: user?.name  ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile saved.'), backgroundColor: AppColors.primary));
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sign Out', style: AppTextStyles.cardTitle),
      content: const Text('Are you sure you want to sign out?',
          style: TextStyle(fontSize: 14, color: AppColors.textSubtle, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSubtle))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<NavigationProvider>().reset();
            context.read<AuthProvider>().logout();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: const Text('Sign Out'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: AppTextStyles.pageTitle),
          const SizedBox(height: 4),
          const Text('Manage your account and preferences', style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 20),

          _SectionCard(children: [
            const _SectionHeader(icon: Icons.person_outline_rounded, title: 'Profile'),
            const SizedBox(height: 16),
            SfTextField(controller: _nameCtrl, hint: 'Full Name', label: 'Full Name'),
            const SizedBox(height: 14),
            SfTextField(controller: _emailCtrl, hint: 'Email', label: 'Email',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SfPrimaryButton(label: 'Save Profile', onPressed: _saveProfile),
          ]),
          const SizedBox(height: 16),

          _SectionCard(children: [
            const _SectionHeader(icon: Icons.language_rounded, title: 'Language'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                  border: Border.all(color: AppColors.cardBorder)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _language, isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                items: _langs.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) { if (v != null) setState(() => _language = v); },
              )),
            ),
          ]),
          const SizedBox(height: 16),

          _SectionCard(children: [
            const _SectionHeader(icon: Icons.notifications_outlined, title: 'Notifications'),
            const SizedBox(height: 8),
            _ToggleRow(label: 'Push Notifications', value: _pushNotif,
                onChanged: (v) => setState(() => _pushNotif = v)),
            const Divider(height: 1, color: AppColors.cardBorder),
            _ToggleRow(label: 'Email Alerts', value: _emailAlerts,
                onChanged: (v) => setState(() => _emailAlerts = v)),
          ]),
          const SizedBox(height: 24),

          SfOutlineButton(label: 'Sign Out', onPressed: _confirmLogout, color: AppColors.error),
        ]),
      )),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon; final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
        child: Icon(icon, color: AppColors.primary, size: 18)),
    const SizedBox(width: 12),
    Text(title, style: AppTextStyles.cardTitle),
  ]);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  final String label; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
  );
}
