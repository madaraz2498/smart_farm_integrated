// lib/features/home/screens/farmer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';

class FarmerSettingsPage extends StatefulWidget {
  const FarmerSettingsPage({super.key});
  @override
  State<FarmerSettingsPage> createState() => _FarmerSettingsPageState();
}

class _FarmerSettingsPageState extends State<FarmerSettingsPage> {
  String _themeMode = 'light';

  // Notification toggles — mirror the 3 fields from the API
  bool _emailNotificationsFarmer = false;
  bool _analysisCompletionAlerts = true;
  bool _weeklyReportSummary = false;

  bool _savingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final provider = context.read<NotificationProvider>();
    await provider.fetchFarmerSettings(userId: userId);

    if (mounted) {
      final s = provider.farmerSettings;
      setState(() {
        _emailNotificationsFarmer = s.emailNotificationsFarmer;
        _analysisCompletionAlerts = s.analysisCompletionAlerts;
        _weeklyReportSummary      = s.weeklyReportSummary;
      });
    }
  }

  Future<void> _saveSettings() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _savingSettings = true);

    final success =
    await context.read<NotificationProvider>().updateFarmerSettings(
      userId: userId,
      updatedSettings: FarmerNotificationSettings(
        emailNotificationsFarmer: _emailNotificationsFarmer,
        analysisCompletionAlerts: _analysisCompletionAlerts,
        weeklyReportSummary:      _weeklyReportSummary,
      ),
    );

    if (mounted) {
      setState(() => _savingSettings = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? l10n.notification_settings_saved : l10n.failed_to_save_changes),
        backgroundColor: success ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Called whenever a toggle changes — updates local state then saves.
  void _onToggle(void Function() update) {
    setState(update);
    _saveSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<AuthProvider>().loadUserProfile();
        await _loadSettings();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Page header ───────────────────────────────────────────────
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

                // ── Theme ─────────────────────────────────────────────────────
                _SectionCard(children: [
                  _SectionHeader(
                      icon: Icons.palette_outlined,
                      title: l10n.theme_preference),
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

                // ── Language ──────────────────────────────────────────────────
                _SectionCard(children: [
                  _SectionHeader(
                      icon: Icons.language_rounded, title: l10n.language),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusMid),
                        border: Border.all(color: AppColors.cardBorder)),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: localeProvider.locale.languageCode,
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(
                                value: 'ar',
                                child: Text('Arabic (العربية)')),
                          ],
                          onChanged: (v) {
                            if (v != null) localeProvider.setLocale(Locale(v));
                          },
                        )),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Notification settings ─────────────────────────────────────
                _SectionCard(children: [
                  _SectionHeader(
                      icon: Icons.notifications_outlined,
                      title: l10n.notifications),
                  const SizedBox(height: 8),

                  // 1. Email notifications
                  _ToggleRow(
                    icon: Icons.email_outlined,
                    label: l10n.email_notifications,
                    subtitle: l10n.email_notifications_desc,
                    value: _emailNotificationsFarmer,
                    disabled: _savingSettings,
                    onChanged: (v) =>
                        _onToggle(() => _emailNotificationsFarmer = v),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),

                  // 2. Analysis completion alerts
                  _ToggleRow(
                    icon: Icons.analytics_outlined,
                    label: l10n.analysis_completion_alerts,
                    subtitle: l10n.analysis_completion_alerts_desc,
                    value: _analysisCompletionAlerts,
                    disabled: _savingSettings,
                    onChanged: (v) =>
                        _onToggle(() => _analysisCompletionAlerts = v),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),

                  // 3. Weekly report summary
                  _ToggleRow(
                    icon: Icons.summarize_outlined,
                    label: l10n.weekly_report_summary,
                    subtitle: l10n.weekly_report_summary_desc,
                    value: _weeklyReportSummary,
                    disabled: _savingSettings,
                    onChanged: (v) =>
                        _onToggle(() => _weeklyReportSummary = v),
                  ),

                  if (_savingSettings)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(),
                    ),
                ]),
              ]),
            )),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

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
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                isSelected ? AppColors.primary : AppColors.textDark,
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6)
        ]),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
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
            borderRadius:
            BorderRadius.circular(AppSizes.radiusMid)),
        child: Icon(icon, color: AppColors.primary, size: 18)),
    const SizedBox(width: 12),
    Text(title, style: AppTextStyles.cardTitle),
  ]);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.subtitle,
    this.disabled = false,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: AppColors.textSubtle),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textDark)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                      height: 1.4)),
          ],
        ),
      ),
      Switch(
          value: value,
          onChanged: disabled ? null : onChanged,
          activeColor: AppColors.primary),
    ]),
  );
}