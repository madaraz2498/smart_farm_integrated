import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/utils/responsive.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<AdminProvider>();
    await provider.loadSystemStatus();

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
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _toggleService(String key, bool val) async {
    setState(() => _services[key] = val);
    debugPrint(
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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pagePadding = Responsive.responsivePadding(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pagePadding),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.system_management_title, style: AppTextStyles.pageTitle),
          const SizedBox(height: 4),
          Text(l10n.system_management_subtitle,
              style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border:
                    Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSubtle,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: l10n.ai_models),
                Tab(text: l10n.general_settings)
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
              animation: _tab,
              builder: (_, __) {
                final loading = context.watch<AdminProvider>().systemLoading;
                if (loading && _services.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                return _tab.index == 0
                    ? _buildAITab(l10n)
                    : _buildGeneralTab(l10n);
              }),
          ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAITab(AppLocalizations l10n) {
    final models = [
      ('plant_disease', l10n.nav_plant_disease, Icons.local_florist_outlined),
      ('animal_weight', l10n.nav_animal_weight, Icons.monitor_weight_outlined),
      ('crop_rec', l10n.nav_crop_recommendation, Icons.grass_outlined),
      ('soil_analysis', l10n.nav_soil_analysis, Icons.layers_outlined),
      ('fruit_quality', l10n.nav_fruit_quality, Icons.apple_outlined),
      ('chatbot', l10n.nav_chatbot, Icons.chat_bubble_outline),
    ];
    return Column(children: [
      ...models.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border:
                    Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: (_services[m.$1] ?? false)
                          ? AppColors.primarySurface
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(m.$3,
                      color: (_services[m.$1] ?? false)
                          ? AppColors.primary
                          : Colors.grey,
                      size: 22)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(m.$2,
                      style: AppTextStyles.label,
                      overflow: TextOverflow.ellipsis)),
              Switch(
                  value: _services[m.$1] ?? false,
                  onChanged: (v) => _toggleService(m.$1, v),
                  activeThumbColor: AppColors.primary),
            ]),
          )),
      SfPrimaryButton(
          label: l10n.save_ai_config,
          onPressed: () {
            context.read<AdminProvider>().logAIConfigurationUpdate();
            _snack(l10n.ai_config_saved);
          }),
    ]);
  }

  Widget _buildGeneralTab(AppLocalizations l10n) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.platform_settings, style: AppTextStyles.cardTitle),
            const SizedBox(height: 16),
            _ToggleRow(
                l10n.maintenance_mode,
                l10n.maintenance_mode_desc,
                _maintenance,
                AppColors.error,
                (v) => _toggleSetting('maintenance_mode', v)),
            _ToggleRow(
                l10n.email_notifications,
                l10n.email_alerts,
                _emailNotif,
                AppColors.info,
                (v) => _toggleSetting('email_notifications', v)),
            _ToggleRow(
                l10n.auto_backup,
                l10n.auto_backup_desc,
                _autoBackup,
                const Color(0xFF9C27B0),
                (v) => _toggleSetting('auto_backup', v)),
          ])),
      const SizedBox(height: 16),
      SfPrimaryButton(
          label: l10n.save_general_settings,
          onPressed: () async {
            final userId = context.read<AuthProvider>().currentUser?.id;
            if (userId == null) {
              _snack(l10n.error_user_not_found);
              return;
            }

            final success = await context
                .read<AdminProvider>()
                .updateAdminNotificationSettings(userId, {
              'maintenance_mode': _maintenance,
              'email_notifications': _emailNotif,
              'auto_backup': _autoBackup,
            });

            if (!mounted) return;

            if (success) {
              _snack(l10n.general_settings_saved);
            } else {
              final error = context.read<AdminProvider>().statsError;
              _snack(error ?? l10n.error_msg);
            }
          }),
    ]);
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      this.label, this.desc, this.value, this.color, this.onChanged);
  final String label, desc;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: AppTextStyles.label),
                Text(desc,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSubtle)),
              ])),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary),
        ]),
      );
}
