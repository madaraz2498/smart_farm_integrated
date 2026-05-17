import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/admin_provider.dart';
import 'package:smart_farm/core/theme/app_text_styles.dart';
import 'package:smart_farm/core/utils/production_logger.dart';
import 'package:smart_farm/core/utils/responsive.dart';

class SystemManagementPage extends StatefulWidget {
  const SystemManagementPage({super.key});
  @override
  State<SystemManagementPage> createState() => _SystemManagementPageState();
}

class _SystemManagementPageState extends State<SystemManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // AI model toggles
  Map<String, bool> _services = {
    'plant_disease': true,
    'animal_weight': true,
    'crop_rec': true,
    'soil_analysis': true,
    'fruit_quality': true,
    'chatbot': true,
  };

  // General settings
  bool _maintenance = false, _emailNotif = true, _autoBackup = true;

  // Guard: prevent duplicate API calls on page revisit via IndexedStack.
  bool _dataLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData({bool force = false}) async {
    // Skip if already loaded and not an explicit pull-to-refresh.
    if (_dataLoadedOnce && !force) return;

    final provider = context.read<AdminProvider>();
    await provider.loadSystemStatus();

    if (!mounted) return;
    setState(() {
      if (provider.servicesStatus.isNotEmpty) {
        _services = Map<String, bool>.from(provider.servicesStatus);
      }

      final settings = provider.systemSettings;
      if (settings.containsKey('maintenance_mode')) {
        _maintenance = settings['maintenance_mode']!;
      }
      if (settings.containsKey('email_notifications')) {
        _emailNotif = settings['email_notifications']!;
      }
      if (settings.containsKey('auto_backup')) {
        _autoBackup = settings['auto_backup']!;
      }

      _dataLoadedOnce = true;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _toggleService(String key, bool val) async {
    setState(() => _services[key] = val);
    ProductionLogger.info(
        '[SystemManagementPage] Calling AdminProvider.toggleService for $key');
    await context.read<AdminProvider>().toggleService(key);
  }

  Future<void> _toggleSetting(String key, bool val) async {
    // Local state update
    if (key == 'maintenance_mode') _maintenance = val;
    if (key == 'email_notifications') _emailNotif = val;
    if (key == 'auto_backup') _autoBackup = val;
    setState(() {});

    await context.read<AdminProvider>().toggleSystemSetting(key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pagePadding = Responsive.responsivePadding(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () => _loadData(force: true),
              color: colorScheme.primary,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.system_management,
                            style: AppTextStyles.pageTitle
                                .copyWith(color: colorScheme.onSurface)),
                        const SizedBox(height: 20),
                        _buildTabHeader(colorScheme),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _buildAIServicesTab(pagePadding, l10n, colorScheme),
                        _buildGeneralSettingsTab(
                            pagePadding, l10n, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabHeader(ColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colorScheme.primary,
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'AI Services'),
          Tab(text: 'System Settings'),
        ],
      ),
    );
  }

  Widget _buildAIServicesTab(
      double padding, AppLocalizations l10n, ColorScheme colorScheme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      children: [
        _SectionHeader(title: 'AI Feature Controls', colorScheme: colorScheme),
        const SizedBox(height: 12),
        _ToggleCard(
          title: l10n.nav_plant_disease,
          subtitle: 'Enable/Disable Plant Disease AI',
          val: _services['plant_disease'] ?? true,
          onChanged: (v) => _toggleService('plant_disease', v),
          icon: Icons.eco_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_animal_weight,
          subtitle: 'Enable/Disable Animal AI',
          val: _services['animal_weight'] ?? true,
          onChanged: (v) => _toggleService('animal_weight', v),
          icon: Icons.pets_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_crop_recommendation,
          subtitle: 'Enable/Disable Crop AI',
          val: _services['crop_rec'] ?? true,
          onChanged: (v) => _toggleService('crop_rec', v),
          icon: Icons.grass_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_soil_analysis,
          subtitle: 'Enable/Disable Soil AI',
          val: _services['soil_analysis'] ?? true,
          onChanged: (v) => _toggleService('soil_analysis', v),
          icon: Icons.landscape_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_fruit_quality,
          subtitle: 'Enable/Disable Fruit AI',
          val: _services['fruit_quality'] ?? true,
          onChanged: (v) => _toggleService('fruit_quality', v),
          icon: Icons.apple_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_chatbot,
          subtitle: 'Enable/Disable Chatbot AI',
          val: _services['chatbot'] ?? true,
          onChanged: (v) => _toggleService('chatbot', v),
          icon: Icons.chat_rounded,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGeneralSettingsTab(
      double padding, AppLocalizations l10n, ColorScheme colorScheme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      children: [
        _SectionHeader(title: 'Global Settings', colorScheme: colorScheme),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Maintenance Mode',
          subtitle: 'Restrict access to the application',
          val: _maintenance,
          onChanged: (v) => _toggleSetting('maintenance_mode', v),
          icon: Icons.build_circle_outlined,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: 'Email Notifications',
          subtitle: 'Enable system alerts via email',
          val: _emailNotif,
          onChanged: (v) => _toggleSetting('email_notifications', v),
          icon: Icons.notifications_active_outlined,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: 'Auto Data Backup',
          subtitle: 'Daily database backups',
          val: _autoBackup,
          onChanged: (v) => _toggleSetting('auto_backup', v),
          icon: Icons.cloud_upload_outlined,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colorScheme});
  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.val,
    required this.onChanged,
    required this.icon,
    required this.colorScheme,
  });

  final String title, subtitle;
  final bool val;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (val ? colorScheme.primary : colorScheme.onSurface)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color:
                    val ? colorScheme.primary : colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
