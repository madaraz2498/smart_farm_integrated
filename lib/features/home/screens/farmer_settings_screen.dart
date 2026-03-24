// lib/features/home/screens/farmer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/locale_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl  = TextEditingController(text: user?.name  ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _saveProfile(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.profile_saved), backgroundColor: AppColors.primary));
  }

  void _confirmLogout(AppLocalizations l10n) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.logout, style: AppTextStyles.cardTitle),
      content: Text(l10n.confirm_logout_message,
          style: const TextStyle(fontSize: 14, color: AppColors.textSubtle, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSubtle))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<NavigationProvider>().reset();
            context.read<AuthProvider>().logout();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: Text(l10n.logout),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.settings, style: AppTextStyles.pageTitle),
          const SizedBox(height: 4),
          Text(l10n.manage_account_preferences, style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 20),

          _SectionCard(children: [
            _SectionHeader(icon: Icons.person_outline_rounded, title: l10n.profile),
            const SizedBox(height: 16),
            SfTextField(controller: _nameCtrl, hint: l10n.full_name, label: l10n.full_name),
            const SizedBox(height: 14),
            SfTextField(controller: _emailCtrl, hint: l10n.email, label: l10n.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SfPrimaryButton(label: l10n.save_profile, onPressed: () => _saveProfile(l10n)),
          ]),
          const SizedBox(height: 16),

          _SectionCard(children: [
            _SectionHeader(icon: Icons.language_rounded, title: l10n.language),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                  border: Border.all(color: AppColors.cardBorder)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: localeProvider.locale.languageCode, isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('Arabic (العربية)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    localeProvider.setLocale(Locale(v));
                  }
                },
              )),
            ),
          ]),
          const SizedBox(height: 16),

          _SectionCard(children: [
            _SectionHeader(icon: Icons.notifications_outlined, title: l10n.notifications),
            const SizedBox(height: 8),
            _ToggleRow(label: l10n.push_notifications, value: _pushNotif,
                onChanged: (v) => setState(() => _pushNotif = v)),
            const Divider(height: 1, color: AppColors.cardBorder),
            _ToggleRow(label: l10n.email_alerts, value: _emailAlerts,
                onChanged: (v) => setState(() => _emailAlerts = v)),
          ]),
          const SizedBox(height: 24),

          SfOutlineButton(label: l10n.logout, onPressed: () => _confirmLogout(l10n), color: AppColors.error),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
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
