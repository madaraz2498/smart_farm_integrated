import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/sf_button.dart';

class SystemReportsPage extends StatefulWidget {
  const SystemReportsPage({super.key});
  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {
  String _period = 'Last 7 Days';
  bool   _exporting = false;

  static const _periods = ['Today', 'Last 7 Days', 'Last 30 Days', 'This Year'];

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await AdminService.instance.generatePdfReport(period: _period);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Report exported!'), backgroundColor: AppColors.primary));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Export failed.'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('System Reports', style: AppTextStyles.pageTitle),
            SizedBox(height: 4),
            Text('Analytics and usage statistics', style: AppTextStyles.pageSubtitle),
          ])),
          DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _period,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) { if (v != null) setState(() => _period = v); },
          )),
        ]),
        const SizedBox(height: 24),
        SfPrimaryButton(
          label: _exporting ? 'Generating…' : 'Export $_period Report',
          isLoading: _exporting,
          onPressed: _export,
        ),
      ]),
    );
  }
}
