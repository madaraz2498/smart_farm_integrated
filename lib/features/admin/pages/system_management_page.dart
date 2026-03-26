import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _services = {
    'plant_disease': true,
    'animal_weight': true,
    'crop_rec': false,
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
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _toggleService(String key, bool val) async {
    setState(() => _services[key] = val);
    await context.read<AdminProvider>().toggleService(key);
  }

  Future<void> _toggleSetting(String key, bool val) async {
    // Local state update
    if (key == 'maintenance') _maintenance = val;
    if (key == 'email_notif') _emailNotif = val;
    if (key == 'auto_backup') _autoBackup = val;
    setState(() {});

    await context.read<AdminProvider>().toggleSystemSetting(key);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('System Management', style: AppTextStyles.pageTitle),
          const SizedBox(height: 4),
          const Text('Configure AI services and platform settings',
              style: AppTextStyles.pageSubtitle),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: Colors.black.withOpacity(0.06))),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSubtle,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'AI Models'),
                Tab(text: 'General Settings')
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
              animation: _tab,
              builder: (_, __) =>
                  _tab.index == 0 ? _buildAITab() : _buildGeneralTab()),
        ]),
      ),
    );
  }

  Widget _buildAITab() {
    final models = [
      (
        'plant_disease',
        'Plant Disease Detection',
        Icons.local_florist_outlined
      ),
      (
        'animal_weight',
        'Animal Weight Estimation',
        Icons.monitor_weight_outlined
      ),
      ('crop_rec', 'Crop Recommendation', Icons.grass_outlined),
      ('soil_analysis', 'Soil Type Analysis', Icons.layers_outlined),
      ('fruit_quality', 'Fruit Quality Analysis', Icons.apple_outlined),
      ('chatbot', 'Smart Farm Chatbot', Icons.chat_bubble_outline),
    ];
    return Column(children: [
      ...models.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: Colors.black.withOpacity(0.06))),
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
                  activeColor: AppColors.primary),
            ]),
          )),
      SfPrimaryButton(
          label: 'Save AI Configuration',
          onPressed: () => _snack('AI configuration saved!')),
    ]);
  }

  Widget _buildGeneralTab() {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: Colors.black.withOpacity(0.06))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Platform Settings', style: AppTextStyles.cardTitle),
            const SizedBox(height: 16),
            _ToggleRow(
                'Maintenance Mode',
                'Disable user access temporarily',
                _maintenance,
                AppColors.error,
                (v) => _toggleSetting('maintenance', v)),
            _ToggleRow(
                'Email Notifications',
                'System alerts via email',
                _emailNotif,
                AppColors.info,
                (v) => _toggleSetting('email_notif', v)),
            _ToggleRow(
                'Auto Backup',
                'Daily database snapshots',
                _autoBackup,
                const Color(0xFF9C27B0),
                (v) => _toggleSetting('auto_backup', v)),
          ])),
      const SizedBox(height: 16),
      SfPrimaryButton(
          label: 'Save General Settings',
          onPressed: () => _snack('General settings saved!')),
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
                Text(desc, style: AppTextStyles.caption),
              ])),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ]),
      );
}
