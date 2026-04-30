// lib/features/admin/pages/admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/features/notifications/models/notification_model.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        // Load admin-specific notification settings (NOT farmer settings)
        context.read<NotificationProvider>().fetchAdminSettings(userId: userId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _logout() {
    context.read<NavigationProvider>().reset();
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final pagePadding = Responsive.responsivePadding(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return _buildContent(context, localeProvider, l10n, pagePadding, isDark);
      },
    );
  }

  Widget _buildContent(BuildContext context, LocaleProvider localeProvider,
      AppLocalizations l10n, double pagePadding, bool isDark) {

    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<AuthProvider>().loadUserProfile();
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(pagePadding),
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

                      // Theme Preference
                      _buildSection(
                        icon: Icons.palette_outlined,
                        title: l10n.theme_preference,
                        child: Column(
                          children: [
                            _buildRadioTile(
                              title: l10n.light_mode,
                              value: false,
                              groupValue: isDark,
                              onTap: () {
                                debugPrint('Light Mode tapped, isDark=$isDark');
                                if (isDark) {
                                  debugPrint('Toggling to light');
                                  ThemeController.toggleTheme();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildRadioTile(
                              title: l10n.dark_mode,
                              value: true,
                              groupValue: isDark,
                              onTap: () {
                                debugPrint('Dark Mode tapped, isDark=$isDark');
                                if (!isDark) {
                                  debugPrint('Toggling to dark');
                                  ThemeController.toggleTheme();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Language Selection
                      _buildSection(
                        icon: Icons.language_outlined,
                        title: l10n.language_selection,
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
                              items: [
                                DropdownMenuItem(
                                    value: 'en', child: Text(l10n.english)),
                                DropdownMenuItem(
                                    value: 'ar', child: Text(l10n.arabic)),
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
                        title: l10n.notification_preferences,
                        child: Consumer<NotificationProvider>(
                          builder: (context, notif, _) {
                            final userId =
                                context.read<AuthProvider>().currentUser?.id ?? '';
                            return Column(
                              children: [
                                _buildSwitchTile(
                                  title: l10n.push_notifications,
                                  value: notif.adminSettings.pushNotifications,
                                  onChanged: notif.isSettingsLoading
                                      ? null
                                      : (v) => notif.updateAdminSettings(
                                    userId: userId,
                                    updatedSettings: AdminNotificationSettings(
                                      pushNotifications: v,
                                      emailNotifications:
                                      notif.adminSettings.emailNotifications,
                                      smsNotifications:
                                      notif.adminSettings.smsNotifications,
                                    ),
                                  ),
                                ),
                                const Divider(height: 1, color: AppColors.divider),
                                _buildSwitchTile(
                                  title: l10n.email_notifications,
                                  value: notif.adminSettings.emailNotifications,
                                  onChanged: notif.isSettingsLoading
                                      ? null
                                      : (v) => notif.updateAdminSettings(
                                    userId: userId,
                                    updatedSettings: AdminNotificationSettings(
                                      pushNotifications:
                                      notif.adminSettings.pushNotifications,
                                      emailNotifications: v,
                                      smsNotifications:
                                      notif.adminSettings.smsNotifications,
                                    ),
                                  ),
                                ),
                                if (notif.isSettingsLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: LinearProgressIndicator(),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                      SfOutlineButton(
                        label: l10n.logout,
                        color: AppColors.error,
                        onPressed: _logout,
                        icon: Icons.logout,
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
    VoidCallback? onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
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
    required ValueChanged<bool>? onChanged,
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
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
