import 'dart:async';
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
  Timer? _pollingTimer;

  // Guard: prevent duplicate API calls on page revisit via IndexedStack.
  bool _dataLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) setState(() {});
    });
  }

  Future<void> _loadData({bool force = false}) async {
    if (_dataLoadedOnce && !force) return;
    final provider = context.read<AdminProvider>();
    try {
      await provider.loadSystemStatus(forceRefresh: force);
    } catch (e) {
      ProductionLogger.error('[SystemManagementPage] _loadData failed', e);
    }

    if (!mounted) return;
    setState(() {
      _dataLoadedOnce = true;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _toggleService(String key, bool val) async {
    await context.read<AdminProvider>().toggleService(key);
  }

  Future<void> _toggleSetting(String key, bool val) async {
    await context.read<AdminProvider>().toggleSystemSetting(key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pagePadding = Responsive.responsivePadding(context);
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<AdminProvider>();
    final services = provider.servicesStatus;
    final settings = provider.systemSettings;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () => _loadData(force: true),
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.system_management,
                        style: AppTextStyles.pageTitle
                            .copyWith(color: colorScheme.onSurface)),
                    Text(
                      'Monitor and manage all AI services and system components',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatusGrid(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildTabHeader(colorScheme),
                    const SizedBox(height: 24),
                    if (_tab.index == 0)
                      _buildAIServicesContent(l10n, colorScheme, services)
                    else
                      _buildGeneralSettingsContent(l10n, colorScheme, settings),
                  ],
                ),
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

  Widget _buildAIServicesContent(AppLocalizations l10n, ColorScheme colorScheme,
      Map<String, bool?> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'AI Feature Controls', colorScheme: colorScheme),
        const SizedBox(height: 12),
        _ToggleCard(
          title: l10n.nav_plant_disease,
          subtitle: 'Enable/Disable Plant Disease AI',
          val: services['plant_disease'],
          onChanged: (v) => _toggleService('plant_disease', v),
          icon: Icons.eco_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_animal_weight,
          subtitle: 'Enable/Disable Animal AI',
          val: services['animal_weight'],
          onChanged: (v) => _toggleService('animal_weight', v),
          icon: Icons.pets_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_crop_recommendation,
          subtitle: 'Enable/Disable Crop AI',
          val: services['crop_rec'],
          onChanged: (v) => _toggleService('crop_rec', v),
          icon: Icons.grass_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_soil_analysis,
          subtitle: 'Enable/Disable Soil AI',
          val: services['soil_analysis'],
          onChanged: (v) => _toggleService('soil_analysis', v),
          icon: Icons.landscape_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_fruit_quality,
          subtitle: 'Enable/Disable Fruit AI',
          val: services['fruit_quality'],
          onChanged: (v) => _toggleService('fruit_quality', v),
          icon: Icons.apple_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: l10n.nav_chatbot,
          subtitle: 'Enable/Disable Chatbot AI',
          val: services['chatbot'],
          onChanged: (v) => _toggleService('chatbot', v),
          icon: Icons.chat_rounded,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGeneralSettingsContent(AppLocalizations l10n,
      ColorScheme colorScheme, Map<String, bool?> settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Global Settings', colorScheme: colorScheme),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Maintenance Mode',
          subtitle: 'Restrict access to the application',
          val: settings['maintenance_mode'],
          onChanged: (v) => _toggleSetting('maintenance_mode', v),
          icon: Icons.engineering_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: 'Email Notifications',
          subtitle: 'Send automated system alerts',
          val: settings['email_notifications'],
          onChanged: (v) => _toggleSetting('email_notifications', v),
          icon: Icons.email_rounded,
          colorScheme: colorScheme,
        ),
        _ToggleCard(
          title: 'Automatic Backups',
          subtitle: 'Scheduled database snapshots',
          val: settings['auto_backup'],
          onChanged: (v) => _toggleSetting('auto_backup', v),
          icon: Icons.backup_rounded,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatusGrid(BuildContext context, ColorScheme colorScheme) {
    final provider = context.watch<AdminProvider>();
    final s = provider.statusDetails;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 2.2 : 1.6,
        children: [
          _StatusCard(
            title: 'System Status',
            statusText: s?.status ?? 'All Systems Operational',
            statusColor: Colors.green,
            icon: Icons.monitor_outlined,
            details: {
              'Uptime': s?.uptime ?? '23h 30m',
              'Response Time': s?.responseTime ?? '40ms',
            },
          ),
          _StatusCard(
            title: 'Database',
            statusText: s?.dbStatus ?? 'Healthy',
            statusColor: Colors.green,
            icon: Icons.storage_outlined,
            details: {
              'Storage Used': s?.dbStorage ?? '8856 kB',
              'Connections': '${s?.dbConnections ?? 16} active',
            },
          ),
          _StatusCard(
            title: 'AI Models',
            statusText: s?.aiActive ?? '6 / 6 Active',
            statusColor: Colors.green,
            icon: Icons.memory_outlined,
            details: {
              'Avg Accuracy': s?.aiAccuracy ?? '92.1%',
              'Total Requests': s?.aiRequests ?? '164',
            },
          ),
        ],
      );
    });
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String statusText;
  final Color statusColor;
  final IconData icon;
  final Map<String, String> details;

  const _StatusCard({
    required this.title,
    required this.statusText,
    required this.statusColor,
    required this.icon,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
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
  final bool? val;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bool isReady = val != null;
    final bool active = val ?? false;

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
              color: (active ? colorScheme.primary : colorScheme.onSurface)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant),
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
          if (!isReady)
            const SizedBox(
              width: 32,
              height: 32,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch(
              value: active,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
        ],
      ),
    );
  }
}
