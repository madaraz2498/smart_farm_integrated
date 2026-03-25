// lib/features/admin/pages/admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';
import '../../../shared/widgets/sf_text_field.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late final TextEditingController _nameCtrl, _emailCtrl, _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? 'Farmer');
    _emailCtrl = TextEditingController(text: user?.email ?? 'farmer@gmail.com');
    _phoneCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<NavigationProvider>().reset();
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settings, style: AppTextStyles.pageTitle),
                      Text(l10n.manage_account_preferences,
                          style: AppTextStyles.pageSubtitle),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Settings
              _buildSection(
                icon: Icons.person_outline,
                title: l10n.profile_settings,
                child: Column(
                  children: [
                    SfTextField(
                        controller: _nameCtrl,
                        hint: l10n.full_name,
                        label: l10n.full_name),
                    const SizedBox(height: 16),
                    SfTextField(
                        controller: _emailCtrl,
                        hint: l10n.email,
                        label: l10n.email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    SfTextField(
                        controller: _phoneCtrl,
                        hint: l10n.phone_number,
                        label: l10n.phone_number,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    SfPrimaryButton(
                      label: l10n.save_profile,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.profile_saved),
                              backgroundColor: AppColors.primary),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Theme Preference
              _buildSection(
                icon: Icons.palette_outlined,
                title: 'Theme Preference',
                child: Column(
                  children: [
                    _buildRadioTile(
                      title: 'Light Mode',
                      value: false,
                      groupValue: themeProvider.isDark,
                      onChanged: (v) => themeProvider.isDark
                          ? themeProvider.toggleTheme()
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildRadioTile(
                      title: 'Dark Mode',
                      value: true,
                      groupValue: themeProvider.isDark,
                      onChanged: (v) => !themeProvider.isDark
                          ? themeProvider.toggleTheme()
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language Selection
              _buildSection(
                icon: Icons.language_outlined,
                title: 'Language Selection',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: localeProvider.locale.languageCode,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textSubtle),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (v) {
                        if (v != null) localeProvider.setLocale(Locale(v));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notification Preferences
              _buildSection(
                icon: Icons.notifications_none_outlined,
                title: 'Notification Preferences',
                child: Consumer<NotificationProvider>(
                  builder: (context, notif, _) => Column(
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        value: notif.pushEnabled,
                        onChanged: (v) {
                          final userId =
                              context.read<AuthProvider>().currentUser?.id ??
                                  '1';
                          notif.updateSettings(userId: userId, push: v);
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildSwitchTile(
                        title: 'Email Notifications',
                        value: notif.emailEnabled,
                        onChanged: (v) {
                          final userId =
                              context.read<AuthProvider>().currentUser?.id ??
                                  '1';
                          notif.updateSettings(userId: userId, email: v);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              SfOutlineButton(
                label: l10n.logout,
                color: AppColors.error,
                onPressed: _logout,
                icon: Icons.logout,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required bool value,
    required bool groupValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.textDisabled,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
