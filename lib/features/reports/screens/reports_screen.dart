import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../providers/reports_provider.dart';
import '../models/report_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id ?? '0';
    return ChangeNotifierProvider(
      create: (_) => ReportsProvider(userId)..load(),
      child: const _ReportsBody(),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReportsProvider>();
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.nav_reports, style: AppTextStyles.pageTitle),
              const SizedBox(height: 4),
              Text(l10n.reports_subtitle, style: AppTextStyles.pageSubtitle),
            ])),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: prov.isGenerating ? null : () async {
                final ok = await prov.generate();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? l10n.success_msg : (prov.error ?? l10n.error_msg)),
                  backgroundColor: ok ? AppColors.primary : AppColors.error,
                ));
              },
              icon: prov.isGenerating
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_rounded, size: 16),
              label: Text(prov.isGenerating ? '...' : l10n.generate_report),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
                elevation: 0,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Stat cards
          if (prov.stats != null)
            LayoutBuilder(builder: (_, c) {
              final w = (c.maxWidth - 24) / 3;
              return Row(children: [
                _StatCard(icon: Icons.description_outlined, value: '${prov.stats!.totalReports}',
                    label: l10n.total_reports, width: w),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.calendar_today_outlined, value: '${prov.stats!.thisMonth}',
                    label: l10n.this_month, width: w),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.trending_up_rounded, value: prov.stats!.growth,
                    label: l10n.vs_last_month, width: w),
              ]);
            }),
          const SizedBox(height: 20),

          // Loading
          if (prov.isLoading) const Center(
              child: Padding(padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary))),

          // Error
          if (!prov.isLoading && prov.error != null)
            _ErrorCard(message: prov.error!, onRetry: prov.load),

          // Report list
          if (!prov.isLoading)
            ...prov.reports.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReportCard(report: r),
            )),

          if (!prov.isLoading && prov.reports.isEmpty && prov.error == null)
            Center(
              child: Padding(padding: const EdgeInsets.all(48),
                  child: Text(l10n.no_reports_yet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSubtle))),
            ),
        ]),
      )),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label, required this.width});
  final IconData icon;
  final String   value, label;
  final double   width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border:       Border.all(color: AppColors.cardBorder),
          boxShadow:   [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
              child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: AppColors.textDark)),
          Text(label, style: AppTextStyles.caption),
        ]),
      ),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final FarmerReportItem report;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border:       Border.all(color: AppColors.cardBorder),
        boxShadow:   [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(report.title, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(report.subtitle, style: AppTextStyles.pageSubtitle),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (report.date.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSubtle),
                  const SizedBox(width: 4),
                  Text(report.date, style: AppTextStyles.caption),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(50)),
                  child: Text(report.type, style: AppTextStyles.caption),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(50)),
                  child: const Text('Completed',
                      style: TextStyle(fontSize: 11, color: AppColors.primary)),
                ),
              ]),
            ])),
          ]),
        ),
        const Divider(height: 1, color: AppColors.cardBorder),
        InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.download_outlined, size: 16, color: AppColors.textSubtle),
              SizedBox(width: 8),
              Text('Download', style: TextStyle(fontSize: 13, color: AppColors.textSubtle,
                  fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSubtle)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ));
  }
}
