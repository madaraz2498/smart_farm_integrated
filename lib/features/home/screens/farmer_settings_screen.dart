// lib/features/home/screens/farmer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';

class FarmerSettingsScreen extends StatefulWidget {
  const FarmerSettingsScreen({super.key});
  @override
  State<FarmerSettingsScreen> createState() => _FarmerSettingsScreenState();
}

class _FarmerSettingsScreenState extends State<FarmerSettingsScreen> {
  String _themeMode = 'light';
  bool _pushNotif = true;
  bool _emailAlerts = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _confirmLogout(AppLocalizations l10n) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.logout, style: AppTextStyles.cardTitle),
              content: Text(l10n.confirm_logout_message,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSubtle, height: 1.5)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: AppColors.textSubtle))),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<NavigationProvider>().reset();
                    context.read<AuthProvider>().logout();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white),
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
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.settings_outlined,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(l10n.settings, style: AppTextStyles.pageTitle),
          ]),
          const SizedBox(height: 4),
          Text(l10n.manage_account_preferences,
              style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 24),
          _SectionCard(children: [
            _SectionHeader(
                icon: Icons.palette_outlined, title: l10n.theme_preference),
            const SizedBox(height: 20),
            _ThemeOption(
              label: l10n.light_mode,
              value: 'light',
              groupValue: _themeMode,
              onChanged: (v) => setState(() => _themeMode = v!),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              label: l10n.dark_mode,
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (v) => setState(() => _themeMode = v!),
            ),
          ]),
          const SizedBox(height: 20),
          _SectionCard(children: [
            _SectionHeader(icon: Icons.language_rounded, title: l10n.language),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid),
                  border: Border.all(color: AppColors.cardBorder)),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: localeProvider.locale.languageCode,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(
                      value: 'ar', child: Text('Arabic (العربية)')),
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
            _SectionHeader(
                icon: Icons.notifications_outlined, title: l10n.notifications),
            const SizedBox(height: 8),
            _ToggleRow(
                label: l10n.push_notifications,
                value: _pushNotif,
                onChanged: (v) => setState(() => _pushNotif = v)),
            const Divider(height: 1, color: AppColors.cardBorder),
            _ToggleRow(
                label: l10n.email_alerts,
                value: _emailAlerts,
                onChanged: (v) => setState(() => _emailAlerts = v)),
          ]),
          const SizedBox(height: 24),
          SfOutlineButton(
              label: l10n.logout,
              onPressed: () => _confirmLogout(l10n),
              color: AppColors.error),
        ]),
      )),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption(
      {required this.label,
      required this.value,
      required this.groupValue,
      required this.onChanged});
  final String label, value, groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSizes.radiusMid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMid),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder),
          color: isSelected
              ? AppColors.primarySurface.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
        child: Row(children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textDark,
              )),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
            child: Icon(icon, color: AppColors.primary, size: 18)),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.cardTitle),
      ]);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark))),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary),
        ]),
      );
}
